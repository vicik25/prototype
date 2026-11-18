import 'package:file_picker/file_picker.dart' as fp;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:states_rebuilder/states_rebuilder.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_status.dart';
import '../../core/utils/donor_helper.dart';
import '../../core/utils/file_bytes_helper.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../main.dart';
import '../../models/kegiatan_model.dart';
import '../../models/notifikasi_model.dart';
import '../../models/pengguna_model.dart';
import '../../models/permintaan_model.dart';
import '../../services/auth_service.dart';
import '../../services/kegiatan_service.dart';
import '../../services/pendonor_service.dart';
import '../../services/permintaan_service.dart';
import '../beranda/beranda_page.dart';
import 'widgets/digital_donor_card.dart';
import 'widgets/skrining_dialog.dart';
import 'widgets/tanggapan_permintaan_dialog.dart';

class MahasiswaDashboard extends StatefulWidget {
  const MahasiswaDashboard({super.key});

  @override
  State<MahasiswaDashboard> createState() => _MahasiswaDashboardState();
}

class _MahasiswaDashboardState extends State<MahasiswaDashboard> {
  int _selectedIndex = 0;
  int _jedaHari = 61;
  bool _isUpdatingStatus = false;

  List<UndanganNotifikasiModel> _undanganList = [];
  List<KegiatanModel> _kegiatanList = [];
  Set<String> _kegiatanTerdaftarIds = {};
  List<RiwayatDonorModel> _riwayatList = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _muatSemuaData();
  }

  Future<void> _muatSemuaData() async {
    final user = currentUserRM.state;
    if (user == null) return;

    setState(() => _isLoadingData = true);
    try {
      final params = await KegiatanService.getAllParameter();
      final jeda = int.tryParse(params['jeda_donor_hari'] ?? '61') ?? 61;

      final undangan = await PermintaanService.getUndanganUntukMahasiswa(user.idPengguna);
      final kegiatan = await KegiatanService.getKegiatanDisetujui();
      final riwayat = await PendonorService.getRiwayatDonor(user.idPengguna);

      final daftarRes = await supabase
          .from('pendaftaran_kegiatan')
          .select('id_kegiatan')
          .eq('id_pengguna', user.idPengguna)
          .eq('status_pendaftaran', 'Terdaftar');

      final terdaftarIds = (daftarRes as List).map((e) => e['id_kegiatan'] as String).toSet();

      if (mounted) {
        setState(() {
          _jedaHari = jeda;
          _undanganList = undangan;
          _kegiatanList = kegiatan;
          _kegiatanTerdaftarIds = terdaftarIds;
          _riwayatList = riwayat;
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _handleNotifAction(NotifikasiInboxModel notif, PenggunaModel user) async {
    if (notif.tipe == 'permintaan_darah' && notif.referensiId != null) {
      await _muatSemuaData();
      final cocok = _undanganList.where((u) => u.idPermintaan == notif.referensiId).toList();
      if (cocok.isNotEmpty && mounted) {
        final updated = await TanggapanPermintaanDialog.show(context, undangan: cocok.first, mahasiswa: user);
        if (updated == true) _muatSemuaData();
      }
    } else if (notif.tipe == 'kegiatan') {
      setState(() => _selectedIndex = 1);
    }
  }

  Future<void> _bukaDialogUnggahBuktiMandiri(PenggunaModel user) async {
    final formKey = GlobalKey<FormState>();
    final lokasiCtrl = TextEditingController(text: 'UDD PMI Kota Tasikmalaya');
    DateTime tanggalDonor = DateTime.now();
    Uint8List? fileBytes;
    String? fileName;
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Catat Bukti Donor Mandiri'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unggah foto kartu donor atau bukti pelaksanaan donor di UDD PMI / luar agenda kampus agar Admin KSR dapat memperbarui masa jeda 61 hari Anda.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: tanggalDonor,
                          firstDate: DateTime.now().subtract(const Duration(days: 180)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => tanggalDonor = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Pelaksanaan Donor *',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(DonorHelper.formatTanggal(tanggalDonor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: lokasiCtrl,
                      decoration: const InputDecoration(labelText: 'Lokasi UDD PMI / Rumah Sakit *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Lokasi donor wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
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
                              setDialogState(() {
                                fileBytes = bytes;
                                fileName = res.first.name;
                              });
                            }
                          }
                        },
                        icon: Icon(
                          fileBytes != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                          color: fileBytes != null ? AppColors.success : AppColors.primary,
                        ),
                        label: Text(
                          fileName != null ? 'Terpilih: $fileName' : 'Pilih Foto Bukti Donor (JPG/PNG/PDF) *',
                        ),
                      ),
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
                      if (fileBytes == null || fileName == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Foto bukti donor wajib diunggah.'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => submitting = true);
                      try {
                        await PendonorService.ajukanBuktiDonorMandiri(
                          idPengguna: user.idPengguna,
                          tanggalDonor: tanggalDonor,
                          lokasiDonor: lokasiCtrl.text,
                          fileBytes: fileBytes!,
                          fileName: fileName!,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _muatSemuaData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bukti donor mandiri berhasil dikirim ke Admin UKM KSR!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => submitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal mengunggah bukti: $e'), backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    },
              child: const Text('Kirim Bukti'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnBuilder<PenggunaModel?>.data(
      listenTo: currentUserRM,
      builder: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final isDesktop = Responsive.isDesktop(context);
        final pages = [
          _buildRingkasanTab(user),
          _buildKegiatanTab(user),
          _buildRiwayatTab(user),
          _buildProfilPrivasiTab(user),
        ];

        return Scaffold(
          appBar: CustomAppBar(
            user: user,
            subtitle: '${user.namaLengkap} (${user.npm ?? '-'})',
            onNotifActionTap: (notif) => _handleNotifAction(notif, user),
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
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Ringkasan'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.event_outlined),
                      selectedIcon: Icon(Icons.event_rounded),
                      label: Text('Kegiatan'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history_rounded),
                      label: Text('Riwayat'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: Text('Profil'),
                    ),
                  ],
                ),
              if (isDesktop) const VerticalDivider(width: 1, color: AppColors.border),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _muatSemuaData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: _isLoadingData
                            ? const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())
                            : pages[_selectedIndex],
                      ),
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
                    NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Ringkasan'),
                    NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Kegiatan'),
                    NavigationDestination(icon: Icon(Icons.history_outlined), label: 'Riwayat'),
                    NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
                  ],
                ),
        );
      },
    );
  }

  // =========================================================================
  // TAB 1: RINGKASAN, DIGITAL DONOR CARD, SKRINING & PANGGILAN DONOR
  // =========================================================================
  Widget _buildRingkasanTab(PenggunaModel user) {
    final skrining = user.skriningTerbaru;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user.statusAkun != AppStatus.akunTerverifikasi)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.catatanVerifikasi != null && user.catatanVerifikasi!.isNotEmpty
                        ? 'Status Akun: ${user.statusAkun}. Catatan Admin: ${user.catatanVerifikasi}'
                        : 'Status Akun Anda saat ini "${user.statusAkun}". Anda akan masuk daftar pencocokan setelah diverifikasi Admin UKM KSR.',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

        DigitalDonorCard(
          user: user,
          jedaHari: _jedaHari,
          isUpdatingStatus: _isUpdatingStatus,
          onToggleKetersediaan: (val) async {
            setState(() => _isUpdatingStatus = true);
            await PendonorService.updateKetersediaan(
              user.idPengguna,
              val ? AppStatus.tersediaAktif : AppStatus.tersediaNonaktif,
            );
            if (mounted) setState(() => _isUpdatingStatus = false);
          },
        ),

        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Skrining Kelayakan Mandiri',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      if (skrining != null) ...[
                        StatusBadge(status: skrining.hasil),
                        const SizedBox(height: 4),
                        Text(
                          'Diisi pada ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(skrining.waktuIsi.toLocal())}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ] else
                        const Text(
                          'Belum pernah mengisi skrining mandiri. Silakan isi untuk syarat pencocokan awal.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await SkriningDialog.show(context, user: user);
                  },
                  child: Text(skrining == null ? 'Isi Skrining' : 'Isi Ulang'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        const Text(
          'Panggilan Permintaan Darah Untuk Anda',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tanggapi panggilan donor yang sesuai dengan golongan darah Anda.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 14),

        if (_undanganList.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Belum ada panggilan permintaan donor darah masuk.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          )
        else
          ..._undanganList.map((und) {
            final minta = und.permintaan;
            final menunggu =
                und.tanggapan == AppStatus.tanggapanMenunggu || und.tanggapan == AppStatus.tanggapanDitunda;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                      child: Text(
                        minta?.goldarLengkap ?? '-',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            minta?.rumahSakit ?? 'Rumah Sakit Tujuan',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kebutuhan: ${minta?.jumlahKantong ?? 1} kantong  •  Batas: ${DateFormat('dd MMM, HH:mm', 'id_ID').format(und.batasRespons.toLocal())}',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          StatusBadge(status: und.tanggapan),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final res = await TanggapanPermintaanDialog.show(context, undangan: und, mahasiswa: user);
                        if (res == true) _muatSemuaData();
                      },
                      child: Text(menunggu ? 'Tanggapi' : 'Detail'),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // =========================================================================
  // TAB 2: KEGIATAN DONOR KAMPUS (F7)
  // =========================================================================
  Widget _buildKegiatanTab(PenggunaModel user) {
    final isVerified = user.statusAkun == AppStatus.akunTerverifikasi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kegiatan Donor Darah Kampus', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(
          'Daftarkan diri Anda pada kegiatan donor darah yang telah diverifikasi Admin UKM KSR.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),

        if (_kegiatanList.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('Belum ada kegiatan donor yang aktif saat ini.')),
            ),
          )
        else
          ..._kegiatanList.map((keg) {
            final sudahDaftar = _kegiatanTerdaftarIds.contains(keg.idKegiatan);
            final penuh = keg.sisaKuota <= 0 && !sudahDaftar;
            final amanJedaPadaTanggalAcara = DonorHelper.isBisaDonor(
              user.profilPendonor?.tanggalDonorTerakhir,
              jedaHari: _jedaHari,
              tanggalAcuan: keg.tanggal,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(keg.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        StatusBadge(status: sudahDaftar ? 'Terdaftar' : 'Sisa ${keg.sisaKuota} kuota'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '📅 ${DonorHelper.formatTanggal(keg.tanggal)}   •   📍 ${keg.lokasi}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    if (!amanJedaPadaTanggalAcara) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Peringatan: Masa jeda donor 61 hari Anda belum selesai pada tanggal pelaksanaan kegiatan ini.',
                                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (sudahDaftar)
                          OutlinedButton(
                            onPressed: () async {
                              await KegiatanService.batalDaftarKegiatan(
                                idKegiatan: keg.idKegiatan,
                                idMahasiswa: user.idPengguna,
                              );
                              _muatSemuaData();
                            },
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                            child: const Text('Batalkan Pendaftaran'),
                          )
                        else
                          ElevatedButton(
                            onPressed: (!isVerified || penuh)
                                ? null
                                : () async {
                                    await KegiatanService.daftarKegiatan(
                                      idKegiatan: keg.idKegiatan,
                                      idMahasiswa: user.idPengguna,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Berhasil mendaftar kegiatan donor!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                    _muatSemuaData();
                                  },
                            child: Text(
                              !isVerified
                                  ? 'Akun Belum Terverifikasi'
                                  : penuh
                                  ? 'Kuota Penuh'
                                  : 'Daftar Kegiatan',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // =========================================================================
  // TAB 3: RIWAYAT DONOR, KARTU APRESIASI & UNGGAH BUKTI MANDIRI (F6)
  // =========================================================================
  Widget _buildRiwayatTab(PenggunaModel user) {
    final berhasilCount = _riwayatList.where((r) => r.status == AppStatus.hasilBerhasil).length;
    final estimasiNyawa = berhasilCount * 3;
    final gelarApresiasi = berhasilCount >= 10
        ? 'Pahlawan Kemanusiaan'
        : berhasilCount >= 5
        ? 'Pendonor Teladan'
        : berhasilCount >= 1
        ? 'Pendonor Aktif'
        : 'Calon Pahlawan';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Riwayat & Apresiasi Donor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text(
                    'Rekap donor darah sukarela dan pencatatan donor mandiri di UDD PMI.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _bukaDialogUnggahBuktiMandiri(user),
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Catat Donor Mandiri'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Kartu Apresiasi Kontribusi Mahasiswa
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Lencana: $gelarApresiasi',
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$berhasilCount Kali Berhasil Donor Darah',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      berhasilCount > 0
                          ? 'Kontribusi Anda berpotensi menyelamatkan hingga $estimasiNyawa nyawa pasien.'
                          : 'Mulai aksi donor pertama Anda untuk meraih lencana apresiasi kemanusiaan.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        if (_riwayatList.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('Belum ada riwayat donor yang tercatat di sistem.')),
            ),
          )
        else
          ..._riwayatList.map((r) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.favorite_rounded, color: AppColors.primary),
                ),
                title: Text(DonorHelper.formatTanggal(r.tanggal), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Sumber: ${r.sumber}  •  Jenis: ${r.jenisDonor}'),
                trailing: StatusBadge(status: r.status),
              ),
            );
          }),
      ],
    );
  }

  // =========================================================================
  // TAB 4: PROFIL, KONTAK WHATSAPP & PENGATURAN PRIVASI UU PDP (F1 & F9)
  // =========================================================================
  Widget _buildProfilPrivasiTab(PenggunaModel user) {
    final profil = user.profilPendonor;
    final waCtrl = TextEditingController(text: user.noWhatsapp ?? '');
    final domisiliCtrl = TextEditingController(text: profil?.domisili ?? '');
    String selectedGoldar = profil?.golonganDarah ?? 'O';
    String selectedRhesus = profil?.rhesus ?? 'Positif';

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profil & Pengaturan Data Pribadi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pembaruan Data & Kontak Darurat',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pastikan nomor WhatsApp selalu aktif untuk menerima koordinasi panggilan donor darurat. Perubahan golongan darah akan diperiksa ulang oleh Admin.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: waCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor WhatsApp Aktif',
                        prefixIcon: Icon(Icons.phone_android_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedGoldar,
                            decoration: const InputDecoration(labelText: 'Golongan Darah'),
                            items: [
                              'A',
                              'B',
                              'AB',
                              'O',
                            ].map((g) => DropdownMenuItem(value: g, child: Text('Golongan $g'))).toList(),
                            onChanged: (v) => setLocalState(() => selectedGoldar = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedRhesus,
                            decoration: const InputDecoration(labelText: 'Rhesus'),
                            items: [
                              'Positif',
                              'Negatif',
                            ].map((r) => DropdownMenuItem(value: r, child: Text('Rhesus $r'))).toList(),
                            onChanged: (v) => setLocalState(() => selectedRhesus = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: domisiliCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Domisili Kecamatan / Kota',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (profil == null) return;
                        await PendonorService.updateProfilPendonor(
                          idPengguna: user.idPengguna,
                          golonganDarahBaru: selectedGoldar,
                          rhesusBaru: selectedRhesus,
                          golonganDarahLama: profil.golonganDarah,
                          rhesusLama: profil.rhesus,
                          statusGoldarSaatIni: profil.statusGolonganDarah,
                          noWhatsappBaru: waCtrl.text.trim(),
                          domisili: domisiliCtrl.text.trim(),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profil dan nomor WhatsApp berhasil diperbarui.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      child: const Text('Simpan Perubahan Profil'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hak Subjek Data Pribadi (UU No. 27 Tahun 2022)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.danger),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Anda berhak menarik persetujuan pemrosesan data dan menonaktifkan akun kapan saja. Akun yang dinonaktifkan tidak akan lagi disertakan dalam pencocokan pendonor.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final yakin = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Tarik Persetujuan & Nonaktifkan Akun?'),
                            content: const Text(
                              'Akun Anda akan segera dinonaktifkan dan Anda akan keluar dari sistem. Lanjutkan?',
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                child: const Text('Ya, Nonaktifkan'),
                              ),
                            ],
                          ),
                        );

                        if (yakin == true) {
                          await AuthService.tarikPersetujuanDanNonaktifkan(user.idPengguna);
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const BerandaPage()),
                              (_) => false,
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                      icon: const Icon(Icons.no_accounts_outlined),
                      label: const Text('Tarik Persetujuan & Nonaktifkan Akun'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
