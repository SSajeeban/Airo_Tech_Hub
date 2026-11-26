import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/localization/admin_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';
import '../../../models/user_session.dart';
import '../../../../mock_meeting_store.dart';

class MeetingsScreen extends ConsumerStatefulWidget {
  const MeetingsScreen({super.key});

  @override
  ConsumerState<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends ConsumerState<MeetingsScreen> {
  String _text(String english, String tamil, String sinhala) {
    return adminUiText(
      ref.read(languageProvider),
      english: english,
      tamil: tamil,
      sinhala: sinhala,
    );
  }

  final _titleController = TextEditingController();
  final _sessionIdController = TextEditingController();
  DateTime? _startsAt;
  String? _selectedGroup;
  bool _isInstantMeeting = true;

  @override
  void dispose() {
    _titleController.dispose();
    _sessionIdController.dispose();
    super.dispose();
  }

  String _generateSessionId() {
    final value = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return value.substring(value.length - 6).toUpperCase();
  }

  Future<void> _launchMeeting(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Could not open meeting: $url',
              'கூட்டத்தைத் திறக்க முடியவில்லை: $url',
              'රැස්වීම විවෘත කළ නොහැක: $url',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _pickStartDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _createMeeting(List<GroupModel> groups) {
    if (ref.read(sessionProvider)?.user.role != UserRole.subscriber) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Only admins can schedule meetings.',
              'நிர்வாகிகள் மட்டுமே கூட்டங்களைத் திட்டமிடலாம்.',
              'රැස්වීම් සැලසුම් කළ හැක්කේ පරිපාලකයින්ට පමණි.',
            ),
          ),
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    final sessionId = _sessionIdController.text.trim().toUpperCase();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Enter a meeting title.',
              'கூட்டத் தலைப்பை உள்ளிடவும்.',
              'රැස්වීමේ මාතෘකාවක් ඇතුළත් කරන්න.',
            ),
          ),
        ),
      );
      return;
    }
    if (_isInstantMeeting && sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Generate or enter a session ID.',
              'அமர்வு ஐடியை உருவாக்கவும் அல்லது உள்ளிடவும்.',
              'සැසි ID එකක් සාදන්න හෝ ඇතුළත් කරන්න.',
            ),
          ),
        ),
      );
      return;
    }
    if (!_isInstantMeeting && _startsAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Choose a start date and time.',
              'தொடக்க தேதி மற்றும் நேரத்தைத் தேர்ந்தெடுக்கவும்.',
              'ආරම්භක දිනය සහ වේලාව තෝරන්න.',
            ),
          ),
        ),
      );
      return;
    }

    GroupModel? selectedGroup;
    for (final group in groups) {
      if (group.name == _selectedGroup) {
        selectedGroup = group;
        break;
      }
    }
    selectedGroup ??= groups.isEmpty ? null : groups.first;
    final groupName = _isInstantMeeting
        ? 'General Session'
        : (selectedGroup?.name ?? 'General Session');
    final id = _isInstantMeeting ? sessionId : _generateSessionId();
    final meeting = MeetingModel(
      id: id,
      title: title,
      groupName: groupName,
      scheduledTime: _isInstantMeeting ? DateTime.now() : _startsAt!,
      durationMinutes: 60,
      meetingUrl: 'https://meet.jit.si/$id',
      isLive: _isInstantMeeting,
    );
    ref.read(meetingsProvider.notifier).update((state) => [meeting, ...state]);
    MockMeetingStore.instance.publishMeeting(
      meeting,
      recipientGroupIds: MockMeetingStore.memberGroupIdsForAdminGroup(
        _isInstantMeeting ? null : selectedGroup?.id,
      ),
    );
    _titleController.clear();
    setState(() {
      _startsAt = null;
      if (_isInstantMeeting) _sessionIdController.text = _generateSessionId();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isInstantMeeting
              ? _text(
                  'Instant meeting created.',
                  'உடனடி கூட்டம் உருவாக்கப்பட்டது.',
                  'ක්ෂණික රැස්වීම සාදන ලදී.',
                )
              : _text(
                  'Meeting scheduled.',
                  'கூட்டம் திட்டமிடப்பட்டது.',
                  'රැස්වීම සැලසුම් කරන ලදී.',
                ),
        ),
        action: SnackBarAction(
          label: _isInstantMeeting
              ? _text('JOIN NOW', 'இப்போது சேரவும்', 'දැන් එක්වන්න')
              : _text('COPY LINK', 'இணைப்பை நகலெடு', 'සබැඳිය පිටපත් කරන්න'),
          onPressed: () {
            if (_isInstantMeeting) {
              _launchMeeting(meeting.meetingUrl);
            } else {
              Clipboard.setData(ClipboardData(text: meeting.meetingUrl));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(sessionProvider)?.user.role;

    if (userRole != UserRole.subscriber) {
      return Scaffold(
        body: Center(
          child: Text(
            _text(
              'Only admins can access meetings.',
              'நிர்வாகிகள் மட்டுமே கூட்டங்களை அணுகலாம்.',
              'රැස්වීම් වෙත ප්‍රවේශ විය හැක්කේ පරිපාලකයින්ට පමණි.',
            ),
          ),
        ),
      );
    }
    final meetings = ref.watch(meetingsProvider);
    final groups = ref.watch(groupsProvider);
    final language = ref.watch(languageProvider);
    final isTamil = language == 'ta';
    final canManageMeetings =
        ref.watch(sessionProvider)?.user.role == UserRole.subscriber;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _selectedGroup ??= groups.isEmpty ? null : groups.first.name;
    if (_sessionIdController.text.isEmpty) {
      _sessionIdController.text = _generateSessionId();
    }

    if (!canManageMeetings) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _text(
                'Only admins can access meetings.',
                'நிர்வாகிகள் மட்டுமே கூட்டங்களை அணுகலாம்.',
                'රැස්වීම් වෙත ප්‍රවේශ විය හැක්කේ පරිපාලකයින්ට පමණි.',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (canManageMeetings) ...[
            _formCard(groups, isDark, isTamil),
            const SizedBox(height: 16),
          ],
          _meetingsTable(meetings, isDark, isTamil),
        ],
      ),
    );
  }

  Widget _formCard(List<GroupModel> groups, bool isDark, bool isTamil) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _modeSelector(isDark, isTamil),
          const SizedBox(height: 14),
          if (!_isInstantMeeting) ...[
            _fieldLabel(_text('Group', 'குழு', 'කණ්ඩායම'), isDark),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: groups.any((group) => group.name == _selectedGroup)
                  ? _selectedGroup
                  : null,
              isExpanded: true,
              decoration: _inputDecoration(isDark),
              hint: Text(
                _text(
                  'Select a group',
                  'குழுவைத் தேர்ந்தெடுக்கவும்',
                  'කණ්ඩායමක් තෝරන්න',
                ),
              ),
              items: groups
                  .map(
                    (group) => DropdownMenuItem(
                      value: group.name,
                      child: Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: groups.isEmpty
                  ? null
                  : (value) => setState(() => _selectedGroup = value),
            ),
            const SizedBox(height: 12),
          ],
          _fieldLabel(_text('Title', 'தலைப்பு', 'මාතෘකාව'), isDark),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            decoration: _inputDecoration(
              isDark,
              hintText: _text(
                'Meeting title',
                'கூட்டத்தின் தலைப்பு',
                'රැස්වීමේ මාතෘකාව',
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_isInstantMeeting) ...[
            _fieldLabel(_text('Session ID', 'அமர்வு ஐடி', 'සැසි ID'), isDark),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sessionIdController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _inputDecoration(isDark),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(92, 48),
                  ),
                  onPressed: () => setState(
                    () => _sessionIdController.text = _generateSessionId(),
                  ),
                  child: Text(_text('Generate', 'உருவாக்கு', 'සාදන්න')),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else ...[
            _fieldLabel(_text('Starts', 'தொடங்கும் நேரம்', 'ආරම්භ වේ'), isDark),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickStartDateTime,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: _inputDecoration(
                  isDark,
                  suffixIcon: const Icon(AppIcons.calendar, size: 18),
                ),
                child: Text(
                  _startsAt == null
                      ? _text(
                          'Choose date and time',
                          'தேதி மற்றும் நேரத்தைத் தேர்ந்தெடுக்கவும்',
                          'දිනය සහ වේලාව තෝරන්න',
                        )
                      : DateFormat('MM/dd/yyyy  h:mm a').format(_startsAt!),
                  style: TextStyle(
                    color: _startsAt == null
                        ? (isDark ? AppColors.mutedDark : AppColors.mutedLight)
                        : (isDark ? AppColors.inkDark : AppColors.inkLight),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _createMeeting(groups),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isInstantMeeting
                    ? _text(
                        'Create instant meeting',
                        'உடனடி கூட்டத்தை உருவாக்கு',
                        'ක්ෂණික රැස්වීම සාදන්න',
                      )
                    : _text(
                        'Schedule meeting',
                        'கூட்டத்தைத் திட்டமிடு',
                        'රැස්වීම සැලසුම් කරන්න',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeSelector(bool isDark, bool isTamil) {
    final border = isDark ? AppColors.lineDark : AppColors.lineLight;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton(
            _text('Schedule meeting', 'திட்டமிடு', 'රැස්වීම සැලසුම් කරන්න'),
            selected: !_isInstantMeeting,
            onPressed: () => setState(() => _isInstantMeeting = false),
            isDark: isDark,
          ),
          _modeButton(
            _text('Instant meeting', 'உடனடி கூட்டம்', 'ක්ෂණික රැස්වීම'),
            selected: _isInstantMeeting,
            onPressed: () => setState(() => _isInstantMeeting = true),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _modeButton(
    String label, {
    required bool selected,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: selected ? AppColors.accent : Colors.transparent,
        foregroundColor: selected
            ? Colors.white
            : (isDark ? AppColors.mutedDark : AppColors.mutedLight),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      child: Text(label),
    );
  }

  Widget _meetingsTable(
    List<MeetingModel> meetings,
    bool isDark,
    bool isTamil,
  ) {
    final border = isDark ? AppColors.lineDark : AppColors.lineLight;
    final headerColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          if (MediaQuery.sizeOf(context).width < 620)
            ..._mobileMeetingRows(meetings, isDark, isTamil)
          else ...[
            Container(
              color: headerColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _headerText(
                      _text('Meeting', 'கூட்டம்', 'රැස්වීම'),
                      isDark,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _headerText(
                      _text('Starts', 'தொடங்கும் நேரம்', 'ආරම්භ වේ'),
                      isDark,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: _headerText(
                      _text('Status', 'நிலை', 'තත්ත්වය'),
                      isDark,
                    ),
                  ),
                  SizedBox(
                    width: 128,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _headerText(
                        _text('Actions', 'செயல்கள்', 'ක්‍රියා'),
                        isDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (meetings.isEmpty)
              _emptyMessage(
                _text(
                  'No meetings yet.',
                  'இன்னும் கூட்டங்கள் இல்லை.',
                  'තවම රැස්වීම් නැත.',
                ),
                isDark,
              )
            else
              ...meetings.map(
                (meeting) =>
                    _desktopMeetingRow(meeting, isDark, isTamil, border),
              ),
          ],
        ],
      ),
    );
  }

  List<Widget> _mobileMeetingRows(
    List<MeetingModel> meetings,
    bool isDark,
    bool isTamil,
  ) {
    if (meetings.isEmpty) {
      return [
        _emptyMessage(
          _text(
            'No meetings yet.',
            'இன்னும் கூட்டங்கள் இல்லை.',
            'තවම රැස්වීම් නැත.',
          ),
          isDark,
        ),
      ];
    }
    return meetings
        .map((meeting) => _mobileMeetingRow(meeting, isDark, isTamil))
        .toList();
  }

  Widget _desktopMeetingRow(
    MeetingModel meeting,
    bool isDark,
    bool isTamil,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppColors.inkDark : AppColors.inkLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${meeting.groupName} · ${_text('Session', 'அமர்வு', 'සැසිය')} ${meeting.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd MMM yyyy, h:mm a').format(meeting.scheduledTime),
              style: TextStyle(
                color: isDark ? AppColors.inkDark : AppColors.inkLight,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(flex: 1, child: _statusChip(meeting, isDark, isTamil)),
          SizedBox(
            width: 128,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: _text(
                    'Copy link',
                    'இணைப்பை நகலெடு',
                    'සබැඳිය පිටපත් කරන්න',
                  ),
                  onPressed: () => _copyMeetingLink(meeting),
                  icon: const Icon(AppIcons.copy, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
                TextButton(
                  onPressed: () => _launchMeeting(meeting.meetingUrl),
                  child: Text(
                    meeting.isLive
                        ? _text('Join', 'சேர்', 'එක්වන්න')
                        : _text('Start', 'தொடங்கு', 'ආරම්භ කරන්න'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileMeetingRow(MeetingModel meeting, bool isDark, bool isTamil) {
    final border = isDark ? AppColors.lineDark : AppColors.lineLight;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meeting.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              _statusChip(meeting, isDark, isTamil),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            meeting.groupName,
            style: TextStyle(
              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd MMM yyyy, h:mm a').format(meeting.scheduledTime),
            style: TextStyle(
              color: isDark ? AppColors.inkDark : AppColors.inkLight,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${_text('Session', 'அமர்வு', 'සැසිය')} ${meeting.id}',
                style: TextStyle(
                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: _text(
                  'Copy link',
                  'இணைப்பை நகலெடு',
                  'සබැඳිය පිටපත් කරන්න',
                ),
                onPressed: () => _copyMeetingLink(meeting),
                icon: const Icon(AppIcons.copy, size: 18),
                visualDensity: VisualDensity.compact,
              ),
              TextButton(
                onPressed: () => _launchMeeting(meeting.meetingUrl),
                child: Text(
                  meeting.isLive
                      ? _text('Join', 'சேர்', 'එක්වන්න')
                      : _text('Start', 'தொடங்கு', 'ආරම්භ කරන්න'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(MeetingModel meeting, bool isDark, bool isTamil) {
    final live = meeting.isLive;
    final color = live ? AppColors.success : AppColors.info;
    final label = live
        ? _text('Live', 'நேரலை', 'සජීවී')
        : _text('Scheduled', 'திட்டமிடப்பட்டது', 'සැලසුම් කර ඇත');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _copyMeetingLink(MeetingModel meeting) {
    Clipboard.setData(ClipboardData(text: meeting.meetingUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            'Meeting URL copied to clipboard.',
            'கூட்ட இணைப்பு கிளிப்போர்டுக்கு நகலெடுக்கப்பட்டது.',
            'රැස්වීමේ URL එක ක්ලිප් පුවරුවට පිටපත් කරන ලදී.',
          ),
        ),
      ),
    );
  }

  Widget _headerText(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  Widget _emptyMessage(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration(
    bool isDark, {
    String? hintText,
    Widget? suffixIcon,
  }) {
    final borderColor = isDark ? AppColors.lineDark : AppColors.lineLight;
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      border: Border.all(
        color: isDark ? AppColors.lineDark : AppColors.lineLight,
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
    );
  }
}
