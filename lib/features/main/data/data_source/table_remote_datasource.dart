// data/datasources/table_remote_data_source.dart
import '../../../../core/network/api_client.dart';
import '../models/table_models.dart';

abstract class TableRemoteDataSource {
  Future<List<TableModel>> getTables();
  Future<TableModel> createTable(String tableNumber);
  Future<TableModel> updateTable(int id, Map<String, dynamic> data);
  Future<void> deleteTable(int id);
}

class TableRemoteDataSourceImpl implements TableRemoteDataSource {
  final ApiClient apiClient;
  TableRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<TableModel>> getTables() async {
    final response = await apiClient.get('/api/tables/');
    final List data = response.data['data'] ?? response.data;
    return data.map((e) => TableModel.fromJson(e)).toList();
  }

  @override
  Future<TableModel> createTable(String tableNumber) async {
    final response = await apiClient.post('/api/tables/', data: {'table_number': tableNumber});
    return TableModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<TableModel> updateTable(int id, Map<String, dynamic> data) async {
    final response = await apiClient.patch('/api/tables/$id/', data: data);
    return TableModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<void> deleteTable(int id) async => await apiClient.delete('/api/tables/$id/');
}