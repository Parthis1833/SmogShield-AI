import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../core/data/family_profile_provider.dart';
import '../../core/data/location_search_repository.dart';
import '../../core/data/nearby_air_quality_repository.dart';
import '../../core/models/nearby_air_quality.dart';
import '../../core/widgets/section_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _locationController = TextEditingController();
  Timer? _searchDebounce;
  String _sessionToken = _newSessionToken();
  List<LocationSuggestion> _suggestions = const [];
  List<LocationDetails> _recentLocations = const [];
  NearbyAirQuality? _airQuality;
  String? _error;
  String? _selectedLocation;
  bool _isSearching = false;
  bool _isLoading = false;
  int _requestId = 0;

  static String _newSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreLocation());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _restoreLocation() async {
    try {
      await ref.read(selectedLocationProvider.notifier).restore();
      await ref.read(recentLocationsProvider.notifier).restore();
      final location = ref.read(selectedLocationProvider);
      if (!mounted) return;
      setState(() {
        _recentLocations = ref.read(recentLocationsProvider);
        if (location != null) {
          _locationController.text = location.city;
          _selectedLocation = location.displayName;
        }
      });
      if (location != null) {
        ref.read(familyProfileProvider.notifier).setCity(location.city);
        await _loadLocation(location);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    final requestId = ++_requestId;
    final query = value.trim();
    setState(() {
      _suggestions = const [];
      _airQuality = null;
      _error = null;
      _isLoading = false;
    });
    if (query.length < 2) {
      setState(() => _isSearching = false);
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchLocations(query, requestId),
    );
  }

  Future<void> _searchLocations(String query, int requestId) async {
    if (!mounted || requestId != _requestId) return;
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final suggestions = await ref.read(locationSearchRepositoryProvider).search(
            query,
            sessionToken: _sessionToken,
          );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _suggestions = suggestions;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error.toString();
        _isSearching = false;
      });
    }
  }

  Future<void> _selectSuggestion(LocationSuggestion suggestion) async {
    final requestId = ++_requestId;
    final sessionToken = _sessionToken;
    _sessionToken = _newSessionToken();
    setState(() {
      _isLoading = true;
      _isSearching = false;
      _suggestions = const [];
      _airQuality = null;
      _error = null;
      _selectedLocation = suggestion.displayName;
      _locationController.text = suggestion.city;
    });
    try {
      final location =
          await ref.read(locationSearchRepositoryProvider).details(
                suggestion.placeId,
                sessionToken: sessionToken,
              );
      if (!mounted || requestId != _requestId) return;
      await ref.read(selectedLocationProvider.notifier).setLocation(location);
      await ref.read(recentLocationsProvider.notifier).add(location);
      ref.read(familyProfileProvider.notifier).setCity(location.city);
      setState(() => _recentLocations = ref.read(recentLocationsProvider));
      await _loadLocation(location, requestId: requestId);
    } catch (error) {
      if (mounted && requestId == _requestId) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLocation(
    LocationDetails location, {
    int? requestId,
  }) async {
    final id = requestId ?? ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
      _airQuality = null;
      _selectedLocation = location.displayName;
      _locationController.text = location.city;
    });
    try {
      final result =
          await ref.read(nearbyAirQualityRepositoryProvider).loadNearby(
                latitude: location.latitude,
                longitude: location.longitude,
                city: location.city,
                state: location.state,
                country: location.country,
                displayName: location.displayName,
              );
      if (!mounted || id != _requestId) return;
      setState(() {
        _airQuality = result;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted && id == _requestId) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
      _airQuality = null;
      _selectedLocation = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Turn on location services, then try again.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw StateError(
          'Location permission was denied. Allow access or search for a place.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw StateError(
          'Location permission is blocked. Change it in system settings or search for a place.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 18),
        ),
      );
      final result =
          await ref.read(nearbyAirQualityRepositoryProvider).loadNearby(
                latitude: position.latitude,
                longitude: position.longitude,
              );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _airQuality = result;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted && requestId == _requestId) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectRecent(LocationDetails location) async {
    final requestId = ++_requestId;
    try {
      await ref.read(selectedLocationProvider.notifier).setLocation(location);
      await ref.read(recentLocationsProvider.notifier).add(location);
      ref.read(familyProfileProvider.notifier).setCity(location.city);
      if (!mounted || requestId != _requestId) return;
      setState(() => _recentLocations = ref.read(recentLocationsProvider));
      await _loadLocation(location, requestId: requestId);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        const PageHeading(
          'SmogShield AI',
          'Live air-quality readings for your selected location',
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _locationController,
                textInputAction: TextInputAction.search,
                onChanged: _onQueryChanged,
                onSubmitted: (query) {
                  if (query.trim().length >= 2) {
                    _searchLocations(query.trim(), ++_requestId);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Search for a city or place',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  suffixIcon: _locationController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _locationController.clear();
                            _onQueryChanged('');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
              if (_isSearching) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
              ],
              for (final suggestion in _suggestions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(suggestion.city),
                  subtitle: Text(suggestion.description),
                  onTap: () => _selectSuggestion(suggestion),
                ),
              if (_suggestions.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Powered by Google Maps',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              if (_locationController.text.isEmpty &&
                  _recentLocations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Recent locations', style: theme.textTheme.labelLarge),
                for (final location in _recentLocations)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history),
                    title: Text(location.city),
                    subtitle: Text(location.displayName),
                    onTap: () => _selectRecent(location),
                  ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use my current location'),
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const SectionCard(
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null)
          SectionCard(
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        if (!_isLoading && _error == null && _airQuality == null)
          SectionCard(
            child: Text(
              'Choose a location to request observations from the configured monitoring provider.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        if (!_isLoading && _airQuality != null)
          _LiveAirQualityCard(
            air: _airQuality!,
            selectedLocation: _selectedLocation,
          ),
      ],
    );
  }
}

class _LiveAirQualityCard extends StatelessWidget {
  const _LiveAirQualityCard({
    required this.air,
    required this.selectedLocation,
  });

  final NearbyAirQuality air;
  final String? selectedLocation;

  static const _pollutants = {
    'pm25': 'PM2.5',
    'pm10': 'PM10',
    'no2': 'NO₂',
    'so2': 'SO₂',
    'co': 'CO',
    'o3': 'O₃',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!air.found) {
      return SectionCard(
        child: Column(
          children: [
            Text(
              'No station readings found',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              air.noDataReason ??
                  'The monitoring provider returned no observations for this location.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final observedAt = air.observedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                air.stationName ?? 'Monitoring station',
                style: theme.textTheme.titleMedium,
              ),
              if (selectedLocation != null) Text('Near $selectedLocation'),
              const SizedBox(height: 6),
              Text('Source: ${air.source}'),
              if (air.provider != null) Text('Provider: ${air.provider}'),
              if (air.distanceKm != null)
                Text('${air.distanceKm!.toStringAsFixed(1)} km away'),
              Text(
                observedAt == null
                    ? 'Observation time unavailable'
                    : 'Observed ${DateFormat.yMMMd().add_jm().format(observedAt.toLocal())}',
              ),
              if (air.isCached)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Showing cached observations. They may not represent current conditions.',
                  ),
                ),
              if (air.freshness != null && air.freshness != 'Fresh')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${air.freshness} observation; use its timestamp to assess recency.',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              if (air.providerError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Provider update unavailable: ${air.providerError}',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 700 ? 3 : 2;
            final width =
                (constraints.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final entry in _pollutants.entries)
                  SizedBox(
                    width: width,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: _PollutantReadingCard(
                          title: entry.value,
                          reading: air.pollutants[entry.key],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (air.recommendations.isNotEmpty)
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommendations based on these readings',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final recommendation in air.recommendations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $recommendation'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PollutantReadingCard extends StatelessWidget {
  const _PollutantReadingCard({
    required this.title,
    required this.reading,
  });

  final String title;
  final PollutantReading? reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          reading?.value == null ? 'No reading' : '${reading!.value}',
          style: theme.textTheme.headlineSmall,
        ),
        if (reading?.unit != null) Text(reading!.unit!),
        if (reading?.observedAt != null)
          Text(
            DateFormat.Hm().format(reading!.observedAt!.toLocal()),
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}
