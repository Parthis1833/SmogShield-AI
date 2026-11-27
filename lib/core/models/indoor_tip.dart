enum IndoorCategory {
  filtration('Filtration & Purifiers'),
  ventilation('Ventilation & Sealing'),
  sourceControl('Source Control & Dust'),
  monitoring('Sensors & Monitoring');

  final String label;
  const IndoorCategory(this.label);
}

class IndoorTip {
  final String id;
  final String title;
  final String summary;
  final String detailedExplanation;
  final IndoorCategory category;
  final String scientificBasis;
  final bool isDoItem; // true for "Do", false for "Don't"

  const IndoorTip({
    required this.id,
    required this.title,
    required this.summary,
    required this.detailedExplanation,
    required this.category,
    required this.scientificBasis,
    this.isDoItem = true,
  });

  factory IndoorTip.fromJson(Map<String, dynamic> json) {
    final category = switch (json['category']) {
      'filtration' => IndoorCategory.filtration,
      'ventilation' => IndoorCategory.ventilation,
      'sourceControl' || 'source_control' => IndoorCategory.sourceControl,
      'monitoring' => IndoorCategory.monitoring,
      final value => throw FormatException(
          'Unknown indoor tip category: $value',
        ),
    };
    return IndoorTip(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      detailedExplanation: json['detailed_explanation'] as String,
      category: category,
      scientificBasis: json['scientific_basis'] as String,
      isDoItem: json['is_recommended'] as bool,
    );
  }
}
