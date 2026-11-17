import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_status.dart';
import '../../models/pengguna_model.dart';
import '../../services/auth_service.dart';
import '../admin/admin_dashboard.dart';
import '../mahasiswa/mahasiswa_dashboard.dart';
import '../penyelenggara/penyelenggara_dashboard.dart';
import 'register_mahasiswa_page.dart';

class LoginPage extends StatefulWidget {
  final String expectedRole;

  const LoginPage({super.key, required this.expectedRole});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await AuthService.loginDenganPeran(
        email: _emailController.text,
        password: _passwordController.text,
        expectedRole: widget.expectedRole,
      );

      if (!mounted) return;
      _navigasiKeDashboard(user);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigasiKeDashboard(PenggunaModel user) {
    Widget destination;
    if (user.peran == AppStatus.roleAdmin) {
      destination = const AdminDashboard();
    } else if (user.peran == AppStatus.rolePenyelenggara) {
      destination = const PenyelenggaraDashboard();
    } else {
      destination = const MahasiswaDashboard();
    }

    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => destination), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isMahasiswa = widget.expectedRole == AppStatus.roleMahasiswa;

    return Scaffold(
      appBar: AppBar(title: Text('Masuk Portal ${widget.expectedRole}')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.lock_person_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Login ${widget.expectedRole}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isMahasiswa
                            ? 'Masuk menggunakan email dan kata sandi akun mahasiswa SiDonor.'
                            : 'Gunakan akun resmi ${widget.expectedRole} yang telah didaftarkan oleh Admin UKM KSR.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'nama@student.unsil.ac.id',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
                          if (!val.contains('@')) return 'Format email tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Kata sandi wajib diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text('Masuk ke Dashboard ${widget.expectedRole}'),
                        ),
                      ),

                      if (isMahasiswa) ...[
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 12),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              const Text('Belum terdaftar sebagai pendonor?', style: TextStyle(fontSize: 13.5)),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterMahasiswaPage()),
                                  );
                                },
                                child: const Text('Daftar Sekarang', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.neutralBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: AppColors.neutral),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pendaftaran mandiri tidak tersedia untuk peran ini. Hubungi pengurus UKM KSR untuk pembuatan akun.',
                                  style: TextStyle(fontSize: 12, color: AppColors.neutral),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
