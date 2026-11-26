import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

class StorageService {
  static final StorageService _i = StorageService._();
  factory StorageService() => _i;
  StorageService._();

  List<CodeFile> _files = [];
  bool _loaded = false;

  List<CodeFile> get files => List.unmodifiable(_files);

  Future<Directory> get rootDir async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(base.path, 'code_vault'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<Directory> get filesDir async {
    final d = Directory(p.join((await rootDir).path, 'files'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<File> get _metaFile async =>
      File(p.join((await rootDir).path, 'metadata.json'));

  Future<void> load() async {
    if (_loaded) return;
    final meta = await _metaFile;
    if (await meta.exists()) {
      try {
        final data = jsonDecode(await meta.readAsString());
        _files = (data['files'] as List).map((e) => CodeFile.fromJson(e)).toList();
      } catch (_) { _files = []; }
    }
    _loaded = true;
  }

  Future<void> _saveMeta() async {
    final meta = await _metaFile;
    await meta.writeAsString(jsonEncode({
      'files': _files.map((f) => f.toJson()).toList(),
    }));
  }

  Future<CodeFile> importFile(String sourcePath,
      {String? category, String? description}) async {
    final dir = await filesDir;
    final id = const Uuid().v4();
    final ext = p.extension(sourcePath);
    final storedName = '$id$ext';
    await File(sourcePath).copy(p.join(dir.path, storedName));

    final f = CodeFile(
      id: id,
      name: p.basename(sourcePath),
      storedName: storedName,
      category: category,
      description: description,
      addedAt: DateTime.now(),
    );
    _files.insert(0, f);
    await _saveMeta();
    return f;
  }

  Future<void> updateFile(CodeFile f) async {
    final i = _files.indexWhere((x) => x.id == f.id);
    if (i >= 0) { _files[i] = f; await _saveMeta(); }
  }

  Future<void> deleteFile(CodeFile f) async {
    _files.removeWhere((x) => x.id == f.id);
    final path = p.join((await filesDir).path, f.storedName);
    final file = File(path);
    if (await file.exists()) await file.delete();
    await _saveMeta();
  }

  Future<String> absolutePath(CodeFile f) async =>
      p.join((await filesDir).path, f.storedName);

  Future<String> readContent(CodeFile f, {int maxBytes = 300000}) async {
    final file = File(await absolutePath(f));
    if (!await file.exists()) return '';
    final size = (await file.stat()).size;
    if (size <= maxBytes) return file.readAsString();
    final raf = await file.open();
    try {
      final bytes = await raf.read(maxBytes);
      return utf8.decode(bytes, allowMalformed: true);
    } finally { await raf.close(); }
  }

  List<String> get categories {
    final set = <String>{};
    for (final f in _files) {
      if (f.category != null && f.category!.isNotEmpty) set.add(f.category!);
    }
    return set.toList()..sort();
  }
}
