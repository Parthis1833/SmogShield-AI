import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../models/air_quality.dart';

class AqiGaugeWidget extends StatelessWidget {
  final AirQuality airQuality;
  final VoidCallback? onDetailsTap;

  const AqiGaugeWidget({
    super.key,
    required this.airQuality,
    this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aqi = airQuality.aqi;
    final aqiColor = AppColors.getAqiColor(aqi);
    final tokens = theme.extension<AerisTokens>() ??
        AerisTokens.forBrightness(theme.brightness);

    // Progress fraction clamped to [0.0, 1.0] for Indian CPCB range max 500
    final progress = (aqi / 500.0).clamp(0.0, 1.0);

    return Container(
      key: const Key('aqi_gauge_widget'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: City & Demo Badge & Category Badge
          LayoutBuilder(
            builder: (context, constraints) {
              final cityHeader = Row(
                children: [
                  Icon(Icons.location_on,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      airQuality.city,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tokens.warning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DEMO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tokens.warning,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              );
              final categoryBadge = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: aqiColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: aqiColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: aqiColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(airQuality.category,
                        style: theme.textTheme.labelLarge),
                  ],
                ),
              );

              if (constraints.maxWidth < 380) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    cityHeader,
                    const SizedBox(height: 8),
                    categoryBadge,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: cityHeader),
                  const SizedBox(width: 10),
                  categoryBadge,
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Main Index Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$aqi',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: aqiColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AQI INDEX',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        airQuality.standard == 'IN_AQI'
                            ? 'Indian CPCB Scale (0 – 500)'
                            : 'US EPA Scale',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Demonstration data (Mock AQI: $aqi)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.warning,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Indian AQI Multi-Stop Progress Indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: tokens.divider,
              valueColor: AlwaysStoppedAnimation<Color>(aqiColor),
            ),
          ),
          const SizedBox(height: 6),

          // Indian CPCB Category Ticks
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0 Good', style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Text('100', style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Text('200', style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Text('300', style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Text('400', style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Text('500+ Severe', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Health Advisory Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.surfaceSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: aqiColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: aqiColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Indian AQI Category: ${airQuality.category}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        airQuality.healthAdvisory,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Source and Observation Metadata Wrap
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Source: ${airQuality.source}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: tokens.mutedText),
              ),
              Text(
                'Observed: ${airQuality.formattedObservationTime}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: tokens.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
