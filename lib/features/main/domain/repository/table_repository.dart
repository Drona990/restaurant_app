import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/table_entity.dart';

abstract class TableRepository {
  Future<Either<Failure, List<TableEntity>>> getTables();

  Future<Either<Failure, void>> createTable(String tableNumber);

  Future<Either<Failure, TableEntity>> updateTable({
    required int id,
    required String tableNumber,
    required bool isActive,
  });

  Future<Either<Failure, void>> deleteTable(int id);
}