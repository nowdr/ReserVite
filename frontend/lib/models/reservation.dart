import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:prbd_2526_f01/core/services/api_client.dart';
import 'package:prbd_2526_f01/models/restaurant.dart';
import 'package:prbd_2526_f01/models/table.dart';
import 'package:prbd_2526_f01/models/user.dart';

class Reservation {
  final int id;
  final User? client;
  final Restaurant restaurant;
  final DateTime datetime;
  final int numberOfGuests;
  final String status;
  final String? specialRequests;
  final List<Table>? tables;

  Reservation({
    required this.id,
    this.client,
    required this.restaurant,
    required this.datetime,
    required this.numberOfGuests,
    required this.status,
    this.specialRequests,
    this.tables,
  });

  Reservation copyWith({
    int? id,
    User? client,
    Restaurant? restaurant,
    DateTime? datetime,
    int? numberOfGuests,
    String? status,
    String? specialRequests,
    List<Table>? tables,
  }) {
    return Reservation(
      id: id ?? this.id,
      client: client ?? this.client,
      restaurant: restaurant ?? this.restaurant,
      datetime: datetime ?? this.datetime,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      status: status ?? this.status,
      specialRequests: specialRequests ?? this.specialRequests,
      tables: tables ?? this.tables,
    );
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final rawTables = json['tables'];
    final List<Table>? parsedTables = rawTables is List
        ? rawTables
              .map((t) => Table.fromJson(t as Map<String, dynamic>))
              .toList()
        : null;

    return Reservation(
      id: json['id'],
      client: json['client'] != null ? User.fromJson(json['client']) : null,
      restaurant: Restaurant.fromJson(json['restaurant']),
      datetime: DateTime.parse(json['datetime']),
      numberOfGuests: json['number_of_guests'],
      status: json['status'],
      specialRequests: json['special_requests'],
      tables: parsedTables,
    );
  }

  static Future<List<Reservation>> getClientReservations() async {
    final response = await ApiClient.post('get_client_reservations');
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Reservation.fromJson(item)).toList();
    } else {
      throw Exception('Échec récupération réservations');
    }
  }

  static Future<Reservation> getClientReservation({
    required int reservationId,
  }) async {
    final response = await ApiClient.post(
      'get_client_reservation',
      body: json.encode({'reservation_id': reservationId}),
    );
    if (response.statusCode == 200) {
      return Reservation.fromJson(json.decode(response.body));
    } else {
      throw Exception('Échec récupération réservation');
    }
  }

  static Future<List<Reservation>> getManagerReservations({
    required int restaurantId,
  }) async {
    final response = await ApiClient.post(
      'get_manager_reservations',
      body: json.encode({'restaurant_id': restaurantId}),
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Reservation.fromJson(item)).toList();
    } else {
      throw Exception('Échec récupération réservations');
    }
  }

  static Future<Reservation> getManagerReservation({
    required int reservationId,
  }) async {
    final response = await ApiClient.post(
      'get_manager_reservation',
      body: json.encode({'reservation_id': reservationId}),
    );
    if (response.statusCode == 200) {
      return Reservation.fromJson(json.decode(response.body));
    } else {
      throw Exception('Échec récupération réservation');
    }
  }

  static Future<int> save({
    int? id,
    required int restaurantId,
    required DateTime datetime,
    required int numberOfGuests,
    String? specialRequests,
  }) async {
    final body = <String, dynamic>{
      '_restaurant_id': restaurantId,
      '_datetime': DateFormat('yyyy-MM-dd HH:mm:ss').format(datetime),
      '_number_of_guests': numberOfGuests,
      '_special_requests': specialRequests,
    };
    if (id != null) {
      body['_reservation_id'] = id;
    }

    final response = await ApiClient.post(
      'save_reservation',
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      final action = id == null ? 'création' : 'mise à jour';
      throw Exception('Échec $action réservation');
    }
    return json.decode(response.body) as int;
  }

  static Future<void> cancel({required int id}) async {
    final response = await ApiClient.post(
      'cancel_reservation',
      body: json.encode({'_id': id}),
    );

    if (response.statusCode != 204) {
      throw Exception('Échec annulation réservation');
    }
  }

  static Future<void> confirm({
    required int id,
    required List<int> selectedTables,
  }) async {
    final response = await ApiClient.post(
      'confirm_reservation',
      body: json.encode({
        'reservation_id': id,
        'selected_tables': selectedTables,
      }),
    );

    if (response.statusCode != 204) {
      throw Exception('Échec confirmation réservation');
    }
  }

  static Future<void> complete({required int id}) async {
    final response = await ApiClient.post(
      'complete_reservation',
      body: json.encode({'_id': id}),
    );

    if (response.statusCode != 204) {
      throw Exception('Échec achèvement réservation');
    }
  }

  static Future<List<AvailableSlot>> getAvailableSlots({
    required int restaurantId,
    required DateTime date,
    required int guests,
    int? excludeReservationId,
  }) async {
    final response = await ApiClient.post(
      'get_available_slots',
      body: json.encode({
        '_restaurant_id': restaurantId,
        '_date': DateFormat('yyyy-MM-dd').format(date),
        '_exclude_reservation': ?excludeReservationId,
      }),
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((item) => AvailableSlot.fromJson(item)).toList();
    } else {
      throw Exception('Échec récupération des créneaux');
    }
  }
}

class AvailableSlot {
  final String time;
  final int remainingCapacity;

  AvailableSlot({required this.time, required this.remainingCapacity});

  factory AvailableSlot.fromJson(Map<String, dynamic> json) {
    return AvailableSlot(
      time: json['time'] as String,
      remainingCapacity: json['remaining_capacity'] as int,
    );
  }

  DateTime toDateTimeOn(DateTime date) {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}

extension AvailableSlotListX on List<AvailableSlot> {
  AvailableSlot? findByTime(String? time) {
    if (time == null) return null;
    for (final slot in this) {
      if (slot.time == time) return slot;
    }
    return null;
  }
}
