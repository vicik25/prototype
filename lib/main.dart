import 'package:material_ui/material_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/beranda/beranda_page.dart';
import 'services/push_notification_service.dart';

// PENTING: Pertahankan Project URL Supabase milikmu yang sudah ada sebelumnya!
const String supabaseUrl = 'https://iztqfgppigrszlhpjrag.supabase.co';
const String supabasePublishableKey = 'sb_publishable_6XN965tY_BxfQNbIe_BE4g_nHnpfiBf';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: supabasePublishableKey,
  );

  // Inisialisasi Push Notification HP (otomatis dilewati jika berjalan di Web)
  await PushNotificationService.init();

  runApp(const SiDonorApp());
}

final supabase = Supabase.instance.client;

class SiDonorApp extends StatelessWidget {
  const SiDonorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiDonor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const BerandaPage(),
    );
  }
}
