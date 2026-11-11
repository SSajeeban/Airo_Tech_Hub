import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Member details saved.')));
  }

  Future<void> _addPayment(MemberModel member) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final result = await showDialog<MapEntry<double, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (LKR)',
                prefixText: 'LKR ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note'),
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
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;
              Navigator.pop(
                context,
                MapEntry(amount, noteController.text.trim()),
              );
            },
            child: const Text('Save payment'),
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
    final member = members
        .where((item) => item.id == widget.memberId)
        .firstOrNull;
    if (member == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Member'),
          leading: IconButton(
            onPressed: () => context.go('/app/members'),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Center(child: Text('Member not found')),
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
        title: const Text('Member Profile'),
        leading: IconButton(
          tooltip: 'Back to members',
          onPressed: () => context.go('/app/members'),
          icon: const Icon(Icons.arrow_back),
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
                                      ? 'No email address'
                                      : member.email,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                _MemberStatus(status: member.status),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickPhoto,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Change photo'),
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
                    title: 'Member details',
                    icon: Icons.badge_outlined,
                    trailing: FilledButton.icon(
                      onPressed: () => _save(member),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save details'),
                    ),
                    child: Column(
                      children: [
                        _ResponsiveDetails(
                          compact: compact,
                          children: [
                            TextFormField(
                              controller: _displayName,
                              decoration: const InputDecoration(
                                labelText: 'Display name',
                              ),
                            ),
                            TextFormField(
                              controller: _fullName,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
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
                              ),
                            ),
                            InkWell(
                              onTap: _selectBirthDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date of birth',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _dateOfBirth == null
                                      ? 'Not provided'
                                      : DateFormat(
                                          'dd MMM yyyy',
                                        ).format(DateTime.parse(_dateOfBirth!)),
                                ),
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: member.status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Active',
                                  child: Text('Active'),
                                ),
                                DropdownMenuItem(
                                  value: 'Inactive',
                                  child: Text('Inactive'),
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
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Custom fields',
                    icon: Icons.tune,
                    child: member.customFields.isEmpty
                        ? Text(
                            'No custom fields have been added.',
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
                    title: 'Documents',
                    icon: Icons.folder_open_outlined,
                    trailing: OutlinedButton.icon(
                      onPressed: () => _addDocuments(member),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Add documents'),
                    ),
                    child: member.documents.isEmpty
                        ? Text(
                            'No documents attached to this profile.',
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
                    title: 'Groups',
                    icon: Icons.groups_outlined,
                    child: groups.isEmpty
                        ? const Text('No groups are available.')
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
                    title: 'Payments',
                    icon: Icons.payments_outlined,
                    trailing: OutlinedButton.icon(
                      onPressed: () => _addPayment(member),
                      icon: const Icon(Icons.add),
                      label: const Text('Record payment'),
                    ),
                    child: payments.isEmpty
                        ? Text(
                            'No payment records for this member.',
                            style: TextStyle(color: Colors.grey.shade600),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 560,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Description')),
                                  DataColumn(label: Text('Amount')),
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Status')),
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
                                              payment.isPaid ? 'Paid' : 'Due',
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
                      child: const Text('Save details'),
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
  const _MemberStatus({required this.status});

  final String status;

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
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
