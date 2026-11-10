import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final scheduleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create New Class Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Group / Cohort Name', hintText: 'e.g. Physics Revision 2026'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Invite Code', hintText: 'e.g. PHY26'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scheduleCtrl,
                  decoration: const InputDecoration(labelText: 'Schedule', hintText: 'e.g. Saturdays 4:00 PM'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final newGroup = GroupModel(
                  id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim().toUpperCase().isNotEmpty ? codeCtrl.text.trim().toUpperCase() : 'AIR99',
                  description: descCtrl.text.trim(),
                  memberCount: 1,
                  schedule: scheduleCtrl.text.trim().isNotEmpty ? scheduleCtrl.text.trim() : 'Flexible',
                  createdAt: DateTime.now(),
                );
                ref.read(groupsProvider.notifier).update((state) => [newGroup, ...state]);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Group "${newGroup.name}" created successfully!')),
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = groups.where((g) {
      return g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.code.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(context),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          isTamil ? 'புதிய குழு' : 'New Group',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: isTamil ? 'குழு அல்லது குறியீடு தேடவும்...' : 'Search group by name or code...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Groups List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      isTamil ? 'குழுக்கள் எதுவும் இல்லை' : 'No groups found',
                      style: TextStyle(color: isDark ? AppColors.mutedDark : AppColors.mutedLight),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final group = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isDark ? AppColors.lineDark : AppColors.lineLight),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                                    child: Text(
                                      group.code.substring(0, 2),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          group.schedule,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      group.code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (group.description.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  group.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.inkDark : AppColors.inkLight,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.people_outline, size: 16, color: AppColors.mutedLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${group.memberCount} students',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: 'https://airotechhub.lk/group/${group.code}'));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Join link for "${group.name}" copied!')),
                                          );
                                        },
                                        icon: const Icon(Icons.copy, size: 14),
                                        label: const Text('Share Link', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(90, 32),
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                        ),
                                      ),
                                    ],
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
        ],
      ),
    );
  }
}

