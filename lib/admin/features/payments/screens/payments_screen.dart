import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String _selectedGroup = 'All groups';

  Future<void> _createPayment(BuildContext context, WidgetRef ref) async {
    final groups = ref.read(groupsProvider);
    final members = ref.read(membersProvider);
    if (groups.isEmpty || members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add a group and at least one member before creating a payment.',
          ),
        ),
      );
      return;
    }

    final draft = await showDialog<_PaymentDraft>(
      context: context,
      builder: (_) => _CreatePaymentDialog(groups: groups, members: members),
    );
    if (draft == null || !context.mounted) return;

    final targetGroup = groups
        .where((group) => group.name == draft.targetName)
        .firstOrNull;
    final targetMembers = draft.appliesTo == 'Group'
        ? members
              .where(
                (member) =>
                    (targetGroup != null &&
                        (member.groupIds.contains(targetGroup.id) ||
                            member.groupId == targetGroup.id)) ||
                    member.groupName == draft.targetName &&
                        member.status.toLowerCase() == 'active',
              )
              .where((member) => member.status.toLowerCase() == 'active')
              .toList()
        : members.where((member) => member.name == draft.targetName).toList();

    if (targetMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There are no active members for this payment.'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final scheduleId = 'schedule_${now.microsecondsSinceEpoch}';
    final created = targetMembers.map((member) {
      return PaymentModel(
        id: 'pay_${now.microsecondsSinceEpoch}_${member.id}',
        memberId: member.id,
        memberName: member.name,
        groupName: draft.appliesTo == 'Group'
            ? draft.targetName
            : member.groupName,
        amount: draft.amount,
        currency: 'LKR',
        scheduleType: draft.repeat,
        dueDate: draft.startsOn,
        startsOn: draft.startsOn,
        isPaid: false,
        title: draft.title,
        note: draft.note,
        scheduleId: scheduleId,
        appliesTo: draft.appliesTo,
      );
    }).toList();

    ref
        .read(paymentsProvider.notifier)
        .update((payments) => [...created, ...payments]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment created for ${created.length} ${created.length == 1 ? 'member' : 'members'}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final payments = ref.watch(paymentsProvider);
    final groups = ref.watch(groupsProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupOptions = ['All groups', ...groups.map((group) => group.name)];
    if (!groupOptions.contains(_selectedGroup)) _selectedGroup = 'All groups';

    final filteredPayments = _selectedGroup == 'All groups'
        ? payments
        : payments
              .where((payment) => payment.groupName == _selectedGroup)
              .toList();
    final schedules = <String, PaymentModel>{};
    for (final payment in payments) {
      final id = payment.scheduleId;
      if (id != null) schedules.putIfAbsent(id, () => payment);
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final pagePadding = compact ? 16.0 : 28.0;
          return ListView(
            padding: EdgeInsets.fromLTRB(pagePadding, 14, pagePadding, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: isDark
                              ? AppColors.mutedDark
                              : AppColors.mutedLight,
                          fontSize: 14,
                        ),
                        children: [
                          const TextSpan(text: 'safran  /  '),
                          TextSpan(
                            text: isTamil ? 'கட்டணங்கள்' : 'Payments',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.headingDark
                                  : AppColors.headingLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _createPayment(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: Text(
                      compact
                          ? (isTamil ? 'உருவாக்கு' : 'Create')
                          : (isTamil ? 'புதிய கட்டணம்' : 'Create a payment'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _sectionTitle(
                isTamil ? 'கட்டண அட்டவணைகள்' : 'Payment schedules',
                isDark,
              ),
              const SizedBox(height: 10),
              _buildSchedulesTable(
                context,
                ref,
                schedules.values.toList(),
                compact: compact,
                isTamil: isTamil,
                isDark: isDark,
              ),
              const SizedBox(height: 26),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _sectionTitle(
                      isTamil ? 'உறுப்பினர் கட்டணங்கள்' : 'Member payments',
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: compact ? 155 : 260,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedGroup,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: isTamil ? 'குழு' : 'Group',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: groupOptions
                          .map(
                            (group) => DropdownMenuItem(
                              value: group,
                              child: Text(
                                group == 'All groups' && isTamil
                                    ? 'அனைத்து குழுக்களும்'
                                    : group,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (group) {
                        if (group != null) {
                          setState(() => _selectedGroup = group);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildMemberPaymentsTable(
                context,
                ref,
                filteredPayments,
                compact: compact,
                isTamil: isTamil,
                isDark: isDark,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) => Text(
    title,
    style: TextStyle(
      color: isDark ? AppColors.headingDark : AppColors.headingLight,
      fontWeight: FontWeight.w700,
      fontSize: 18,
    ),
  );

  Widget _buildSchedulesTable(
    BuildContext context,
    WidgetRef ref,
    List<PaymentModel> schedules, {
    required bool compact,
    required bool isTamil,
    required bool isDark,
  }) {
    final emptyMessage = isTamil
        ? 'இன்னும் கட்டண அட்டவணைகள் இல்லை.'
        : 'No payment schedules yet.';
    if (compact) {
      return _tableContainer(
        context,
        child: schedules.isEmpty
            ? _emptyTableMessage(emptyMessage, isDark)
            : Column(
                children: schedules
                    .map(
                      (schedule) => _mobileScheduleRow(
                        context,
                        ref,
                        schedule,
                        isTamil: isTamil,
                        isDark: isDark,
                      ),
                    )
                    .toList(),
              ),
      );
    }

    const headers = [
      'Title',
      'Amount',
      'Repeats',
      'Applies to',
      'Starts on',
      'Status',
      'Actions',
    ];
    return _tableContainer(
      context,
      child: schedules.isEmpty
          ? Column(
              children: [
                _tableHeader(
                  headers,
                  isDark,
                  widths: const [185, 110, 120, 210, 140, 100, 90],
                ),
                _emptyTableMessage(emptyMessage, isDark),
              ],
            )
          : Column(
              children: [
                _tableHeader(
                  headers,
                  isDark,
                  widths: const [185, 110, 120, 210, 140, 100, 90],
                ),
                ...schedules.map(
                  (schedule) => _tableRow(
                    context,
                    isDark,
                    [
                      Text(schedule.title),
                      Text(
                        '${schedule.currency} ${schedule.amount.toStringAsFixed(0)}',
                      ),
                      Text(schedule.scheduleType),
                      Text(
                        schedule.appliesTo == 'Group'
                            ? schedule.groupName
                            : schedule.memberName,
                      ),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(schedule.startsOn ?? schedule.dueDate),
                      ),
                      const Text('Active'),
                      _deleteScheduleButton(ref, schedule, isTamil),
                    ],
                    widths: const [185, 110, 120, 210, 140, 100, 90],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMemberPaymentsTable(
    BuildContext context,
    WidgetRef ref,
    List<PaymentModel> payments, {
    required bool compact,
    required bool isTamil,
    required bool isDark,
  }) {
    final emptyMessage = isTamil
        ? 'இந்த வடிகட்டிக்கு உறுப்பினர் கட்டணங்கள் இல்லை.'
        : 'No member payments match this filter.';
    if (compact) {
      return _tableContainer(
        context,
        child: payments.isEmpty
            ? _emptyTableMessage(emptyMessage, isDark)
            : Column(
                children: payments
                    .map(
                      (payment) => _mobilePaymentRow(
                        context,
                        ref,
                        payment,
                        isTamil: isTamil,
                        isDark: isDark,
                      ),
                    )
                    .toList(),
              ),
      );
    }

    const headers = [
      'Member',
      'Group',
      'Title',
      'Repeats',
      'Amount',
      'Due date',
      'Status',
      'Actions',
    ];
    return _tableContainer(
      context,
      child: payments.isEmpty
          ? Column(
              children: [
                _tableHeader(
                  headers,
                  isDark,
                  widths: const [145, 165, 160, 90, 110, 115, 90, 100],
                ),
                _emptyTableMessage(emptyMessage, isDark),
              ],
            )
          : Column(
              children: [
                _tableHeader(
                  headers,
                  isDark,
                  widths: const [145, 165, 160, 90, 110, 115, 90, 100],
                ),
                ...payments.map(
                  (payment) => _tableRow(
                    context,
                    isDark,
                    [
                      Text(payment.memberName),
                      Text(payment.groupName),
                      Text(payment.title.isEmpty ? '—' : payment.title),
                      Text(payment.scheduleType),
                      Text(
                        '${payment.currency} ${payment.amount.toStringAsFixed(0)}',
                      ),
                      Text(DateFormat('dd/MM/yyyy').format(payment.dueDate)),
                      Text(payment.isPaid ? 'Paid' : 'Pending'),
                      payment.isPaid
                          ? const SizedBox.shrink()
                          : _markPaidButton(context, ref, payment, isTamil),
                    ],
                    widths: const [145, 165, 160, 90, 110, 115, 90, 100],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tableContainer(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tableContent = MediaQuery.sizeOf(context).width < 680
        ? child
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: math.max(1050, MediaQuery.sizeOf(context).width - 56),
              child: child,
            ),
          );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        border: Border.all(
          color: isDark ? AppColors.lineDark : AppColors.lineLight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: tableContent,
    );
  }

  Widget _tableHeader(
    List<String> labels,
    bool isDark, {
    required List<double> widths,
  }) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: List.generate(labels.length, (index) {
          final label = labels[index];
          return SizedBox(
            width: widths[index],
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tableRow(
    BuildContext context,
    bool isDark,
    List<Widget> cells, {
    required List<double> widths,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.lineDark : AppColors.lineLight,
          ),
        ),
      ),
      child: Row(
        children: List.generate(cells.length, (index) {
          final cell = cells[index];
          return SizedBox(
            width: widths[index],
            child: cell is Text
                ? DefaultTextStyle.merge(
                    style: TextStyle(
                      color: isDark ? AppColors.inkDark : AppColors.inkLight,
                      fontSize: 12,
                    ),
                    child: Text(
                      cell.data ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cell.style,
                    ),
                  )
                : Align(alignment: Alignment.centerLeft, child: cell),
          );
        }),
      ),
    );
  }

  Widget _emptyTableMessage(String message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: TextStyle(
            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _mobileScheduleRow(
    BuildContext context,
    WidgetRef ref,
    PaymentModel schedule, {
    required bool isTamil,
    required bool isDark,
  }) {
    return _mobileRow(
      context,
      title: schedule.title,
      subtitle:
          '${schedule.appliesTo == 'Group' ? schedule.groupName : schedule.memberName} • ${schedule.scheduleType}',
      details:
          'LKR ${schedule.amount.toStringAsFixed(0)} • ${DateFormat('dd/MM/yyyy').format(schedule.startsOn ?? schedule.dueDate)}',
      status: isTamil ? 'செயலில்' : 'Active',
      action: _deleteScheduleButton(ref, schedule, isTamil),
      isDark: isDark,
    );
  }

  Widget _mobilePaymentRow(
    BuildContext context,
    WidgetRef ref,
    PaymentModel payment, {
    required bool isTamil,
    required bool isDark,
  }) {
    return _mobileRow(
      context,
      title: payment.memberName,
      subtitle:
          '${payment.groupName} • ${payment.title.isEmpty ? payment.scheduleType : payment.title}',
      details:
          '${payment.scheduleType} • ${payment.currency} ${payment.amount.toStringAsFixed(0)} • ${DateFormat('dd/MM/yyyy').format(payment.dueDate)}',
      status: payment.isPaid
          ? (isTamil ? 'செலுத்தப்பட்டது' : 'Paid')
          : (isTamil ? 'நிலுவை' : 'Pending'),
      action: payment.isPaid
          ? const SizedBox.shrink()
          : _markPaidButton(context, ref, payment, isTamil),
      isDark: isDark,
    );
  }

  Widget _mobileRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String details,
    required String status,
    required Widget action,
    required bool isDark,
  }) {
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.lineDark : AppColors.lineLight,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 4),
                Text(
                  '$details • $status',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          action,
        ],
      ),
    );
  }

  Widget _deleteScheduleButton(
    WidgetRef ref,
    PaymentModel schedule,
    bool isTamil,
  ) {
    return IconButton(
      tooltip: isTamil ? 'அட்டவணையை நீக்கு' : 'Delete schedule',
      visualDensity: VisualDensity.compact,
      onPressed: () {
        ref
            .read(paymentsProvider.notifier)
            .update(
              (payments) => payments
                  .where((payment) => payment.scheduleId != schedule.scheduleId)
                  .toList(),
            );
      },
      icon: const Icon(Icons.delete_forever_outlined, size: 18),
    );
  }

  Widget _markPaidButton(
    BuildContext context,
    WidgetRef ref,
    PaymentModel payment,
    bool isTamil,
  ) {
    return TextButton(
      onPressed: () {
        ref.read(paymentsProvider.notifier).update((list) {
          return list.map((item) {
            if (item.id != payment.id) return item;
            return PaymentModel(
              id: item.id,
              memberName: item.memberName,
              groupName: item.groupName,
              amount: item.amount,
              currency: item.currency,
              scheduleType: item.scheduleType,
              dueDate: item.dueDate,
              isPaid: true,
              paidAt: DateTime.now(),
              title: item.title,
              note: item.note,
              startsOn: item.startsOn,
              scheduleId: item.scheduleId,
              appliesTo: item.appliesTo,
            );
          }).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTamil
                  ? '${payment.memberName} கட்டணம் செலுத்தியதாக குறிக்கப்பட்டது.'
                  : 'Marked ${payment.memberName} as paid.',
            ),
          ),
        );
      },
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(isTamil ? 'செலுத்து' : 'Mark paid'),
    );
  }
}

class _PaymentDraft {
  final String title;
  final double amount;
  final String repeat;
  final String appliesTo;
  final String targetName;
  final DateTime startsOn;
  final String note;

  const _PaymentDraft({
    required this.title,
    required this.amount,
    required this.repeat,
    required this.appliesTo,
    required this.targetName,
    required this.startsOn,
    required this.note,
  });
}

class _CreatePaymentDialog extends StatefulWidget {
  final List<GroupModel> groups;
  final List<MemberModel> members;

  const _CreatePaymentDialog({required this.groups, required this.members});

  @override
  State<_CreatePaymentDialog> createState() => _CreatePaymentDialogState();
}

class _CreatePaymentDialogState extends State<_CreatePaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _repeat = 'Monthly';
  String _appliesTo = 'Group';
  String? _groupName;
  String? _memberName;
  DateTime _startsOn = DateTime.now();

  @override
  void initState() {
    super.initState();
    _groupName = widget.groups.isEmpty ? null : widget.groups.first.name;
    final activeMembers = widget.members
        .where((member) => member.status.toLowerCase() == 'active')
        .toList();
    _memberName = activeMembers.isEmpty ? null : activeMembers.first.name;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsOn,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() {
        _startsOn = DateTime(date.year, date.month, date.day);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final appliesTo = _appliesTo;
    final targetName = appliesTo == 'Group' ? _groupName : _memberName;
    if (targetName == null) return;

    Navigator.of(context).pop(
      _PaymentDraft(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        repeat: _repeat,
        appliesTo: appliesTo,
        targetName: targetName,
        startsOn: _startsOn,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = widget.groups;
    final activeMembers = widget.members
        .where((member) => member.status.toLowerCase() == 'active')
        .toList();
    final targetValue = _appliesTo == 'Group' ? _groupName : _memberName;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 570, maxHeight: 720),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 500;
            final fields = <Widget>[
              _field(
                label: 'Title',
                child: TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Monthly tuition',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a payment title'
                      : null,
                ),
              ),
              _field(
                label: 'Amount (LKR)',
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(hintText: '0.00'),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || !amount.isFinite || amount <= 0) {
                      return 'Enter an amount greater than 0';
                    }
                    return null;
                  },
                ),
              ),
              _field(
                label: 'Repeats',
                child: DropdownButtonFormField<String>(
                  initialValue: _repeat,
                  isExpanded: true,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(
                      value: 'One-time',
                      child: Text('One-time'),
                    ),
                    DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _repeat = value);
                  },
                ),
              ),
              _field(
                label: 'Applies to',
                child: DropdownButtonFormField<String>(
                  initialValue: _appliesTo,
                  isExpanded: true,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'Group', child: Text('Group')),
                    DropdownMenuItem(value: 'Member', child: Text('Member')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _appliesTo = value);
                  },
                ),
              ),
              _field(
                label: _appliesTo == 'Group' ? 'Group' : 'Member',
                child: DropdownButtonFormField<String>(
                  initialValue: targetValue,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: _appliesTo == 'Group'
                        ? 'Choose a group'
                        : 'Choose a member',
                  ),
                  items: _appliesTo == 'Group'
                      ? groups
                            .map(
                              (group) => DropdownMenuItem(
                                value: group.name,
                                child: Text(
                                  group.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList()
                      : activeMembers
                            .map(
                              (member) => DropdownMenuItem(
                                value: member.name,
                                child: Text(
                                  member.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                  validator: (value) => value == null
                      ? 'Choose a ${_appliesTo.toLowerCase()}'
                      : null,
                  onChanged: (value) {
                    setState(() {
                      if (_appliesTo == 'Group') {
                        _groupName = value;
                      } else {
                        _memberName = value;
                      }
                    });
                  },
                ),
              ),
              _field(
                label: 'Starts on',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _pickStartDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 17),
                    ),
                    child: Text(DateFormat('MM/dd/yyyy').format(_startsOn)),
                  ),
                ),
              ),
              _field(
                label: 'Note',
                child: TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Optional'),
                ),
              ),
            ];

            final formContent = twoColumns
                ? _buildTwoColumnFields(fields)
                : Column(
                    children: [
                      for (final field in fields) ...[
                        field,
                        const SizedBox(height: 12),
                      ],
                    ],
                  );

            return Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create a payment',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark
                            ? AppColors.headingDark
                            : AppColors.headingLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _appliesTo == 'Group'
                          ? 'A group payment applies to every current active member of that group. Members are notified when it is set, and the due payment stays on their home page until it is marked paid.'
                          : 'This payment applies to one member. They are notified when it is set and can mark the payment as paid.',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.mutedDark
                            : AppColors.mutedLight,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        child: twoColumns ? formContent : formContent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: _submit,
                          child: const Text('Create a payment'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTwoColumnFields(List<Widget> fields) {
    final rows = <Widget>[];
    for (var index = 0; index < fields.length; index += 2) {
      final second = index + 1 < fields.length ? fields[index + 1] : null;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: fields[index]),
            const SizedBox(width: 12),
            Expanded(child: second ?? const SizedBox.shrink()),
          ],
        ),
      );
      rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }

  Widget _field({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedLight,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}
