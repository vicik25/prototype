import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_status.dart';
import '../../../core/utils/donor_helper.dart';
import '../../../models/pengguna_model.dart';
import '../../../services/pendonor_service.dart';

class SkriningDialog extends StatefulWidget {
  final PenggunaModel user;
  final String? idPermintaan;

  const SkriningDialog({super.key, required this.user, this.idPermintaan});

  /// Menampilkan modal skrining dan mengembalikan hasil ('Memenuhi syarat awal' / 'Belum memenuhi syarat awal')
  static Future<String?> show(BuildContext context, {required PenggunaModel user, String? idPermintaan}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SkriningDialog(user: user, idPermintaan: idPermintaan),
    );
  }

  @override
  State<SkriningDialog> createState() => _SkriningDialogState();
}

class _SkriningDialogState extends State<SkriningDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usiaCtrl = TextEditingController();
  final _beratCtrl = TextEditingController();
  final _tidurCtrl = TextEditingController();

  late bool _pernahDonor;
  bool _sehatHariIni = true;
  bool _minumAntibiotik48Jam = false;
  bool _minumAspirin7Hari = false;
  bool _hamilAtauMenyusui = false;
  bool _operasiBaru = false;
  bool _tato6BulanTerakhir = false;

  bool _isSubmitting = false;
  String? _hasilEvaluasi;

  @override
  void initState() {
    super.initState();
    _pernahDonor = widget.user.profilPendonor?.tanggalDonorTerakhir != null;
  }

  @override
  void dispose() {
    _usiaCtrl.dispose();
    _beratCtrl.dispose();
    _tidurCtrl.dispose();
    super.dispose();
  }

  Future<void> _prosesSkrining() async {
    if (!_formKey.currentState!.validate()) return;

    final usia = int.tryParse(_usiaCtrl.text.trim()) ?? 0;
    final berat = double.tryParse(_beratCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final tidur = double.tryParse(_tidurCtrl.text.trim().replaceAll(',', '.')) ?? 0;

    final hasil = DonorHelper.evaluasiSkrining(
      usia: usia,
      pernahDonorSebelumnya: _pernahDonor,
      beratBadan: berat,
      sehatHariIni: _sehatHariIni,
      minumAntibiotik48Jam: _minumAntibiotik48Jam,
      minumAspirin7Hari: _minumAspirin7Hari,
      hamilAtauMenyusui: _hamilAtauMenyusui,
      operasiBaru: _operasiBaru,
      tato6BulanTerakhir: _tato6BulanTerakhir,
      durasiTidurJam: tidur,
    );

    setState(() => _isSubmitting = true);
    try {
      await PendonorService.simpanSkrining(
        idPengguna: widget.user.idPengguna,
        idPermintaan: widget.idPermintaan,
        hasil: hasil,
      );
      if (mounted) {
        setState(() {
          _hasilEvaluasi = hasil;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan skrining: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _hasilEvaluasi != null ? _buildHasilView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.health_and_safety_rounded, color: AppColors.primary, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.idPermintaan != null ? 'Skrining Ulang Wajib Sebelum Konfirmasi' : 'Skrining Kelayakan Mandiri',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(onPressed: () => Navigator.pop(context, null), icon: const Icon(Icons.close_rounded)),
          ],
        ),
        const SizedBox(height: 10),

        // Disclaimer Wajib (FR-F3-07)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: const Text(
            'Perhatian: Hasil kuesioner ini hanyalah perkiraan awal dan bukan diagnosis medis. Pemeriksaan kadar Hb, tekanan darah, dan keputusan kelayakan akhir tetap wajib dilakukan oleh petugas UDD PMI.',
            style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),

        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _usiaCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Usia (Tahun) *'),
                          validator: (v) => (v == null || int.tryParse(v) == null) ? 'Isi angka valid' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _beratCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Berat Badan (kg) *'),
                          validator: (v) =>
                              (v == null || double.tryParse(v.replaceAll(',', '.')) == null) ? 'Isi berat valid' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tidurCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Durasi Tidur Malam Tadi (Jam) *',
                      hintText: 'Contoh: 6.5',
                    ),
                    validator: (v) =>
                        (v == null || double.tryParse(v.replaceAll(',', '.')) == null) ? 'Isi durasi tidur' : null,
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sudah pernah donor darah sebelumnya?', style: TextStyle(fontSize: 13.5)),
                    value: _pernahDonor,
                    onChanged: (v) => setState(() => _pernahDonor = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Apakah Anda merasa sehat & bugar hari ini?', style: TextStyle(fontSize: 13.5)),
                    value: _sehatHariIni,
                    onChanged: (v) => setState(() => _sehatHariIni = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Mengonsumsi antibiotik / obat lain dalam 48 jam terakhir?',
                      style: TextStyle(fontSize: 13.5),
                    ),
                    value: _minumAntibiotik48Jam,
                    onChanged: (v) => setState(() => _minumAntibiotik48Jam = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mengonsumsi aspirin dalam 7 hari terakhir?', style: TextStyle(fontSize: 13.5)),
                    value: _minumAspirin7Hari,
                    onChanged: (v) => setState(() => _minumAspirin7Hari = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Sedang hamil atau menyusui? (Pilih Tidak jika tidak berlaku)',
                      style: TextStyle(fontSize: 13.5),
                    ),
                    value: _hamilAtauMenyusui,
                    onChanged: (v) => setState(() => _hamilAtauMenyusui = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Menjalani operasi baru dalam 6 bulan terakhir?',
                      style: TextStyle(fontSize: 13.5),
                    ),
                    value: _operasiBaru,
                    onChanged: (v) => setState(() => _operasiBaru = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Membuat tato / tindik dalam 6 bulan terakhir?',
                      style: TextStyle(fontSize: 13.5),
                    ),
                    value: _tato6BulanTerakhir,
                    onChanged: (v) => setState(() => _tato6BulanTerakhir = v),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _prosesSkrining,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Evaluasi Kelayakan Awal'),
          ),
        ),
      ],
    );
  }

  Widget _buildHasilView() {
    final lolos = _hasilEvaluasi == AppStatus.skriningMemenuhi;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: lolos ? AppColors.successBg : AppColors.dangerBg, shape: BoxShape.circle),
          child: Icon(
            lolos ? Icons.check_circle_rounded : Icons.info_rounded,
            color: lolos ? AppColors.success : AppColors.danger,
            size: 54,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _hasilEvaluasi!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: lolos ? AppColors.success : AppColors.danger,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          lolos
              ? 'Anda memenuhi syarat awal untuk mengikuti donor darah. Hasil ini merupakan perkiraan awal dan pemeriksaan fisik/laboratorium tetap wajib dilakukan oleh petugas UDD PMI.'
              : 'Anda belum memenuhi syarat awal donor darah saat ini. Dianjurkan untuk berkonsultasi langsung dengan petugas UDD PMI saat kegiatan donor. Sistem tidak menyimpan rincian jawaban medis Anda.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, _hasilEvaluasi),
            style: ElevatedButton.styleFrom(backgroundColor: lolos ? AppColors.success : AppColors.neutral),
            child: Text(lolos && widget.idPermintaan != null ? 'Lanjutkan Konfirmasi Kesediaan' : 'Selesai'),
          ),
        ),
      ],
    );
  }
}
