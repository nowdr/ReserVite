import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationFormFields extends StatelessWidget {
  final String restaurantName;
  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final Widget slotsSection;
  final int numberOfGuests;
  final VoidCallback? onGuestsMinus;
  final VoidCallback? onGuestsPlus;
  final String initialSpecialRequests;
  final ValueChanged<String> onSpecialRequestsChanged;
  final bool canSubmit;
  final VoidCallback? onSubmit;
  final String submitLabel;
  final IconData submitIcon;
  final bool showOvercapacityWarning;

  const ReservationFormFields({
    super.key,
    required this.restaurantName,
    required this.selectedDate,
    required this.onPickDate,
    required this.onPrevDay,
    required this.onNextDay,
    required this.slotsSection,
    required this.numberOfGuests,
    required this.onGuestsMinus,
    required this.onGuestsPlus,
    this.initialSpecialRequests = '',
    required this.onSpecialRequestsChanged,
    required this.canSubmit,
    required this.onSubmit,
    required this.submitLabel,
    required this.submitIcon,
    this.showOvercapacityWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RestaurantHeader(name: restaurantName),
        const SizedBox(height: 24),
        _DateRow(
          selectedDate: selectedDate,
          onPickDate: onPickDate,
          onPrevDay: onPrevDay,
          onNextDay: onNextDay,
        ),
        const Divider(),
        slotsSection,
        const SizedBox(height: 16),
        _GuestsRow(
          numberOfGuests: numberOfGuests,
          onMinus: onGuestsMinus,
          onPlus: onGuestsPlus,
        ),
        if (showOvercapacityWarning) ...[
          const SizedBox(height: 12),
          const _OvercapacityWarning(),
        ],
        const SizedBox(height: 32),
        _SpecialRequestsField(
          initialValue: initialSpecialRequests,
          onChanged: onSpecialRequestsChanged,
        ),
        const SizedBox(height: 32),
        _SubmitButton(
          label: submitLabel,
          icon: submitIcon,
          canSubmit: canSubmit,
          onSubmit: onSubmit,
        ),
      ],
    );
  }
}

class _RestaurantHeader extends StatelessWidget {
  final String name;

  const _RestaurantHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}

class _DateRow extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;

  const _DateRow({
    required this.selectedDate,
    required this.onPickDate,
    required this.onPrevDay,
    required this.onNextDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat(
      'EEEE d/MM/yyyy',
      'fr_FR',
    ).format(selectedDate);

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Date'),
                          Text(formattedDate, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.remove), onPressed: onPrevDay),
        IconButton(icon: const Icon(Icons.add), onPressed: onNextDay),
      ],
    );
  }
}

class _GuestsRow extends StatelessWidget {
  final int numberOfGuests;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  const _GuestsRow({
    required this.numberOfGuests,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.people),
      title: const Text('Nombre de convives'),
      subtitle: Text('$numberOfGuests'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.remove), onPressed: onMinus),
          IconButton(icon: const Icon(Icons.add), onPressed: onPlus),
        ],
      ),
    );
  }
}

class _SpecialRequestsField extends StatelessWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _SpecialRequestsField({
    required this.initialValue,
    required this.onChanged,
  });

  String? _validate(String? value) {
    if (value != null && value.isNotEmpty && value.length < 10) {
      return 'Les demandes spéciales doivent contenir au moins 10 caractères.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: const InputDecoration(
        labelText: 'Demandes spéciales (optionnel)',
        border: OutlineInputBorder(),
        hintText: 'Allergies, préférences...',
      ),
      maxLines: 3,
      validator: _validate,
      onChanged: onChanged,
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool canSubmit;
  final VoidCallback? onSubmit;

  const _SubmitButton({
    required this.label,
    required this.icon,
    required this.canSubmit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: canSubmit ? onSubmit : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _OvercapacityWarning extends StatelessWidget {
  const _OvercapacityWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Surréservation (capacité)',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'La capacité du restaurant pour ce créneau pourrait être insuffisante pour le nombre de convives demandé.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
