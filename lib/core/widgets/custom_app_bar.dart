import 'package:material_ui/material_ui.dart';

import '../../features/beranda/beranda_page.dart';
import '../../models/notifikasi_model.dart';
import '../../models/pengguna_model.dart';
import '../../services/auth_service.dart';
import '../../services/notifikasi_service.dart';
import '../constants/app_colors.dart';
import 'inbox_drawer.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PenggunaModel user;
  final String subtitle;
  final void Function(NotifikasiInboxModel notif)? onNotifActionTap;

  const CustomAppBar({super.key, required this.user, required this.subtitle, this.onNotifActionTap});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Brand Logo
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bloodtype_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Text('SiDonor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.peran,
                            style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // Tombol Lonceng Inbox Realtime
              StreamBuilder<List<NotifikasiInboxModel>>(
                stream: NotifikasiService.streamInboxUser(user.idPengguna),
                builder: (context, snapshot) {
                  final unreadCount = (snapshot.data ?? []).where((e) => !e.dibaca).length;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        tooltip: 'Kotak Masuk Notifikasi',
                        onPressed: () =>
                            InboxPanel.show(context, userId: user.idPengguna, onActionTap: onNotifActionTap),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),

              // Tombol Keluar
              IconButton(
                tooltip: 'Keluar Akun',
                onPressed: () async {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const BerandaPage()),
                      (_) => false,
                    );
                  }
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.dangerBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
