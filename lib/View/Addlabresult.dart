import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:admindiabetes/ViewModel.dart'; // 👈 Sesuaikan lokasi import PatientModel kamu

// ==========================================
// POPUP DIALOG: INPUT HASIL LAB (REVISI FULL)
// ==========================================
class InputLabResultPopup extends StatefulWidget {
  final PatientModel patient; // 👈 Menangkap data lembaran pasien dari tabel

  const InputLabResultPopup({super.key, required this.patient});

  @override
  State<InputLabResultPopup> createState() => _InputLabResultPopupState();
}

class _InputLabResultPopupState extends State<InputLabResultPopup> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _hba1cController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Jika data lab sebelumnya sudah ada, pecah datanya untuk ditampilkan kembali saat edit
    if (widget.patient.hba1c != '0' && widget.patient.lastCheckDate != '-') {
      _hba1cController.text = widget.patient.hba1c;

      // Mengurai kembali string "2026-06-11 13:00" menjadi tanggal dan jam terpisah
      try {
        List<String> dateTimeSplit = widget.patient.lastCheckDate.split(' ');
        if (dateTimeSplit.length >= 2) {
          _dateController.text = dateTimeSplit[0];
          _timeController.text = dateTimeSplit[1];
        }
      } catch (e) {
        // Fallback jika format tidak sengaja berbeda
        _dateController.text = widget.patient.lastCheckDate;
      }
    } else {
      // Jika data baru kosong, isi default dengan tanggal dan jam hari ini
      _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _timeController.text = DateFormat('HH:mm').format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _hba1cController.dispose();
    super.dispose();
  }

  // Fungsi memunculkan tanggal picker bawaan
  Future<void> _selectDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Fungsi memunculkan jam picker bawaan
  Future<void> _selectTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  // 🔥 FUNGSI UTAMA: UPDATE DATA LAB KE FIRESTORE
  Future<void> _saveLabResultToFirebase() async {
    String dateText = _dateController.text.trim();
    String timeText = _timeController.text.trim();
    String hba1cText = _hba1cController.text.trim();

    if (dateText.isEmpty || timeText.isEmpty || hba1cText.isEmpty) {
      EasyLoading.showError('Semua field wajib diisi!');
      return;
    }

    try {
      EasyLoading.show(status: 'Menyimpan hasil lab...');

      // Gabungkan menjadi format "yyyy-MM-dd HH:mm" agar sesuai tampilan kolom 2 tabelmu
      String combinedDateTime = '$dateText $timeText';

      // Jalankan perintah update ke Firestore
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patient.id)
          .update({
        'hba1c': hba1cText,
        'lastCheckDate': combinedDateTime,
      });

      EasyLoading.showSuccess('Data hasil lab berhasil disimpan!');

      if (mounted) {
        Navigator.pop(context); // Tutup pop-up dialog
      }
    } catch (e) {
      EasyLoading.showError('Gagal menyimpan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER: Judul & Tombol Close (X)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.patient.hba1c == '0' ? 'Input Hasil Lab' : 'Ubah Hasil Lab',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff111827),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 22, color: Color(0xff6b7280)),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Pasien: ${widget.patient.name}',
              style: const TextStyle(fontSize: 13, color: Color(0xff6b7280)),
            ),
            const Divider(height: 24, color: Color(0xffe5e7eb)),

            // INPUT 1: Tanggal Input
            _buildLabel('Tanggal Input'),
            GestureDetector(
              onTap: () => _selectDatePicker(context),
              child: AbsorbPointer(
                child: _buildInputBox(
                  controller: _dateController,
                  hint: 'Tanggal Input',
                  suffixIcon: Icons.calendar_today_rounded,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // INPUT 2: Waktu Pengecekan
            _buildLabel('Waktu Pengecekan'),
            GestureDetector(
              onTap: () => _selectTimePicker(context),
              child: AbsorbPointer(
                child: _buildInputBox(
                  controller: _timeController,
                  hint: 'Waktu Pengecekan',
                  suffixIcon: Icons.access_time_rounded,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // INPUT 3: Hasil HbA1c
            _buildLabel('Hasil HbA1c'),
            _buildInputBox(
              controller: _hba1cController,
              hint: '%',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 100),

            // TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveLabResultToFirebase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff111827),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xff374151),
        ),
      ),
    );
  }

  Widget _buildInputBox({
    required TextEditingController controller,
    required String hint,
    IconData? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xfff3f4f6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xff1f2937)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xff9ca3af), fontSize: 14),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, size: 20, color: const Color(0xff9ca3af))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}