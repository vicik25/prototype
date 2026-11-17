import 'package:material_ui/material_ui.dart';
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

    final terverifikasiCount = _pendonorList.where((m) => m.statusAkun == AppStatus.akunTerverifikasi).length;
    final terlaksanaCount = _permintaanList.where((p) => p.status == AppStatus.mintaTerlaksana).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Rekap Laporan Agregat (F8)
        const Text('Ringkasan Laporan Agregat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _MetricCard(label: 'Pendonor Terverifikasi', value: '$terverifikasiCount Orang', color: AppColors.success),
            _MetricCard(label: 'Permintaan Terlaksana', value: '$terlaksanaCount Kasus', color: AppColors.primary),
            _MetricCard(label: 'Total Kegiatan Kampus', value: '${_kegiatanList.length} Agenda', color: Colors.blue),
          ],
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
  final Color color;

  const _MetricCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
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
        ],
      ),
    );
  }
}
