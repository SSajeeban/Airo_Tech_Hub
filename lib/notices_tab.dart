import 'package:material_ui/material_ui.dart';

import 'mock_data.dart';
import 'app_settings.dart';

class NoticesTab extends StatelessWidget {
  final List<Notice> notices;

  const NoticesTab({super.key, required this.notices});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final translate = AppSettings.instance.tr;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          translate('Notice board'),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ).copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: 12),
        if (notices.isEmpty)
          Text(
            translate('No notices for you yet.'),
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
          )
        else
          for (final n in notices)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                title: Text(
                  translate(n.title),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(translate(n.body)),
              ),
            ),
      ],
    );
  }
}
