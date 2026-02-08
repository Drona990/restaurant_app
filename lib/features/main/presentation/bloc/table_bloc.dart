import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/table_entity.dart';
import '../../domain/repository/table_repository.dart';

// --- Events ---
abstract class TableEvent {}

class LoadTables extends TableEvent {}

class AddTable extends TableEvent {
  final String number;
  AddTable(this.number);
}

class UpdateTable extends TableEvent {
  final int id;
  final String tableNumber;
  final bool isActive;
  UpdateTable({required this.id, required this.tableNumber, required this.isActive});
}

class DeleteTable extends TableEvent {
  final int id;
  DeleteTable(this.id);
}

class SearchTables extends TableEvent {
  final String query;
  SearchTables(this.query);
}

// --- States ---
abstract class TableState {}

class TableInitial extends TableState {}
class TableLoading extends TableState {}
class TableError extends TableState {
  final String message;
  TableError(this.message);
}
class TableLoaded extends TableState {
  final List<TableEntity> tables; // Current filtered list
  final List<TableEntity> allTables; // Master list
  TableLoaded(this.tables, this.allTables);
}

// --- Bloc Logic ---
class TableBloc extends Bloc<TableEvent, TableState> {
  final TableRepository repository;

  TableBloc(this.repository) : super(TableInitial()) {

    // 1. Load All Tables
    on<LoadTables>((event, emit) async {
      emit(TableLoading());
      final result = await repository.getTables();
      result.fold(
            (failure) => emit(TableError(failure.message)),
            (tables) => emit(TableLoaded(tables, tables)),
      );
    });

    // 2. Search/Filter Logic
    on<SearchTables>((event, emit) {
      if (state is TableLoaded) {
        final currentState = state as TableLoaded;
        if (event.query.isEmpty) {
          emit(TableLoaded(currentState.allTables, currentState.allTables));
        } else {
          final filtered = currentState.allTables
              .where((table) => table.tableNumber
              .toLowerCase()
              .contains(event.query.toLowerCase()))
              .toList();
          emit(TableLoaded(filtered, currentState.allTables));
        }
      }
    });

    // 3. Add Table
    on<AddTable>((event, emit) async {
      final result = await repository.createTable(event.number);
      result.fold(
            (failure) => emit(TableError(failure.message)),
            (_) => add(LoadTables()), // Refresh list
      );
    });

    // 4. Update Table (Status or Number)
    on<UpdateTable>((event, emit) async {
      final result = await repository.updateTable(
        id: event.id,
        tableNumber: event.tableNumber,
        isActive: event.isActive,
      );
      result.fold(
            (failure) => emit(TableError(failure.message)),
            (_) => add(LoadTables()), // Refresh list
      );
    });

    // 5. Delete Table
    on<DeleteTable>((event, emit) async {
      final result = await repository.deleteTable(event.id);
      result.fold(
            (failure) => emit(TableError(failure.message)),
            (_) => add(LoadTables()), // Refresh list
      );
    });
  }
}