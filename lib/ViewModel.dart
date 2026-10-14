class PatientModel {
  final String id;
  final String nik;
  final String name;
  final String gender;
  final String age;
  final String email;
  final String phone;
  final String lastCheckDate;
  final String appointmentDate;
  final String appointmentCount;
  final String gdp;
  final String gd2pp;
  final String hba1c;
  final String medicineTimes;
  final String medicineNames;

  PatientModel({
    required this.id,
    required this.nik,
    required this.name,
    required this.gender,
    required this.age,
    required this.email,
    required this.phone,
    required this.lastCheckDate,
    required this.appointmentDate,
    required this.appointmentCount,
    required this.gdp,
    required this.gd2pp,
    required this.hba1c,
    required this.medicineTimes, // 2. MASUKKAN CONSTRUCTOR
    required this.medicineNames,
  });

  factory PatientModel.fromFirestore(var doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    String asString(dynamic value, {String fallback = ''}) {
      if (value == null) return fallback;
      if (value is String) return value;
      return value.toString();
    }

    return PatientModel(
      id: doc.id,
      nik: asString(data['nik']),
      name: asString(data['name']),
      gender: asString(data['gender']),
      age: asString(data['age'], fallback: '0'),
      email: asString(data['email']),
      phone: asString(data['phone']),
      lastCheckDate: asString(data['lastCheckDate']),
      appointmentDate: asString(data['appointmentDate']),
      appointmentCount: asString(data['appointmentCount'], fallback: '0'),
      gdp: asString(data['gdp'], fallback: '0'),
      gd2pp: asString(data['gd2pp'], fallback: '0'),
      hba1c: asString(data['hba1c'], fallback: '0'),
      // 3. MAPPING DARI FIRESTORE (Default set '-' kalau kosong) 👇
      medicineTimes: asString(data['medicineTimes'], fallback: '-'),
      medicineNames: asString(data['medicineNames'], fallback: '-'),
    );
  }
}