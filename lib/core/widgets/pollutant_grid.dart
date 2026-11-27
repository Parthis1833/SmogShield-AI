import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/air_quality.dart';

class PollutantGridWidget extends StatelessWidget {
  final AirQuality airQuality;

  const PollutantGridWidget({super.key, required this.airQuality});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('pollutant_grid_widget'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Key Pollutants',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Indian CPCB Standards & Units',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final count = constraints.maxWidth >= 900 ? 3 : (isWide ? 3 : 2);
            return GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isWide ? 1.55 : 1.18,
              children: [
                _PollutantCard(
                  name: 'PM 2.5',
                  subtitle: 'Fine particles',
                  value: '${airQuality.pm25}',
                  unit: 'µg/m³',
                  status: airQuality.pm25 > 120
                      ? 'Severe'
                      : airQuality.pm25 > 60
                          ? 'High'
                          : 'Moderate',
                  color: airQuality.pm25 > 120
                      ? AppColors.aqiSevere
                      : airQuality.pm25 > 60
                          ? AppColors.aqiVeryPoor
                          : AppColors.aqiModerate,
                  note: 'CPCB 24h: 60 µg/m³',
                ),
                _PollutantCard(
                  name: 'PM 10',
                  subtitle: 'Inhalable dust',
                  value: '${airQuality.pm10}',
                  unit: 'µg/m³',
                  status: airQuality.pm10 > 250
                      ? 'Severe'
                      : airQuality.pm10 > 100
                          ? 'High'
                          : 'Acceptable',
                  color: airQuality.pm10 > 250
                      ? AppColors.aqiSevere
                      : airQuality.pm10 > 100
                          ? AppColors.aqiPoor
                          : AppColors.aqiModerate,
                  note: 'CPCB 24h: 100 µg/m³',
                ),
                _PollutantCard(
                  name: 'NO₂',
                  subtitle: 'Traffic fumes',
                  value: '${airQuality.no2}',
                  unit: 'µg/m³',
                  status: airQuality.no2 > 80 ? 'Elevated' : 'Normal',
                  color: airQuality.no2 > 80
                      ? AppColors.aqiPoor
                      : AppColors.aqiGood,
                  note: 'CPCB 24h: 80 µg/m³',
                ),
                _PollutantCard(
                  name: 'SO₂',
                  subtitle: 'Industrial emission',
                  value: '${airQuality.so2}',
                  unit: 'µg/m³',
                  status: airQuality.so2 > 80 ? 'Elevated' : 'Normal',
                  color: airQuality.so2 > 80
                      ? AppColors.aqiPoor
                      : AppColors.aqiGood,
                  note: 'CPCB 24h: 80 µg/m³',
                ),
                _PollutantCard(
                  name: 'CO',
                  subtitle: 'Incomplete burn',
                  value: '${airQuality.co}',
                  unit: 'mg/m³',
                  status: airQuality.co > 2.0 ? 'Elevated' : 'Good',
                  color: airQuality.co > 2.0
                      ? AppColors.aqiPoor
                      : AppColors.aqiGood,
                  note: 'CPCB 8h: 2.0 mg/m³',
                ),
                _PollutantCard(
                  name: 'O₃',
                  subtitle: 'Ground-level ozone',
                  value: '${airQuality.o3}',
                  unit: 'µg/m³',
                  status: airQuality.o3 > 100 ? 'Elevated' : 'Good',
                  color: airQuality.o3 > 100
                      ? AppColors.aqiPoor
                      : AppColors.aqiGood,
                  note: 'CPCB 8h: 100 µg/m³',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PollutantCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String value;
  final String unit;
  final String status;
  final Color color;
  final String note;

  const _PollutantCard({
    required this.name,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.status,
    required this.color,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            note,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
