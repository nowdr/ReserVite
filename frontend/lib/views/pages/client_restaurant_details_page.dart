import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_f01/models/service.dart';
import 'package:prbd_2526_f01/providers/client_state_provider.dart';
import 'package:prbd_2526_f01/views/pages/client_add_reservation_page.dart';
import 'package:prbd_2526_f01/views/widgets/data_error_widget.dart';
import 'package:prbd_2526_f01/views/widgets/loading_widget.dart';
import 'package:prbd_2526_f01/views/widgets/page_app_bar.dart';

class ClientRestaurantDetailsPage extends ConsumerWidget {
  static const List<(String, int)> _weekDays = [
    ('Lundi', 1),
    ('Mardi', 2),
    ('Mercredi', 3),
    ('Jeudi', 4),
    ('Vendredi', 5),
    ('Samedi', 6),
    ('Dimanche', 7),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(clientStateProvider);

    return Scaffold(
      appBar: PageAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: 'Détails du restaurant',
        onRefreshPressed: () =>
            ref.read(clientStateProvider.notifier).refreshRestaurant(),
      ),
      body: SafeArea(
        child: asyncState.when(
          data: (clientState) {
            final currentRestaurant = clientState.currentRestaurant!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentRestaurant.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (currentRestaurant.rating != null) ...[
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(currentRestaurant.rating!.toStringAsFixed(1)),
                        const SizedBox(width: 16),
                      ],
                      if (currentRestaurant.priceRange != null) ...[
                        Text('€' * currentRestaurant.priceRange!),
                        const SizedBox(width: 16),
                      ],
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text(currentRestaurant.city!),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          currentRestaurant.address!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  if (currentRestaurant.description != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(currentRestaurant.description!),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Horaires',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._buildOpeningDaysColumns(currentRestaurant.services),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientAddReservationPage(
                              restaurant: currentRestaurant,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Réserver'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
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

  String _formatToHourMinute(String timeString) {
    final parts = timeString.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeString;
  }

  List<Widget> _buildOpeningDaysColumns(List<Service>? services) {
    final openDays = _weekDays
        .where(
          (day) =>
              (services ?? []).any((service) => service.dayOfWeek == day.$2),
        )
        .toList();
    if (openDays.isEmpty) return const [];

    final mid = (openDays.length / 2).ceil();
    final left = openDays.sublist(0, mid);
    final right = openDays.sublist(mid);

    Widget column(List<(String, int)> namedWeekDays) => Expanded(
      child: Column(
        children: namedWeekDays
            .map((day) => _buildDayScheduleRow(day.$1, day.$2, services))
            .toList(),
      ),
    );

    return [
      column(left),
      if (right.isNotEmpty) ...[const SizedBox(width: 16), column(right)],
    ];
  }

  Widget _buildDayScheduleRow(
    String dayName,
    int dayIndex,
    List<Service>? services,
  ) {
    final timeSlots = (services ?? [])
        .where((service) => service.dayOfWeek == dayIndex)
        .map(
          (service) =>
              '${_formatToHourMinute(service.startTime)} - ${_formatToHourMinute(service.endTime)}',
        )
        .toList();
    final scheduleText = timeSlots.join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              dayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              scheduleText,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
