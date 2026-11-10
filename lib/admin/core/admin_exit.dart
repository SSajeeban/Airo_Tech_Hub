import 'package:flutter/widgets.dart';

class AdminExit extends InheritedWidget {
  final VoidCallback onExit;

  const AdminExit({super.key, required this.onExit, required super.child});

  static VoidCallback? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdminExit>()?.onExit;
  }

  @override
  bool updateShouldNotify(AdminExit oldWidget) => onExit != oldWidget.onExit;
}

