import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {},
    );

    // Request permission Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // ── Jadwalkan notifikasi harian ───────────────────────────
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    await _plugin.cancel(1); // Cancel yang lama dulu

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Kalau sudah lewat, jadwalkan besok
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'finansa_daily',
      'Pengingat Harian FINANSA',
      channelDescription: 'Notifikasi pengingat mencatat transaksi harian',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4527A0),
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    final messages = [
      (
        '💰 Sudah catat transaksi hari ini?',
        'Jangan lupa catat pengeluaran dan emosimu hari ini di FINANSA!',
      ),
      (
        '📊 Cek keuanganmu yuk!',
        'Luangkan 1 menit untuk mencatat transaksi hari ini.',
      ),
      (
        '😊 Bagaimana emosimu hari ini?',
        'Catat transaksimu dan pilih emosimu di FINANSA.',
      ),
      (
        '🎯 Tetap on track!',
        'Cek progress budget dan goalmu hari ini di FINANSA.',
      ),
    ];

    final idx = DateTime.now().day % messages.length;
    final (title, body) = messages[idx];

    await _plugin.zonedSchedule(
      1,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Cancel semua notifikasi ───────────────────────────────
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Tampilkan notifikasi langsung (untuk test) ────────────
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'finansa_test',
      'Test Notifikasi',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      0,
      '✅ Notifikasi Aktif!',
      'FINANSA akan mengingatkanmu setiap hari.',
      details,
    );
  }
}
