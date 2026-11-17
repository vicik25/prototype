import '../core/constants/app_status.dart';
import '../core/utils/donor_helper.dart';
import '../main.dart';
import '../models/kegiatan_model.dart';
import '../models/pengguna_model.dart';
import 'auth_service.dart';

class PendonorService {
  /// Ambil seluruh daftar mahasiswa pendonor (untuk Admin KSR)
  static Future<List<PenggunaModel>> getAllMahasiswaPendonor() async {
    final res = await supabase
        .from('pengguna')
        .select('*, profil_pendonor(*), skrining(*)')
        .eq('peran', AppStatus.roleMahasiswa)
        .order('waktu_dibuat', ascending: false);

    return (res as List).map((e) => PenggunaModel.fromMap(e)).toList();
  }

  /// Ambil dokumen bukti milik pendaftar
  static Future<List<DokumenBuktiModel>> getDokumenPendonor(String idPengguna) async {
    final res = await supabase
        .from('dokumen_bukti')
        .select()
        .eq('id_pengguna', idPengguna)
        .isFilter('waktu_hapus', null);

    return (res as List).map((e) => DokumenBuktiModel.fromMap(e)).toList();
  }

  /// Buat Signed URL sementara (1 jam) untuk pratinjau KTP / Kartu Donor privat
  static Future<String> getSignedUrlDokumen(String lokasiBerkas) async {
    return await supabase.storage.from('dokumen-bukti').createSignedUrl(lokasiBerkas, 3600);
  }

  /// Hapus file bukti setelah verifikasi selesai (FR-F2-11 minimisasi data)
  static Future<void> hapusDokumenBukti(DokumenBuktiModel doc, String adminId) async {
    await supabase.storage.from('dokumen-bukti').remove([doc.lokasiBerkas]);
    await supabase
        .from('dokumen_bukti')
        .update({'waktu_hapus': DateTime.now().toIso8601String()})
        .eq('id_dokumen', doc.idDokumen);

    await _catatLog(adminId, 'Hapus berkas bukti', 'Dokumen ${doc.jenis}', 'ID: ${doc.idDokumen}');
  }

  /// Admin memverifikasi akun & status golongan darah pendaftar (F2)
  static Future<void> verifikasiPendaftar({
    required String idMahasiswa,
    required String adminId,
    required String statusAkun, // Terverifikasi, Perlu dilengkapi, Ditolak
    required String statusGoldar, // Terverifikasi, Belum terverifikasi
    String? catatan,
  }) async {
    await supabase
        .from('pengguna')
        .update({
          'status_akun': statusAkun,
          'catatan_verifikasi': catatan,
          'diverifikasi_oleh': adminId,
          'waktu_verifikasi': DateTime.now().toIso8601String(),
        })
        .eq('id_pengguna', idMahasiswa);

    await supabase
        .from('profil_pendonor')
        .update({'status_golongan_darah': statusGoldar})
        .eq('id_pengguna', idMahasiswa);

    // Kirim notifikasi ke Inbox Mahasiswa
    await supabase.from('notifikasi_inbox').insert({
      'id_penerima': idMahasiswa,
      'judul': 'Status Verifikasi Akun: $statusAkun',
      'pesan': catatan != null && catatan.isNotEmpty
          ? 'Admin KSR menetapkan status akun Anda "$statusAkun". Catatan: $catatan'
          : 'Admin KSR menetapkan status akun Anda "$statusAkun" (Golongan darah: $statusGoldar).',
      'tipe': 'verifikasi',
    });

    await _catatLog(
      adminId,
      'Verifikasi pendaftar',
      'Mahasiswa $idMahasiswa',
      'Status: $statusAkun, Goldar: $statusGoldar',
    );
  }

  /// Simpan hasil Skrining Mandiri (hanya hasil & waktu, tanpa jawaban detail medis - BR-15)
  static Future<void> simpanSkrining({required String idPengguna, String? idPermintaan, required String hasil}) async {
    await supabase.from('skrining').insert({
      'id_pengguna': idPengguna,
      'id_permintaan': idPermintaan,
      'hasil': hasil,
      'versi_aturan': 'v1.0-UDD-Tasik',
    });

    await AuthService.fetchCurrentUserProfile(idPengguna);
  }

  /// Toggle ketersediaan pendonor (Aktif / Nonaktif - FR-F5-14)
  static Future<void> updateKetersediaan(String idPengguna, String statusBaru) async {
    await supabase.from('profil_pendonor').update({'ketersediaan': statusBaru}).eq('id_pengguna', idPengguna);

    await AuthService.fetchCurrentUserProfile(idPengguna);
  }

  /// Update profil & golongan darah (mengembalikan status goldar ke Belum terverifikasi jika berubah - FR-F1-13)
  static Future<void> updateProfilPendonor({
    required String idPengguna,
    required String golonganDarahBaru,
    required String rhesusBaru,
    required String golonganDarahLama,
    required String rhesusLama,
    required String statusGoldarSaatIni,
    String? domisili,
  }) async {
    final isGoldarBerubah = golonganDarahBaru != golonganDarahLama || rhesusBaru != rhesusLama;

    await supabase
        .from('profil_pendonor')
        .update({
          'golongan_darah': golonganDarahBaru,
          'rhesus': rhesusBaru,
          'status_golongan_darah': isGoldarBerubah ? AppStatus.goldarBelumTerverifikasi : statusGoldarSaatIni,
          'domisili': domisili,
        })
        .eq('id_pengguna', idPengguna);

    await AuthService.fetchCurrentUserProfile(idPengguna);
  }

  /// Admin mencatat hasil donor pasca-pelaksanaan di UDD PMI (F6)
  static Future<void> catatHasilDonor({
    required String idPendonor,
    required String adminId,
    required DateTime tanggalDonor,
    required String sumber, // 'Permintaan' atau 'Kegiatan'
    String? idPermintaan,
    String? idKegiatan,
    required String statusHasil, // Berhasil donor, Tidak lolos pemeriksaan petugas, Tidak hadir
    int jedaHari = 61,
  }) async {
    final tglStr = tanggalDonor.toIso8601String().split('T').first;

    // 1. Simpan riwayat donor (tanpa data medis Hb/tensi)
    await supabase.from('riwayat_donor').insert({
      'id_pengguna': idPendonor,
      'sumber': sumber,
      'id_permintaan': idPermintaan,
      'id_kegiatan': idKegiatan,
      'tanggal': tglStr,
      'jenis_donor': 'Darah lengkap',
      'status': statusHasil,
      'dicatat_oleh': adminId,
    });

    // 2. Hanya jika "Berhasil donor", perbarui tanggal_donor_terakhir & kirim info jeda
    if (statusHasil == AppStatus.hasilBerhasil) {
      await supabase.from('profil_pendonor').update({'tanggal_donor_terakhir': tglStr}).eq('id_pengguna', idPendonor);

      final tglBolehLagi = DonorHelper.hitungTanggalBolehDonor(tanggalDonor, jedaHari: jedaHari);
      await supabase.from('notifikasi_inbox').insert({
        'id_penerima': idPendonor,
        'judul': 'Terima Kasih! Donor Darah Tercatat',
        'pesan':
            'Donor Anda pada ${DonorHelper.formatTanggal(tanggalDonor)} berhasil dicatat. Anda memasuki masa jeda $jedaHari hari dan dapat kembali mendonor mulai ${DonorHelper.formatTanggal(tglBolehLagi)}.',
        'tipe': 'pengingat_jeda',
      });
    }

    await _catatLog(adminId, 'Catat hasil donor', 'Pendonor $idPendonor', 'Tanggal: $tglStr, Hasil: $statusHasil');
  }

  /// Ambil riwayat donor milik mahasiswa
  static Future<List<RiwayatDonorModel>> getRiwayatDonor(String idPengguna) async {
    final res = await supabase
        .from('riwayat_donor')
        .select()
        .eq('id_pengguna', idPengguna)
        .order('tanggal', ascending: false);

    return (res as List).map((e) => RiwayatDonorModel.fromMap(e)).toList();
  }

  static Future<void> _catatLog(String pelakuId, String aksi, String objek, String rincian) async {
    await supabase.from('log_aktivitas').insert({
      'id_pengguna': pelakuId,
      'aksi': aksi,
      'objek': objek,
      'rincian': rincian,
    });
  }
}
