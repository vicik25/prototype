import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_status.dart';
import '../../../core/utils/donor_helper.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/pengguna_model.dart';
import '../../../services/pendonor_service.dart';
import '../../../services/permintaan_service.dart';

class VerifikasiDaftarPendonorTab extends StatefulWidget {
  final PenggunaModel admin;

  const VerifikasiDaftarPendonorTab({super.key, required this.admin});

  @override
  State<VerifikasiDaftarPendonorTab> createState() => _VerifikasiDaftarPendonorTabState();
}

class _VerifikasiDaftarPendonorTabState extends State<VerifikasiDaftarPendonorTab> {
  List<PenggunaModel> _semuaMahasiswa = [];
  bool _isLoading = true;
  String _filterGoldar = 'Semua';
  String _filterStatus = 'Semua';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _muatPendonor();
  }

  Future<void> _muatPendonor() async {
    setState(() => _isLoading = true);
    try {
      final list = await PendonorService.getAllMahasiswaPendonor();
      if (mounted) {
        setState(() {
          _semuaMahasiswa = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _bukaModalVerifikasi(PenggunaModel mhs) async {
    final dokumenList = await PendonorService.getDokumenPendonor(mhs.idPengguna);
    if (!mounted) return;

    String statusAkun = mhs.statusAkun == AppStatus.akunMenunggu ? AppStatus.akunTerverifikasi : mhs.statusAkun;
    String statusGoldar = mhs.profilPendonor?.statusGolonganDarah ?? AppStatus.goldarBelumTerverifikasi;
    final catatanCtrl = TextEditingController(text: mhs.catatanVerifikasi ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Verifikasi: ${mhs.namaLengkap}'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NPM: ${mhs.npm ?? '-'}  •  Prodi: ${mhs.programStudi ?? '-'}'),
                  Text('Golongan Darah: ${mhs.profilPendonor?.goldarLengkap ?? '-'}'),
                  Text('WhatsApp: ${mhs.noWhatsapp ?? '-'}  •  Email: ${mhs.email}'),
                  const Divider(height: 24),
                  const Text('Dokumen Bukti Terunggah:', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (dokumenList.isEmpty)
                    const Text(
                      'Tidak ada berkas aktif (sudah dihapus atau belum diunggah).',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    )
                  else
                    ...dokumenList.map(
                      (doc) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                          title: Text(doc.jenis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final url = await PendonorService.getSignedUrlDokumen(doc.lokasiBerkas);
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                child: const Text('Lihat Berkas'),
                              ),
                              IconButton(
                                tooltip: 'Hapus berkas setelah verifikasi (Minimisasi Data)',
                                onPressed: () async {
                                  await PendonorService.hapusDokumenBukti(doc, widget.admin.idPengguna);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _bukaModalVerifikasi(mhs);
                                },
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: statusAkun,
                    decoration: const InputDecoration(labelText: 'Keputusan Status Akun'),
                    items: [
                      AppStatus.akunTerverifikasi,
                      AppStatus.akunPerluDilengkapi,
                      AppStatus.akunDitolak,
                      AppStatus.akunMenunggu,
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setDialogState(() => statusAkun = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: statusGoldar,
                    decoration: const InputDecoration(labelText: 'Status Verifikasi Golongan Darah'),
                    items: [
                      AppStatus.goldarTerverifikasi,
                      AppStatus.goldarBelumTerverifikasi,
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setDialogState(() => statusGoldar = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: catatanCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Verifikasi (Wajib jika Perlu dilengkapi / Ditolak)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
            ElevatedButton(
              onPressed: () async {
                await PendonorService.verifikasiPendaftar(
                  idMahasiswa: mhs.idPengguna,
                  adminId: widget.admin.idPengguna,
                  statusAkun: statusAkun,
                  statusGoldar: statusGoldar,
                  catatan: catatanCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _muatPendonor();
              },
              child: const Text('Simpan Keputusan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final antrean = _semuaMahasiswa
        .where((m) => m.statusAkun == AppStatus.akunMenunggu || m.statusAkun == AppStatus.akunPerluDilengkapi)
        .toList();

    final filtered = _semuaMahasiswa.where((m) {
      final cocokNama =
          m.namaLengkap.toLowerCase().contains(_searchQuery.toLowerCase()) || (m.npm ?? '').contains(_searchQuery);
      final cocokGoldar = _filterGoldar == 'Semua' || m.profilPendonor?.golonganDarah == _filterGoldar;
      final cocokStatus = _filterStatus == 'Semua' || m.statusAkun == _filterStatus;
      return cocokNama && cocokGoldar && cocokStatus;
    }).toList();

    if (_isLoading) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bagian 1: Antrean Verifikasi Pendaftar Baru
        Row(
          children: [
            const Text('Antrean Verifikasi Pendaftar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: Text(
                '${antrean.length} Menunggu',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (antrean.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('Tidak ada pendaftar baru yang menunggu verifikasi.')),
            ),
          )
        else
          ...antrean.map(
            (m) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    m.profilPendonor?.goldarLengkap ?? '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                title: Text('${m.namaLengkap} (${m.npm ?? '-'})', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${m.programStudi ?? '-'}  •  WA: ${m.noWhatsapp ?? '-'}'),
                trailing: ElevatedButton(
                  onPressed: () => _bukaModalVerifikasi(m),
                  child: const Text('Periksa & Verifikasi'),
                ),
              ),
            ),
          ),

        const SizedBox(height: 28),

        // Bagian 2: Direktori Seluruh Pendonor (Kontak WA & Email Terbuka untuk Admin KSR)
        const Text('Direktori Pendonor Mahasiswa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(
          'Kontak WhatsApp dan email pendonor dapat diakses langsung oleh Admin UKM KSR untuk koordinasi.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 14),

        // Filter Bar
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                decoration: const InputDecoration(hintText: 'Cari nama atau NPM...', prefixIcon: Icon(Icons.search)),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                initialValue: _filterGoldar,
                decoration: const InputDecoration(labelText: 'Gol. Darah'),
                items: ['Semua', 'A', 'B', 'AB', 'O'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _filterGoldar = v!),
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                initialValue: _filterStatus,
                decoration: const InputDecoration(labelText: 'Status Akun'),
                items: [
                  'Semua',
                  AppStatus.akunTerverifikasi,
                  AppStatus.akunMenunggu,
                  AppStatus.akunPerluDilengkapi,
                  AppStatus.akunDitolak,
                ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _filterStatus = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        ...filtered.map((m) {
          final profil = m.profilPendonor;
          final bisaDonor = DonorHelper.isBisaDonor(profil?.tanggalDonorTerakhir);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          profil?.goldarLengkap ?? '-',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m.namaLengkap} (${m.npm ?? '-'})',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            Text(
                              '📱 ${m.noWhatsapp ?? '-'}   •   ✉️ ${m.email}',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (m.noWhatsapp != null && m.noWhatsapp!.isNotEmpty)
                        IconButton(
                          tooltip: 'Hubungi via WhatsApp',
                          onPressed: () => PermintaanService.bukaWhatsApp(
                            m.noWhatsapp!,
                            'Halo ${m.namaLengkap}, kami dari pengurus UKM KSR PMI Unsil terkait koordinasi pendonor darah SiDonor.',
                          ),
                          icon: const Icon(Icons.chat_rounded, color: AppColors.success),
                        ),
                      IconButton(
                        tooltip: 'Ubah Status Verifikasi',
                        onPressed: () => _bukaModalVerifikasi(m),
                        icon: const Icon(Icons.edit_note_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatusBadge(status: m.statusAkun, fontSize: 11),
                      if (profil != null) ...[
                        StatusBadge(status: 'Goldar: ${profil.statusGolonganDarah}', fontSize: 11),
                        StatusBadge(
                          status: bisaDonor ? AppStatus.jedaBisaDonor : AppStatus.jedaBelumBisa,
                          fontSize: 11,
                        ),
                        StatusBadge(status: 'Ketersediaan: ${profil.ketersediaan}', fontSize: 11),
                      ],
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
}
