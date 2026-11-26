import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;

import 'dart:convert';
import 'dart:typed_data';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/admin_localizations.dart';
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
        SnackBar(
          content: Text(
            adminUiText(
              ref.read(languageProvider),
              english: 'Could not read the selected image.',
              tamil: 'தேர்ந்தெடுத்த படத்தைப் படிக்க முடியவில்லை.',
              sinhala: 'තෝරාගත් රූපය කියවිය නොහැකි විය.',
            ),
          ),
        ),
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
        SnackBar(
          content: Text(
            adminUiText(
              ref.read(languageProvider),
              english: 'Organization logo updated.',
              tamil: 'நிறுவன லோகோ புதுப்பிக்கப்பட்டது.',
              sinhala: 'ආයතන ලාංඡනය යාවත්කාලීන කරන ලදී.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(
            SnackBar(
              content: Text(
                adminUiText(
                  ref.read(languageProvider),
                  english: 'Logo saved locally: $error',
                  tamil: 'லோகோ உள்ளூரில் சேமிக்கப்பட்டது: $error',
                  sinhala: 'ලාංඡනය උපාංගයේ සුරකින ලදී: $error',
                ),
              ),
            ),
          );
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
            adminUiText(
              ref.read(languageProvider),
              english: 'Could not read the selected image.',
              tamil: 'தேர்ந்தெடுத்த படத்தைப் படிக்க முடியவில்லை.',
              sinhala: 'තෝරාගත් රූපය කියවිය නොහැකි විය.',
            ),
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
            adminUiText(
              ref.read(languageProvider),
              english: 'Could not open this image.',
              tamil: 'இந்தப் படத்தைத் திறக்க முடியவில்லை.',
              sinhala: 'මෙම රූපය විවෘත කළ නොහැක.',
            ),
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
        language: ref.read(languageProvider),
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
          adminUiText(
            ref.read(languageProvider),
            english: 'Profile photo updated.',
            tamil: 'சுயவிவரப் படம் புதுப்பிக்கப்பட்டது.',
            sinhala: 'පැතිකඩ ඡායාරූපය යාවත්කාලීන කරන ලදී.',
          ),
        ),
      ),
    );
  }

  Future<void> _showProfilePhotoOptions() async {
    final language = ref.read(languageProvider);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_profilePhotoBase64.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(adminUiText(language, english: 'View photo', tamil: 'படத்தைப் பார்க்க', sinhala: 'ඡායාරූපය බලන්න')),
                onTap: () => Navigator.pop(context, 'view'),
              ),
            if (_profilePhotoBase64.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.crop_outlined),
                title: Text(adminUiText(language, english: 'Edit photo', tamil: 'படத்தைத் திருத்து', sinhala: 'ඡායාරූපය සංස්කරණය කරන්න')),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(
                _profilePhotoBase64.isEmpty
                    ? adminUiText(language, english: 'Add photo', tamil: 'படத்தைச் சேர்', sinhala: 'ඡායාරූපයක් එක් කරන්න')
                    : adminUiText(language, english: 'Change photo', tamil: 'படத்தை மாற்று', sinhala: 'ඡායාරූපය වෙනස් කරන්න'),
              ),
              onTap: () => Navigator.pop(context, 'change'),
            ),
            if (_profilePhotoBase64.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  adminUiText(language, english: 'Remove photo', tamil: 'படத்தை நீக்கு', sinhala: 'ඡායාරූපය ඉවත් කරන්න'),
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
        SnackBar(
          content: Text(adminUiText(ref.read(languageProvider), english: 'Teacher name is required.', tamil: 'ஆசிரியர் பெயர் தேவை.', sinhala: 'ගුරුවරයාගේ නම අවශ්‍යය.')),
        ),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adminUiText(ref.read(languageProvider), english: 'Enter a valid email address.', tamil: 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்.', sinhala: 'වලංගු විද්‍යුත් තැපැල් ලිපිනයක් ඇතුළත් කරන්න.')),
        ),
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
              ? adminUiText(ref.read(languageProvider), english: 'Profile settings saved successfully!', tamil: 'சுயவிவர அமைப்புகள் வெற்றிகரமாகச் சேமிக்கப்பட்டன!', sinhala: 'පැතිකඩ සැකසුම් සාර්ථකව සුරකින ලදී!')
              : adminUiText(ref.read(languageProvider), english: 'Profile saved locally. Server unavailable.', tamil: 'சுயவிவரம் உள்ளூரில் சேமிக்கப்பட்டது. சேவையகம் கிடைக்கவில்லை.', sinhala: 'පැතිකඩ උපාංගයේ සුරකින ලදී. සේවාදායකය ලබා ගත නොහැක.'),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final language = ref.read(languageProvider);
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          adminUiText(
            language,
            english: 'Change Password',
            tamil: 'கடவுச்சொல்லை மாற்று',
            sinhala: 'මුරපදය වෙනස් කරන්න',
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: adminUiText(
                    language,
                    english: 'Current password',
                    tamil: 'தற்போதைய கடவுச்சொல்',
                    sinhala: 'වත්මන් මුරපදය',
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? adminUiText(
                        language,
                        english: 'Enter your current password.',
                        tamil: 'உங்கள் தற்போதைய கடவுச்சொல்லை உள்ளிடவும்.',
                        sinhala: 'ඔබගේ වත්මන් මුරපදය ඇතුළත් කරන්න.',
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: adminUiText(
                    language,
                    english: 'New password',
                    tamil: 'புதிய கடவுச்சொல்',
                    sinhala: 'නව මුරපදය',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return adminUiText(
                      language,
                      english: 'Use at least 8 characters.',
                      tamil: 'குறைந்தது 8 எழுத்துகளைப் பயன்படுத்தவும்.',
                      sinhala: 'අවම වශයෙන් අක්ෂර 8ක් භාවිතා කරන්න.',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: adminUiText(
                    language,
                    english: 'Confirm new password',
                    tamil: 'புதிய கடவுச்சொல்லை உறுதிப்படுத்தவும்',
                    sinhala: 'නව මුරපදය තහවුරු කරන්න',
                  ),
                ),
                validator: (value) => value != newController.text
                    ? adminUiText(
                        language,
                        english: 'Passwords do not match.',
                        tamil: 'கடவுச்சொற்கள் பொருந்தவில்லை.',
                        sinhala: 'මුරපද ගැළපෙන්නේ නැත.',
                      )
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              adminUiText(
                language,
                english: 'Cancel',
                tamil: 'ரத்து',
                sinhala: 'අවලංගු කරන්න',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: Text(
              adminUiText(
                language,
                english: 'Change Password',
                tamil: 'கடவுச்சொல்லை மாற்று',
                sinhala: 'මුරපදය වෙනස් කරන්න',
              ),
            ),
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
          SnackBar(
            content: Text(
              adminUiText(
                language,
                english: 'Password changed successfully.',
                tamil: 'கடவுச்சொல் வெற்றிகரமாக மாற்றப்பட்டது.',
                sinhala: 'මුරපදය සාර්ථකව වෙනස් කරන ලදී.',
              ),
            ),
          ),
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
    final language = ref.watch(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          adminUiText(
            language,
            english: 'Profile',
            tamil: 'சுயவிவரம்',
            sinhala: 'පැතිකඩ',
          ),
        ),
        actions: [
          IconButton(
            tooltip: adminUiText(
              language,
              english: 'Close',
              tamil: 'மூடு',
              sinhala: 'වසන්න',
            ),
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
              adminUiText(
                language,
                english: 'Teacher Details',
                tamil: 'ஆசிரியர் விவரங்கள்',
                sinhala: 'ගුරු විස්තර',
              ),
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
                      decoration: InputDecoration(
                        labelText: adminUiText(language, english: 'Organization Name', tamil: 'நிறுவனத்தின் பெயர்', sinhala: 'ආයතනයේ නම'),
                        prefixIcon: Icon(Icons.business_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Teacher Name
                    TextField(
                      controller: _teacherNameController,
                      decoration: InputDecoration(
                        labelText: adminUiText(language, english: 'Teacher Name', tamil: 'ஆசிரியர் பெயர்', sinhala: 'ගුරුවරයාගේ නම'),
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Subject
                    TextField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: adminUiText(language, english: 'Subject / Specialization', tamil: 'பாடம் / சிறப்புத் துறை', sinhala: 'විෂය / විශේෂීකරණය'),
                        prefixIcon: Icon(Icons.book_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Qualification
                    TextField(
                      controller: _qualificationController,
                      decoration: InputDecoration(
                        labelText: adminUiText(language, english: 'Qualification', tamil: 'தகுதி', sinhala: 'සුදුසුකම'),
                        prefixIcon: Icon(Icons.school_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Teaching Experience
                    TextField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: adminUiText(language, english: 'Teaching Experience (Years)', tamil: 'கற்பித்தல் அனுபவம் (ஆண்டுகள்)', sinhala: 'ඉගැන්වීමේ පළපුරුද්ද (වසර)'),
                        prefixIcon: Icon(Icons.work_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Contact Number
                    TextField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: adminUiText(language, english: 'Contact Number', tamil: 'தொடர்பு எண்', sinhala: 'සම්බන්ධතා අංකය'),
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Teacher Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: adminUiText(language, english: 'Teacher Email Address', tamil: 'ஆசிரியர் மின்னஞ்சல் முகவரி', sinhala: 'ගුරු විද්‍යුත් තැපැල් ලිපිනය'),
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
                    title: Text(
                      adminUiText(language, english: 'Subscription Plan', tamil: 'சந்தா திட்டம்', sinhala: 'දායකත්ව සැලැස්ම'),
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(adminUiText(language, english: 'Pro Educator Tier • Active', tamil: 'ப்ரோ கல்வியாளர் நிலை • செயலில்', sinhala: 'ප්‍රෝ අධ්‍යාපක මට්ටම • සක්‍රිය')),
                    trailing: const Icon(Icons.chevron_right),
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.palette_outlined,
                      color: AppColors.brandBlue,
                    ),
                    title: Text(
                      adminUiText(language, english: 'Custom Organization Logo', tamil: 'தனிப்பயன் நிறுவன லோகோ', sinhala: 'අභිරුචි ආයතනික ලාංඡනය'),
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(adminUiText(language, english: 'Enabled for student portal', tamil: 'மாணவர் போர்ட்டலுக்கு இயக்கப்பட்டது', sinhala: 'ශිෂ්‍ය ද්වාරය සඳහා සක්‍රිය කර ඇත')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickOrganizationLogo,
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.security_outlined,
                      color: AppColors.warning,
                    ),
                    title: Text(
                      adminUiText(language, english: 'Change Password', tamil: 'கடவுச்சொல்லை மாற்று', sinhala: 'මුරපදය වෙනස් කරන්න'),
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
              child: Text(adminUiText(language, english: 'Save Changes', tamil: 'மாற்றங்களைச் சேமி', sinhala: 'වෙනස්කම් සුරකින්න')),
            ),
          ],
        ),
      ),
    );
  }
}
