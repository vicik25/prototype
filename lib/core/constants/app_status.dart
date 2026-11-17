class AppStatus {
  // Peran Pengguna
  static const String roleMahasiswa = 'Mahasiswa';
  static const String roleAdmin = 'Admin';
  static const String rolePenyelenggara = 'Penyelenggara';

  // Status Akun
  static const String akunMenunggu = 'Menunggu verifikasi';
  static const String akunPerluDilengkapi = 'Perlu dilengkapi';
  static const String akunTerverifikasi = 'Terverifikasi';
  static const String akunDitolak = 'Ditolak';
  static const String akunNonaktif = 'Nonaktif';

  // Status Golongan Darah
  static const String goldarBelumTerverifikasi = 'Belum terverifikasi';
  static const String goldarTerverifikasi = 'Terverifikasi';

  // Hasil Skrining Mandiri
  static const String skriningMemenuhi = 'Memenuhi syarat awal';
  static const String skriningBelumMemenuhi = 'Belum memenuhi syarat awal';

  // Ketersediaan Pendonor
  static const String tersediaAktif = 'Aktif';
  static const String tersediaNonaktif = 'Nonaktif';

  // Status Jeda Donor
  static const String jedaBelumBisa = 'Belum bisa donor';
  static const String jedaBisaDonor = 'Bisa donor';

  // Status Permintaan Donor
  static const String mintaMenungguVerifikasi = 'Menunggu verifikasi pemohon';
  static const String mintaMencari = 'Mencari pendonor';
  static const String mintaPendonorBersedia = 'Pendonor bersedia';
  static const String mintaTerlaksana = 'Donor terlaksana';
  static const String mintaDitutup = 'Ditutup';
  static const String mintaDibatalkan = 'Dibatalkan';

  // Tanggapan Pendonor
  static const String tanggapanMenunggu = 'Menunggu';
  static const String tanggapanBersedia = 'Bersedia';
  static const String tanggapanTidakBersedia = 'Tidak bersedia';
  static const String tanggapanDitunda = 'Ditunda';
  static const String tanggapanTidakMerespons = 'Tidak merespons';

  // Hasil Donor
  static const String hasilBerhasil = 'Berhasil donor';
  static const String hasilTidakLolos = 'Tidak lolos pemeriksaan petugas';
  static const String hasilTidakHadir = 'Tidak hadir';

  // Status Kegiatan
  static const String kegiatanMenunggu = 'Menunggu verifikasi';
  static const String kegiatanDisetujui = 'Disetujui';
  static const String kegiatanRevisi = 'Perlu revisi';
  static const String kegiatanDitolak = 'Ditolak';
  static const String kegiatanDibatalkan = 'Dibatalkan';
  static const String kegiatanSelesai = 'Selesai';
}
