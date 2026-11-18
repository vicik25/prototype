import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:states_rebuilder/states_rebuilder.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_status.dart';
import '../../core/utils/donor_helper.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/kegiatan_model.dart';
import '../../models/pengguna_model.dart';
import '../../services/auth_service.dart';
import '../../services/kegiatan_service.dart';

class PenyelenggaraDashboard extends StatefulWidget {
  const PenyelenggaraDashboard({super.key});

  @override
  State<PenyelenggaraDashboard> createState() => _PenyelenggaraDashboardState();
}

class _PenyelenggaraDashboardState extends State<PenyelenggaraDashboard> {
  List<KegiatanModel> _kegiatanList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatKegiatan();
  }

  Future<void> _muatKegiatan() async {
    final user = currentUserRM.state;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final list = await KegiatanService.getKegiatanByFilter(idPengaju: user.idPengguna);
      if (mounted) {
        setState(() {
          _kegiatanList = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _bukaDialogFormKegiatan(PenggunaModel user, {KegiatanModel? existing}) async {
    final formKey = GlobalKey<FormState>();
    final namaCtrl = TextEditingController(text: existing?.nama ?? '');
    final lokasiCtrl = TextEditingController(text: existing?.lokasi ?? '');
    final kuotaCtrl = TextEditingController(text: '${existing?.kuota ?? 50}');
    final kontakCtrl = TextEditingController(text: user.noWhatsapp ?? '');
    DateTime tanggalPilihan = existing?.tanggal ?? DateTime.now().add(const Duration(days: 7));
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Ajukan Kegiatan Donor Darah' : 'Perbarui Ajuan Kegiatan'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (existing?.catatanVerifikasi != null && existing!.catatanVerifikasi!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          'Catatan Revisi Admin KSR: ${existing.catatanVerifikasi}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    TextFormField(
                      controller: namaCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Kegiatan *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: tanggalPilihan,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => tanggalPilihan = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Pelaksanaan *',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(DonorHelper.formatTanggal(tanggalPilihan)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: lokasiCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi Kegiatan *',
                        hintText: 'Contoh: Gedung Mandala Universitas Siliwangi',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: kuotaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Target Kuota Pendonor *'),
                      validator: (v) =>
                          (v == null || int.tryParse(v) == null || int.parse(v) <= 0) ? 'Isi angka valid' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: kontakCtrl,
                      decoration: const InputDecoration(labelText: 'Kontak Panitia (WhatsApp) *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      if (existing == null) {
                        await KegiatanService.ajukanKegiatan(
                          nama: namaCtrl.text,
                          tanggal: tanggalPilihan,
                          lokasi: lokasiCtrl.text,
                          kuota: int.parse(kuotaCtrl.text.trim()),
                          kontak: kontakCtrl.text,
                          idPengaju: user.idPengguna,
                        );
                      } else {
                        await KegiatanService.revisiKegiatan(
                          idKegiatan: existing.idKegiatan,
                          nama: namaCtrl.text,
                          tanggal: tanggalPilihan,
                          lokasi: lokasiCtrl.text,
                          kuota: int.parse(kuotaCtrl.text.trim()),
                          kontak: kontakCtrl.text,
                        );
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _muatKegiatan();
                    },
              child: Text(existing == null ? 'Kirim Ajuan' : 'Kirim Ulang Ajuan'),
            ),
          ],
        ),
      ),
    );
  }

  void _bukaPresensiHariH(KegiatanModel keg) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PresensiKegiatanPage(kegiatan: keg)),
    ).then((_) => _muatKegiatan());
  }

  @override
  Widget build(BuildContext context) {
    return OnBuilder<PenggunaModel?>.data(
      listenTo: currentUserRM,
      builder: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final disetujuiCount = _kegiatanList
            .where((k) => k.status == AppStatus.kegiatanDisetujui || k.status == AppStatus.kegiatanSelesai)
            .length;
        final totalPendaftar = _kegiatanList.fold<int>(0, (sum, item) => sum + item.jumlahPendaftar);

        return Scaffold(
          appBar: CustomAppBar(
            user: user,
            subtitle: '${user.organisasi ?? 'Penyelenggara Kegiatan'} • ${user.namaLengkap}',
            onNotifActionTap: (_) => _muatKegiatan(),
          ),
          body: RefreshIndicator(
            onRefresh: _muatKegiatan,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pengajuan & Presensi Kegiatan Donor',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Ajukan jadwal kegiatan donor kampus dan kelola presensi peserta hari-H tanpa membuka data sensitif pendonor.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _bukaDialogFormKegiatan(user),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Ajukan Kegiatan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Ringkasan Statistik Organisasi
                      Wrap(
                        spacing: 14,
                        runSpacing: 12,
                        children: [
                          _SummaryBox(
                            label: 'Total Agenda Diajukan',
                            value: '${_kegiatanList.length} Kegiatan',
                            color: AppColors.textPrimary,
                          ),
                          _SummaryBox(
                            label: 'Kegiatan Tayang / Selesai',
                            value: '$disetujuiCount Kegiatan',
                            color: AppColors.success,
                          ),
                          _SummaryBox(
                            label: 'Total Mahasiswa Terdaftar',
                            value: '$totalPendaftar Peserta',
                            color: AppColors.primary,
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_kegiatanList.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('Belum ada kegiatan donor yang diajukan oleh organisasi Anda.')),
                          ),
                        )
                      else
                        ..._kegiatanList.map((keg) {
                          final bisaPresensi =
                              keg.status == AppStatus.kegiatanDisetujui || keg.status == AppStatus.kegiatanSelesai;
                          final bisaEdit =
                              keg.status == AppStatus.kegiatanRevisi || keg.status == AppStatus.kegiatanMenunggu;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          keg.nama,
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusBadge(status: keg.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '📅 ${DonorHelper.formatTanggal(keg.tanggal)}   •   📍 ${keg.lokasi}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Pendaftar Terdaftar: ${keg.jumlahPendaftar} / ${keg.kuota} peserta',
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                                        ),
                                      ),
                                      if (bisaEdit)
                                        OutlinedButton.icon(
                                          onPressed: () => _bukaDialogFormKegiatan(user, existing: keg),
                                          icon: const Icon(Icons.edit_outlined, size: 17),
                                          label: const Text('Edit & Ajukan Ulang'),
                                        ),
                                      if (bisaPresensi)
                                        ElevatedButton.icon(
                                          onPressed: () => _bukaPresensiHariH(keg),
                                          icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                                          label: const Text('Presensi Hari-H'),
                                        ),
                                    ],
                                  ),
                                  if (keg.catatanVerifikasi != null && keg.catatanVerifikasi!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.warningBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Catatan Admin KSR: ${keg.catatanVerifikasi}',
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _PresensiKegiatanPage extends StatefulWidget {
  final KegiatanModel kegiatan;

  const _PresensiKegiatanPage({required this.kegiatan});

  @override
  State<_PresensiKegiatanPage> createState() => _PresensiKegiatanPageState();
}

class _PresensiKegiatanPageState extends State<_PresensiKegiatanPage> {
  List _peserta = [];
  bool _loading = true;
  String _kataKunci = '';
  String _filterHadir = 'Semua';

  @override
  void initState() {
    super.initState();
    _muatPeserta();
  }

  Future<void> _muatPeserta() async {
    setState(() => _loading = true);
    try {
      final data = await KegiatanService.getPresensiPenyelenggara(widget.kegiatan.idKegiatan);
      if (mounted) {
        setState(() {
          _peserta = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat daftar presensi: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _ubahStatusHadir(Map row, String statusBaru) async {
    try {
      await KegiatanService.catatPresensiPenyelenggara(
        idPendaftaran: row['id_pendaftaran'].toString(),
        statusHadir: statusBaru,
      );
      await _muatPeserta();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memperbarui presensi: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _salinCsvPresensi() async {
    final buffer = StringBuffer();
    buffer.writeln('No;Kode Tiket;Nama Mahasiswa;NPM;Program Studi;Status Kehadiran;Waktu Hadir');
    for (var i = 0; i < _peserta.length; i++) {
      final p = _peserta[i];
      final waktuRaw = p['waktu_hadir']?.toString();
      final waktuFmt = waktuRaw != null
          ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(waktuRaw).toLocal())
          : '-';
      buffer.writeln(
        '${i + 1};'
        '"${p['kode_tiket']}";'
        '"${p['nama_lengkap']}";'
        '"${p['npm']}";'
        '"${p['program_studi']}";'
        '"${p['status_hadir']}";'
        '"$waktuFmt"',
      );
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daftar hadir (CSV) berhasil disalin! Silakan tempel di Excel/Google Sheets.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hadirCount = _peserta.where((p) => p['status_hadir'] == 'Hadir').length;
    final belumCount = _peserta.length - hadirCount;

    final filtered = _peserta.where((p) {
      final status = p['status_hadir']?.toString() ?? 'Belum hadir';
      if (_filterHadir != 'Semua' && status != _filterHadir) return false;

      if (_kataKunci.isEmpty) return true;
      final q = _kataKunci.toLowerCase();
      final nama = (p['nama_lengkap'] ?? '').toString().toLowerCase();
      final npm = (p['npm'] ?? '').toString().toLowerCase();
      final tiket = (p['kode_tiket'] ?? '').toString().toLowerCase();
      return nama.contains(q) || npm.contains(q) || tiket.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Peserta Hari-H'),
        actions: [
          if (_peserta.isNotEmpty)
            TextButton.icon(
              onPressed: _salinCsvPresensi,
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              label: const Text('Salin CSV'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.kegiatan.nama, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        '${DonorHelper.formatTanggal(widget.kegiatan.tanggal)} • ${widget.kegiatan.lokasi}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 14),

                      // Banner Kepatuhan Privasi UU PDP
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.neutralBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Perlindungan Privasi UU PDP: Nomor WhatsApp, email, dan data skrining medis peserta disembunyikan. Gunakan Nama, NPM, atau Kode Tiket untuk verifikasi kehadiran di meja registrasi.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Counter Kehadiran
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          Chip(label: Text('Terdaftar: ${_peserta.length}')),
                          Chip(
                            backgroundColor: AppColors.primaryLight,
                            label: Text(
                              'Sudah Hadir: $hadirCount',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success),
                            ),
                          ),
                          Chip(label: Text('Belum Hadir: $belumCount')),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Pencarian & Filter
                      TextField(
                        onChanged: (v) => setState(() => _kataKunci = v.trim()),
                        decoration: const InputDecoration(
                          hintText: 'Cari Nama Mahasiswa, NPM, atau Kode Tiket...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: ['Semua', 'Belum hadir', 'Hadir'].map((f) {
                          return ChoiceChip(
                            label: Text(f),
                            selected: _filterHadir == f,
                            onSelected: (_) => setState(() => _filterHadir = f),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      if (filtered.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(28),
                            child: Center(child: Text('Tidak ada data peserta yang sesuai dengan pencarian.')),
                          ),
                        )
                      else
                        ...filtered.map((row) {
                          final hadir = row['status_hadir'] == 'Hadir';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: hadir ? AppColors.success : AppColors.primaryLight,
                                child: Text(
                                  row['kode_tiket'].toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: hadir ? Colors.white : AppColors.primary,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${row['nama_lengkap']}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                'NPM: ${row['npm']} • ${row['program_studi']}\nTiket: #${row['kode_tiket']} • Hasil Medis KSR: ${row['hasil']}',
                                style: const TextStyle(fontSize: 12.5),
                              ),
                              isThreeLine: true,
                              trailing: hadir
                                  ? OutlinedButton.icon(
                                      onPressed: () => _ubahStatusHadir(row, 'Belum hadir'),
                                      icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                                      label: const Text('Hadir'),
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _ubahStatusHadir(row, 'Hadir'),
                                      child: const Text('Tandai Hadir'),
                                    ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
