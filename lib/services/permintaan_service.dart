import 'dart:typed_data';

import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_status.dart';
import '../core/utils/donor_helper.dart';
import '../main.dart';
import '../models/pengguna_model.dart';
import '../models/permintaan_model.dart';
import 'pendonor_service.dart';

class HasilPencocokan {
  final List<PenggunaModel> kandidatSiap;
  final List<PenggunaModel> pendonorSedangJeda;

  HasilPencocokan({required this.kandidatSiap, required this.pendonorSedangJeda});
}

class PermintaanService {
  /// Ambil semua permintaan donor (untuk Admin)
  static Future<List<PermintaanDonorModel>> getAllPermintaan() async {
    final res = await supabase.from('permintaan_donor').select().order('waktu_dibuat', ascending: false);

    return (res as List).map((e) => PermintaanDonorModel.fromMap(e)).toList();
  }

  /// Buat permintaan donor baru atas nama pemohon + unggah surat RS
  static Future<void> buatPermintaanDonor({
    required String adminId,
    required String namaPemohon,
    required String kontakPemohon,
    required String rumahSakit,
    required String golonganDarah,
    required String rhesus,
    required int jumlahKantong,
    required DateTime batasWaktuKebutuhan,
    required int batasResponsHari,
    required Uint8List suratRsBytes,
    required String suratRsFileName,
  }) async {
    final inserted = await supabase
        .from('permintaan_donor')
        .insert({
          'dibuat_oleh': adminId,
          'nama_pemohon': namaPemohon.trim(),
          'kontak_pemohon': kontakPemohon.trim(),
          'rumah_sakit': rumahSakit.trim(),
          'golongan_darah': golonganDarah,
          'rhesus': rhesus,
          'jumlah_kantong': jumlahKantong,
          'batas_waktu_kebutuhan': batasWaktuKebutuhan.toIso8601String(),
          'batas_respons_hari': batasResponsHari,
          'status_pemohon': 'Belum terverifikasi',
          'status': AppStatus.mintaMenungguVerifikasi,
        })
        .select()
        .single();

    final idPermintaan = inserted['id_permintaan'];
    final suratPath = 'surat_rs/${idPermintaan}_${DateTime.now().millisecondsSinceEpoch}_$suratRsFileName';
    await supabase.storage.from('dokumen-bukti').uploadBinary(suratPath, suratRsBytes);

    await supabase.from('dokumen_bukti').insert({
      'jenis': 'Surat permintaan rumah sakit',
      'id_permintaan': idPermintaan,
      'lokasi_berkas': suratPath,
    });

    await supabase.from('log_aktivitas').insert({
      'id_pengguna': adminId,
      'aksi': 'Buat permintaan donor',
      'objek': 'Permintaan $idPermintaan',
      'rincian': 'RS: $rumahSakit, Goldar: $golonganDarah $rhesus ($jumlahKantong kantong)',
    });
  }

  /// Verifikasi pemohon berdasarkan surat RS (FR-F4-03)
  static Future<void> verifikasiPemohon({
    required String idPermintaan,
    required String adminId,
    required bool disetujui,
  }) async {
    await supabase
        .from('permintaan_donor')
        .update({
          'status_pemohon': disetujui ? 'Terverifikasi' : 'Belum terverifikasi',
          'status': disetujui ? AppStatus.mintaMencari : AppStatus.mintaDibatalkan,
        })
        .eq('id_permintaan', idPermintaan);

    await supabase.from('log_aktivitas').insert({
      'id_pengguna': adminId,
      'aksi': disetujui ? 'Verifikasi pemohon disetujui' : 'Permintaan dibatalkan',
      'objek': 'Permintaan $idPermintaan',
    });
  }

  /// Penyaringan otomatis kandidat sesuai BR-16, BR-17, dan kuota notifikasi bulanan
  static Future<HasilPencocokan> cariKandidatCocok({
    required PermintaanDonorModel permintaan,
    int jedaHari = 61,
    int batasNotifBulanan = 3,
  }) async {
    final semuaMahasiswa = await PendonorService.getAllMahasiswaPendonor();

    // Ambil daftar id_pengguna yang sudah pernah diundang pada permintaan ini
    final undanganSebelumnya = await supabase
        .from('undangan_notifikasi')
        .select('id_pengguna')
        .eq('id_permintaan', permintaan.idPermintaan);
    final sudahDiundangIds = (undanganSebelumnya as List).map((e) => e['id_pengguna']).toSet();

    // Hitung jumlah notifikasi bulan ini per pendonor
    final awalBulan = DateTime(DateTime.now().year, DateTime.now().month, 1).toIso8601String();
    final notifBulanIni = await supabase
        .from('undangan_notifikasi')
        .select('id_pengguna')
        .gte('waktu_kirim', awalBulan);

    final Map<String, int> hitunganBulanan = {};
    for (final row in (notifBulanIni as List)) {
      final uid = row['id_pengguna'] as String;
      hitunganBulanan[uid] = (hitunganBulanan[uid] ?? 0) + 1;
    }

    final List<PenggunaModel> siap = [];
    final List<PenggunaModel> sedangJeda = [];

    for (final mhs in semuaMahasiswa) {
      final profil = mhs.profilPendonor;
      if (profil == null) continue;

      // Syarat wajib: Akun Terverifikasi + Golongan Darah & Rhesus Sama Persis
      if (mhs.statusAkun != AppStatus.akunTerverifikasi) continue;
      if (profil.golonganDarah != permintaan.golonganDarah || profil.rhesus != permintaan.rhesus) {
        continue;
      }

      // Cek jeda donor
      final bisaDonor = DonorHelper.isBisaDonor(profil.tanggalDonorTerakhir, jedaHari: jedaHari);
      if (!bisaDonor) {
        sedangJeda.add(mhs);
        continue;
      }

      // Syarat kandidat siap: Aktif, Lolos Skrining awal, belum diundang di permintaan ini, kuota bulanan aman
      final aktif = profil.ketersediaan == AppStatus.tersediaAktif;
      final lolosSkrining = mhs.skriningTerbaru?.hasil == AppStatus.skriningMemenuhi;
      final belumDiundang = !sudahDiundangIds.contains(mhs.idPengguna);
      final kuotaAman = (hitunganBulanan[mhs.idPengguna] ?? 0) < batasNotifBulanan;

      if (aktif && lolosSkrining && belumDiundang && kuotaAman) {
        siap.add(mhs);
      }
    }

    return HasilPencocokan(kandidatSiap: siap, pendonorSedangJeda: sedangJeda);
  }

  /// Kirim gelombang notifikasi ke kandidat terpilih (maks 10 per gelombang - BR-23)
  static Future<void> kirimGelombangNotifikasi({
    required PermintaanDonorModel permintaan,
    required List<PenggunaModel> kandidatTerpilih,
    required String adminId,
    required int gelombangKe,
  }) async {
    final now = DateTime.now();
    final batasRespons = now.add(Duration(days: permintaan.batasResponsHari));

    for (final k in kandidatTerpilih) {
      // 1. Catat di undangan_notifikasi
      await supabase.from('undangan_notifikasi').insert({
        'id_permintaan': permintaan.idPermintaan,
        'id_pengguna': k.idPengguna,
        'gelombang': gelombangKe,
        'kanal': 'WhatsApp',
        'status_kirim': 'Terkirim',
        'tanggapan': AppStatus.tanggapanMenunggu,
        'waktu_kirim': now.toIso8601String(),
        'batas_respons': batasRespons.toIso8601String(),
      });

      // 2. Kirim ke Inbox In-App Mahasiswa secara Realtime
      await supabase.from('notifikasi_inbox').insert({
        'id_penerima': k.idPengguna,
        'judul': 'Urgent: Kebutuhan Darah ${permintaan.goldarLengkap}',
        'pesan':
            'Dibutuhkan ${permintaan.jumlahKantong} kantong darah ${permintaan.goldarLengkap} di ${permintaan.rumahSakit}. Mohon konfirmasi kesediaan Anda.',
        'tipe': 'permintaan_darah',
        'referensi_id': permintaan.idPermintaan,
      });
    }

    // Catat waktu_notifikasi_pertama jika belum ada (indikator B1)
    if (permintaan.waktuNotifikasiPertama == null) {
      await supabase
          .from('permintaan_donor')
          .update({'waktu_notifikasi_pertama': now.toIso8601String()})
          .eq('id_permintaan', permintaan.idPermintaan);
    }

    await supabase.from('log_aktivitas').insert({
      'id_pengguna': adminId,
      'aksi': 'Kirim gelombang notifikasi ke-$gelombangKe',
      'objek': 'Permintaan ${permintaan.idPermintaan}',
      'rincian': 'Dikirim ke ${kandidatTerpilih.length} pendonor',
    });
  }

  /// Ambil daftar undangan pada suatu permintaan (untuk pantauan Admin)
  static Future<List<UndanganNotifikasiModel>> getUndanganByPermintaan(String idPermintaan) async {
    final res = await supabase
        .from('undangan_notifikasi')
        .select('*, pengguna(*, profil_pendonor(*))')
        .eq('id_permintaan', idPermintaan)
        .order('gelombang', ascending: true);

    return (res as List).map((e) => UndanganNotifikasiModel.fromMap(e)).toList();
  }

  /// Ambil daftar undangan masuk milik Mahasiswa
  static Future<List<UndanganNotifikasiModel>> getUndanganUntukMahasiswa(String idMahasiswa) async {
    final res = await supabase
        .from('undangan_notifikasi')
        .select('*, permintaan_donor(*)')
        .eq('id_pengguna', idMahasiswa)
        .order('waktu_kirim', ascending: false);

    return (res as List).map((e) => UndanganNotifikasiModel.fromMap(e)).toList();
  }

  /// Mahasiswa merespons undangan (Bersedia, Tidak bersedia, Ditunda)
  static Future<void> tanggapiUndangan({
    required UndanganNotifikasiModel undangan,
    required PenggunaModel mahasiswa,
    required String tanggapanBaru,
    DateTime? tundaHingga,
  }) async {
    final now = DateTime.now();

    await supabase
        .from('undangan_notifikasi')
        .update({
          'tanggapan': tanggapanBaru,
          'tunda_hingga': tundaHingga?.toIso8601String(),
          'waktu_tanggapan': now.toIso8601String(),
        })
        .eq('id_undangan', undangan.idUndangan);

    if (tanggapanBaru == AppStatus.tanggapanBersedia) {
      // Update status permintaan menjadi "Pendonor bersedia"
      await supabase
          .from('permintaan_donor')
          .update({'status': AppStatus.mintaPendonorBersedia})
          .eq('id_permintaan', undangan.idPermintaan);

      // Catat waktu_bersedia_pertama jika belum ada (indikator B1)
      if (undangan.permintaan?.waktuBersediaPertama == null) {
        await supabase
            .from('permintaan_donor')
            .update({'waktu_bersedia_pertama': now.toIso8601String()})
            .eq('id_permintaan', undangan.idPermintaan);
      }

      // Beri notifikasi ke Admin bahwa ada pendonor yang bersedia
      final admins = await supabase.from('pengguna').select('id_pengguna').eq('peran', AppStatus.roleAdmin);

      for (final admin in admins) {
        await supabase.from('notifikasi_inbox').insert({
          'id_penerima': admin['id_pengguna'],
          'judul': 'Pendonor Menyatakan Bersedia!',
          'pesan':
              '${mahasiswa.namaLengkap} bersedia mendonor untuk permintaan di ${undangan.permintaan?.rumahSakit ?? '-'}. Segera hubungi via WhatsApp.',
          'tipe': 'permintaan_darah',
          'referensi_id': undangan.idPermintaan,
        });
      }
    }
  }

  /// Admin menandai pendonor sudah dihubungi + catatan tindak lanjut (FR-F5-09)
  static Future<void> tandaiSudahDihubungi({required String idUndangan, required String catatan}) async {
    await supabase
        .from('undangan_notifikasi')
        .update({'sudah_dihubungi': true, 'catatan_tindak_lanjut': catatan})
        .eq('id_undangan', idUndangan);
  }

  /// Ubah status permintaan (Donor terlaksana / Ditutup / Dibatalkan)
  static Future<void> updateStatusPermintaan(String idPermintaan, String statusBaru) async {
    await supabase.from('permintaan_donor').update({'status': statusBaru}).eq('id_permintaan', idPermintaan);
  }

  /// Helper buka WhatsApp langsung (Web & Mobile)
  static Future<void> bukaWhatsApp(String nomorWa, String pesan) async {
    var cleanNumber = nomorWa.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$cleanNumber?text=${Uri.encodeComponent(pesan)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
