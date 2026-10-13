import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_f01/providers/manager_state_provider.dart';
import 'package:prbd_2526_f01/views/widgets/data_error_widget.dart';
import 'package:prbd_2526_f01/views/widgets/loading_widget.dart';
import 'package:prbd_2526_f01/views/widgets/page_app_bar.dart';
import 'package:prbd_2526_f01/views/widgets/table_card.dart';

class ManagerAssignTables extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManagerAssignTablesState();
}

class _ManagerAssignTablesState extends ConsumerState<ManagerAssignTables> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(managerStateProvider);
    final managerStateNotifier = ref.read(managerStateProvider.notifier);

    return Scaffold(
      appBar: PageAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: 'Assigner des tables',
        onRefreshPressed: () {
          managerStateNotifier.refreshManagerReservation();
          managerStateNotifier.refreshRestaurantTables();
        },
      ),
      body: SafeArea(
        child: asyncState.when(
          data: (managerState) {
            final currentReservation = managerState.currentReservation!;
            final restaurantTables = managerState.restaurantTables!;
            final selectedTableIds = managerState.selectedTablesIds!;

            final currentCapacity = restaurantTables
                .where((table) => selectedTableIds.contains(table.id))
                .fold(0, (sum, table) => sum + table.capacity);

            final isSufficient =
                currentCapacity >= currentReservation.numberOfGuests;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Réservation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${currentReservation.numberOfGuests} convive${currentReservation.numberOfGuests > 1 ? 's' : ''}',
                          ),
                          Text(
                            DateFormat(
                              "dd/MM/yy 'à' HH:mm",
                              'fr_FR',
                            ).format(currentReservation.datetime),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (currentCapacity > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      color: isSufficient
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              isSufficient ? Icons.check_circle : Icons.warning,
                              color: isSufficient
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Capacité totale: $currentCapacity places',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isSufficient
                                        ? '✓ Capacité suffisante pour ${currentReservation.numberOfGuests} convives'
                                        : '⚠ Capacité insuffisante: $currentCapacity places pour ${currentReservation.numberOfGuests} convives',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSufficient
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sélectionnez les tables disponibles',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: restaurantTables
                        .map((table) => TableCard(table: table))
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSufficient
                          ? () async {
                              await managerStateNotifier.confirmReservation();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Réservation confirmée avec les tables assignées',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.popUntil(
                                context,
                                (route) =>
                                    route.settings.name ==
                                    '/manager/reservations',
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Confirmer la réservation'),
                    ),
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
    );
  }
}
