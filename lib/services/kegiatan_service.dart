import 'dart:async';

import '../core/constants/app_status.dart';
import '../main.dart';
import '../models/kegiatan_model.dart';
import 'pendonor_service.dart';

typedef StringMap = Map<String, String>;
typedef DynamicMap = Map<String, dynamic>;

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
    final inserted = await supabase
        .from('kegiatan')
        .insert({
          'nama': nama.trim(),
          'tanggal': tanggal.toIso8601String().split('T').first,
          'lokasi': lokasi.trim(),
          'kuota': kuota,
          'kontak': kontak.trim(),
          'id_pengaju': idPengaju,
          'status': langsungDisetujui ? AppStatus.kegiatanDisetujui : AppStatus.kegiatanMenunggu,
        })
        .select('id_kegiatan')
        .single();

    if (!langsungDisetujui) {
      final admins = await supabase.from('pengguna').select('id_pengguna').eq('peran', AppStatus.roleAdmin);

      for (final admin in (admins as List)) {
        await supabase.from('notifikasi_inbox').insert({
          'id_penerima': admin['id_pengguna'],
          'judul': 'Pengajuan Kegiatan Donor Baru',
          'pesan': 'Kegiatan "${nama.trim()}" di ${lokasi.trim()} menunggu persetujuan Admin KSR.',
          'tipe': 'kegiatan',
          'referensi_id': inserted['id_kegiatan'],
        });
      }
    }
  }

  /// Penyelenggara memperbarui ajuan kegiatan yang berstatus "Perlu revisi" / menunggu
  static Future<void> revisiKegiatan({
    required String idKegiatan,
    required String nama,
    required DateTime tanggal,
    required String lokasi,
    required int kuota,
    required String kontak,
  }) async {
    await supabase
        .from('kegiatan')
        .update({
          'nama': nama.trim(),
          'tanggal': tanggal.toIso8601String().split('T').first,
          'lokasi': lokasi.trim(),
          'kuota': kuota,
          'kontak': kontak.trim(),
          'status': AppStatus.kegiatanMenunggu,
        })
        .eq('id_kegiatan', idKegiatan);

    final admins = await supabase.from('pengguna').select('id_pengguna').eq('peran', AppStatus.roleAdmin);

    for (final admin in (admins as List)) {
      await supabase.from('notifikasi_inbox').insert({
        'id_penerima': admin['id_pengguna'],
        'judul': 'Revisi Kegiatan Diajukan Ulang',
        'pesan': 'Kegiatan "${nama.trim()}" telah diperbarui oleh penyelenggara dan siap diperiksa kembali.',
        'tipe': 'kegiatan',
        'referensi_id': idKegiatan,
      });
    }
  }

  /// Ambil daftar presensi peserta untuk Penyelenggara (tanpa membuka data privasi/kontak)
  static Future<List<DynamicMap>> getPresensiPenyelenggara(String idKegiatan) async {
    final res = await supabase.rpc('get_presensi_kegiatan_penyelenggara', params: {'p_id_kegiatan': idKegiatan});
    return List<DynamicMap>.from(res as List);
  }

  /// Catat kehadiran peserta hari-H oleh Penyelenggara
  static Future<void> catatPresensiPenyelenggara({required String idPendaftaran, required String statusHadir}) async {
    await supabase.rpc(
      'catat_presensi_penyelenggara',
      params: {'p_id_pendaftaran': idPendaftaran, 'p_status_hadir': statusHadir},
    );
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
  static Future<StringMap> getAllParameter() async {
    final res = await supabase.from('parameter').select();
    final StringMap params = {};
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
