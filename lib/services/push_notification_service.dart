import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart';

/// Handler wajib di top-level untuk menangkap notifikasi saat aplikasi tertutup / di background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _urgentChannel = AndroidNotificationChannel(
    'sidonor_urgent_channel',
    'Notifikasi Penting SiDonor',
    description: 'Panggilan donor darah darurat dan status verifikasi akun',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Inisialisasi Firebase & Channel Notifikasi bersuara
  static Future<void> init() async {
    if (kIsWeb) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 1. Minta izin notifikasi (wajib untuk Android 13+ dan iOS)
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // 2. Setup plugin notifikasi lokal agar berbunyi meski aplikasi sedang dibuka
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
      await _localNotif.initialize(settings: initSettings);

      // 3. Daftarkan Notification Channel berprioritas tinggi (dengan suara) di Android
      await _localNotif
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_urgentChannel);

      // 4. Tangkap notifikasi saat aplikasi sedang aktif di layar (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notif = message.notification;
        if (notif != null) {
          _localNotif.show(
            id: notif.hashCode,
            title: notif.title,
            body: notif.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _urgentChannel.id,
                _urgentChannel.name,
                channelDescription: _urgentChannel.description,
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
            ),
          );
        }
      });

      // 5. Perbarui token otomatis jika Firebase me-refresh token perangkat
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen((newToken) async {
        final uid = supabase.auth.currentUser?.id;
        if (uid != null) {
          await supabase.from('pengguna').update({'fcm_token': newToken}).eq('id_pengguna', uid);
        }
      });
    } catch (e) {
      debugPrint('PushNotificationService init dilewati: $e');
    }
  }

  /// Simpan FCM Token HP pengguna ke database saat berhasil login
  static Future<void> simpanTokenKeSupabase(String userId) async {
    if (kIsWeb) return;
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await supabase.from('pengguna').update({'fcm_token': token}).eq('id_pengguna', userId);
      }
    } catch (e) {
      debugPrint('Gagal menyimpan FCM token: $e');
    }
  }

  /// Hapus FCM Token saat logout agar HP tidak menerima notifikasi akun sebelumnya
  static Future<void> hapusTokenDariSupabase(String userId) async {
    if (kIsWeb) return;
    try {
      await supabase.from('pengguna').update({'fcm_token': null}).eq('id_pengguna', userId);
    } catch (_) {}
  }
}
