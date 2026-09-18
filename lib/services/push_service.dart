import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';

/// Must be a top-level (or static) function, marked with this pragma, so
/// Android can call it in a fresh background isolate when a message arrives
/// while the app is fully killed. A plain "notification" payload (which is
/// all this app ever sends — see fcm.ts) is already shown by the OS without
/// any code running here; this exists so Firebase never warns about a
/// missing handler and so a future data-only payload has somewhere to go.
///
/// That fresh isolate never ran main() or any login flow, so Firebase must
/// be (re-)initialised here even though PushService.start already did it in
/// the foreground isolate — this call is cheap and idempotent.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

const _channelId = 'swarmangal_updates';
const _channelName = 'Swar Mangal updates';

/// Registers this device for push notifications and keeps the server's copy
/// of the token current. A no-op everywhere Firebase isn't configured yet
/// (no google-services.json) or in demo mode (there is no server to tell).
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _ready = false;
  ApiService? _api;
  String? _registeredToken;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  /// Call once after a real (non-demo) login. Safe to call again on every
  /// app resume — it only does the one-time setup once.
  Future<void> start(ApiService api) async {
    _api = api;
    if (_ready) {
      await _registerCurrentToken();
      return;
    }
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // No Firebase project configured on this build yet. This is the
      // expected state until google-services.json is added — push simply
      // stays off; nothing else in the app depends on it.
      debugPrint('[push] Firebase not configured, push disabled: $e');
      return;
    }
    try {
      final settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[push] notification permission denied by the user');
        return;
      }
      await _initLocalNotifications();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_showWhileForeground);
      FirebaseMessaging.instance.onTokenRefresh.listen(_register);
      _ready = true;
      await _registerCurrentToken();
    } catch (e) {
      debugPrint('[push] setup failed: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(settings: const InitializationSettings(android: androidInit));
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Approvals waiting, decisions made, and daily reminders.',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Android does not show a "notification" payload's system banner while
  /// the app is in the foreground (by design) — show it ourselves so
  /// foreground, background and killed all feel the same to the operator.
  void _showWhileForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      id: message.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token);
    } catch (e) {
      debugPrint('[push] could not read the device token: $e');
    }
  }

  Future<void> _register(String token) async {
    final api = _api;
    if (api == null) return;
    try {
      await api.registerPushToken(fcmToken: token, platform: Platform.isIOS ? 'ios' : 'android');
      _registeredToken = token;
    } catch (e) {
      debugPrint('[push] register failed (will retry next launch): $e');
    }
  }

  /// Called on sign-out, so a shared or handed-back device stops receiving
  /// this session's notifications once someone else signs in.
  Future<void> stop() async {
    final token = _registeredToken;
    final api = _api;
    _registeredToken = null;
    if (token == null || api == null) return;
    try {
      await api.unregisterPushToken(token);
    } catch (_) {
      // Best-effort: the server also drops a token the moment a send to it fails.
    }
  }
}
