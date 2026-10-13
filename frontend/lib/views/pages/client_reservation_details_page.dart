import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_f01/models/reservation.dart';
import 'package:prbd_2526_f01/models/status.dart';
import 'package:prbd_2526_f01/providers/client_state_provider.dart';
import 'package:prbd_2526_f01/providers/simulated_time_provider.dart';
import 'package:prbd_2526_f01/views/pages/client_edit_reservation_page.dart';
import 'package:prbd_2526_f01/views/widgets/data_error_widget.dart';
import 'package:prbd_2526_f01/views/widgets/loading_widget.dart';
import 'package:prbd_2526_f01/views/widgets/page_app_bar.dart';

class ClientReservationDetailsPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<ClientReservationDetailsPage> createState() =>
      _ClientReservationDetailsPageState();
}

class _ClientReservationDetailsPageState
    extends ConsumerState<ClientReservationDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(clientStateProvider);
    final clientStateNotifier = ref.read(clientStateProvider.notifier);

    return Scaffold(
      appBar: PageAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: 'Détails de la réservation',
        onRefreshPressed: () => clientStateNotifier.refreshReservation(),
      ),
      body: SafeArea(
        child: asyncState.when(
          data: (clientState) {
            final currentReservation = clientState.currentReservation!;
            final currentDateTime = ref
                .watch(simulatedTimeProvider)
                .maybeWhen(data: (data) => data, orElse: () => DateTime.now());
            final canEdit = currentReservation.datetime.isAfter(
              currentDateTime,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReservationDetailsCard(currentReservation),
                  if (![
                    'completed',
                    'cancelled',
                  ].contains(currentReservation.status)) ...[
                    const SizedBox(height: 24),
                    _buildReservationActionButtons(
                      currentReservation,
                      canEdit,
                      clientStateNotifier,
                    ),
                  ],
                ],
              ),
            );
          },
          error: (error, stackTrace) =>
              DataErrorWidget(error: error, stackTrace: stackTrace),
          loading: () => LoadingWidget(),
        ),
      ),
    );
  }

  Widget _buildReservationDetailsCard(Reservation reservation) {
    final status = Status.values.byName(reservation.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              Icons.restaurant,
              Text(
                reservation.restaurant.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.location_on,
              Text(
                '${reservation.restaurant.address}, ${reservation.restaurant.city}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              iconSize: 16,
              iconColor: Colors.grey,
            ),
            const SizedBox(height: 4),
            _buildDetailRow(
              Icons.phone,
              Text(
                reservation.restaurant.phone!,
                style: TextStyle(color: Colors.grey[600]),
              ),
              iconSize: 16,
              iconColor: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.calendar_today,
              Text(
                DateFormat(
                  'EEE dd/MM/yyyy',
                  'fr_FR',
                ).format(reservation.datetime),
              ),
              iconSize: 20,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.access_time,
              Text(DateFormat('HH:mm').format(reservation.datetime)),
              iconSize: 20,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.people,
              Text('Nombre de convives: ${reservation.numberOfGuests}'),
              iconSize: 20,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info, size: 20),
                const SizedBox(width: 8),
                const Text('Statut: '),
                Chip(
                  label: Text(
                    status.label,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: status.color,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            if (reservation.specialRequests != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Demandes spéciales',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                reservation.specialRequests!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReservationActionButtons(
    Reservation reservation,
    bool canEdit,
    ClientStateNotifier clientStateNotifier,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canEdit
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ClientEditReservationPage(reservation: reservation),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.edit),
            label: const Text('Modifier'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                _showCancelReservationDialog(reservation, clientStateNotifier),
            icon: const Icon(Icons.cancel),
            label: const Text('Annuler'),
          ),
        ),
      ],
    );
  }

  void _showCancelReservationDialog(
    Reservation reservation,
    ClientStateNotifier clientStateNotifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette réservation ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await clientStateNotifier.cancelReservation(id: reservation.id);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    Widget widget, {
    double iconSize = 20,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        SizedBox(width: iconSize <= 16 ? 4 : 8),
        Expanded(child: widget),
      ],
    );
  }
}
