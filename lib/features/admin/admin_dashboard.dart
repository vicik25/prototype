import 'package:material_ui/material_ui.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../models/pengguna_model.dart';
import '../../services/auth_service.dart';
import 'tabs/kegiatan_laporan_pengaturan_tab.dart';
import 'tabs/permintaan_donor_tab.dart';
import 'tabs/verifikasi_daftar_pendonor_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return OnBuilder<PenggunaModel?>.data(
      listenTo: currentUserRM,
      builder: (admin) {
        if (admin == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final isDesktop = Responsive.isDesktop(context);
        final tabs = [
          VerifikasiDaftarPendonorTab(admin: admin),
          PermintaanDonorTab(admin: admin),
          KegiatanLaporanPengaturanTab(admin: admin),
        ];

        return Scaffold(
          appBar: CustomAppBar(
            user: admin,
            subtitle: 'Admin UKM KSR • ${admin.namaLengkap}',
            onNotifActionTap: (notif) {
              if (notif.tipe == 'permintaan_darah') {
                setState(() => _selectedIndex = 1);
              } else if (notif.tipe == 'kegiatan') {
                setState(() => _selectedIndex = 2);
              } else {
                setState(() => _selectedIndex = 0);
              }
            },
          ),
          body: Row(
            children: [
              if (isDesktop)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: AppColors.surface,
                  selectedIconTheme: const IconThemeData(color: AppColors.primary),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.verified_user_outlined),
                      selectedIcon: Icon(Icons.verified_user_rounded),
                      label: Text('Pendonor'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bloodtype_outlined),
                      selectedIcon: Icon(Icons.bloodtype_rounded),
                      label: Text('Permintaan'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.analytics_outlined),
                      selectedIcon: Icon(Icons.analytics_rounded),
                      label: Text('Kegiatan & Sistem'),
                    ),
                  ],
                ),
              if (isDesktop) const VerticalDivider(width: 1, color: AppColors.border),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: tabs[_selectedIndex],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.verified_user_outlined), label: 'Pendonor'),
                    NavigationDestination(icon: Icon(Icons.bloodtype_outlined), label: 'Permintaan'),
                    NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Sistem'),
                  ],
                ),
        );
      },
    );
  }
}