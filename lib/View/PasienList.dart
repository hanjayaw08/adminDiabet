import 'package:admindiabetes/Controller.dart';
import 'package:admindiabetes/View/AddPatient.dart';
import 'package:admindiabetes/View/Dashboard.dart';
import 'package:admindiabetes/View/Patientdetail.dart';
import 'package:admindiabetes/ViewModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

// ==========================================
// WIDGET UTAMA: PATIENT LIST CONTENT
// ==========================================
class PatientListContent extends StatefulWidget {
  const PatientListContent({super.key});

  @override
  State<PatientListContent> createState() => _PatientListContentState();
}

class _PatientListContentState extends State<PatientListContent> {
  late TextEditingController _searchPatientController;
  final AdminPatientSearchController _searchCtrl =
      Get.find<AdminPatientSearchController>();
  int _currentPage = 0;
  int _totalFilteredPatients = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _searchPatientController = TextEditingController();
  }

  @override
  void dispose() {
    _searchPatientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TOP HEADER ACTION ROW (Judul, Search, Filter, +Pasien)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul Halaman
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar Pasien',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff111827)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kelola data pasien diabetes',
                    style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Indikator Realtime Data
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => Text(
                  'Data diperbarui realtime ${_searchCtrl.lastUpdateTime.value} ',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xff9ca3af)),
                ),
              ),
              const Icon(Icons.refresh, size: 14, color: Color(0xff9ca3af)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. TABEL DAFTAR PASIEN RESPONSIF
        PatientResponsiveTable(
          currentPage: _currentPage,
          itemsPerPage: _itemsPerPage,
          onPageAdjusted: (page) => setState(() => _currentPage = page),
          onTotalFilteredChanged: (total) {
            if (_totalFilteredPatients != total) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _totalFilteredPatients = total);
              });
            }
          },
        ),
        const SizedBox(height: 20),

        // 3. PAGINATION ROW
        PatientPaginationRow(
          currentPage: _currentPage,
          totalPages: _totalFilteredPatients == 0 ? 1 : (_totalFilteredPatients / _itemsPerPage).ceil(),
          onPrevious: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          onNext: _currentPage < ((_totalFilteredPatients == 0 ? 1 : (_totalFilteredPatients / _itemsPerPage).ceil()) - 1)
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );
  }
}

// ==========================================
// SUB-WIDGET: PATIENT RESPONSIVE TABLE (STREAM REALTIME)
// ==========================================
class PatientResponsiveTable extends StatefulWidget {
  final int currentPage;
  final int itemsPerPage;
  final ValueChanged<int> onPageAdjusted;
  final ValueChanged<int> onTotalFilteredChanged;

  const PatientResponsiveTable({
    super.key,
    required this.currentPage,
    required this.itemsPerPage,
    required this.onPageAdjusted,
    required this.onTotalFilteredChanged,
  });

  @override
  State<PatientResponsiveTable> createState() => _PatientResponsiveTableState();
}

class _PatientResponsiveTableState extends State<PatientResponsiveTable> {
  // 1. Ambil/Find GlobalSearchController yang terhubung dengan Navbar global
  final AdminPatientSearchController searchCtrl = Get.find<AdminPatientSearchController>();
  late final Stream<List<PatientModel>> _adminPatientsStream;

  @override
  void initState() {
    super.initState();
    // Membuka stream langsung ke collection 'patients'
    _adminPatientsStream = FirebaseFirestore.instance
        .collection('patients')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PatientModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffe5e7eb)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Table Header
          Container(
            color: const Color(0xfff9fafb),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Pasien', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff4b5563)))),
                Expanded(flex: 4, child: Text('Kontak', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff4b5563)))),
                Expanded(flex: 3, child: Text('Pemeriksaan Terakhir', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff4b5563)))),
                Expanded(flex: 2, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff4b5563)))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xffe5e7eb)),

          // Table Body dengan StreamBuilder
          StreamBuilder<List<PatientModel>>(
            stream: _adminPatientsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(child: Text('Terjadi kesalahan: ${snapshot.error}')),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final List<PatientModel>? allPatients = snapshot.data;

              if (allPatients == null || allPatients.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('Belum ada data pasien di database.')),
                );
              }

              // 2. 🔥 BUNGKUS DENGAN OBX SUPAYA DATA KETIKAN NAVBAR REAKTIF KE TABEL INI
              return Obx(() {
                String query = searchCtrl.searchQuery.value.trim().toLowerCase();

                // Menyaring data berdasarkan apa yang diketik di Search Bar Global Navbar
                final List<PatientModel> filteredPatients = allPatients.where((patient) {
                  if (query.isEmpty) return true;
                  final matchName = patient.name.toLowerCase().contains(query);
                  final matchNik = patient.nik.contains(query);
                  return matchName || matchNik;
                }).toList();

                widget.onTotalFilteredChanged(filteredPatients.length);

                if (filteredPatients.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('Pasien tidak ditemukan.')),
                  );
                }

                final int totalPages = (filteredPatients.length / widget.itemsPerPage).ceil();
                final int safeCurrentPage = widget.currentPage >= totalPages ? totalPages - 1 : widget.currentPage;
                if (safeCurrentPage != widget.currentPage) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => widget.onPageAdjusted(safeCurrentPage));
                }
                final int startIndex = safeCurrentPage * widget.itemsPerPage;
                final paginatedPatients = filteredPatients.skip(startIndex).take(widget.itemsPerPage).toList();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(paginatedPatients.length, (index) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Melempar data patient ke widget baris tabel
                        PatientRowData(patient: paginatedPatients[index]),
                        if (index < paginatedPatients.length - 1)
                          const Divider(height: 1, color: Color(0xffe5e7eb)),
                      ],
                    );
                  }),
                );
              }); // 👈 Tutup Obx
            },
          )
        ],
      ),
    );
  }
}

// ==========================================
// SUB-WIDGET: PATIENT ROW DATA (SUDAH KONEK MODEL)
// ==========================================
class PatientRowData extends StatefulWidget {
  final PatientModel patient; // 👈 Menerima kiriman data objek model dari tabel di atas
  const PatientRowData({super.key, required this.patient});

  @override
  State<PatientRowData> createState() => _PatientRowDataState();
}

class _PatientRowDataState extends State<PatientRowData> {

  Future<void> _deleteFromFirebase(String patientId, String patientName) async {
    try {
      // 1. Tampilkan loading dengan status menghapus
      EasyLoading.show(status: 'Menghapus data...');

      // 2. Jalankan perintah hapus dokumen asli ke Firestore berdasarkan ID
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .delete();

      // 3. Tampilkan pesan sukses jika berhasil
      EasyLoading.showSuccess('Data $patientName berhasil dihapus!');
    } catch (e) {
      // 4. Jika ada error dari Firebase, handle dan tampilkan di EasyLoading
      EasyLoading.showError('Gagal menghapus: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Kolom 1: Nama, Gender, Umur & NIK Pasien (Menggunakan data dari Firebase)
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patient.name, // 👈 Ambil field 'name'
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff111827), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '(${widget.patient.gender}, ${widget.patient.age} tahun) ${widget.patient.nik}', // 👈 Ambil field 'gender', 'age', 'nik'
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xff9ca3af), fontSize: 12),
                ),
              ],
            ),
          ),

          // Kolom 2: Informasi Kontak (Telepon & Email dari Firebase)
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 13, color: Color(0xff4b5563)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.patient.phone, // 👈 Ambil field 'phone'
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xff4b5563), fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 13, color: Color(0xff4b5563)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.patient.email, // 👈 Ambil field 'email'
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xff4b5563), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Kolom 3: Tanggal Pemeriksaan Terakhir
          Expanded(
            flex: 3,
            child: Text(
              widget.patient.lastCheckDate, // 👈 Ambil field 'lastCheckDate'
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xff1f2937), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),

          // Kolom 4: Kumpulan Kotak Aksi Ikon (Lihat, Edit, Hapus)
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildActionIcon(Icons.visibility_outlined, onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => PatientDetailPopup(patient: widget.patient),
                  );
                }),
                const SizedBox(width: 6),
                _buildActionIcon(Icons.edit_outlined, onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true, // Biar bisa menutup pop-up kalau klik di luar area dialog
                    builder: (BuildContext context) {
                      return  AddPatientPopup(patient: widget.patient,);
                    },
                  );
                }),
                const SizedBox(width: 6),
                _buildActionIcon(Icons.delete_outline, color: Colors.red[400], onTap: () {
                  _deleteFromFirebase(widget.patient.id, widget.patient.name);
                }),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffe5e7eb)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color ?? const Color(0xff4b5563)),
      ),
    );
  }
}

// ==========================================
// SUB-WIDGET: PATIENT PAGINATION ROW
// ==========================================
class PatientPaginationRow extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PatientPaginationRow({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: onPrevious,
          icon: Icon(Icons.arrow_back, size: 14, color: onPrevious == null ? const Color(0xff9ca3af) : const Color(0xff4b5563)),
          label: screenWidth < 480 ? const SizedBox.shrink() : Text('Previous', style: TextStyle(color: onPrevious == null ? const Color(0xff9ca3af) : const Color(0xff4b5563), fontSize: 12)),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            side: const BorderSide(color: Color(0xffe5e7eb)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        Text(
          'Halaman ${currentPage + 1} dari $totalPages',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff4b5563)),
        ),
        OutlinedButton(
          onPressed: onNext,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            side: const BorderSide(color: Color(0xffe5e7eb)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Row(
            children: [
              if (screenWidth >= 480) ...[
                Text('Next', style: TextStyle(color: onNext == null ? const Color(0xff9ca3af) : const Color(0xff4b5563), fontSize: 12)),
                const SizedBox(width: 4),
              ],
              Icon(Icons.arrow_forward, size: 14, color: onNext == null ? const Color(0xff9ca3af) : const Color(0xff4b5563)),
            ],
          ),
        ),
      ],
    );
  }
}
