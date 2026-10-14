import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admindiabetes/ViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';

class EducationContentPage extends StatefulWidget {
  const EducationContentPage({super.key});

  @override
  State<EducationContentPage> createState() => _EducationContentPageState();
}

class _EducationContentPageState extends State<EducationContentPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showContentDialog({DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final data = doc?.data() ?? <String, dynamic>{};
    final titleController = TextEditingController(text: data['title']?.toString() ?? data['Judul']?.toString() ?? '');
    final descController = TextEditingController(text: data['description']?.toString() ?? data['Keterangan']?.toString() ?? '');
    final urlController = TextEditingController(text: data['videoUrl']?.toString() ?? '');
    final imageUrlController = TextEditingController(text: data['imageUrl']?.toString() ?? '');
    String type = data['type']?.toString() == 'video' ? 'video' : 'article';
    PatientModel? selectedPatient;
    final existingPatientId = (data['patientId'] ?? '').toString();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(doc == null ? 'Tambah Edukasi Kesehatan' : 'Edit Edukasi Kesehatan'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jenis Konten', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(value: 'article', child: Text('Artikel Kesehatan')),
                        DropdownMenuItem(value: 'video', child: Text('Video Kesehatan')),
                      ],
                      onChanged: (value) => setDialogState(() => type = value ?? 'article'),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    const Text('Hubungkan ke Pasien (opsional)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('patients').snapshots(),
                      builder: (context, snapshot) {
                        final patients = snapshot.data?.docs
                            .map((doc) => PatientModel.fromFirestore(doc))
                            .where((patient) => patient.name.trim().isNotEmpty)
                            .toList() ?? <PatientModel>[];
                        patients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                        if (selectedPatient == null && existingPatientId.isNotEmpty) {
                          final matching = patients.where((patient) => patient.id == existingPatientId).toList();
                          if (matching.isNotEmpty) selectedPatient = matching.first;
                        }
                        return DropdownButtonFormField<String>(
                          value: selectedPatient?.id ?? '',
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(value: '', child: Text('Global / semua pasien')),
                            ...patients.map((patient) => DropdownMenuItem<String>(
                              value: patient.id,
                              child: Text('${patient.name}${patient.nik.isNotEmpty ? ' - ${patient.nik}' : ''}'),
                            )),
                          ],
                          onChanged: (value) => setDialogState(() {
                            selectedPatient = (value == null || value.isEmpty) ? null : patients.firstWhere((patient) => patient.id == value);
                          }),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Isi / Deskripsi', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Gambar (opsional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        labelText: 'Link Video (khusus video)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final description = descController.text.trim();
                  final videoUrl = urlController.text.trim();
                  if (title.isEmpty || description.isEmpty) {
                    EasyLoading.showError('Judul dan isi tidak boleh kosong');
                    return;
                  }
                  Navigator.pop(context);
                  await _saveContent(
                    docId: doc?.id,
                    type: type,
                    title: title,
                    description: description,
                    videoUrl: videoUrl,
                    imageUrl: imageUrlController.text.trim(),
                    patientId: selectedPatient?.id ?? '',
                    patientName: selectedPatient?.name ?? '',
                  );
                },
                child: Text(doc == null ? 'Tambah' : 'Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveContent({
    String? docId,
    required String type,
    required String title,
    required String description,
    required String videoUrl,
    required String imageUrl,
    required String patientId,
    required String patientName,
  }) async {
    try {
      EasyLoading.show(status: 'Menyimpan edukasi...');
      final nowText = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      final payload = <String, dynamic>{
        'type': type,
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'imageUrl': imageUrl,
        'patientId': patientId,
        'patientName': patientName,
        'isGlobal': patientId.isEmpty,
        'createdBy': 'admin',
        'Judul': title,
        'Keterangan': description,
        'tipeKonten': type,
        'tanggalUpload': nowText,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final ref = FirebaseFirestore.instance.collection('education_contents');
      if (docId == null) {
        await ref.add({...payload, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await ref.doc(docId).update(payload);
      }
      EasyLoading.showSuccess('Edukasi berhasil disimpan');
    } catch (e) {
      EasyLoading.showError('Gagal menyimpan edukasi: $e');
    }
  }

  Future<void> _deleteContent(String docId) async {
    try {
      EasyLoading.show(status: 'Menghapus edukasi...');
      await FirebaseFirestore.instance.collection('education_contents').doc(docId).delete();
      EasyLoading.showSuccess('Edukasi berhasil dihapus');
    } catch (e) {
      EasyLoading.showError('Gagal menghapus edukasi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edukasi Kesehatan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Tambah dan kelola artikel/video kesehatan', style: TextStyle(color: Color(0xff6b7280))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showContentDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Artikel / Video'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2d4da7), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Cari edukasi...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('education_contents').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('Gagal memuat edukasi: ${snapshot.error}');
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final title = (data['title'] ?? data['Judul'] ?? '').toString().toLowerCase();
                final desc = (data['description'] ?? data['Keterangan'] ?? '').toString().toLowerCase();
                return _query.isEmpty || title.contains(_query) || desc.contains(_query);
              }).toList();

              if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: Text('Belum ada edukasi kesehatan.'));

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final type = data['type']?.toString() == 'video' ? 'Video' : 'Artikel';
                  final title = data['title']?.toString() ?? data['Judul']?.toString() ?? '-';
                  final desc = data['description']?.toString() ?? data['Keterangan']?.toString() ?? '-';
                  return Card(
                    child: ListTile(
                      leading: Icon(type == 'Video' ? Icons.play_circle_outline : Icons.article_outlined, color: const Color(0xff2d4da7)),
                      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('$type • $desc', maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showContentDialog(doc: doc)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteContent(doc.id)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
