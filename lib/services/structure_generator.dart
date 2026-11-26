import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';

import '../models/code_file.dart';

class StructureGenerator {
  static Future<String> generate(
    CodeFile file,
    String content, {
    String? absolutePath,
  }) async {
    try {
      switch (file.extension) {
        case 'py':
        case 'pyw':
          return _python(content);
        case 'js':
        case 'jsx':
        case 'ts':
        case 'tsx':
        case 'mjs':
        case 'cjs':
          return _js(content);
        case 'html':
        case 'htm':
          return _html(content);
        case 'css':
        case 'scss':
        case 'less':
          return _css(content);
        case 'json':
          return _json(content);
        case 'md':
          return _markdown(content);
        case 'java':
        case 'kt':
        case 'kts':
        case 'swift':
        case 'c':
        case 'cc':
        case 'cpp':
        case 'h':
        case 'hpp':
        case 'cs':
        case 'go':
        case 'rs':
        case 'php':
        case 'rb':
          return _cLike(content);
        case 'yaml':
        case 'yml':
          return _yaml(content);
        case 'xml':
          return _xml(content);
        case 'zip':
          return absolutePath != null
              ? await _zip(absolutePath)
              : '📦 ZIP archive';
        case 'sh':
        case 'bash':
          return _shell(content);
        default:
          return _generic(file, content);
      }
    } catch (e) {
      return '⚠️ Could not analyze: $e';
    }
  }

  static String _python(String content) {
    final lines = content.split('\n');
    final imports = <String>[];
    final classes = <String>[];
    final funcs = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('import ')) {
        for (final part in trimmed.substring(7).split(',')) {
          final name = part.trim().split(' ').first;
          if (name.isNotEmpty) imports.add(name);
        }
      } else if (trimmed.startsWith('from ') && trimmed.contains(' import ')) {
        imports.add(trimmed.substring(5, trimmed.indexOf(' import ')).trim());
      } else if (trimmed.startsWith('class ')) {
        final match = RegExp(r'class\s+(\w+)').firstMatch(trimmed);
        if (match != null) classes.add(match.group(1)!);
      } else if (trimmed.startsWith('def ') ||
          trimmed.startsWith('async def ')) {
        final match = RegExp(r'(?:async\s+)?def\s+(\w+)').firstMatch(trimmed);
        if (match != null) funcs.add(match.group(1)!);
      }
    }
    return _build('🐍 Python Module', lines.length, imports, classes, funcs);
  }

  static String _js(String content) {
    final lines = content.split('\n');
    final imports = <String>[];
    final classes = <String>[];
    final funcs = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('import ') ||
          (trimmed.startsWith('const ') && trimmed.contains('require('))) {
        imports.add(
          trimmed.length > 70 ? '${trimmed.substring(0, 70)}…' : trimmed,
        );
      } else if (trimmed.startsWith('class ')) {
        final match = RegExp(r'class\s+(\w+)').firstMatch(trimmed);
        if (match != null) classes.add(match.group(1)!);
      } else if (trimmed.startsWith('function ') ||
          trimmed.startsWith('async function ')) {
        final match = RegExp(r'function\s+(\w+)').firstMatch(trimmed);
        if (match != null) funcs.add(match.group(1)!);
      }
      final arrow =
          RegExp(r'const\s+(\w+)\s*=\s*(?:async\s*)?\(').firstMatch(trimmed);
      if (arrow != null && !funcs.contains(arrow.group(1)!)) {
        funcs.add(arrow.group(1)!);
      }
    }
    return _build('📜 JavaScript / TypeScript', lines.length, imports, classes,
        funcs);
  }

  static String _html(String content) {
    final buffer = StringBuffer();
    final lines = content.split('\n');
    buffer.writeln('🌐 HTML Document • ${lines.length} lines');
    buffer.writeln();

    final title = RegExp(r'<title>([^<]+)</title>', caseSensitive: false)
        .firstMatch(content);
    if (title != null) {
      buffer.writeln('📌 Title: ${title.group(1)!.trim()}');
      buffer.writeln();
    }

    final scripts = RegExp("<script[^>]*src=[\"']([^\"']+)")
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toList();

    final links = RegExp("<link[^>]*href=[\"']([^\"']+)")
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toList();

    final ids = RegExp("id=[\"']([^\"']+)")
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toList();

    final tags = RegExp(r'<(\w+)')
        .allMatches(content)
        .map((m) => m.group(1)!.toLowerCase())
        .toSet()
        .toList()
      ..sort();

    if (scripts.isNotEmpty) {
      buffer.writeln('📜 Scripts (${scripts.length}):');
      for (final s in scripts) {
        buffer.writeln('   • $s');
      }
      buffer.writeln();
    }
    if (links.isNotEmpty) {
      buffer.writeln('🔗 Links (${links.length}):');
      for (final l in links.take(10)) {
        buffer.writeln('   • $l');
      }
      buffer.writeln();
    }
    if (ids.isNotEmpty) {
      buffer.writeln('🆔 IDs (${ids.length}):');
      for (final id in ids.take(20)) {
        buffer.writeln('   • #$id');
      }
      buffer.writeln();
    }
    buffer.writeln('🏷 Tags: ${tags.take(20).join(', ')}');
    return buffer.toString().trim();
  }

  static String _css(String content) {
    final selectors = RegExp(r'([^{}]+)\{')
        .allMatches(content)
        .map((m) => m.group(1)!.trim())
        .where((s) => s.isNotEmpty && !s.startsWith('@'))
        .toList();

    final buffer = StringBuffer();
    buffer.writeln('🎨 Stylesheet • ${content.split('\n').length} lines');
    buffer.writeln();
    if (selectors.isNotEmpty) {
      buffer.writeln('🎯 Selectors (${selectors.length}):');
      for (final s in selectors.take(30)) {
        buffer.writeln('   • $s');
      }
      if (selectors.length > 30) {
        buffer.writeln('   … +${selectors.length - 30} more');
      }
    }
    return buffer.toString().trim();
  }

  static String _json(String content) {
    final buffer = StringBuffer();
    buffer.writeln('📊 JSON Document');
    buffer.writeln();
    try {
      final data = jsonDecode(content);

      void walk(dynamic node, [String pad = '']) {
        if (node is Map) {
          for (final entry in node.entries.take(20)) {
            final value = entry.value;
            final String type;
            if (value is Map) {
              type = '{…}';
            } else if (value is List) {
              type = '[${value.length}]';
            } else {
              type = _typeOf(value);
            }
            buffer.writeln('$pad• ${entry.key}: $type');
            if (value is Map && pad.length < 6) {
              walk(value, '$pad  ');
            }
          }
        } else if (node is List) {
          buffer.writeln('$pad• Array[${node.length}]');
        }
      }

      walk(data);
    } catch (_) {
      buffer.writeln('(Invalid JSON)');
    }
    return buffer.toString().trim();
  }

  static String _typeOf(dynamic value) {
    if (value == null) return 'null';
    if (value is String) {
      return '"${value.length > 20 ? '${value.substring(0, 20)}…' : value}"';
    }
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    return value.runtimeType.toString();
  }

  static String _markdown(String content) {
    final headings = RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true)
        .allMatches(content)
        .map((m) {
          final level = m.group(1)!.length;
          final indent = '  ' * (level - 1);
          final icon = level == 1 ? '📌' : '•';
          return '$indent$icon ${m.group(2)!}';
        })
        .toList();

    final buffer = StringBuffer();
    buffer.writeln('📝 Markdown Document • ${content.split('\n').length} lines');
    buffer.writeln();
    if (headings.isNotEmpty) {
      buffer.writeln('📋 Headings (${headings.length}):');
      for (final h in headings.take(30)) {
        buffer.writeln('   $h');
      }
    } else {
      buffer.writeln('(No headings found)');
    }
    return buffer.toString().trim();
  }

  static String _cLike(String content) {
    final lines = content.split('\n');
    final classes = <String>[];
    final funcs = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      final classMatch = RegExp(r'(?:class|interface|struct|enum)\s+(\w+)')
          .firstMatch(trimmed);
      if (classMatch != null) {
        classes.add(classMatch.group(1)!);
        continue;
      }
      final funcMatch = RegExp(
        r'(?:public|private|protected|static|\s)*\s*(?:fun|void|int|String|bool|Future<[^>]+>|[\w<>\[\]]+)\s+(\w+)\s*\(',
      ).firstMatch(trimmed);
      if (funcMatch != null &&
          !['if', 'for', 'while', 'switch', 'return']
              .contains(funcMatch.group(1))) {
        funcs.add(funcMatch.group(1)!);
      }
    }
    return _build('⚡ Source File', lines.length, const [], classes, funcs);
  }

  static String _yaml(String content) {
    final lines = content.split('\n');
    final keys = <String>[];
    for (final line in lines) {
      final match = RegExp(r'^(\w[\w-]*)\s*:').firstMatch(line);
      if (match != null) keys.add(match.group(1)!);
    }
    final buffer = StringBuffer();
    buffer.writeln('⚙️ YAML Config • ${lines.length} lines');
    buffer.writeln();
    if (keys.isNotEmpty) {
      buffer.writeln('🔑 Top-level keys (${keys.length}):');
      for (final k in keys.take(30)) {
        buffer.writeln('   • $k');
      }
    }
    return buffer.toString().trim();
  }

  static String _xml(String content) {
    final tags = RegExp(r'<([\w:]+)')
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toSet()
        .toList()
      ..sort();
    final buffer = StringBuffer();
    buffer.writeln('📄 XML Document • ${content.split('\n').length} lines');
    buffer.writeln();
    buffer.writeln('🏷 Tags (${tags.length}):');
    for (final t in tags.take(30)) {
      buffer.writeln('   • <$t>');
    }
    return buffer.toString().trim();
  }

  static String _shell(String content) {
    final funcs = RegExp(r'^(\w+)\s*\(\)', multiLine: true)
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toList();
    final buffer = StringBuffer();
    buffer.writeln('⌨️ Shell Script • ${content.split('\n').length} lines');
    if (funcs.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('⚙️ Functions (${funcs.length}):');
      for (final f in funcs) {
        buffer.writeln('   • $f()');
      }
    }
    return buffer.toString().trim();
  }

  static Future<String> _zip(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final buffer = StringBuffer();
    buffer.writeln('📦 ZIP Archive');
    buffer.writeln('${archive.files.length} entries');
    buffer.writeln();
    for (final file in archive.files.take(50)) {
      final icon = file.isFile ? '📄' : '📁';
      final size = file.isFile ? '  (${_formatSize(file.size)})' : '';
      buffer.writeln('$icon ${file.name}$size');
    }
    if (archive.files.length > 50) {
      buffer.writeln('… +${archive.files.length - 50} more');
    }
    return buffer.toString().trim();
  }

  static String _generic(CodeFile file, String content) {
    final lines = content.split('\n');
    final buffer = StringBuffer();
    buffer.writeln('📄 ${file.extension.toUpperCase()} File');
    buffer.writeln('Lines: ${lines.length}');
    buffer.writeln('Chars: ${content.length}');
    buffer.writeln();
    buffer.writeln('Preview:');
    for (final line in lines.take(10)) {
      final preview = line.length > 70 ? '${line.substring(0, 70)}…' : line;
      buffer.writeln('  $preview');
    }
    return buffer.toString().trim();
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  static String _build(
    String title,
    int lines,
    List<String> imports,
    List<String> classes,
    List<String> funcs,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('$title • $lines lines');
    buffer.writeln();
    if (imports.isNotEmpty) {
      buffer.writeln('📥 Imports (${imports.length}):');
      for (final i in imports.take(20)) {
        buffer.writeln('   • $i');
      }
      if (imports.length > 20) {
        buffer.writeln('   … +${imports.length - 20} more');
      }
      buffer.writeln();
    }
    if (classes.isNotEmpty) {
      buffer.writeln('🏛 Classes (${classes.length}):');
      for (final c in classes) {
        buffer.writeln('   • $c');
      }
      buffer.writeln();
    }
    if (funcs.isNotEmpty) {
      buffer.writeln('⚙️ Functions (${funcs.length}):');
      for (final f in funcs.take(30)) {
        buffer.writeln('   • $f()');
      }
      if (funcs.length > 30) {
        buffer.writeln('   … +${funcs.length - 30} more');
      }
    }
    if (imports.isEmpty && classes.isEmpty && funcs.isEmpty) {
      buffer.writeln('(No declarations detected)');
    }
    return buffer.toString().trim();
  }
}
