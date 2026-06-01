class LaborLog {
  final int id;
  final int workerId;
  final String? workerName;
  final int days;
  final int hours;
  final double manDays;
  final List<String> crafts; // 'borci', 'embroidery', 'fitting', 'alteration'
  final String description;
  final DateTime createdAt;

  LaborLog({
    required this.id,
    required this.workerId,
    this.workerName,
    required this.days,
    required this.hours,
    required this.manDays,
    required this.crafts,
    required this.description,
    required this.createdAt,
  });

  factory LaborLog.fromJson(Map<String, dynamic> json) {
    return LaborLog(
      id: json['id'] as int,
      workerId: json['worker_id'] as int,
      workerName: json['worker_name'] as String?,
      days: json['days'] as int,
      hours: json['hours'] as int,
      manDays: double.parse(json['man_days'].toString()),
      crafts: List<String>.from(json['crafts'] ?? []),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
