import 'package:flutter/material.dart';
import 'package:prbd_2526_f01/models/reservation.dart';

enum EmptySlotsReason { closed, userBooked, none }

class SlotsSection extends StatelessWidget {
  final bool loading;
  final List<AvailableSlot> slots;
  final String? selectedTime;
  final EmptySlotsReason emptyReason;
  final ValueChanged<String> onSelect;

  const SlotsSection({
    super.key,
    required this.loading,
    required this.slots,
    required this.selectedTime,
    required this.emptyReason,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (slots.isEmpty) {
      return _EmptyState(reason: emptyReason);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Créneaux disponibles',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: slots
              .map(
                (slot) => _SlotChip(
                  slot: slot,
                  selected: slot.time == selectedTime,
                  onTap: () => onSelect(slot.time),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  final AvailableSlot slot;
  final bool selected;
  final VoidCallback onTap;

  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        child: Center(child: Text(slot.time)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final EmptySlotsReason reason;

  const _EmptyState({required this.reason});

  String get _message {
    switch (reason) {
      case EmptySlotsReason.closed:
        return 'Le restaurant est fermé ce jour-là.';
      case EmptySlotsReason.userBooked:
        return 'Vous avez déjà une réservation couvrant tous les services de ce jour.';
      case EmptySlotsReason.none:
        return 'Aucun créneau futur disponible pour cette date.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _message,
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
