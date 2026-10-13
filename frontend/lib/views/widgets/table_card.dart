import 'package:flutter/material.dart' hide Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_f01/models/table.dart';
import 'package:prbd_2526_f01/providers/manager_state_provider.dart';

class TableCard extends ConsumerStatefulWidget {
  final Table table;

  TableCard({required this.table});

  @override
  ConsumerState<TableCard> createState() => _TableCardState();
}

class _TableCardState extends ConsumerState<TableCard> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(managerStateProvider);
    final selectedTableIds = asyncState.value?.selectedTablesIds ?? {};
    final table = widget.table;
    final isSelected = selectedTableIds.contains(table.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: table.isAvailable!
            ? (_) => ref
                  .read(managerStateProvider.notifier)
                  .toggleTableSelection(table.id)
            : null,
        title: Text(
          'Table ${table.tableNumber}',
          style: TextStyle(
            decoration: table.isAvailable! ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          table.isAvailable!
              ? 'Capacité: ${table.capacity} personne${table.capacity > 1 ? 's' : ''}'
              : 'Occupée pour ce service',
          style: TextStyle(
            color: table.isAvailable! ? null : Colors.red.shade300,
          ),
        ),
        secondary: const Icon(Icons.table_restaurant),
      ),
    );
  }
}
