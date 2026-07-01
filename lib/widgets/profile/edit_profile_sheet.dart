import 'dart:io';

import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/unsaved_changes_guard.dart';
import 'package:habitt/util/profile_image_util.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:habitt/providers/profile_image_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  bool _isExitDialogOpen = false;
  bool _allowPop = false;
  final closeResult = false;
  final scrollController = ScrollController();
  late bool hasUnsavedChanges = false;

  bool _unsavedChangesCheck() => hasUnsavedChanges;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _selectedImage;
  String? _originalImagePath;
  String _originalName = '';
  bool _isPickingImage = false;

  void _popSheet({required bool result}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _allowPop = true;
    });
    Navigator.of(context).pop(result);
  }

  Future<void> _showExitConfirmation(bool allowPop) async {
    if (_isExitDialogOpen) {
      return;
    }
    final loc = AppLocalizations.of(context)!;

    final title = loc.exitWithoutSaving;
    final desc = loc.allChangesYouMadeWillBeDiscarded;

    _isExitDialogOpen = true;
    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => NewDefaultDialog(
            title: title,
            desc: desc,
            primaryButtonLabel: loc.exit,
            onPrimaryButtonPressed: () {
              Navigator.of(dialogContext).pop();
              _popSheet(result: closeResult);
            },
          ),
    );
    _isExitDialogOpen = false;
  }

  Future<void> _handleCloseAttempt() async {
    if (_allowPop || !hasUnsavedChanges) {
      _popSheet(result: closeResult);
      return;
    }

    await _showExitConfirmation(closeResult);
  }

  Future<void> _pickImage() async {
    setState(() {
      _isPickingImage = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _removeImage() async {
    // Clear both selected preview and original preview immediately
    setState(() {
      _selectedImage = null;
      _originalImagePath = null;
      hasUnsavedChanges = true;
    });
  }

  @override
  void initState() {
    super.initState();
    UnsavedChangesGuard.register(_unsavedChangesCheck);
    _initControllers();
  }

  void _initControllers() async {
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('name') ?? '';
    _emailController.text = prefs.getString('backup_user_email') ?? '';

    // Load existing profile image path and original name
    final imagePath = await getProfileImagePath();
    setState(() {
      _originalImagePath = imagePath;
      _originalName = prefs.getString('name') ?? '';
    });

    // Listen for text changes to detect unsaved changes
    _nameController.addListener(_updateUnsavedChanges);
    _emailController.addListener(_updateUnsavedChanges);
  }

  void _updateUnsavedChanges() {
    final nameChanged = _nameController.text.trim() != _originalName;
    final imageAdded = _selectedImage != null;
    final imageRemoved = _selectedImage == null && _originalImagePath != null;
    setState(() {
      hasUnsavedChanges = nameChanged || imageAdded || imageRemoved;
    });
  }

  @override
  void dispose() {
    UnsavedChangesGuard.unregister(_unsavedChangesCheck);
    _nameController.removeListener(_updateUnsavedChanges);
    _emailController.removeListener(_updateUnsavedChanges);
    _nameController.dispose();
    _emailController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Widget _buildImageButton(ColorProvider cp) {
    if (_isPickingImage) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(cp.lightGreyText),
        ),
      );
    }

    return SizedBox(
      width: 20,
      height: 20,
      child: SvgPicture.asset(
        "assets/images/new-svg/upload-photo.svg",
        colorFilter: ColorFilter.mode(cp.lightGreyText, BlendMode.srcIn),
      ),
    );
  }

  Widget? _buildImageContent(ColorProvider cp) {
    if (_selectedImage != null || _originalImagePath != null) {
      final displayFile =
          _selectedImage != null ? _selectedImage! : File(_originalImagePath!);

      return SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(displayFile, fit: BoxFit.cover),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: NewCircleButton(
                    width: 28,
                    height: 28,
                    onPressed: _removeImage,
                    svgPath: "assets/images/new-svg/close.svg",
                    cnIcon: CNSymbol("xmark", size: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = mediaQuery.size.height - 59 - 16;
    final canSave = hasUnsavedChanges;
    final loc = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _allowPop || !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _handleCloseAttempt();
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: SingleChildScrollView(
              controller: scrollController,
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    topSection(context, cp, canSave),
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16, top: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 20,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 20,
                            children: [
                              Text(
                                loc.uploadPhoto,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: _isPickingImage ? null : _pickImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Center(
                                    child:
                                        _buildImageContent(cp) ??
                                        Center(
                                          child: DottedBorder(
                                            options:
                                                RoundedRectDottedBorderOptions(
                                                  dashPattern: [10, 5],
                                                  strokeWidth: 1,
                                                  radius: Radius.circular(24),
                                                  color: cp.disabled,
                                                  padding: EdgeInsets.all(48),
                                                ),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              clipBehavior: Clip.antiAlias,
                                              decoration: ShapeDecoration(
                                                color: cp.field,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                ),
                                              ),
                                              child: _buildImageButton(cp),
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.profileDetails,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              NewDefaultTextField(
                                topPadding: 20,
                                title: loc.name,
                                hint: loc.yourUsername,
                                controller: _nameController,
                              ),
                              NewDefaultTextField(
                                topPadding: 10,
                                title: loc.email,
                                enabled: false,
                                hint: loc.youDontHaveAnEmailYet,
                                controller: _emailController,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Padding topSection(BuildContext context, ColorProvider cp, bool canSave) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  _handleCloseAttempt();
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 16),
                  color: Colors.transparent,
                  height: 36,
                  width: 66 + 16,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SvgPicture.asset(
                      "assets/images/new-svg/back.svg",
                      colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: NewDefaultButton.primarySmall(
                  width: null,
                  enabled: canSave,
                  onPressed: () async {
                    if (!canSave) return;

                    final prefs = await SharedPreferences.getInstance();
                    final storedName = prefs.getString('name') ?? '';
                    final storedImagePath = await getProfileImagePath();

                    final nameChanged =
                        _nameController.text.trim() != storedName;
                    final imageAdded = _selectedImage != null;
                    final imageRemoved =
                        _selectedImage == null && storedImagePath != null;

                    if (!nameChanged && !imageAdded && !imageRemoved) {
                      // Nothing to save
                      setState(() {
                        hasUnsavedChanges = false;
                      });
                      if (mounted) _popSheet(result: true);
                      return;
                    }

                    if (nameChanged) {
                      await prefs.setString(
                        'name',
                        _nameController.text.trim(),
                      );
                    }

                    if (!context.mounted) {
                      debugPrint(
                        'Context not mounted after saving name, aborting pop',
                      );
                      return;
                    }

                    final profileImageProvider =
                        context.read<ProfileImageProvider>();

                    if (imageAdded) {
                      // Use provider to save and update cached image
                      await profileImageProvider.save(_selectedImage!, context);
                    } else if (imageRemoved) {
                      await profileImageProvider.remove();
                    }

                    // Update originals
                    _originalName =
                        prefs.getString('name') ?? _nameController.text.trim();
                    _originalImagePath = await getProfileImagePath();

                    setState(() {
                      hasUnsavedChanges = false;
                    });

                    if (mounted) _popSheet(result: true);
                  },
                  label: loc.save,
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              loc.editProfile,
              style: TextStyle(
                color: cp.text,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
