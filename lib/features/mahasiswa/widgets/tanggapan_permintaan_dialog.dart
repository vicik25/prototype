import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_status.dart';
import '../../../models/pengguna_model.dart';
import '../../../models/permintaan_model.dart';
import '../../../services/permintaan_service.dart';
import 'skrining_dialog.dart';

class TanggapanPermintaanDialog extends StatefulWidget {
  final UndanganNotifikasiModel undangan;
  final PenggunaModel mahasiswa;

  const TanggapanPermintaanDialog({super.key, required this.undangan, required this.mahasiswa});

  static Future<bool?> show(
    BuildContext context, {
    required UndanganNotifikasiModel undangan,
    required PenggunaModel mahasiswa,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => TanggapanPermintaanDialog(undangan: undangan, mahasiswa: mahasiswa),
    );
  }

  @override
  State<TanggapanPermintaanDialog> createState() => _TanggapanPermintaanDialogState();
}

class _TanggapanPermintaanDialogState extends State<TanggapanPermintaanDialog> {
  bool _isLoading = false;

  Future<void> _handleBersedia() async {
    // 1. Wajib skrining ulang setiap kali menanggapi permintaan (FR-F3-11)
    final hasilSkrining = await SkriningDialog.show(
      context,
      user: widget.mahasiswa,
      idPermintaan: widget.undangan.idPermintaan,
    );

    if (!mounted) return;
    if (hasilSkrining == null) return;

    // 2. Cegah Bersedia jika hasil skrining ulang Belum memenuhi syarat awal (FR-F3-12)
    if (hasilSkrining != AppStatus.skriningMemenuhi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak dapat menyatakan bersedia karena hasil skrining ulang belum memenuhi syarat awal.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // 3. Konfirmasi akhir sebelum mencatat kesediaan
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Kesediaan Donor'),
        content: const Text(
          'Dengan menekan "Ya, Saya Bersedia", Admin UKM KSR akan segera menghubungi Anda melalui WhatsApp atau email untuk koordinasi jadwal donor di UDD PMI.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Ya, Saya Bersedia'),
          ),
        ],
      ),
    );

    if (yakin != true || !mounted) return;
    await _kirimTanggapan(AppStatus.tanggapanBersedia);
  }

  Future<void> _handleTunda() async {
    final tgl = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: widget.undangan.batasRespons,
    );
    if (tgl == null || !mounted) return;
    await _kirimTanggapan(AppStatus.tanggapanDitunda, tundaHingga: tgl);
  }

  Future<void> _kirimTanggapan(String status, {DateTime? tundaHingga}) async {
    setState(() => _isLoading = true);
    try {
      await PermintaanService.tanggapiUndangan(
        undangan: widget.undangan,
        mahasiswa: widget.mahasiswa,
        tanggapanBaru: status,
        tundaHingga: tundaHingga,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tanggapan "$status" berhasil dicatat. Terima kasih!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal mengirim tanggapan: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final minta = widget.undangan.permintaan;
    final sudahDitutup =
        minta?.status == AppStatus.mintaDitutup ||
        minta?.status == AppStatus.mintaDibatalkan ||
        minta?.status == AppStatus.mintaTerlaksana;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.bloodtype_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Panggilan Kebutuhan Darah',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 16),

              // Detail Permintaan (Tanpa kontak pemohon sesuai BR-28)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Golongan Darah', value: minta?.goldarLengkap ?? '-'),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Rumah Sakit / Lokasi', value: minta?.rumahSakit ?? '-'),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Kebutuhan', value: '${minta?.jumlahKantong ?? 1} Kantong Darah Lengkap'),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Batas Respons',
                      value: DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(widget.undangan.batasRespons.toLocal()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (sudahDitutup)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.neutralBg, borderRadius: BorderRadius.circular(10)),
                  child: const Text(
                    'Permintaan darah ini sudah terpenuhi atau ditutup oleh Admin UKM KSR.',
                    style: TextStyle(fontSize: 13, color: AppColors.neutral),
                  ),
                )
              else if (_isLoading)
                const Center(
                  child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
                )
              else ...[
                const Text('Pilih Tanggapan Anda:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleBersedia,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Bersedia (Isi Skrining Ulang)'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: _handleTunda, child: const Text('Tunda')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _kirimTanggapan(AppStatus.tanggapanTidakBersedia),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                        child: const Text('Tidak Bersedia'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
