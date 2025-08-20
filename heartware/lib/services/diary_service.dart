// services/diary_service.dart
import '../services/api_client.dart';

class DiaryService {
  final ApiClient _api;
  DiaryService(this._api);

  Future<Map<String, dynamic>> list(Map<String, String> params) async {
    // /history? page, size, from, to, q, mood=... (CSV)
    return await _api.get('/history', params: params) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    return await _api.post('/history', body: body) as Map<String, dynamic>;
  }

  Future<void> delete(int id) async {
    await _api.delete('/history/$id');
  }
}
