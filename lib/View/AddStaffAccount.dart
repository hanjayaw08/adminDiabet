import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class AddStaffAccountPopup extends StatefulWidget {
  const AddStaffAccountPopup({super.key});

  @override
  State<AddStaffAccountPopup> createState() => _AddStaffAccountPopupState();
}

class _AddStaffAccountPopupState extends State<AddStaffAccountPopup> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const String _fixedRole = 'apoteker';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    final name = _nameController.text.trim();
    final nik = _nikController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || nik.isEmpty || email.isEmpty || password.isEmpty) {
      EasyLoading.showError('Semua data akun apoteker wajib diisi!');
      return;
    }

    try {
      EasyLoading.show(status: 'Menyimpan akun apoteker...');

      final existingNik = await FirebaseFirestore.instance
          .collection('staff_accounts')
          .where('nik', isEqualTo: nik)
          .limit(1)
          .get();

      if (existingNik.docs.isNotEmpty) {
        EasyLoading.showError('NIK sudah terdaftar sebagai akun staff!');
        return;
      }

      final existingEmail = await FirebaseFirestore.instance
          .collection('staff_accounts')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingEmail.docs.isNotEmpty) {
        EasyLoading.showError('Email sudah terdaftar sebagai akun staff!');
        return;
      }

      await FirebaseFirestore.instance.collection('staff_accounts').add({
        'role': _fixedRole,
        'name': name,
        'nik': nik,
        'email': email,
        'password': password,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
      });

      EasyLoading.showSuccess('Akun apoteker berhasil dibuat!');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      EasyLoading.showError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxDialogHeight = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 460, maxHeight: maxDialogHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xff3b59b6).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      color: Color(0xff3b59b6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tambah Akun Apoteker',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff111827),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Role otomatis apoteker',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xff6b7280)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _RoleInfo(),
              const SizedBox(height: 14),
              _buildLabel('Nama'),
              _buildInput(_nameController, 'Nama lengkap apoteker'),
              _buildLabel('NIK'),
              _buildInput(
                _nikController,
                'NIK apoteker',
                keyboardType: TextInputType.number,
              ),
              _buildLabel('Email'),
              _buildInput(
                _emailController,
                'email@contoh.com',
                keyboardType: TextInputType.emailAddress,
              ),
              _buildLabel('Password'),
              _buildInput(
                _passwordController,
                'Password akun',
                obscureText: _obscurePassword,
                suffixIcon: _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff3b59b6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text(
                    'Simpan Akun Apoteker',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Data akan masuk ke collection staff_accounts dengan role apoteker, bukan patients.',
                style: TextStyle(fontSize: 12, color: Color(0xff6b7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    bool obscureText = false,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
  }) {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xfff3f4f6),
        borderRadius: BorderRadius.circular(21),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  onPressed: onSuffixTap,
                  icon: Icon(suffixIcon, size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        ),
      ),
    );
  }
}

class _RoleInfo extends StatelessWidget {
  const _RoleInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffeef2ff),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, size: 18, color: Color(0xff3b59b6)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Role: Apoteker',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xff3b59b6)),
            ),
          ),
        ],
      ),
    );
  }
}
