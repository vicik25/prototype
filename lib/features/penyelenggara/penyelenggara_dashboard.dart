import 'package:material_ui/material_ui.dart';
import 'package:states_rebuilder/states_rebuilder.dart';

import '../../core/constants/app_colors.dart';
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

  Future<void> _bukaDialogAjukanKegiatan(PenggunaModel user) async {
    final formKey = GlobalKey<FormState>();
    final namaCtrl = TextEditingController();
    final lokasiCtrl = TextEditingController();
    final kuotaCtrl = TextEditingController(text: '50');
    final kontakCtrl = TextEditingController(text: user.noWhatsapp ?? '');
    DateTime tanggalPilihan = DateTime.now().add(const Duration(days: 7));
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Ajukan Kegiatan Donor Darah'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      await KegiatanService.ajukanKegiatan(
                        nama: namaCtrl.text,
                        tanggal: tanggalPilihan,
                        lokasi: lokasiCtrl.text,
                        kuota: int.parse(kuotaCtrl.text.trim()),
                        kontak: kontakCtrl.text,
                        idPengaju: user.idPengguna,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _muatKegiatan();
                    },
              child: const Text('Kirim Ajuan'),
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
                                  'Pengajuan & Pantauan Kegiatan Donor',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Ajukan jadwal kegiatan donor darah kampus. Data pendaftar ditampilkan secara agregat demi privasi pendonor.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _bukaDialogAjukanKegiatan(user),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Ajukan Kegiatan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          keg.nama,
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      StatusBadge(status: keg.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '📅 ${DonorHelper.formatTanggal(keg.tanggal)}   •   📍 ${keg.lokasi}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Jumlah Pendaftar Terdaftar: ${keg.jumlahPendaftar} / ${keg.kuota} peserta',
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                                  ),
                                  if (keg.catatanVerifikasi != null && keg.catatanVerifikasi!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
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
