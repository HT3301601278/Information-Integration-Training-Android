import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'http://192.168.75.47:8080';
  String? token;

  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['token'];
      return true;
    }
    return false;
  }

  Future<List<dynamic>> getDevices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/devices'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('加载设备失败');
  }

  Future<Map<String, dynamic>> getDeviceData(String deviceId, {DateTime? startTime, DateTime? endTime}) async {
    String url = '$baseUrl/api/devices/$deviceId/data';
    if (startTime != null && endTime != null) {
      url += '?startTime=${startTime.toIso8601String()}&endTime=${endTime.toIso8601String()}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('加载设备数据失败');
  }

  Future<bool> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }
}