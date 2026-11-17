import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_status.dart';
import '../../../core/utils/donor_helper.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/pengguna_model.dart';

class DigitalDonorCard extends StatelessWidget {
  final PenggunaModel user;
  final int jedaHari;
  final bool isUpdatingStatus;
  final ValueChanged<bool> onToggleKetersediaan;

  const DigitalDonorCard({
    super.key,
    required this.user,
    required this.jedaHari,
    required this.isUpdatingStatus,
    required this.onToggleKetersediaan,
  });

  @override
  Widget build(BuildContext context) {
    final profil = user.profilPendonor;
    final bisaDonor = DonorHelper.isBisaDonor(profil?.tanggalDonorTerakhir, jedaHari: jedaHari);
    final sisaHari = DonorHelper.sisaHariJeda(profil?.tanggalDonorTerakhir, jedaHari: jedaHari);
    final tglBolehLagi = DonorHelper.hitungTanggalBolehDonor(profil?.tanggalDonorTerakhir, jedaHari: jedaHari);
    final isAktif = profil?.ketersediaan == AppStatus.tersediaAktif;

    final progress = jedaHari > 0 ? ((jedaHari - sisaHari) / jedaHari).clamp(0.0, 1.0) : 1.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Atas: Label Kartu & Badge Golongan Darah
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bloodtype_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'KARTU PENDONOR DIGITAL',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.namaLengkap,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NPM: ${user.npm ?? '-'}  •  ${user.programStudi ?? '-'}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Kotak Golongan Darah & Rhesus
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        profil?.goldarLengkap ?? '-',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const Text(
                        'GOL. DARAH',
                        style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status Akun & Status Verifikasi Golongan Darah
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(status: user.statusAkun, fontSize: 11.5),
                if (profil != null) StatusBadge(status: 'Goldar: ${profil.statusGolonganDarah}', fontSize: 11.5),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
            const SizedBox(height: 18),

            // Pantauan Jeda Donor (61 Hari)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      bisaDonor ? Icons.check_circle_rounded : Icons.hourglass_bottom_rounded,
                      color: bisaDonor ? AppColors.success : AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bisaDonor ? AppStatus.jedaBisaDonor : AppStatus.jedaBelumBisa,
                      style: TextStyle(
                        color: bisaDonor ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  bisaDonor
                      ? (profil?.tanggalDonorTerakhir == null
                            ? 'Belum ada riwayat donor'
                            : 'Terakhir: ${DonorHelper.formatTanggal(profil?.tanggalDonorTerakhir)}')
                      : 'Sisa $sisaHari hari lagi',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                ),
              ],
            ),

            if (!bisaDonor) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Dapat mendonor kembali mulai ${DonorHelper.formatTanggal(tglBolehLagi)} (Jeda $jedaHari hari)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5),
              ),
            ],

            const SizedBox(height: 18),

            // Toggle Ketersediaan Panggilan Donor (FR-F5-14)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status Ketersediaan Panggilan',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          isAktif
                              ? 'Aktif menerima notifikasi permintaan darah'
                              : 'Nonaktif (tidak menerima notifikasi darurat)',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  if (isUpdatingStatus)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  else
                    Switch(value: isAktif, activeThumbColor: AppColors.success, onChanged: onToggleKetersediaan),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
