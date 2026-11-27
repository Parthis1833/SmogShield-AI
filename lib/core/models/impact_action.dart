enum ImpactCategory { transport, domestic, lifestyle }

class ImpactBenchmark {
  const ImpactBenchmark({
    required this.mode,
    required this.emissionFactorKgCo2ePerKm,
    required this.description,
  });

  final String mode;
  final double emissionFactorKgCo2ePerKm;
  final String description;

  factory ImpactBenchmark.fromJson(Map<String, dynamic> json) {
    return ImpactBenchmark(
      mode: json['mode'] as String,
      emissionFactorKgCo2ePerKm:
          (json['emission_factor_kg_co2e_per_km'] as num).toDouble(),
      description: json['description'] as String,
    );
  }
}

class ImpactAction {
  const ImpactAction({
    required this.id,
    required this.title,
    this.description = '',
    this.category = ImpactCategory.transport,
    this.baselineMode = '',
    this.alternativeMode = '',
    this.distanceKm = 0.0,
    required this.co2eSavingsKg,
    this.formula = '',
    this.calculationFormula = '',
    this.assumptions = '',
    this.exposureNote = '',
    this.recordedAt,
    this.isLogged = false,
    this.loggedAt,
  });

  final String id;
  final String title;
  final String description;
  final ImpactCategory category;
  final String baselineMode;
  final String alternativeMode;
  final double distanceKm;
  final double co2eSavingsKg;
  final String formula;
  final String calculationFormula;
  final String assumptions;
  final String exposureNote;
  final DateTime? recordedAt;
  final bool isLogged;
  final DateTime? loggedAt;

  ImpactAction copyWith({
    String? id,
    String? title,
    String? description,
    ImpactCategory? category,
    String? baselineMode,
    String? alternativeMode,
    double? distanceKm,
    double? co2eSavingsKg,
    String? formula,
    String? calculationFormula,
    String? assumptions,
    String? exposureNote,
    DateTime? recordedAt,
    bool? isLogged,
    DateTime? loggedAt,
  }) {
    return ImpactAction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      baselineMode: baselineMode ?? this.baselineMode,
      alternativeMode: alternativeMode ?? this.alternativeMode,
      distanceKm: distanceKm ?? this.distanceKm,
      co2eSavingsKg: co2eSavingsKg ?? this.co2eSavingsKg,
      formula: formula ?? this.formula,
      calculationFormula: calculationFormula ?? this.calculationFormula,
      assumptions: assumptions ?? this.assumptions,
      exposureNote: exposureNote ?? this.exposureNote,
      recordedAt: recordedAt ?? this.recordedAt,
      isLogged: isLogged ?? this.isLogged,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  factory ImpactAction.fromJson(Map<String, dynamic> json) {
    return ImpactAction(
      id: json['id'] as String,
      title: json['title'] as String,
      baselineMode: json['baseline_mode'] as String? ?? '',
      alternativeMode: json['alternative_mode'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      co2eSavingsKg: (json['co2e_savings_kg'] as num).toDouble(),
      formula: json['formula'] as String? ?? '',
      calculationFormula: json['calculation_formula'] as String? ?? (json['formula'] as String? ?? ''),
      assumptions: json['assumptions'] as String? ?? '',
      exposureNote: json['exposure_note'] as String? ?? '',
      recordedAt: json['recorded_at'] != null ? DateTime.tryParse(json['recorded_at'] as String) : null,
    );
  }
}

class ImpactActionRequest {
  const ImpactActionRequest({
    required this.title,
    required this.baselineMode,
    required this.alternativeMode,
    required this.distanceKm,
  });

  final String title;
  final String baselineMode;
  final String alternativeMode;
  final double distanceKm;

  Map<String, Object> toJson() => {
        'title': title,
        'baseline_mode': baselineMode,
        'alternative_mode': alternativeMode,
        'distance_km': distanceKm,
      };
}
