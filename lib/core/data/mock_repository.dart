import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/aqi_standards.dart';
import '../models/air_quality.dart';
import '../models/community_challenge.dart';
import '../models/family_profile.dart';
import '../models/impact_action.dart';
import '../models/indoor_tip.dart';
import '../models/routine_item.dart';

// Re-export repository contracts and RoutineItem for backward compatibility
export '../models/routine_item.dart';
export '../theme/theme_controller.dart';
export 'air_quality_repository.dart';
export 'fastapi_air_quality_repository.dart';
export 'routine_repository.dart';
import 'air_quality_repository.dart';
import 'fastapi_air_quality_repository.dart';
import 'routine_repository.dart';

class MockAirQualityRepository implements AirQualityRepository {
  static final Map<String, AirQuality> _mockCityData = {
    'New Delhi': AirQuality(
      city: 'New Delhi',
      aqi: 342,
      pm25: 184.0,
      pm10: 276.0,
      no2: 84.5,
      so2: 24.2,
      co: 2.8,
      o3: 38.0,
      updatedAt: DateTime(2026, 11, 17, 8, 0),
      source: 'Central Continuous Monitoring (CPCB Simulated)',
      stationName: 'Anand Vihar Clean Air Station',
      isMock: true,
      standard: 'IN_AQI',
      hourlyForecast: const [
        HourlyAqi(hour: 0, aqi: 310, pm25: 160),
        HourlyAqi(hour: 3, aqi: 325, pm25: 172),
        HourlyAqi(hour: 6, aqi: 355, pm25: 195),
        HourlyAqi(hour: 8, aqi: 375, pm25: 210), // Morning peak inversion
        HourlyAqi(hour: 11, aqi: 330, pm25: 175),
        HourlyAqi(
            hour: 14, aqi: 280, pm25: 145), // Solar heating / dispersion dip
        HourlyAqi(hour: 17, aqi: 310, pm25: 168),
        HourlyAqi(hour: 20, aqi: 360, pm25: 202), // Evening peak
        HourlyAqi(hour: 23, aqi: 335, pm25: 180),
      ],
    ),
    'Lahore': AirQuality(
      city: 'Lahore',
      aqi: 385,
      pm25: 220.0,
      pm10: 315.0,
      no2: 92.0,
      so2: 28.0,
      co: 3.1,
      o3: 42.0,
      updatedAt: DateTime(2026, 11, 17, 8, 0),
      source: 'Punjab EPA Monitoring (Simulated)',
      stationName: 'The Mall Observatory',
      isMock: true,
      standard: 'IN_AQI',
      hourlyForecast: const [
        HourlyAqi(hour: 0, aqi: 340, pm25: 185),
        HourlyAqi(hour: 4, aqi: 365, pm25: 205),
        HourlyAqi(hour: 8, aqi: 410, pm25: 245),
        HourlyAqi(hour: 12, aqi: 360, pm25: 195),
        HourlyAqi(hour: 16, aqi: 330, pm25: 175),
        HourlyAqi(hour: 20, aqi: 395, pm25: 230),
      ],
    ),
    'Beijing': AirQuality(
      city: 'Beijing',
      aqi: 115,
      pm25: 41.5,
      pm10: 82.0,
      no2: 38.0,
      so2: 12.0,
      co: 1.1,
      o3: 55.0,
      updatedAt: DateTime(2026, 11, 17, 8, 0),
      source: 'Municipal Environmental Monitoring (Simulated)',
      stationName: 'Chaoyang Olympic Park',
      isMock: true,
      standard: 'IN_AQI',
      hourlyForecast: const [
        HourlyAqi(hour: 0, aqi: 95, pm25: 32),
        HourlyAqi(hour: 6, aqi: 125, pm25: 45),
        HourlyAqi(hour: 12, aqi: 110, pm25: 39),
        HourlyAqi(hour: 18, aqi: 130, pm25: 48),
      ],
    ),
    'Mumbai': AirQuality(
      city: 'Mumbai',
      aqi: 142,
      pm25: 56.0,
      pm10: 110.0,
      no2: 45.0,
      so2: 15.0,
      co: 1.2,
      o3: 32.0,
      updatedAt: DateTime(2026, 11, 17, 8, 0),
      source: 'MPCB Air Monitoring Network (Simulated)',
      stationName: 'Bandra Kurla Complex',
      isMock: true,
      standard: 'IN_AQI',
      hourlyForecast: const [
        HourlyAqi(hour: 0, aqi: 120, pm25: 45),
        HourlyAqi(hour: 6, aqi: 150, pm25: 60),
        HourlyAqi(hour: 12, aqi: 135, pm25: 52),
        HourlyAqi(hour: 18, aqi: 145, pm25: 58),
      ],
    ),
    'New York': AirQuality(
      city: 'New York',
      aqi: 36,
      pm25: 8.5,
      pm10: 16.0,
      no2: 18.0,
      so2: 4.0,
      co: 0.4,
      o3: 24.0,
      updatedAt: DateTime(2026, 11, 17, 8, 0),
      source: 'DEC Air Quality Monitoring (Simulated)',
      stationName: 'Central Park Station',
      isMock: true,
      standard: 'US_AQI',
      hourlyForecast: const [
        HourlyAqi(hour: 0, aqi: 30, pm25: 7),
        HourlyAqi(hour: 6, aqi: 42, pm25: 10),
        HourlyAqi(hour: 12, aqi: 35, pm25: 8),
        HourlyAqi(hour: 18, aqi: 38, pm25: 9),
      ],
    ),
    'London': AirQuality(
      city: 'London',
      aqi: 28,
      pm25: 6.8,
      pm10: 14.0,
      no2: 22.0,
      so2: 3.5,
      co: 0.3,
      o3: 20.0,
      updatedAt: DateTime(2026, 11, 17, 8, 0),
      source: 'London Air Quality Network (Simulated)',
      stationName: 'Westminster Observatory',
      isMock: true,
      standard: 'US_AQI',
      hourlyForecast: const [
        HourlyAqi(hour: 0, aqi: 24, pm25: 5),
        HourlyAqi(hour: 6, aqi: 32, pm25: 8),
        HourlyAqi(hour: 12, aqi: 26, pm25: 6),
        HourlyAqi(hour: 18, aqi: 30, pm25: 7),
      ],
    ),
  };

  @override
  Future<AirQuality> load() async => _mockCityData['New Delhi']!;

  @override
  Future<AirQuality> loadCity(String city) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final quality = _mockCityData[city];
    if (quality == null) {
      throw AirQualityRepositoryException(
        'No demonstration data is available for $city.',
        statusCode: 404,
      );
    }
    return quality;
  }

  @override
  List<String> getAvailableCities() => _mockCityData.keys.toList();

  @override
  Future<List<HourlyAqi>> getHourlyForecast(String city) async {
    final quality = await loadCity(city);
    return quality.hourlyForecast;
  }

  @override
  Future<bool> checkHealth() async => true;
}

// Global Providers
final airQualityRepositoryProvider = Provider<AirQualityRepository>(
  (ref) => FastApiAirQualityRepository(),
);

final fastApiAirQualityRepositoryProvider = Provider<AirQualityRepository>(
  (ref) => FastApiAirQualityRepository(),
);

class SelectedCityNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setCity(String city) {
    state = city;
  }
}

final selectedCityProvider =
    NotifierProvider<SelectedCityNotifier, String>(SelectedCityNotifier.new);

final airQualityProvider = FutureProvider<AirQuality>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final repo = ref.watch(airQualityRepositoryProvider);
  return repo.loadCity(city);
});

// AQI Standard Selection Notifier
class AqiStandardNotifier extends Notifier<AqiStandard> {
  @override
  AqiStandard build() => AqiStandard.indianCpcb;

  void setStandard(AqiStandard standard) {
    state = standard;
  }
}

final aqiStandardProvider =
    NotifierProvider<AqiStandardNotifier, AqiStandard>(AqiStandardNotifier.new);

// Routine Repository Provider
final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => FastApiRoutineRepository(),
);

// Backward compatible mockRoutine list
const mockRoutine = <RoutineItem>[
  RoutineItem(
    id: 'morning_exercise',
    time: '7:00 AM',
    timePeriod: 'Morning',
    title: 'Exercise indoors',
    detail:
        'Replace outdoor jogging or running with indoor stretching, yoga, or indoor cardio in a HEPA-filtered room.',
    reason:
        'Heavy breathing outdoors during morning surface temperature inversions increases pulmonary particle deposition by up to 400%.',
    category: RoutineCategory.exercise,
    targetAudience: 'All Family Members',
  ),
  RoutineItem(
    id: 'morning_commute',
    time: '8:30 AM',
    timePeriod: 'Morning',
    title: 'Protected low-emission commute',
    detail:
        'Use electrified metro or mass transit. In personal vehicles, keep windows sealed with AC on internal recirculation. Wear a certified N95 respirator during roadside walking.',
    reason:
        'Roadside sidewalks and vehicles without internal air recirculation draw concentrated vehicular exhaust and coarse resuspended road dust directly into breathing zones.',
    category: RoutineCategory.commute,
    targetAudience: 'Working Adults & Students',
  ),
  RoutineItem(
    id: 'afternoon_indoor_air',
    time: '1:00 PM',
    timePeriod: 'Afternoon',
    title: 'Midday indoor air check & hygiene',
    detail:
        'If indoor CO₂ feels elevated, perform a brief 10-minute cross-ventilation during peak solar dispersion (1–3 PM), then immediately reseal windows and run the purifier on high for 20 minutes.',
    reason:
        'Surface thermal inversion weakens in early afternoon due to solar warming, creating the safest window for necessary air exchange.',
    category: RoutineCategory.indoor,
    targetAudience: 'Home & Office',
  ),
  RoutineItem(
    id: 'evening_family_time',
    time: '6:00 PM',
    timePeriod: 'Evening',
    title: 'Transition children & family play indoors',
    detail:
        'Move children’s active recreation inside. Avoid lighting incense (agarbatti), dhoop, scented candles, or unvented indoor combustion.',
    reason:
        'Late afternoon cools the ground rapidly, re-establishing the surface inversion layer that traps evening traffic and domestic emissions near breathing height.',
    category: RoutineCategory.evening,
    targetAudience: 'Children & Elderly',
  ),
  RoutineItem(
    id: 'night_filtration',
    time: '10:00 PM',
    timePeriod: 'Night',
    title: 'Bedroom clean-air sanctuary setup',
    detail:
        'Keep bedroom doors and windows shut with HEPA purifier set to quiet continuous mode.',
    reason:
        'During 7 to 8 hours of uninterrupted sleep, clean indoor air prevents sustained particulate irritation of mucosal linings and bronchial airways.',
    category: RoutineCategory.indoor,
    targetAudience: 'All Family Members',
  ),
];

// Routine Notifier
class RoutineNotifier extends Notifier<List<RoutineItem>> {
  @override
  List<RoutineItem> build() => mockRoutine;

  void toggleCompleted(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(isCompleted: !item.isCompleted)
        else
          item,
    ];
  }

  void resetRoutines() {
    state = mockRoutine;
  }
}

final routineProvider =
    NotifierProvider<RoutineNotifier, List<RoutineItem>>(RoutineNotifier.new);

// Impact Actions
const initialImpactActions = <ImpactAction>[
  ImpactAction(
    id: 'metro_transit',
    title: 'Take Electric Metro instead of Solo Car',
    description:
        'Replaced a 12 km daily commute in a solo petrol car with electric mass transit.',
    category: ImpactCategory.transport,
    co2eSavingsKg: 1.32,
    calculationFormula:
        '12 km × (0.18 kg CO₂e/km [car] − 0.07 kg CO₂e/km [transit]) = 1.32 kg CO₂e',
    assumptions:
        'Assumes average urban compact petrol car vs electrified metro per passenger km.',
    exposureNote:
        'Exposure note: Underground stations may have elevated coarse dust; wear N95 in transit if sensitive.',
  ),
  ImpactAction(
    id: 'carpool_trip',
    title: 'Carpool with 3 Neighbors',
    description:
        'Combined two school and grocery runs into a single shared vehicle journey (8 km).',
    category: ImpactCategory.transport,
    co2eSavingsKg: 0.96,
    calculationFormula:
        '8 km × 0.18 kg CO₂e/km × (2 vehicles avoided) / 3 passengers = 0.96 kg CO₂e',
    assumptions: 'Reduces net vehicle trips in residential smog hotspot.',
    exposureNote:
        'Exposure note: Keep vehicle cabin air recirculating with a fresh cabin filter.',
  ),
  ImpactAction(
    id: 'wfh_day',
    title: 'Work Remotely / Avoid Commute',
    description:
        'Avoided a 20 km round-trip drive by working from home during peak smog day.',
    category: ImpactCategory.transport,
    co2eSavingsKg: 3.60,
    calculationFormula:
        '20 km × 0.18 kg CO₂e/km = 3.60 kg CO₂e avoided entirely',
    assumptions:
        'Eliminates peak-hour tailpipe emissions during temperature inversion.',
    exposureNote:
        'Exposure note: Staying indoors reduces roadside particle inhalation by ~60% if windows are sealed.',
  ),
  ImpactAction(
    id: 'avoid_open_burning',
    title: 'Dispose Garden/Kitchen Waste Without Burning',
    description:
        'Composted dry winter leaves and yard trimmings instead of open burn piles.',
    category: ImpactCategory.domestic,
    co2eSavingsKg: 2.50,
    calculationFormula:
        'Estimated 5 kg biomass burning prevented × 0.50 kg CO₂e/kg biomass = 2.50 kg CO₂e',
    assumptions:
        'Prevents direct ground-level release of black carbon, VOCs, and PM2.5.',
    exposureNote:
        'Direct community benefit: Open burning creates immediate hazardous plumes in neighborhoods.',
  ),
  ImpactAction(
    id: 'induction_cooking',
    title: 'Cook with Induction / Electric Range',
    description:
        'Used induction cooktop with active ducted vent rather than unvented biomass/gas burning.',
    category: ImpactCategory.domestic,
    co2eSavingsKg: 0.85,
    calculationFormula:
        'Replaces 45 minutes of fossil gas burner combustion with clean electric heating.',
    assumptions:
        'Gas cooking produces indoor NO₂ spikes exceeding 100 µg/m³ without strong exhaust.',
    exposureNote:
        'Indoor exposure: Drastically cuts indoor NO₂ and ultra-fine particles inside family living spaces.',
  ),
];

class ImpactNotifier extends Notifier<List<ImpactAction>> {
  @override
  List<ImpactAction> build() => initialImpactActions;

  void toggleAction(String id) {
    state = [
      for (final a in state)
        if (a.id == id)
          a.copyWith(
            isLogged: !a.isLogged,
            loggedAt: !a.isLogged ? DateTime.now() : null,
          )
        else
          a,
    ];
  }

  double get totalSavings => state
      .where((a) => a.isLogged)
      .fold<double>(0.0, (acc, item) => acc + item.co2eSavingsKg);

  int get loggedCount => state.where((a) => a.isLogged).length;
}

final impactProvider =
    NotifierProvider<ImpactNotifier, List<ImpactAction>>(ImpactNotifier.new);

// Family Profile Notifier
class FamilyProfileNotifier extends Notifier<FamilyProfile> {
  @override
  FamilyProfile build() => const FamilyProfile();

  void updateProfile(FamilyProfile updated) {
    state = updated;
  }

  void setCity(String city) {
    state = state.copyWith(city: city);
  }

  void updateMembers(
      {int? adults, int? children, int? seniors, bool? hasVulnerable}) {
    state = state.copyWith(
      adultsCount: adults ?? state.adultsCount,
      childrenCount: children ?? state.childrenCount,
      seniorsCount: seniors ?? state.seniorsCount,
      hasVulnerableMember: hasVulnerable ?? state.hasVulnerableMember,
    );
  }

  void setCommute(String mode) {
    state = state.copyWith(primaryCommuteMode: mode);
  }

  void setAirSetup(String setup) {
    state = state.copyWith(airPurificationSetup: setup);
  }

  void toggleAlerts(bool value) {
    state = state.copyWith(alertOnSpikes: value);
  }
}

final familyProfileProvider =
    NotifierProvider<FamilyProfileNotifier, FamilyProfile>(
        FamilyProfileNotifier.new);

// Indoor Air Tips Data
const mockIndoorTips = <IndoorTip>[
  IndoorTip(
    id: 'hepa_purifiers',
    title: 'True HEPA (H13) Filtration',
    summary:
        'Captures 99.97% of PM2.5, pollen, and airborne particles down to 0.3 microns.',
    detailedExplanation:
        'Ensure the clean air delivery rate (CADR) matches your room volume. Keep doors and windows closed in the filtered room to prevent continuous outdoor particle infiltration.',
    category: IndoorCategory.filtration,
    scientificBasis:
        'Standardized ISO 29463 and EN 1822 mechanical particle filtration efficiency.',
    isDoItem: true,
  ),
  IndoorTip(
    id: 'timing_ventilation',
    title: 'Ventilate Only During Midday Solar Dispersion',
    summary:
        'Never open windows during early morning or late night temperature inversions.',
    detailedExplanation:
        'In winter, cool stagnant surface air traps heavy smog between 6 AM and 10 AM. If outdoor air is needed, do short 10-minute cross-ventilation between 1 PM and 3 PM when solar mixing dilutes ground pollutants.',
    category: IndoorCategory.ventilation,
    scientificBasis:
        'Atmospheric boundary layer height and planetary boundary dynamics.',
    isDoItem: true,
  ),
  IndoorTip(
    id: 'indoor_combustion',
    title: 'Eliminate Indoor Combustion (Incense & Candles)',
    summary:
        'Burning incense sticks generates particulate matter comparable to cigarette smoke.',
    detailedExplanation:
        'In an enclosed winter room, a single incense stick can raise indoor PM2.5 above 200 µg/m³ along with harmful VOCs (benzene, toluene). Switch to fragrance-free diffusers or clean air.',
    category: IndoorCategory.sourceControl,
    scientificBasis:
        'Indoor aerosol emission spectrometry and EPA indoor air chemistry studies.',
    isDoItem: false,
  ),
  IndoorTip(
    id: 'kitchen_exhaust',
    title: 'Run Ducted Kitchen Exhaust While Cooking',
    summary:
        'High-temperature oil frying emits large spikes of ultra-fine particulate matter.',
    detailedExplanation:
        'Always turn on range exhaust 2 minutes before cooking and leave it on for 5 minutes after. Ensure exhaust is ducted to the outside rather than recirculating back into the kitchen.',
    category: IndoorCategory.sourceControl,
    scientificBasis:
        'Cooking oil pyrolysis aerosol dynamics and indoor nitrogen dioxide dispersion.',
    isDoItem: true,
  ),
  IndoorTip(
    id: 'wet_mopping',
    title: 'Wet Mopping Instead of Dry Brooming',
    summary:
        'Dry sweeping resuspends deposited toxic heavy metal dust into the breathing zone.',
    detailedExplanation:
        'Use microfiber damp cloths and wet mops. Dry brooms mechanically re-suspend settled fine particulate matter, making it easily inhalable by toddlers and crawling infants.',
    category: IndoorCategory.sourceControl,
    scientificBasis:
        'Particle resuspension kinetics in indoor residential environments.',
    isDoItem: true,
  ),
];

final indoorTipsProvider = Provider<List<IndoorTip>>((ref) => mockIndoorTips);

// Community Challenges Data
final initialCommunityChallenges = <CommunityChallenge>[
  CommunityChallenge(
    id: 'winter_shield_week',
    title: '7-Day Winter Smog Shield',
    description:
        'Commit to 7 consecutive days of zero open waste burning, carpooling, and indoor HEPA air hygiene.',
    goal: '500 Families in Sector 14 & East Enclave',
    participantGoal: 500,
    participantsCount: 342,
    isJoined: false,
    endsAt: DateTime.now().add(const Duration(days: 3)),
    createdBy: 'Community Clean Air Taskforce',
  ),
  CommunityChallenge(
    id: 'car_free_wednesday',
    title: 'Car-Free Clean Commute Day',
    description:
        'Switch all personal vehicular school and office runs to metro, bus, EV shuttle or remote work.',
    goal: '10,000 kg CO₂e aggregate reduction',
    participantGoal: 1500,
    participantsCount: 1205,
    isJoined: false,
    endsAt: DateTime.now().add(const Duration(days: 1)),
    createdBy: 'Urban Mobility Initiative',
  ),
  CommunityChallenge(
    id: 'school_clean_corridor',
    title: 'School Gate Anti-Idling Zone',
    description:
        'Pledge to turn off car engines immediately upon parking outside school drop-off zones.',
    goal: '100% engine shut-off within 200m radius',
    participantGoal: 150,
    participantsCount: 88,
    isJoined: false,
    endsAt: DateTime.now().add(const Duration(days: 5)),
    createdBy: 'Parent Teacher Association',
  ),
];

class CommunityNotifier extends Notifier<List<CommunityChallenge>> {
  @override
  List<CommunityChallenge> build() => const [];

  void toggleJoin(String id) {
    state = [
      for (final c in state)
        if (c.id == id)
          c.copyWith(
            isJoined: !c.isJoined,
            participantsCount:
                !c.isJoined ? c.participantsCount + 1 : c.participantsCount - 1,
          )
        else
          c,
    ];
  }
}

final communityProvider =
    NotifierProvider<CommunityNotifier, List<CommunityChallenge>>(
        CommunityNotifier.new);
