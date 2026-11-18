import 'package:file_picker/file_picker.dart' as fp;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/donor_helper.dart';
import '../../core/utils/file_bytes_helper.dart';
import '../../core/widgets/status_badge.dart';
import '../../main.dart';

class PermintaanPublikPage extends StatefulWidget {
  final int initialTabIndex;

  const PermintaanPublikPage({super.key, this.initialTabIndex = 0});

  @override
  State<PermintaanPublikPage> createState() => _PermintaanPublikPageState();
}

class _PermintaanPublikPageState extends State<PermintaanPublikPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _kontakCtrl = TextEditingController();
  final _rsCtrl = TextEditingController();
  final _kantongCtrl = TextEditingController(text: '1');
  String _goldar = 'O';
  String _rhesus = 'Positif';
  DateTime _batasKebutuhan = DateTime.now().add(const Duration(days: 1));
  Uint8List? _suratBytes;
  String? _suratName;
  bool _submitting = false;
  String? _kodeTerbaru;

  final _lacakWaCtrl = TextEditingController();
  final _lacakKodeCtrl = TextEditingController();
  bool _loadingLacak = false;
  bool _sudahCari = false;
  List _hasilLacak = [];

  @override
  void dispose() {
    _namaCtrl.dispose();
    _kontakCtrl.dispose();
    _rsCtrl.dispose();
    _kantongCtrl.dispose();
    _lacakWaCtrl.dispose();
    _lacakKodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _kirimPengajuan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_suratBytes == null || _suratName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Surat permintaan darah dari Rumah Sakit wajib diunggah.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final cleanName = _suratName!.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final storagePath = 'surat-rs/${DateTime.now().millisecondsSinceEpoch}_$cleanName';

      await supabase.storage.from('dokumen-bukti').uploadBinary(storagePath, _suratBytes!);

      final res = await supabase.rpc(
        'ajukan_permintaan_publik',
        params: {
          'p_nama_pemohon': _namaCtrl.text.trim(),
          'p_kontak_pemohon': _kontakCtrl.text.trim(),
          'p_rumah_sakit': _rsCtrl.text.trim(),
          'p_golongan_darah': _goldar,
          'p_rhesus': _rhesus,
          'p_jumlah_kantong': int.tryParse(_kantongCtrl.text.trim()) ?? 1,
          'p_batas_waktu': _batasKebutuhan.toIso8601String().split('T').first,
          'p_lokasi_surat': storagePath,
        },
      );

      final kode = (res as Map)['kode_pelacakan']?.toString() ?? '-';

      if (!mounted) return;
      setState(() {
        _kodeTerbaru = kode;
        _lacakWaCtrl.text = _kontakCtrl.text.trim();
        _lacakKodeCtrl.text = kode;
        _suratBytes = null;
        _suratName = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengirim pengajuan: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cariStatusPermintaan() async {
    if (_lacakWaCtrl.text.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor WhatsApp pemohon yang valid.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() {
      _loadingLacak = true;
      _sudahCari = true;
    });

    try {
      final res = await supabase.rpc(
        'lacak_permintaan_publik',
        params: {'p_kontak_pemohon': _lacakWaCtrl.text.trim(), 'p_kode_pelacakan': _lacakKodeCtrl.text.trim()},
      );

      if (mounted) {
        setState(() {
          _hasilLacak = List.from(res as List);
          _loadingLacak = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingLacak = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memuat status: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Layanan Kebutuhan Darah'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(icon: Icon(Icons.bloodtype_outlined), text: 'Ajukan Permintaan'),
              Tab(icon: Icon(Icons.track_changes_rounded), text: 'Lacak Status'),
            ],
          ),
        ),
        body: TabBarView(children: [_buildTabPengajuan(), _buildTabPelacakan()]),
      ),
    );
  }

  Widget _buildTabPengajuan() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_kodeTerbaru != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.success),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pengajuan Berhasil Dikirim ke UKM KSR!',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Simpan Kode Pelacakan berikut untuk memantau progres pencarian pendonor:',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              _kodeTerbaru!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _kodeTerbaru!));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(content: Text('Kode pelacakan disalin!')));
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Salin Kode'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Formulir Permintaan Darah Pasien',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Lengkapi data kebutuhan darah dan unggah surat resmi dari Rumah Sakit / UDD PMI.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _namaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Pemohon / Keluarga Pasien *',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Nama pemohon wajib diisi' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _kontakCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Nomor WhatsApp Aktif *',
                            hintText: 'Contoh: 081234567890',
                            prefixIcon: Icon(Icons.phone_android_outlined),
                          ),
                          validator: (v) => v == null || v.trim().length < 9 ? 'Nomor WhatsApp wajib diisi' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _rsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Rumah Sakit / UDD PMI Tujuan *',
                            hintText: 'Contoh: RSUD dr. Soekardjo Tasikmalaya',
                            prefixIcon: Icon(Icons.local_hospital_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Lokasi RS wajib diisi' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _goldar,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Gol. Darah *'),
                                items: [
                                  'A',
                                  'B',
                                  'AB',
                                  'O',
                                ].map((g) => DropdownMenuItem(value: g, child: Text('Gol. $g'))).toList(),
                                onChanged: (v) => setState(() => _goldar = v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _rhesus,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Rhesus *'),
                                items: [
                                  'Positif',
                                  'Negatif',
                                ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                onChanged: (v) => setState(() => _rhesus = v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 95,
                              child: TextFormField(
                                controller: _kantongCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Kantong *'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _batasKebutuhan,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 60)),
                            );
                            if (picked != null) setState(() => _batasKebutuhan = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Batas Waktu Kebutuhan *',
                              suffixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(DonorHelper.formatTanggal(_batasKebutuhan)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final res = await fp.FilePicker.pickFiles(
                                type: fp.FileType.custom,
                                allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                              );
                              if (res.isNotEmpty) {
                                final bytes = await readPlatformFileBytes(res.first);
                                if (bytes != null) {
                                  setState(() {
                                    _suratBytes = bytes;
                                    _suratName = res.first.name;
                                  });
                                }
                              }
                            },
                            icon: Icon(
                              _suratBytes != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                              color: _suratBytes != null ? AppColors.success : AppColors.primary,
                            ),
                            label: Text(
                              _suratName != null
                                  ? 'Terpilih: $_suratName'
                                  : 'Unggah Surat Permintaan RS (JPG/PNG/PDF) *',
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _kirimPengajuan,
                            child: _submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Kirim Permintaan Darah'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabPelacakan() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lacak Progres Permintaan Darah',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Masukkan nomor WhatsApp yang digunakan saat mengajukan permintaan.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lacakWaCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nomor WhatsApp Pemohon *',
                          prefixIcon: Icon(Icons.phone_android_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _lacakKodeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Kode Pelacakan (Opsional)',
                          hintText: 'Contoh: A1B2C3D4',
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loadingLacak ? null : _cariStatusPermintaan,
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('Cek Status Permintaan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_loadingLacak)
                const Center(child: CircularProgressIndicator())
              else if (_sudahCari && _hasilLacak.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Data pengajuan tidak ditemukan untuk nomor WhatsApp tersebut.')),
                  ),
                )
              else
                ..._hasilLacak.map((item) => _buildCardHasilLacak(item as Map)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHasilLacak(Map item) {
    final bersedia = item['jumlah_pendonor_bersedia'] ?? 0;
    final status = item['status']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kode: ${item['kode_pelacakan']}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                StatusBadge(status: status),
              ],
            ),
            const Divider(height: 20),
            Text(
              '${item['rumah_sakit']} — Gol. ${item['golongan_darah']} ${item['rhesus']} (${item['jumlah_kantong']} kantong)',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Pemohon: ${item['nama_pemohon']}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.neutralBg, borderRadius: BorderRadius.circular(10)),
              child: Text(
                status == 'Menunggu verifikasi'
                    ? 'Surat rumah sakit sedang diperiksa oleh pengurus UKM KSR PMI.'
                    : 'Respons pendonor: $bersedia pendonor telah menyatakan bersedia dan sedang dikoordinasikan oleh Admin UKM KSR.',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
