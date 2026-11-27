import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/family_profile.dart';

class FamilyProfileNotifier extends Notifier<FamilyProfile> {
  @override
  FamilyProfile build() => const FamilyProfile();

  void updateProfile(FamilyProfile updated) => state = updated;

  void setCity(String city) => state = state.copyWith(city: city);

  void updateMembers({
    int? adults,
    int? children,
    int? seniors,
    bool? hasVulnerable,
  }) {
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
  FamilyProfileNotifier.new,
);
