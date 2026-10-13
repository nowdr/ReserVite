import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_f01/providers/current_user_provider.dart';
import 'package:prbd_2526_f01/providers/manager_state_provider.dart';
import 'package:prbd_2526_f01/views/widgets/data_error_widget.dart';
import 'package:prbd_2526_f01/views/widgets/loading_widget.dart';
import 'package:prbd_2526_f01/views/widgets/no_result_widget.dart';
import 'package:prbd_2526_f01/views/widgets/page_app_bar.dart';
import 'package:prbd_2526_f01/views/widgets/restaurant_card.dart';

class ManagerRestaurantListPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManagerRestaurantListPage();
}

class _ManagerRestaurantListPage
    extends ConsumerState<ManagerRestaurantListPage> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(managerStateProvider);
    final managerStateNotifier = ref.read(managerStateProvider.notifier);

    return Scaffold(
      appBar: PageAppBar(
        title: 'Mes restaurants',
        actionsAfterRefresh: [_buildLogoutButton()],
        onRefreshPressed: managerStateNotifier.refreshRestaurants,
      ),
      body: SafeArea(
        child: asyncState.when(
          data: (managerState) {
            final restaurants = managerState.restaurants;

            if (restaurants.isEmpty) {
              NoResultWidget(
                iconData: Icons.restaurant_outlined,
                title: 'Aucun restaurant ne vous a été assigné',
                message: 'Veuillez contacter un administrateur',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: restaurants.map((restaurant) {
                return RestaurantCard(
                  restaurant: restaurant,
                  onTap: () async {
                    managerStateNotifier.loadRestaurant(restaurant: restaurant);
                    await managerStateNotifier.getManagerReservations(
                      restaurantId: restaurant.id,
                    );
                    if (context.mounted) {
                      Navigator.pushNamed(context, '/manager/reservations');
                    }
                  },
                );
              }).toList(),
            );
          },
          error: (error, stackTrace) =>
              DataErrorWidget(error: error, stackTrace: stackTrace),
          loading: () => LoadingWidget(),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    final userName = ref.watch(currentUserProvider.notifier).userName;
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: userName == null ? 'Déconnexion' : 'Déconnexion ($userName)',
      onPressed: () {
        ref.read(currentUserProvider.notifier).logout();
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }
}
