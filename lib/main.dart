import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.instance.init();

  final prefs = await SharedPreferences.getInstance();
  final notifEnabled = prefs.getBool('notif_enabled') ?? true;
  if (notifEnabled) {
    await NotificationService.instance
        .scheduleDailyReminder(hour: 20, minute: 0);
  }

  runApp(
    const ProviderScope(child: FinansaApp()),
  );
}
