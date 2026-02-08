import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/menu_item_model.dart';

abstract class MenuRemoteDataSource {
  Future<List<MenuItemModel>> getMenuItems({String? query, int? categoryId});
  Future<MenuItemModel> createMenuItem(Map<String, dynamic> data, File? image);
  Future<MenuItemModel> updateMenuItem(int id, Map<String, dynamic> data, File? image);
  Future<void> deleteMenuItem(int id);
}

class MenuRemoteDataSourceImpl implements MenuRemoteDataSource {
  final ApiClient apiClient;
  MenuRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<MenuItemModel>> getMenuItems({String? query, int? categoryId}) async {
    String path = '/api/menu-items/';
    Map<String, dynamic> params = {};
    if (query != null && query.isNotEmpty) params['search'] = query;
    if (categoryId != null) params['category'] = categoryId;

    final response = await apiClient.get(path, query: params);
    print("menu item data:$response");

    final dynamic resData = response.data;
    List<dynamic> data = (resData is Map && resData.containsKey('results'))
        ? resData['results']
        : (resData is List ? resData : []);

    return data.map((e) => MenuItemModel.fromJson(e)).toList();
  }

  @override
  Future<MenuItemModel> createMenuItem(Map<String, dynamic> data, File? image) async {
    final Map<String, dynamic> finalMap = {
      'name': data['name'],
      'description': data['description'],
      'price': data['price'].toString(),
      'category': data['category'].toString(),
      'is_ready_to_serve': data['is_ready_to_serve'].toString(), // 'true'/'false'
      'prep_time': data['prep_time'].toString(),
      'is_available': 'true',
    };

    if (image != null) {
      finalMap['image'] = await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      );
    }

    FormData formData = FormData.fromMap(finalMap);

    try {
      final response = await apiClient.post('/api/menu-items/', data: formData);
      final result = response.data['data'] ?? response.data;
      return MenuItemModel.fromJson(result);
    } on DioException catch (e) {
      print("❌ BACKEND VALIDATION ERROR: ${e.response?.data}");
      rethrow;
    }
  }

  @override
  Future<MenuItemModel> updateMenuItem(int id, Map<String, dynamic> data, File? image) async {
    // 🌟 Dynamic Mapping with String conversion for FormData
    final Map<String, dynamic> finalMap = {};
    data.forEach((key, value) {
      finalMap[key] = value.toString();
    });

    if (image != null) {
      finalMap['image'] = await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      );
    }

    FormData formData = FormData.fromMap(finalMap);

    try {
      final response = await apiClient.patch('/api/menu-items/$id/', data: formData);
      final result = response.data['data'] ?? response.data;
      return MenuItemModel.fromJson(result);
    } on DioException catch (e) {
      print("❌ UPDATE ERROR: ${e.response?.data}");
      rethrow;
    }
  }

  @override
  Future<void> deleteMenuItem(int id) async {
    await apiClient.delete('/api/menu-items/$id/');
  }
}