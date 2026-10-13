import 'dart:convert';

import 'package:prbd_2526_f01/core/services/api_client.dart';

class Security {
  static Future<String> login(String email, String password) async {
    final response = await ApiClient.post(
      'login',
      body: json.encode({'email': email, 'password': password}),
      anonymous: true,
    );
    if (response.statusCode != 200) {
      throw Exception('Identifiants invalides');
    }
    final body = json.decode(response.body);
    return body['token'] as String;
  }

  static Future<bool> checkFullNameAvailable({String? fullName}) async {
    final response = await ApiClient.post(
      'check_full_name_available',
      body: json.encode({'_full_name': fullName}),
      anonymous: true,
    );
    final dynamic body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception('Échec validation nom complet\n\n${body['message']}');
    }
    return body;
  }

  static Future<bool> checkEmailAvailable({String? email}) async {
    final response = await ApiClient.post(
      'check_email_available',
      body: json.encode({'_email': email}),
      anonymous: true,
    );
    final dynamic body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception('Échec validation email\n\n${body['message']}');
    }
    return body;
  }

  static Future<void> signup({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await ApiClient.post(
      'signup',
      body: json.encode({
        '_email': email,
        '_password': password,
        '_full_name': fullName,
        '_phone': phone,
      }),
      anonymous: true,
    );
    if (response.statusCode != 204) {
      throw Exception('Échec inscription\n\n${response.body}');
    }
  }

  static Future<void> resetDatabase() async {
    final response = await ApiClient.post('reset_database', anonymous: true);
    if (response.statusCode != 204) {
      throw Exception('Échec réinitialisation base de données');
    }
  }
}
