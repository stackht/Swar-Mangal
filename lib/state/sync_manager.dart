import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/api.dart';
import '../services/api_service.dart';

/// The ONE centralized synchronization owner. No screen owns a timer.
///
/// Model:
///   backend bumps a per-entity revision on every successful write
///   → syncChanges({branch, knownRevisions}) returns current revisions
///   → if any differ, this manager advertises which entities changed
///   → affected screens reload ONLY those entities (via [SyncAware]).
///
/// Transport is revision polling, not a push channel: the Railway gateway
/// has no websocket, so we deliberately call this NEAR-REAL-TIME (mandate
/// §"near-real-time synchronization" wording).
class SyncManager extends ChangeNotifier {
  SyncManager();

  // -- state machine ------------------------------------------------
  SyncState _state = SyncState.synced;
  DateTime? _lastSyncedAt;
  String? _lastError;
  String _branch = 'ALL';
  final Map<String, int> _known = {};
  final Map<String, int> _server = {};
  Set<String> _changed = const {};
  Timer? _timer;
  AppLifecycleListener? _life;
  bool _enabled = false;
  bool _inFlight = false;
  ApiService? _svc;

  /// Attach the live/demo API service (called by the app on login/logout).
  void attach(ApiService? service) {
    _svc = service;
    if (service != null) _begin();
  }

  // ---- exposure ---------------------------------------------------
  SyncState get state => _state;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;
  String get branch => _branch;
  bool get offline => _state == SyncState.offline;
  bool get syncing => _state == SyncState.syncing;
  Set<String> get changedEntities => _changed;

  bool isSynced({required String branch}) => branch == _branch && _state == SyncState.synced;

  /// Entities this manager is currently advertising as needing reload.
  bool didChange(String entity) => _changed.contains(entity);

  /// Tracks whether a foreground sync beat has run (for the indicator).
  bool get hasSynced => _lastSyncedAt != null;

  // ---- lifecycle --------------------------------------------------
  /// Attach to the nearest context's lifecycle (call once from a top-level
  /// widget). Owns the single foreground timer — never per screen.
  void start(BuildContext context, {required void Function(String) onBranchChange}) {
    if (_enabled) return;
    _enabled = true;
    _life = AppLifecycleListener(
      onResume: () {
        _begin();
        _startTimer();
      },
      onPause: () {
        _stopTimer();
      },
      onDetach: () {
        _stopTimer();
      },
    );
    WidgetsBinding.instance.addObserver(_LifecycleBridge(onResume: () {
      _begin();
      _startTimer();
    }, onPause: _stopTimer));
    _startTimer();
  }

  void setBranch(String branch) {
    if (branch == _branch) return;
    _branch = branch;
    _known.clear(); // never carry another branch's revisions across
    _changed = const {};
    _lastError = null;
    _begin();
  }

  Future<void> syncNow() => _sync();

  void disposeSelf() {
    _stopTimer();
    _life?.dispose();
    super.dispose();
  }

  // ---- internals ---------------------------------------------------
  void _startTimer() {
    _stopTimer();
    // Reasonable foreground interval for a small academy; one timer, global.
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _sync());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _begin() async {
    _state = SyncState.syncing;
    notifyListeners();
    await _sync();
  }

  Future<void> _sync() async {
    if (_inFlight) return;
    final svc = _svc;
    if (svc == null) {
      _state = SyncState.offline;
      notifyListeners();
      return;
    }
    _inFlight = true;
    try {
      final res = await svc.syncChanges(branch: _branch, knownRevisions: _known);
      _server..clear();
      _server.addAll(res.revisions);
      _changed = _diff(_known, _server);
      _known.clear();
      _known.addAll(_server);
      _lastSyncedAt = DateTime.now();
      _lastError = null;
      _state = SyncState.synced;
    } on ApiUnreachable {
      _state = SyncState.offline;
      _lastError = 'Offline — last synced ${_ago()} ago';
    } catch (e) {
      _state = SyncState.syncError;
      _lastError = e.toString();
    } finally {
      _inFlight = false;
      notifyListeners(); // any changed entities advertised here
    }
  }

  Set<String> _diff(Map<String, int> known, Map<String, int> server) {
    final changed = <String>{};
    for (final entry in server.entries) {
      if (known[entry.key] != entry.value) changed.add(entry.key);
    }
    return changed;
  }

  String _ago() {
    final t = _lastSyncedAt;
    if (t == null) return '—';
    final min = DateTime.now().difference(t).inMinutes;
    return min == 0 ? 'just now' : '$min min';
  }
}

enum SyncState { online, offline, syncing, synced, syncError }

/// Tiny shim so [SyncManager] can observe lifecycle without re-typing the
/// observer contract repeatedly.
class _LifecycleBridge with WidgetsBindingObserver {
  _LifecycleBridge({required this.onResume, required this.onPause});
  final void Function() onResume;
  final void Function() onPause;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.paused:
        onPause();
      case AppLifecycleState.detached:
        onPause();
    }
  }
}

/// Convenience mixin for screens that must reload when a watched entity's
/// revision changes. Screens implement [syncEntities] + [reloadFromSync].
mixin SyncAware<T extends StatefulWidget> on State<T> {
  Set<String> get syncEntities;
  Future<void> reloadFromSync();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mgr = SyncScope.maybeOf(context);
    if (mgr == null) return;
    if (syncEntities.any(mgr.didChange)) {
      reloadFromSync();
    }
  }
}

/// Inherited handle so screens can find the SyncManager without Provider deps.
class SyncScope extends InheritedWidget {
  const SyncScope({super.key, required this.manager, required super.child});
  final SyncManager manager;

  static SyncManager? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SyncScope>()?.manager;

  @override
  bool updateShouldNotify(SyncScope oldWidget) => manager != oldWidget.manager;
}