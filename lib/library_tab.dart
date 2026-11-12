import 'package:flutter/material.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  DateTime? _from;
  DateTime? _to;
  bool _gridView = false;

  String _fmt(DateTime? d) {
    if (d == null) return 'mm/dd/yyyy';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$m/$day/${d.year}';
  }

  Future<void> _pick(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1B9A85);
    final navy = Theme.of(context).colorScheme.onSurface;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Library',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: navy,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(true),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text('From: ${_fmt(_from)}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(false),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text('To: ${_fmt(_to)}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, icon: Icon(Icons.grid_view)),
              ButtonSegment(value: false, icon: Icon(Icons.list)),
            ],
            selected: {_gridView},
            onSelectionChanged: (s) => setState(() => _gridView = s.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: teal.withValues(alpha: 0.15),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              'Nothing in this folder.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
