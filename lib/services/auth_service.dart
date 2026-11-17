import 'dart:typed_data';

import 'package:states_rebuilder/states_rebuilder.dart';

import '../core/constants/app_status.dart';
import '../main.dart';
import '../models/pengguna_model.dart';

// Global Reactive State untuk User yang sedang login
final currentUserRM = RM.inject<PenggunaModel?>(() => null);

class AuthService {
  /// Login dan validasi apakah peran sesuai dengan pintu portal yang dipilih
  static Future<PenggunaModel> loginDenganPeran({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    final res = await supabase.auth.signInWithPassword(email: email.trim(), password: password);

    if (res.user == null) {
      throw Exception('Gagal masuk. Periksa kembali email dan kata sandi Anda.');
    }

    final userData = await fetchCurrentUserProfile(res.user!.id);

    if (userData == null) {
      await supabase.auth.signOut();
      throw Exception('Data profil akun tidak ditemukan di sistem.');
    }

    if (userData.statusAkun == AppStatus.akunNonaktif) {
      await supabase.auth.signOut();
      throw Exception('Akun Anda dinonaktifkan. Hubungi Admin UKM KSR.');
    }

    if (userData.peran != expectedRole) {
      await supabase.auth.signOut();
      throw Exception(
        'Akses ditolak: Akun ini terdaftar sebagai "${userData.peran}", silakan masuk melalui Portal ${userData.peran}.',
      );
    }

    currentUserRM.state = userData;
    return userData;
  }

  /// Ambil data lengkap pengguna beserta profil_pendonor dan skrining terbaru
  static Future<PenggunaModel?> fetchCurrentUserProfile([String? uid]) async {
    final userId = uid ?? supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await supabase
        .from('pengguna')
        .select('*, profil_pendonor(*), skrining(*)')
        .eq('id_pengguna', userId)
        .maybeSingle();

    if (data == null) return null;
    final model = PenggunaModel.fromMap(data);
    currentUserRM.state = model;
    return model;
  }

  /// Pendaftaran Mahasiswa Mandiri (F1) + Persetujuan UU PDP + Unggah KTP/Kartu Donor
  static Future<void> registerMahasiswa({
    required String namaLengkap,
    required String npm,
    required String email,
    required String noWhatsapp,
    required String programStudi,
    required String fakultas,
    required String password,
    required String golonganDarah,
    required String rhesus,
    String? domisili,
    DateTime? tanggalDonorTerakhir,
    required Uint8List ktpBytes,
    required String ktpFileName,
    Uint8List? kartuDonorBytes,
    String? kartuDonorFileName,
  }) async {
    // 1. Cek duplikasi NPM sebelum buat akun Auth
    final existingNpm = await supabase.from('pengguna').select('id_pengguna').eq('npm', npm.trim()).maybeSingle();

    if (existingNpm != null) {
      throw Exception('NPM sudah terdaftar pada akun lain.');
    }

    // 2. Buat akun di Supabase Auth
    final authRes = await supabase.auth.signUp(email: email.trim(), password: password);

    final uid = authRes.user?.id;
    if (uid == null) {
      throw Exception('Gagal membuat akun autentikasi. Pastikan email belum terdaftar.');
    }

    // 3. Simpan ke tabel pengguna
    await supabase.from('pengguna').insert({
      'id_pengguna': uid,
      'nama_lengkap': namaLengkap.trim(),
      'npm': npm.trim(),
      'email': email.trim(),
      'no_whatsapp': noWhatsapp.trim(),
      'program_studi': programStudi.trim(),
      'fakultas': fakultas.trim(),
      'peran': AppStatus.roleMahasiswa,
      'status_akun': AppStatus.akunMenunggu,
    });

    // 4. Simpan ke tabel profil_pendonor
    await supabase.from('profil_pendonor').insert({
      'id_pengguna': uid,
      'golongan_darah': golonganDarah,
      'rhesus': rhesus,
      'status_golongan_darah': AppStatus.goldarBelumTerverifikasi,
      'domisili': domisili?.trim().isEmpty == true ? null : domisili?.trim(),
      'ketersediaan': AppStatus.tersediaAktif,
      'tanggal_donor_terakhir': tanggalDonorTerakhir?.toIso8601String().split('T').first,
    });

    // 5. Catat Persetujuan Eksplisit UU No. 27 Tahun 2022
    await supabase.from('persetujuan').insert({
      'id_pengguna': uid,
      'versi_pemberitahuan': 'v1.0-UUPDP',
      'status': 'Diberikan',
    });

    // 6. Upload Bukti KTP ke Supabase Storage (Lintas Web & Mobile via Bytes)
    final ktpPath = 'ktp/${uid}_${DateTime.now().millisecondsSinceEpoch}_$ktpFileName';
    await supabase.storage.from('dokumen-bukti').uploadBinary(ktpPath, ktpBytes);
    await supabase.from('dokumen_bukti').insert({'jenis': 'KTP', 'id_pengguna': uid, 'lokasi_berkas': ktpPath});

    // 7. Upload Bukti Kartu Donor (jika dilampirkan)
    if (kartuDonorBytes != null && kartuDonorFileName != null) {
      final goldarPath = 'goldar/${uid}_${DateTime.now().millisecondsSinceEpoch}_$kartuDonorFileName';
      await supabase.storage.from('dokumen-bukti').uploadBinary(goldarPath, kartuDonorBytes);
      await supabase.from('dokumen_bukti').insert({
        'jenis': 'Bukti golongan darah',
        'id_pengguna': uid,
        'lokasi_berkas': goldarPath,
      });
    }

    // 8. Beri notifikasi Inbox ke semua Admin bahwa ada pendaftar baru
    final admins = await supabase.from('pengguna').select('id_pengguna').eq('peran', AppStatus.roleAdmin);

    for (final admin in admins) {
      await supabase.from('notifikasi_inbox').insert({
        'id_penerima': admin['id_pengguna'],
        'judul': 'Pendaftar Mahasiswa Baru',
        'pesan': '$namaLengkap ($npm) mendaftar dengan golongan darah $golonganDarah $rhesus dan menunggu verifikasi.',
        'tipe': 'verifikasi',
        'referensi_id': uid,
      });
    }

    await fetchCurrentUserProfile(uid);
  }

  /// Admin membuat akun Admin baru atau akun Penyelenggara Kegiatan (FR-F9-04)
  static Future<void> buatAkunPengurusAtauPenyelenggara({
    required String namaLengkap,
    required String email,
    required String password,
    required String noWhatsapp,
    required String organisasi,
    required String peran, // Admin atau Penyelenggara
  }) async {
    // Simpan sesi admin saat ini agar tidak ter-replace
    final currentSession = supabase.auth.currentSession;

    final authRes = await supabase.auth.signUp(email: email.trim(), password: password);

    if (authRes.user == null) {
      throw Exception('Gagal membuat akun baru.');
    }

    await supabase.from('pengguna').insert({
      'id_pengguna': authRes.user!.id,
      'nama_lengkap': namaLengkap.trim(),
      'email': email.trim(),
      'no_whatsapp': noWhatsapp.trim(),
      'organisasi': organisasi.trim(),
      'peran': peran,
      'status_akun': AppStatus.akunTerverifikasi,
    });

    // Pulihkan sesi Admin utama
    if (currentSession != null) {
      await supabase.auth.setSession(currentSession.refreshToken!);
    }
  }

  /// Penarikan persetujuan / penghapusan akun oleh Mahasiswa (BR-10)
  static Future<void> tarikPersetujuanDanNonaktifkan(String idPengguna) async {
    await supabase.from('persetujuan').insert({
      'id_pengguna': idPengguna,
      'versi_pemberitahuan': 'v1.0-UUPDP',
      'status': 'Ditarik',
    });

    await supabase.from('pengguna').update({'status_akun': AppStatus.akunNonaktif}).eq('id_pengguna', idPengguna);

    await supabase
        .from('profil_pendonor')
        .update({'ketersediaan': AppStatus.tersediaNonaktif})
        .eq('id_pengguna', idPengguna);

    await logout();
  }

  static Future<void> logout() async {
    await supabase.auth.signOut();
    currentUserRM.state = null;
  }
}
