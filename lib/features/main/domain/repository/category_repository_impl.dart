import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../data/data_source/category_remote_data_source.dart';
import '../entities/category_entity.dart';
import 'category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories({String? query}) async {
    try {
      final categories = await remoteDataSource.getCategories(query: query);
      return Right(categories);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['message'] ?? "Failed to load categories"));
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> createCategory({
    required String name,
    required String description,
    required String station, // ✅ Matches Interface
    File? image,
  }) async {
    try {
      final category = await remoteDataSource.createCategory(
        name: name,
        description: description,
        station: station,
        imageFile: image,
      );
      return Right(category);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['message'] ?? "Failed to create category"));
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory({
    required int id,
    required String name,
    required String description,
    required String station, // ✅ Matches Interface
    File? image,
    required bool isActive,
  }) async {
    try {
      final category = await remoteDataSource.updateCategory(
        id: id,
        name: name,
        description: description,
        station: station,
        imageFile: image,
        isActive: isActive,
      );
      return Right(category);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['message'] ?? "Failed to update category"));
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> updateCategoryStatus(int id, bool isActive) async {
    try {
      final category = await remoteDataSource.updateCategoryStatus(id, isActive);
      return Right(category);
    } on DioException catch (e) {
      return Left(ServerFailure("Failed to update status"));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(int id) async {
    try {
      await remoteDataSource.deleteCategory(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure("Failed to delete category"));
    }
  }
}