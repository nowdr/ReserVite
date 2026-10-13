import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_f01/models/reservation.dart';
import 'package:prbd_2526_f01/models/restaurant.dart';
import 'package:prbd_2526_f01/providers/current_user_provider.dart';

final clientStateProvider =
    AsyncNotifierProvider<ClientStateNotifier, ClientState>(
      ClientStateNotifier.new,
    );

class ClientStateNotifier extends AsyncNotifier<ClientState> {
  @override
  Future<ClientState> build() async {
    ref.watch(currentUserProvider);
    return ClientState(
      reservations: await Reservation.getClientReservations(),
      restaurants: await Restaurant.getClientRestaurants(),
    );
  }

  Future<void> getClientReservation({required int reservationId}) async {
    state = AsyncLoading();
    try {
      final reservation = await Reservation.getClientReservation(
        reservationId: reservationId,
      );
      state = AsyncData(state.value!.copyWith(currentReservation: reservation));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> getClientRestaurant({required int restaurantId}) async {
    state = AsyncLoading();
    try {
      final restaurant = await Restaurant.getClientRestaurant(
        restaurantId: restaurantId,
      );
      state = AsyncData(state.value!.copyWith(currentRestaurant: restaurant));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void setStatusFilter({required String statusFilter}) {
    state = AsyncData(state.value!.copyWith(statusFilter: statusFilter));
  }

  void setSearchFilter({required String searchFilter}) {
    state = AsyncData(state.value!.copyWith(searchFilter: searchFilter));
  }

  Future<void> saveReservation({
    int? id,
    required int restaurantId,
    required DateTime datetime,
    required int numberOfGuests,
    String? specialRequests,
  }) async {
    final currentState = state.value!;
    state = AsyncLoading();
    try {
      final savedId = await Reservation.save(
        id: id,
        restaurantId: restaurantId,
        datetime: datetime,
        numberOfGuests: numberOfGuests,
        specialRequests: specialRequests,
      );

      if (id == null) {
        final restaurants = currentState.restaurants
            .map(
              (restaurant) => restaurant.id == restaurantId
                  ? restaurant.copyWith(
                      pendingReservations: restaurant.pendingReservations! + 1,
                    )
                  : restaurant,
            )
            .toList();

        final restaurant = currentState.restaurants.firstWhere(
          (r) => r.id == restaurantId,
        );
        final created = Reservation(
          id: savedId,
          restaurant: restaurant,
          datetime: datetime,
          numberOfGuests: numberOfGuests,
          status: 'pending',
          specialRequests: specialRequests,
        );
        _appendReservation(currentState, created, restaurants);
      } else {
        _replaceReservation(
          currentState,
          id: id,
          datetime: datetime,
          numberOfGuests: numberOfGuests,
          specialRequests: specialRequests,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void _appendReservation(
    ClientState currentState,
    Reservation created,
    List<Restaurant> restaurants,
  ) {
    final updated = [created, ...currentState.reservations]
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    state = AsyncData(
      currentState.copyWith(reservations: updated, restaurants: restaurants),
    );
  }

  void _replaceReservation(
    ClientState currentState, {
    required int id,
    required DateTime datetime,
    required int numberOfGuests,
    required String? specialRequests,
  }) {
    final updatedReservations = currentState.reservations.map((r) {
      if (r.id != id) return r;
      return r.copyWith(
        datetime: datetime,
        numberOfGuests: numberOfGuests,
        specialRequests: specialRequests,
        status: 'pending',
      );
    }).toList();

    final current = currentState.currentReservation;
    final updatedCurrent = (current != null && current.id == id)
        ? current.copyWith(
            datetime: datetime,
            numberOfGuests: numberOfGuests,
            specialRequests: specialRequests,
            status: 'pending',
          )
        : current;

    state = AsyncData(
      currentState.copyWith(
        reservations: updatedReservations,
        currentReservation: updatedCurrent,
      ),
    );
  }

  Future<void> cancelReservation({required int id}) async {
    final currentState = state.value!;

    state = const AsyncLoading();
    try {
      await Reservation.cancel(id: id);

      var restaurants = currentState.restaurants;
      if (currentState.currentReservation!.status == 'pending') {
        restaurants = restaurants
            .map(
              (restaurant) =>
                  restaurant.id ==
                      currentState.currentReservation!.restaurant.id
                  ? restaurant.copyWith(
                      pendingReservations: restaurant.pendingReservations! - 1,
                    )
                  : restaurant,
            )
            .toList();
      }

      final reservations = currentState.reservations
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
          reservations: reservations,
          currentReservation: currentReservation,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refreshReservations() async {
    state = AsyncLoading();
    try {
      final reservations = await Reservation.getClientReservations();
      state = AsyncData(state.value!.copyWith(reservations: reservations));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refreshRestaurants() async {
    final currentState = state.value!;

    state = AsyncLoading();
    try {
      final restaurants = await Restaurant.getClientRestaurants(
        searchFilter: currentState.searchFilter,
      );
      state = AsyncData(state.value!.copyWith(restaurants: restaurants));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refreshReservation() async {
    final reservationId = state.value?.currentReservation?.id;

    if (reservationId != null) {
      await getClientReservation(reservationId: reservationId);
    }
  }

  Future<void> refreshRestaurant() async {
    final restaurantId = state.value?.currentRestaurant?.id;

    if (restaurantId != null) {
      await getClientRestaurant(restaurantId: restaurantId);
    }
  }
}

class ClientState {
  final List<Reservation> reservations;
  final List<Restaurant> restaurants;
  final Reservation? currentReservation;
  final Restaurant? currentRestaurant;
  final String statusFilter;
  final String? searchFilter;

  ClientState({
    required this.reservations,
    required this.restaurants,
    this.currentReservation,
    this.currentRestaurant,
    this.statusFilter = 'pending',
    this.searchFilter,
  });

  ClientState copyWith({
    List<Reservation>? reservations,
    List<Restaurant>? restaurants,
    Reservation? currentReservation,
    Restaurant? currentRestaurant,
    String? statusFilter,
    String? searchFilter,
  }) {
    return ClientState(
      reservations: reservations ?? this.reservations,
      restaurants: restaurants ?? this.restaurants,
      currentReservation: currentReservation ?? this.currentReservation,
      currentRestaurant: currentRestaurant ?? this.currentRestaurant,
      statusFilter: statusFilter ?? this.statusFilter,
      searchFilter: searchFilter ?? this.searchFilter,
    );
  }
}
