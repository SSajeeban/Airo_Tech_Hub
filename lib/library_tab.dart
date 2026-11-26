import 'package:material_ui/material_ui.dart';

import 'app_settings.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  DateTime? _from;
  DateTime? _to;
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
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, child) {
        final colors = Theme.of(context).colorScheme;
        final translate = AppSettings.instance.tr;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              translate('Library'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ).copyWith(color: colors.onSurface),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('${translate('From')}: ${_fmt(_from)}'),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('${translate('To')}: ${_fmt(_to)}'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Center(
                child: Text(
                  translate('Nothing in this folder.'),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
