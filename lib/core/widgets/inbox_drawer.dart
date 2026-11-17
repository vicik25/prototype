import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../models/notifikasi_model.dart';
import '../../services/notifikasi_service.dart';
import '../constants/app_colors.dart';
import '../utils/responsive.dart';

class InboxPanel extends StatelessWidget {
  final String userId;
  final void Function(NotifikasiInboxModel notif)? onActionTap;

  const InboxPanel({super.key, required this.userId, this.onActionTap});

  static void show(
    BuildContext context, {
    required String userId,
    void Function(NotifikasiInboxModel notif)? onActionTap,
  }) {
    if (Responsive.isMobile(context)) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: InboxPanel(userId: userId, onActionTap: onActionTap),
        ),
      );
    } else {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Tutup Inbox',
        barrierColor: Colors.black45,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, _, _) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: AppColors.surface,
              elevation: 16,
              child: SizedBox(
                width: 420,
                height: double.infinity,
                child: InboxPanel(userId: userId, onActionTap: onActionTap),
              ),
            ),
          );
        },
        transitionBuilder: (ctx, anim, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      );
    }
  }

  IconData _iconByTipe(String tipe) {
    switch (tipe) {
      case 'permintaan_darah':
        return Icons.bloodtype_rounded;
      case 'verifikasi':
        return Icons.verified_user_rounded;
      case 'pengingat_jeda':
        return Icons.event_available_rounded;
      case 'kegiatan':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorByTipe(String tipe) {
    switch (tipe) {
      case 'permintaan_darah':
        return AppColors.primary;
      case 'verifikasi':
        return AppColors.success;
      case 'pengingat_jeda':
        return Colors.blue;
      case 'kegiatan':
        return AppColors.warning;
      default:
        return AppColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Inbox
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.inbox_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kotak Masuk Notifikasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(
                      'Pembaruan realtime & cadangan WhatsApp',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => NotifikasiService.tandaiSemuaDibaca(userId),
                child: const Text('Tandai dibaca', style: TextStyle(fontSize: 12)),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ],
          ),
        ),

        // Daftar Notifikasi Realtime
        Expanded(
          child: StreamBuilder<List<NotifikasiInboxModel>>(
            stream: NotifikasiService.streamInboxUser(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada notifikasi masuk',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = list[index];
                  final iconColor = _colorByTipe(item.tipe);

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      if (!item.dibaca) {
                        await NotifikasiService.tandaiDibaca(item.idNotifikasi);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        onActionTap?.call(item);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: item.dibaca ? AppColors.surface : AppColors.primaryLight.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: item.dibaca ? AppColors.border : AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_iconByTipe(item.tipe), color: iconColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.judul,
                                        style: TextStyle(
                                          fontWeight: item.dibaca ? FontWeight.w600 : FontWeight.w700,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                    if (!item.dibaca)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.pesan,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(item.waktuDibuat.toLocal()),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    if (item.tipe == 'permintaan_darah')
                                      const Text(
                                        'Tanggapi →',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
