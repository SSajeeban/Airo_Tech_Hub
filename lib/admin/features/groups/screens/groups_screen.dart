import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/localization/admin_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteGroup(GroupModel group, String language) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          adminUiText(
            language,
            english: 'Delete group?',
            tamil: 'குழுவை நீக்கவா?',
            sinhala: 'කණ්ඩායම මකා දමන්නද?',
          ),
        ),
        content: Text(
          adminUiText(
            language,
            english: 'Are you sure you want to delete "${group.name}"?',
            tamil: '"${group.name}" குழுவை நீக்க விரும்புகிறீர்களா?',
            sinhala: '"${group.name}" කණ්ඩායම මකා දැමීමට ඔබට විශ්වාසද?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              adminUiText(
                language,
                english: 'Cancel',
                tamil: 'ரத்து',
                sinhala: 'අවලංගු කරන්න',
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(
              adminUiText(
                language,
                english: 'Delete',
                tamil: 'நீக்கு',
                sinhala: 'මකන්න',
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref
        .read(groupsProvider.notifier)
        .update(
          (groups) => groups.where((item) => item.id != group.id).toList(),
        );
  }

  void _copyJoinLink(GroupModel group, String language) {
    Clipboard.setData(
      ClipboardData(text: 'https://airotechhub.lk/group/${group.code}'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          adminUiText(
            language,
            english: 'Join link for "${group.name}" copied.',
            tamil: '"${group.name}" குழுவின் இணைப்பு நகலெடுக்கப்பட்டது.',
            sinhala: '"${group.name}" කණ්ඩායමේ සම්බන්ධකය පිටපත් කරන ලදී.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider);
    final language = ref.watch(languageProvider);
    final colors = Theme.of(context).colorScheme;
    final filtered = groups.where((group) {
      final query = _searchQuery.toLowerCase();
      return group.name.toLowerCase().contains(query) ||
          group.code.toLowerCase().contains(query) ||
          group.description.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                adminUiText(
                  language,
                  english: 'Groups',
                  tamil: 'குழுக்கள்',
                  sinhala: 'කණ්ඩායම්',
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: adminUiText(
                          language,
                          english: 'Search groups',
                          tamil: 'குழுக்களைத் தேடவும்',
                          sinhala: 'කණ්ඩායම් සොයන්න',
                        ),
                        prefixIcon: const Icon(AppIcons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: adminUiText(
                                  language,
                                  english: 'Clear',
                                  tamil: 'அழி',
                                  sinhala: 'මකන්න',
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => context.push('/app/groups/new'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(AppIcons.add, size: 18),
                    label: Text(
                      adminUiText(
                        language,
                        english: 'Create',
                        tamil: 'உருவாக்கு',
                        sinhala: 'සාදන්න',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    adminUiText(
                      language,
                      english: 'No groups found',
                      tamil: 'குழுக்கள் எதுவும் இல்லை',
                      sinhala: 'කණ්ඩායම් හමු නොවීය',
                    ),
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1000
                        ? 3
                        : constraints.maxWidth >= 650
                        ? 2
                        : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 142,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _groupCard(filtered[index], language, colors),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _groupCard(GroupModel group, String language, ColorScheme colors) {
    final initial = group.name.trim().isEmpty
        ? '?'
        : group.name.trim()[0].toUpperCase();
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.surfaceContainerHighest,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (group.description.isNotEmpty)
                        Text(
                          group.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                _actionButton(
                  icon: AppIcons.view,
                  tooltip: adminUiText(
                    language,
                    english: 'View details',
                    tamil: 'விவரங்கள்',
                    sinhala: 'විස්තර බලන්න',
                  ),
                  onPressed: () => context.push('/app/groups/${group.id}'),
                ),
                _actionButton(
                  icon: AppIcons.copy,
                  tooltip: adminUiText(
                    language,
                    english: 'Copy join link',
                    tamil: 'இணைப்பு நகலெடு',
                    sinhala: 'එක්වීමේ සබැඳිය පිටපත් කරන්න',
                  ),
                  onPressed: () => _copyJoinLink(group, language),
                ),
                _actionButton(
                  icon: AppIcons.edit,
                  tooltip: adminUiText(
                    language,
                    english: 'Edit',
                    tamil: 'திருத்து',
                    sinhala: 'සංස්කරණය කරන්න',
                  ),
                  onPressed: () =>
                      context.push('/app/groups/edit', extra: group),
                ),
                _actionButton(
                  icon: AppIcons.delete,
                  tooltip: adminUiText(
                    language,
                    english: 'Delete',
                    tamil: 'நீக்கு',
                    sinhala: 'මකන්න',
                  ),
                  color: AppColors.danger,
                  onPressed: () => _deleteGroup(group, language),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${group.memberCount} ${adminUiText(language, english: 'Members', tamil: 'உறுப்பினர்கள்', sinhala: 'සාමාජිකයින්')}',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: EdgeInsets.zero,
      iconSize: 18,
      color: color,
      icon: Icon(icon),
    );
  }
}
