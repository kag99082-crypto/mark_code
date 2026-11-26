import 'dart:io';
import 'package:archive/archive_io.dart';
import '../models/code_file.dart';

class StructureGenerator {
  static Future<String> generate(CodeFile f, String content,
      {String? absolutePath}) async {
    final ext = f.extension;
    try {
      switch (ext) {
        case 'py': case 'pyw': return _python(content);
        case 'js': case 'jsx': case 'ts': case 'tsx': case 'mjs': case 'cjs':
          return _js(content);
        case 'html': case 'htm': return _html(content);
        case 'css': case 'scss': case 'less': return _css(content);
        case 'json': return _json(content);
        case 'md': return _md(content);
        case 'java': case 'kt': case 'kts': case 'swift':
        case 'c': case 'cc': case 'cpp': case 'h': case 'hpp':
        case 'cs': case 'go': case 'rs': case 'php': case 'rb':
          return _cLike(content);
        case 'yaml': case 'yml': return _yaml(content);
        case 'xml': return _xml(content);
        case 'zip': return absolutePath != null ? await _zip(absolutePath) : '📦 ZIP archive';
        case 'sh': case 'bash': return _shell(content);
        default: return _generic(f, content);
      }
    } catch (e) {
      return '⚠️ Could not analyze: $e';
    }
  }

  static String _python(String c) {
    final lines = c.split('\n');
    final imports = <String>[], classes = <String>[], funcs = <String>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith('import ')) {
        for (final part in t.substring(7).split(',')) {
          imports.add(part.trim().split(' ').first);
        }
      } else if (t.startsWith('from ') && t.contains(' import ')) {
        imports.add(t.substring(5, t.indexOf(' import ')).trim());
      } else if (t.startsWith('class ')) {
        final m = RegExp(r'class\s+(\w+)').firstMatch(t);
        if (m != null) classes.add(m.group(1)!);
      } else if (t.startsWith('def ') || t.startsWith('async def ')) {
        final m = RegExp(r'(?:async\s+)?def\s+(\w+)').firstMatch(t);
        if (m != null) funcs.add(m.group(1)!);
      }
    }
    return _build('🐍 Python Module', lines.length, imports, classes, funcs);
  }

  static String _js(String c) {
    final lines = c.split('\n');
    final imports = <String>[], classes = <String>[], funcs = <String>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith('import ') || t.startsWith('const ') && t.contains('require(')) {
        imports.add(t.length > 70 ? '${t.substring(0, 70)}…' : t);
      } else if (t.startsWith('class ')) {
        final m = RegExp(r'class\s+(\w+)').firstMatch(t);
        if (m != null) classes.add(m.group(1)!);
      } else if (t.startsWith('function ') || t.startsWith('async function ')) {
        final m = RegExp(r'function\s+(\w+)').firstMatch(t);
        if (m != null) funcs.add(m.group(1)!);
      }
      final am = RegExp(r'const\s+(\w+)\s*=\s*(?:async\s*)?\(').firstMatch(t);
      if (am != null && !funcs.contains(am.group(1)!)) funcs.add(am.group(1)!);
    }
    return _build('📜 JavaScript / TypeScript', lines.length, imports, classes, funcs);
  }

  static String _html(String c) {
    final b = StringBuffer();
    final lines = c.split('\n');
    b.writeln('🌐 HTML Document • ${lines.length} lines');
    b.writeln();
    final title = RegExp(r'<title>([^<]+)</title>', caseSensitive: false).firstMatch(c);
    if (title != null) { b.writeln('📌 Title: ${title.group(1)!.trim()}'); b.writeln(); }
    final scripts = RegExp(r'<script[^>]*src=["\']([^"\']+)').allMatches(c).map((m) => m.group(1)!).toList();
    final links = RegExp(r'<link[^>]*href=["\']([^"\']+)').allMatches(c).map((m) => m.group(1)!).toList();
    final ids = RegExp(r'id=["\']([^"\']+)').allMatches(c).map((m) => m.group(1)!).toList();
    final tags = RegExp(r'<(\w+)').allMatches(c).map((m) => m.group(1)!.toLowerCase()).toSet().toList()..sort();
    if (scripts.isNotEmpty) { b.writeln('📜 Scripts (${scripts.length}):'); for (final s in scripts) b.writeln('   • $s'); b.writeln(); }
    if (links.isNotEmpty) { b.writeln('🔗 Links (${links.length}):'); for (final l in links.take(10)) b.writeln('   • $l'); b.writeln(); }
    if (ids.isNotEmpty) { b.writeln('🆔 IDs (${ids.length}):'); for (final i in ids.take(20)) b.writeln('   • #$i'); b.writeln(); }
    b.writeln('🏷 Tags: ${tags.take(20).join(', ')}');
    return b.toString().trim();
  }

  static String _css(String c) {
    final selectors = RegExp(r'([^{}]+)\{').allMatches(c)
        .map((m) => m.group(1)!.trim())
        .where((s) => s.isNotEmpty && !s.startsWith('@'))
        .toList();
    final b = StringBuffer();
    b.writeln('🎨 Stylesheet • ${c.split('\n').length} lines');
    b.writeln();
    if (selectors.isNotEmpty) {
      b.writeln('🎯 Selectors (${selectors.length}):');
      for (final s in selectors.take(30)) b.writeln('   • $s');
      if (selectors.length > 30) b.writeln('   … +${selectors.length - 30} more');
    }
    return b.toString().trim();
  }

  static String _json(String c) {
    final b = StringBuffer();
    try {
      final data = _tryJson(c);
      b.writeln('📊 JSON Document');
      b.writeln();
      void walk(dynamic d, [String pad = '']) {
        if (d is Map) {
          for (final e in d.entries.take(20)) {
            final v = e.value;
            final type = v is Map ? '{…}' : v is List ? '[${(v).length}]' : _typeOf(v);
            b.writeln('$pad• ${e.key}: $type');
            if (v is Map && pad.length < 6) walk(v, '$pad  ');
          }
        } else if (d is List) {
          b.writeln('$pad• Array[${d.length}]');
        }
      }
      walk(data);
    } catch (_) {
      b.writeln('📊 JSON Document');
      b.writeln('(Could not parse — file may be invalid JSON)');
    }
    return b.toString().trim();
  }

  static dynamic _tryJson(String c) {
    // ignore: avoid_dynamic_calls
    try { return _decode(c); } catch (_) { return null; }
  }
  static dynamic _decode(String c) => _jsonDecode(c);

  static String _typeOf(dynamic v) {
    if (v == null) return 'null';
    if (v is String) return '"${v.length > 20 ? '${v.substring(0, 20)}…' : v}"';
    if (v is num) return v.toString();
    if (v is bool) return v.toString();
    return v.runtimeType.toString();
  }

  static String _md(String c) {
    final headings = RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true)
        .allMatches(c)
        .map((m) => '${'  ' * (m.group(1)!.length - 1)}${m.group(1)!.length == 1 ? '📌' : '•'} ${m.group(2)!}')
        .toList();
    final b = StringBuffer();
    b.writeln('📝 Markdown Document • ${c.split('\n').length} lines');
    b.writeln();
    if (headings.isNotEmpty) {
      b.writeln('📋 Headings (${headings.length}):');
      for (final h in headings.take(30)) b.writeln('   $h');
    } else {
      b.writeln('(No headings found)');
    }
    return b.toString().trim();
  }

  static String _cLike(String c) {
    final lines = c.split('\n');
    final classes = <String>[], funcs = <String>[];
    for (final line in lines) {
      final t = line.trim();
      final cm = RegExp(r'(?:class|interface|struct|enum)\s+(\w+)').firstMatch(t);
      if (cm != null) { classes.add(cm.group(1)!); continue; }
      final fm = RegExp(r'(?:public|private|protected|static|\s)*\s*(?:fun|void|int|String|bool|Future<[^>]+>|[\w<>\[\]]+)\s+(\w+)\s*\(').firstMatch(t);
      if (fm != null && !['if', 'for', 'while', 'switch', 'return'].contains(fm.group(1))) {
        funcs.add(fm.group(1)!);
      }
    }
    return _build('⚡ Source File', lines.length, [], classes, funcs);
  }

  static String _yaml(String c) {
    final lines = c.split('\n');
    final keys = <String>[];
    for (final line in lines) {
      final m = RegExp(r'^(\w[\w-]*)\s*:').firstMatch(line);
      if (m != null) keys.add(m.group(1)!);
    }
    final b = StringBuffer();
    b.writeln('⚙️ YAML Config • ${lines.length} lines');
    b.writeln();
    if (keys.isNotEmpty) {
      b.writeln('🔑 Top-level keys (${keys.length}):');
      for (final k in keys.take(30)) b.writeln('   • $k');
    }
    return b.toString().trim();
  }

  static String _xml(String c) {
    final tags = RegExp(r'<([\w:]+)').allMatches(c).map((m) => m.group(1)!).toSet().toList()..sort();
    final b = StringBuffer();
    b.writeln('📄 XML Document • ${c.split('\n').length} lines');
    b.writeln();
    b.writeln('🏷 Tags (${tags.length}):');
    for (final t in tags.take(30)) b.writeln('   • <$t>');
    return b.toString().trim();
  }

  static String _shell(String c) {
    final funcs = RegExp(r'^(\w+)\s*\(\)', multiLine: true).allMatches(c).map((m) => m.group(1)!).toList();
    final b = StringBuffer();
    b.writeln('⌨️ Shell Script • ${c.split('\n').length} lines');
    if (funcs.isNotEmpty) {
      b.writeln();
      b.writeln('⚙️ Functions (${funcs.length}):');
      for (final f in funcs) b.writeln('   • $f()');
    }
    return b.toString().trim();
  }

  static Future<String> _zip(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final b = StringBuffer();
    b.writeln('📦 ZIP Archive');
    b.writeln('${archive.files.length} entries');
    b.writeln();
    for (final f in archive.files.take(50)) {
      final icon = f.isFile ? '📄' : '📁';
      final size = f.isFile ? '  (${_size(f.size)})' : '';
      b.writeln('$icon ${f.name}$size');
    }
    if (archive.files.length > 50) b.writeln('… +${archive.files.length - 50} more');
    return b.toString().trim();
  }

  static String _generic(CodeFile f, String c) {
    final lines = c.split('\n');
    final b = StringBuffer();
    b.writeln('📄 ${f.extension.toUpperCase()} File');
    b.writeln('Lines: ${lines.length}');
    b.writeln('Chars: ${c.length}');
    b.writeln();
    b.writeln('Preview:');
    for (final l in lines.take(10)) b.writeln('  ${l.length > 70 ? '${l.substring(0, 70)}…' : l}');
    return b.toString().trim();
  }

  static String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  static String _build(String title, int lines,
      List<String> imports, List<String> classes, List<String> funcs) {
    final b = StringBuffer();
    b.writeln('$title • $lines lines');
    b.writeln();
    if (imports.isNotEmpty) {
      b.writeln('📥 Imports (${imports.length}):');
      for (final i in imports.take(20)) b.writeln('   • $i');
      if (imports.length > 20) b.writeln('   … +${imports.length - 20} more');
      b.writeln();
    }
    if (classes.isNotEmpty) {
      b.writeln('🏛 Classes (${classes.length}):');
      for (final c in classes) b.writeln('   • $c');
      b.writeln();
    }
    if (funcs.isNotEmpty) {
      b.writeln('⚙️ Functions (${funcs.length}):');
      for (final f in funcs.take(30)) b.writeln('   • $f()');
      if (funcs.length > 30) b.writeln('   … +${funcs.length - 30} more');
    }
    if (imports.isEmpty && classes.isEmpty && funcs.isEmpty) {
      b.writeln('(No declarations detected)');
    }
    return b.toString().trim();
  }
}

// small helpers to avoid import clash
dynamic _jsonDecode(String s) => _decodeJSON(s);
dynamic _decodeJSON(String s) => json.decode(s);
