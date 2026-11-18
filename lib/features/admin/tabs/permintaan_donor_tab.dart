import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_status.dart';
import '../../../core/utils/donor_helper.dart';
import '../../../core/utils/file_bytes_helper.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/pengguna_model.dart';
import '../../../models/permintaan_model.dart';
import '../../../services/kegiatan_service.dart';
import '../../../services/pendonor_service.dart';
import '../../../services/permintaan_service.dart';

class PermintaanDonorTab extends StatefulWidget {
  final PenggunaModel admin;

  const PermintaanDonorTab({super.key, required this.admin});

  @override
  State<PermintaanDonorTab> createState() => _PermintaanDonorTabState();
}

class _PermintaanDonorTabState extends State<PermintaanDonorTab> {
  List<PermintaanDonorModel> _permintaanList = [];
  Map<String, String> _params = {};
  bool _isLoading = true;
  String _filterStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    _muatPermintaan();
  }

  Future<void> _muatPermintaan() async {
    setState(() => _isLoading = true);
    try {
      final list = await PermintaanService.getAllPermintaan();
      final p = await KegiatanService.getAllParameter();
      if (mounted) {
        setState(() {
          _permintaanList = list;
          _params = p;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _bukaFormBuatPermintaan() async {
    final formKey = GlobalKey<FormState>();
    final pemohonCtrl = TextEditingController();
    final kontakCtrl = TextEditingController();
    final rsCtrl = TextEditingController();
    final kantongCtrl = TextEditingController(text: '1');
    String goldar = 'O';
    String rhesus = 'Positif';
    DateTime batasKebutuhan = DateTime.now().add(const Duration(days: 2));
    Uint8List? suratBytes;
    String? suratName;
    bool submitting = false;

    final defaultBatasRespons = int.tryParse(_params['batas_respons_hari'] ?? '3') ?? 3;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Catat Permintaan Darah Baru'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: pemohonCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Pemohon / Keluarga Pasien *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: kontakCtrl,
                      decoration: const InputDecoration(labelText: 'Nomor WhatsApp Pemohon *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: rsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Rumah Sakit / UDD Tujuan *',
                        hintText: 'Contoh: RSUD dr. Soekardjo / UDD PMI Kota Tasikmalaya',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: goldar,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Golongan Darah *'),
                            items: [
                              'A',
                              'B',
                              'AB',
                              'O',
                            ].map((g) => DropdownMenuItem(value: g, child: Text('Golongan $g'))).toList(),
                            onChanged: (v) => setDialogState(() => goldar = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: rhesus,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Rhesus *'),
                            items: [
                              'Positif',
                              'Negatif',
                            ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                            onChanged: (v) => setDialogState(() => rhesus = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: kantongCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Kantong *'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: batasKebutuhan,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                        );
                        if (picked != null) {
                          setDialogState(() => batasKebutuhan = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Batas Waktu Kebutuhan *',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(DonorHelper.formatTanggal(batasKebutuhan)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final res = await fp.FilePicker.pickFiles(
                          type: fp.FileType.custom,
                          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                        );
                        if (res.isNotEmpty) {
                          final bytes = await readPlatformFileBytes(res.first);
                          if (bytes != null) {
                            setDialogState(() {
                              suratBytes = bytes;
                              suratName = res.first.name;
                            });
                          }
                        }
                      },
                      icon: Icon(
                        suratBytes != null ? Icons.check_circle : Icons.upload_file_rounded,
                        color: suratBytes != null ? AppColors.success : AppColors.primary,
                      ),
                      label: Text(suratName != null ? 'Surat RS: $suratName' : 'Unggah Surat Permintaan Rumah Sakit *'),
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
                      if (suratBytes == null || suratName == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Surat permintaan rumah sakit wajib diunggah.'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => submitting = true);
                      await PermintaanService.buatPermintaanDonor(
                        adminId: widget.admin.idPengguna,
                        namaPemohon: pemohonCtrl.text,
                        kontakPemohon: kontakCtrl.text,
                        rumahSakit: rsCtrl.text,
                        golonganDarah: goldar,
                        rhesus: rhesus,
                        jumlahKantong: int.tryParse(kantongCtrl.text) ?? 1,
                        batasWaktuKebutuhan: batasKebutuhan,
                        batasResponsHari: defaultBatasRespons,
                        suratRsBytes: suratBytes!,
                        suratRsFileName: suratName!,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _muatPermintaan();
                    },
              child: const Text('Simpan Permintaan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bukaKelolaPermintaan(PermintaanDonorModel minta) async {
    final jedaHari = int.tryParse(_params['jeda_donor_hari'] ?? '61') ?? 61;
    final batasNotif = int.tryParse(_params['batas_notifikasi_bulanan'] ?? '3') ?? 3;
    final maxGelombang = int.tryParse(_params['pendonor_per_gelombang'] ?? '10') ?? 10;

    final hasilCocok = await PermintaanService.cariKandidatCocok(
      permintaan: minta,
      jedaHari: jedaHari,
      batasNotifBulanan: batasNotif,
    );
    final undanganList = await PermintaanService.getUndanganByPermintaan(minta.idPermintaan);

    if (!mounted) return;
    final terpilihIds = hasilCocok.kandidatSiap.take(maxGelombang).map((e) => e.idPengguna).toSet();
    final gelombangBerikutnya = undanganList.isEmpty
        ? 1
        : (undanganList.map((e) => e.gelombang).reduce((a, b) => a > b ? a : b) + 1);

    final jumlahBersedia = undanganList.where((u) => u.tanggapan == AppStatus.tanggapanBersedia).length;
    final jumlahMenunggu = undanganList.where((u) => u.tanggapan == 'Menunggu tanggapan').length;
    final jumlahMenolak = undanganList.length - jumlahBersedia - jumlahMenunggu;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 760),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Koordinasi Permintaan ${minta.goldarLengkap} — ${minta.rumahSakit}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  Text(
                    'Pemohon: ${minta.namaPemohon} (${minta.kontakPemohon})  •  Kebutuhan: ${minta.jumlahKantong} kantong',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // Ringkasan Progres Gelombang untuk Eskalasi Cepat
                  if (undanganList.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.neutralBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          Text(
                            'Total Diundang: ${undanganList.length} (${gelombangBerikutnya - 1} Gelombang)',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                          ),
                          Text(
                            'Bersedia: $jumlahBersedia',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            'Menunggu Respons: $jumlahMenunggu',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: AppColors.warning,
                            ),
                          ),
                          Text(
                            'Tidak Bersedia/Tunda: $jumlahMenolak',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Langkah 1: Verifikasi Pemohon jika masih menunggu
                  if (minta.status == AppStatus.mintaMenungguVerifikasi)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Verifikasi kebenaran pemohon dan surat RS sebelum membuka pencarian pendonor:',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              await PermintaanService.verifikasiPemohon(
                                idPermintaan: minta.idPermintaan,
                                adminId: widget.admin.idPengguna,
                                disetujui: true,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              _muatPermintaan();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                            child: const Text('Setujui Pemohon'),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pantauan Undangan Terkirim
                          const Text('Daftar Pendonor Diundang:', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          if (undanganList.isEmpty)
                            const Text(
                              'Belum ada gelombang notifikasi yang dikirim.',
                              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            )
                          else
                            ...undanganList.map((u) {
                              final p = u.pendonor;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    'Gel. ${u.gelombang} • ${p?.namaLengkap ?? '-'}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    'WA: ${p?.noWhatsapp ?? '-'} • Dihubungi: ${u.sudahDihubungi ? 'Sudah' : 'Belum'}',
                                  ),
                                  trailing: Wrap(
                                    spacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      StatusBadge(status: u.tanggapan, fontSize: 11),
                                      if (p?.noWhatsapp != null)
                                        IconButton(
                                          tooltip: 'Kirim / Hubungi via WhatsApp',
                                          onPressed: () => PermintaanService.bukaWhatsApp(
                                            p!.noWhatsapp!,
                                            'Halo ${p.namaLengkap}, ada kebutuhan darah ${minta.goldarLengkap} sebanyak ${minta.jumlahKantong} kantong di ${minta.rumahSakit}. Silakan konfirmasi kesediaan melalui aplikasi SiDonor.',
                                          ),
                                          icon: const Icon(Icons.chat_rounded, color: AppColors.success),
                                        ),
                                      if (u.tanggapan == AppStatus.tanggapanBersedia)
                                        ElevatedButton(
                                          onPressed: () async {
                                            await PermintaanService.tandaiSudahDihubungi(
                                              idUndangan: u.idUndangan,
                                              catatan: 'Sudah dihubungi Admin KSR via WhatsApp',
                                            );
                                            await PendonorService.catatHasilDonor(
                                              idPendonor: u.idPengguna,
                                              adminId: widget.admin.idPengguna,
                                              tanggalDonor: DateTime.now(),
                                              sumber: 'Permintaan',
                                              idPermintaan: minta.idPermintaan,
                                              statusHasil: AppStatus.hasilBerhasil,
                                              jedaHari: jedaHari,
                                            );
                                            await PermintaanService.updateStatusPermintaan(
                                              minta.idPermintaan,
                                              AppStatus.mintaTerlaksana,
                                            );
                                            if (ctx.mounted) Navigator.pop(ctx);
                                            _muatPermintaan();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                          child: const Text('Catat Berhasil Donor', style: TextStyle(fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                          const Divider(height: 28),

                          // Pencocokan Kandidat Baru / Eskalasi Gelombang Berikutnya
                          if (minta.status == AppStatus.mintaMencari ||
                              minta.status == AppStatus.mintaPendonorBersedia) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Kandidat Gelombang $gelombangBerikutnya (${hasilCocok.kandidatSiap.length} tersedia, maks. $maxGelombang/gelombang):',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (hasilCocok.kandidatSiap.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      setDialogState(() {
                                        terpilihIds
                                          ..clear()
                                          ..addAll(hasilCocok.kandidatSiap.take(maxGelombang).map((e) => e.idPengguna));
                                      });
                                    },
                                    child: Text('Pilih $maxGelombang Teratas'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (hasilCocok.kandidatSiap.isEmpty)
                              const Text(
                                'Tidak ada kandidat baru yang memenuhi seluruh syarat saat ini.',
                                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                              )
                            else
                              ...hasilCocok.kandidatSiap.map((k) {
                                final checked = terpilihIds.contains(k.idPengguna);
                                return CheckboxListTile(
                                  dense: true,
                                  value: checked,
                                  title: Text('${k.namaLengkap} (${k.npm ?? '-'})'),
                                  subtitle: Text('WA: ${k.noWhatsapp ?? '-'} • Skrining: Memenuhi syarat awal'),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true && terpilihIds.length < maxGelombang) {
                                        terpilihIds.add(k.idPengguna);
                                      } else {
                                        terpilihIds.remove(k.idPengguna);
                                      }
                                    });
                                  },
                                );
                              }),
                            if (hasilCocok.pendonorSedangJeda.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Info: ${hasilCocok.pendonorSedangJeda.length} pendonor bergolongan darah sama sedang dalam masa jeda $jedaHari hari (otomatis dikecualikan).',
                                style: const TextStyle(fontSize: 12, color: AppColors.warning),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          await PermintaanService.updateStatusPermintaan(minta.idPermintaan, AppStatus.mintaDitutup);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _muatPermintaan();
                        },
                        child: const Text('Tutup Permintaan'),
                      ),
                      if (terpilihIds.isNotEmpty &&
                          (minta.status == AppStatus.mintaMencari || minta.status == AppStatus.mintaPendonorBersedia))
                        ElevatedButton.icon(
                          onPressed: () async {
                            final kandidat = hasilCocok.kandidatSiap
                                .where((k) => terpilihIds.contains(k.idPengguna))
                                .toList();
                            await PermintaanService.kirimGelombangNotifikasi(
                              permintaan: minta,
                              kandidatTerpilih: kandidat,
                              adminId: widget.admin.idPengguna,
                              gelombangKe: gelombangBerikutnya,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            _muatPermintaan();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gelombang ke-$gelombangBerikutnya berhasil dikirim ke ${kandidat.length} pendonor (Inbox & Push Notif HP).',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text('Kirim Gelombang $gelombangBerikutnya (${terpilihIds.length})'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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

    final filteredList = _permintaanList.where((m) {
      if (_filterStatus == 'Semua') return true;
      if (_filterStatus == 'Aktif') {
        return m.status == AppStatus.mintaMenungguVerifikasi ||
            m.status == AppStatus.mintaMencari ||
            m.status == AppStatus.mintaPendonorBersedia;
      }
      return m.status == _filterStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Permintaan Darah & Pencocokan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text(
                    'Catat kebutuhan darah dari pasien/RS, verifikasi pemohon, dan kirim notifikasi gelombang.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _bukaFormBuatPermintaan,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Permintaan'),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Filter Status Permintaan
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Semua', 'Aktif', AppStatus.mintaTerlaksana, AppStatus.mintaDitutup].map((st) {
            final selected = _filterStatus == st;
            return ChoiceChip(
              label: Text(st),
              selected: selected,
              onSelected: (_) => setState(() => _filterStatus = st),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        if (filteredList.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('Tidak ada permintaan donor darah pada filter ini.')),
            ),
          )
        else
          ...filteredList.map(
            (m) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        m.goldarLengkap,
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${m.rumahSakit} (${m.jumlahKantong} kantong)',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pemohon: ${m.namaPemohon} (${m.kontakPemohon})  •  Kebutuhan: ${DateFormat('dd MMM yyyy', 'id_ID').format(m.batasWaktuKebutuhan)}',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          StatusBadge(status: m.status),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(onPressed: () => _bukaKelolaPermintaan(m), child: const Text('Kelola')),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
