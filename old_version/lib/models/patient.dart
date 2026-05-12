class Patient {
  final int    id;
  final String fullName;
  final String nationalId;
  final String? gender;
  final int?   age;
  final String? bloodType;
  final String? phoneNumber;
  final List<String> chronicDiseases;
  final List<String> allergies;
  final List<String> currentMedications;

  Patient({
    required this.id,
    required this.fullName,
    required this.nationalId,
    this.gender,
    this.age,
    this.bloodType,
    this.phoneNumber,
    this.chronicDiseases     = const [],
    this.allergies           = const [],
    this.currentMedications  = const [],
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id:                 json['id']           ?? 0,
      fullName:           json['full_name']    ?? '',
      nationalId:         json['national_id']  ?? '',
      gender:             json['gender'],
      age:                json['age'],
      bloodType:          json['blood_type'],
      phoneNumber:        json['phone_number'],
      chronicDiseases:    _parseList(json['chronic_diseases']),
      allergies:          _parseList(json['allergies']),
      currentMedications: _parseList(json['current_medications']),
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String && value.isNotEmpty) {
      return value.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  String get genderAr {
    if (gender == null) return 'غير محدد';
    return gender!.toLowerCase() == 'male' ? 'ذكر' : 'أنثى';
  }

  String get bloodTypeDisplay => bloodType ?? '—';
}
