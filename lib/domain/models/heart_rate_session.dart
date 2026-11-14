// Bluetooth Heart Rate & Physiological Telemetry Domain Models (Page 05)
// Compliant with Bluetooth SIG Heart Rate Service (0x180D) & Characteristic (0x2A37).

enum HeartRateZone {
  zone1('Zone 1', 'Recovery', '<60% HRmax', 0.50, 0.60),
  zone2('Zone 2', 'Aerobic Base', '60–70% HRmax', 0.60, 0.70),
  zone3('Zone 3', 'Tempo / Power', '70–80% HRmax', 0.70, 0.80),
  zone4('Zone 4', 'Threshold', '80–90% HRmax', 0.80, 0.90),
  zone5('Zone 5', 'Anaerobic Max', '>90% HRmax', 0.90, 1.00);

  final String label;
  final String title;
  final String description;
  final double lowerRatio;
  final double upperRatio;
  const HeartRateZone(this.label, this.title, this.description, this.lowerRatio, this.upperRatio);
}

class BpmSample {
  final DateTime timestamp;
  final int bpm;

  const BpmSample({required this.timestamp, required this.bpm});

  Map<String, dynamic> toJson() => {
        'ts': timestamp.millisecondsSinceEpoch,
        'bpm': bpm,
      };

  factory BpmSample.fromJson(Map<String, dynamic> json) => BpmSample(
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
        bpm: json['bpm'] as int,
      );
}

class WorkoutSessionRecord {
  final String id;
  final String deviceName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final int avgBpm;
  final int maxBpm;
  final int minBpm;
  final Map<HeartRateZone, int> zoneSeconds;
  final List<BpmSample> samples;

  WorkoutSessionRecord({
    required this.id,
    required this.deviceName,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.avgBpm = 0,
    this.maxBpm = 0,
    this.minBpm = 0,
    Map<HeartRateZone, int>? zoneSeconds,
    this.samples = const [],
  }) : zoneSeconds = zoneSeconds ?? {
          HeartRateZone.zone1: 0,
          HeartRateZone.zone2: 0,
          HeartRateZone.zone3: 0,
          HeartRateZone.zone4: 0,
          HeartRateZone.zone5: 0,
        };

  static HeartRateZone classifyZone(int bpm, {int maxHr = 190}) {
    final ratio = bpm / maxHr;
    if (ratio >= 0.90) return HeartRateZone.zone5;
    if (ratio >= 0.80) return HeartRateZone.zone4;
    if (ratio >= 0.70) return HeartRateZone.zone3;
    if (ratio >= 0.60) return HeartRateZone.zone2;
    return HeartRateZone.zone1;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceName': deviceName,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'durationSeconds': durationSeconds,
        'avgBpm': avgBpm,
        'maxBpm': maxBpm,
        'minBpm': minBpm,
        'zoneSeconds': zoneSeconds.map((k, v) => MapEntry(k.name, v)),
        'samplesCount': samples.length,
      };

  factory WorkoutSessionRecord.fromJson(Map<String, dynamic> json) {
    final zonesMap = <HeartRateZone, int>{};
    final rawZones = json['zoneSeconds'] as Map<String, dynamic>?;
    if (rawZones != null) {
      for (final zone in HeartRateZone.values) {
        zonesMap[zone] = rawZones[zone.name] as int? ?? 0;
      }
    }
    return WorkoutSessionRecord(
      id: json['id'] as String,
      deviceName: json['deviceName'] as String? ?? 'BLE Heart Rate Strap',
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      avgBpm: json['avgBpm'] as int? ?? 0,
      maxBpm: json['maxBpm'] as int? ?? 0,
      minBpm: json['minBpm'] as int? ?? 0,
      zoneSeconds: zonesMap,
    );
  }
}
