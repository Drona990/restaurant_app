
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories({String? query});
  Future<CategoryModel> createCategory({
    required String name,
    required String description,
    required String station,
    File? imageFile
  });
  Future<CategoryModel> updateCategory({
    required int id,
    required String name,
    required String description,
    required String station,
    File? imageFile,
    required bool isActive
  });
  Future<CategoryModel> updateCategoryStatus(int id, bool isActive);
  Future<void> deleteCategory(int id);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final ApiClient apiClient;
  CategoryRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<CategoryModel>> getCategories({String? query}) async {
    String path = '/api/categories/';
    final response = await apiClient.get(path, query: query != null ? {'search': query} : null);

    print("category data : $response");

    final List data = (response.data is Map && response.data.containsKey('results'))
        ? response.data['results']
        : (response.data is List ? response.data : []);

    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  @override
  Future<CategoryModel> createCategory({required String name, required String description, required String station, File? imageFile}) async {
    FormData formData = FormData.fromMap({
      'name': name,
      'description': description,
      'station': station,
      'is_active': true,
      if (imageFile != null) 'image': await MultipartFile.fromFile(imageFile.path),
    });
    final response = await apiClient.post('/api/categories/', data: formData);
    return CategoryModel.fromJson(response.data);
  }

  @override
  Future<CategoryModel> updateCategory({required int id, required String name, required String description, required String station, File? imageFile, required bool isActive}) async {
    FormData formData = FormData.fromMap({
      'name': name,
      'description': description,
      'station': station,
      'is_active': isActive,
      if (imageFile != null) 'image': await MultipartFile.fromFile(imageFile.path),
    });
    final response = await apiClient.patch('/api/categories/$id/', data: formData);
    return CategoryModel.fromJson(response.data);
  }

  @override
  Future<CategoryModel> updateCategoryStatus(int id, bool isActive) async {
    final response = await apiClient.patch('/api/categories/$id/', data: {'is_active': isActive});
    return CategoryModel.fromJson(response.data);
  }

  @override
  Future<void> deleteCategory(int id) async {
    await apiClient.delete('/api/categories/$id/');
  }
}