import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_status.dart';
import '../../../core/utils/donor_helper.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/kegiatan_model.dart';
import '../../../models/pengguna_model.dart';
import '../../../models/permintaan_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/kegiatan_service.dart';
import '../../../services/pendonor_service.dart';
import '../../../services/permintaan_service.dart';

class KegiatanLaporanPengaturanTab extends StatefulWidget {
  final PenggunaModel admin;

  const KegiatanLaporanPengaturanTab({super.key, required this.admin});

  @override
  State<KegiatanLaporanPengaturanTab> createState() => _KegiatanLaporanPengaturanTabState();
}

class _KegiatanLaporanPengaturanTabState extends State<KegiatanLaporanPengaturanTab> {
  List<KegiatanModel> _kegiatanList = [];
  List<PenggunaModel> _pendonorList = [];
  List<PermintaanDonorModel> _permintaanList = [];
  Map<String, String> _params = {};
  List<LogAktivitasModel> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatSemua();
  }

  Future<void> _muatSemua() async {
    setState(() => _isLoading = true);
    try {
      final keg = await KegiatanService.getKegiatanByFilter();
      final mhs = await PendonorService.getAllMahasiswaPendonor();
      final minta = await PermintaanService.getAllPermintaan();
      final prm = await KegiatanService.getAllParameter();
      final lg = await KegiatanService.getLogAktivitas();

      if (mounted) {
        setState(() {
          _kegiatanList = keg;
          _pendonorList = mhs;
          _permintaanList = minta;
          _params = prm;
          _logs = lg;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Susun CSV Laporan Pendonor untuk Excel / Google Sheets
  String _generateCsvPendonor() {
    final buffer = StringBuffer();
    buffer.writeln(
      'No;Nama Lengkap;NPM;Program Studi;Golongan Darah;Rhesus;Status Goldar;Status Akun;Ketersediaan;Status Jeda;No WhatsApp;Email',
    );

    for (var i = 0; i < _pendonorList.length; i++) {
      final m = _pendonorList[i];
      final p = m.profilPendonor;
      final bisaDonor = DonorHelper.isBisaDonor(p?.tanggalDonorTerakhir);
      final statusJeda = bisaDonor ? AppStatus.jedaBisaDonor : AppStatus.jedaBelumBisa;

      buffer.writeln(
        '${i + 1};'
        '"${m.namaLengkap}";'
        '"${m.npm ?? '-'}";'
        '"${m.programStudi ?? '-'}";'
        '"${p?.golonganDarah ?? '-'}";'
        '"${p?.rhesus ?? '-'}";'
        '"${p?.statusGolonganDarah ?? '-'}";'
        '"${m.statusAkun}";'
        '"${p?.ketersediaan ?? '-'}";'
        '"$statusJeda";'
        '"${m.noWhatsapp ?? '-'}";'
        '"${m.email}"',
      );
    }
    return buffer.toString();
  }

  /// Susun CSV Laporan Permintaan Darah & Kegiatan Kampus
  String _generateCsvPermintaanDanKegiatan() {
    final buffer = StringBuffer();
    buffer.writeln('=== REKAP PERMINTAAN DARAH ===');
    buffer.writeln('No;Rumah Sakit;Pemohon;Kontak Pemohon;Golongan Darah;Jumlah Kantong;Batas Kebutuhan;Status');

    for (var i = 0; i < _permintaanList.length; i++) {
      final m = _permintaanList[i];
      final tgl = DateFormat('yyyy-MM-dd').format(m.batasWaktuKebutuhan);
      buffer.writeln(
        '${i + 1};'
        '"${m.rumahSakit}";'
        '"${m.namaPemohon}";'
        '"${m.kontakPemohon}";'
        '"${m.goldarLengkap}";'
        '${m.jumlahKantong};'
        '"$tgl";'
        '"${m.status}"',
      );
    }

    buffer.writeln('');
    buffer.writeln('=== REKAP KEGIATAN DONOR KAMPUS ===');
    buffer.writeln('No;Nama Kegiatan;Tanggal;Lokasi;Pendaftar;Kuota;Status');

    for (var i = 0; i < _kegiatanList.length; i++) {
      final k = _kegiatanList[i];
      final tgl = DateFormat('yyyy-MM-dd').format(k.tanggal);
      buffer.writeln(
        '${i + 1};'
        '"${k.nama}";'
        '"$tgl";'
        '"${k.lokasi}";'
        '${k.jumlahPendaftar};'
        '${k.kuota};'
        '"${k.status}"',
      );
    }

    return buffer.toString();
  }

  Future<void> _bukaModalEksporLaporan({required String judul, required String csvContent}) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(judul),
        content: SizedBox(
          width: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Format CSV (pemisah titik koma ";") siap ditempel langsung ke Microsoft Excel atau Google Sheets untuk keperluan LPJ UKM KSR:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                height: 260,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neutralBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(csvContent, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csvContent));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Data laporan CSV berhasil disalin! Silakan tempel (Ctrl+V) di Excel atau Google Sheets.',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy_all_rounded, size: 18),
            label: const Text('Salin CSV untuk Excel'),
          ),
        ],
      ),
    );
  }

  Future<void> _bukaVerifikasiKegiatan(KegiatanModel keg) async {
    String status = AppStatus.kegiatanDisetujui;
    final catatanCtrl = TextEditingController(text: keg.catatanVerifikasi ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Verifikasi Kegiatan: ${keg.nama}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal: ${DonorHelper.formatTanggal(keg.tanggal)}'),
                Text('Lokasi: ${keg.lokasi}  •  Kuota: ${keg.kuota}'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Keputusan Admin'),
                  items: [
                    AppStatus.kegiatanDisetujui,
                    AppStatus.kegiatanRevisi,
                    AppStatus.kegiatanDitolak,
                    AppStatus.kegiatanSelesai,
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => status = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: catatanCtrl,
                  decoration: const InputDecoration(labelText: 'Catatan untuk Penyelenggara'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                await KegiatanService.verifikasiKegiatan(
                  kegiatan: keg,
                  adminId: widget.admin.idPengguna,
                  statusBaru: status,
                  catatan: catatanCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _muatSemua();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bukaRekapPesertaKegiatan(KegiatanModel keg) async {
    final pesertaList = await KegiatanService.getPesertaKegiatan(keg.idKegiatan);
    final jedaHari = int.tryParse(_params['jeda_donor_hari'] ?? '61') ?? 61;
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rekap Peserta: ${keg.nama}'),
        content: SizedBox(
          width: 560,
          height: 420,
          child: pesertaList.isEmpty
              ? const Center(child: Text('Belum ada mahasiswa terdaftar pada kegiatan ini.'))
              : ListView.builder(
                  itemCount: pesertaList.length,
                  itemBuilder: (_, i) {
                    final p = pesertaList[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${p.namaMahasiswa ?? '-'} (${p.npmMahasiswa ?? '-'})'),
                        subtitle: Text('Goldar: ${p.goldarMahasiswa ?? '-'}  •  Hasil: ${p.hasil}'),
                        trailing: p.hasil == 'Belum dicatat'
                            ? PopupMenuButton<String>(
                                onSelected: (hasil) async {
                                  await KegiatanService.rekapHasilPesertaKegiatan(
                                    peserta: p,
                                    kegiatan: keg,
                                    adminId: widget.admin.idPengguna,
                                    hasilBaru: hasil,
                                    jedaHari: jedaHari,
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _bukaRekapPesertaKegiatan(keg);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: AppStatus.hasilBerhasil,
                                    child: Text('Berhasil donor (Mulai jeda 61 hari)'),
                                  ),
                                  const PopupMenuItem(
                                    value: AppStatus.hasilTidakLolos,
                                    child: Text('Tidak lolos pemeriksaan petugas'),
                                  ),
                                  const PopupMenuItem(value: AppStatus.hasilTidakHadir, child: Text('Tidak hadir')),
                                ],
                                child: const Chip(label: Text('Catat Hasil')),
                              )
                            : StatusBadge(status: p.hasil, fontSize: 11),
                      ),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
      ),
    );
  }

  Future<void> _bukaDialogBuatAkunPengurus() async {
    final namaCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final waCtrl = TextEditingController();
    final orgCtrl = TextEditingController();
    String peran = AppStatus.rolePenyelenggara;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Buat Akun Pengurus / Penyelenggara'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: peran,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Peran Akun'),
                    items: [
                      AppStatus.rolePenyelenggara,
                      AppStatus.roleAdmin,
                    ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setDialogState(() => peran = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: namaCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap *'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: orgCtrl,
                    decoration: const InputDecoration(labelText: 'Nama UKM / Himpunan / Organisasi *'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: waCtrl,
                    decoration: const InputDecoration(labelText: 'No. WhatsApp *'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email Login *'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Kata Sandi Awal (Min. 8 karakter) *'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                await AuthService.buatAkunPengurusAtauPenyelenggara(
                  namaLengkap: namaCtrl.text,
                  email: emailCtrl.text,
                  password: passCtrl.text,
                  noWhatsapp: waCtrl.text,
                  organisasi: orgCtrl.text,
                  peran: peran,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Akun $peran berhasil dibuat!'), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text('Buat Akun'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
      );
    }

    final terverifikasiList = _pendonorList.where((m) => m.statusAkun == AppStatus.akunTerverifikasi).toList();
    final siapDonorList = terverifikasiList.where((m) {
      final p = m.profilPendonor;
      if (p == null) return false;
      return p.ketersediaan == AppStatus.tersediaAktif && DonorHelper.isBisaDonor(p.tanggalDonorTerakhir);
    }).toList();

    final terlaksanaCount = _permintaanList.where((p) => p.status == AppStatus.mintaTerlaksana).length;

    // Hitung sebaran per golongan darah (total terverifikasi vs siap donor hari ini)
    const daftarGoldar = ['A', 'B', 'AB', 'O'];

    // Hitung sebaran per Program Studi (top 5)
    final Map<String, int> prodiCounts = {};
    for (final m in terverifikasiList) {
      final prodi = (m.programStudi == null || m.programStudi!.trim().isEmpty) ? 'Belum diisi' : m.programStudi!.trim();
      prodiCounts[prodi] = (prodiCounts[prodi] ?? 0) + 1;
    }
    final sortedProdi = prodiCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Rekap Laporan Agregat & Ekspor CSV (F8)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ringkasan Laporan & Ekspor LPJ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text(
                    'Pantau kesiapan stok pendonor kampus dan salin laporan format CSV untuk Excel/LPJ UKM KSR.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      _bukaModalEksporLaporan(judul: 'Ekspor Data Pendonor (CSV)', csvContent: _generateCsvPendonor()),
                  icon: const Icon(Icons.people_alt_outlined, size: 18),
                  label: const Text('Ekspor Pendonor'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _bukaModalEksporLaporan(
                    judul: 'Ekspor Permintaan & Kegiatan (CSV)',
                    csvContent: _generateCsvPermintaanDanKegiatan(),
                  ),
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Ekspor Permintaan & Kegiatan'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _MetricCard(
              label: 'Pendonor Terverifikasi',
              value: '${terverifikasiList.length} Orang',
              subtitle: '${siapDonorList.length} siap donor hari ini',
              color: AppColors.success,
            ),
            _MetricCard(
              label: 'Permintaan Terlaksana',
              value: '$terlaksanaCount / ${_permintaanList.length} Kasus',
              subtitle: 'Kebutuhan darah terpenuhi',
              color: AppColors.primary,
            ),
            _MetricCard(
              label: 'Total Kegiatan Kampus',
              value: '${_kegiatanList.length} Agenda',
              subtitle: 'Kolaborasi organisasi kampus',
              color: Colors.blue,
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Kartu Distribusi Stok per Golongan Darah & Program Studi
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kesiapan Pendonor Terverifikasi per Golongan Darah',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: daftarGoldar.map((g) {
                    final totalG = terverifikasiList.where((m) => m.profilPendonor?.golonganDarah == g).length;
                    final siapG = siapDonorList.where((m) => m.profilPendonor?.golonganDarah == g).length;
                    final rhesusNeg = siapDonorList
                        .where((m) => m.profilPendonor?.golonganDarah == g && m.profilPendonor?.rhesus == 'Negatif')
                        .length;

                    return Container(
                      width: 195,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.neutralBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Golongan $g',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '$siapG Siap',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total terdaftar: $totalG orang${rhesusNeg > 0 ? ' ($rhesusNeg Rh-)' : ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (sortedProdi.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Sebaran Pendonor per Program Studi:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortedProdi.take(6).map((entry) {
                      return Chip(
                        backgroundColor: AppColors.primaryLight,
                        label: Text(
                          '${entry.key}: ${entry.value} pendonor',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // 2. Kelola Kegiatan Kampus & Rekap Hasil Peserta (F7)
        const Text('Kelola Kegiatan Donor Kampus', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (_kegiatanList.isEmpty)
          const Card(
            child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada kegiatan terdaftar.')),
          )
        else
          ..._kegiatanList.map(
            (keg) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                title: Text(keg.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${DonorHelper.formatTanggal(keg.tanggal)} • ${keg.lokasi} • Peserta: ${keg.jumlahPendaftar}/${keg.kuota}',
                ),
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(status: keg.status, fontSize: 11),
                    OutlinedButton(onPressed: () => _bukaVerifikasiKegiatan(keg), child: const Text('Verifikasi')),
                    ElevatedButton(onPressed: () => _bukaRekapPesertaKegiatan(keg), child: const Text('Peserta')),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 28),

        // 3. Pengaturan Parameter Dinamis & Akun Pengurus (F9)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pengaturan Sistem & Akun', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ElevatedButton.icon(
              onPressed: _bukaDialogBuatAkunPengurus,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Tambah Akun Penyelenggara/Admin'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: _params.entries.map((entry) {
                return ListTile(
                  dense: true,
                  title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: SizedBox(
                    width: 110,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () async {
                            final ctrl = TextEditingController(text: entry.value);
                            await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Ubah ${entry.key}'),
                                content: TextField(controller: ctrl, keyboardType: TextInputType.number),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await KegiatanService.updateParameter(
                                        kunci: entry.key,
                                        nilaiBaru: ctrl.text.trim(),
                                        adminId: widget.admin.idPengguna,
                                      );
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      _muatSemua();
                                    },
                                    child: const Text('Simpan'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // 4. Log Aktivitas (Read-only Audit Trail - FR-F9-14)
        const Text('Log Aktivitas Penting (Audit Trail)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _logs.isEmpty
                ? const Center(child: Text('Belum ada catatan aktivitas.'))
                : Column(
                    children: _logs.take(15).map((l) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.history_toggle_off_rounded, size: 18),
                        title: Text('${l.aksi} — ${l.objek}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${l.namaPelaku ?? 'Admin'} • ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(l.waktu.toLocal())}${l.rincian != null ? ' • ${l.rincian}' : ''}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricCard({required this.label, required this.value, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
