import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_f01/providers/manager_state_provider.dart';
import 'package:prbd_2526_f01/views/widgets/data_error_widget.dart';
import 'package:prbd_2526_f01/views/widgets/loading_widget.dart';
import 'package:prbd_2526_f01/views/widgets/no_result_widget.dart';
import 'package:prbd_2526_f01/views/widgets/page_app_bar.dart';
import 'package:prbd_2526_f01/views/widgets/reservation_card.dart';

class ManagerReservationListPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManagerReservationListPage();
}

class _ManagerReservationListPage
    extends ConsumerState<ManagerReservationListPage> {
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
        title: asyncState.value?.currentRestaurant?.name ?? 'Réservations',
        onRefreshPressed: managerStateNotifier.refreshManagerReservations,
      ),
      body: SafeArea(
        child: asyncState.when(
          data: (managerState) {
            final reservations = managerState.restaurantReservations!;
            final statusFilter = managerState.statusFilter;

            final filteredReservations = statusFilter == 'all'
                ? reservations
                : reservations
                      .where(
                        (reservation) => reservation.status == statusFilter,
                      )
                      .toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: 'all',
                        icon: Icon(Icons.list, size: 24),
                        tooltip: 'Toutes',
                      ),
                      ButtonSegment(
                        value: 'pending',
                        icon: Icon(
                          Icons.pending,
                          size: 24,
                          color: Colors.orange,
                        ),
                        tooltip: 'En attente',
                      ),
                      ButtonSegment(
                        value: 'confirmed',
                        icon: Icon(
                          Icons.check_circle,
                          size: 24,
                          color: Colors.green,
                        ),
                        tooltip: 'Confirmées',
                      ),
                      ButtonSegment(
                        value: 'completed',
                        icon: Icon(
                          Icons.event_available,
                          size: 24,
                          color: Colors.blue,
                        ),
                        tooltip: 'Terminées',
                      ),
                      ButtonSegment(
                        value: 'cancelled',
                        icon: Icon(Icons.cancel, size: 24, color: Colors.red),
                        tooltip: 'Annulées',
                      ),
                    ],
                    selected: {statusFilter},
                    onSelectionChanged: (newSelection) => managerStateNotifier
                        .setStatusFilter(newSelection.first),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filteredReservations.isEmpty
                      ? NoResultWidget(
                          iconData: Icons.calendar_month,
                          title: 'Aucune réservation trouvée',
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: filteredReservations.map((reservation) {
                            return ReservationCard(
                              reservation: reservation,
                              onTap: () async {
                                await managerStateNotifier
                                    .getManagerReservation(
                                      reservationId: reservation.id,
                                    );

                                if (context.mounted) {
                                  Navigator.pushNamed(
                                    context,
                                    '/manager/reservations/details',
                                  );
                                }
                              },
                              isManager: true,
                            );
                          }).toList(),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (_) {},
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Réservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant),
            label: 'Tables',
          ),
        ],
      ),
    );
  }
}
