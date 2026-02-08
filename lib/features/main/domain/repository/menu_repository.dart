import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/menu_item_entity.dart';

abstract class MenuItemRepository {
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems({String? query, int? categoryId});

  Future<Either<Failure, MenuItemEntity>> createMenuItem({
    required String name,
    required String description,
    required double price,
    required int categoryId, // 🌟 Iska naam 'categoryId' fix kar diya
    required bool isReadyToServe,
    required int prepTime,
    File? image,
  });

  Future<Either<Failure, MenuItemEntity>> updateMenuItem({
    required int id,
    required int categoryId, // 🌟 Iska naam bhi 'categoryId' fix kar diya
    required String name,
    required String description,
    required double price,
    required bool isReadyToServe,
    required int prepTime,
    required bool isAvailable,
    File? image,
  });

  Future<Either<Failure, void>> deleteMenuItem(int id);
}