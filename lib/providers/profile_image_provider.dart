import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:habitt/util/profile_image_util.dart';

class ProfileImageProvider extends ChangeNotifier {
  File? _imageFile;
  int _version = 0;

  File? get imageFile => _imageFile;
  int get version => _version;

  /// Load image file from persisted path
  Future<void> load() async {
    final file = await getProfileImageFile();
    _imageFile = file;
    notifyListeners();
  }

  /// Save picked file to app storage and update cached file
  Future<String?> save(File pickedFile, BuildContext? ctx) async {
    final savedPath = await saveProfileImage(pickedFile);
    if (savedPath != null) {
      // Evict previous cached image if exists
      if (_imageFile != null) {
        try {
          await FileImage(_imageFile!).evict();
        } catch (_) {}
      }

      _imageFile = File(savedPath);
      _version++;

      // Precache new image if context provided
      if (ctx != null) {
        try {
          await precacheImage(FileImage(_imageFile!), ctx);
        } catch (_) {}
      }

      notifyListeners();
    }

    return savedPath;
  }

  /// Delete persisted image and clear cache
  Future<bool> remove() async {
    final existed = await deleteProfileImage();
    _imageFile = null;
    _version++;
    notifyListeners();
    return existed;
  }
}
