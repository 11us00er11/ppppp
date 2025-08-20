import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

// 전역 ApiClient
late final ApiClient apiClient;

Future<void> initApiClient() async {
  apiClient = ApiClient(
    baseUrl: 'http://127.0.0.1:5000/api',
    tokenProvider: getStoredToken,
  );
}

Future<String?> getStoredToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

Future<void> saveStoredToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

Future<void> clearStoredToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
}
