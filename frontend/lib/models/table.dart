import 'dart:convert';

import 'package:prbd_2526_f01/core/services/api_client.dart';

class Table {
  final int id;
  final int? restaurant;
  final int tableNumber;
  final int capacity;
  final bool? isAvailable;

  Table({
    required this.id,
    this.restaurant,
    required this.tableNumber,
    required this.capacity,
    this.isAvailable,
  });

  Table copyWith({
    int? id,
    int? restaurant,
    int? tableNumber,
    int? capacity,
    bool? isAvailable,
  }) {
    return Table(
      id: id ?? this.id,
      restaurant: restaurant ?? this.restaurant,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  factory Table.fromJson(Map<String, dynamic> json) {
    return Table(
      id: json['id'],
      restaurant: json['restaurant'],
      tableNumber: json['table_number'],
      capacity: json['capacity'],
      isAvailable: json['is_available'],
    );
  }

  static Future<List<Table>> getRestaurantTablesAvailibility({
    required int restaurantId,
    required int reservationId,
  }) async {
    final response = await ApiClient.post(
      'get_restaurant_tables_availibility',
      body: json.encode({
        'restaurant_id': restaurantId,
        'reservation_id': reservationId,
      }),
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Table.fromJson(item)).toList();
    } else {
      throw Exception('Échec récupération tables');
    }
  }
}
