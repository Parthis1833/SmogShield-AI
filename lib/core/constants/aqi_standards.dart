enum AqiStandard {
  indianCpcb('Indian National AQI (CPCB)', 'IN_AQI', 'µg/m³'),
  usEpa('US EPA AQI', 'US_AQI', 'ppm / µg/m³');

  final String displayName;
  final String code;
  final String primaryUnit;

  const AqiStandard(this.displayName, this.code, this.primaryUnit);
}

class AqiCategoryInfo {
  final String category;
  final int minAqi;
  final int maxAqi;
  final String shortHealthAdvice;
  final String sensitiveGroupAdvice;

  const AqiCategoryInfo({
    required this.category,
    required this.minAqi,
    required this.maxAqi,
    required this.shortHealthAdvice,
    required this.sensitiveGroupAdvice,
  });
}

class AqiStandardsHelper {
  static const List<AqiCategoryInfo> indianCategories = [
    AqiCategoryInfo(
      category: 'Good',
      minAqi: 0,
      maxAqi: 50,
      shortHealthAdvice: 'Minimal impact. Ideal for outdoor activities.',
      sensitiveGroupAdvice: 'No special precautions required.',
    ),
    AqiCategoryInfo(
      category: 'Satisfactory',
      minAqi: 51,
      maxAqi: 100,
      shortHealthAdvice: 'Minor breathing discomfort to sensitive people.',
      sensitiveGroupAdvice: 'Unusually sensitive people should consider reducing prolonged outdoor exertion.',
    ),
    AqiCategoryInfo(
      category: 'Moderate',
      minAqi: 101,
      maxAqi: 200,
      shortHealthAdvice: 'Breathing discomfort to people with lungs, asthma and heart diseases.',
      sensitiveGroupAdvice: 'Children and adults with asthma should limit prolonged heavy outdoor exertion.',
    ),
    AqiCategoryInfo(
      category: 'Poor',
      minAqi: 201,
      maxAqi: 300,
      shortHealthAdvice: 'Breathing discomfort to most people on prolonged exposure.',
      sensitiveGroupAdvice: 'Sensitive groups should avoid outdoor exertion; general public should reduce prolonged exposure.',
    ),
    AqiCategoryInfo(
      category: 'Very Poor',
      minAqi: 301,
      maxAqi: 400,
      shortHealthAdvice: 'Respiratory illness on prolonged exposure. Pronounced effect on sensitive groups.',
      sensitiveGroupAdvice: 'Avoid outdoor exercise. Use particulate masks (N95) outdoors and operate HEPA purifiers indoors.',
    ),
    AqiCategoryInfo(
      category: 'Severe',
      minAqi: 401,
      maxAqi: 500,
      shortHealthAdvice: 'Affects healthy people and seriously impacts those with existing diseases.',
      sensitiveGroupAdvice: 'Everyone should avoid physical outdoor activity. Keep doors and windows closed with active filtration.',
    ),
  ];

  static AqiCategoryInfo getCategoryInfo(int aqi) {
    if (aqi <= 50) return indianCategories[0];
    if (aqi <= 100) return indianCategories[1];
    if (aqi <= 200) return indianCategories[2];
    if (aqi <= 300) return indianCategories[3];
    if (aqi <= 400) return indianCategories[4];
    return indianCategories[5];
  }
}
