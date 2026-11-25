// Converts the flat SVG artwork the Android home screen widgets use into
// VectorDrawables. Only what those files contain is supported: <path>
// elements with fill, fill-opacity, opacity and fill-rule. Groups, filters
// (the drop shadow of streak-fade.svg), clip paths and defs are dropped.
//
//   dart run tool/svg_to_vector_drawable.dart
//
// See docs/home_widgets.md.
import 'dart:io';

const _out = 'android/app/src/main/res/drawable';

const _files = {
  'assets/images/new-svg/streak.svg': 'widget_art_streak',
  'assets/images/new-svg/streak-fade.svg': 'widget_art_streak_fade',
  'assets/images/new-svg/ice-left.svg': 'widget_art_ice_left',
  'assets/images/new-svg/ice-over.svg': 'widget_art_ice_over',
};

void main() {
  for (final entry in _files.entries) {
    final svg = File(entry.key).readAsStringSync();
    final xml = convert(svg, source: entry.key);
    File('$_out/${entry.value}.xml').writeAsStringSync(xml);
    stdout.writeln('${entry.key} -> $_out/${entry.value}.xml');
  }
}

String convert(String svg, {required String source}) {
  final root = RegExp(r'<svg\b([^>]*)>').firstMatch(svg)!.group(1)!;
  final width = _attr(root, 'width')!;
  final height = _attr(root, 'height')!;
  final viewBox = (_attr(root, 'viewBox') ?? '0 0 $width $height')
      .split(RegExp(r'[\s,]+'))
      .map(double.parse)
      .toList();

  // drop <defs> (filters, clip paths) before looking for paths
  final body = svg.replaceAll(RegExp(r'<defs>[\s\S]*?</defs>'), '');
  final buffer =
      StringBuffer()
        ..writeln('<?xml version="1.0" encoding="utf-8"?>')
        ..writeln(
          '<!-- Generated from $source by tool/svg_to_vector_drawable.dart. Do not edit. -->',
        )
        ..writeln(
          '<vector xmlns:android="http://schemas.android.com/apk/res/android"',
        )
        ..writeln('    android:width="${width}dp"')
        ..writeln('    android:height="${height}dp"')
        ..writeln('    android:viewportWidth="${_num(viewBox[2])}"')
        ..writeln('    android:viewportHeight="${_num(viewBox[3])}">');

  final translate =
      viewBox[0] != 0 || viewBox[1] != 0
          ? (-viewBox[0], -viewBox[1])
          : null;
  if (translate != null) {
    buffer.writeln(
      '    <group android:translateX="${_num(translate.$1)}" android:translateY="${_num(translate.$2)}">',
    );
  }
  for (final m in RegExp(r'<path\b([^>]*?)/?>').allMatches(body)) {
    final a = m.group(1)!;
    final d = _attr(a, 'd');
    if (d == null) continue;
    final fill = _color(_attr(a, 'fill') ?? '#000000');
    if (fill == null) continue; // fill="none"
    final alpha =
        double.parse(_attr(a, 'opacity') ?? '1') *
        double.parse(_attr(a, 'fill-opacity') ?? '1');
    final indent = translate != null ? '        ' : '    ';
    buffer.writeln('$indent<path');
    buffer.writeln('$indent    android:fillColor="$fill"');
    if (alpha < 1) {
      buffer.writeln('$indent    android:fillAlpha="${_num(alpha)}"');
    }
    if (_attr(a, 'fill-rule') == 'evenodd') {
      buffer.writeln('$indent    android:fillType="evenOdd"');
    }
    buffer.writeln('$indent    android:pathData="$d"/>');
  }
  if (translate != null) buffer.writeln('    </group>');
  buffer.writeln('</vector>');
  return buffer.toString();
}

String? _attr(String attrs, String name) =>
    RegExp('(?:^|\\s)$name="([^"]*)"').firstMatch(attrs)?.group(1);

String? _color(String value) {
  final v = value.trim().toLowerCase();
  if (v == 'none') return null;
  const named = {'white': '#FFFFFF', 'black': '#000000'};
  if (named.containsKey(v)) return named[v];
  if (RegExp(r'^#[0-9a-f]{6}$').hasMatch(v)) return v.toUpperCase();
  if (RegExp(r'^#[0-9a-f]{3}$').hasMatch(v)) {
    return '#${v.substring(1).split('').map((c) => '$c$c').join()}'
        .toUpperCase();
  }
  throw FormatException('Unsupported fill colour: $value');
}

String _num(double v) =>
    v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '');
