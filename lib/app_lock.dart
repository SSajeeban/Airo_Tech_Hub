import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LockType { none, pin, password, pattern }

String lockTypeLabel(LockType type) {
  switch (type) {
    case LockType.none:
      return 'None';
    case LockType.pin:
      return 'PIN';
    case LockType.password:
      return 'Password';
    case LockType.pattern:
      return 'Pattern';
  }
}

/// Stores the lock type and a salted SHA-256 hash of the secret.
/// The PIN / password / pattern itself is never saved as plain text.
class AppLockStore {
  AppLockStore(this.memberId);

  final String memberId;

  String get _typeKey => 'member_${memberId}_lock_type';
  String get _saltKey => 'member_${memberId}_lock_salt';
  String get _hashKey => 'member_${memberId}_lock_hash';

  static String _hash(String salt, String secret) {
    return sha256.convert(utf8.encode('$salt:$secret')).toString();
  }

  Future<LockType> loadType() async {
    final p = await SharedPreferences.getInstance();
    final name = p.getString(_typeKey);
    for (final t in LockType.values) {
      if (t.name == name) return t;
    }
    return LockType.none;
  }

  Future<void> save(LockType type, String secret) async {
    final p = await SharedPreferences.getInstance();
    final rnd = Random.secure();
    final salt = base64UrlEncode(
      List<int>.generate(16, (_) => rnd.nextInt(256)),
    );
    await p.setString(_saltKey, salt);
    await p.setString(_hashKey, _hash(salt, secret));
    await p.setString(_typeKey, type.name);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_typeKey);
    await p.remove(_saltKey);
    await p.remove(_hashKey);
  }

  Future<bool> verify(String secret) async {
    final p = await SharedPreferences.getInstance();
    final salt = p.getString(_saltKey);
    final hash = p.getString(_hashKey);
    if (salt == null || hash == null) return false;
    return _hash(salt, secret) == hash;
  }
}

/// 3x3 dot board. Calls [onCompleted] with the dot indexes (0-8) in order.
class PatternPad extends StatefulWidget {
  const PatternPad({super.key, required this.onCompleted});

  final void Function(List<int> pattern) onCompleted;

  @override
  State<PatternPad> createState() => _PatternPadState();
}

class _PatternPadState extends State<PatternPad> {
  static const double _boardSize = 260;
  final List<int> _selected = [];
  Offset? _current;

  Offset _center(int i) {
    const cell = _boardSize / 3;
    return Offset((i % 3) * cell + cell / 2, (i ~/ 3) * cell + cell / 2);
  }

  void _hit(Offset pos) {
    for (var i = 0; i < 9; i++) {
      if (!_selected.contains(i) && (pos - _center(i)).distance < 34) {
        _selected.add(i);
        HapticFeedback.selectionClick();
        break;
      }
    }
  }

  void _start(Offset pos) {
    setState(() {
      _selected.clear();
      _current = pos;
      _hit(pos);
    });
  }

  void _update(Offset pos) {
    setState(() {
      _current = pos;
      _hit(pos);
    });
  }

  void _end() {
    final result = List<int>.from(_selected);
    setState(() {
      _selected.clear();
      _current = null;
    });
    if (result.isNotEmpty) widget.onCompleted(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: _boardSize,
      height: _boardSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _start(d.localPosition),
        onPanUpdate: (d) => _update(d.localPosition),
        onPanEnd: (_) => _end(),
        child: CustomPaint(
          painter: _PatternPainter(
            selected: List<int>.from(_selected),
            current: _current,
            activeColor: colors.primary,
            idleColor: colors.outline,
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.selected,
    required this.current,
    required this.activeColor,
    required this.idleColor,
  });

  final List<int> selected;
  final Offset? current;
  final Color activeColor;
  final Color idleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 3;
    Offset c(int i) =>
        Offset((i % 3) * cell + cell / 2, (i ~/ 3) * cell + cell / 2);

    final line = Paint()
      ..color = activeColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < selected.length - 1; i++) {
      canvas.drawLine(c(selected[i]), c(selected[i + 1]), line);
    }
    final cur = current;
    if (selected.isNotEmpty && cur != null) {
      canvas.drawLine(c(selected.last), cur, line);
    }
    for (var i = 0; i < 9; i++) {
      final on = selected.contains(i);
      canvas.drawCircle(
        c(i),
        on ? 14 : 9,
        Paint()..color = on ? activeColor : idleColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) => true;
}

/// Screen used to create a new PIN / password / pattern (asks twice).
class LockSetupScreen extends StatefulWidget {
  const LockSetupScreen({super.key, required this.type, required this.store});

  final LockType type;
  final AppLockStore store;

  @override
  State<LockSetupScreen> createState() => _LockSetupScreenState();
}

class _LockSetupScreenState extends State<LockSetupScreen> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  String? _firstPattern;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  Future<void> _saveText() async {
    final a = _first.text;
    final b = _second.text;
    if (a.length < 4) {
      setState(() => _error = 'Use at least 4 characters');
      return;
    }
    if (a != b) {
      setState(() => _error = 'Entries do not match');
      return;
    }
    await widget.store.save(widget.type, a);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _patternDone(List<int> p) async {
    final s = p.join('-');
    if (p.length < 4) {
      setState(() => _error = 'Connect at least 4 dots');
      return;
    }
    if (_firstPattern == null) {
      setState(() {
        _firstPattern = s;
        _error = null;
      });
      return;
    }
    if (s != _firstPattern) {
      setState(() {
        _firstPattern = null;
        _error = 'Patterns did not match. Try again.';
      });
      return;
    }
    await widget.store.save(LockType.pattern, s);
    if (mounted) Navigator.pop(context, true);
  }

  Widget _errorText(BuildContext context) {
    if (_error == null) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        _error!,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget _textBody(BuildContext context) {
    final isPin = widget.type == LockType.pin;
    final label = isPin ? 'PIN' : 'Password';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
          controller: _first,
          obscureText: true,
          keyboardType: isPin ? TextInputType.number : TextInputType.text,
          inputFormatters: isPin
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(labelText: 'Enter $label'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _second,
          obscureText: true,
          keyboardType: isPin ? TextInputType.number : TextInputType.text,
          inputFormatters: isPin
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(labelText: 'Confirm $label'),
        ),
        _errorText(context),
        const SizedBox(height: 12),
        FilledButton(onPressed: _saveText, child: const Text('Save')),
      ],
    );
  }

  Widget _patternBody(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _firstPattern == null
                  ? 'Draw your pattern (at least 4 dots)'
                  : 'Draw the pattern again to confirm',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PatternPad(onCompleted: _patternDone),
            _errorText(context),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set ${lockTypeLabel(widget.type)}')),
      body: widget.type == LockType.pattern
          ? _patternBody(context)
          : _textBody(context),
    );
  }
}

/// Full-screen unlock screen. Used when the app opens and when the person
/// must confirm the current lock before changing it.
class LockUnlockScreen extends StatefulWidget {
  const LockUnlockScreen({
    super.key,
    required this.type,
    required this.store,
    required this.onUnlocked,
    required this.onExit,
    this.onFingerprint,
    this.title = 'Unlock Airo Tech Hub',
  });

  final LockType type;
  final AppLockStore store;
  final VoidCallback onUnlocked;
  final VoidCallback onExit;
  final Future<void> Function()? onFingerprint;
  final String title;

  @override
  State<LockUnlockScreen> createState() => _LockUnlockScreenState();
}

class _LockUnlockScreenState extends State<LockUnlockScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitText() async {
    final ok = await widget.store.verify(_controller.text);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      _controller.clear();
      setState(() => _error = 'Wrong ${lockTypeLabel(widget.type)}');
    }
  }

  Future<void> _submitPattern(List<int> p) async {
    final ok = await widget.store.verify(p.join('-'));
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() => _error = 'Wrong pattern');
    }
  }

  List<Widget> _textInputs() {
    final isPin = widget.type == LockType.pin;
    return [
      SizedBox(
        width: 280,
        child: TextField(
          controller: _controller,
          obscureText: true,
          autofocus: true,
          keyboardType: isPin ? TextInputType.number : TextInputType.text,
          inputFormatters: isPin
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(labelText: lockTypeLabel(widget.type)),
          onSubmitted: (_) => _submitText(),
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(onPressed: _submitText, child: const Text('Unlock')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fingerprint = widget.onFingerprint;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 48, color: colors.primary),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (widget.type == LockType.pattern)
                  PatternPad(onCompleted: _submitPattern)
                else
                  ..._textInputs(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                const SizedBox(height: 16),
                if (fingerprint != null)
                  TextButton.icon(
                    onPressed: () => fingerprint(),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use fingerprint'),
                  ),
                TextButton(
                  onPressed: widget.onExit,
                  child: const Text('Exit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Samsung-style flow: confirm the current lock (if any), pick a lock type
/// (None / PIN / Password / Pattern), then set it. Returns true if changed.
Future<bool> configureScreenLock(
  BuildContext context,
  AppLockStore store,
) async {
  final current = await store.loadType();
  if (!context.mounted) return false;

  if (current != LockType.none) {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (routeContext) => LockUnlockScreen(
          type: current,
          store: store,
          title: 'Confirm current screen lock',
          onUnlocked: () => Navigator.pop(routeContext, true),
          onExit: () => Navigator.pop(routeContext, false),
        ),
      ),
    );
    if (ok != true || !context.mounted) return false;
  }

  final picked = await showDialog<LockType>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Screen lock type'),
      children: [
        for (final t in LockType.values)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, t),
            child: Text(
              t == current
                  ? '${lockTypeLabel(t)}  (current)'
                  : lockTypeLabel(t),
            ),
          ),
      ],
    ),
  );
  if (picked == null || !context.mounted) return false;

  if (picked == LockType.none) {
    await store.clear();
    return true;
  }

  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => LockSetupScreen(type: picked, store: store),
    ),
  );
  return saved == true;
}
