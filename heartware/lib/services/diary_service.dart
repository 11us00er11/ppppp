import '../services/api_client.dart';

class DiaryService {
  final ApiClient api;
  DiaryService(this.api);

  Future<dynamic> list(Map<String, String> qp) async {
    return await api.get('/api/diary', params: qp);
  }

  Future<dynamic> create(Map<String, dynamic> body) async {
    return await api.post('/api/diary', body: body);
  }

  Future<void> delete(int id) async {
    await api.delete('/api/diary/$id');
  }
}
