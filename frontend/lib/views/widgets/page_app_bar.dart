import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_f01/providers/simulated_time_provider.dart';

class PageAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget> actionsBeforeRefresh;
  final List<Widget> actionsAfterRefresh;
  final bool showRefreshButton;
  final VoidCallback? onRefreshPressed;
  final String refreshTooltip;
  final String simulatedTimeTooltip;

  const PageAppBar({
    super.key,
    required this.title,
    this.leading,
    this.automaticallyImplyLeading = false,
    this.actionsBeforeRefresh = const [],
    this.actionsAfterRefresh = const [],
    this.showRefreshButton = true,
    this.onRefreshPressed,
    this.refreshTooltip = 'Rafraîchir les données',
    this.simulatedTimeTooltip =
        'Date/heure simulée utilisée pour les tests.\nCliquez pour modifier.',
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final simulatedTime = ref
        .watch(simulatedTimeProvider)
        .maybeWhen(data: (date) => date, orElse: () => DateTime.now());

    final trailingActions = <Widget>[
      ...actionsBeforeRefresh,
      if (showRefreshButton)
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: refreshTooltip,
          onPressed: onRefreshPressed ?? () {},
        ),
      ...actionsAfterRefresh,
    ];

    return AppBar(
      leading: leading,
      title: Text(title),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: trailingActions,
      elevation: 2,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: Align(
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Tooltip(
              message: simulatedTimeTooltip,
              child: InkWell(
                onTap: () => _openSimulatedTimeDialog(context, simulatedTime),
                child: Text(
                  DateFormat(
                    'EEEE dd/MM/yyyy HH:mm',
                    'fr_FR',
                  ).format(simulatedTime),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openSimulatedTimeDialog(BuildContext context, DateTime initial) {
    showDialog(
      context: context,
      builder: (_) => _SimulatedTimeDialog(initial: initial),
    );
  }
}

class _SimulatedTimeDialog extends ConsumerStatefulWidget {
  final DateTime initial;

  const _SimulatedTimeDialog({required this.initial});

  @override
  ConsumerState<_SimulatedTimeDialog> createState() =>
      _SimulatedTimeDialogState();
}

class _SimulatedTimeDialogState extends ConsumerState<_SimulatedTimeDialog> {
  late DateTime _date;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _date = DateTime(initial.year, initial.month, initial.day);
    _time = TimeOfDay.fromDateTime(initial);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(_date.year + 10),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _validate() async {
    final combined = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    await ref.read(simulatedTimeProvider.notifier).setSimulatedTime(combined);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clear() async {
    await ref.read(simulatedTimeProvider.notifier).clearSimulatedTime();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le temps simulé'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            subtitle: Text(
              DateFormat('EEEE dd/MM/yyyy', 'fr_FR').format(_date),
            ),
            onTap: _pickDate,
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Heure'),
            subtitle: Text(_time.format(context)),
            onTap: _pickTime,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(onPressed: _clear, child: const Text('Effacer (null)')),
        ElevatedButton(onPressed: _validate, child: const Text('Valider')),
      ],
    );
  }
}
