import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';

/// Lets a screen disable an [UnsavedChangesGuard] once its data is saved.
///
/// Call [markSaved] before popping from a save path.
class UnsavedChangesController extends ChangeNotifier {
  bool _saved = false;

  bool get saved => _saved;

  void markSaved() {
    if (_saved) return;
    _saved = true;
    notifyListeners();
  }
}

/// Asks for confirmation before a route with unsaved edits is popped
/// (back button, back gesture, AppBar back, `maybePop`).
///
/// Usage:
/// ```dart
/// final _guard = UnsavedChangesController();
/// UnsavedChangesGuard(isDirty: _dirty, controller: _guard, child: ...);
/// // On save success: `_guard.markSaved(); Navigator.of(context).pop(true);`
/// ```
/// Note: a direct `Navigator.pop` never consults [PopScope]; the controller
/// is for save paths that use `maybePop` or pop after an async gap.
class UnsavedChangesGuard extends StatefulWidget {
  const UnsavedChangesGuard({
    super.key,
    required this.isDirty,
    required this.child,
    this.controller,
  });

  final bool isDirty;
  final Widget child;
  final UnsavedChangesController? controller;

  @override
  State<UnsavedChangesGuard> createState() => _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends State<UnsavedChangesGuard> {
  bool _prompting = false;

  Future<void> _onPop(BuildContext context, bool didPop) async {
    if (didPop || _prompting) return;
    _prompting = true;
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context)!;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.discardChangesTitle),
        content: Text(l10n.discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    _prompting = false;
    if (!mounted) return;
    if (discard == true && (ModalRoute.of(this.context)?.isCurrent ?? false)) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller ?? const _NoListenable(),
      builder: (context, _) {
        final blocked = widget.isDirty && !(widget.controller?.saved ?? false);
        return PopScope(
          canPop: !blocked,
          onPopInvokedWithResult: (didPop, _) => _onPop(context, didPop),
          child: widget.child,
        );
      },
    );
  }
}

class _NoListenable implements Listenable {
  const _NoListenable();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}
