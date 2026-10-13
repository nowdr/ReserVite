import 'package:flutter/material.dart' hide Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_f01/models/reservation.dart';
import 'package:prbd_2526_f01/models/status.dart';
import 'package:prbd_2526_f01/models/table.dart';
import 'package:prbd_2526_f01/providers/manager_state_provider.dart';
import 'package:prbd_2526_f01/providers/simulated_time_provider.dart';
import 'package:prbd_2526_f01/views/widgets/data_error_widget.dart';
import 'package:prbd_2526_f01/views/widgets/loading_widget.dart';
import 'package:prbd_2526_f01/views/widgets/page_app_bar.dart';

class ManagerReservationDetailsPage extends ConsumerStatefulWidget {
  const ManagerReservationDetailsPage({super.key});

  @override
  ConsumerState<ManagerReservationDetailsPage> createState() =>
      _ManagerReservationDetailsPageState();
}

class _ManagerReservationDetailsPageState
    extends ConsumerState<ManagerReservationDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(managerStateProvider);
    final managerStateNotifier = ref.read(managerStateProvider.notifier);

    return Scaffold(
      appBar: PageAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: 'Détails de la réservation',
        onRefreshPressed: () =>
            managerStateNotifier.refreshManagerReservation(),
      ),
      body: SafeArea(
        child: asyncState.when(
          data: (managerState) {
            final reservation = managerState.currentReservation!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildClientDetailsCard(reservation),
                  const SizedBox(height: 16),
                  _buildReservationDetailsCard(reservation),
                  const SizedBox(height: 16),
                  _buildAssignedTablesCard(reservation),
                  if (![
                    'completed',
                    'cancelled',
                  ].contains(reservation.status)) ...[
                    const SizedBox(height: 24),
                    _buildManagerActionButtons(
                      reservation,
                      managerStateNotifier,
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

  Widget _buildClientDetailsCard(Reservation reservation) {
    final client = reservation.client;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations client',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.person,
              Text('Nom: ${client?.fullName ?? 'Non renseigné'}'),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.email,
              Text(
                'Email: ${client?.email ?? 'Non renseigné'}',
                style: client?.email == null
                    ? TextStyle(color: Colors.grey[600])
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.phone,
              Text(
                'Téléphone: ${client?.phone ?? 'Non renseigné'}',
                style: client?.phone == null
                    ? TextStyle(color: Colors.grey[600])
                    : null,
              ),
            ),
          ],
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
            const Text(
              'Détails de la réservation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.restaurant,
              Text(
                reservation.restaurant.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.calendar_today,
              Text(
                'Date: ${DateFormat('EEE dd/MM/yyyy', 'fr_FR').format(reservation.datetime)}',
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.access_time,
              Text(
                'Heure: ${DateFormat('HH:mm').format(reservation.datetime)}',
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.people,
              Text('Nombre de convives: ${reservation.numberOfGuests}'),
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

  Widget _buildAssignedTablesCard(Reservation reservation) {
    final tables = reservation.tables ?? const <Table>[];
    final emptyMessage = reservation.status == 'pending'
        ? 'Aucune table assignée (en attente de confirmation)'
        : 'Aucune table assignée';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tables assignées',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (tables.isEmpty)
          Text(emptyMessage, style: TextStyle(color: Colors.grey[600]))
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < tables.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _buildTableDetailRow(tables[i]),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTableDetailRow(Table table) {
    return Row(
      children: [
        const Icon(Icons.table_restaurant, size: 20),
        const SizedBox(width: 8),
        Text('Table ${table.tableNumber}'),
        const SizedBox(width: 16),
        Text(
          '(${table.capacity} places)',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildManagerActionButtons(
    Reservation reservation,
    ManagerStateNotifier managerStateNotifier,
  ) {
    final currentDateTime = ref
        .watch(simulatedTimeProvider)
        .maybeWhen(data: (data) => data, orElse: () => DateTime.now());

    final isPending = reservation.status == 'pending';
    final confirmOrCompleteLabel = isPending
        ? 'Confirmer et assigner tables'
        : 'Marquer comme terminée';

    final canComplete = !reservation.datetime.isAfter(currentDateTime);
    final isPrimaryActionEnabled = isPending || canComplete;
    final showServiceNotice = !isPending && !canComplete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: isPrimaryActionEnabled
              ? () async {
                  if (isPending) {
                    Navigator.pushNamed(
                      context,
                      '/manager/reservations/assign-tables',
                    );

                    await managerStateNotifier.getRestaurantTables();
                  } else {
                    _showCompleteReservationDialog(
                      reservation,
                      managerStateNotifier,
                    );
                  }
                }
              : null,
          icon: const Icon(Icons.check_circle),
          label: Text(confirmOrCompleteLabel),
        ),
        if (showServiceNotice) ...[
          const SizedBox(height: 8),
          const Text(
            'La réservation ne peut être terminée que durant son service ou après celui-ci',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () =>
              _showCancelReservationDialog(reservation, managerStateNotifier),
          icon: const Icon(Icons.cancel),
          label: const Text('Annuler'),
        ),
      ],
    );
  }

  void _showCompleteReservationDialog(
    Reservation reservation,
    ManagerStateNotifier managerStateNotifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer la réservation'),
        content: const Text(
          'Voulez-vous marquer cette réservation comme terminée ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await managerStateNotifier.completeReservation(
                id: reservation.id,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Réservation marquée comme terminée'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }

  void _showCancelReservationDialog(
    Reservation reservation,
    ManagerStateNotifier managerStateNotifier,
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
              await managerStateNotifier.cancelReservation(id: reservation.id);
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
