import 'dart:core';

import '../core/constants/app_status.dart';
import '../main.dart';
import '../models/kegiatan_model.dart';
import 'pendonor_service.dart';

class KegiatanService {
  /// Ambil kegiatan berstatus "Disetujui" untuk Beranda publik & Mahasiswa
  static Future<List<KegiatanModel>> getKegiatanDisetujui() async {
    final res = await supabase
        .from('kegiatan')
        .select('*, pendaftaran_kegiatan(status_pendaftaran)')
        .eq('status', AppStatus.kegiatanDisetujui)
        .order('tanggal', ascending: true);

    return (res as List).map((e) => KegiatanModel.fromMap(e)).toList();
  }

  /// Ambil semua kegiatan (untuk Admin) atau kegiatan milik Penyelenggara tertentu
  static Future<List<KegiatanModel>> getKegiatanByFilter({String? idPengaju}) async {
    var query = supabase.from('kegiatan').select('*, pendaftaran_kegiatan(status_pendaftaran)');

    if (idPengaju != null) {
      query = query.eq('id_pengaju', idPengaju);
    }

    final res = await query.order('waktu_dibuat', ascending: false);
    return (res as List).map((e) => KegiatanModel.fromMap(e)).toList();
  }

  /// Ajukan kegiatan baru (Penyelenggara atau Admin)
  static Future<void> ajukanKegiatan({
    required String nama,
    required DateTime tanggal,
    required String lokasi,
    required int kuota,
    required String kontak,
    required String idPengaju,
    bool langsungDisetujui = false,
  }) async {
    await supabase.from('kegiatan').insert({
      'nama': nama.trim(),
      'tanggal': tanggal.toIso8601String().split('T').first,
      'lokasi': lokasi.trim(),
      'kuota': kuota,
      'kontak': kontak.trim(),
      'id_pengaju': idPengaju,
      'status': langsungDisetujui ? AppStatus.kegiatanDisetujui : AppStatus.kegiatanMenunggu,
    });
  }

  /// Admin memverifikasi ajuan kegiatan (Disetujui / Perlu revisi / Ditolak)
  static Future<void> verifikasiKegiatan({
    required KegiatanModel kegiatan,
    required String adminId,
    required String statusBaru,
    String? catatan,
  }) async {
    await supabase
        .from('kegiatan')
        .update({'status': statusBaru, 'catatan_verifikasi': catatan, 'diverifikasi_oleh': adminId})
        .eq('id_kegiatan', kegiatan.idKegiatan);

    // Beri tahu Penyelenggara lewat Inbox
    await supabase.from('notifikasi_inbox').insert({
      'id_penerima': kegiatan.idPengaju,
      'judul': 'Status Kegiatan "${kegiatan.nama}": $statusBaru',
      'pesan': catatan != null && catatan.isNotEmpty
          ? 'Ajuan kegiatan Anda berstatus "$statusBaru". Catatan Admin: $catatan'
          : 'Ajuan kegiatan "${kegiatan.nama}" telah ditetapkan berstatus "$statusBaru".',
      'tipe': 'kegiatan',
      'referensi_id': kegiatan.idKegiatan,
    });

    await supabase.from('log_aktivitas').insert({
      'id_pengguna': adminId,
      'aksi': 'Verifikasi kegiatan',
      'objek': kegiatan.nama,
      'rincian': 'Status: $statusBaru',
    });
  }

  /// Mahasiswa mendaftar kegiatan donor (FR-F7-06)
  static Future<void> daftarKegiatan({required String idKegiatan, required String idMahasiswa}) async {
    await supabase.from('pendaftaran_kegiatan').upsert({
      'id_kegiatan': idKegiatan,
      'id_pengguna': idMahasiswa,
      'status_pendaftaran': 'Terdaftar',
      'hasil': 'Belum dicatat',
      'waktu_daftar': DateTime.now().toIso8601String(),
    }, onConflict: 'id_kegiatan, id_pengguna');
  }

  /// Mahasiswa membatalkan pendaftaran kegiatan (FR-F7-08)
  static Future<void> batalDaftarKegiatan({required String idKegiatan, required String idMahasiswa}) async {
    await supabase
        .from('pendaftaran_kegiatan')
        .update({'status_pendaftaran': 'Dibatalkan'})
        .eq('id_kegiatan', idKegiatan)
        .eq('id_pengguna', idMahasiswa);
  }

  /// Ambil daftar peserta kegiatan (untuk Admin rekap pasca-acara)
  static Future<List<PendaftaranKegiatanModel>> getPesertaKegiatan(String idKegiatan) async {
    final res = await supabase
        .from('pendaftaran_kegiatan')
        .select('*, pengguna(nama_lengkap, npm, profil_pendonor(golongan_darah, rhesus))')
        .eq('id_kegiatan', idKegiatan)
        .eq('status_pendaftaran', 'Terdaftar');

    return (res as List).map((e) => PendaftaranKegiatanModel.fromMap(e)).toList();
  }

  /// Admin merekap hasil donor peserta kegiatan & update riwayat + jeda 61 hari (FR-F7-10)
  static Future<void> rekapHasilPesertaKegiatan({
    required PendaftaranKegiatanModel peserta,
    required KegiatanModel kegiatan,
    required String adminId,
    required String hasilBaru,
    int jedaHari = 61,
  }) async {
    await supabase
        .from('pendaftaran_kegiatan')
        .update({'hasil': hasilBaru})
        .eq('id_pendaftaran', peserta.idPendaftaran);

    await PendonorService.catatHasilDonor(
      idPendonor: peserta.idPengguna,
      adminId: adminId,
      tanggalDonor: kegiatan.tanggal,
      sumber: 'Kegiatan',
      idKegiatan: kegiatan.idKegiatan,
      statusHasil: hasilBaru,
      jedaHari: jedaHari,
    );
  }

  /// Ambil Parameter Sistem Dinamis (Tabel 3.39)
  static Future<Map<String, String>> getAllParameter() async {
    final res = await supabase.from('parameter').select();
    final Map<String, String> params = {};
    for (final row in (res as List<dynamic>)) {
      params[row['kunci'] as String] = row['nilai'] as String;
    }
    return params;
  }

  /// Admin mengubah nilai Parameter Sistem
  static Future<void> updateParameter({
    required String kunci,
    required String nilaiBaru,
    required String adminId,
  }) async {
    await supabase
        .from('parameter')
        .update({'nilai': nilaiBaru, 'diubah_oleh': adminId, 'waktu_ubah': DateTime.now().toIso8601String()})
        .eq('kunci', kunci);

    await supabase.from('log_aktivitas').insert({
      'id_pengguna': adminId,
      'aksi': 'Ubah parameter sistem',
      'objek': kunci,
      'rincian': 'Nilai baru: $nilaiBaru',
    });
  }

  /// Ambil Log Aktivitas Admin (Read-only - FR-F9-14)
  static Future<List<LogAktivitasModel>> getLogAktivitas() async {
    final res = await supabase
        .from('log_aktivitas')
        .select('*, pengguna(nama_lengkap)')
        .order('waktu', ascending: false)
        .limit(100);

    return (res as List).map((e) => LogAktivitasModel.fromMap(e)).toList();
  }
}
