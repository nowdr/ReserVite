import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_f01/models/reservation.dart';
import 'package:prbd_2526_f01/models/status.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onTap;
  final bool isManager;

  ReservationCard({
    required this.reservation,
    required this.onTap,
    required this.isManager,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Tooltip(
                message: Status.values.byName(reservation.status).label,
                child: Status.values.byName(reservation.status).icon,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isManager
                          ? reservation.client!.fullName
                          : reservation.restaurant.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isManager ? Icons.restaurant : Icons.location_on,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isManager
                              ? reservation.restaurant.name
                              : reservation.restaurant.city!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            "EEE dd/MM/yy 'à' HH:mm",
                            'fr_FR',
                          ).format(reservation.datetime),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.people, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${reservation.numberOfGuests} convive${reservation.numberOfGuests > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
