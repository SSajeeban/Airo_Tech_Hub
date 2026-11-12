import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _dateFormat = DateFormat('MMM d, yyyy, h:mm a');
  final _folders = <String>[
    'Combined Mathematics',
    'Python & AI',
    'Assignments',
  ];
  DateTime? _fromDate;
  DateTime? _toDate;
  String _uploadFolder = 'Combined Mathematics';
  String? _selectedItemId;
  String? _allocatingItemId;
  String _allocationType = 'Group';
  String? _selectedGroup;
  String? _selectedMember;
  String _permission = 'View only';
  bool _isGridView = false;
  final Set<String> _allocatedItems = {};

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(libraryItemsProvider);
    final groups = ref.watch(groupsProvider);
    final members = ref.watch(membersProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';
    final colors = Theme.of(context).colorScheme;
    final filteredItems = items.where((item) {
      final date = item.uploadedAt;
      final afterStart =
          _fromDate == null || !date.isBefore(_startOfDay(_fromDate!));
      final beforeEnd = _toDate == null || !date.isAfter(_endOfDay(_toDate!));
      return afterStart && beforeEnd;
    }).toList();
    final selectedItem = items
        .where((item) => item.id == _selectedItemId)
        .firstOrNull;
    final allocatingItem = items
        .where((item) => item.id == _allocatingItemId)
        .firstOrNull;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToolbar(context, isTamil),
          const SizedBox(height: 16),
          if (_isGridView)
            _buildGrid(filteredItems, isTamil, colors)
          else
            _buildList(filteredItems, isTamil, colors),
          if (allocatingItem != null) ...[
            const SizedBox(height: 16),
            _buildAllocationPanel(
              context,
              allocatingItem,
              groups,
              members,
              isTamil,
            ),
          ],
          if (selectedItem != null) ...[
            const SizedBox(height: 16),
            _buildDetailsCard(selectedItem, isTamil),
          ],
          if (filteredItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  isTamil
                      ? 'இந்தக் காலப்பகுதியில் கோப்புகள் இல்லை.'
                      : 'No files found for this date range.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  Widget _buildToolbar(BuildContext context, bool isTamil) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 184,
              child: _dateButton(
                context,
                label: isTamil ? 'இருந்து' : 'From',
                date: _fromDate,
                onSelected: (date) => setState(() => _fromDate = date),
              ),
            ),
            SizedBox(
              width: 184,
              child: _dateButton(
                context,
                label: isTamil ? 'வரை' : 'To',
                date: _toDate,
                onSelected: (date) => setState(() => _toDate = date),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _showNewFolderDialog(isTamil),
              icon: const Icon(AppIcons.folderAdd),
              label: Text(isTamil ? 'புதிய கோப்புறை' : 'New folder'),
            ),
            OutlinedButton.icon(
              onPressed: () => _showUploadDialog(isTamil),
              icon: const Icon(AppIcons.upload),
              label: Text(isTamil ? 'கோப்பைப் பதிவேற்று' : 'Upload file'),
            ),
            ToggleButtons(
              isSelected: [!_isGridView, _isGridView],
              onPressed: (index) => setState(() => _isGridView = index == 1),
              borderRadius: BorderRadius.circular(8),
              selectedColor: AppColors.accent,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(AppIcons.grid),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(AppIcons.list),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateButton(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime?> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) onSelected(picked);
          },
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(0, 40),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  date == null
                      ? 'mm/dd/yyyy'
                      : DateFormat('MM/dd/yyyy').format(date),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(AppIcons.calendar, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<LibraryItem> items, bool isTamil, ColorScheme colors) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 920),
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              colors.surfaceContainerHighest,
            ),
            columns: [
              DataColumn(label: Text(isTamil ? 'பெயர்' : 'Name')),
              DataColumn(label: Text(isTamil ? 'உரிமையாளர்' : 'Owner')),
              DataColumn(label: Text(isTamil ? 'மாற்றப்பட்டது' : 'Modified')),
              DataColumn(label: Text(isTamil ? 'அளவு' : 'Size')),
              DataColumn(label: Text(isTamil ? 'ஒதுக்கப்பட்டது' : 'Allocated')),
              const DataColumn(label: SizedBox.shrink()),
            ],
            rows: items.map((item) {
              final selected = _selectedItemId == item.id;
              return DataRow(
                selected: selected,
                onSelectChanged: (_) => setState(() {
                  _selectedItemId = selected ? null : item.id;
                  _allocatingItemId = null;
                }),
                cells: [
                  DataCell(
                    SizedBox(
                      width: 300,
                      child: Row(
                        children: [
                          Icon(
                            _fileIcon(item.fileType),
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const DataCell(Text('R M Safran')),
                  DataCell(Text(_dateFormat.format(item.uploadedAt))),
                  DataCell(Text(item.size)),
                  DataCell(
                    Text(
                      _allocatedItems.contains(item.id)
                          ? (isTamil ? 'ஒதுக்கப்பட்டது' : 'Allocated')
                          : (isTamil ? 'ஒதுக்கப்படவில்லை' : 'Not allocated'),
                    ),
                  ),
                  DataCell(
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedItemId = item.id;
                        _allocatingItemId = item.id;
                        _selectedGroup = null;
                        _selectedMember = null;
                      }),
                      child: Text(isTamil ? 'ஒதுக்கு' : 'Allocate'),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<LibraryItem> items, bool isTamil, ColorScheme colors) {
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 1000
            ? 3
            : constraints.maxWidth > 620
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() {
                  _selectedItemId = item.id;
                  _allocatingItemId = null;
                }),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        _fileIcon(item.fileType),
                        color: AppColors.accent,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.folder} • ${item.size}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: isTamil ? 'ஒதுக்கு' : 'Allocate',
                        onPressed: () => setState(() {
                          _selectedItemId = item.id;
                          _allocatingItemId = item.id;
                        }),
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllocationPanel(
    BuildContext context,
    LibraryItem item,
    List<GroupModel> groups,
    List<MemberModel> members,
    bool isTamil,
  ) {
    final colors = Theme.of(context).colorScheme;
    final selectedGroup = groups
        .where((group) => group.name == _selectedGroup)
        .firstOrNull;
    final availableMembers = _selectedGroup == null
        ? members
        : members
              .where(
                (member) =>
                    (selectedGroup != null &&
                        (member.groupIds.contains(selectedGroup.id) ||
                            member.groupId == selectedGroup.id)) ||
                    member.groupName == _selectedGroup,
              )
              .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isTamil ? 'கோப்பை ஒதுக்கு' : 'Allocate file',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _allocatingItemId = null),
                  child: Text(isTamil ? 'மூடு' : 'Close'),
                ),
              ],
            ),
            Text(
              '${item.title}. ${isTamil ? 'பகிரப்பட்ட கோப்பு கோப்புறையாக மறைக்கப்படும். பகிரப்பட்ட கோப்புறையை உறுப்பினர் திறக்கலாம்.' : 'A shared file stays hidden as a folder. A shared folder is what the member can open.'}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(isTamil ? 'குழு' : 'Group'),
                  selected: _allocationType == 'Group',
                  onSelected: (_) => setState(() {
                    _allocationType = 'Group';
                    _selectedMember = null;
                  }),
                ),
                ChoiceChip(
                  label: Text(isTamil ? 'தனிநபர்' : 'Individual'),
                  selected: _allocationType == 'Individual',
                  onSelected: (_) => setState(() {
                    _allocationType = 'Individual';
                    _selectedGroup = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final target = _allocationType == 'Group'
                    ? (groups.isEmpty
                          ? null
                          : (groups.any((group) => group.name == _selectedGroup)
                                ? _selectedGroup
                                : null))
                    : (availableMembers.isEmpty
                          ? null
                          : (availableMembers.any(
                                  (member) => member.name == _selectedMember,
                                )
                                ? _selectedMember
                                : null));
                final targetOptions = _allocationType == 'Group'
                    ? groups.map((group) => group.name).toList()
                    : availableMembers.map((member) => member.name).toList();
                final targetDropdown = DropdownButtonFormField<String>(
                  initialValue: target,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  hint: Text(
                    _allocationType == 'Group'
                        ? (isTamil
                              ? 'குழுவைத் தேர்ந்தெடுக்கவும்'
                              : 'Select group')
                        : (isTamil
                              ? 'உறுப்பினரைத் தேர்ந்தெடுக்கவும்'
                              : 'Select individual'),
                  ),
                  items: targetOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    if (_allocationType == 'Group') {
                      _selectedGroup = value;
                    } else {
                      _selectedMember = value;
                    }
                  }),
                );
                final permissionDropdown = DropdownButtonFormField<String>(
                  initialValue: _permission,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'View only',
                      child: Text('View only'),
                    ),
                    DropdownMenuItem(
                      value: 'Can download',
                      child: Text('Can download'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _permission = value);
                    }
                  },
                );
                final allocateButton = FilledButton(
                  onPressed: target == null
                      ? null
                      : () {
                          setState(() {
                            _allocatedItems.add(item.id);
                            _allocatingItemId = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isTamil
                                    ? 'கோப்பு ஒதுக்கப்பட்டது.'
                                    : 'File allocated to $target ($_permission).',
                              ),
                            ),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(isTamil ? 'ஒதுக்கு' : 'Allocate'),
                );
                if (constraints.maxWidth < 620) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      targetDropdown,
                      const SizedBox(height: 8),
                      permissionDropdown,
                      const SizedBox(height: 8),
                      allocateButton,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 5, child: targetDropdown),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: permissionDropdown),
                    const SizedBox(width: 8),
                    allocateButton,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(LibraryItem item, bool isTamil) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _roundAction(
                  icon: AppIcons.download,
                  tooltip: isTamil ? 'பதிவிறக்கு' : 'Download',
                  onPressed: () => _showMessage(
                    isTamil
                        ? 'பதிவிறக்கம் விரைவில் கிடைக்கும்.'
                        : 'File download is not connected yet.',
                  ),
                ),
                _roundAction(
                  icon: AppIcons.copy,
                  tooltip: isTamil ? 'நகலெடு' : 'Copy link',
                  onPressed: () => _showMessage(
                    isTamil
                        ? 'கோப்பு இணைப்பு நகலெடுக்கப்பட்டது.'
                        : 'File link copied.',
                  ),
                ),
                _roundAction(
                  icon: AppIcons.view,
                  tooltip: isTamil ? 'பார்க்க' : 'Preview',
                  onPressed: () => _showMessage(
                    isTamil
                        ? 'முன்னோட்டம் கிடைக்கவில்லை.'
                        : 'File preview is not available for this item.',
                  ),
                ),
                _roundAction(
                  icon: AppIcons.delete,
                  tooltip: isTamil ? 'நீக்கு' : 'Delete',
                  color: AppColors.warning,
                  onPressed: () => _confirmDelete(item, isTamil),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${item.fileType} · ${item.size} · ${_dateFormat.format(item.uploadedAt)}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = AppColors.mutedLight,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      style: IconButton.styleFrom(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        shape: const CircleBorder(),
      ),
    );
  }

  IconData _fileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'xlsx':
      case 'xls':
      case 'csv':
        return Icons.table_chart_outlined;
      case 'mp4':
      case 'mov':
        return Icons.video_file_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Future<void> _showNewFolderDialog(bool isTamil) async {
    final controller = TextEditingController();
    final folderName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isTamil ? 'புதிய கோப்புறை' : 'New folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isTamil ? 'கோப்புறை பெயர்' : 'Folder name',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isTamil ? 'ரத்து' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(isTamil ? 'உருவாக்கு' : 'Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (folderName == null || folderName.isEmpty || !mounted) return;
    if (_folders.contains(folderName)) {
      _showMessage(
        isTamil
            ? 'இந்தக் கோப்புறை ஏற்கனவே உள்ளது.'
            : 'That folder already exists.',
      );
      return;
    }
    setState(() => _folders.add(folderName));
    _showMessage(isTamil ? 'கோப்புறை உருவாக்கப்பட்டது.' : 'Folder created.');
  }

  Future<void> _showUploadDialog(bool isTamil) async {
    final controller = TextEditingController();
    final filename = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isTamil ? 'கோப்பைப் பதிவேற்று' : 'Upload file'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: isTamil ? 'கோப்பு பெயர்' : 'File name',
                hintText: 'Study notes.pdf',
              ),
              onSubmitted: (value) =>
                  Navigator.pop(dialogContext, value.trim()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _folders.contains(_uploadFolder)
                  ? _uploadFolder
                  : _folders.first,
              decoration: InputDecoration(
                labelText: isTamil ? 'கோப்புறை' : 'Folder',
                border: const OutlineInputBorder(),
              ),
              items: _folders
                  .map(
                    (folder) => DropdownMenuItem(
                      value: folder,
                      child: Text(folder, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (folder) {
                if (folder != null) {
                  setState(() => _uploadFolder = folder);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isTamil ? 'ரத்து' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(isTamil ? 'சேர்' : 'Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (filename == null || filename.isEmpty || !mounted) return;

    final extension = filename.contains('.')
        ? filename.split('.').last.toUpperCase()
        : 'FILE';
    final newItem = LibraryItem(
      id: 'lib_${DateTime.now().microsecondsSinceEpoch}',
      title: filename,
      folder: _uploadFolder,
      fileType: extension,
      size: '—',
      uploadedAt: DateTime.now(),
    );
    ref
        .read(libraryItemsProvider.notifier)
        .update((items) => [newItem, ...items]);
    setState(() {
      _selectedItemId = newItem.id;
      _allocatingItemId = null;
      _fromDate = null;
      _toDate = null;
    });
    _showMessage(
      isTamil
          ? 'கோப்பு பட்டியலில் சேர்க்கப்பட்டது. உண்மையான கோப்பு பதிவேற்றம் இன்னும் இணைக்கப்படவில்லை.'
          : 'Added to the library list. File storage upload is not connected yet.',
    );
  }

  Future<void> _confirmDelete(LibraryItem item, bool isTamil) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isTamil ? 'கோப்பை நீக்கவா?' : 'Delete file?'),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isTamil ? 'ரத்து' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isTamil ? 'நீக்கு' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref
        .read(libraryItemsProvider.notifier)
        .update(
          (items) => items.where((existing) => existing.id != item.id).toList(),
        );
    setState(() {
      _selectedItemId = null;
      _allocatingItemId = null;
      _allocatedItems.remove(item.id);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
