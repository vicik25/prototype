class KegiatanModel {
  final String idKegiatan;
  final String nama;
  final DateTime tanggal;
  final String lokasi;
  final int kuota;
  final String kontak;
  final String idPengaju;
  final String status;
  final String? catatanVerifikasi;
  final int jumlahPendaftar;

  KegiatanModel({
    required this.idKegiatan,
    required this.nama,
    required this.tanggal,
    required this.lokasi,
    required this.kuota,
    required this.kontak,
    required this.idPengaju,
    required this.status,
    this.catatanVerifikasi,
    this.jumlahPendaftar = 0,
  });

  int get sisaKuota => (kuota - jumlahPendaftar) > 0 ? (kuota - jumlahPendaftar) : 0;

  factory KegiatanModel.fromMap(Map<String, dynamic> map) {
    int count = 0;
    if (map['pendaftaran_kegiatan'] != null && map['pendaftaran_kegiatan'] is List) {
      count = (map['pendaftaran_kegiatan'] as List).where((e) => e['status_pendaftaran'] == 'Terdaftar').length;
    }

    return KegiatanModel(
      idKegiatan: map['id_kegiatan'] ?? '',
      nama: map['nama'] ?? '',
      tanggal: DateTime.tryParse(map['tanggal'] ?? '') ?? DateTime.now(),
      lokasi: map['lokasi'] ?? '',
      kuota: map['kuota'] ?? 0,
      kontak: map['kontak'] ?? '',
      idPengaju: map['id_pengaju'] ?? '',
      status: map['status'] ?? 'Menunggu verifikasi',
      catatanVerifikasi: map['catatan_verifikasi'],
      jumlahPendaftar: count,
    );
  }
}

class PendaftaranKegiatanModel {
  final String idPendaftaran;
  final String idKegiatan;
  final String idPengguna;
  final String statusPendaftaran;
  final String hasil;
  final DateTime waktuDaftar;
  final String? namaMahasiswa;
  final String? npmMahasiswa;
  final String? goldarMahasiswa;

  PendaftaranKegiatanModel({
    required this.idPendaftaran,
    required this.idKegiatan,
    required this.idPengguna,
    required this.statusPendaftaran,
    required this.hasil,
    required this.waktuDaftar,
    this.namaMahasiswa,
    this.npmMahasiswa,
    this.goldarMahasiswa,
  });

  factory PendaftaranKegiatanModel.fromMap(Map<String, dynamic> map) {
    String? nama;
    String? npm;
    String? goldar;
    if (map['pengguna'] != null) {
      nama = map['pengguna']['nama_lengkap'];
      npm = map['pengguna']['npm'];
      final profil = map['pengguna']['profil_pendonor'];
      if (profil != null) {
        final p = profil is List && profil.isNotEmpty ? profil[0] : profil;
        if (p is Map) {
          goldar = '${p['golongan_darah']} ${p['rhesus'] == 'Positif' ? '+' : '-'}';
        }
      }
    }

    return PendaftaranKegiatanModel(
      idPendaftaran: map['id_pendaftaran'] ?? '',
      idKegiatan: map['id_kegiatan'] ?? '',
      idPengguna: map['id_pengguna'] ?? '',
      statusPendaftaran: map['status_pendaftaran'] ?? 'Terdaftar',
      hasil: map['hasil'] ?? 'Belum dicatat',
      waktuDaftar: DateTime.tryParse(map['waktu_daftar'] ?? '') ?? DateTime.now(),
      namaMahasiswa: nama,
      npmMahasiswa: npm,
      goldarMahasiswa: goldar,
    );
  }
}

class RiwayatDonorModel {
  final String idRiwayat;
  final String idPengguna;
  final String sumber;
  final String? idPermintaan;
  final String? idKegiatan;
  final DateTime tanggal;
  final String jenisDonor;
  final String status;

  RiwayatDonorModel({
    required this.idRiwayat,
    required this.idPengguna,
    required this.sumber,
    this.idPermintaan,
    this.idKegiatan,
    required this.tanggal,
    required this.jenisDonor,
    required this.status,
  });

  factory RiwayatDonorModel.fromMap(Map<String, dynamic> map) {
    return RiwayatDonorModel(
      idRiwayat: map['id_riwayat'] ?? '',
      idPengguna: map['id_pengguna'] ?? '',
      sumber: map['sumber'] ?? 'Kegiatan',
      idPermintaan: map['id_permintaan'],
      idKegiatan: map['id_kegiatan'],
      tanggal: DateTime.tryParse(map['tanggal'] ?? '') ?? DateTime.now(),
      jenisDonor: map['jenis_donor'] ?? 'Darah lengkap',
      status: map['status'] ?? 'Berhasil donor',
    );
  }
}

class LogAktivitasModel {
  final String idLog;
  final String idPengguna;
  final String aksi;
  final String objek;
  final String? rincian;
  final DateTime waktu;
  final String? namaPelaku;

  LogAktivitasModel({
    required this.idLog,
    required this.idPengguna,
    required this.aksi,
    required this.objek,
    this.rincian,
    required this.waktu,
    this.namaPelaku,
  });

  factory LogAktivitasModel.fromMap(Map<String, dynamic> map) {
    return LogAktivitasModel(
      idLog: map['id_log'] ?? '',
      idPengguna: map['id_pengguna'] ?? '',
      aksi: map['aksi'] ?? '',
      objek: map['objek'] ?? '',
      rincian: map['rincian'],
      waktu: DateTime.tryParse(map['waktu'] ?? '') ?? DateTime.now(),
      namaPelaku: map['pengguna']?['nama_lengkap'],
    );
  }
}
