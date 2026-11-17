import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';
import '../constants/app_status.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.neutralBg;
    Color textColor = AppColors.neutral;

    if ([
      AppStatus.akunTerverifikasi,
      AppStatus.goldarTerverifikasi,
      AppStatus.skriningMemenuhi,
      AppStatus.tersediaAktif,
      AppStatus.jedaBisaDonor,
      AppStatus.mintaPendonorBersedia,
      AppStatus.mintaTerlaksana,
      AppStatus.tanggapanBersedia,
      AppStatus.hasilBerhasil,
      AppStatus.kegiatanDisetujui,
    ].contains(status)) {
      bgColor = AppColors.successBg;
      textColor = AppColors.success;
    } else if ([
      AppStatus.akunMenunggu,
      AppStatus.akunPerluDilengkapi,
      AppStatus.goldarBelumTerverifikasi,
      AppStatus.mintaMenungguVerifikasi,
      AppStatus.mintaMencari,
      AppStatus.tanggapanMenunggu,
      AppStatus.tanggapanDitunda,
      AppStatus.kegiatanMenunggu,
      AppStatus.kegiatanRevisi,
    ].contains(status)) {
      bgColor = AppColors.warningBg;
      textColor = AppColors.warning;
    } else if ([
      AppStatus.akunDitolak,
      AppStatus.akunNonaktif,
      AppStatus.skriningBelumMemenuhi,
      AppStatus.tersediaNonaktif,
      AppStatus.jedaBelumBisa,
      AppStatus.mintaDibatalkan,
      AppStatus.tanggapanTidakBersedia,
      AppStatus.hasilTidakLolos,
      AppStatus.hasilTidakHadir,
      AppStatus.kegiatanDitolak,
      AppStatus.kegiatanDibatalkan,
    ].contains(status)) {
      bgColor = AppColors.dangerBg;
      textColor = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
    );
  }
}
