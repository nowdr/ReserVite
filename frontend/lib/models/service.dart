class Service {
  final int id;
  final int? restaurant;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  Service({
    required this.id,
    this.restaurant,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      restaurant: json['restaurant'],
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }
}
