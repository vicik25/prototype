import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/donor_helper.dart';
import '../../core/utils/file_bytes_helper.dart';
import '../../services/auth_service.dart';
import '../beranda/beranda_page.dart';

class RegisterMahasiswaPage extends StatefulWidget {
  const RegisterMahasiswaPage({super.key});

  @override
  State<RegisterMahasiswaPage> createState() => _RegisterMahasiswaPageState();
}

class _RegisterMahasiswaPageState extends State<RegisterMahasiswaPage> {
  final _formKey = GlobalKey<FormState>();

  final _namaCtrl = TextEditingController();
  final _npmCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _prodiCtrl = TextEditingController();
  final _fakultasCtrl = TextEditingController();
  final _domisiliCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _golonganDarah = 'O';
  String _rhesus = 'Positif';
  DateTime? _tanggalDonorTerakhir;

  Uint8List? _ktpBytes;
  String? _ktpName;

  Uint8List? _kartuDonorBytes;
  String? _kartuDonorName;

  // Kotak centang tidak boleh terisi otomatis (FR-F1-09)
  bool _setujuPemrosesanData = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _npmCtrl.dispose();
    _emailCtrl.dispose();
    _waCtrl.dispose();
    _prodiCtrl.dispose();
    _fakultasCtrl.dispose();
    _domisiliCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihFile({required bool isKtp}) async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result.isNotEmpty) {
      final file = result.first;
      final bytes = await readPlatformFileBytes(file);

      if (bytes != null) {
        setState(() {
          if (isKtp) {
            _ktpBytes = bytes;
            _ktpName = file.name;
          } else {
            _kartuDonorBytes = bytes;
            _kartuDonorName = file.name;
          }
        });
      }
    }
  }

  Future<void> _pilihTanggalDonorTerakhir() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 65)),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _tanggalDonorTerakhir = picked);
    }
  }

  Future<void> _submitPendaftaran() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ktpBytes == null || _ktpName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap unggah foto/dokumen KTP atau KTM untuk verifikasi identitas.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (!_setujuPemrosesanData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus mencentang persetujuan pemrosesan data pribadi terlebih dahulu.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.registerMahasiswa(
        namaLengkap: _namaCtrl.text,
        npm: _npmCtrl.text,
        email: _emailCtrl.text,
        noWhatsapp: _waCtrl.text,
        programStudi: _prodiCtrl.text,
        fakultas: _fakultasCtrl.text,
        password: _passwordCtrl.text,
        golonganDarah: _golonganDarah,
        rhesus: _rhesus,
        domisili: _domisiliCtrl.text,
        tanggalDonorTerakhir: _tanggalDonorTerakhir,
        ktpBytes: _ktpBytes!,
        ktpFileName: _ktpName!,
        kartuDonorBytes: _kartuDonorBytes,
        kartuDonorFileName: _kartuDonorName,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Pendaftaran Berhasil!'),
          content: const Text(
            'Akun Anda telah dibuat dengan status "Menunggu verifikasi" oleh Admin UKM KSR. Silakan login menggunakan akun baru Anda.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const BerandaPage()),
                  (_) => false,
                );
              },
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pendaftaran Calon Pendonor Mahasiswa')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Formulir Pendonor Sukarela',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Khusus mahasiswa aktif yang memiliki NPM. Data Anda dilindungi sesuai ketentuan privasi SiDonor.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                      ),
                      const SizedBox(height: 24),

                      // Bagian 1: Identitas Mahasiswa
                      const Text('1. Identitas & Kontak Mahasiswa', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _namaCtrl,
                        decoration: const InputDecoration(labelText: 'Nama Lengkap (sesuai KTP/KTM) *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nama lengkap wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _npmCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'NPM *', hintText: '257007...'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'NPM wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _waCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Nomor WhatsApp *',
                                hintText: '0812xxxxxxxx',
                              ),
                              validator: (v) => v == null || v.trim().length < 10 ? 'Nomor WhatsApp tidak valid' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fakultasCtrl,
                              decoration: const InputDecoration(labelText: 'Fakultas *', hintText: 'Teknik'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Fakultas wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _prodiCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Program Studi *',
                                hintText: 'Sistem Informasi',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Program studi wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _domisiliCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Domisili Kecamatan / Kota (Opsional)',
                          hintText: 'Contoh: Tawang, Kota Tasikmalaya',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'Email *'),
                              validator: (v) => v == null || !v.contains('@') ? 'Format email tidak valid' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _passwordCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Kata Sandi *',
                                hintText: 'Minimal 8 karakter',
                              ),
                              validator: (v) => v == null || v.length < 8 ? 'Kata sandi minimal 8 karakter' : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Bagian 2: Informasi Golongan Darah
                      const Text('2. Informasi Golongan Darah', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _golonganDarah,
                              decoration: const InputDecoration(labelText: 'Golongan Darah *'),
                              items: [
                                'A',
                                'B',
                                'AB',
                                'O',
                              ].map((g) => DropdownMenuItem(value: g, child: Text('Golongan $g'))).toList(),
                              onChanged: (v) => setState(() => _golonganDarah = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _rhesus,
                              decoration: const InputDecoration(labelText: 'Rhesus *'),
                              items: [
                                'Positif',
                                'Negatif',
                              ].map((r) => DropdownMenuItem(value: r, child: Text('Rhesus $r'))).toList(),
                              onChanged: (v) => setState(() => _rhesus = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pilihTanggalDonorTerakhir,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Donor Terakhir (Opsional - jika pernah donor)',
                            suffixIcon: Icon(Icons.calendar_month_outlined),
                          ),
                          child: Text(
                            _tanggalDonorTerakhir == null
                                ? 'Belum pernah donor / kosongkan'
                                : DonorHelper.formatTanggal(_tanggalDonorTerakhir),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bagian 3: Unggah Bukti Verifikasi
                      const Text(
                        '3. Dokumen Verifikasi (JPG, PNG, atau PDF)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _pilihFile(isKtp: true),
                        icon: Icon(
                          _ktpBytes != null ? Icons.check_circle : Icons.upload_file_rounded,
                          color: _ktpBytes != null ? AppColors.success : AppColors.primary,
                        ),
                        label: Text(
                          _ktpName != null ? 'KTP/KTM Terpilih: $_ktpName' : 'Unggah Bukti Identitas (KTP / KTM) *',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _pilihFile(isKtp: false),
                        icon: Icon(
                          _kartuDonorBytes != null ? Icons.check_circle : Icons.badge_outlined,
                          color: _kartuDonorBytes != null ? AppColors.success : AppColors.neutral,
                        ),
                        label: Text(
                          _kartuDonorName != null
                              ? 'Kartu Donor Terpilih: $_kartuDonorName'
                              : 'Unggah Kartu Donor / Bukti Golongan Darah (Opsional)',
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bagian 4: Pemberitahuan & Persetujuan UU PDP (FR-F1-08 & FR-F1-09)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Pemberitahuan Pemrosesan Data Pribadi',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Data yang dikumpulkan: Identitas akademik, nomor WhatsApp, email, golongan darah, rhesus, status skrining mandiri, dan riwayat tanggal donor.\n'
                              '• Tujuan: Pendataan dan koordinasi kebutuhan donor darah sukarela di lingkungan kampus bersama UKM KSR dan UDD PMI.\n'
                              '• Hak Anda: Anda dapat memperbarui data, mengatur status ketersediaan menjadi Nonaktif, atau menarik persetujuan kapan saja.\n'
                              '• Pemeriksaan medis (Hb, tekanan darah, uji silang) tetap dilakukan petugas UDD PMI di luar sistem.',
                              style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            CheckboxListTile(
                              value: _setujuPemrosesanData,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text(
                                'Saya telah membaca pemberitahuan di atas dan memberikan persetujuan eksplisit atas pemrosesan data pribadi saya sesuai UU No. 27 Tahun 2022.',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                              onChanged: (val) => setState(() => _setujuPemrosesanData = val ?? false),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitPendaftaran,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Kirim Pendaftaran Pendonor'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
