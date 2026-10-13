import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_f01/models/reservation.dart';
import 'package:prbd_2526_f01/providers/client_state_provider.dart';
import 'package:prbd_2526_f01/providers/current_user_provider.dart';
import 'package:prbd_2526_f01/views/widgets/data_error_widget.dart';
import 'package:prbd_2526_f01/views/widgets/loading_widget.dart';
import 'package:prbd_2526_f01/views/widgets/no_result_widget.dart';
import 'package:prbd_2526_f01/views/widgets/page_app_bar.dart';
import 'package:prbd_2526_f01/views/widgets/reservation_card.dart';

class ClientReservationListPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ClientReservationListPageState();
}

class _ClientReservationListPageState
    extends ConsumerState<ClientReservationListPage> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(clientStateProvider);
    final clientStateNotifier = ref.read(clientStateProvider.notifier);

    return Scaffold(
      appBar: PageAppBar(
        title: 'Mes réservations',
        actionsBeforeRefresh: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () =>
                Navigator.pushNamed(context, '/client/restaurants/search'),
          ),
        ],
        actionsAfterRefresh: [_buildLogoutButton()],
        onRefreshPressed: () => clientStateNotifier.refreshReservations(),
      ),
      body: SafeArea(
        child: asyncState.when(
          data: (clientState) {
            final filteredReservations = _filterReservations(
              clientState.reservations,
              clientState.statusFilter,
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                  child: _buildStatusSelector(
                    clientState.statusFilter,
                    clientStateNotifier,
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
                          children: filteredReservations
                              .map(
                                (reservation) => _buildReservationCard(
                                  reservation,
                                  clientStateNotifier,
                                ),
                              )
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/client/restaurants/search'),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle réservation'),
      ),
    );
  }

  List<Reservation> _filterReservations(
    List<Reservation> reservations,
    String statusFilter,
  ) {
    if (statusFilter == 'all') return reservations;
    return reservations
        .where((reservation) => reservation.status == statusFilter)
        .toList();
  }

  Widget _buildStatusSelector(
    String statusFilter,
    ClientStateNotifier clientStateNotifier,
  ) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: 'all',
          icon: Icon(Icons.list, size: 24),
          tooltip: 'Toutes',
        ),
        ButtonSegment(
          value: 'pending',
          icon: Icon(Icons.pending, size: 24, color: Colors.orange),
          tooltip: 'En attente',
        ),
        ButtonSegment(
          value: 'confirmed',
          icon: Icon(Icons.check_circle, size: 24, color: Colors.green),
          tooltip: 'Confirmées',
        ),
        ButtonSegment(
          value: 'completed',
          icon: Icon(Icons.event_available, size: 24, color: Colors.blue),
          tooltip: 'Terminées',
        ),
        ButtonSegment(
          value: 'cancelled',
          icon: Icon(Icons.cancel, size: 24, color: Colors.red),
          tooltip: 'Annulées',
        ),
      ],
      selected: {statusFilter},
      onSelectionChanged: (newSelection) =>
          clientStateNotifier.setStatusFilter(statusFilter: newSelection.first),
    );
  }

  Widget _buildReservationCard(
    Reservation reservation,
    ClientStateNotifier clientStateNotifier,
  ) {
    return ReservationCard(
      reservation: reservation,
      onTap: () async {
        await clientStateNotifier.getClientReservation(
          reservationId: reservation.id,
        );
        if (mounted) {
          Navigator.pushNamed(context, '/client/reservations/details');
        }
      },
      isManager: false,
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
