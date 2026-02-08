import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../data/data_source/menu_remote_data_source.dart';
import '../entities/menu_item_entity.dart';
import 'menu_repository.dart';


class MenuRepositoryImpl implements MenuItemRepository {
  final MenuRemoteDataSource remoteDataSource;
  MenuRepositoryImpl(this.remoteDataSource);


  @override
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems({String? query, int? categoryId}) async {
    try {
      final items = await remoteDataSource.getMenuItems(query: query, categoryId: categoryId);
      return Right(items);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data.toString() ?? "Error loading menu"));
    }
  }

  @override
  Future<Either<Failure, MenuItemEntity>> createMenuItem({
    required String name,
    required String description,
    required double price,
    required int categoryId, // ✅ Interface se match ho gaya
    required bool isReadyToServe,
    required int prepTime,
    File? image,
  }) async {
    try {
      final data = {
        'name': name,
        'description': description,
        'price': price,
        'category': categoryId, // Backend integer expect karta hai
        'is_ready_to_serve': isReadyToServe,
        'prep_time': prepTime,
        'is_available': true
      };
      final item = await remoteDataSource.createMenuItem(data, image);
      return Right(item);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? "Error creating item"));
    }
  }

  @override
  Future<Either<Failure, MenuItemEntity>> updateMenuItem({
    required int id,
    required int categoryId, // ✅ Interface se match ho gaya
    required String name,
    required String description,
    required double price,
    required bool isReadyToServe,
    required int prepTime,
    required bool isAvailable,
    File? image,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'name': name,
        'description': description,
        'price': price,
        'category': categoryId,
        'is_ready_to_serve': isReadyToServe,
        'prep_time': prepTime,
        'is_available': isAvailable,
      };
      final item = await remoteDataSource.updateMenuItem(id, data, image);
      return Right(item);
    } on DioException {
      return Left(ServerFailure("Update failed"));
    }
  }


  @override
  Future<Either<Failure, void>> deleteMenuItem(int id) async {
    try {
      await remoteDataSource.deleteMenuItem(id);
      return const Right(null);
    } on DioException {
      return Left(ServerFailure("Delete failed"));
    }
  }
}