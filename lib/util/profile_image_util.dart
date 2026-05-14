import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _profileImagePathKey = 'profile_image_path';
const String _profileImageFileName = 'profile_picture.jpg';

/// Saves an image file to the application documents directory
/// and stores the path in SharedPreferences
Future<String?> saveProfileImage(File imageFile) async {
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    final profileImagePath = '${appDocDir.path}/$_profileImageFileName';

    // Copy the selected image to the app documents directory
    final savedImage = await imageFile.copy(profileImagePath);

    // Store the path in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImagePathKey, savedImage.path);

    return savedImage.path;
  } catch (e) {
    print('Error saving profile image: $e');
    return null;
  }
}

/// Retrieves the stored profile image path from SharedPreferences
Future<String?> getProfileImagePath() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImagePathKey);
  } catch (e) {
    print('Error retrieving profile image path: $e');
    return null;
  }
}

/// Checks if the profile image file exists on disk
Future<bool> profileImageExists() async {
  try {
    final imagePath = await getProfileImagePath();
    if (imagePath == null) {
      return false;
    }
    return File(imagePath).existsSync();
  } catch (e) {
    print('Error checking profile image existence: $e');
    return false;
  }
}

/// Deletes the profile image file and clears the path from SharedPreferences
Future<bool> deleteProfileImage() async {
  try {
    final imagePath = await getProfileImagePath();
    if (imagePath != null) {
      final imageFile = File(imagePath);
      if (imageFile.existsSync()) {
        await imageFile.delete();
      }
    }

    // Clear the path from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileImagePathKey);

    return true;
  } catch (e) {
    print('Error deleting profile image: $e');
    return false;
  }
}

/// Gets the profile image file if it exists
Future<File?> getProfileImageFile() async {
  try {
    final imagePath = await getProfileImagePath();
    if (imagePath == null) {
      return null;
    }
    final imageFile = File(imagePath);
    if (imageFile.existsSync()) {
      return imageFile;
    }
    // If file doesn't exist, clear the path
    await deleteProfileImage();
    return null;
  } catch (e) {
    print('Error getting profile image file: $e');
    return null;
  }
}
