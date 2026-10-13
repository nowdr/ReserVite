import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_f01/models/reservation.dart';
import 'package:prbd_2526_f01/models/restaurant.dart';
import 'package:prbd_2526_f01/providers/current_user_provider.dart';

import '../models/table.dart';

final managerStateProvider =
    AsyncNotifierProvider<ManagerStateNotifier, ManagerState>(
      ManagerStateNotifier.new,
    );

class ManagerStateNotifier extends AsyncNotifier<ManagerState> {
  @override
  Future<ManagerState> build() async {
    ref.watch(currentUserProvider);
    return ManagerState(restaurants: await Restaurant.getManagerRestaurants());
  }

  void loadRestaurant({required Restaurant restaurant}) {
    state = AsyncData(state.value!.copyWith(currentRestaurant: restaurant));
  }

  Future<void> getManagerReservations({required int restaurantId}) async {
    state = AsyncLoading();
    try {
      final restaurantReservations = await Reservation.getManagerReservations(
        restaurantId: restaurantId,
      );
      state = AsyncData(
        state.value!.copyWith(restaurantReservations: restaurantReservations),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> getManagerReservation({required int reservationId}) async {
    state = AsyncLoading();
    try {
      final reservation = await Reservation.getManagerReservation(
        reservationId: reservationId,
      );
      state = AsyncData(state.value!.copyWith(currentReservation: reservation));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void setStatusFilter(String statusFilter) {
    state = AsyncData(state.value!.copyWith(statusFilter: statusFilter));
  }

  Future<void> cancelReservation({required int id}) async {
    final currentState = state.value!;

    state = const AsyncLoading();
    try {
      await Reservation.cancel(id: id);

      var restaurants = currentState.restaurants;
      var currentRestaurant = currentState.currentRestaurant!;

      if (currentState.currentReservation!.status == 'pending') {
        restaurants = restaurants
            .map(
              (restaurant) => restaurant.id == currentRestaurant.id
                  ? restaurant.copyWith(
                      pendingReservations: restaurant.pendingReservations! - 1,
                    )
                  : restaurant,
            )
            .toList();
        currentRestaurant = restaurants.firstWhere(
          (restaurant) => restaurant.id == currentRestaurant.id,
        );
      }

      final restaurantReservations = currentState.restaurantReservations!
          .map(
            (reservation) => reservation.id == id
                ? reservation.copyWith(status: 'cancelled')
                : reservation,
          )
          .toList();

      Reservation currentReservation = currentState.currentReservation!;
      if (currentReservation.id == id) {
        currentReservation = currentReservation.copyWith(status: 'cancelled');
      }

      state = AsyncData(
        currentState.copyWith(
          restaurants: restaurants,
          currentRestaurant: currentRestaurant,
          restaurantReservations: restaurantReservations,
          currentReservation: currentReservation,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> confirmReservation() async {
    final currentState = state.value!;
    final reservationId = currentState.currentReservation!.id;
    final List<int> selectedTables = currentState.selectedTablesIds!.toList();

    state = const AsyncLoading();
    try {
      await Reservation.confirm(
        id: reservationId,
        selectedTables: selectedTables,
      );

      final tables = currentState.restaurantTables!
          .where((table) => selectedTables.contains(table.id))
          .toList();

      var restaurants = currentState.restaurants;
      var currentRestaurant = currentState.currentRestaurant!;

      if (currentState.currentReservation!.status == 'pending') {
        restaurants = restaurants
            .map(
              (restaurant) => restaurant.id == currentRestaurant.id
                  ? restaurant.copyWith(
                      pendingReservations: restaurant.pendingReservations! - 1,
                    )
                  : restaurant,
            )
            .toList();
        currentRestaurant = restaurants.firstWhere(
          (restaurant) => restaurant.id == currentRestaurant.id,
        );
      }

      final restaurantReservations = currentState.restaurantReservations!
          .map(
            (reservation) => reservation.id == reservationId
                ? reservation.copyWith(status: 'confirmed', tables: tables)
                : reservation,
          )
          .toList();

      Reservation currentReservation = currentState.currentReservation!;
      if (currentReservation.id == reservationId) {
        currentReservation = currentReservation.copyWith(
          status: 'confirmed',
          tables: tables,
        );
      }

      state = AsyncData(
        currentState.copyWith(
          restaurants: restaurants,
          currentRestaurant: currentRestaurant,
          restaurantReservations: restaurantReservations,
          currentReservation: currentReservation,
          selectedTablesIds: const {},
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> completeReservation({required int id}) async {
    final currentState = state.value!;

    state = const AsyncLoading();
    try {
      await Reservation.complete(id: id);

      final restaurantReservations = currentState.restaurantReservations!
          .map(
            (reservation) => reservation.id == id
                ? reservation.copyWith(status: 'completed')
                : reservation,
          )
          .toList();

      Reservation currentReservation = currentState.currentReservation!;
      if (currentReservation.id == id) {
        currentReservation = currentReservation.copyWith(status: 'completed');
      }

      state = AsyncData(
        currentState.copyWith(
          restaurantReservations: restaurantReservations,
          currentReservation: currentReservation,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> getRestaurantTables() async {
    final restaurantId = state.value?.currentRestaurant?.id;
    final reservationId = state.value?.currentReservation?.id;

    if (restaurantId == null || reservationId == null) {
      return;
    }

    state = AsyncLoading();
    try {
      final restaurantTables = await Table.getRestaurantTablesAvailibility(
        restaurantId: restaurantId,
        reservationId: reservationId,
      );
      state = AsyncData(
        state.value!.copyWith(restaurantTables: restaurantTables),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void toggleTableSelection(int tableId) {
    final currentState = state.value!;
    Set<int> newSelection = Set<int>.from(currentState.selectedTablesIds!);
    if (newSelection.contains(tableId)) {
      newSelection.remove(tableId);
    } else {
      newSelection.add(tableId);
    }

    state = AsyncData(currentState.copyWith(selectedTablesIds: newSelection));
  }

  Future<void> refreshRestaurants() async {
    state = AsyncLoading();
    try {
      final restaurants = await Restaurant.getManagerRestaurants();
      state = AsyncData(state.value!.copyWith(restaurants: restaurants));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refreshManagerReservations() async {
    final restaurantId = state.value?.currentRestaurant?.id;

    if (restaurantId != null) {
      await getManagerReservations(restaurantId: restaurantId);
    }
  }

  Future<void> refreshManagerReservation() async {
    final reservationId = state.value?.currentReservation?.id;

    if (reservationId != null) {
      await getManagerReservation(reservationId: reservationId);
    }
  }

  Future<void> refreshRestaurantTables() async {
    await getRestaurantTables();
  }
}

class ManagerState {
  final List<Restaurant> restaurants;
  final Restaurant? currentRestaurant;
  final List<Reservation>? restaurantReservations;
  final String statusFilter;
  final Reservation? currentReservation;
  final List<Table>? restaurantTables;
  final Set<int>? selectedTablesIds;

  ManagerState({
    required this.restaurants,
    this.currentRestaurant,
    this.restaurantReservations,
    this.statusFilter = 'all',
    this.currentReservation,
    this.restaurantTables,
    this.selectedTablesIds = const {},
  });

  ManagerState copyWith({
    List<Restaurant>? restaurants,
    Restaurant? currentRestaurant,
    List<Reservation>? restaurantReservations,
    String? statusFilter,
    Reservation? currentReservation,
    List<Table>? restaurantTables,
    Set<int>? selectedTablesIds,
  }) {
    return ManagerState(
      restaurants: restaurants ?? this.restaurants,
      currentRestaurant: currentRestaurant ?? this.currentRestaurant,
      restaurantReservations:
          restaurantReservations ?? this.restaurantReservations,
      statusFilter: statusFilter ?? this.statusFilter,
      currentReservation: currentReservation ?? this.currentReservation,
      restaurantTables: restaurantTables ?? this.restaurantTables,
      selectedTablesIds: selectedTablesIds ?? this.selectedTablesIds,
    );
  }
}
