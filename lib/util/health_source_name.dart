import 'package:flutter/foundation.dart';

// brand names, the same in every language
String healthSourceName() =>
    defaultTargetPlatform == TargetPlatform.iOS
        ? 'Apple Health'
        : 'Health Connect';
