import 'package:admindiabetes/View/Dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const Color _primary = Color(0xFF2D4DA7);
  static const Color _softBlue = Color(0xFFEAF0FF);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    if (_isRegisterMode) {
      await _registerAdmin();
    } else {
      await _loginAdmin();
    }
  }

  Future<void> _loginAdmin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email dan password wajib diisi.');
      return;
    }

    try {
      setState(() => _isLoading = true);

      final staffSnapshot = await FirebaseFirestore.instance
          .collection('staff_accounts')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (!mounted) return;

      if (staffSnapshot.docs.isEmpty) {
        setState(() => _isLoading = false);
        _showMessage('Email atau password admin salah.');
        return;
      }

      final staffData = staffSnapshot.docs.first.data();
      final role = staffData['role']?.toString().toLowerCase();
      final savedPassword = staffData['password']?.toString();
      final isActive = staffData['isActive'] != false;

      if (role != 'admin' || savedPassword != password || !isActive) {
        setState(() => _isLoading = false);
        _showMessage('Email atau password admin salah.');
        return;
      }

      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainDashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Gagal login admin: $e');
    }
  }

  Future<void> _registerAdmin() async {
    final name = _nameController.text.trim();
    final nik = _nikController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (name.isEmpty || nik.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Nama, NIK, email, dan password wajib diisi.');
      return;
    }

    try {
      setState(() => _isLoading = true);

      final existingNik = await FirebaseFirestore.instance
          .collection('staff_accounts')
          .where('nik', isEqualTo: nik)
          .limit(1)
          .get();

      if (existingNik.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showMessage('NIK sudah terdaftar sebagai akun staff.');
        return;
      }

      final existingEmail = await FirebaseFirestore.instance
          .collection('staff_accounts')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingEmail.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showMessage('Email sudah terdaftar sebagai akun staff.');
        return;
      }

      await FirebaseFirestore.instance.collection('staff_accounts').add({
        'role': 'admin',
        'name': name,
        'nik': nik,
        'email': email,
        'password': password,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'self_signup',
      });

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRegisterMode = false;
      });
      _nameController.clear();
      _nikController.clear();
      _passwordController.clear();
      _showMessage('Akun admin berhasil dibuat. Silakan masuk.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Gagal daftar admin: $e');
    }
  }

  void _toggleMode() {
    if (_isLoading) return;
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _obscurePassword = true;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showHelpMessage() {
    _showMessage('Hubungi admin sistem untuk reset password atau aktivasi akun.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBlue,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1F000000),
                                  blurRadius: 32,
                                  offset: Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                if (constraints.maxWidth >= 820)
                                  Expanded(
                                    child: _HeroPanel(
                                      primary: _primary,
                                      title: _isRegisterMode
                                          ? 'Daftar Admin'
                                          : 'Admin Dashboard',
                                      subtitle: _isRegisterMode
                                          ? 'Buat akun admin sendiri untuk mengelola layanan PharmaDiaCare.'
                                          : 'Kelola pasien, edukasi, jadwal obat, dan hasil lab dari satu tempat.',
                                    ),
                                  ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          constraints.maxWidth < 520 ? 24 : 42,
                                      vertical: 38,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _BrandHeader(),
                                        const SizedBox(height: 30),
                                        _ModeSwitcher(
                                          isRegisterMode: _isRegisterMode,
                                          onChanged: _toggleMode,
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          _isRegisterMode
                                              ? 'Daftar Admin'
                                              : 'Masuk Admin',
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _isRegisterMode
                                              ? 'Isi data admin. Role otomatis admin dan tersimpan ke staff_accounts.'
                                              : 'Gunakan akun admin PharmaDiaCare untuk melanjutkan.',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        if (_isRegisterMode) ...[
                                          const _FieldLabel('Nama'),
                                          const SizedBox(height: 8),
                                          _InputField(
                                            controller: _nameController,
                                            hint: 'Nama lengkap admin',
                                            icon: Icons.person_outline_rounded,
                                            textInputAction:
                                                TextInputAction.next,
                                          ),
                                          const SizedBox(height: 18),
                                          const _FieldLabel('NIK'),
                                          const SizedBox(height: 8),
                                          _InputField(
                                            controller: _nikController,
                                            hint: 'NIK admin',
                                            icon: Icons.badge_outlined,
                                            keyboardType: TextInputType.number,
                                            textInputAction:
                                                TextInputAction.next,
                                          ),
                                          const SizedBox(height: 18),
                                        ],
                                        const _FieldLabel('Email'),
                                        const SizedBox(height: 8),
                                        _InputField(
                                          controller: _emailController,
                                          hint: 'admin@email.com',
                                          icon: Icons.mail_outline_rounded,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                        ),
                                        const SizedBox(height: 18),
                                        const _FieldLabel('Password'),
                                        const SizedBox(height: 8),
                                        _InputField(
                                          controller: _passwordController,
                                          hint: 'Password',
                                          icon: Icons.lock_outline_rounded,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          onSubmitted: (_) => _submit(),
                                          suffix: IconButton(
                                            onPressed: () => setState(() =>
                                                _obscurePassword =
                                                    !_obscurePassword),
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        if (!_isRegisterMode)
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) => setState(
                                                    () => _rememberMe =
                                                        value ?? false),
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              const Text('Ingat saya',
                                                  style:
                                                      TextStyle(fontSize: 13)),
                                              const Spacer(),
                                              TextButton(
                                                  onPressed: _showHelpMessage,
                                                  child: const Text('Bantuan')),
                                            ],
                                          ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: ElevatedButton(
                                            onPressed: _submit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _primary,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16)),
                                            ),
                                            child: Text(
                                              _isRegisterMode
                                                  ? 'Daftar Admin'
                                                  : 'Masuk Sekarang',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Center(
                                          child: TextButton(
                                            onPressed: _toggleMode,
                                            child: Text(
                                              _isRegisterMode
                                                  ? 'Sudah punya akun admin? Masuk'
                                                  : 'Belum punya akun admin? Daftar',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Center(
                                          child: Text(
                                            'PharmaDiaCare Admin © 2025',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF9CA3AF)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const _LoadingOverlay(),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.isRegisterMode, required this.onChanged});

  final bool isRegisterMode;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ModeTab(
              label: 'Masuk',
              selected: !isRegisterMode,
              onTap: isRegisterMode ? onChanged : null),
          _ModeTab(
              label: 'Daftar',
              selected: isRegisterMode,
              onTap: isRegisterMode ? null : onChanged),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected ? _AdminLoginScreenState._primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF4B5563),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel(
      {required this.primary, required this.title, required this.subtitle});

  final Color primary;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 620,
      padding: const EdgeInsets.all(42),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.health_and_safety_rounded,
              color: Colors.white, size: 42),
          const Spacer(),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Text(subtitle,
              style: const TextStyle(
                  color: Color(0xDFFFFFFF), fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.medical_services_rounded,
            color: _AdminLoginScreenState._primary, size: 26),
        SizedBox(width: 10),
        Text('PharmaDiaCare',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13));
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0x99000000),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 18),
              Text('Harap Menunggu',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
