import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:admindiabetes/ViewModel.dart'; // 👈 Sesuaikan lokasi PatientModel

class AddPatientPopup extends StatefulWidget {
  final PatientModel? patient; // 👈 Jika diisi, maka otomatis masuk mode EDIT

  const AddPatientPopup({super.key, this.patient});

  @override
  State<AddPatientPopup> createState() => _AddPatientPopupState();
}

class _AddPatientPopupState extends State<AddPatientPopup> {
  // Controller form
  late TextEditingController _nikController;
  late TextEditingController _nameController;
  late TextEditingController _tglLahirController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;

  String _selectedGender = '';
  int _calculatedAge = 0;
  DateTime? _selectedBirthDate;
  bool _obscurePassword = true;
  bool get isEdit =>
      widget.patient != null; // 👈 Cek apakah mode Edit atau Tambah

  @override
  void initState() {
    super.initState();

    // Inisialisasi data: Jika Edit, ambil data lama. Jika Tambah, kosongkan.
    _nikController =
        TextEditingController(text: isEdit ? widget.patient!.nik : '');
    _nameController =
        TextEditingController(text: isEdit ? widget.patient!.name : '');
    _emailController =
        TextEditingController(text: isEdit ? widget.patient!.email : '');
    _passwordController = TextEditingController();
    _phoneController =
        TextEditingController(text: isEdit ? widget.patient!.phone : '');

    // Khusus tanggal lahir, kita tampilkan info umur kalau di mode edit
    _tglLahirController = TextEditingController(
        text: isEdit ? 'Data Tersimpan (Klik untuk Ubah)' : '');

    if (isEdit) {
      _selectedGender = widget.patient!.gender;
      _calculatedAge = int.tryParse(widget.patient!.age.toString()) ?? 0;
    }
  }

  @override
  void dispose() {
    _nikController.dispose();
    _nameController.dispose();
    _tglLahirController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _tglLahirController.text =
            DateFormat('dd MMMM yyyy', 'id').format(picked);
        _selectedBirthDate = picked;
        final today = DateTime.now();
        _calculatedAge = today.year -
            picked.year -
            ((today.month < picked.month ||
                    (today.month == picked.month && today.day < picked.day))
                ? 1
                : 0);
      });
    }
  }

  Future<void> _saveToFirebase() async {
    final password = _passwordController.text.trim();

    if (_nikController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _selectedGender.isEmpty ||
        (!isEdit && _calculatedAge <= 0) ||
        (!isEdit && password.isEmpty)) {
      EasyLoading.showError('Data wajib diisi!');
      return;
    }

    try {
      EasyLoading.show(status: isEdit ? 'Memperbarui...' : 'Menyimpan...');

      final data = {
        'nik': _nikController.text.trim(),
        'name': _nameController.text.trim(),
        'gender': _selectedGender,
        'age': _calculatedAge.toString(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      if (_selectedBirthDate != null) {
        data['birthDate'] = DateFormat('yyyy-MM-dd').format(_selectedBirthDate!);
      }

      // Password dipakai app pasien untuk login fallback Firestore.
      // Mode edit: password hanya diubah kalau admin mengisi field ini.
      if (password.isNotEmpty) {
        data['password'] = password;
      }

      if (isEdit) {
        // ✏️ UPDATE: Jika mode edit, update dokumen berdasarkan ID
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patient!.id)
            .update(data);
        EasyLoading.showSuccess('Data berhasil diperbarui!');
      } else {
        // ➕ ADD: Jika mode tambah, buat dokumen baru
        data.addAll({
          'lastCheckDate': '-',
          'appointmentDate': '-',
          'appointmentCount': '0',
          'gdp': '0',
          'gd2pp': '0',
          'hba1c': '0',
          'medicineNames': '-',
          'medicineTimes': '-',
        });
        await FirebaseFirestore.instance.collection('patients').add(data);
        EasyLoading.showSuccess('Pasien berhasil ditambahkan!');
      }

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
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: maxDialogHeight,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul berubah dinamis sesuai mode
              Text(
                isEdit ? 'Edit Data Pasien' : 'Tambah Pasien Baru',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildLabel('NIK'),
              _buildInput(_nikController, 'NIK'),

              _buildLabel('Nama Lengkap'),
              _buildInput(_nameController, 'Nama Lengkap'),

              _buildLabel('Tanggal Lahir / Umur'),
              GestureDetector(
                onTap: () => _selectBirthDate(context),
                child: AbsorbPointer(
                  child: _buildInput(_tglLahirController, 'Pilih Tanggal',
                      suffixIcon: Icons.calendar_today),
                ),
              ),

              _buildLabel('Jenis Kelamin'),
              _buildGenderDropdown(),

              _buildLabel('Email'),
              _buildInput(_emailController, 'Email'),

              _buildLabel(isEdit ? 'Password Baru' : 'Password'),
              _buildInput(
                _passwordController,
                isEdit
                    ? 'Kosongkan jika tidak ingin mengubah password'
                    : 'Password pasien',
                obscureText: _obscurePassword,
                suffixIcon: _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),

              _buildLabel('Nomor Telepon'),
              _buildInput(_phoneController, 'Nomor Telepon'),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _saveToFirebase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff111827),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(
                    isEdit ? 'Simpan Perubahan' : 'Simpan & Sambungkan Data',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _buildInput(
    TextEditingController ctrl,
    String hint, {
    IconData? suffixIcon,
    bool obscureText = false,
    VoidCallback? onSuffixTap,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
          color: const Color(0xfff3f4f6),
          borderRadius: BorderRadius.circular(20)),
      child: TextField(
        controller: ctrl,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  onPressed: onSuffixTap,
                  icon: Icon(suffixIcon, size: 16),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: const Color(0xfff3f4f6),
          borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedGender.isEmpty ? null : _selectedGender,
          hint:
              const Text('Pilih Jenis Kelamin', style: TextStyle(fontSize: 13)),
          items: ['Laki - Laki', 'Perempuan']
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (v) => setState(() => _selectedGender = v!),
        ),
      ),
    );
  }
}
