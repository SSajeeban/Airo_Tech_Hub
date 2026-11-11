import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

enum _GroupView { cards, table }

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _GroupView _view = _GroupView.cards;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteGroup(GroupModel group, bool isTamil) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTamil ? 'குழுவை நீக்கவா?' : 'Delete group?'),
        content: Text(
          isTamil
              ? '"${group.name}" குழுவை நீக்க விரும்புகிறீர்களா?'
              : 'Are you sure you want to delete "${group.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isTamil ? 'ரத்து' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(isTamil ? 'நீக்கு' : 'Delete'),
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

  void _copyJoinLink(GroupModel group, bool isTamil) {
    Clipboard.setData(
      ClipboardData(text: 'https://airotechhub.lk/group/${group.code}'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isTamil
              ? '"${group.name}" குழுவின் இணைப்பு நகலெடுக்கப்பட்டது.'
              : 'Join link for "${group.name}" copied.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isTamil ? 'குழுக்கள்' : 'Groups',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ToggleButtons(
                    isSelected: [
                      _view == _GroupView.cards,
                      _view == _GroupView.table,
                    ],
                    onPressed: (index) => setState(
                      () => _view = index == 0
                          ? _GroupView.cards
                          : _GroupView.table,
                    ),
                    borderRadius: BorderRadius.circular(9),
                    borderColor: colors.outlineVariant,
                    selectedBorderColor: AppColors.accent,
                    fillColor: AppColors.accent,
                    color: colors.onSurface,
                    selectedColor: Colors.white,
                    constraints: const BoxConstraints(
                      minWidth: 68,
                      minHeight: 40,
                    ),
                    children: [
                      Text(isTamil ? 'அட்டைகள்' : 'Cards'),
                      Text(isTamil ? 'அட்டவணை' : 'Table'),
                    ],
                  ),
                ],
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
                        hintText: isTamil
                            ? 'குழுக்களைத் தேடவும்'
                            : 'Search groups',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: isTamil ? 'அழி' : 'Clear',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close),
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
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(isTamil ? 'உருவாக்கு' : 'Create'),
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
                    isTamil ? 'குழுக்கள் எதுவும் இல்லை' : 'No groups found',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                )
              : _view == _GroupView.cards
              ? LayoutBuilder(
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
                          _groupCard(filtered[index], isTamil, colors),
                    );
                  },
                )
              : _groupTable(filtered, isTamil),
        ),
      ],
    );
  }

  Widget _groupCard(GroupModel group, bool isTamil, ColorScheme colors) {
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
                  icon: Icons.visibility_outlined,
                  tooltip: isTamil ? 'விவரங்கள்' : 'View details',
                  onPressed: () => context.push('/app/groups/${group.id}'),
                ),
                _actionButton(
                  icon: Icons.copy_outlined,
                  tooltip: isTamil ? 'இணைப்பு நகலெடு' : 'Copy join link',
                  onPressed: () => _copyJoinLink(group, isTamil),
                ),
                _actionButton(
                  icon: Icons.edit_outlined,
                  tooltip: isTamil ? 'திருத்து' : 'Edit',
                  onPressed: () =>
                      context.push('/app/groups/edit', extra: group),
                ),
                _actionButton(
                  icon: Icons.delete_outline,
                  tooltip: isTamil ? 'நீக்கு' : 'Delete',
                  color: AppColors.danger,
                  onPressed: () => _deleteGroup(group, isTamil),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${group.memberCount} ${isTamil ? 'உறுப்பினர்கள்' : 'Members'}',
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

  Widget _groupTable(List<GroupModel> groups, bool isTamil) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            DataColumn(label: Text(isTamil ? 'பெயர்' : 'Name')),
            DataColumn(label: Text(isTamil ? 'விளக்கம்' : 'Description')),
            DataColumn(label: Text(isTamil ? 'உறுப்பினர்கள்' : 'Members')),
            DataColumn(label: Text(isTamil ? 'செயல்கள்' : 'Actions')),
          ],
          rows: [
            for (final group in groups)
              DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Text(
                        group.description.isEmpty ? '—' : group.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text('${group.memberCount}')),
                  DataCell(
                    Row(
                      children: [
                        _actionButton(
                          icon: Icons.visibility_outlined,
                          tooltip: isTamil ? 'விவரங்கள்' : 'View details',
                          onPressed: () =>
                              context.push('/app/groups/${group.id}'),
                        ),
                        _actionButton(
                          icon: Icons.copy_outlined,
                          tooltip: isTamil
                              ? 'இணைப்பு நகலெடு'
                              : 'Copy join link',
                          onPressed: () => _copyJoinLink(group, isTamil),
                        ),
                        _actionButton(
                          icon: Icons.edit_outlined,
                          tooltip: isTamil ? 'திருத்து' : 'Edit',
                          onPressed: () =>
                              context.push('/app/groups/edit', extra: group),
                        ),
                        _actionButton(
                          icon: Icons.delete_outline,
                          tooltip: isTamil ? 'நீக்கு' : 'Delete',
                          color: AppColors.danger,
                          onPressed: () => _deleteGroup(group, isTamil),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
