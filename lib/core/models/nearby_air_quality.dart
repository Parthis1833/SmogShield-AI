class PollutantReading {
  const PollutantReading({
    required this.value,
    required this.unit,
    required this.observedAt,
  });

  final double? value;
  final String? unit;
  final DateTime? observedAt;

  factory PollutantReading.fromJson(Map<String, dynamic> json) {
    final rawValue = json['value'];
    final rawTime = json['observed_at'];
    return PollutantReading(
      value: rawValue is num ? rawValue.toDouble() : null,
      unit: json['unit'] as String?,
      observedAt: rawTime is String ? DateTime.tryParse(rawTime) : null,
    );
  }
}

class AirQualityLocation {
  const AirQualityLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.country,
    this.displayName,
  });

  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? displayName;

  factory AirQualityLocation.fromJson(Map<String, dynamic> json) {
    return AirQualityLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      displayName: json['display_name'] as String?,
    );
  }
}

class NearbyAirQuality {
  const NearbyAirQuality({
    required this.found,
    required this.status,
    required this.source,
    required this.dataStatus,
    required this.requestedLocation,
    required this.isCached,
    required this.cacheAgeSeconds,
    required this.searchRadiusKm,
    required this.providerError,
    required this.noDataReason,
    required this.locationId,
    required this.stationName,
    required this.stationLatitude,
    required this.stationLongitude,
    required this.distanceKm,
    required this.provider,
    required this.observedAt,
    required this.freshness,
    required this.freshestAgeMinutes,
    required this.pollutants,
    required this.recommendations,
    required this.recommendationEngine,
    required this.recommendationsAreMock,
  });

  final bool found;
  final String status;
  final String source;
  final String dataStatus;
  final AirQualityLocation? requestedLocation;
  final bool isCached;
  final double cacheAgeSeconds;
  final int? searchRadiusKm;
  final String? providerError;
  final String? noDataReason;
  final String? locationId;
  final String? stationName;
  final double? stationLatitude;
  final double? stationLongitude;
  final double? distanceKm;
  final String? provider;
  final DateTime? observedAt;
  final String? freshness;
  final double? freshestAgeMinutes;
  final Map<String, PollutantReading> pollutants;
  final List<String> recommendations;
  final String? recommendationEngine;
  final bool recommendationsAreMock;

  factory NearbyAirQuality.fromJson(Map<String, dynamic> json) {
    final pollutantData = json['pollutants'];
    final rawPollutants = pollutantData is Map && pollutantData.isNotEmpty
        ? pollutantData
        : json['measurements'];
    final pollutants = <String, PollutantReading>{};
    if (rawPollutants is Map<String, dynamic>) {
      for (final entry in rawPollutants.entries) {
        if (entry.value is Map<String, dynamic>) {
          pollutants[entry.key] = PollutantReading.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }
    }

    final rawRecommendations = json['recommendations'];
    final rawRequestedLocation = json['requested_location'];
    final rawStation = json['station'];
    return NearbyAirQuality(
      found: json['found'] == true,
      status: json['status'] as String? ??
          (json['found'] == true ? 'success' : 'no_data'),
      source: json['source'] as String? ?? 'OpenAQ',
      dataStatus: json['data_status'] as String? ?? 'nearest_station',
      requestedLocation: rawRequestedLocation is Map<String, dynamic>
          ? AirQualityLocation.fromJson(rawRequestedLocation)
          : null,
      isCached: json['is_cached'] == true,
      cacheAgeSeconds: (json['cache_age_seconds'] as num?)?.toDouble() ?? 0,
      searchRadiusKm: (json['search_radius_km'] as num?)?.toInt(),
      providerError: json['provider_error'] as String?,
      noDataReason: json['no_data_reason'] as String?,
      locationId: rawStation is Map<String, dynamic>
          ? rawStation['id']?.toString()
          : json['location_id'] as String?,
      stationName: rawStation is Map<String, dynamic>
          ? rawStation['name'] as String?
          : json['station_name'] as String?,
      stationLatitude: rawStation is Map<String, dynamic>
          ? (rawStation['latitude'] as num?)?.toDouble()
          : (json['station_latitude'] as num?)?.toDouble(),
      stationLongitude: rawStation is Map<String, dynamic>
          ? (rawStation['longitude'] as num?)?.toDouble()
          : (json['station_longitude'] as num?)?.toDouble(),
      distanceKm: rawStation is Map<String, dynamic>
          ? (rawStation['distance_km'] as num?)?.toDouble()
          : (json['distance_km'] as num?)?.toDouble(),
      provider: json['provider'] as String?,
      observedAt: json['observed_at'] is String
          ? DateTime.tryParse(json['observed_at'] as String)
          : null,
      freshness: json['freshness'] as String?,
      freshestAgeMinutes: (json['freshest_age_minutes'] as num?)?.toDouble(),
      pollutants: pollutants,
      recommendations: rawRecommendations is List
          ? rawRecommendations.whereType<String>().toList()
          : const [],
      recommendationEngine: json['recommendation_engine'] as String?,
      recommendationsAreMock: json['recommendations_is_mock'] != false,
    );
  }
}
