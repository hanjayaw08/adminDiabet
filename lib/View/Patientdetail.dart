import 'package:flutter/material.dart';
import 'package:admindiabetes/ViewModel.dart'; // 👈 Pastikan import lokasi PatientModel kamu benar

// ==========================================
// POPUP DIALOG: DETAIL PASIEN (KONEK FIREBASE)
// ==========================================
class PatientDetailPopup extends StatefulWidget {
  final PatientModel patient; // 👈 Menerima kiriman objek data pasien dari baris tabel

  const PatientDetailPopup({super.key, required this.patient});

  @override
  State<PatientDetailPopup> createState() => _PatientDetailPopupState();
}

class _PatientDetailPopupState extends State<PatientDetailPopup> {
  // Late initialization controller agar bisa mengambil data dari widget.patient
  late final TextEditingController _nikController;
  late final TextEditingController _namaController;
  late final TextEditingController _tglLahirController;
  late final TextEditingController _genderController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _glukosaPPController;
  late final TextEditingController _glukosaPuasaController;
  late final TextEditingController _hba1cController;

  bool _isDiabetes = false;

  @override
  void initState() {
    super.initState();
    // Isi controller langsung dari data dokumen Firebase pasien
    _nikController = TextEditingController(text: widget.patient.nik);
    _namaController = TextEditingController(text: widget.patient.name);

    // Tampilkan umur sekalian di samping informasi pelengkap jika dibutuhkan,
    // atau biarkan tanggal check-nya di sini
    _tglLahirController = TextEditingController(text: '${widget.patient.age} Tahun');
    _genderController = TextEditingController(text: widget.patient.gender);
    _emailController = TextEditingController(text: widget.patient.email);
    _phoneController = TextEditingController(text: widget.patient.phone);

    // Mengambil data string medis hasil input form tambah pasien kemarin
    _glukosaPPController = TextEditingController(text: '${widget.patient.gd2pp} mg/dl');
    _glukosaPuasaController = TextEditingController(text: '${widget.patient.gdp} mg/dl');
    _hba1cController = TextEditingController(text: '${widget.patient.hba1c} %');

    // Logika penentuan status badge otomatis berdasarkan HbA1c
    double hba1cValue = double.tryParse(widget.patient.hba1c) ?? 0.0;
    if (hba1cValue >= 6.5) {
      _isDiabetes = true;
    }
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _tglLahirController.dispose();
    _genderController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _glukosaPPController.dispose();
    _glukosaPuasaController.dispose();
    _hba1cController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 460,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER POPUP (Judul + Tombol Close Silang)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detail Pasien',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff111827)),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 20, color: Color(0xff6b7280)),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 12),

            // AREA INPUT FORM SCROLLABLE (READ ONLY)
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabelField('NIK'),
                    _buildInputBox(_nikController, 'NIK'),

                    _buildLabelField('Nama Lengkap'),
                    _buildInputBox(_namaController, 'Nama Lengkap'),

                    // Row Umur & Jenis Kelamin
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabelField('Umur Pasien'),
                              _buildInputBox(_tglLahirController, 'Umur'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabelField('Jenis Kelamin'),
                              _buildInputBox(_genderController, 'Jenis Kelamin'),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Row Email & Nomor Telepon
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabelField('Email'),
                              _buildInputBox(_emailController, 'Email'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabelField('Nomor Telepon'),
                              _buildInputBox(_phoneController, 'Nomor Telepon'),
                            ],
                          ),
                        ),
                      ],
                    ),

                    _buildLabelField('Kadar Glukosa Plasma 2 jam PP'),
                    _buildInputBox(_glukosaPPController, 'mg/dl'),

                    _buildLabelField('Kadar Glukosa Plasma Puasa'),
                    _buildInputBox(_glukosaPuasaController, 'mg/dl'),

                    _buildLabelField('Hba1C'),
                    _buildInputBox(_hba1cController, '%'),

                    _buildMedicineExplanation(),

                    // Status Badge Dinamis berdasarkan indikasi medis pasien
                    _buildLabelField('Status'),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isDiabetes ? const Color(0xffef4444) : const Color(0xff4ade80), // Merah jika diabetes, hijau jika normal
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isDiabetes ? 'Diabetes' : 'Normal',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // TOMBOL UTAMA AKSI DI BAWAH (Buat Janji Temu)
            // SizedBox(
            //   width: double.infinity,
            //   height: 46,
            //   child: ElevatedButton(
            //     onPressed: () {
            //       // Di sini nanti bisa kamu sambungkan ke fungsi getJanjiTemu() atau modal janji temu kemarin!
            //       Navigator.pop(context);
            //     },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: const Color(0xff111827),
            //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            //       elevation: 0,
            //     ),
            //     child: const Text(
            //       'Buat Janji Temu',
            //       style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // Helper pembuat judul form field
  Widget _buildLabelField(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 13),
      ),
    );
  }

  Widget _buildMedicineExplanation() {
    final double hba1cValue = double.tryParse(widget.patient.hba1c.replaceAll(',', '.')) ?? 0.0;
    String recommendation;

    if (hba1cValue > 9) {
      recommendation =
          'HbA1c pasien tinggi. Biasanya perlu evaluasi terapi intensif, bisa berupa kombinasi obat oral dan/atau insulin sesuai keputusan dokter/apoteker.';
    } else if (hba1cValue >= 7) {
      recommendation =
          'HbA1c belum mencapai target. Umumnya terapi obat oral seperti metformin atau kombinasi obat lain perlu dievaluasi ulang.';
    } else if (hba1cValue > 0) {
      recommendation =
          'HbA1c relatif terkontrol. Terapi tetap dilanjutkan sesuai resep, disertai pemantauan gula darah, makan, dan aktivitas.';
    } else {
      recommendation =
          'Data HbA1c belum tersedia, sehingga jenis obat belum bisa disarankan dari hasil lab terbaru.';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffeff6ff),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffbfdbfe)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medication_outlined, size: 18, color: Color(0xff2563eb)),
              SizedBox(width: 8),
              Text(
                'Penjelasan Jenis Obat',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff1e3a8a)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation,
            style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xff1f2937)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Contoh jenis obat diabetes: Metformin untuk membantu sensitivitas insulin, Sulfonilurea untuk merangsang produksi insulin, dan Insulin untuk kondisi tertentu saat gula darah sangat tinggi atau terapi oral belum cukup.',
            style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xff4b5563)),
          ),
        ],
      ),
    );
  }

  // Helper pembuat input box bulat abu-abu (Read-Only)
  Widget _buildInputBox(TextEditingController controller, String placeholder) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: const Color(0xfff3f4f6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        readOnly: true, // 👈 Diset true agar admin hanya bisa melihat data detail tanpa tidak sengaja mengubah ketikan
        style: const TextStyle(fontSize: 13, color: Color(0xff1f2937), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: Color(0xff9ca3af), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}