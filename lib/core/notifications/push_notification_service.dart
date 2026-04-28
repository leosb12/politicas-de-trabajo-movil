import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/auth/domain/entities/authenticated_user.dart';
import '../network/network_constants.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.bootstrap();
  PushNotificationService.logRemoteMessage('background', message);
}

class PushNotificationService {
  PushNotificationService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'politicas_push_channel',
    'Notificaciones push',
    description: 'Canal para notificaciones push del backend.',
    importance: Importance.high,
  );

  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _bootstrapCompleted = false;
  static bool _localNotificationsReady = false;

  bool _initialized = false;
  AuthenticatedUser? _authenticatedUser;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageTapSubscription;

  static Future<void> bootstrap() async {
    if (_bootstrapCompleted || !_supportsPushNotifications) {
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _bootstrapCompleted = true;
    } catch (error, stackTrace) {
      developer.log(
        '[PUSH] Firebase bootstrap skipped: $error',
        name: 'PushNotificationService',
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint('[PUSH] Firebase bootstrap skipped: $error');
    }
  }

  Future<void> initialize() async {
    if (_initialized || !_supportsPushNotifications) {
      return;
    }

    await bootstrap();
    if (!_bootstrapCompleted) {
      return;
    }

    await _initializeLocalNotifications();
    await _requestPermissions();
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) async {
      logRemoteMessage('foreground', message);
      await _showForegroundNotification(message);
    });

    _messageTapSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen((
      RemoteMessage message,
    ) {
      logRemoteMessage('tap', message);
    });

    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      logRemoteMessage('initial', initialMessage);
    }

    _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
        .listen((String token) async {
          developer.log(
            '[PUSH] FCM token refreshed',
            name: 'PushNotificationService',
          );
          debugPrint('[PUSH] FCM token refreshed');
          await _registerTokenIfPossible(token);
        });

    _initialized = true;
  }

  Future<void> syncForUser(AuthenticatedUser? user) async {
    _authenticatedUser = user;
    if (user == null) {
      return;
    }

    await initialize();
    if (!_bootstrapCompleted) {
      return;
    }

    final String? token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) {
      developer.log(
        '[PUSH] No FCM token available for user=${user.id}',
        name: 'PushNotificationService',
      );
      debugPrint('[PUSH] No FCM token available for user=${user.id}');
      return;
    }

    await _registerToken(token.trim(), user);
  }

  void clearAuthenticatedUser() {
    _authenticatedUser = null;
  }

  Future<void> _registerTokenIfPossible(String token) async {
    final AuthenticatedUser? user = _authenticatedUser;
    if (user == null || token.trim().isEmpty) {
      return;
    }

    await _registerToken(token.trim(), user);
  }

  Future<void> _registerToken(String token, AuthenticatedUser user) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'userId': user.id,
      'token': token,
      'platform': _platformName,
      'role': user.rol,
    };

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        NetworkConstants.mobileDeviceTokensPath,
        data: jsonEncode(payload),
        options: Options(
          headers: <String, String>{'X-User-Id': user.id},
          contentType: Headers.jsonContentType,
        ),
      );

      developer.log(
        '[PUSH] Token registered for user=${user.id} status=${response.statusCode}',
        name: 'PushNotificationService',
      );
      debugPrint(
        '[PUSH] Token registered for user=${user.id} status=${response.statusCode}',
      );
    } on DioException catch (error, stackTrace) {
      developer.log(
        '[PUSH] Token registration failed user=${user.id} '
        'status=${error.response?.statusCode} '
        'message=${error.message}',
        name: 'PushNotificationService',
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint(
        '[PUSH] Token registration failed user=${user.id} '
        'status=${error.response?.statusCode} '
        'message=${error.message}',
      );
    } catch (error, stackTrace) {
      developer.log(
        '[PUSH] Unexpected token registration failure user=${user.id}: $error',
        name: 'PushNotificationService',
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint(
        '[PUSH] Unexpected token registration failure user=${user.id}: $error',
      );
    }
  }

  Future<void> _requestPermissions() async {
    final NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

    developer.log(
      '[PUSH] Permission status=${settings.authorizationStatus.name}',
      name: 'PushNotificationService',
    );
    debugPrint('[PUSH] Permission status=${settings.authorizationStatus.name}');

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsReady) {
      return;
    }

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('ic_stat_notification');
    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: darwinInitializationSettings,
        );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (
        NotificationResponse notificationResponse,
      ) {
        developer.log(
          '[PUSH] Local notification tapped payload=${notificationResponse.payload}',
          name: 'PushNotificationService',
        );
        debugPrint(
          '[PUSH] Local notification tapped payload=${notificationResponse.payload}',
        );
      },
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    _localNotificationsReady = true;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final String? title = notification?.title ?? message.data['title'];
    final String? body = notification?.body ?? message.data['body'];

    if ((title == null || title.trim().isEmpty) &&
        (body == null || body.trim().isEmpty)) {
      return;
    }

    await _localNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_notification',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void logRemoteMessage(String source, RemoteMessage message) {
    developer.log(
      '[PUSH][$source] messageId=${message.messageId} '
      'title=${message.notification?.title} '
      'body=${message.notification?.body} '
      'data=${message.data}',
      name: 'PushNotificationService',
    );
    debugPrint(
      '[PUSH][$source] messageId=${message.messageId} '
      'title=${message.notification?.title} '
      'body=${message.notification?.body} '
      'data=${message.data}',
    );
  }

  static bool get _supportsPushNotifications {
    if (kIsWeb) {
      return false;
    }

    return Platform.isAndroid || Platform.isIOS;
  }

  static String get _platformName {
    if (kIsWeb) {
      return 'WEB';
    }
    if (Platform.isAndroid) {
      return 'ANDROID';
    }
    if (Platform.isIOS) {
      return 'IOS';
    }
    return 'UNKNOWN';
  }
}
