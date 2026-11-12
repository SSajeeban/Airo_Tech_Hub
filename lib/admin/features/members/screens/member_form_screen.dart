import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  Future<void> _addCustomField() async {
    final field = await showDialog<MapEntry<String, String>>(
      context: context,
      builder: (context) => const _CustomFieldDialog(),
    );
    if (field != null) setState(() => _customFields.add(field));
  }

  void _save() {
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
      SnackBar(content: Text('${member.name} added to the directory.')),
    );
    context.go('/app/members');
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;
    if (_groupId == null && groups.isNotEmpty) _groupId = groups.first.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Member'),
        leading: IconButton(
          tooltip: 'Back to members',
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
                    'Create a new member profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Add member information, group membership, and supporting documents.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 22),
                  _FormSection(
                    title: 'Member Information',
                    icon: Icons.person_outline,
                    children: [
                      _ResponsiveFields(
                        compact: compact,
                        children: [
                          TextFormField(
                            controller: _displayName,
                            decoration: const InputDecoration(
                              labelText: 'Display name *',
                              hintText: 'e.g. Kavindu Perera',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter a display name'
                                : null,
                          ),
                          TextFormField(
                            controller: _fullName,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              hintText: 'Full legal name',
                            ),
                          ),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                            ),
                          ),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone number',
                              hintText: '+94',
                            ),
                          ),
                          InkWell(
                            onTap: _selectBirthDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date of birth',
                                suffixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              child: Text(
                                _birthDate == null
                                    ? 'Select date'
                                    : DateFormat(
                                        'dd MMM yyyy',
                                      ).format(DateTime.parse(_birthDate!)),
                              ),
                            ),
                          ),
                          DropdownButtonFormField<String?>(
                            initialValue: _groupId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Group',
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No group'),
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
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active member'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormSection(
                    title: 'Photo',
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
                              _photoName ?? 'No photo selected',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _ActionButton(
                            label: 'Choose photo',
                            icon: Icons.upload_file_rounded,
                            onPressed: _pickPhoto,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormSection(
                    title: 'Documents',
                    icon: Icons.folder_open_outlined,
                    children: [
                      if (_documents.isEmpty)
                        Text(
                          'No documents selected.',
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
                              tooltip: 'Remove document',
                              onPressed: () => setState(
                                () => _documents.removeAt(entry.key),
                              ),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ),
                      _ActionButton(
                        label: 'Choose documents',
                        icon: Icons.upload_file_rounded,
                        onPressed: _pickDocuments,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Files are selected on this device only; remote upload is not configured.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormSection(
                    title: 'Custom Fields',
                    icon: Icons.tune_rounded,
                    children: [
                      if (_customFields.isEmpty)
                        Text(
                          'Add optional information specific to this member.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ..._customFields.asMap().entries.map(
                        (entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(entry.value.key),
                          subtitle: Text(entry.value.value),
                          trailing: IconButton(
                            tooltip: 'Remove custom field',
                            onPressed: () => setState(
                              () => _customFields.removeAt(entry.key),
                            ),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ),
                      _ActionButton(
                        label: 'Add field',
                        icon: Icons.add_rounded,
                        onPressed: _addCustomField,
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
                        child: const Text('Cancel'),
                      ),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Create Member'),
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
  const _CustomFieldDialog();

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
      title: const Text('Add custom field'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Field name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _value,
            decoration: const InputDecoration(labelText: 'Value'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              MapEntry(_name.text.trim(), _value.text.trim()),
            );
          },
          child: const Text('Add'),
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
