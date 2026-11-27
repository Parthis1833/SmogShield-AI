import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/aqi_standards.dart';

class HourlyAqi {
  final int hour; // 0 - 23
  final int aqi;
  final double pm25;

  const HourlyAqi({
    required this.hour,
    required this.aqi,
    required this.pm25,
  });

  String get timeLabel {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h $ampm';
  }

  factory HourlyAqi.fromJson(Map<String, dynamic> json) {
    return HourlyAqi(
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      aqi: (json['aqi'] as num?)?.toInt() ?? 0,
      pm25: (json['pm25'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'aqi': aqi,
    'pm25': pm25,
  };
}

class AirQuality {
  const AirQuality({
    required this.city,
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.updatedAt,
    required this.source,
    required this.isMock,
    this.no2 = 42.0,
    this.so2 = 18.0,
    this.co = 1.4,
    this.o3 = 28.0,
    this.standard = 'IN_AQI',
    this.stationName = 'Central Continuous Monitoring Station',
    this.hourlyForecast = const [],
  });

  final String city;
  final int aqi;
  final double pm25;
  final double pm10;
  final double no2;
  final double so2;
  final double co;
  final double o3;
  final DateTime updatedAt;
  final String source;
  final bool isMock;
  final String standard;
  final String stationName;
  final List<HourlyAqi> hourlyForecast;

  /// Indian CPCB AQI Category presentation
  ///
  /// Breakpoints:
  /// - 0 - 50: Good
  /// - 51 - 100: Satisfactory
  /// - 101 - 200: Moderate
  /// - 201 - 300: Poor
  /// - 301 - 400: Very Poor
  /// - 401 - 500+: Severe
  String get category {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Satisfactory';
    if (aqi <= 200) return 'Moderate';
    if (aqi <= 300) return 'Poor';
    if (aqi <= 400) return 'Very Poor';
    return 'Severe';
  }

  /// Official CPCB Health Advisory for this AQI category
  String get healthAdvisory {
    switch (category) {
      case 'Good':
        return 'Air quality is considered satisfactory, and air pollution poses little or no risk.';
      case 'Satisfactory':
        return 'Minor breathing discomfort to sensitive people. Normal outdoor activity acceptable for most.';
      case 'Moderate':
        return 'May cause breathing discomfort to children, the elderly, and people with asthma or lung disease.';
      case 'Poor':
        return 'Breathing discomfort to most people on prolonged exposure. Limit vigorous outdoor exercise.';
      case 'Very Poor':
        return 'Respiratory illness on prolonged exposure. Significant risk for sensitive groups. Wear N95 outdoors.';
      case 'Severe':
      default:
        return 'Emergency conditions. Affects healthy people and severely impacts individuals with lung or heart disease.';
    }
  }

  /// Returns detailed category metadata based on Indian CPCB standards
  AqiCategoryInfo get categoryInfo => AqiStandardsHelper.getCategoryInfo(aqi);

  /// Returns official AQI warning color
  Color get categoryColor => AppColors.getAqiColor(aqi);

  /// Formatted observation timestamp for clear presentation
  String get formattedObservationTime {
    final formatter = DateFormat('dd MMM yyyy, hh:mm a');
    return '${formatter.format(updatedAt)} IST';
  }

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    List<HourlyAqi> forecast = [];
    final rawForecast = json['hourly_trend'] ?? json['hourlyForecast'];
    if (rawForecast is List) {
      forecast = rawForecast
          .map((item) => HourlyAqi.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    DateTime parsedDate;
    final rawDate = json['observed_at'] ?? json['updatedAt'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return AirQuality(
      city: json['city'] as String? ?? 'New Delhi',
      aqi: (json['aqi'] as num?)?.toInt() ?? 342,
      pm25: (json['pm25_ug_m3'] ?? json['pm25'] as num?)?.toDouble() ?? 184.0,
      pm10: (json['pm10_ug_m3'] ?? json['pm10'] as num?)?.toDouble() ?? 276.0,
      no2: (json['no2_ug_m3'] ?? json['no2'] as num?)?.toDouble() ?? 42.0,
      so2: (json['so2_ug_m3'] ?? json['so2'] as num?)?.toDouble() ?? 18.0,
      co: (json['co_mg_m3'] ?? json['co'] as num?)?.toDouble() ?? 1.4,
      o3: (json['o3_ug_m3'] ?? json['o3'] as num?)?.toDouble() ?? 28.0,
      updatedAt: parsedDate,
      source: json['source'] as String? ?? 'Central Continuous Monitoring (CPCB Simulated)',
      isMock: json['is_mock'] ?? json['isMock'] ?? true,
      standard: json['aqi_standard'] ?? json['standard'] ?? 'IN_AQI',
      stationName: json['station_name'] ?? json['stationName'] ?? 'Central Continuous Monitoring Station',
      hourlyForecast: forecast,
    );
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    'aqi': aqi,
    'category': category,
    'pm25_ug_m3': pm25,
    'pm10_ug_m3': pm10,
    'no2_ug_m3': no2,
    'so2_ug_m3': so2,
    'co_mg_m3': co,
    'o3_ug_m3': o3,
    'observed_at': updatedAt.toIso8601String(),
    'source': source,
    'is_mock': isMock,
    'aqi_standard': standard,
    'station_name': stationName,
    'health_advisory': healthAdvisory,
    'hourly_trend': hourlyForecast.map((f) => f.toJson()).toList(),
  };

  AirQuality copyWith({
    String? city,
    int? aqi,
    double? pm25,
    double? pm10,
    double? no2,
    double? so2,
    double? co,
    double? o3,
    DateTime? updatedAt,
    String? source,
    bool? isMock,
    String? standard,
    String? stationName,
    List<HourlyAqi>? hourlyForecast,
  }) {
    return AirQuality(
      city: city ?? this.city,
      aqi: aqi ?? this.aqi,
      pm25: pm25 ?? this.pm25,
      pm10: pm10 ?? this.pm10,
      no2: no2 ?? this.no2,
      so2: so2 ?? this.so2,
      co: co ?? this.co,
      o3: o3 ?? this.o3,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      isMock: isMock ?? this.isMock,
      standard: standard ?? this.standard,
      stationName: stationName ?? this.stationName,
      hourlyForecast: hourlyForecast ?? this.hourlyForecast,
    );
  }
}
