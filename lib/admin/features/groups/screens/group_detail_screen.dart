import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

enum _MemberView { cards, table }

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  _MemberView _memberView = _MemberView.cards;
  String? _memberError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<MemberModel> _membersFor(GroupModel group, List<MemberModel> members) {
    return members
        .where(
          (member) =>
              member.groupIds.contains(group.id) ||
              member.groupId == group.id ||
              (member.groupId == null && member.groupName == group.name),
        )
        .toList();
  }

  void _addMember(GroupModel group, bool isTamil) {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() {
        _memberError = isTamil
            ? 'பெயர் மற்றும் தொலைபேசி எண்ணை உள்ளிடவும்.'
            : 'Enter a name and phone number.';
      });
      return;
    }

    final member = MemberModel(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      initial: name.characters.first.toUpperCase(),
      email: '',
      phone: phone,
      groupName: group.name,
      groupId: group.id,
      status: 'Active',
    );
    ref
        .read(membersProvider.notifier)
        .update((members) => [member, ...members]);
    _nameController.clear();
    _phoneController.clear();
    setState(() => _memberError = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isTamil ? 'உறுப்பினர் சேர்க்கப்பட்டார்.' : 'Member added.',
        ),
      ),
    );
  }

  Future<void> _deleteMember(MemberModel member, bool isTamil) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTamil ? 'உறுப்பினரை நீக்கவா?' : 'Remove member?'),
        content: Text(
          isTamil
              ? '${member.name} உறுப்பினரை இந்தக் குழுவிலிருந்து நீக்கவா?'
              : 'Remove ${member.name} from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isTamil ? 'ரத்து' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(isTamil ? 'நீக்கு' : 'Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final groups = ref.read(groupsProvider);
    final remainingIds = member.groupIds.isNotEmpty
        ? member.groupIds.where((id) => id != widget.groupId).toList()
        : member.groupId != null && member.groupId != widget.groupId
        ? [member.groupId!]
        : <String>[];
    final remainingGroups = groups
        .where((group) => remainingIds.contains(group.id))
        .toList();
    ref
        .read(membersProvider.notifier)
        .update(
          (members) => members.map((item) {
            if (item.id != member.id) return item;
            return MemberModel(
              id: item.id,
              name: item.name,
              initial: item.initial,
              email: item.email,
              phone: item.phone,
              groupName: remainingGroups.isEmpty
                  ? 'No group assigned'
                  : remainingGroups.map((group) => group.name).join(', '),
              groupId: remainingIds.isEmpty ? null : remainingIds.first,
              groupIds: remainingIds,
              status: item.status,
              photoUrl: item.photoUrl,
              fullName: item.fullName,
              dateOfBirth: item.dateOfBirth,
              address: item.address,
              customFields: item.customFields,
              documents: item.documents,
              joinedAt: item.joinedAt,
            );
          }).toList(),
        );
  }

  Future<void> _editMember(MemberModel member, bool isTamil) async {
    final nameController = TextEditingController(text: member.name);
    final phoneController = TextEditingController(text: member.phone);
    final updated = await showDialog<MemberModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTamil ? 'உறுப்பினரைத் திருத்து' : 'Edit member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: isTamil ? 'பெயர்' : 'Name with initial',
              ),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: isTamil ? 'தொலைபேசி' : 'Phone',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTamil ? 'ரத்து' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty || phone.isEmpty) return;
              Navigator.pop(
                context,
                MemberModel(
                  id: member.id,
                  name: name,
                  initial: name.characters.first.toUpperCase(),
                  email: member.email,
                  phone: phone,
                  groupName: member.groupName,
                  groupId: member.groupId,
                  groupIds: member.groupIds,
                  status: member.status,
                  photoUrl: member.photoUrl,
                  fullName: member.fullName,
                  dateOfBirth: member.dateOfBirth,
                  address: member.address,
                  customFields: member.customFields,
                  documents: member.documents,
                  joinedAt: member.joinedAt,
                ),
              );
            },
            child: Text(isTamil ? 'சேமி' : 'Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    phoneController.dispose();
    if (updated == null || !mounted) return;
    ref
        .read(membersProvider.notifier)
        .update(
          (members) => [
            for (final item in members)
              if (item.id == updated.id) updated else item,
          ],
        );
  }

  Future<void> _deleteGroup(GroupModel group, bool isTamil) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTamil ? 'குழுவை நீக்கவா?' : 'Delete group?'),
        content: Text(
          isTamil
              ? '"${group.name}" குழுவை நிரந்தரமாக நீக்கவா?'
              : 'Permanently delete "${group.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isTamil ? 'ரத்து' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(isTamil ? 'குழுவை நீக்கு' : 'Delete group'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref
        .read(membersProvider.notifier)
        .update(
          (members) => members
              .where(
                (member) =>
                    member.groupId != group.id &&
                    !(member.groupId == null && member.groupName == group.name),
              )
              .toList(),
        );
    ref
        .read(groupsProvider.notifier)
        .update(
          (groups) => groups.where((item) => item.id != group.id).toList(),
        );
    context.go('/app/groups');
  }

  void _copyJoinLink(GroupModel group, bool isTamil) {
    final link = 'https://app.airotechhub.lk/group/${group.code}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isTamil ? 'சேரும் இணைப்பு நகலெடுக்கப்பட்டது.' : 'Join link copied.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = ref
        .watch(groupsProvider)
        .where((item) => item.id == widget.groupId)
        .firstOrNull;
    final isTamil = ref.watch(languageProvider) == 'ta';
    final colors = Theme.of(context).colorScheme;

    if (group == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isTamil ? 'குழு கிடைக்கவில்லை' : 'Group not found'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/app/groups'),
              child: Text(
                isTamil ? 'குழுக்களுக்குத் திரும்பு' : 'Back to groups',
              ),
            ),
          ],
        ),
      );
    }

    final members = _membersFor(group, ref.watch(membersProvider));
    final joinLink = 'https://app.airotechhub.lk/group/${group.code}';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _breadcrumb(group, isTamil, colors),
              const SizedBox(height: 12),
              _joinLinkCard(group, joinLink, isTamil, colors),
              const SizedBox(height: 16),
              Text(
                isTamil
                    ? 'ஒப்புதலுக்காக காத்திருக்கிறது'
                    : 'Waiting for approval',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    isTamil
                        ? 'யாரும் காத்திருக்கவில்லை.'
                        : 'No one is waiting.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _addMemberForm(group, isTamil, colors),
              const SizedBox(height: 12),
              _membersSection(group, members, isTamil, colors),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _deleteGroup(group, isTamil),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(isTamil ? 'குழுவை நீக்கு' : 'Delete group'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _breadcrumb(GroupModel group, bool isTamil, ColorScheme colors) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        InkWell(
          onTap: () => context.go('/app/groups'),
          child: Text(
            isTamil ? 'குழுக்கள்' : 'Groups',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
        Icon(Icons.chevron_right_rounded, size: 18, color: colors.onSurfaceVariant),
        Text(
          group.name,
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _joinLinkCard(
    GroupModel group,
    String joinLink,
    bool isTamil,
    ColorScheme colors,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTamil ? 'சேரும் இணைப்பு' : 'Join link',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              isTamil
                  ? 'இந்த இணைப்பைப் பகிரவும். சேர விரும்புபவரை அவர்கள் பதிவு செய்வதற்கு முன் நீங்கள் ஏற்க வேண்டும்.'
                  : 'Share this link. A person asks to join, and you accept them before they can sign in.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final linkBox = Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: SelectableText(
                    joinLink,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
                final copyButton = OutlinedButton(
                  onPressed: () => _copyJoinLink(group, isTamil),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(isTamil ? 'இணைப்பை நகலெடு' : 'Copy link'),
                );
                if (constraints.maxWidth < 480) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      linkBox,
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: copyButton,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: linkBox),
                    const SizedBox(width: 8),
                    copyButton,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _addMemberForm(GroupModel group, bool isTamil, ColorScheme colors) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final nameField = _memberTextField(
                  label: isTamil
                      ? 'பெயர் மற்றும் முதலெழுத்து'
                      : 'Name with initial',
                  controller: _nameController,
                  errorText: _memberError,
                );
                final phoneField = _memberTextField(
                  label: isTamil ? 'தொலைபேசி' : 'Phone',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                );
                final addButton = FilledButton(
                  onPressed: () => _addMember(group, isTamil),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size(0, 42),
                  ),
                  child: Text(isTamil ? 'உறுப்பினரைச் சேர்' : 'Add member'),
                );
                if (constraints.maxWidth < 650) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      nameField,
                      const SizedBox(height: 10),
                      phoneField,
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerRight, child: addButton),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: nameField),
                    const SizedBox(width: 10),
                    Expanded(child: phoneField),
                    const SizedBox(width: 10),
                    addButton,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberTextField({
    required String label,
    required TextEditingController controller,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (_) {
            if (_memberError != null) setState(() => _memberError = null);
          },
          decoration: InputDecoration(
            isDense: true,
            errorText: errorText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _membersSection(
    GroupModel group,
    List<MemberModel> members,
    bool isTamil,
    ColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isTamil ? 'உறுப்பினர்கள்' : 'Members',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ToggleButtons(
              isSelected: [
                _memberView == _MemberView.cards,
                _memberView == _MemberView.table,
              ],
              onPressed: (index) => setState(
                () => _memberView = index == 0
                    ? _MemberView.cards
                    : _MemberView.table,
              ),
              borderRadius: BorderRadius.circular(9),
              borderColor: colors.outlineVariant,
              selectedBorderColor: AppColors.accent,
              fillColor: AppColors.accent,
              color: colors.onSurface,
              selectedColor: Colors.white,
              constraints: const BoxConstraints(minWidth: 58, minHeight: 36),
              children: [
                Text(isTamil ? 'அட்டைகள்' : 'Cards'),
                Text(isTamil ? 'அட்டவணை' : 'Table'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (members.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isTamil ? 'உறுப்பினர்கள் இல்லை.' : 'No members in this group.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          )
        else if (_memberView == _MemberView.cards)
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 580
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 82,
                ),
                itemCount: members.length,
                itemBuilder: (context, index) =>
                    _memberCard(members[index], isTamil, colors),
              );
            },
          )
        else
          _memberTable(members, isTamil, colors),
      ],
    );
  }

  Widget _memberCard(MemberModel member, bool isTamil, ColorScheme colors) {
    final initial = member.name.isEmpty
        ? '?'
        : member.name.characters.first.toUpperCase();
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.surfaceContainerHighest,
              child: Text(initial, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    member.phone,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showMemberDetails(member, isTamil),
              tooltip: isTamil ? 'விவரங்கள்' : 'View details',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              iconSize: 17,
              icon: const Icon(Icons.visibility_outlined),
            ),
            IconButton(
              onPressed: () => _editMember(member, isTamil),
              tooltip: isTamil ? 'திருத்து' : 'Edit',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              iconSize: 17,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: () => _deleteMember(member, isTamil),
              tooltip: isTamil ? 'நீக்கு' : 'Remove',
              color: AppColors.danger,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              iconSize: 17,
              icon: const Icon(Icons.delete_forever_outlined),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberDetails(MemberModel member, bool isTamil) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: Text(
          '${isTamil ? 'தொலைபேசி' : 'Phone'}: ${member.phone}\n'
          '${isTamil ? 'மின்னஞ்சல்' : 'Email'}: ${member.email.isEmpty ? '—' : member.email}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTamil ? 'மூடு' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _memberTable(
    List<MemberModel> members,
    bool isTamil,
    ColorScheme colors,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(isTamil ? 'பெயர்' : 'Name')),
          DataColumn(label: Text(isTamil ? 'தொலைபேசி' : 'Phone')),
          DataColumn(label: Text(isTamil ? 'செயல்கள்' : 'Actions')),
        ],
        rows: [
          for (final member in members)
            DataRow(
              cells: [
                DataCell(Text(member.name)),
                DataCell(Text(member.phone)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showMemberDetails(member, isTamil),
                        tooltip: isTamil ? 'விவரங்கள்' : 'View details',
                        icon: const Icon(Icons.visibility_outlined),
                        color: colors.onSurface,
                      ),
                      IconButton(
                        onPressed: () => _editMember(member, isTamil),
                        tooltip: isTamil ? 'திருத்து' : 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        color: colors.onSurface,
                      ),
                      IconButton(
                        onPressed: () => _deleteMember(member, isTamil),
                        tooltip: isTamil ? 'நீக்கு' : 'Remove',
                        icon: const Icon(Icons.delete_forever_outlined),
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
