import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';

// --- Events ---
abstract class MenuEvent {}
class LoadMenuData extends MenuEvent {}
class FilterByCategory extends MenuEvent { final String category; FilterByCategory(this.category); }

// 🌟 Search Event added
class SearchMenu extends MenuEvent {
  final String query;
  SearchMenu(this.query);
}
class RemoveFromCart extends MenuEvent {
  final int index;
  RemoveFromCart(this.index);
}

class ConfirmOrder extends MenuEvent {
  final String? orderId; final int? tableId; final String? guestName; final List cartItems;
  ConfirmOrder({this.orderId, this.tableId, this.guestName,required this.cartItems});
}


// 🌟 Naya Professional Code (Named Parameters):
class AddToCart extends MenuEvent {
  final dynamic item;
  final String seatName; // Guest name ya seat

  AddToCart({required this.item, required this.seatName});
}

// --- States ---
abstract class MenuState {}
class MenuInitial extends MenuState {}
class MenuLoading extends MenuState {}
class MenuLoaded extends MenuState {
  final List categories, allItems, filteredItems, cart;
  final String activeCategory;
  final String searchQuery; // 🌟 Search query state mein track karna achha hota hai

  MenuLoaded({
    required this.categories,
    required this.allItems,
    required this.filteredItems,
    required this.cart,
    this.activeCategory = "All",
    this.searchQuery = "",
  });

  MenuLoaded copyWith({List? categories, List? allItems, List? filteredItems, List? cart, String? activeCategory, String? searchQuery}) {
    return MenuLoaded(
      categories: categories ?? this.categories,
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      cart: cart ?? this.cart,
      activeCategory: activeCategory ?? this.activeCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
class MenuOrderSuccess extends MenuState {}
class MenuError extends MenuState { final String message; MenuError(this.message); }

// --- Logic ---
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final ApiClient apiClient;

  MenuBloc({required this.apiClient}) : super(MenuInitial()) {

    on<LoadMenuData>((event, emit) async {
      emit(MenuLoading());
      try {
        final catRes = await apiClient.get("/api/categories/");
        final itemRes = await apiClient.get("/api/menu-items/");

        // 🌟 Django DRF Fix: Data 'results' key ke andar hai
        final List categories = catRes.data['results'] ?? [];
        final List items = itemRes.data['results'] ?? [];

        emit(MenuLoaded(categories: categories, allItems: items, filteredItems: items, cart: []));
      } catch (e) {
        emit(MenuError("Failed to load: $e"));
      }
    });


    on<FilterByCategory>((event, emit) {
      if (state is MenuLoaded) {
        final s = state as MenuLoaded;
        final filtered = event.category == "All"
            ? s.allItems
            : s.allItems.where((i) => i['category_name'] == event.category).toList();

        emit(s.copyWith(filteredItems: filtered, activeCategory: event.category, searchQuery: ""));
      }
    });

    // 🌟 Corrected Search Logic
    on<SearchMenu>((event, emit) {
      if (state is MenuLoaded) {
        final s = state as MenuLoaded;
        final query = event.query.toLowerCase();

        final filtered = s.allItems.where((item) {
          final nameMatch = item['name'].toString().toLowerCase().contains(query);
          final categoryMatch = s.activeCategory == "All" ||
              item['category_name'] == s.activeCategory;
          return nameMatch && categoryMatch;
        }).toList();

        emit(s.copyWith(filteredItems: filtered, searchQuery: event.query));
      }
    });

    on<AddToCart>((event, emit) {
      if (state is MenuLoaded) {
        final s = state as MenuLoaded;

        // Naya cart item
        final newItem = {
          "item": event.item,
          "guest": event.seatName,
          "quantity": 1,
        };

        final updatedCart = List.from(s.cart)..add(newItem);
        emit(s.copyWith(cart: updatedCart));
      }
    });

    on<RemoveFromCart>((event, emit) {
      if (state is MenuLoaded) {
        final s = state as MenuLoaded;
        final updatedCart = List.from(s.cart)..removeAt(event.index);
        emit(s.copyWith(cart: updatedCart));
      }
    });


    on<ConfirmOrder>((event, emit) async {
      if (state is! MenuLoaded) return;
      final s = state as MenuLoaded;
      final savedCart = s.cart;

      if (savedCart.isEmpty) {
        emit(MenuError("Cart is empty!"));
        return;
      }

      emit(MenuLoading());

      try {
        // 1. Fetch User Role for Auto-Approval
        const storage = FlutterSecureStorage();
        final String? userRole = await storage.read(key: 'user_role');

        // 🎯 Define who is a staff member
        final bool isWaiterRole = (
            userRole?.toLowerCase() == 'waiter' ||
                userRole?.toLowerCase() == 'captain' ||
                userRole?.toLowerCase() == 'admin'
        );

        // 2. Construct Request Body
        final Map<String, dynamic> requestBody = {
          "table_id": event.tableId,
          "order_id": event.orderId, // Non-null for add-ons
          "guest_name": event.guestName ?? "Guest",
          "is_waiter": isWaiterRole, // 🌟 CRITICAL: Tells backend to auto-confirm
          "items": savedCart.map((c) => {
            "menu_item_id": c['item']['id'],
            "quantity": c['quantity'] ?? 1,
            "seat_number": c['seat'] ?? 1,
          }).toList(),
        };

        // 3. API Call
        final response = await apiClient.post("/api/orders/submit/", data: requestBody);

        if (response.statusCode == 200 || response.statusCode == 201) {
          emit(MenuOrderSuccess());
        } else {
          final errorMsg = response.data['error'] ?? "Failed to submit order";
          emit(MenuError(errorMsg));
        }

      } catch (e) {
        emit(MenuError("Order Error: $e"));
      }
    });


  }
}