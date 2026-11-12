import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedGroup = 'All groups';
  bool _showCards = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _deleteMember(MemberModel member) {
    ref
        .read(membersProvider.notifier)
        .update(
          (members) => members.where((item) => item.id != member.id).toList(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${member.name} removed from the directory.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider);
    final groups = ref.watch(groupsProvider);
    final groupOptions = ['All groups', ...groups.map((group) => group.name)];
    if (!groupOptions.contains(_selectedGroup)) _selectedGroup = 'All groups';
    final selectedGroup = groups
        .where((group) => group.name == _selectedGroup)
        .firstOrNull;
    final filteredMembers = members.where((member) {
      final matchesGroup =
          _selectedGroup == 'All groups' ||
          (selectedGroup != null &&
              (member.groupIds.contains(selectedGroup.id) ||
                  member.groupId == selectedGroup.id)) ||
          member.groupName == _selectedGroup;
      final searchable =
          '${member.name} ${member.fullName ?? ''} ${member.email} ${member.phone} ${member.groupName}'
              .toLowerCase();
      return matchesGroup && searchable.contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final padding = compact ? 16.0 : 28.0;
          final columns = constraints.maxWidth > 1100
              ? 3
              : constraints.maxWidth > 720
              ? 2
              : 1;
          return ListView(
            padding: EdgeInsets.fromLTRB(padding, 18, padding, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Members Directory',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your students and member profiles.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  if (!compact)
                    FilledButton.icon(
                      onPressed: () => context.push('/app/members/new'),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Create Member'),
                    ),
                ],
              ),
              if (compact) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/app/members/new'),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Create Member'),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: compact ? constraints.maxWidth - 32 : 330,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search members...',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: compact ? constraints.maxWidth - 32 : 240,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedGroup,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Group',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: groupOptions
                          .map(
                            (group) => DropdownMenuItem(
                              value: group,
                              child: Text(
                                group,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedGroup = value);
                        }
                      },
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.grid_view_rounded),
                        label: Text('Cards'),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.table_rows_rounded),
                        label: Text('Table'),
                      ),
                    ],
                    selected: {_showCards},
                    onSelectionChanged: (values) =>
                        setState(() => _showCards = values.first),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (filteredMembers.isEmpty)
                _EmptyMembers(onCreate: () => context.push('/app/members/new'))
              else if (_showCards)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredMembers.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 196,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, index) => _MemberCard(
                    member: filteredMembers[index],
                    onView: () => context.push(
                      '/app/members/${filteredMembers[index].id}',
                    ),
                    onDelete: () => _deleteMember(filteredMembers[index]),
                  ),
                )
              else
                _MembersTable(
                  members: filteredMembers,
                  onView: (member) => context.push('/app/members/${member.id}'),
                  onDelete: _deleteMember,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onView,
    required this.onDelete,
  });

  final MemberModel member;
  final VoidCallback onView;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _MemberAvatar(member: member, radius: 25),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        member.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Member actions',
                  onSelected: (value) {
                    if (value == 'view') onView();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'view', child: Text('View member')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Remove member'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoLine(icon: Icons.groups_2_outlined, text: member.groupName),
            const SizedBox(height: 8),
            _InfoLine(icon: Icons.phone_outlined, text: member.phone),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersTable extends StatelessWidget {
  const _MembersTable({
    required this.members,
    required this.onView,
    required this.onDelete,
  });

  final List<MemberModel> members;
  final ValueChanged<MemberModel> onView;
  final ValueChanged<MemberModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Member')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Group')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: members
              .map(
                (member) => DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 220,
                        child: Row(
                          children: [
                            _MemberAvatar(member: member, radius: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    member.email,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(member.phone)),
                    DataCell(Text(member.groupName)),
                    DataCell(_StatusBadge(status: member.status)),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'View member',
                            onPressed: () => onView(member),
                            icon: const Icon(Icons.visibility_outlined),
                          ),
                          IconButton(
                            tooltip: 'Remove member',
                            onPressed: () => onDelete(member),
                            icon: const Icon(Icons.delete_forever_outlined),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.radius});

  final MemberModel member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photo = member.photoUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.brandBlue.withValues(alpha: 0.12),
      backgroundImage: photo != null && photo.startsWith('http')
          ? NetworkImage(photo)
          : null,
      child: photo == null || !photo.startsWith('http')
          ? Text(
              member.initial.isEmpty
                  ? member.name.characters.first
                  : member.initial,
              style: const TextStyle(
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.brandBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isEmpty ? 'Not provided' : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final active = status.toLowerCase() == 'active';
    final color = active ? AppColors.success : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 54),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No members found',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            'Try another search or add your first member.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Create Member'),
          ),
        ],
      ),
    );
  }
}
