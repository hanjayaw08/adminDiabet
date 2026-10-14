import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admindiabetes/ViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ContentManagementContent extends StatefulWidget {
  const ContentManagementContent({super.key});

  @override
  State<ContentManagementContent> createState() => _ContentManagementContentState();
}

class _ContentManagementContentState extends State<ContentManagementContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showContentDialog({DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final data = doc?.data() ?? <String, dynamic>{};
    final titleController = TextEditingController(text: (data['Judul'] ?? '').toString());
    final descController = TextEditingController(text: (data['Keterangan'] ?? '').toString());
    final imageUrlController = TextEditingController(text: (data['imageUrl'] ?? '').toString());
    final videoUrlController = TextEditingController(text: (data['videoUrl'] ?? '').toString());
    String contentType = (data['tipeKonten'] ?? 'artikel').toString();
    PatientModel? selectedPatient;
    final existingPatientId = (data['patientId'] ?? '').toString();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.48,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(doc == null ? 'Tambah Konten Edukasi' : 'Edit Konten Edukasi', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Jenis Konten', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: contentType,
                    items: const [
                      DropdownMenuItem(value: 'artikel', child: Text('Artikel')),
                      DropdownMenuItem(value: 'video', child: Text('Video')),
                    ],
                    onChanged: (value) => setDialogState(() => contentType = value ?? 'artikel'),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  const Text('Hubungkan ke Pasien (opsional)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('patients').snapshots(),
                    builder: (context, snapshot) {
                      final patients = snapshot.data?.docs.map((d) => PatientModel.fromFirestore(d)).where((p) => p.name.trim().isNotEmpty).toList() ?? <PatientModel>[];
                      patients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                      selectedPatient ??= existingPatientId.isEmpty ? null : patients.where((p) => p.id == existingPatientId).cast<PatientModel?>().firstOrNull;
                      return DropdownButtonFormField<String>(
                        value: selectedPatient?.id ?? '',
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(value: '', child: Text('Global / semua pasien')),
                          ...patients.map((patient) => DropdownMenuItem(value: patient.id, child: Text('${patient.name}${patient.nik.isNotEmpty ? ' - ${patient.nik}' : ''}'))),
                        ],
                        onChanged: (value) => setDialogState(() {
                          selectedPatient = (value == null || value.isEmpty) ? null : patients.firstWhere((p) => p.id == value);
                        }),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Judul', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: titleController, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Judul konten')),
                  const SizedBox(height: 14),
                  const Text('Isi / Deskripsi', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: descController, maxLines: 5, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Isi artikel atau deskripsi video')),
                  const SizedBox(height: 14),
                  TextField(controller: imageUrlController, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'URL gambar (opsional)')),
                  if (contentType == 'video') ...[
                    const SizedBox(height: 14),
                    TextField(controller: videoUrlController, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'URL video')),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2d4da7), foregroundColor: Colors.white),
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty || descController.text.trim().isEmpty) {
                          EasyLoading.showError('Judul dan deskripsi wajib diisi');
                          return;
                        }
                        if (contentType == 'video' && videoUrlController.text.trim().isEmpty) {
                          EasyLoading.showError('URL video wajib diisi');
                          return;
                        }
                        final normalizedType =
                            contentType == 'video' ? 'video' : 'article';
                        final title = titleController.text.trim();
                        final description = descController.text.trim();
                        final payload = {
                          'title': title,
                          'description': description,
                          'type': normalizedType,
                          'Judul': title,
                          'Keterangan': description,
                          'tipeKonten': contentType,
                          'imageUrl': imageUrlController.text.trim(),
                          'videoUrl': videoUrlController.text.trim(),
                          'patientId': selectedPatient?.id ?? '',
                          'patientName': selectedPatient?.name ?? '',
                          'isGlobal': selectedPatient == null,
                          'createdBy': 'admin',
                          'authorRole': 'Admin',
                          'tanggalUpload': (data['tanggalUpload'] ?? _formattedNow()).toString(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        };
                        try {
                          if (doc == null) {
                            payload['createdAt'] = FieldValue.serverTimestamp();
                            await FirebaseFirestore.instance.collection('education_contents').add(payload);
                          } else {
                            await FirebaseFirestore.instance.collection('education_contents').doc(doc.id).update(payload);
                          }
                          if (mounted) Navigator.pop(context);
                          EasyLoading.showSuccess('Konten edukasi tersimpan');
                        } catch (e) {
                          EasyLoading.showError('Gagal menyimpan: $e');
                        }
                      },
                      child: const Text('Simpan Konten'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formattedNow() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteContent(String id) async {
    await FirebaseFirestore.instance.collection('education_contents').doc(id).delete();
    EasyLoading.showSuccess('Konten dihapus');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edukasi Kesehatan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff111827))),
                  SizedBox(height: 4),
                  Text('Tambah dan kelola artikel/video kesehatan', style: TextStyle(fontSize: 14, color: Color(0xff6b7280))),
                ],
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari konten', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _showContentDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah Konten', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2d4da7)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('education_contents').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Gagal memuat konten: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data();
              final haystack = '${data['Judul'] ?? ''} ${data['Keterangan'] ?? ''} ${data['patientName'] ?? ''}'.toLowerCase();
              return _searchQuery.isEmpty || haystack.contains(_searchQuery);
            }).toList();
            if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Belum ada konten edukasi')));
            return Container(
              decoration: BoxDecoration(border: Border.all(color: const Color(0xffe5e7eb)), borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final type = (data['tipeKonten'] ?? 'artikel').toString();
                  final patientName = (data['patientName'] ?? '').toString();
                  return ListTile(
                    leading: Icon(type == 'video' ? Icons.play_circle_outline : Icons.article_outlined, color: const Color(0xff2d4da7)),
                    title: Text((data['Judul'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${type == 'video' ? 'Video' : 'Artikel'} • ${patientName.isEmpty ? 'Global' : patientName}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showContentDialog(doc: doc)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteContent(doc.id)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
