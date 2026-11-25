// Generates the iOS home screen widget artwork: the asset catalog image sets
// of ios/HabittWidgets/Assets.xcassets. Run after changing any source SVG:
//
//   dart run tool/gen_ios_widget_art.dart
//
// - art_*: the app's SVGs from assets/images/new-svg, as vectors. Filters
//   (streak-fade's drop shadow) and clip paths are dropped: the asset
//   catalog's SVG renderer does not support them, and the Android widgets
//   drop the shadow too.
// - icon_*: the widgets' small template icons (tinted in SwiftUI), the same
//   paths as the Android `widget_*` masks and the design canvas.
// See docs/home_widgets.md.
import 'dart:convert';
import 'dart:io';

const _src = 'assets/images/new-svg';
const _out = 'ios/HabittWidgets/Assets.xcassets';

const art = {
  'art_streak': 'streak.svg',
  'art_streak_fade': 'streak-fade.svg',
  'art_ice_left': 'ice-left.svg',
  'art_ice_over': 'ice-over.svg',
  'art_empty_box': 'empty-box.svg',
};

const icons = {
  'icon_sun':
      '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<circle cx="8" cy="8" r="3.2" stroke="#000" stroke-width="1.5"/>'
      '<path d="M8 1.5V3M8 13V14.5M1.5 8H3M13 8H14.5M3.4 3.4L4.4 4.4M11.6 11.6L12.6 12.6M3.4 12.6L4.4 11.6M11.6 4.4L12.6 3.4" stroke="#000" stroke-width="1.5" stroke-linecap="round"/>'
      '</svg>',
  'icon_moon':
      '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M13.5 9.6A5.6 5.6 0 1 1 6.4 2.5a4.6 4.6 0 0 0 7.1 7.1Z" stroke="#000" stroke-width="1.5" stroke-linejoin="round"/>'
      '</svg>',
  'icon_anytime':
      '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<circle cx="8" cy="8" r="6.25" stroke="#000" stroke-width="1.5"/>'
      '<path d="M8 4.6V8L10.4 9.6" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>'
      '</svg>',
  // the app's check mark, 24 box (done / todo indicators)
  'icon_check':
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M18.5486 8.60578C18.5488 8.7974 18.511 8.98717 18.4376 9.16415C18.3641 9.34114 18.2564 9.50185 18.1206 9.63703L11.3317 16.4269C11.058 16.7001 10.6871 16.8535 10.3005 16.8535C9.91377 16.8535 9.54288 16.7001 9.26921 16.4269L5.88718 13.0444C5.74229 12.9111 5.62584 12.75 5.54485 12.5706C5.46385 12.3912 5.41997 12.1973 5.41585 12.0005C5.41173 11.8037 5.44745 11.6081 5.52087 11.4255C5.59428 11.2428 5.70388 11.0769 5.84306 10.9378C5.98224 10.7986 6.14814 10.689 6.33077 10.6156C6.51339 10.5421 6.70899 10.5064 6.90578 10.5105C7.10257 10.5147 7.29649 10.5585 7.47589 10.6395C7.65528 10.7205 7.81644 10.837 7.94968 10.9819L10.2995 13.3317L16.0562 7.57312C16.2604 7.36909 16.5204 7.23014 16.8035 7.17382C17.0866 7.1175 17.38 7.14634 17.6467 7.25669C17.9134 7.36704 18.1414 7.55395 18.3019 7.79382C18.4624 8.03369 18.5483 8.31575 18.5486 8.60437V8.60578Z" fill="#000"/>'
      '</svg>',
};

void main() {
  Directory(_out).createSync(recursive: true);
  File('$_out/Contents.json').writeAsStringSync(_json({
    'info': {'author': 'xcode', 'version': 1},
  }));

  for (final e in art.entries) {
    final svg = File('$_src/${e.value}').readAsStringSync();
    _imageSet(e.key, _clean(svg), template: false);
  }
  for (final e in icons.entries) {
    _imageSet(e.key, e.value, template: true);
  }
}

/// Drops what the asset catalog cannot render: filters and clip paths.
String _clean(String svg) => svg
    .replaceAll(RegExp(r'<defs>[\s\S]*?</defs>'), '')
    .replaceAll(RegExp(r'\s(filter|clip-path)="[^"]*"'), '');

void _imageSet(String name, String svg, {required bool template}) {
  final dir = Directory('$_out/$name.imageset')..createSync(recursive: true);
  File('${dir.path}/$name.svg').writeAsStringSync(svg);
  File('${dir.path}/Contents.json').writeAsStringSync(_json({
    'images': [
      {'filename': '$name.svg', 'idiom': 'universal'},
    ],
    'info': {'author': 'xcode', 'version': 1},
    'properties': {
      'preserves-vector-representation': true,
      'template-rendering-intent': template ? 'template' : 'original',
    },
  }));
  stdout.writeln('${dir.path}/$name.svg');
}

String _json(Object o) => '${const JsonEncoder.withIndent('  ').convert(o)}\n';
