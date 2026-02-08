import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'injection.dart' as di;
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('Notification tapped in background: ${notificationResponse.payload}');
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const LinuxInitializationSettings linuxInit = LinuxInitializationSettings(defaultActionName: 'Open');
    const WindowsInitializationSettings windowInit = WindowsInitializationSettings(
        appName: 'Svenska restaurant',
        appUserModelId: 'com.svenska.restaurant.app',
        guid: '9f8b4d8d-2d9d-4e9d-8d8d-9d8d8d8d8d8d',
    );


    await flutterLocalNotificationsPlugin.initialize(
      onDidReceiveNotificationResponse: (response) => debugPrint(response.payload),
      settings: InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        macOS: iosInit,
        linux: linuxInit,
        windows: windowInit
      )
    );

    await dotenv.load(fileName: ".env");
    await di.init();

    runApp(const MyApp());
  } catch (e) {
    debugPrint("INIT ERROR: $e");
    runApp(const MyApp());
  }
}