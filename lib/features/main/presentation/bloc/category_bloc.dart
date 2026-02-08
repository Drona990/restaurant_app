import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repository/category_repository.dart';

// --- 1. Events (Added Station Field) ---
abstract class CategoryEvent {}

class LoadCategories extends CategoryEvent {
  final String? query;
  LoadCategories({this.query});
}

class AddCategory extends CategoryEvent {
  final String name, description, station; // 🌟 Logic: station added
  final File? image;
  AddCategory({
    required this.name,
    required this.description,
    required this.station,
    this.image
  });
}

class EditCategory extends CategoryEvent {
  final int id;
  final String name, description, station; // 🌟 Logic: station added
  final File? image;
  final bool isActive;
  EditCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.station,
    this.image,
    required this.isActive
  });
}

class ToggleCategoryStatus extends CategoryEvent {
  final int id;
  final bool currentStatus;
  ToggleCategoryStatus(this.id, this.currentStatus);
}

class DeleteCategory extends CategoryEvent {
  final int id;
  DeleteCategory(this.id);
}

// --- 2. States ---
abstract class CategoryState {}
class CategoryInitial extends CategoryState {}
class CategoryLoading extends CategoryState {}
class CategoryLoaded extends CategoryState {
  final List<CategoryEntity> categories;
  CategoryLoaded(this.categories);
}
class CategoryError extends CategoryState {
  final String message;
  CategoryError(this.message);
}

// --- 3. Bloc Implementation ---
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository repository;

  CategoryBloc(this.repository) : super(CategoryInitial()) {

    on<LoadCategories>((event, emit) async {
      emit(CategoryLoading());
      final res = await repository.getCategories(query: event.query);
      res.fold((f) => emit(CategoryError(f.message)), (c) => emit(CategoryLoaded(c)));
    });

    on<AddCategory>((event, emit) async {
      // 🌟 Calling repository with station
      final res = await repository.createCategory(
          name: event.name,
          description: event.description,
          station: event.station,
          image: event.image
      );
      res.fold(
              (f) => emit(CategoryError(f.message)),
              (_) => add(LoadCategories())
      );
    });

    on<EditCategory>((event, emit) async {
      final currentState = state;
      if (currentState is CategoryLoaded) {
        // 🌟 Calling repository with updated station
        final res = await repository.updateCategory(
            id: event.id,
            name: event.name,
            description: event.description,
            station: event.station,
            image: event.image,
            isActive: event.isActive
        );
        res.fold(
                (f) => emit(CategoryError(f.message)),
                (updatedCat) {
              final newList = currentState.categories.map((c) => c.id == event.id ? updatedCat : c).toList();
              emit(CategoryLoaded(newList));
            }
        );
      }
    });

    on<ToggleCategoryStatus>((event, emit) async {
      final currentState = state;
      if (currentState is CategoryLoaded) {
        final res = await repository.updateCategoryStatus(event.id, !event.currentStatus);
        res.fold(
                (f) => emit(CategoryError(f.message)),
                (updatedCat) {
              final newList = currentState.categories.map((c) => c.id == event.id ? updatedCat : c).toList();
              emit(CategoryLoaded(newList));
            }
        );
      }
    });

    on<DeleteCategory>((event, emit) async {
      final currentState = state;
      if (currentState is CategoryLoaded) {
        final res = await repository.deleteCategory(event.id);
        res.fold(
                (f) => emit(CategoryError(f.message)),
                (_) {
              final newList = currentState.categories.where((c) => c.id != event.id).toList();
              emit(CategoryLoaded(newList));
            }
        );
      }
    });
  }
}