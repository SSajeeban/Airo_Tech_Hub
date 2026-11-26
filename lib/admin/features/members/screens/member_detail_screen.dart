import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/admin_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class MemberDetailScreen extends ConsumerStatefulWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  final _displayName = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _customName = TextEditingController();
  final _customValue = TextEditingController();
  final Set<String> _selectedGroups = {};
  String? _dateOfBirth;
  String? _photoPath;
  bool _isInitialized = false;

  @override
  void dispose() {
    _displayName.dispose();
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _customName.dispose();
    _customValue.dispose();
    super.dispose();
  }

  void _initialize(MemberModel member, List<GroupModel> groups) {
    if (_isInitialized) return;
    _displayName.text = member.name;
    _fullName.text = member.fullName ?? '';
    _email.text = member.email;
    _phone.text = member.phone;
    _address.text = member.address ?? '';
    _dateOfBirth = member.dateOfBirth;
    _photoPath = member.photoUrl;
    if (member.groupIds.isNotEmpty) {
      _selectedGroups.addAll(member.groupIds);
    } else if (member.groupId != null) {
      _selectedGroups.add(member.groupId!);
    } else {
      _selectedGroups.addAll(
        groups
            .where((group) => group.name == member.groupName)
            .map((group) => group.id),
      );
    }
    _isInitialized = true;
  }

  Future<void> _selectBirthDate() async {
    final initial = _dateOfBirth == null
        ? DateTime(2005)
        : DateTime.tryParse(_dateOfBirth!) ?? DateTime(2005);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() => _dateOfBirth = DateFormat('yyyy-MM-dd').format(selected));
    }
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.pickFile(type: FileType.image);
    if (result != null) {
      setState(() => _photoPath = result.path ?? result.name);
    }
  }

  Future<void> _addDocuments(MemberModel member) async {
    final result = await FilePicker.pickFiles();
    if (result.isEmpty) return;
    final additions = result.map((file) => file.name).toList();
    ref.read(membersProvider.notifier).update((members) {
      return members
          .map(
            (item) => item.id == member.id
                ? _withMember(
                    item,
                    documents: [...item.documents, ...additions],
                  )
                : item,
          )
          .toList();
    });
  }

  MemberModel _withMember(
    MemberModel member, {
    String? name,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? dateOfBirth,
    String? photoUrl,
    List<String>? groupIds,
    String? groupName,
    List<String>? documents,
    Map<String, String>? customFields,
    String? status,
  }) {
    final groups = ref.read(groupsProvider);
    final ids =
        groupIds ??
        (member.groupIds.isNotEmpty
            ? member.groupIds
            : member.groupId == null
            ? const <String>[]
            : [member.groupId!]);
    final resolvedGroupName =
        groupName ??
        (ids.isNotEmpty
            ? groups
                  .where((group) => ids.contains(group.id))
                  .map((group) => group.name)
                  .join(', ')
            : member.groupId == null
            ? member.groupName
            : 'No group assigned');
    return MemberModel(
      id: member.id,
      name: name ?? member.name,
      initial: (name ?? member.name).isEmpty
          ? 'M'
          : (name ?? member.name).characters.first.toUpperCase(),
      fullName: fullName ?? member.fullName,
      email: email ?? member.email,
      phone: phone ?? member.phone,
      groupName: resolvedGroupName,
      groupId: ids.isEmpty ? null : ids.first,
      groupIds: ids,
      status: status ?? member.status,
      photoUrl: photoUrl ?? member.photoUrl,
      dateOfBirth: dateOfBirth ?? member.dateOfBirth,
      address: address ?? member.address,
      customFields: customFields ?? member.customFields,
      documents: documents ?? member.documents,
      joinedAt: member.joinedAt,
    );
  }

  void _save(MemberModel member) {
    final groups = ref.read(groupsProvider);
    final selectedGroupNames = groups
        .where((group) => _selectedGroups.contains(group.id))
        .map((group) => group.name)
        .toList();
    final updated = _withMember(
      member,
      name: _displayName.text.trim(),
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      dateOfBirth: _dateOfBirth,
      photoUrl: _photoPath,
      groupIds: _selectedGroups.toList(),
      groupName: selectedGroupNames.isEmpty
          ? 'No group assigned'
          : selectedGroupNames.join(', '),
      customFields: member.customFields,
    );
    ref.read(membersProvider.notifier).update((members) {
      return members
          .map((item) => item.id == member.id ? updated : item)
          .toList();
    });
    final language = ref.read(languageProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          adminUiText(
            language,
            english: 'Member details saved.',
            tamil: 'உறுப்பினர் விவரங்கள் சேமிக்கப்பட்டன.',
            sinhala: 'සාමාජික විස්තර සුරකින ලදී.',
          ),
        ),
      ),
    );
  }

  Future<void> _addPayment(MemberModel member, String language) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final result = await showDialog<MapEntry<double, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          adminUiText(
            language,
            english: 'Record payment',
            tamil: 'கட்டணத்தைப் பதிவு செய்',
            sinhala: 'ගෙවීම සටහන් කරන්න',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: adminUiText(
                  language,
                  english: 'Amount (LKR)',
                  tamil: 'தொகை (LKR)',
                  sinhala: 'මුදල (LKR)',
                ),
                prefixText: 'LKR ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: adminUiText(
                  language,
                  english: 'Note',
                  tamil: 'குறிப்பு',
                  sinhala: 'සටහන',
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
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;
              Navigator.pop(
                context,
                MapEntry(amount, noteController.text.trim()),
              );
            },
            child: Text(
              adminUiText(
                language,
                english: 'Save payment',
                tamil: 'கட்டணத்தைச் சேமி',
                sinhala: 'ගෙවීම සුරකින්න',
              ),
            ),
          ),
        ],
      ),
    );
    amountController.dispose();
    noteController.dispose();
    if (result == null || !mounted) return;
    final group = ref
        .read(groupsProvider)
        .where((item) => _selectedGroups.contains(item.id))
        .firstOrNull;
    final now = DateTime.now();
    ref
        .read(paymentsProvider.notifier)
        .update(
          (payments) => [
            PaymentModel(
              id: 'pay_${now.microsecondsSinceEpoch}',
              memberId: member.id,
              memberName: _displayName.text.trim(),
              groupName: group?.name ?? 'No group assigned',
              amount: result.key,
              currency: 'LKR',
              scheduleType: 'One-time',
              dueDate: now,
              isPaid: true,
              paidAt: now,
              title: result.value.isEmpty ? 'Member payment' : result.value,
              appliesTo: 'Member',
            ),
            ...payments,
          ],
        );
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider);
    final groups = ref.watch(groupsProvider);
    final language = ref.watch(languageProvider);
    final member = members
        .where((item) => item.id == widget.memberId)
        .firstOrNull;
    if (member == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            adminUiText(
              language,
              english: 'Member',
              tamil: 'உறுப்பினர்',
              sinhala: 'සාමාජිකයා',
            ),
          ),
          leading: IconButton(
            onPressed: () => context.go('/app/members'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Center(
          child: Text(
            adminUiText(
              language,
              english: 'Member not found',
              tamil: 'உறுப்பினர் கிடைக்கவில்லை',
              sinhala: 'සාමාජිකයා හමු නොවීය',
            ),
          ),
        ),
      );
    }
    _initialize(member, groups);
    final payments = ref
        .watch(paymentsProvider)
        .where(
          (payment) =>
              payment.memberId == member.id ||
              payment.memberName.toLowerCase() == member.name.toLowerCase(),
        )
        .toList();
    final compact = MediaQuery.sizeOf(context).width < 700;
    final photo = _photoPath;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          adminUiText(
            language,
            english: 'Member Profile',
            tamil: 'உறுப்பினர் சுயவிவரம்',
            sinhala: 'සාමාජික පැතිකඩ',
          ),
        ),
        leading: IconButton(
          tooltip: adminUiText(
            language,
            english: 'Back to members',
            tamil: 'உறுப்பினர்களுக்குத் திரும்பு',
            sinhala: 'සාමාජිකයින් වෙත ආපසු',
          ),
          onPressed: () => context.go('/app/members'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(compact ? 16 : 28),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(compact ? 16 : 24),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 18,
                        runSpacing: 16,
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: AppColors.brandBlue.withValues(
                              alpha: 0.12,
                            ),
                            backgroundImage:
                                photo != null && photo.startsWith('http')
                                ? NetworkImage(photo)
                                : null,
                            child: photo == null || !photo.startsWith('http')
                                ? Text(
                                    member.initial,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandBlue,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(
                            width: compact ? 210 : 330,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  member.email.isEmpty
                                      ? adminUiText(
                                          language,
                                          english: 'No email address',
                                          tamil: 'மின்னஞ்சல் முகவரி இல்லை',
                                          sinhala: 'විද්‍යුත් තැපැල් ලිපිනයක් නැත',
                                        )
                                      : member.email,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                _MemberStatus(
                                  status: member.status,
                                  language: language,
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickPhoto,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: Text(
                              adminUiText(
                                language,
                                english: 'Change photo',
                                tamil: 'புகைப்படத்தை மாற்று',
                                sinhala: 'ඡායාරූපය වෙනස් කරන්න',
                              ),
                            ),
                          ),
                          if (photo != null && !photo.startsWith('http'))
                            SizedBox(
                              width: compact ? 210 : 220,
                              child: Text(
                                photo.split(RegExp(r'[/\\]')).last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: adminUiText(
                      language,
                      english: 'Member details',
                      tamil: 'உறுப்பினர் விவரங்கள்',
                      sinhala: 'සාමාජික විස්තර',
                    ),
                    icon: Icons.badge_outlined,
                    trailing: FilledButton.icon(
                      onPressed: () => _save(member),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        adminUiText(
                          language,
                          english: 'Save details',
                          tamil: 'விவரங்களைச் சேமி',
                          sinhala: 'විස්තර සුරකින්න',
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        _ResponsiveDetails(
                          compact: compact,
                          children: [
                            TextFormField(
                              controller: _displayName,
                              decoration: InputDecoration(
                                labelText: adminUiText(
                                  language,
                                  english: 'Display name',
                                  tamil: 'காட்சிப் பெயர்',
                                  sinhala: 'පෙන්වන නම',
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _fullName,
                              decoration: InputDecoration(
                                labelText: adminUiText(
                                  language,
                                  english: 'Full name',
                                  tamil: 'முழுப் பெயர்',
                                  sinhala: 'සම්පූර්ණ නම',
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: adminUiText(
                                  language,
                                  english: 'Email address',
                                  tamil: 'மின்னஞ்சல் முகவரி',
                                  sinhala: 'විද්‍යුත් තැපැල් ලිපිනය',
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: adminUiText(
                                  language,
                                  english: 'Phone number',
                                  tamil: 'தொலைபேசி எண்',
                                  sinhala: 'දුරකථන අංකය',
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _selectBirthDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: adminUiText(
                                    language,
                                    english: 'Date of birth',
                                    tamil: 'பிறந்த தேதி',
                                    sinhala: 'උපන් දිනය',
                                  ),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _dateOfBirth == null
                                      ? adminUiText(
                                          language,
                                          english: 'Not provided',
                                          tamil: 'வழங்கப்படவில்லை',
                                          sinhala: 'සපයා නැත',
                                        )
                                      : DateFormat(
                                          'dd MMM yyyy',
                                        ).format(DateTime.parse(_dateOfBirth!)),
                                ),
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: member.status,
                              decoration: InputDecoration(
                                labelText: adminUiText(
                                  language,
                                  english: 'Status',
                                  tamil: 'நிலை',
                                  sinhala: 'තත්ත්වය',
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'Active',
                                  child: Text(
                                    adminUiText(
                                      language,
                                      english: 'Active',
                                      tamil: 'செயலில்',
                                      sinhala: 'සක්‍රිය',
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Inactive',
                                  child: Text(
                                    adminUiText(
                                      language,
                                      english: 'Inactive',
                                      tamil: 'செயலற்றது',
                                      sinhala: 'අක්‍රිය',
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  ref
                                      .read(membersProvider.notifier)
                                      .update(
                                        (members) => members
                                            .map(
                                              (item) => item.id == member.id
                                                  ? _withMember(
                                                      item,
                                                      status: value,
                                                    )
                                                  : item,
                                            )
                                            .toList(),
                                      );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _address,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: adminUiText(
                              language,
                              english: 'Address',
                              tamil: 'முகவரி',
                              sinhala: 'ලිපිනය',
                            ),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: adminUiText(
                      language,
                      english: 'Custom fields',
                      tamil: 'தனிப்பயன் புலங்கள்',
                      sinhala: 'අභිරුචි ක්ෂේත්‍ර',
                    ),
                    icon: Icons.tune_rounded,
                    child: member.customFields.isEmpty
                        ? Text(
                            adminUiText(
                              language,
                              english: 'No custom fields have been added.',
                              tamil: 'தனிப்பயன் புலங்கள் சேர்க்கப்படவில்லை.',
                              sinhala: 'අභිරුචි ක්ෂේත්‍ර එක් කර නැත.',
                            ),
                            style: TextStyle(color: Colors.grey.shade600),
                          )
                        : Column(
                            children: member.customFields.entries
                                .map(
                                  (field) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(field.key),
                                    subtitle: Text(field.value),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: adminUiText(
                      language,
                      english: 'Documents',
                      tamil: 'ஆவணங்கள்',
                      sinhala: 'ලේඛන',
                    ),
                    icon: Icons.folder_open_outlined,
                    trailing: OutlinedButton.icon(
                      onPressed: () => _addDocuments(member),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(
                        adminUiText(
                          language,
                          english: 'Add documents',
                          tamil: 'ஆவணங்களைச் சேர்',
                          sinhala: 'ලේඛන එක් කරන්න',
                        ),
                      ),
                    ),
                    child: member.documents.isEmpty
                        ? Text(
                            adminUiText(
                              language,
                              english: 'No documents attached to this profile.',
                              tamil: 'இந்த சுயவிவரத்துடன் ஆவணங்கள் இணைக்கப்படவில்லை.',
                              sinhala: 'මෙම පැතිකඩට ලේඛන අමුණා නැත.',
                            ),
                            style: TextStyle(color: Colors.grey.shade600),
                          )
                        : Column(
                            children: member.documents
                                .map(
                                  (document) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                      Icons.insert_drive_file_outlined,
                                    ),
                                    title: Text(document),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: adminUiText(
                      language,
                      english: 'Groups',
                      tamil: 'குழுக்கள்',
                      sinhala: 'කණ්ඩායම්',
                    ),
                    icon: Icons.groups_2_outlined,
                    child: groups.isEmpty
                        ? Text(
                            adminUiText(
                              language,
                              english: 'No groups are available.',
                              tamil: 'குழுக்கள் எதுவும் இல்லை.',
                              sinhala: 'කණ්ඩායම් නොමැත.',
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: groups
                                .map(
                                  (group) => FilterChip(
                                    label: Text(group.name),
                                    selected: _selectedGroups.contains(
                                      group.id,
                                    ),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedGroups.add(group.id);
                                        } else {
                                          _selectedGroups.remove(group.id);
                                        }
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: adminUiText(
                      language,
                      english: 'Payments',
                      tamil: 'கட்டணங்கள்',
                      sinhala: 'ගෙවීම්',
                    ),
                    icon: Icons.payments_outlined,
                    trailing: OutlinedButton.icon(
                      onPressed: () => _addPayment(member, language),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        adminUiText(
                          language,
                          english: 'Record payment',
                          tamil: 'கட்டணத்தைப் பதிவு செய்',
                          sinhala: 'ගෙවීම සටහන් කරන්න',
                        ),
                      ),
                    ),
                    child: payments.isEmpty
                        ? Text(
                            adminUiText(
                              language,
                              english: 'No payment records for this member.',
                              tamil: 'இந்த உறுப்பினருக்கான கட்டணப் பதிவுகள் இல்லை.',
                              sinhala: 'මෙම සාමාජිකයා සඳහා ගෙවීම් වාර්තා නැත.',
                            ),
                            style: TextStyle(color: Colors.grey.shade600),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 560,
                              child: DataTable(
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      adminUiText(
                                        language,
                                        english: 'Description',
                                        tamil: 'விளக்கம்',
                                        sinhala: 'විස්තරය',
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      adminUiText(
                                        language,
                                        english: 'Amount',
                                        tamil: 'தொகை',
                                        sinhala: 'මුදල',
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      adminUiText(
                                        language,
                                        english: 'Date',
                                        tamil: 'தேதி',
                                        sinhala: 'දිනය',
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      adminUiText(
                                        language,
                                        english: 'Status',
                                        tamil: 'நிலை',
                                        sinhala: 'තත්ත්වය',
                                      ),
                                    ),
                                  ),
                                ],
                                rows: payments
                                    .map(
                                      (payment) => DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              payment.title.isEmpty
                                                  ? payment.scheduleType
                                                  : payment.title,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '${payment.currency} ${payment.amount.toStringAsFixed(2)}',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              DateFormat(
                                                'dd MMM yyyy',
                                              ).format(payment.dueDate),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              payment.isPaid
                                                  ? adminUiText(
                                                      language,
                                                      english: 'Paid',
                                                      tamil: 'செலுத்தப்பட்டது',
                                                      sinhala: 'ගෙවා ඇත',
                                                    )
                                                  : adminUiText(
                                                      language,
                                                      english: 'Due',
                                                      tamil: 'நிலுவை',
                                                      sinhala: 'ගෙවිය යුතුය',
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => _save(member),
                      child: Text(
                        adminUiText(
                          language,
                          english: 'Save details',
                          tamil: 'விவரங்களைச் சேமி',
                          sinhala: 'විස්තර සුරකින්න',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveDetails extends StatelessWidget {
  const _ResponsiveDetails({required this.compact, required this.children});

  final bool compact;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            children[index],
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - 14) / 2,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 9),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _MemberStatus extends StatelessWidget {
  const _MemberStatus({required this.status, required this.language});

  final String status;
  final String language;

  @override
  Widget build(BuildContext context) {
    final color = status.toLowerCase() == 'active'
        ? AppColors.success
        : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toLowerCase() == 'active'
            ? adminUiText(
                language,
                english: 'Active',
                tamil: 'செயலில்',
                sinhala: 'සක්‍රිය',
              )
            : adminUiText(
                language,
                english: 'Inactive',
                tamil: 'செயலற்றது',
                sinhala: 'අක්‍රිය',
              ),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
