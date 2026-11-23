import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;

import 'dart:convert';
import 'dart:typed_data';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../widgets/profile_photo_editor_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Teacher Details Controllers
  final _teacherNameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _organizationController = TextEditingController();
  String _profilePhotoBase64 = '';

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageServiceProvider);
    _organizationController.text = storage.getOrganizationName();
    _profilePhotoBase64 = storage.getProfilePhoto();

    final session = ref.read(sessionProvider);
    if (session != null) {
      _teacherNameController.text = session.user.displayName;
      _emailController.text = session.user.email;
    }
  }

  @override
  void dispose() {
    _teacherNameController.dispose();
    _subjectController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _pickOrganizationLogo() async {
    final result = await FilePicker.pickFile(type: FileType.image);
    if (result == null) return;
    final bytes = await result.readAsBytes();
    if (bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected image.')),
      );
      return;
    }

    final base64 = base64Encode(bytes);
    await ref.read(storageServiceProvider).setOrganizationLogo(base64);
    if (!mounted) return;

    try {
      await ref
          .read(apiClientProvider)
          .uploadOrganizationLogo(bytes: bytes, fileName: result.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization logo updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Logo saved locally: $error')));
    }
  }

  Future<void> _pickProfilePhoto() async {
    final result = await FilePicker.pickFile(type: FileType.image);
    if (result == null) return;

    final bytes = await result.readAsBytes();
    if (!mounted) return;
    if (bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(languageProvider) == 'ta'
                ? 'தேர்ந்தெடுத்த படத்தைப் படிக்க முடியவில்லை.'
                : 'Could not read the selected image.',
          ),
        ),
      );
      return;
    }

    await _editProfilePhoto(bytes);
  }

  Future<void> _editProfilePhoto(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(languageProvider) == 'ta'
                ? 'இந்தப் படத்தைத் திறக்க முடியவில்லை.'
                : 'Could not open this image.',
          ),
        ),
      );
      return;
    }

    final orientedImage = img.bakeOrientation(decoded);
    final previewScale =
        orientedImage.width > 1024 || orientedImage.height > 1024
        ? 1024 /
              (orientedImage.width > orientedImage.height
                  ? orientedImage.width
                  : orientedImage.height)
        : 1.0;
    final previewImage = previewScale == 1
        ? orientedImage
        : img.copyResize(
            orientedImage,
            width: (orientedImage.width * previewScale).round(),
            height: (orientedImage.height * previewScale).round(),
          );
    final previewBytes = Uint8List.fromList(img.encodeJpg(previewImage));
    final croppedBytes = await showDialog<Uint8List>(
      context: context,
      builder: (context) => ProfilePhotoEditorDialog(
        image: orientedImage,
        previewBytes: previewBytes,
        isTamil: ref.read(languageProvider) == 'ta',
      ),
    );
    if (croppedBytes == null || !mounted) return;

    final encodedPhoto = base64Encode(croppedBytes);
    await ref.read(storageServiceProvider).setProfilePhoto(encodedPhoto);
    if (!mounted) return;
    setState(() => _profilePhotoBase64 = encodedPhoto);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(languageProvider) == 'ta'
              ? 'சுயவிவரப் படம் புதுப்பிக்கப்பட்டது.'
              : 'Profile photo updated.',
        ),
      ),
    );
  }

  Future<void> _showProfilePhotoOptions() async {
    final isTamil = ref.read(languageProvider) == 'ta';
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_profilePhotoBase64.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(isTamil ? 'படத்தைப் பார்க்க' : 'View photo'),
                onTap: () => Navigator.pop(context, 'view'),
              ),
            if (_profilePhotoBase64.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.crop_outlined),
                title: Text(isTamil ? 'படத்தைத் திருத்து' : 'Edit photo'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(
                _profilePhotoBase64.isEmpty
                    ? (isTamil ? 'படத்தைச் சேர்' : 'Add photo')
                    : (isTamil ? 'படத்தை மாற்று' : 'Change photo'),
              ),
              onTap: () => Navigator.pop(context, 'change'),
            ),
            if (_profilePhotoBase64.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  isTamil ? 'படத்தை நீக்கு' : 'Remove photo',
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'view') {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipOval(
              child: Image.memory(
                base64Decode(_profilePhotoBase64),
                fit: BoxFit.cover,
                width: 280,
                height: 280,
              ),
            ),
          ),
        ),
      );
    } else if (action == 'change') {
      await _pickProfilePhoto();
    } else if (action == 'edit') {
      await _editProfilePhoto(base64Decode(_profilePhotoBase64));
    } else if (action == 'remove') {
      await ref.read(storageServiceProvider).setProfilePhoto('');
      if (!mounted) return;
      setState(() => _profilePhotoBase64 = '');
    }
  }

  Future<void> _saveProfile() async {
    final name = _teacherNameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher name is required.')),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }

    final storage = ref.read(storageServiceProvider);
    await storage.setOrganizationName(_organizationController.text.trim());
    final savedToServer = await ref
        .read(sessionProvider.notifier)
        .updateProfile(displayName: name, email: email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedToServer
              ? 'Profile settings saved successfully!'
              : 'Profile saved locally. Server unavailable.',
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your current password.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Use at least 8 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                validator: (value) => value != newController.text
                    ? 'Passwords do not match.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(apiClientProvider)
            .changePassword(
              currentPassword: currentController.text,
              newPassword: newController.text,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully.')),
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  void _closeProfile() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/app');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'சுயவிவரம்' : 'Profile'),
        actions: [
          IconButton(
            tooltip: isTamil ? 'மூடு' : 'Close',
            icon: const Icon(Icons.close),
            color: Colors.red,
            onPressed: _closeProfile,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Image
            Center(
              child: Stack(
                children: [
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _showProfilePhotoOptions,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                      backgroundImage: _profilePhotoBase64.isNotEmpty
                          ? MemoryImage(base64Decode(_profilePhotoBase64))
                          : null,
                      child: _profilePhotoBase64.isEmpty
                          ? Text(
                              session?.user.displayName.isNotEmpty == true
                                  ? session!.user.displayName[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            )
                          : null,
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.accent,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                        onPressed: _showProfilePhotoOptions,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Profile Name
            Center(
              child: Text(
                session?.user.displayName ?? 'AIRO Subscriber',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            // Profile Email
            Center(
              child: Text(
                session?.user.email ?? 'educator@airotechhub.lk',
                style: TextStyle(
                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Teacher Details Heading
            Text(
              isTamil ? 'ஆசிரியர் விவரங்கள்' : 'Teacher Details',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Teacher Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _organizationController,
                      decoration: const InputDecoration(
                        labelText: 'Organization Name',
                        prefixIcon: Icon(Icons.business_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Teacher Name
                    TextField(
                      controller: _teacherNameController,
                      decoration: const InputDecoration(
                        labelText: 'Teacher Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Subject
                    TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject / Specialization',
                        prefixIcon: Icon(Icons.book_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Qualification
                    TextField(
                      controller: _qualificationController,
                      decoration: const InputDecoration(
                        labelText: 'Qualification',
                        prefixIcon: Icon(Icons.school_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Teaching Experience
                    TextField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Teaching Experience (Years)',
                        prefixIcon: Icon(Icons.work_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Contact Number
                    TextField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Teacher Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Teacher Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Existing Subscription and Settings Card
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: AppColors.accent,
                    ),
                    title: const Text(
                      'Subscription Plan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Pro Educator Tier • Active'),
                    trailing: const Icon(Icons.chevron_right),
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.palette_outlined,
                      color: AppColors.brandBlue,
                    ),
                    title: const Text(
                      'Custom Organization Logo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Enabled for student portal'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickOrganizationLogo,
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.security_outlined,
                      color: AppColors.warning,
                    ),
                    title: const Text(
                      'Change Password',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changePassword,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Save Changes Button
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
