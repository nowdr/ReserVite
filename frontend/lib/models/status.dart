import 'package:flutter/material.dart';

enum Status {
  pending(
    'En attente',
    Icon(Icons.pending, size: 32, color: Colors.orange),
    Colors.orange,
  ),
  confirmed(
    'Confirmée',
    Icon(Icons.check_circle, size: 32, color: Colors.green),
    Colors.green,
  ),
  completed(
    'Terminée',
    Icon(Icons.event_available, size: 32, color: Colors.blue),
    Colors.blue,
  ),
  cancelled(
    'Annulée',
    Icon(Icons.cancel, size: 32, color: Colors.red),
    Colors.red,
  );

  final String label;
  final Icon icon;
  final Color color;

  const Status(this.label, this.icon, this.color);
}
