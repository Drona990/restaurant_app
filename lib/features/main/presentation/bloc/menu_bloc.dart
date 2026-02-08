import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../../domain/repository/menu_repository.dart';

// --- 1. Events (Sync with New Logic) ---
abstract class MenuEvent {}

class LoadMenu extends MenuEvent {
  final String? query;
  final int? categoryId;
  LoadMenu({this.query, this.categoryId});
}

class AddMenuItem extends MenuEvent {
  final String name, desc;
  final double price;
  final int catId;
  final bool isReadyToServe; // 🌟 Logic: Instant pickup?
  final int prepTime;        // 🌟 Logic: Kitchen timer
  final File? img;

  AddMenuItem({
    required this.name,
    required this.desc,
    required this.price,
    required this.catId,
    required this.isReadyToServe,
    required this.prepTime,
    this.img,
  });
}

class EditMenuItem extends MenuEvent {
  final int id;
  final String name, desc;
  final double price;
  final int catId;
  final bool isReadyToServe;
  final int prepTime;
  final bool isAvailable;
  final File? img;

  EditMenuItem({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.catId,
    required this.isReadyToServe,
    required this.prepTime,
    required this.isAvailable,
    this.img,
  });
}

class ToggleMenuAvailability extends MenuEvent {
  final int id;
  final bool current;
  ToggleMenuAvailability(this.id, this.current);
}

class DeleteMenuItem extends MenuEvent {
  final int id;
  DeleteMenuItem(this.id);
}

// --- 2. States ---
abstract class MenuState {}
class MenuLoading extends MenuState {}
class MenuLoaded extends MenuState {
  final List<MenuItemEntity> items;
  MenuLoaded(this.items);
}
class MenuError extends MenuState {
  final String msg;
  MenuError(this.msg);
}

// --- 3. Bloc Logic ---
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final MenuItemRepository repository;

  MenuBloc(this.repository) : super(MenuLoading()) {

    on<LoadMenu>((event, emit) async {
      emit(MenuLoading());
      final res = await repository.getMenuItems(
          query: event.query,
          categoryId: event.categoryId
      );
      res.fold(
              (f) => emit(MenuError(f.message)),
              (items) => emit(MenuLoaded(items))
      );
    });

    on<AddMenuItem>((event, emit) async {
      final currentState = state;
      if (currentState is MenuLoaded) {
        final res = await repository.createMenuItem(
          name: event.name,
          description: event.desc,
          price: event.price,
          categoryId: event.catId, // ✅ Fixed parameter name
          isReadyToServe: event.isReadyToServe,
          prepTime: event.prepTime,
          image: event.img,
        );

        res.fold(
                (f) => emit(MenuError(f.message)),
                (newItem) {
              final updatedList = List<MenuItemEntity>.from(currentState.items)..add(newItem);
              emit(MenuLoaded(updatedList));
            }
        );
      }
    });

    on<EditMenuItem>((event, emit) async {
      final currentState = state;
      if (currentState is MenuLoaded) {
        final res = await repository.updateMenuItem(
          id: event.id,
          name: event.name,
          description: event.desc,
          price: event.price,
          categoryId: event.catId,
          isReadyToServe: event.isReadyToServe,
          prepTime: event.prepTime,
          isAvailable: event.isAvailable,
          image: event.img,
        );

        res.fold(
                (f) => emit(MenuError(f.message)),
                (updatedItem) {
              final newList = currentState.items.map((i) => i.id == event.id ? updatedItem : i).toList();
              emit(MenuLoaded(newList));
            }
        );
      }
    });

    on<ToggleMenuAvailability>((event, emit) async {
      final curState = state;
      if (curState is MenuLoaded) {
        final item = curState.items.firstWhere((i) => i.id == event.id);
        // We use full update for consistency
        final res = await repository.updateMenuItem(
          id: item.id,
          name: item.name,
          description: item.description,
          price: item.price,
          categoryId: item.category,
          isReadyToServe: item.isReadyToServe,
          prepTime: item.prepTime,
          isAvailable: !event.current,
          image: null,
        );

        res.fold(
                (f) => emit(MenuError(f.message)),
                (updated) {
              final newList = curState.items.map((i) => i.id == event.id ? updated : i).toList();
              emit(MenuLoaded(newList));
            }
        );
      }
    });

    on<DeleteMenuItem>((event, emit) async {
      final curState = state;
      if (curState is MenuLoaded) {
        final res = await repository.deleteMenuItem(event.id);
        res.fold(
                (f) => emit(MenuError(f.message)),
                (_) {
              final newList = curState.items.where((i) => i.id != event.id).toList();
              emit(MenuLoaded(newList));
            }
        );
      }
    });
  }
}