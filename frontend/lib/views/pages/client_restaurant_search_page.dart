import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_f01/constants/app_constants.dart';
import 'package:prbd_2526_f01/core/tools/debounce.dart';
import 'package:prbd_2526_f01/providers/client_state_provider.dart';
import 'package:prbd_2526_f01/views/widgets/data_error_widget.dart';
import 'package:prbd_2526_f01/views/widgets/loading_widget.dart';
import 'package:prbd_2526_f01/views/widgets/no_result_widget.dart';
import 'package:prbd_2526_f01/views/widgets/page_app_bar.dart';
import 'package:prbd_2526_f01/views/widgets/restaurant_card.dart';

class ClientRestaurantSearchPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ClientRestaurantSearchPageState();
}

class _ClientRestaurantSearchPageState
    extends ConsumerState<ClientRestaurantSearchPage> {
  final Debouncer _debouncer = Debouncer();

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(clientStateProvider);
    final clientStateNotifier = ref.read(clientStateProvider.notifier);

    return Scaffold(
      appBar: PageAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: 'Rechercher un restaurant',
        onRefreshPressed: clientStateNotifier.refreshRestaurants,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher par nom, ville, description...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                initialValue: asyncState.value?.searchFilter ?? '',
                onChanged: (newText) {
                  _debouncer.call(() {
                    clientStateNotifier.setSearchFilter(
                      searchFilter: newText.trim(),
                    );
                    clientStateNotifier.refreshRestaurants();
                  });
                },
              ),
            ),
            Expanded(
              child: asyncState.when(
                data: (clientState) {
                  final restaurants = clientState.restaurants;

                  if (restaurants.isEmpty) {
                    return NoResultWidget(
                      iconData: Icons.restaurant_outlined,
                      title: 'Aucun restaurant trouvé',
                    );
                  }

                  return Column(
                    children: [
                      if (restaurants.length > AppConstants.limitCount)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          color: Colors.orange.shade50,
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Trop de résultats trouvés. Veuillez affiner votre recherche pour voir plus de restaurants.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: restaurants
                              .take(AppConstants.limitCount)
                              .map((restaurant) {
                                return RestaurantCard(
                                  restaurant: restaurant,
                                  onTap: () async {
                                    await clientStateNotifier
                                        .getClientRestaurant(
                                          restaurantId: restaurant.id,
                                        );
                                    if (context.mounted) {
                                      Navigator.pushNamed(
                                        context,
                                        '/client/restaurants/details',
                                      );
                                    }
                                  },
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ],
                  );
                },
                error: (error, stackTrace) =>
                    DataErrorWidget(error: error, stackTrace: stackTrace),
                loading: () => LoadingWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
