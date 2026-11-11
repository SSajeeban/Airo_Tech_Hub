import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class GroupFormScreen extends ConsumerStatefulWidget {
  const GroupFormScreen({super.key, this.group});

  final GroupModel? group;

  @override
  ConsumerState<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends ConsumerState<GroupFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late List<_CustomFieldControllers> _customFields;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.group?.description ?? '',
    );
    _customFields =
        widget.group?.customFields.entries
            .map(
              (entry) =>
                  _CustomFieldControllers(field: entry.key, value: entry.value),
            )
            .toList() ??
        [_CustomFieldControllers()];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final field in _customFields) {
      field.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() => _customFields.add(_CustomFieldControllers()));
  }

  void _removeField(int index) {
    setState(() {
      _customFields.removeAt(index).dispose();
    });
  }

  void _saveGroup(bool isTamil) {
    final name = _nameController.text.trim();
    if (name.length < 2 || name.length > 120) {
      setState(() {
        _nameError = isTamil
            ? 'குழு பெயர் 2 முதல் 120 எழுத்துகளுக்குள் இருக்க வேண்டும்.'
            : 'Enter a group name between 2 and 120 characters.';
      });
      return;
    }

    final customFields = <String, String>{};
    for (final field in _customFields) {
      final key = field.fieldController.text.trim();
      final value = field.valueController.text.trim();
      if (key.isNotEmpty) customFields[key] = value;
    }

    final existing = widget.group;
    final generatedCode = name
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final updatedGroup = GroupModel(
      id: existing?.id ?? 'grp_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      code:
          existing?.code ??
          (generatedCode.isEmpty
              ? 'AIR01'
              : generatedCode.substring(0, generatedCode.length.clamp(0, 6))),
      description: _descriptionController.text.trim(),
      memberCount: existing?.memberCount ?? 0,
      schedule: existing?.schedule ?? 'Flexible',
      createdAt: existing?.createdAt ?? DateTime.now(),
      customFields: customFields,
    );

    ref.read(groupsProvider.notifier).update((groups) {
      if (existing == null) return [updatedGroup, ...groups];
      return [
        for (final group in groups)
          if (group.id == existing.id) updatedGroup else group,
      ];
    });
    context.go('/app/groups');
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(languageProvider) == 'ta';
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final formWidth = availableWidth.clamp(0.0, 1050.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: formWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/app/groups'),
                        tooltip: isTamil
                            ? 'குழுக்களுக்குத் திரும்பு'
                            : 'Back to groups',
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isTamil ? 'குழுக்கள் / உருவாக்கு' : 'Groups / Create',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_nameError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        _nameError!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final nameField = _textField(
                                label: isTamil ? 'பெயர்' : 'Name',
                                controller: _nameController,
                                errorText: _nameError,
                                onChanged: (_) {
                                  if (_nameError != null) {
                                    setState(() => _nameError = null);
                                  }
                                },
                              );
                              final descriptionField = _textField(
                                label: isTamil ? 'விளக்கம்' : 'Description',
                                controller: _descriptionController,
                              );
                              if (!constraints.maxWidth.isFinite ||
                                  constraints.maxWidth < 620) {
                                return Column(
                                  children: [
                                    nameField,
                                    const SizedBox(height: 12),
                                    descriptionField,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: nameField),
                                  const SizedBox(width: 12),
                                  Expanded(child: descriptionField),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isTamil
                                      ? 'தனிப்பயன் புலங்கள்'
                                      : 'Custom fields',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: colors.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _addField,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: colors.outlineVariant,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.add, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          isTamil
                                              ? 'புலம் சேர்க்க'
                                              : 'Add field',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(_customFields.length, (index) {
                            final field = _customFields[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final keyField = _textField(
                                    label: isTamil ? 'புலம்' : 'Field',
                                    controller: field.fieldController,
                                  );
                                  final valueField = _textField(
                                    label: isTamil ? 'மதிப்பு' : 'Value',
                                    controller: field.valueController,
                                  );
                                  final removeButton = IconButton(
                                    tooltip: isTamil ? 'நீக்கு' : 'Remove',
                                    color: AppColors.danger,
                                    onPressed: () => _removeField(index),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  );
                                  if (!constraints.maxWidth.isFinite ||
                                      constraints.maxWidth < 520) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        keyField,
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(child: valueField),
                                            removeButton,
                                          ],
                                        ),
                                      ],
                                    );
                                  }
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(child: keyField),
                                      const SizedBox(width: 8),
                                      Expanded(child: valueField),
                                      removeButton,
                                    ],
                                  );
                                },
                              ),
                            );
                          }),
                          const SizedBox(height: 4),
                          FilledButton(
                            onPressed: () => _saveGroup(isTamil),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              widget.group == null
                                  ? (isTamil ? 'உருவாக்கு' : 'Create')
                                  : (isTamil ? 'சேமி' : 'Save'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: label == 'Description' || label == 'விளக்கம்' ? 2 : 1,
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
}

class _CustomFieldControllers {
  _CustomFieldControllers({String field = '', String value = ''})
    : fieldController = TextEditingController(text: field),
      valueController = TextEditingController(text: value);

  final TextEditingController fieldController;
  final TextEditingController valueController;

  void dispose() {
    fieldController.dispose();
    valueController.dispose();
  }
}
