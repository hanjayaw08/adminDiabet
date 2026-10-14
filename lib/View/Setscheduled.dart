import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:admindiabetes/ViewModel.dart'; // 👈 Sesuaikan lokasi import PatientModel kamu

// ==========================================
// POPUP DIALOG: SET JADWAL OBAT (FULL INTEGRASI)
// ==========================================
class SetSchedulePopup extends StatefulWidget {
  final PatientModel patient; // 👈 Menerima data lemparan pasien dari tabel utama

  const SetSchedulePopup({super.key, required this.patient});

  @override
  State<SetSchedulePopup> createState() => _SetSchedulePopupState();
}

class _SetSchedulePopupState extends State<SetSchedulePopup> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String? _selectedMedicine;

  // List dinamis untuk menampung jam minum obat dan nama obat
  List<String> _selectedTimes = [];
  List<String> _selectedMedicines = [];

  final List<String> _medicineOptions = const [
    'Metformin',
    'Sulfonilurea',
    'Acarbose',
    'DPP-4 Inhibitor',
    'SGLT2 Inhibitor',
    'Insulin',
  ];

  @override
  void initState() {
    super.initState();
    // 1. Kunci nama controller langsung dari data pasien database (Read-only)
    _namaController.text = widget.patient.name;

    // 2. Load data jadwal lama dari Firebase jika sudah pernah diset sebelumnya
    if (widget.patient.medicineTimes != '-') {
      _selectedTimes = widget.patient.medicineTimes
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (widget.patient.medicineNames != '-') {
      _selectedMedicines = widget.patient.medicineNames
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // Fungsi memunculkan jam picker bawaan agar admin tidak perlu ngetik manual
  Future<void> _selectTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        // Format menjadi string HH:mm (contoh: 08:30)
        _timeController.text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  // Fungsi untuk menambah jam ke dalam list chips
  void _addTime() {
    String inputTime = _timeController.text.trim();
    if (inputTime.isNotEmpty) {
      if (!_selectedTimes.contains(inputTime)) {
        setState(() {
          _selectedTimes.add(inputTime);
          _selectedTimes.sort(); // Mengurutkan jam otomatis dari pagi ke malam
          _timeController.clear();
        });
      } else {
        EasyLoading.showInfo('Jam tersebut sudah terdaftar');
      }
    } else {
      EasyLoading.showInfo('Pilih jam terlebih dahulu!');
    }
  }

  // Fungsi untuk menghapus jam dari list chips
  void _removeTime(int index) {
    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  void _addMedicine() {
    final medicine = _selectedMedicine?.trim() ?? '';
    if (medicine.isEmpty) {
      EasyLoading.showInfo('Pilih obat terlebih dahulu!');
      return;
    }

    if (_selectedMedicines.contains(medicine)) {
      EasyLoading.showInfo('Obat tersebut sudah terdaftar');
      return;
    }

    setState(() {
      _selectedMedicines.add(medicine);
      _selectedMedicine = null;
    });
  }

  void _removeMedicine(int index) {
    setState(() {
      _selectedMedicines.removeAt(index);
    });
  }

  // 🔥 FUNGSI UTAMA: MENYIMPAN GABUNGAN JADWAL KE FIREBASE FIRESTORE
  Future<void> _saveScheduleToFirebase() async {
    if (_selectedTimes.isEmpty) {
      EasyLoading.showError('Minimal harus ada 1 jadwal minum obat!');
      return;
    }

    if (_selectedMedicines.isEmpty) {
      EasyLoading.showError('Minimal pilih 1 obat!');
      return;
    }

    try {
      EasyLoading.show(status: 'Menyimpan jadwal...');

      // Menggabungkan array ['07:00', '15:00'] menjadi string "07:00, 15:00"
      String mergedTimes = _selectedTimes.join(', ');
      String mergedMedicines = _selectedMedicines.join(', ');

      // Update langsung field 'medicineTimes' dan 'medicineNames' ke dokumen pasien berdasarkan ID-nya
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patient.id)
          .update({
        'medicineTimes': mergedTimes,
        'medicineNames': mergedMedicines,
      });

      EasyLoading.showSuccess('Jadwal obat berhasil diperbarui!');

      if (mounted) {
        Navigator.pop(context); // Tutup popup dialog
      }
    } catch (e) {
      EasyLoading.showError('Gagal memproses data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 460, // Lebar modal sesuai desain figma kamu
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER: Judul dengan Underline & Tombol Close X
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set Jadwal Obat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 140,
                      height: 2,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xff3b59b6),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xff3b59b6),
                          style: BorderStyle.solid,
                          width: 1
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.close, size: 20, color: Color(0xff3b59b6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // INPUT: Nama Pasien (Set readOnly biar aman)
            _buildLabelField('Nama Pasien'),
            _buildInputBox(_namaController, 'Nama Lengkap', readOnly: true),

            const SizedBox(height: 16),

            // INPUT: Pilih Jam + Tombol Tambah
            _buildLabelField('Pilih Jam'),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTimePicker(context), // Klik input langsung buka timepicker
                    child: AbsorbPointer(
                      child: _buildInputBox(
                          _timeController,
                          'Pilih Jam',
                          suffixIcon: Icons.access_time
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff111827),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // LIST CHIPS JAM (Warna Biru Khas Figma Kamu)
            _selectedTimes.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Belum ada jadwal jam yang ditambahkan.',
                style: TextStyle(fontSize: 12, color: Color(0xff9ca3af), fontStyle: FontStyle.italic),
              ),
            )
                : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedTimes.asMap().entries.map((entry) {
                int index = entry.key;
                String time = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xff3b59b6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeTime(index),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            _buildLabelField('Pilih Obat'),
            Row(
              children: [
                Expanded(
                  child: _buildMedicineDropdown(),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff111827),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _selectedMedicines.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Belum ada obat yang ditambahkan.',
                style: TextStyle(fontSize: 12, color: Color(0xff9ca3af), fontStyle: FontStyle.italic),
              ),
            )
                : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedMedicines.asMap().entries.map((entry) {
                int index = entry.key;
                String medicine = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xff059669),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        medicine,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeMedicine(index),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // TOMBOL SIMPAN (Menjalankan fungsi update database Firestore)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveScheduleToFirebase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff111827),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: const Text(
                  'Simpan & Sambungkan Data',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Label
  Widget _buildLabelField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 13),
      ),
    );
  }

  Widget _buildMedicineDropdown() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xfff3f4f6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMedicine,
          hint: const Text(
            'Pilih Obat',
            style: TextStyle(color: Color(0xff9ca3af), fontSize: 14),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff9ca3af)),
          items: _medicineOptions
              .map((medicine) => DropdownMenuItem<String>(
            value: medicine,
            child: Text(medicine, style: const TextStyle(fontSize: 14)),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedMedicine = value;
            });
          },
        ),
      ),
    );
  }

  // Helper Input Box (Ditambahkan parameter readOnly)
  Widget _buildInputBox(TextEditingController controller, String hint, {IconData? suffixIcon, bool readOnly = false}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xfff3f4f6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xff9ca3af), fontSize: 14),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20, color: const Color(0xff9ca3af)) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}