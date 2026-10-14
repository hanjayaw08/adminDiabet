import 'package:admindiabetes/Controller.dart';
import 'package:admindiabetes/View/Setscheduled.dart';
import 'package:admindiabetes/ViewModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ==========================================
// WIDGET UTAMA: HALAMAN JADWAL OBAT
// ==========================================
class MedicineScheduleContent extends StatefulWidget {
  const MedicineScheduleContent({super.key});

  @override
  State<MedicineScheduleContent> createState() => _MedicineScheduleContentState();
}

class _MedicineScheduleContentState extends State<MedicineScheduleContent> {
  late TextEditingController _searchScheduleController;
  final AdminPatientSearchController searchCtrl = Get.put(AdminPatientSearchController());
  int _currentPage = 0;
  int _totalFilteredPatients = 0;
  final int _itemsPerPage = 5;
  String _scheduleStatusFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _searchScheduleController = TextEditingController();

    // Sinkronisasi kolom pencarian dengan GetX Controller kamu
    _searchScheduleController.addListener(() {
      searchCtrl.searchQuery.value = _searchScheduleController.text;
    });
  }

  @override
  void dispose() {
    _searchScheduleController.dispose();
    super.dispose();
  }


  Future<void> _showScheduleFilterDialog(BuildContext context) async {
    String tempStatus = _scheduleStatusFilter;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Jadwal Obat'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status Jadwal', style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButton<String>(
                    value: tempStatus,
                    isExpanded: true,
                    items: const ['Semua', 'Sudah Diset', 'Belum Diset']
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
                      _scheduleStatusFilter = 'Semua';
                      _currentPage = 0;
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _scheduleStatusFilter = tempStatus;
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
        // 1. TOP NAVBAR ACTION ROW (Judul & Filter Kontrol)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jadwal Obat',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff111827)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Jadwalkan secara teratur untuk minum obat bagi pasien',
                    style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
                  ),
                ],
              ),
            ),

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
                      controller: _searchScheduleController,
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
                  onPressed: () => _showScheduleFilterDialog(context),
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

        // Indikator Realtime
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

        // 2. TABEL UTAMA SINKRON FIREBASE
        ScheduleResponsiveTable(
          currentPage: _currentPage,
          itemsPerPage: _itemsPerPage,
          statusFilter: _scheduleStatusFilter,
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

        SchedulePaginationRow(
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
// SUB-WIDGET: RESPONSIVE SCHEDULE TABLE (KONEK STREAM)
// ==========================================
class ScheduleResponsiveTable extends StatefulWidget {
  final int currentPage;
  final int itemsPerPage;
  final String statusFilter;
  final ValueChanged<int> onPageAdjusted;
  final ValueChanged<int> onTotalFilteredChanged;

  const ScheduleResponsiveTable({
    super.key,
    required this.currentPage,
    required this.itemsPerPage,
    required this.statusFilter,
    required this.onPageAdjusted,
    required this.onTotalFilteredChanged,
  });

  @override
  State<ScheduleResponsiveTable> createState() => _ScheduleResponsiveTableState();
}

class _ScheduleResponsiveTableState extends State<ScheduleResponsiveTable> {
  // 1. Ambil/Find instance GlobalSearchController dari Navbar global
  final AdminPatientSearchController searchCtrl = Get.find<AdminPatientSearchController>();
  late final Stream<List<PatientModel>> _scheduleStream;

  @override
  void initState() {
    super.initState();
    // Buka koneksi realtime stream ke Firestore
    _scheduleStream = FirebaseFirestore.instance
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
          // Header Tabel
          Container(
            color: const Color(0xfff9fafb),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Pasien', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff4b5563)))),
                Expanded(flex: 4, child: Text('Jadwal Obat Pasien', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff4b5563)))),
                Expanded(flex: 3, child: Text('Pemeriksaan Terakhir (Hasil)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff4b5563)))),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff4b5563))),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xffe5e7eb)),

          // StreamBuilder Menggantikan List.generate Statis
          StreamBuilder<List<PatientModel>>(
            stream: _scheduleStream,
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

                // Filter data berdasarkan pencarian dan status jadwal
                final filteredPatients = allPatients.where((p) {
                  final matchesSearch = query.isEmpty || p.name.toLowerCase().contains(query) || p.nik.contains(query);
                  final hasSchedule = p.medicineTimes.trim().isNotEmpty && p.medicineTimes.trim() != '-';
                  final matchesStatus = widget.statusFilter == 'Semua' ||
                      (widget.statusFilter == 'Sudah Diset' && hasSchedule) ||
                      (widget.statusFilter == 'Belum Diset' && !hasSchedule);
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
                        // Lempar data objek pasien dinamis ke baris tabel 👇
                        ScheduleRowData(patient: patient),
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
// SUB-WIDGET: KONTEN DATA BARIS TABEL (DINAMIS)
// ==========================================
class ScheduleRowData extends StatelessWidget {
  final PatientModel patient; // 👈 Terima data objek pasien asli dari Firestore

  const ScheduleRowData({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    // Logika otomatis: Jika medicineTimes bernilai '-' maka dianggap belum diset!
    bool isNotSet = patient.medicineTimes == '-';
    final String medicineSummary = patient.medicineNames == '-' || patient.medicineNames.trim().isEmpty
        ? 'Obat belum dipilih'
        : patient.medicineNames;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Kolom 1: Profil & Identitas Pasien (Data Nyata)
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

          // Kolom 2: Obat dan Jam Pengingat Dinamis
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Expanded(
                  child: isNotSet
                      ? const Text(
                    'Jadwal belum diset',
                    style: TextStyle(color: Color(0xff6b7280), fontSize: 13, fontStyle: FontStyle.italic),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medication_outlined, size: 14, color: Color(0xff059669)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              medicineSummary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xff1f2937), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Color(0xff4b5563)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              patient.medicineTimes,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xff4b5563), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol "Ingatkan" berganti warna sesuai status set jadwal
                OutlinedButton.icon(
                  onPressed: () {
                    // Aksi opsional trigger push notification/WhatsApp blast pengingat
                  },
                  icon: Icon(
                      Icons.notifications_none_outlined,
                      size: 13,
                      color: isNotSet ? const Color(0xff9ca3af) : Colors.white
                  ),
                  label: Text(
                      'Ingatkan',
                      style: TextStyle(
                          color: isNotSet ? const Color(0xff9ca3af) : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold
                      )
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isNotSet ? Colors.white : const Color(0xff111827),
                    side: BorderSide(color: isNotSet ? const Color(0xffe5e7eb) : Colors.transparent),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),

          // Kolom 3: Hasil Riwayat Lab Terakhir Nyata dari Form Diagnosa Pasien
          Expanded(
            flex: 3,
            child: Text(
              '${patient.lastCheckDate} (HbA1c: ${patient.hba1c}%)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xff4b5563), fontSize: 13),
            ),
          ),

          // Kolom 4: Tombol Aksi Utama Dinamis (Melempar Objek Pasien ke Pop-up)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: isNotSet
                  ? ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => SetSchedulePopup(patient: patient), // 👈 Oper data ke pop-up buat baru
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff111827),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text(
                  'Set Jadwal',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
                  : OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => SetSchedulePopup(patient: patient), // 👈 Oper data ke pop-up untuk edit
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xfff9fafb),
                  side: const BorderSide(color: Color(0xffe5e7eb)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text(
                  'Ubah Jadwal',
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
// SUB-WIDGET: BOTTOM PAGINATION BAR
// ==========================================
class SchedulePaginationRow extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const SchedulePaginationRow({
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