class PenggunaModel {
  final String idPengguna;
  final String namaLengkap;
  final String? npm;
  final String email;
  final String? noWhatsapp;
  final String? programStudi;
  final String? fakultas;
  final String? organisasi;
  final String peran;
  final String statusAkun;
  final String? catatanVerifikasi;
  final DateTime waktuDibuat;
  final ProfilPendonorModel? profilPendonor;
  final SkriningModel? skriningTerbaru;

  PenggunaModel({
    required this.idPengguna,
    required this.namaLengkap,
    this.npm,
    required this.email,
    this.noWhatsapp,
    this.programStudi,
    this.fakultas,
    this.organisasi,
    required this.peran,
    required this.statusAkun,
    this.catatanVerifikasi,
    required this.waktuDibuat,
    this.profilPendonor,
    this.skriningTerbaru,
  });

  factory PenggunaModel.fromMap(Map<String, dynamic> map) {
    ProfilPendonorModel? profil;
    if (map['profil_pendonor'] != null) {
      if (map['profil_pendonor'] is List && (map['profil_pendonor'] as List).isNotEmpty) {
        profil = ProfilPendonorModel.fromMap(map['profil_pendonor'][0]);
      } else if (map['profil_pendonor'] is Map<String, dynamic>) {
        profil = ProfilPendonorModel.fromMap(map['profil_pendonor']);
      }
    }

    SkriningModel? skrining;
    if (map['skrining'] != null && map['skrining'] is List && (map['skrining'] as List).isNotEmpty) {
      final list = (map['skrining'] as List).map((e) => SkriningModel.fromMap(e)).toList()
        ..sort((a, b) => b.waktuIsi.compareTo(a.waktuIsi));
      skrining = list.first;
    }

    return PenggunaModel(
      idPengguna: map['id_pengguna'] ?? '',
      namaLengkap: map['nama_lengkap'] ?? '',
      npm: map['npm'],
      email: map['email'] ?? '',
      noWhatsapp: map['no_whatsapp'],
      programStudi: map['program_studi'],
      fakultas: map['fakultas'],
      organisasi: map['organisasi'],
      peran: map['peran'] ?? 'Mahasiswa',
      statusAkun: map['status_akun'] ?? 'Menunggu verifikasi',
      catatanVerifikasi: map['catatan_verifikasi'],
      waktuDibuat: DateTime.tryParse(map['waktu_dibuat'] ?? '') ?? DateTime.now(),
      profilPendonor: profil,
      skriningTerbaru: skrining,
    );
  }
}

class ProfilPendonorModel {
  final String idProfil;
  final String idPengguna;
  final String golonganDarah;
  final String rhesus;
  final String statusGolonganDarah;
  final String? domisili;
  final String ketersediaan;
  final DateTime? tanggalDonorTerakhir;

  ProfilPendonorModel({
    required this.idProfil,
    required this.idPengguna,
    required this.golonganDarah,
    required this.rhesus,
    required this.statusGolonganDarah,
    this.domisili,
    required this.ketersediaan,
    this.tanggalDonorTerakhir,
  });

  String get goldarLengkap => '$golonganDarah ${rhesus == 'Positif' ? '+' : '-'}';

  factory ProfilPendonorModel.fromMap(Map<String, dynamic> map) {
    return ProfilPendonorModel(
      idProfil: map['id_profil'] ?? '',
      idPengguna: map['id_pengguna'] ?? '',
      golonganDarah: map['golongan_darah'] ?? 'O',
      rhesus: map['rhesus'] ?? 'Positif',
      statusGolonganDarah: map['status_golongan_darah'] ?? 'Belum terverifikasi',
      domisili: map['domisili'],
      ketersediaan: map['ketersediaan'] ?? 'Aktif',
      tanggalDonorTerakhir: map['tanggal_donor_terakhir'] != null
          ? DateTime.tryParse(map['tanggal_donor_terakhir'])
          : null,
    );
  }
}

class SkriningModel {
  final String idSkrining;
  final String idPengguna;
  final String? idPermintaan;
  final String hasil;
  final String versiAturan;
  final DateTime waktuIsi;

  SkriningModel({
    required this.idSkrining,
    required this.idPengguna,
    this.idPermintaan,
    required this.hasil,
    required this.versiAturan,
    required this.waktuIsi,
  });

  factory SkriningModel.fromMap(Map<String, dynamic> map) {
    return SkriningModel(
      idSkrining: map['id_skrining'] ?? '',
      idPengguna: map['id_pengguna'] ?? '',
      idPermintaan: map['id_permintaan'],
      hasil: map['hasil'] ?? 'Belum memenuhi syarat awal',
      versiAturan: map['versi_aturan'] ?? 'v1.0',
      waktuIsi: DateTime.tryParse(map['waktu_isi'] ?? '') ?? DateTime.now(),
    );
  }
}

class DokumenBuktiModel {
  final String idDokumen;
  final String jenis;
  final String? idPengguna;
  final String? idPermintaan;
  final String lokasiBerkas;
  final DateTime waktuUnggah;
  final DateTime? waktuHapus;

  DokumenBuktiModel({
    required this.idDokumen,
    required this.jenis,
    this.idPengguna,
    this.idPermintaan,
    required this.lokasiBerkas,
    required this.waktuUnggah,
    this.waktuHapus,
  });

  factory DokumenBuktiModel.fromMap(Map<String, dynamic> map) {
    return DokumenBuktiModel(
      idDokumen: map['id_dokumen'] ?? '',
      jenis: map['jenis'] ?? '',
      idPengguna: map['id_pengguna'],
      idPermintaan: map['id_permintaan'],
      lokasiBerkas: map['lokasi_berkas'] ?? '',
      waktuUnggah: DateTime.tryParse(map['waktu_unggah'] ?? '') ?? DateTime.now(),
      waktuHapus: map['waktu_hapus'] != null ? DateTime.tryParse(map['waktu_hapus']) : null,
    );
  }
}
