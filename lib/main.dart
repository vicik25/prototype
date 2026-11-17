import 'package:material_ui/material_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/beranda/beranda_page.dart';

// Pastikan Project URL kamu sudah terisi di sini
const String supabaseUrl = 'https://iztqfgppigrszlhpjrag.supabase.co';
const String supabasePublishableKey = 'sb_publishable_6XN965tY_BxfQNbIe_BE4g_nHnpfiBf';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // ignore: deprecated_member_use
  await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);

  runApp(const SiDonorApp());
}

final supabase = Supabase.instance.client;

class SiDonorApp extends StatelessWidget {
  const SiDonorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiDonor - Sistem Pendataan & Koordinasi Pendonor Darah Kampus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const BerandaPage(),
    );
  }
}
