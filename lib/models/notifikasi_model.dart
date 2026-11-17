class NotifikasiInboxModel {
  final String idNotifikasi;
  final String idPenerima;
  final String judul;
  final String pesan;
  final String tipe; // permintaan_darah, verifikasi, pengingat_jeda, kegiatan, sistem
  final String? referensiId;
  final bool dibaca;
  final DateTime waktuDibuat;

  NotifikasiInboxModel({
    required this.idNotifikasi,
    required this.idPenerima,
    required this.judul,
    required this.pesan,
    required this.tipe,
    this.referensiId,
    required this.dibaca,
    required this.waktuDibuat,
  });

  factory NotifikasiInboxModel.fromMap(Map<String, dynamic> map) {
    return NotifikasiInboxModel(
      idNotifikasi: map['id_notifikasi'] ?? '',
      idPenerima: map['id_penerima'] ?? '',
      judul: map['judul'] ?? '',
      pesan: map['pesan'] ?? '',
      tipe: map['tipe'] ?? 'sistem',
      referensiId: map['referensi_id'],
      dibaca: map['dibaca'] ?? false,
      waktuDibuat: DateTime.tryParse(map['waktu_dibuat'] ?? '') ?? DateTime.now(),
    );
  }
}
