import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/admin_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
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

  void _addMember(GroupModel group, String language) {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() {
        _memberError = adminUiText(
          language,
          english: 'Enter a name and phone number.',
          tamil: 'பெயர் மற்றும் தொலைபேசி எண்ணை உள்ளிடவும்.',
          sinhala: 'නම සහ දුරකථන අංකය ඇතුළත් කරන්න.',
        );
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
          adminUiText(
            language,
            english: 'Member added.',
            tamil: 'உறுப்பினர் சேர்க்கப்பட்டார்.',
            sinhala: 'සාමාජිකයා එක් කරන ලදී.',
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMember(MemberModel member, String language) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          adminUiText(
            language,
            english: 'Remove member?',
            tamil: 'உறுப்பினரை நீக்கவா?',
            sinhala: 'සාමාජිකයා ඉවත් කරන්නද?',
          ),
        ),
        content: Text(
          adminUiText(
            language,
            english: 'Remove ${member.name} from this group?',
            tamil: '${member.name} உறுப்பினரை இந்தக் குழுவிலிருந்து நீக்கவா?',
            sinhala: '${member.name} මෙම කණ්ඩායමෙන් ඉවත් කරන්නද?',
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
                english: 'Remove',
                tamil: 'நீக்கு',
                sinhala: 'ඉවත් කරන්න',
              ),
            ),
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

  Future<void> _editMember(MemberModel member, String language) async {
    final nameController = TextEditingController(text: member.name);
    final phoneController = TextEditingController(text: member.phone);
    final updated = await showDialog<MemberModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          adminUiText(
            language,
            english: 'Edit member',
            tamil: 'உறுப்பினரைத் திருத்து',
            sinhala: 'සාමාජිකයා සංස්කරණය කරන්න',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: adminUiText(
                  language,
                  english: 'Name with initial',
                  tamil: 'பெயர்',
                  sinhala: 'මුලකුරු සමඟ නම',
                ),
              ),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: adminUiText(
                  language,
                  english: 'Phone',
                  tamil: 'தொலைபேசி',
                  sinhala: 'දුරකථනය',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            child: Text(
              adminUiText(
                language,
                english: 'Save',
                tamil: 'சேமி',
                sinhala: 'සුරකින්න',
              ),
            ),
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
            english: 'Permanently delete "${group.name}"?',
            tamil: '"${group.name}" குழுவை நிரந்தரமாக நீக்கவா?',
            sinhala: '"${group.name}" කණ්ඩායම ස්ථිරවම මකා දමන්නද?',
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
                english: 'Delete group',
                tamil: 'குழுவை நீக்கு',
                sinhala: 'කණ්ඩායම මකන්න',
              ),
            ),
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

  void _copyJoinLink(GroupModel group, String language) {
    final link = 'https://app.airotechhub.lk/group/${group.code}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          adminUiText(
            language,
            english: 'Join link copied.',
            tamil: 'சேரும் இணைப்பு நகலெடுக்கப்பட்டது.',
            sinhala: 'එක්වීමේ සබැඳිය පිටපත් කරන ලදී.',
          ),
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
    final currentLang = ref.watch(languageProvider);
    final isTamil = currentLang == 'ta';
    final isSinhala = currentLang == 'si';
    final colors = Theme.of(context).colorScheme;

    if (group == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              adminUiText(
                currentLang,
                english: 'Group not found',
                tamil: 'குழு கிடைக்கவில்லை',
                sinhala: 'කණ්ඩායම හමු නොවීය',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/app/groups'),
              child: Text(
                adminUiText(
                  currentLang,
                  english: 'Back to groups',
                  tamil: 'குழுக்களுக்குத் திரும்பு',
                  sinhala: 'කණ්ඩායම් වෙත ආපසු',
                ),
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
              Align(
                alignment: Alignment.centerRight,
                child: _languageSwitch(isTamil, isSinhala, currentLang),
              ),
              const SizedBox(height: 12),
              _breadcrumb(group, currentLang, colors),
              const SizedBox(height: 12),
              _joinLinkCard(group, joinLink, currentLang, colors),
              const SizedBox(height: 16),
              Text(
                adminUiText(
                  currentLang,
                  english: 'Waiting for approval',
                  tamil: 'ஒப்புதலுக்காக காத்திருக்கிறது',
                  sinhala: 'අනුමැතිය සඳහා රැඳී සිටී',
                ),
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
                    adminUiText(
                      currentLang,
                      english: 'No one is waiting.',
                      tamil: 'யாரும் காத்திருக்கவில்லை.',
                      sinhala: 'කිසිවෙකු රැඳී නොසිටී.',
                    ),
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _addMemberForm(group, currentLang, colors),
              const SizedBox(height: 12),
              _membersSection(group, members, currentLang, colors),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _deleteGroup(group, currentLang),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  adminUiText(
                    currentLang,
                    english: 'Delete group',
                    tamil: 'குழுவை நீக்கு',
                    sinhala: 'කණ්ඩායම මකන්න',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageSwitch(bool isTamil, bool isSinhala, String currentLang) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _languageSegment(
            label: 'EN',
            selected: currentLang == 'en',
            onTap: () => ref.read(languageProvider.notifier).setLanguage('en'),
          ),
          const SizedBox(width: 2),
          _languageSegment(
            label: 'த',
            selected: isTamil,
            onTap: () => ref.read(languageProvider.notifier).setLanguage('ta'),
          ),
          const SizedBox(width: 2),
          _languageSegment(
            label: 'සි',
            selected: isSinhala,
            onTap: () => ref.read(languageProvider.notifier).setLanguage('si'),
          ),
        ],
      ),
    );
  }

  Widget _languageSegment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 28,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _breadcrumb(GroupModel group, String language, ColorScheme colors) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        InkWell(
          onTap: () => context.go('/app/groups'),
          child: Text(
            adminUiText(
              language,
              english: 'Groups',
              tamil: 'குழுக்கள்',
              sinhala: 'කණ්ඩායම්',
            ),
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: colors.onSurfaceVariant,
        ),
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
    String language,
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
              adminUiText(
                language,
                english: 'Join link',
                tamil: 'சேரும் இணைப்பு',
                sinhala: 'එක්වීමේ සබැඳිය',
              ),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              adminUiText(
                language,
                english:
                    'Share this link. A person asks to join, and you accept them before they can sign in.',
                tamil:
                    'இந்த இணைப்பைப் பகிரவும். சேர விரும்புபவரை அவர்கள் பதிவு செய்வதற்கு முன் நீங்கள் ஏற்க வேண்டும்.',
                sinhala:
                    'මෙම සබැඳිය බෙදාගන්න. එක්වීමට ඉල්ලන අය පුරනය වීමට පෙර ඔබ ඔවුන්ව පිළිගන්න.',
              ),
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
                  onPressed: () => _copyJoinLink(group, language),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    adminUiText(
                      language,
                      english: 'Copy link',
                      tamil: 'இணைப்பை நகலெடு',
                      sinhala: 'සබැඳිය පිටපත් කරන්න',
                    ),
                  ),
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

  Widget _addMemberForm(
    GroupModel group,
    String language,
    ColorScheme colors,
  ) {
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
                  label: adminUiText(
                    language,
                    english: 'Name with initial',
                    tamil: 'பெயர் மற்றும் முதலெழுத்து',
                    sinhala: 'මුලකුරු සමඟ නම',
                  ),
                  controller: _nameController,
                  errorText: _memberError,
                );
                final phoneField = _memberTextField(
                  label: adminUiText(
                    language,
                    english: 'Phone',
                    tamil: 'தொலைபேசி',
                    sinhala: 'දුරකථනය',
                  ),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                );
                final addButton = FilledButton(
                  onPressed: () => _addMember(group, language),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size(0, 42),
                  ),
                  child: Text(
                    adminUiText(
                      language,
                      english: 'Add member',
                      tamil: 'உறுப்பினரைச் சேர்',
                      sinhala: 'සාමාජිකයා එක් කරන්න',
                    ),
                  ),
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
    String language,
    ColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          adminUiText(
            language,
            english: 'Members',
            tamil: 'உறுப்பினர்கள்',
            sinhala: 'සාමාජිකයින්',
          ),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (members.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                adminUiText(
                  language,
                  english: 'No members in this group.',
                  tamil: 'உறுப்பினர்கள் இல்லை.',
                  sinhala: 'මෙම කණ්ඩායමේ සාමාජිකයින් නැත.',
                ),
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          )
        else
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
                    _memberCard(members[index], language, colors),
              );
            },
          ),
      ],
    );
  }

  Widget _memberCard(
    MemberModel member,
    String language,
    ColorScheme colors,
  ) {
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
              onPressed: () => _showMemberDetails(member, language),
              tooltip: adminUiText(
                language,
                english: 'View details',
                tamil: 'விவரங்கள்',
                sinhala: 'විස්තර බලන්න',
              ),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              iconSize: 17,
              icon: const Icon(Icons.visibility_outlined),
            ),
            IconButton(
              onPressed: () => _editMember(member, language),
              tooltip: adminUiText(
                language,
                english: 'Edit',
                tamil: 'திருத்து',
                sinhala: 'සංස්කරණය කරන්න',
              ),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              iconSize: 17,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: () => _deleteMember(member, language),
              tooltip: adminUiText(
                language,
                english: 'Remove',
                tamil: 'நீக்கு',
                sinhala: 'ඉවත් කරන්න',
              ),
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

  void _showMemberDetails(MemberModel member, String language) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: Text(
          '${adminUiText(language, english: 'Phone', tamil: 'தொலைபேசி', sinhala: 'දුරකථනය')}: ${member.phone}\n'
          '${adminUiText(language, english: 'Email', tamil: 'மின்னஞ்சல்', sinhala: 'විද්‍යුත් තැපෑල')}: ${member.email.isEmpty ? '—' : member.email}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              adminUiText(
                language,
                english: 'Close',
                tamil: 'மூடு',
                sinhala: 'වසන්න',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
