class LearningResource {
  const LearningResource({required this.label, required this.url});

  final String label;
  final String url;

  factory LearningResource.fromMap(Map<String, dynamic> data) {
    return LearningResource(
      label: data['label'] is String ? data['label'] as String : '',
      url: data['url'] is String ? data['url'] as String : '',
    );
  }

  Map<String, String> toFirestore() => {'label': label, 'url': url};
}
