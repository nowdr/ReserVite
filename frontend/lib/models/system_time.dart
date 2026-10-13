import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:prbd_2526_f01/core/services/api_client.dart';

class SystemTime {
  static Future<DateTime> getSimulatedTime() async {
    final response = await ApiClient.post(
      'get_system_time',
      anonymous: true,
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      if (body.isNotEmpty && body.first['simulated_time'] != null) {
        return DateTime.parse(body.first['simulated_time']);
      }
      throw Exception('Aucune valeur dans system_time');
    } else {
      throw Exception('Échec récupération system_time');
    }
  }

  static Future<void> setSimulatedTime(DateTime simulatedTime) async {
    final response = await ApiClient.post(
      'save_system_time',
      body: json.encode({
        '_simulated_time': DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(simulatedTime),
      }),
      anonymous: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Échec mise à jour system_time');
    }
  }

  static Future<void> clearSimulatedTime() async {
    final response = await ApiClient.post(
      'clear_system_time',
      anonymous: true,
    );
    if (response.statusCode != 200) {
      throw Exception('Échec effacement system_time');
    }
  }
}
