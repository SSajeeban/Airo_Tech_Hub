import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/admin_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class MemberFormScreen extends ConsumerStatefulWidget {
  const MemberFormScreen({super.key});

  @override
  ConsumerState<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends ConsumerState<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _customFields = <MapEntry<String, String>>[];
  String? _groupId;
  String? _birthDate;
  String? _photoPath;
  String? _photoName;
  final _documents = <String>[];
  bool _isActive = true;

  @override
  void dispose() {
    _displayName.dispose();
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final initial = _birthDate == null
        ? DateTime(2005)
        : DateTime.tryParse(_birthDate!) ?? DateTime(2005);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() => _birthDate = DateFormat('yyyy-MM-dd').format(selected));
    }
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.pickFile(type: FileType.image);
    if (result != null) {
      setState(() {
        _photoName = result.name;
        _photoPath = result.path ?? result.name;
      });
    }
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.pickFiles();
    if (result.isNotEmpty) {
      setState(() {
        _documents.addAll(result.map((file) => file.name));
      });
    }
  }

  Future<void> _addCustomField(String language) async {
    final field = await showDialog<MapEntry<String, String>>(
      context: context,
      builder: (context) => _CustomFieldDialog(language: language),
    );
    if (field != null) setState(() => _customFields.add(field));
  }

  void _save(String language) {
    if (!_formKey.currentState!.validate()) return;
    final groups = ref.read(groupsProvider);
    final group = groups.where((item) => item.id == _groupId).firstOrNull;
    final displayName = _displayName.text.trim();
    final now = DateTime.now();
    final member = MemberModel(
      id: 'm_${now.microsecondsSinceEpoch}',
      name: displayName,
      initial: displayName.characters.first.toUpperCase(),
      fullName: _fullName.text.trim().isEmpty ? null : _fullName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      dateOfBirth: _birthDate,
      photoUrl: _photoPath,
      groupName: group?.name ?? 'No group assigned',
      groupId: group?.id,
      groupIds: group == null ? const [] : [group.id],
      status: _isActive ? 'Active' : 'Inactive',
      documents: List.unmodifiable(_documents),
      customFields: Map.fromEntries(_customFields),
      joinedAt: now,
    );
    ref
        .read(membersProvider.notifier)
        .update((members) => [member, ...members]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          adminUiText(
            language,
            english: '${member.name} added to the directory.',
            tamil: '${member.name} கோப்பகத்தில் சேர்க்கப்பட்டார்.',
            sinhala: '${member.name} නාමාවලියට එක් කරන ලදී.',
          ),
        ),
      ),
    );
    context.go('/app/members');
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider);
    final language = ref.watch(languageProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;
    if (_groupId == null && groups.isNotEmpty) _groupId = groups.first.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          adminUiText(
            language,
            english: 'Create Member',
            tamil: 'உறுப்பினரை உருவாக்கு',
            sinhala: 'සාමාජිකයෙකු සාදන්න',
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width < 920
                ? MediaQuery.sizeOf(context).width
                : 920,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(compact ? 16 : 28),
                children: [
                  Text(
                    adminUiText(
                      language,
                      english: 'Create a new member profile',
                      tamil: 'புதிய உறுப்பினர் சுயவிவரத்தை உருவாக்கவும்',
                      sinhala: 'නව සාමාජික පැතිකඩක් සාදන්න',
                    ),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    adminUiText(
                      language,
                      english: 'Add member information, group membership, and supporting documents.',
                      tamil: 'உறுப்பினர் தகவல், குழு உறுப்பினர் விவரங்கள் மற்றும் ஆதார ஆவணங்களைச் சேர்க்கவும்.',
                      sinhala: 'සාමාජික තොරතුරු, කණ්ඩායම් සාමාජිකත්වය සහ උපකාරක ලේඛන එක් කරන්න.',
                    ),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 22),
                  _FormSection(
                    title: adminUiText(
                      language,
                      english: 'Member Information',
                      tamil: 'உறுப்பினர் தகவல்',
                      sinhala: 'සාමාජික තොරතුරු',
                    ),
                    icon: Icons.person_outline,
                    children: [
                      _ResponsiveFields(
                        compact: compact,
                        children: [
                          TextFormField(
                            controller: _displayName,
                            decoration: InputDecoration(
                              labelText: adminUiText(language, english: 'Display name *', tamil: 'காட்சிப் பெயர் *', sinhala: 'පෙන්වන නම *'),
                              hintText: adminUiText(language, english: 'e.g. Kavindu Perera', tamil: 'எ.கா. Kavindu Perera', sinhala: 'උදා: Kavindu Perera'),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? adminUiText(language, english: 'Enter a display name', tamil: 'காட்சிப் பெயரை உள்ளிடவும்', sinhala: 'පෙන්වන නම ඇතුළත් කරන්න')
                                : null,
                          ),
                          TextFormField(
                            controller: _fullName,
                            decoration: InputDecoration(
                              labelText: adminUiText(language, english: 'Full name', tamil: 'முழுப் பெயர்', sinhala: 'සම්පූර්ණ නම'),
                              hintText: adminUiText(language, english: 'Full legal name', tamil: 'முழு சட்டப்பூர்வ பெயர்', sinhala: 'සම්පූර්ණ නීත්‍යානුකූල නම'),
                            ),
                          ),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: adminUiText(language, english: 'Email address', tamil: 'மின்னஞ்சல் முகவரி', sinhala: 'විද්‍යුත් තැපැල් ලිපිනය'),
                            ),
                          ),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: adminUiText(language, english: 'Phone number', tamil: 'தொலைபேசி எண்', sinhala: 'දුරකථන අංකය'),
                              hintText: '+94',
                            ),
                          ),
                          InkWell(
                            onTap: _selectBirthDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: adminUiText(language, english: 'Date of birth', tamil: 'பிறந்த தேதி', sinhala: 'උපන් දිනය'),
                                suffixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              child: Text(
                                _birthDate == null
                                    ? adminUiText(language, english: 'Select date', tamil: 'தேதியைத் தேர்ந்தெடுக்கவும்', sinhala: 'දිනය තෝරන්න')
                                    : DateFormat(
                                        'dd MMM yyyy',
                                      ).format(DateTime.parse(_birthDate!)),
                              ),
                            ),
                          ),
                          DropdownButtonFormField<String?>(
                            initialValue: _groupId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: adminUiText(language, english: 'Group', tamil: 'குழு', sinhala: 'කණ්ඩායම'),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(adminUiText(language, english: 'No group', tamil: 'குழு இல்லை', sinhala: 'කණ්ඩායමක් නැත')),
                              ),
                              ...groups.map(
                                (group) => DropdownMenuItem<String?>(
                                  value: group.id,
                                  child: Text(
                                    group.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _groupId = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _address,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: adminUiText(language, english: 'Address', tamil: 'முகவரி', sinhala: 'ලිපිනය'),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(adminUiText(language, english: 'Active member', tamil: 'செயலில் உள்ள உறுப்பினர்', sinhala: 'සක්‍රිය සාමාජිකයා')),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormSection(
                    title: adminUiText(language, english: 'Photo', tamil: 'புகைப்படம்', sinhala: 'ඡායාරූපය'),
                    icon: Icons.photo_outlined,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            child: Icon(
                              _photoName == null
                                  ? Icons.person_outline
                                  : Icons.check,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _photoName ?? adminUiText(language, english: 'No photo selected', tamil: 'புகைப்படம் தேர்ந்தெடுக்கப்படவில்லை', sinhala: 'ඡායාරූපයක් තෝරා නැත'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _ActionButton(
                            label: adminUiText(language, english: 'Choose photo', tamil: 'புகைப்படத்தைத் தேர்ந்தெடு', sinhala: 'ඡායාරූපයක් තෝරන්න'),
                            icon: Icons.upload_file_rounded,
                            onPressed: _pickPhoto,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormSection(
                    title: adminUiText(language, english: 'Documents', tamil: 'ஆவணங்கள்', sinhala: 'ලේඛන'),
                    icon: Icons.folder_open_outlined,
                    children: [
                      if (_documents.isEmpty)
                        Text(
                          adminUiText(language, english: 'No documents selected.', tamil: 'ஆவணங்கள் தேர்ந்தெடுக்கப்படவில்லை.', sinhala: 'ලේඛන තෝරා නැත.'),
                          style: TextStyle(color: Colors.grey.shade600),
                        )
                      else
                        ..._documents.asMap().entries.map(
                          (entry) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.insert_drive_file_outlined,
                            ),
                            title: Text(entry.value),
                            trailing: IconButton(
                              tooltip: adminUiText(language, english: 'Remove document', tamil: 'ஆவணத்தை நீக்கு', sinhala: 'ලේඛනය ඉවත් කරන්න'),
                              onPressed: () => setState(
                                () => _documents.removeAt(entry.key),
                              ),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ),
                      _ActionButton(
                        label: adminUiText(language, english: 'Choose documents', tamil: 'ஆவணங்களைத் தேர்ந்தெடு', sinhala: 'ලේඛන තෝරන්න'),
                        icon: Icons.upload_file_rounded,
                        onPressed: _pickDocuments,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        adminUiText(language, english: 'Files are selected on this device only; remote upload is not configured.', tamil: 'கோப்புகள் இந்தச் சாதனத்தில் மட்டுமே தேர்ந்தெடுக்கப்படுகின்றன; தொலைநிலைப் பதிவேற்றம் அமைக்கப்படவில்லை.', sinhala: 'ගොනු තෝරාගනු ලබන්නේ මෙම උපාංගයෙන් පමණි; දුරස්ථ උඩුගත කිරීම සකසා නැත.'),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormSection(
                    title: adminUiText(language, english: 'Custom Fields', tamil: 'தனிப்பயன் புலங்கள்', sinhala: 'අභිරුචි ක්ෂේත්‍ර'),
                    icon: Icons.tune_rounded,
                    children: [
                      if (_customFields.isEmpty)
                        Text(
                          adminUiText(language, english: 'Add optional information specific to this member.', tamil: 'இந்த உறுப்பினருக்கான விருப்பத் தகவலைச் சேர்க்கவும்.', sinhala: 'මෙම සාමාජිකයාට අදාළ විකල්ප තොරතුරු එක් කරන්න.'),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ..._customFields.asMap().entries.map(
                        (entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(entry.value.key),
                          subtitle: Text(entry.value.value),
                          trailing: IconButton(
                            tooltip: adminUiText(language, english: 'Remove custom field', tamil: 'தனிப்பயன் புலத்தை நீக்கு', sinhala: 'අභිරුචි ක්ෂේත්‍රය ඉවත් කරන්න'),
                            onPressed: () => setState(
                              () => _customFields.removeAt(entry.key),
                            ),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ),
                      _ActionButton(
                        label: adminUiText(language, english: 'Add field', tamil: 'புலத்தைச் சேர்', sinhala: 'ක්ෂේත්‍රය එක් කරන්න'),
                        icon: Icons.add_rounded,
                        onPressed: () => _addCustomField(language),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.go('/app/members'),
                        child: Text(adminUiText(language, english: 'Cancel', tamil: 'ரத்து', sinhala: 'අවලංගු කරන්න')),
                      ),
                      FilledButton.icon(
                        onPressed: () => _save(language),
                        icon: const Icon(Icons.save_outlined),
                        label: Text(adminUiText(language, english: 'Create Member', tamil: 'உறுப்பினரை உருவாக்கு', sinhala: 'සාමාජිකයෙකු සාදන්න')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.compact, required this.children});

  final bool compact;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: 14),
            children[index],
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _CustomFieldDialog extends StatefulWidget {
  const _CustomFieldDialog({required this.language});

  final String language;

  @override
  State<_CustomFieldDialog> createState() => _CustomFieldDialogState();
}

class _CustomFieldDialogState extends State<_CustomFieldDialog> {
  final _name = TextEditingController();
  final _value = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        adminUiText(
          widget.language,
          english: 'Add custom field',
          tamil: 'தனிப்பயன் புலத்தைச் சேர்',
          sinhala: 'අභිරුචි ක්ෂේත්‍රය එක් කරන්න',
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: adminUiText(
                widget.language,
                english: 'Field name',
                tamil: 'புலத்தின் பெயர்',
                sinhala: 'ක්ෂේත්‍රයේ නම',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _value,
            decoration: InputDecoration(
              labelText: adminUiText(
                widget.language,
                english: 'Value',
                tamil: 'மதிப்பு',
                sinhala: 'අගය',
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
              widget.language,
              english: 'Cancel',
              tamil: 'ரத்து',
              sinhala: 'අවලංගු කරන්න',
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              MapEntry(_name.text.trim(), _value.text.trim()),
            );
          },
          child: Text(
            adminUiText(
              widget.language,
              english: 'Add',
              tamil: 'சேர்',
              sinhala: 'එක් කරන්න',
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
