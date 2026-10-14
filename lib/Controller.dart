import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminPatientSearchController extends GetxController {
  // 1. Variabel reaktif (.obs) untuk menyimpan teks yang sedang diketik di Search Bar.
  // Setiap huruf yang diketik user akan langsung merubah nilai ini secara realtime.
  var searchQuery = ''.obs;

  // 2. Variabel reaktif untuk menampilkan teks status kapan data terakhir diperbarui.
  var lastUpdateTime = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Saat aplikasi pertama kali dibuka, langsung catat waktu saat ini
    updateTimeNow();
  }

  // 3. Fungsi untuk mengambil jam & tanggal dari device saat ini menggunakan format Indonesia.
  void updateTimeNow() {
    lastUpdateTime.value = DateFormat('dd MMMM yyyy HH:mm', 'id').format(DateTime.now());
  }

  final TextEditingController textController = TextEditingController();

  // Fungsi untuk mengupdate query saat admin mengetik
  void updateQuery(String text) {
    searchQuery.value = text;
  }

  // Fungsi untuk membersihkan search bar jika dibutuhkan
  void clearSearch() {
    textController.clear();
    searchQuery.value = '';
  }

  @override
  void onClose() {
    textController.dispose();
    super.dispose();
  }
}