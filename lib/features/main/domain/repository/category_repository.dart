import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories({String? query});

  // 🌟 Added 'required String station' here
  Future<Either<Failure, CategoryEntity>> createCategory({
    required String name,
    required String description,
    required String station,
    File? image
  });

  // 🌟 Added 'required String station' here as well
  Future<Either<Failure, CategoryEntity>> updateCategory({
    required int id,
    required String name,
    required String description,
    required String station,
    File? image,
    required bool isActive
  });

  Future<Either<Failure, CategoryEntity>> updateCategoryStatus(int id, bool isActive);
  Future<Either<Failure, void>> deleteCategory(int id);
}