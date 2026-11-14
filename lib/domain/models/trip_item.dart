// Trip Countdown Domain Model for DayBook
// Supports airport IATA routes, countdown calculations, and widget snapshot generation.

class TripItem {
  final String id;
  final String originIata;
  final String destinationIata;
  final String destinationCity;
  final String? flightNumber;
  final DateTime departureTimeUtc;
  final DateTime? arrivalTimeUtc;
  final DateTime? boardingTimeUtc;
  final String timezoneOrigin;
  final String timezoneDestination;
  final String status; // 'scheduled', 'boarding', 'in_air', 'landed', 'cancelled'
  final String? notes;
  final bool isPinnedForWidget;
  final DateTime updatedAt;

  TripItem({
    required this.id,
    required this.originIata,
    required this.destinationIata,
    required this.destinationCity,
    this.flightNumber,
    required this.departureTimeUtc,
    this.arrivalTimeUtc,
    this.boardingTimeUtc,
    this.timezoneOrigin = 'Asia/Dhaka',
    this.timezoneDestination = 'Europe/London',
    this.status = 'scheduled',
    this.notes,
    this.isPinnedForWidget = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Duration get timeRemaining {
    final now = DateTime.now().toUtc();
    if (now.isAfter(departureTimeUtc)) {
      return Duration.zero;
    }
    return departureTimeUtc.difference(now);
  }

  bool get isDeparted => DateTime.now().toUtc().isAfter(departureTimeUtc);

  String get routeFormatted => '${originIata.toUpperCase()} ➔ ${destinationIata.toUpperCase()}';

  String get countdownFormatted {
    final remaining = timeRemaining;
    if (remaining.inSeconds <= 0) {
      return 'Departed / En Route';
    }
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m left';
    }
  }

  Map<String, dynamic> toWidgetSnapshot() {
    return {
      'tripId': id,
      'route': routeFormatted,
      'destination': destinationCity,
      'flightNum': flightNumber ?? '',
      'targetTimestamp': departureTimeUtc.millisecondsSinceEpoch ~/ 1000,
      'statusText': status.toUpperCase(),
      'countdownText': countdownFormatted,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originIata': originIata,
      'destinationIata': destinationIata,
      'destinationCity': destinationCity,
      'flightNumber': flightNumber,
      'departureTimeUtc': departureTimeUtc.toIso8601String(),
      'arrivalTimeUtc': arrivalTimeUtc?.toIso8601String(),
      'boardingTimeUtc': boardingTimeUtc?.toIso8601String(),
      'timezoneOrigin': timezoneOrigin,
      'timezoneDestination': timezoneDestination,
      'status': status,
      'notes': notes,
      'isPinnedForWidget': isPinnedForWidget,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TripItem.fromJson(Map<String, dynamic> json) {
    return TripItem(
      id: json['id'] as String,
      originIata: json['originIata'] as String,
      destinationIata: json['destinationIata'] as String,
      destinationCity: json['destinationCity'] as String,
      flightNumber: json['flightNumber'] as String?,
      departureTimeUtc: DateTime.parse(json['departureTimeUtc'] as String),
      arrivalTimeUtc: json['arrivalTimeUtc'] != null ? DateTime.parse(json['arrivalTimeUtc'] as String) : null,
      boardingTimeUtc: json['boardingTimeUtc'] != null ? DateTime.parse(json['boardingTimeUtc'] as String) : null,
      timezoneOrigin: json['timezoneOrigin'] as String? ?? 'Asia/Dhaka',
      timezoneDestination: json['timezoneDestination'] as String? ?? 'Europe/London',
      status: json['status'] as String? ?? 'scheduled',
      notes: json['notes'] as String?,
      isPinnedForWidget: json['isPinnedForWidget'] as bool? ?? false,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  TripItem copyWith({
    String? id,
    String? originIata,
    String? destinationIata,
    String? destinationCity,
    String? flightNumber,
    DateTime? departureTimeUtc,
    DateTime? arrivalTimeUtc,
    DateTime? boardingTimeUtc,
    String? timezoneOrigin,
    String? timezoneDestination,
    String? status,
    String? notes,
    bool? isPinnedForWidget,
    DateTime? updatedAt,
  }) {
    return TripItem(
      id: id ?? this.id,
      originIata: originIata ?? this.originIata,
      destinationIata: destinationIata ?? this.destinationIata,
      destinationCity: destinationCity ?? this.destinationCity,
      flightNumber: flightNumber ?? this.flightNumber,
      departureTimeUtc: departureTimeUtc ?? this.departureTimeUtc,
      arrivalTimeUtc: arrivalTimeUtc ?? this.arrivalTimeUtc,
      boardingTimeUtc: boardingTimeUtc ?? this.boardingTimeUtc,
      timezoneOrigin: timezoneOrigin ?? this.timezoneOrigin,
      timezoneDestination: timezoneDestination ?? this.timezoneDestination,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isPinnedForWidget: isPinnedForWidget ?? this.isPinnedForWidget,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
