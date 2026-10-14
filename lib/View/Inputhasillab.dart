import 'package:admindiabetes/Controller.dart';
import 'package:admindiabetes/View/Addlabresult.dart';
import 'package:admindiabetes/ViewModel.dart'; // 👈 Pastikan import lokasi PatientModel sudah benar
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ==========================================
// WIDGET UTAMA: HALAMAN INPUT HASIL LAB
// ==========================================
class LabResultInputContent extends StatefulWidget {
  const LabResultInputContent({super.key});

  @override
  State<LabResultInputContent> createState() => _LabResultInputContentState();
}

class _LabResultInputContentState extends State<LabResultInputContent> {
  late TextEditingController _searchLabController;
  final AdminPatientSearchController searchCtrl = Get.put(AdminPatientSearchController());
  int _currentPage = 0;
  int _totalFilteredPatients = 0;
  final int _itemsPerPage = 5;
  String _labStatusFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _searchLabController = TextEditingController();

    // Sinkronisasi kolom pencarian dengan GetX Controller kamu
    _searchLabController.addListener(() {
      searchCtrl.searchQuery.value = _searchLabController.text;
    });
  }

  @override
  void dispose() {
    _searchLabController.dispose();
    super.dispose();
  }


  Future<void> _showLabFilterDialog(BuildContext context) async {
    String tempStatus = _labStatusFilter;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Hasil Lab'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status Hasil Lab', style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButton<String>(
                    value: tempStatus,
                    isExpanded: true,
                    items: const ['Semua', 'Sudah Ada Hasil', 'Belum Ada Hasil', 'HbA1c Normal', 'HbA1c Tinggi']
                        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => tempStatus = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _labStatusFilter = 'Semua';
                      _currentPage = 0;
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _labStatusFilter = tempStatus;
                      _currentPage = 0;
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TOP SECTION ROW (Header Title & Navigasi Filter)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Input Hasil Lab',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff111827)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Input hasil untuk monitoring lebih mudah',
                    style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
                  ),
                ],
              ),
            ),

            // Komponen Sisi Kanan: Kotak Cari & Tombol Filter
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (screenWidth > 768) ...[
                  Container(
                    width: 200,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xfff3f4f6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchLabController,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Color(0xff9ca3af), fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: Color(0xff9ca3af), size: 16),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(bottom: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                OutlinedButton.icon(
                  onPressed: () => _showLabFilterDialog(context),
                  icon: const Icon(Icons.tune_rounded, size: 14, color: Color(0xff4b5563)),
                  label: const Text('Filter', style: TextStyle(color: Color(0xff4b5563), fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xffe5e7eb)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Penunjuk Realtime
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Data diperbarui realtime ',
                style: TextStyle(fontSize: 12, color: Color(0xff9ca3af)),
              ),
              const Icon(Icons.refresh, size: 14, color: Color(0xff9ca3af)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. TABEL STRUKTUR DATA LABORATORIUM REALTIME
        LabResponsiveTable(
          currentPage: _currentPage,
          itemsPerPage: _itemsPerPage,
          labStatusFilter: _labStatusFilter,
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

        // 3. BARIS CONTROL HALAMAN (Pagination)
        LabPaginationRow(
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
// SUB-WIDGET: DATA LAB GRID TABLE (STREAM FIRESTORE)
// ==========================================
class LabResponsiveTable extends StatefulWidget {
  final int currentPage;
  final int itemsPerPage;
  final String labStatusFilter;
  final ValueChanged<int> onPageAdjusted;
  final ValueChanged<int> onTotalFilteredChanged;

  const LabResponsiveTable({
    super.key,
    required this.currentPage,
    required this.itemsPerPage,
    required this.labStatusFilter,
    required this.onPageAdjusted,
    required this.onTotalFilteredChanged,
  });

  @override
  State<LabResponsiveTable> createState() => _LabResponsiveTableState();
}

class _LabResponsiveTableState extends State<LabResponsiveTable> {
  // 1. Ambil/Find instance GlobalSearchController dari Navbar global
  final AdminPatientSearchController searchCtrl = Get.find<AdminPatientSearchController>();
  late final Stream<List<PatientModel>> _labPatientsStream;

  @override
  void initState() {
    super.initState();
    // Membuka koneksi stream realtime ke koleksi 'patients' di Firestore
    _labPatientsStream = FirebaseFirestore.instance
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
          // Struktur Nama Kolom Header Tabel
          Container(
            color: const Color(0xfff9fafb),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Pasien', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff4b5563)))),
                Expanded(flex: 4, child: Text('Pemeriksaan Terakhir', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff4b5563)))),
                Expanded(flex: 3, child: Text('Hasil dan Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff4b5563)))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff4b5563))))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xffe5e7eb)),

          // StreamBuilder mengambil data riil dari Firebase
          StreamBuilder<List<PatientModel>>(
            stream: _labPatientsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Error: ${snapshot.error}')));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: const EdgeInsets.all(32), child: CircularProgressIndicator()));
              }

              final allPatients = snapshot.data ?? [];

              // 2. 🔥 BUNGKUS DENGAN OBX SUPAYA REAKTIF TERHADAP KETIKAN GLOBAL SEARCH NAVBAR
              return Obx(() {
                String query = searchCtrl.searchQuery.value.trim().toLowerCase();

                // Memfilter list pasien berdasarkan keyword pencarian dan status hasil lab
                final filteredPatients = allPatients.where((p) {
                  final matchesSearch = query.isEmpty || p.name.toLowerCase().contains(query) || p.nik.contains(query);
                  final hba1cValue = double.tryParse(p.hba1c) ?? 0.0;
                  final hasLabResult = p.hba1c != '0' && p.lastCheckDate.trim().isNotEmpty && p.lastCheckDate.trim() != '-';
                  final isNormal = hasLabResult && hba1cValue < 7.0;
                  final matchesStatus = widget.labStatusFilter == 'Semua' ||
                      (widget.labStatusFilter == 'Sudah Ada Hasil' && hasLabResult) ||
                      (widget.labStatusFilter == 'Belum Ada Hasil' && !hasLabResult) ||
                      (widget.labStatusFilter == 'HbA1c Normal' && isNormal) ||
                      (widget.labStatusFilter == 'HbA1c Tinggi' && hasLabResult && !isNormal);
                  return matchesSearch && matchesStatus;
                }).toList();

                widget.onTotalFilteredChanged(filteredPatients.length);

                if (filteredPatients.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Pasien tidak ditemukan.')));
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
                    final patient = paginatedPatients[index];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Oper data objek pasien ke dalam baris tabel
                        LabRowData(patient: patient),
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
// SUB-WIDGET: ROW DATA REKAM LAB INDIVIDU (DATA FIREBASE)
// ==========================================
class LabRowData extends StatelessWidget {
  final PatientModel patient; // 👈 Menangkap data lemparan asli dari Firestore

  const LabRowData({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    // Parsing nilai HbA1c ke double untuk mengecek kondisi klinisnya
    double hba1cValue = double.tryParse(patient.hba1c) ?? 0.0;

    // Status normal jika di bawah 7% dan datanya bukan '0' (belum diisi)
    bool isNormalStatus = hba1cValue < 7.0 && patient.hba1c != '0';
    bool isDataEmpty = patient.hba1c == '0' || patient.lastCheckDate == '-' || patient.lastCheckDate.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Kolom 1: Profil ringkas pasien dari DB
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff111827), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '(${patient.gender}, ${patient.age} tahun) ${patient.nik}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xff9ca3af), fontSize: 12),
                ),
              ],
            ),
          ),

          // Kolom 2: Tanggal & Waktu Cek Lab Terakhir
          Expanded(
            flex: 4,
            child: Text(
              isDataEmpty ? '-' : patient.lastCheckDate,
              style: const TextStyle(color: Color(0xff1f2937), fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ),

          // Kolom 3: Hasil + Status Color Badge
          Expanded(
            flex: 3,
            child: isDataEmpty
                ? const Text(
              'Belum ada riwayat lab',
              style: TextStyle(color: Color(0xff9ca3af), fontSize: 13, fontStyle: FontStyle.italic),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HbA1c ${patient.hba1c}% ',
                  style: const TextStyle(color: Color(0xff1f2937), fontSize: 13, fontWeight: FontWeight.w400),
                ),
                const SizedBox(width: 4),

                // Pembungkus Badge Indikator Status Klinis (Hijau / Merah)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isNormalStatus ? const Color(0xffe8f5e9) : const Color(0xfffce8e6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isNormalStatus ? const Color(0xffa5d6a7) : const Color(0xfff8b4b4),
                    ),
                  ),
                  child: Text(
                    isNormalStatus ? 'Normal' : 'Tinggi',
                    style: TextStyle(
                      color: isNormalStatus ? const Color(0xff2e7d32) : const Color(0xffc62828),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Kolom 4: Tombol Utama Aksi (Dinamis Otomatis berubah teks & style)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: isDataEmpty
                  ? ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => InputLabResultPopup(patient: patient),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff111827), // Hitam Solid jika baru mau input
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text(
                  'Input Hasil',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
                  : OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => InputLabResultPopup(patient: patient),
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xfff9fafb), // Abu-abu Terang jika sifatnya mengedit
                  side: const BorderSide(color: Color(0xffe5e7eb)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text(
                  'Ubah Hasil',
                  style: TextStyle(color: Color(0xff4b5563), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// SUB-WIDGET: CONTROL FOOTER PAGINATION
// ==========================================
class LabPaginationRow extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const LabPaginationRow({
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