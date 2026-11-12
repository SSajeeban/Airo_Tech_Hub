import 'package:flutter/material.dart';

/// Shared Material 3 icon catalog used throughout the application.
///
/// Keeping the glyph choices here prevents individual screens from drifting
/// between legacy, filled, and outlined icon styles.
abstract final class AppIcons {
  static const home = Icons.dashboard_customize_outlined;
  static const homeActive = Icons.dashboard_customize_rounded;
  static const groups = Icons.diversity_3_outlined;
  static const groupsActive = Icons.diversity_3_rounded;
  static const chat = Icons.forum_outlined;
  static const chatActive = Icons.forum_rounded;
  static const meetings = Icons.videocam_outlined;
  static const meetingsActive = Icons.videocam_rounded;
  static const library = Icons.auto_stories_outlined;
  static const libraryActive = Icons.auto_stories_rounded;

  static const add = Icons.add_rounded;
  static const back = Icons.arrow_back_rounded;
  static const calendar = Icons.calendar_month_outlined;
  static const close = Icons.close_rounded;
  static const copy = Icons.content_copy_rounded;
  static const delete = Icons.delete_forever_outlined;
  static const download = Icons.download_outlined;
  static const edit = Icons.edit_outlined;
  static const file = Icons.file_present_outlined;
  static const folder = Icons.folder_copy_outlined;
  static const folderAdd = Icons.create_new_folder_rounded;
  static const grid = Icons.grid_view_rounded;
  static const list = Icons.view_list_rounded;
  static const next = Icons.chevron_right_rounded;
  static const previous = Icons.chevron_left_rounded;
  static const search = Icons.manage_search_rounded;
  static const send = Icons.send_rounded;
  static const upload = Icons.file_upload_outlined;
  static const view = Icons.visibility_outlined;

  static const attach = Icons.attach_file_rounded;
  static const conversation = Icons.mark_unread_chat_alt_outlined;
  static const notification = Icons.notifications_none_outlined;
  static const participants = Icons.person_add_alt_1_rounded;
  static const schedule = Icons.event_available_outlined;
  static const settings = Icons.tune_rounded;
  static const voice = Icons.mic_none_rounded;
}
