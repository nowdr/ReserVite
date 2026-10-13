import 'dart:convert';

import 'package:prbd_2526_f01/constants/app_constants.dart';
import 'package:prbd_2526_f01/core/services/api_client.dart';
import 'package:prbd_2526_f01/models/service.dart';
import 'package:prbd_2526_f01/models/table.dart';

class Restaurant {
  final int id;
  final String name;
  final String? address;
  final String? city;
  final String? phone;
  final String? description;
  final double? rating;
  final int? priceRange;
  final int? slotDuration;
  final List<Table>? tables;
  final List<Service>? services;
  final DateTime? lastReservation;
  int? pendingReservations;

  Restaurant({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.phone,
    this.description,
    this.rating,
    this.priceRange,
    this.slotDuration,
    this.tables,
    this.services,
    this.lastReservation,
    this.pendingReservations,
  });

  Restaurant copyWith({
    int? id,
    String? name,
    String? address,
    String? city,
    String? phone,
    String? description,
    double? rating,
    int? priceRange,
    int? slotDuration,
    List<Table>? tables,
    List<Service>? services,
    DateTime? lastReservation,
    int? pendingReservations,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      priceRange: priceRange ?? this.priceRange,
      slotDuration: slotDuration ?? this.slotDuration,
      tables: tables ?? this.tables,
      services: services ?? this.services,
      lastReservation: lastReservation ?? this.lastReservation,
      pendingReservations: pendingReservations ?? this.pendingReservations,
    );
  }

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      phone: json['phone'],
      description: json['description'],
      rating: json['rating'],
      priceRange: json['price_range'],
      slotDuration: json['slot_duration'],
      tables:
          (json['tables'] as List?)
              ?.map((table) => Table.fromJson(table))
              .toList() ??
          [],
      services:
          (json['services'] as List?)
              ?.map((service) => Service.fromJson(service))
              .toList() ??
          [],
      lastReservation: json['last_reservation'] != null
          ? DateTime.parse(json['last_reservation'])
          : null,
      pendingReservations: json['pending_reservations'],
    );
  }

  static Future<List<Restaurant>> getClientRestaurants({
    String? searchFilter,
  }) async {
    final response = await ApiClient.post(
      'get_client_restaurants',
      body: json.encode({
        'search_filter': searchFilter,
        'limit_count': AppConstants.limitCount,
      }),
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Restaurant.fromJson(item)).toList();
    } else {
      throw Exception('Échec récupération restaurants');
    }
  }

  static Future<Restaurant> getClientRestaurant({
    required int restaurantId,
  }) async {
    final response = await ApiClient.post(
      'get_client_restaurant',
      body: json.encode({'restaurant_id': restaurantId}),
    );
    if (response.statusCode == 200) {
      return Restaurant.fromJson(json.decode(response.body));
    } else {
      throw Exception('Échec récupération restaurant');
    }
  }

  static Future<List<Restaurant>> getManagerRestaurants() async {
    final response = await ApiClient.post('get_manager_restaurants');
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Restaurant.fromJson(item)).toList();
    } else {
      throw Exception('Échec récupération restaurants');
    }
  }
}
