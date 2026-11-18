import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_status.dart';
import '../../core/utils/donor_helper.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/status_badge.dart';
import '../../main.dart';
import '../../models/kegiatan_model.dart';
import '../../services/kegiatan_service.dart';
import '../auth/login_page.dart';
import '../pemohon/permintaan_publik_page.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  late Future<List<KegiatanModel>> _kegiatanFuture;
  int _jumlahPendonorAktif = 0;

  @override
  void initState() {
    super.initState();
    _kegiatanFuture = KegiatanService.getKegiatanDisetujui();
    _loadStatistikPublik();
  }

  Future<void> _loadStatistikPublik() async {
    try {
      final res = await supabase
          .from('profil_pendonor')
          .select('id_profil')
          .eq('ketersediaan', AppStatus.tersediaAktif);
      if (mounted) {
        setState(() {
          _jumlahPendonorAktif = (res as List).length;
        });
      }
    } catch (_) {}
  }

  void _bukaPortalLogin(String role) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage(expectedRole: role)));
  }

  void _bukaLayananPemohon(int tabIndex) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PermintaanPublikPage(initialTabIndex: tabIndex)));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Navbar Publik
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bloodtype_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SiDonor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
                          Text(
                            'Koordinasi Pendonor Darah Kampus',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (isDesktop) ...[
                        OutlinedButton.icon(
                          onPressed: () => _bukaLayananPemohon(0),
                          icon: const Icon(Icons.emergency_outlined, size: 18),
                          label: const Text('Butuh Darah / Lacak'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _bukaPortalLogin(AppStatus.roleMahasiswa),
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text('Masuk Portal Mahasiswa'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Hero Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF1F2), Color(0xFFF8FAFC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: isDesktop ? 56 : 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_outlined, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Sinergi UKM KSR & UDD PMI Kota Tasikmalaya',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Setetes Darah Mahasiswa,\nHarapan Hidup bagi Sesama.',
                        style: TextStyle(
                          fontSize: isDesktop ? 42 : 28,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const SizedBox(
                        width: 680,
                        child: Text(
                          'Platform pendataan dan koordinasi cepat pendonor darah sukarela di lingkungan kampus. Pemeriksaan kesehatan, uji silang, dan pengambilan darah tetap dilaksanakan oleh petugas medis UDD PMI.',
                          style: TextStyle(fontSize: 15, height: 1.6, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Layanan Pemohon Darah & Pelacakan Publik
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _bukaLayananPemohon(0),
                            icon: const Icon(Icons.bloodtype_outlined, size: 19),
                            label: const Text('Ajukan Permintaan Darah'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _bukaLayananPemohon(1),
                            style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                            icon: const Icon(Icons.track_changes_rounded, size: 19),
                            label: const Text('Lacak Status Permintaan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Statistik Ringkas Publik
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          _StatChip(
                            icon: Icons.people_alt_rounded,
                            label: 'Pendonor Siaga Aktif',
                            value: '$_jumlahPendonorAktif Mahasiswa',
                          ),
                          const _StatChip(
                            icon: Icons.timer_outlined,
                            label: 'Standar Jeda Donor',
                            value: '61 Hari (Whole Blood)',
                          ),
                          const _StatChip(
                            icon: Icons.shield_outlined,
                            label: 'Perlindungan Data',
                            value: 'Sesuai UU No. 27/2022',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bagian 3 Portal Akses Utama
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pilih Portal Akses', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text(
                        'Silakan masuk sesuai peran Anda di lingkungan kampus untuk mulai menggunakan SiDonor.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cards = [
                            _PortalCard(
                              title: 'Portal Mahasiswa',
                              subtitle: 'Calon Pendonor & Pendonor',
                              description: 'Daftar sebagai pendonor sukarela, isi skrining kelayakan mandiri, tanggapi panggilan donor darurat, dan pantau jeda 61 hari.',
                              icon: Icons.volunteer_activism_rounded,
                              accentColor: AppColors.primary,
                              buttonText: 'Masuk / Daftar Mahasiswa',
                              onTap: () => _bukaPortalLogin(AppStatus.roleMahasiswa),
                            ),
                            _PortalCard(
                              title: 'Portal Admin UKM KSR',
                              subtitle: 'Koordinator & Verifikator',
                              description: 'Verifikasi pendaftar mahasiswa, kelola permintaan darah rumah sakit, lakukan pencocokan gelombang, dan catat riwayat donor.',
                              icon: Icons.admin_panel_settings_rounded,
                              accentColor: const Color(0xFF0F172A),
                              buttonText: 'Masuk Admin KSR',
                              onTap: () => _bukaPortalLogin(AppStatus.roleAdmin),
                            ),
                            _PortalCard(
                              title: 'Portal Penyelenggara',
                              subtitle: 'UKM, Himpunan, & BEM',
                              description: 'Ajukan jadwal kegiatan donor darah kampus agar dipublikasikan ke mahasiswa dan pantau jumlah pendaftar secara agregat.',
                              icon: Icons.event_note_rounded,
                              accentColor: const Color(0xFF0284C7),
                              buttonText: 'Masuk Penyelenggara',
                              onTap: () => _bukaPortalLogin(AppStatus.rolePenyelenggara),
                            ),
                          ];

                          if (constraints.maxWidth >= 860) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 16),
                                Expanded(child: cards[1]),
                                const SizedBox(width: 16),
                                Expanded(child: cards[2]),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 16),
                              cards[1],
                              const SizedBox(height: 16),
                              cards[2],
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 44),

                      // Papan Pengumuman Kegiatan Donor Kampus
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Agenda Kegiatan Donor Darah',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Kegiatan terverifikasi yang terbuka untuk pendaftaran mahasiswa.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: 'Muat ulang jadwal',
                            onPressed: () {
                              setState(() {
                                _kegiatanFuture = KegiatanService.getKegiatanDisetujui();
                              });
                            },
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      FutureBuilder<List<KegiatanModel>>(
                        future: _kegiatanFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
                            );
                          }

                          final kegiatanList = snapshot.data ?? [];
                          if (kegiatanList.isEmpty) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 36,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Belum ada jadwal kegiatan donor yang tayang saat ini.',
                                        style: TextStyle(color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 12),
                                      OutlinedButton(
                                        onPressed: () => _bukaPortalLogin(AppStatus.roleMahasiswa),
                                        child: const Text('Daftar Sebagai Pendonor Siaga'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: kegiatanList.map((keg) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 28),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  keg.nama,
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                                ),
                                                StatusBadge(status: keg.status),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '📅 ${DonorHelper.formatTanggal(keg.tanggal)}  •  📍 ${keg.lokasi}',
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Sisa Kuota: ${keg.sisaKuota} dari ${keg.kuota} peserta',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12.5,
                                                color: AppColors.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () => _bukaPortalLogin(AppStatus.roleMahasiswa),
                                        child: const Text('Ikut Donor'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.surface,
              child: const Center(
                child: Text(
                  'SiDonor — Sistem Pendataan & Koordinasi Mahasiswa Pendonor Darah Kampus (Kelompok 4 RKPL)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String buttonText;
  final VoidCallback onTap;

  const _PortalCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: accentColor),
            ),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
