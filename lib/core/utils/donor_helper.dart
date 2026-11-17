import 'package:intl/intl.dart';

import '../constants/app_status.dart';

class DonorHelper {
  /// Menghitung tanggal boleh donor berikutnya (default jeda = 61 hari)
  static DateTime? hitungTanggalBolehDonor(DateTime? tanggalDonorTerakhir, {int jedaHari = 61}) {
    if (tanggalDonorTerakhir == null) return null;
    final tglAwal = DateTime(tanggalDonorTerakhir.year, tanggalDonorTerakhir.month, tanggalDonorTerakhir.day);
    return tglAwal.add(Duration(days: jedaHari));
  }

  /// Mengecek apakah pendonor sudah melewati jeda pada tanggal acuan (default hari ini)
  static bool isBisaDonor(DateTime? tanggalDonorTerakhir, {int jedaHari = 61, DateTime? tanggalAcuan}) {
    if (tanggalDonorTerakhir == null) return true;
    final bolehDonor = hitungTanggalBolehDonor(tanggalDonorTerakhir, jedaHari: jedaHari)!;
    final acuan = tanggalAcuan ?? DateTime.now();
    final tglAcuan = DateTime(acuan.year, acuan.month, acuan.day);
    return !tglAcuan.isBefore(bolehDonor); // Hari ke-61 sudah boleh donor
  }

  /// Menghitung sisa hari jeda (0 jika sudah boleh donor)
  static int sisaHariJeda(DateTime? tanggalDonorTerakhir, {int jedaHari = 61}) {
    if (tanggalDonorTerakhir == null) return 0;
    final bolehDonor = hitungTanggalBolehDonor(tanggalDonorTerakhir, jedaHari: jedaHari)!;
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    final selisih = bolehDonor.difference(hariIni).inDays;
    return selisih > 0 ? selisih : 0;
  }

  /// Evaluasi kelayakan mandiri sesuai Tabel 3.14 & BR-12 (1 syarat gagal = Belum memenuhi)
  static String evaluasiSkrining({
    required int usia,
    required bool pernahDonorSebelumnya,
    required double beratBadan,
    required bool sehatHariIni,
    required bool minumAntibiotik48Jam,
    required bool minumAspirin7Hari,
    required bool hamilAtauMenyusui,
    required bool operasiBaru,
    required bool tato6BulanTerakhir,
    required double durasiTidurJam,
  }) {
    final minBerat = pernahDonorSebelumnya ? 45.0 : 47.0;
    final usiaValid = usia >= 17 && usia <= 65 && (usia < 60 || pernahDonorSebelumnya);

    final lolosSemua =
        usiaValid &&
        beratBadan >= minBerat &&
        sehatHariIni &&
        !minumAntibiotik48Jam &&
        !minumAspirin7Hari &&
        !hamilAtauMenyusui &&
        !operasiBaru &&
        !tato6BulanTerakhir &&
        durasiTidurJam >= 5.0;

    return lolosSemua ? AppStatus.skriningMemenuhi : AppStatus.skriningBelumMemenuhi;
  }

  static String formatTanggal(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }
}
