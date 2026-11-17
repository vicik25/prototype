import 'pengguna_model.dart';

class PermintaanDonorModel {
  final String idPermintaan;
  final String dibuatOleh;
  final String namaPemohon;
  final String kontakPemohon;
  final String rumahSakit;
  final String golonganDarah;
  final String rhesus;
  final int jumlahKantong;
  final DateTime batasWaktuKebutuhan;
  final int batasResponsHari;
  final String statusPemohon;
  final String status;
  final DateTime waktuDibuat;
  final DateTime? waktuNotifikasiPertama;
  final DateTime? waktuBersediaPertama;

  PermintaanDonorModel({
    required this.idPermintaan,
    required this.dibuatOleh,
    required this.namaPemohon,
    required this.kontakPemohon,
    required this.rumahSakit,
    required this.golonganDarah,
    required this.rhesus,
    required this.jumlahKantong,
    required this.batasWaktuKebutuhan,
    required this.batasResponsHari,
    required this.statusPemohon,
    required this.status,
    required this.waktuDibuat,
    this.waktuNotifikasiPertama,
    this.waktuBersediaPertama,
  });

  String get goldarLengkap => '$golonganDarah ${rhesus == 'Positif' ? '+' : '-'}';

  factory PermintaanDonorModel.fromMap(Map<String, dynamic> map) {
    return PermintaanDonorModel(
      idPermintaan: map['id_permintaan'] ?? '',
      dibuatOleh: map['dibuat_oleh'] ?? '',
      namaPemohon: map['nama_pemohon'] ?? '',
      kontakPemohon: map['kontak_pemohon'] ?? '',
      rumahSakit: map['rumah_sakit'] ?? '',
      golonganDarah: map['golongan_darah'] ?? 'O',
      rhesus: map['rhesus'] ?? 'Positif',
      jumlahKantong: map['jumlah_kantong'] ?? 1,
      batasWaktuKebutuhan: DateTime.tryParse(map['batas_waktu_kebutuhan'] ?? '') ?? DateTime.now(),
      batasResponsHari: map['batas_respons_hari'] ?? 3,
      statusPemohon: map['status_pemohon'] ?? 'Belum terverifikasi',
      status: map['status'] ?? 'Menunggu verifikasi pemohon',
      waktuDibuat: DateTime.tryParse(map['waktu_dibuat'] ?? '') ?? DateTime.now(),
      waktuNotifikasiPertama: map['waktu_notifikasi_pertama'] != null
          ? DateTime.tryParse(map['waktu_notifikasi_pertama'])
          : null,
      waktuBersediaPertama: map['waktu_bersedia_pertama'] != null
          ? DateTime.tryParse(map['waktu_bersedia_pertama'])
          : null,
    );
  }
}

class UndanganNotifikasiModel {
  final String idUndangan;
  final String idPermintaan;
  final String idPengguna;
  final int gelombang;
  final String kanal;
  final String statusKirim;
  final String tanggapan;
  final DateTime? tundaHingga;
  final bool sudahDihubungi;
  final String? catatanTindakLanjut;
  final DateTime waktuKirim;
  final DateTime batasRespons;
  final DateTime? waktuTanggapan;
  final PenggunaModel? pendonor;
  final PermintaanDonorModel? permintaan;

  UndanganNotifikasiModel({
    required this.idUndangan,
    required this.idPermintaan,
    required this.idPengguna,
    required this.gelombang,
    required this.kanal,
    required this.statusKirim,
    required this.tanggapan,
    this.tundaHingga,
    required this.sudahDihubungi,
    this.catatanTindakLanjut,
    required this.waktuKirim,
    required this.batasRespons,
    this.waktuTanggapan,
    this.pendonor,
    this.permintaan,
  });

  factory UndanganNotifikasiModel.fromMap(Map<String, dynamic> map) {
    return UndanganNotifikasiModel(
      idUndangan: map['id_undangan'] ?? '',
      idPermintaan: map['id_permintaan'] ?? '',
      idPengguna: map['id_pengguna'] ?? '',
      gelombang: map['gelombang'] ?? 1,
      kanal: map['kanal'] ?? 'WhatsApp',
      statusKirim: map['status_kirim'] ?? 'Terkirim',
      tanggapan: map['tanggapan'] ?? 'Menunggu',
      tundaHingga: map['tunda_hingga'] != null ? DateTime.tryParse(map['tunda_hingga']) : null,
      sudahDihubungi: map['sudah_dihubungi'] ?? false,
      catatanTindakLanjut: map['catatan_tindak_lanjut'],
      waktuKirim: DateTime.tryParse(map['waktu_kirim'] ?? '') ?? DateTime.now(),
      batasRespons: DateTime.tryParse(map['batas_respons'] ?? '') ?? DateTime.now(),
      waktuTanggapan: map['waktu_tanggapan'] != null ? DateTime.tryParse(map['waktu_tanggapan']) : null,
      pendonor: map['pengguna'] != null ? PenggunaModel.fromMap(map['pengguna']) : null,
      permintaan: map['permintaan_donor'] != null ? PermintaanDonorModel.fromMap(map['permintaan_donor']) : null,
    );
  }
}
