import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _selectedFolder = 'All';

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(libraryItemsProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final folders = ['All', 'Combined Mathematics', 'Python & AI', 'Assignments'];

    final filtered = _selectedFolder == 'All'
        ? items
        : items.where((i) => i.folder == _selectedFolder).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final titleCtrl = TextEditingController();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Upload Study Resource'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Document Name', hintText: 'e.g. Past Paper 2025.pdf'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final newItem = LibraryItem(
                      id: 'lib_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      folder: _selectedFolder == 'All' ? 'Combined Mathematics' : _selectedFolder,
                      fileType: 'PDF',
                      size: '1.4 MB',
                      uploadedAt: DateTime.now(),
                    );
                    ref.read(libraryItemsProvider.notifier).update((state) => [newItem, ...state]);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Uploaded "${newItem.title}" to library!')),
                    );
                  },
                  child: const Text('Upload'),
                ),
              ],
            ),
          );
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: Text(isTamil ? 'பதிவேற்று' : 'Upload', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Folder Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: folders.map((folder) {
                final isSelected = _selectedFolder == folder;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(folder),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? AppColors.inkDark : AppColors.inkLight),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFolder = folder);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Resources List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final doc = filtered[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.picture_as_pdf, color: AppColors.danger, size: 24),
                    ),
                    title: Text(
                      doc.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${doc.folder} • ${doc.size}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download_outlined, color: AppColors.accent),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Downloading "${doc.title}"...')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

