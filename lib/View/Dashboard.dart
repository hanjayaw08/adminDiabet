import 'package:admindiabetes/Controller.dart';
import 'package:admindiabetes/View/AddPatient.dart';
import 'package:admindiabetes/View/AddStaffAccount.dart';
import 'package:admindiabetes/View/ChatPage.dart';
import 'package:admindiabetes/View/EducationContent.dart';
import 'package:admindiabetes/View/Inputhasillab.dart';
import 'package:admindiabetes/View/Jadwalobat.dart';
import 'package:admindiabetes/View/PasienList.dart';
import 'package:flutter/material.dart';
import 'package:admindiabetes/View/Addlabresult.dart';
import 'package:admindiabetes/ViewModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

// ==========================================
// MAIN DASHBOARD SCREEN (STATEFUL)
// ==========================================
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  String _selectedMenu = 'Dashboard';

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      drawer: !isDesktop ? Drawer(child: _buildSidebarContent()) : null,
      body: Column(
        children: [
          // 1. TOP NAVIGATION BAR (Full Width)
          TopNavigationBar(isDesktop: isDesktop),

          // 2. AREA UTAMA (Sidebar + Content Area)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SIDEBAR MENU (Muncul permanen di desktop)
                if (isDesktop)
                  Container(
                    width: 240,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border:
                          Border(right: BorderSide(color: Color(0xffe5e7eb))),
                    ),
                    child: _buildSidebarContent(),
                  ),

                // CONTENT AREA (Scroll Vertikal Saja, No Scroll Samping)
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth < 640 ? 16.0 : 24.0),
                    child: _selectedMenu == 'Dashboard'
                        ? DashboardContent()
                        : _selectedMenu == 'Daftar Pasien'
                            ? PatientListContent()
                            : _selectedMenu == 'Jadwal Obat'
                                ? MedicineScheduleContent()
                                : _selectedMenu == 'Input Hasil Lab'
                                    ? LabResultInputContent()
                                    : const EducationContentPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: const CustomChatFloatingButton(),
    );
  }

  // Konten navigasi Sidebar disesuaikan dengan Screenshot
  Widget _buildSidebarContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildSidebarItem(Icons.dashboard_rounded, 'Dashboard'),
        _buildSidebarItem(Icons.people_alt_rounded, 'Daftar Pasien'),
        _buildSidebarItem(Icons.calendar_today_rounded, 'Jadwal Obat'),
        _buildSidebarItem(
            Icons.assignment_turned_in_rounded, 'Input Hasil Lab'),
        _buildSidebarItem(Icons.menu_book_rounded, 'Edukasi Kesehatan'),
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, String title) {
    bool isSelected = _selectedMenu == title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff2d4da7) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? Colors.white : const Color(0xff4b5563),
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xff1f2937),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onTap: () {
            setState(() {
              _selectedMenu = title;
            });
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET: TOP NAVIGATION BAR
// ==========================================
class TopNavigationBar extends StatefulWidget {
  final bool isDesktop;
  const TopNavigationBar({super.key, required this.isDesktop});

  @override
  State<TopNavigationBar> createState() => _TopNavigationBarState();
}

class _TopNavigationBarState extends State<TopNavigationBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final AdminPatientSearchController searchController =
        Get.find<AdminPatientSearchController>();
    return Container(
      height: 70,
      color: const Color(0xff3b59b6), // Biru gelap figma sesuai gambar
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (!widget.isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 8),
          ],

          // Logo Brand
          const Row(
            children: [
              Icon(Icons.medical_services, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'PharmaDiaCare',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ],
          ),
          const Spacer(),

          // Navbar Search
          if (screenWidth > 768) ...[
            Container(
              width: 260,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: searchController.textController,
                onChanged: (value) {
                  searchController.updateQuery(
                      value); // 👈 Update nilai global tiap kali ngetik
                },
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.white60, fontSize: 13),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.white60, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 10),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Tombol + Akun Apoteker Atas
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return const AddStaffAccountPopup();
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Row(
              children: [
                Icon(Icons.manage_accounts_rounded,
                    size: 16, color: Color(0xff3b59b6)),
                SizedBox(width: 4),
                Text('Apoteker',
                    style: TextStyle(
                        color: Color(0xff3b59b6),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Tombol + Pasien Atas
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible:
                    true, // Biar bisa menutup pop-up kalau klik di luar area dialog
                builder: (BuildContext context) {
                  return AddPatientPopup();
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Row(
              children: [
                Icon(Icons.add, size: 16, color: Color(0xff3b59b6)),
                SizedBox(width: 4),
                Text('Pasien',
                    style: TextStyle(
                        color: Color(0xff3b59b6),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          IconButton(
            icon: const Icon(Icons.notifications_none_outlined,
                color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Belum ada notifikasi baru.')),
              );
            },
          ),
          const SizedBox(width: 4),

          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person_outline, color: Colors.white, size: 20),
          )
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET UTAMA: HALAMAN DASHBOARD MAIN OVERVIEW
// ==========================================
class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  late final Stream<List<PatientModel>> _dashboardStream;

  // 1. Inisialisasi/Temukan GlobalSearchController GetX
  final AdminPatientSearchController _searchCtrl =
      Get.find<AdminPatientSearchController>();
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  String _dashboardScheduleFilter = 'Semua';
  String _dashboardLabFilter = 'Semua';

  bool _hasMedicineSchedule(PatientModel patient) {
    return patient.medicineTimes.trim().isNotEmpty &&
        patient.medicineTimes.trim() != '-';
  }

  bool _hasLabResult(PatientModel patient) {
    return patient.hba1c != '0' &&
        patient.lastCheckDate.trim().isNotEmpty &&
        patient.lastCheckDate.trim() != '-';
  }

  @override
  void initState() {
    super.initState();
    // Membuka stream realtime ke koleksi 'patients'
    _dashboardStream = FirebaseFirestore.instance
        .collection('patients')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PatientModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> _showDashboardFilterDialog(BuildContext context) async {
    String tempSchedule = _dashboardScheduleFilter;
    String tempLab = _dashboardLabFilter;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Dashboard'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status Jadwal Obat',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButton<String>(
                    value: tempSchedule,
                    isExpanded: true,
                    items: const [
                      'Semua',
                      'Sudah Ada Jadwal',
                      'Belum Ada Jadwal'
                    ]
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null)
                        setDialogState(() => tempSchedule = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Status Hasil Lab',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButton<String>(
                    value: tempLab,
                    isExpanded: true,
                    items: const [
                      'Semua',
                      'Sudah Ada Hasil Lab',
                      'Belum Ada Hasil Lab'
                    ]
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => tempLab = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _dashboardScheduleFilter = 'Semua';
                      _dashboardLabFilter = 'Semua';
                      _currentPage = 0;
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _dashboardScheduleFilter = tempSchedule;
                      _dashboardLabFilter = tempLab;
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

    return StreamBuilder<List<PatientModel>>(
      stream: _dashboardStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator()));
        }

        final masterListPasien = snapshot.data ?? [];

        // 2. Hitung Total Pasien secara riil dari database (Master Data)
        int totalPasien = masterListPasien.length;

        // Jadwal konsultasi disembunyikan dari dashboard; dashboard hanya menampilkan data pasien/lab/obat.

        // 3. 🔥 BUNGKUS RETUR UI MENGGUNAKAN OBX SUPAYA REAKTIF TERHADAP NAVBAR SEARCH CONTROLLER
        return Obx(() {
          // Ambil nilai teks search ter-update dari GetX
          String query = _searchCtrl.searchQuery.value.toLowerCase().trim();

          // Saring/Filter daftar pasien berdasarkan nama/NIK, jadwal obat, dan hasil lab
          final filteredListPasien = masterListPasien.where((patient) {
            final matchesSearch = query.isEmpty ||
                patient.name.toLowerCase().contains(query) ||
                patient.nik.toLowerCase().contains(query);
            final hasSchedule = _hasMedicineSchedule(patient);
            final hasLab = _hasLabResult(patient);
            final matchesSchedule = _dashboardScheduleFilter == 'Semua' ||
                (_dashboardScheduleFilter == 'Sudah Ada Jadwal' &&
                    hasSchedule) ||
                (_dashboardScheduleFilter == 'Belum Ada Jadwal' &&
                    !hasSchedule);
            final matchesLab = _dashboardLabFilter == 'Semua' ||
                (_dashboardLabFilter == 'Sudah Ada Hasil Lab' && hasLab) ||
                (_dashboardLabFilter == 'Belum Ada Hasil Lab' && !hasLab);

            return matchesSearch && matchesSchedule && matchesLab;
          }).toList();

          final int totalPages = filteredListPasien.isEmpty
              ? 1
              : (filteredListPasien.length / _itemsPerPage).ceil();
          final int safeCurrentPage =
              _currentPage >= totalPages ? totalPages - 1 : _currentPage;
          if (safeCurrentPage != _currentPage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _currentPage = safeCurrentPage);
            });
          }
          final int startIndex = safeCurrentPage * _itemsPerPage;
          final paginatedListPasien =
              filteredListPasien.skip(startIndex).take(_itemsPerPage).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Welcome & Filter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang, Bagus Dwi',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff1f2937)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kelola pasien diabetes dengan efisien hari ini',
                          style:
                              TextStyle(fontSize: 14, color: Color(0xff6b7280)),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showDashboardFilterDialog(context),
                    icon: const Icon(Icons.tune_rounded,
                        size: 16, color: Color(0xff4b5563)),
                    label: const Text('Filter',
                        style: TextStyle(color: Color(0xff4b5563))),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xffe5e7eb)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Menu Title & Realtime Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1f2937)),
                  ),
                  if (screenWidth > 600)
                    const Row(
                      children: [
                        Text(
                          'Data diperbarui realtime ',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xff9ca3af)),
                        ),
                        Icon(Icons.refresh, size: 14, color: Color(0xff9ca3af)),
                      ],
                    )
                ],
              ),
              const SizedBox(height: 16),

              // Grid Info Cards (jadwal konsultasi disembunyikan)
              Row(
                children: [
                  Expanded(
                      child: InfoCard(
                          title: 'Total Pasien',
                          count: '$totalPasien',
                          subtitle: 'Semua waktu',
                          icon: Icons.groups_outlined)),
                  if (screenWidth >= 1024)
                    const Expanded(flex: 1, child: SizedBox()),
                  if (screenWidth >= 1024)
                    const Expanded(flex: 1, child: SizedBox()),
                ],
              ),
              const SizedBox(height: 28),

              // Judul Section Tabel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Pasien',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1f2937)),
                  ),
                  TextButton(
                    onPressed: () {
                      _searchCtrl.clearSearch();
                      setState(() {
                        _dashboardScheduleFilter = 'Semua';
                        _dashboardLabFilter = 'Semua';
                        _currentPage = 0;
                      });
                    },
                    child: const Text('Lihat semua',
                        style: TextStyle(
                            color: Color(0xff3b59b6),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // TABEL RESPONSIF REALTIME (Memakai filteredListPasien hasil pencarian)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xffe5e7eb)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      color: const Color(0xfff9fafb),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: const Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text('Pasien',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff4b5563)))),
                          Expanded(
                              flex: 4,
                              child: Text('Jadwal Obat Pasien',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff4b5563)))),
                          Expanded(
                              flex: 3,
                              child: Text('Pemeriksaan Terakhir (Hasil)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff4b5563)))),
                          Expanded(
                              flex: 2,
                              child: Text('Aksi',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff4b5563)))),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xffe5e7eb)),
                    filteredListPasien.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                                child: Text(
                                    'Belum ada data pasien atau tidak ditemukan.',
                                    style:
                                        TextStyle(color: Color(0xff6b7280)))),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              paginatedListPasien.length,
                              (index) {
                                final patient = paginatedListPasien[index];
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TableRowData(patient: patient),
                                    if (index < paginatedListPasien.length - 1)
                                      const Divider(
                                          height: 1, color: Color(0xffe5e7eb)),
                                  ],
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Pagination Footer
              PaginationRow(
                currentPage: safeCurrentPage,
                totalPages: totalPages,
                onPrevious: safeCurrentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                onNext: safeCurrentPage < totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          );
        }); // 👈 Tutup Obx GetX
      }, // 👈 Tutup builder StreamBuilder
    ); // 👈 Tutup return StreamBuilder
  }
}

// ==========================================
// SUB-WIDGET: INFO CARD
// ==========================================
class InfoCard extends StatelessWidget {
  final String title;
  final String count;
  final String subtitle;
  final IconData icon;

  const InfoCard({
    super.key,
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff4b5563), size: 22),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff374151))),
          const SizedBox(height: 8),
          Text(count,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff111827))),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xff9ca3af))),
        ],
      ),
    );
  }
}

// ==========================================
// SUB-WIDGET: TABLE ROW DATA
// ==========================================
class TableRowData extends StatelessWidget {
  final PatientModel patient;

  const TableRowData({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    bool isMedicineEmpty =
        patient.medicineTimes == '-' || patient.medicineTimes.isEmpty;
    bool isLabEmpty = patient.hba1c == '0' ||
        patient.lastCheckDate == '-' ||
        patient.lastCheckDate.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // 1. Kolom Pasien
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff111827),
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '(${patient.gender}, ${patient.age} tahun) ${patient.nik}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xff9ca3af), fontSize: 12),
                ),
              ],
            ),
          ),

          // 2. Kolom Jadwal Obat Pasien
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: Color(0xff4b5563)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isMedicineEmpty
                        ? 'Belum set jadwal'
                        : patient.medicineTimes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isMedicineEmpty
                          ? const Color(0xff9ca3af)
                          : const Color(0xff1f2937),
                      fontSize: 13,
                      fontStyle:
                          isMedicineEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isMedicineEmpty
                      ? null
                      : () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('patients')
                                .doc(patient.id)
                                .collection('messages')
                                .add({
                              'text':
                                  'Pengingat minum obat: ${patient.medicineNames} pada ${patient.medicineTimes}.',
                              'sender': 'Admin',
                              'type': 'medicine_reminder',
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Pengingat obat dikirim ke ${patient.name}.'),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Gagal mengirim pengingat: $e')),
                            );
                          }
                        },
                  icon: const Icon(Icons.notifications_none,
                      size: 12, color: Colors.white),
                  label: const Text('Ingatkan',
                      style: TextStyle(fontSize: 11, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff111827),
                    disabledBackgroundColor: const Color(0xffe5e7eb),
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          // 3. Kolom Pemeriksaan Terakhir
          Expanded(
            flex: 3,
            child: Text(
              isLabEmpty
                  ? 'Belum cek lab'
                  : '${patient.lastCheckDate.split(' ')[0]} (HbA1c ${patient.hba1c}%)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLabEmpty
                    ? const Color(0xff9ca3af)
                    : const Color(0xff1f2937),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontStyle: isLabEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),

          // 4. Kolom Aksi (Input / Ubah)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: isLabEmpty
                  ? ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              InputLabResultPopup(patient: patient),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff111827),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text(
                        'Input HbA1c',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              InputLabResultPopup(patient: patient),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xfff9fafb),
                        side: const BorderSide(color: Color(0xffe5e7eb)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text(
                        'Ubah HbA1c',
                        style: TextStyle(
                            color: Color(0xff4b5563),
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SUB-WIDGET: CONTROL FOOTER PAGINATION
// ==========================================
class PaginationRow extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PaginationRow({
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
          icon: Icon(Icons.arrow_back,
              size: 14,
              color: onPrevious == null
                  ? const Color(0xff9ca3af)
                  : const Color(0xff4b5563)),
          label: screenWidth < 480
              ? const SizedBox.shrink()
              : Text('Previous',
                  style: TextStyle(
                      color: onPrevious == null
                          ? const Color(0xff9ca3af)
                          : const Color(0xff4b5563),
                      fontSize: 12)),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            side: const BorderSide(color: Color(0xffe5e7eb)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        Text(
          'Halaman ${currentPage + 1} dari $totalPages',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xff4b5563)),
        ),
        OutlinedButton(
          onPressed: onNext,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            side: const BorderSide(color: Color(0xffe5e7eb)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Row(
            children: [
              if (screenWidth >= 480) ...[
                Text('Next',
                    style: TextStyle(
                        color: onNext == null
                            ? const Color(0xff9ca3af)
                            : const Color(0xff4b5563),
                        fontSize: 12)),
                const SizedBox(width: 4),
              ],
              Icon(Icons.arrow_forward,
                  size: 14,
                  color: onNext == null
                      ? const Color(0xff9ca3af)
                      : const Color(0xff4b5563)),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// SUB-WIDGET: FLOATING CHAT BUTTON
// ==========================================
class CustomChatFloatingButton extends StatefulWidget {
  const CustomChatFloatingButton({super.key});

  @override
  State<CustomChatFloatingButton> createState() =>
      _CustomChatFloatingButtonState();
}

class _CustomChatFloatingButtonState extends State<CustomChatFloatingButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PatientChatListPage()),
        );
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('patients').snapshots(),
          builder: (context, snapshot) {
            final int totalPatients = snapshot.data?.docs.length ?? 0;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pesan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 9,
                  child: Text(
                    totalPatients > 99 ? '99+' : totalPatients.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_up,
                    color: Colors.white, size: 18),
              ],
            );
          },
        ),
      ),
    );
  }
}
