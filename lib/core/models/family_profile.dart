import '../constants/aqi_standards.dart';

class FamilyProfile {
  final String city;
  final int adultsCount;
  final int childrenCount;
  final int seniorsCount;
  final bool hasVulnerableMember;
  final String primaryCommuteMode;
  final String airPurificationSetup;
  final bool alertOnSpikes;
  final AqiStandard preferredStandard;

  const FamilyProfile({
    this.city = '',
    this.adultsCount = 0,
    this.childrenCount = 0,
    this.seniorsCount = 0,
    this.hasVulnerableMember = false,
    this.primaryCommuteMode = '',
    this.airPurificationSetup = '',
    this.alertOnSpikes = false,
    this.preferredStandard = AqiStandard.indianCpcb,
  });

  FamilyProfile copyWith({
    String? city,
    int? adultsCount,
    int? childrenCount,
    int? seniorsCount,
    bool? hasVulnerableMember,
    String? primaryCommuteMode,
    String? airPurificationSetup,
    bool? alertOnSpikes,
    AqiStandard? preferredStandard,
  }) {
    return FamilyProfile(
      city: city ?? this.city,
      adultsCount: adultsCount ?? this.adultsCount,
      childrenCount: childrenCount ?? this.childrenCount,
      seniorsCount: seniorsCount ?? this.seniorsCount,
      hasVulnerableMember: hasVulnerableMember ?? this.hasVulnerableMember,
      primaryCommuteMode: primaryCommuteMode ?? this.primaryCommuteMode,
      airPurificationSetup: airPurificationSetup ?? this.airPurificationSetup,
      alertOnSpikes: alertOnSpikes ?? this.alertOnSpikes,
      preferredStandard: preferredStandard ?? this.preferredStandard,
    );
  }
}
