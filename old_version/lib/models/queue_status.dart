class QueueStatus {
  final int    queueId;
  final int    doctorId;
  final String doctorName;
  final String? specialty;
  final String? specialtyAr;
  final int    position;
  final String status;
  final int    estimatedWaitMinutes;
  final int    patientsAhead;
  final DateTime joinTime;
  final String? floorNumber;
  final String? roomNumber;

  QueueStatus({
    required this.queueId,
    required this.doctorId,
    required this.doctorName,
    this.specialty,
    this.specialtyAr,
    required this.position,
    required this.status,
    required this.estimatedWaitMinutes,
    required this.patientsAhead,
    required this.joinTime,
    this.floorNumber,
    this.roomNumber,
  });

  factory QueueStatus.fromJson(Map<String, dynamic> json) {
    return QueueStatus(
      queueId:               json['queue_id']               ?? 0,
      doctorId:              json['doctor_id']              ?? 0,
      doctorName:            json['doctor_name']            ?? 'غير محدد',
      specialty:             json['specialty'],
      specialtyAr:           json['specialty_ar'],
      position:              json['position']               ?? 0,
      status:                json['status']                 ?? 'waiting',
      estimatedWaitMinutes:  json['estimated_wait_minutes'] ?? 0,
      patientsAhead:         json['patients_ahead']         ?? 0,
      joinTime: DateTime.tryParse(json['join_time'] ?? '') ?? DateTime.now(),
      floorNumber:           json['floor_number']?.toString(),
      roomNumber:            json['room_number'],
    );
  }

  bool get isWaiting        => status == 'waiting';
  bool get isCalled         => status == 'called';
  bool get isInConsultation => status == 'in_consultation';
  bool get isCompleted      => status == 'completed';

  String get statusLabel {
    switch (status) {
      case 'waiting':         return 'في الانتظار';
      case 'called':          return 'تم الاستدعاء';
      case 'in_consultation': return 'في الكشف';
      case 'completed':       return 'انتهى';
      default:                return status;
    }
  }

  String get locationText {
    if (floorNumber != null && roomNumber != null) {
      return 'الدور $floorNumber  •  غرفة $roomNumber';
    } else if (roomNumber != null) {
      return 'غرفة $roomNumber';
    }
    return 'الموقع غير محدد';
  }
}
