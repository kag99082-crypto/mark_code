class CodeFile {
  final String id;
  final String name;        // original filename
  final String storedName;  // uuid.ext in app storage
  final String? category;
  final String? description;
  final String? structure;
  final DateTime addedAt;

  CodeFile({
    required this.id,
    required this.name,
    required this.storedName,
    this.category,
    this.description,
    this.structure,
    required this.addedAt,
  });

  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'storedName': storedName,
    'category': category, 'description': description,
    'structure': structure, 'addedAt': addedAt.toIso8601String(),
  };

  factory CodeFile.fromJson(Map<String, dynamic> j) => CodeFile(
    id: j['id'], name: j['name'], storedName: j['storedName'],
    category: j['category'], description: j['description'],
    structure: j['structure'], addedAt: DateTime.parse(j['addedAt']),
  );
}
