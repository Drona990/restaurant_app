import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/data_source/table_remote_datasource.dart';
import '../../domain/entities/table_entity.dart';
import '../../domain/repository/table_repository.dart';

class TableRepositoryImpl implements TableRepository {
  final TableRemoteDataSource remoteDataSource;

  TableRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<TableEntity>>> getTables() async {
    try {
      final remoteTables = await remoteDataSource.getTables();
      return Right(remoteTables);
    } catch (e) {
      return Left(ServerFailure("Failed to fetch tables: $e"));
    }
  }

  @override
  Future<Either<Failure, void>> createTable(String tableNumber) async {
    try {
      // RemoteDataSource expects tableNumber string
      await remoteDataSource.createTable(tableNumber);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure("Failed to create table: $e"));
    }
  }

  @override
  Future<Either<Failure, TableEntity>> updateTable({
    required int id,
    required String tableNumber,
    required bool isActive,
  }) async {
    try {
      // 🌟 Syncing with RemoteDataSource which expects a Map
      final Map<String, dynamic> updateData = {
        'table_number': tableNumber,
        'is_active': isActive,
      };

      final table = await remoteDataSource.updateTable(id, updateData);
      return Right(table);
    } catch (e) {
      return Left(ServerFailure("Update failed: $e"));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTable(int id) async {
    try {
      await remoteDataSource.deleteTable(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure("Delete failed: $e"));
    }
  }
}