import 'dart:io';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';

/// Picks an image, lets the user crop/zoom it to a square, and copies the
/// result into the app's documents directory so it survives temp-file cleanup.
class ImagePickerService {
  ImagePickerService();

  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndCropSquare({bool fromCamera = false}) async {
    final XFile? picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      // Square aspect. The crop UI supports pinch/drag zoom by default.
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.png,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '画像をトリミング',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: AppColors.onPrimary,
          activeControlsWidgetColor: AppColors.primary,
          lockAspectRatio: true,
          hideBottomControls: false,
          initAspectRatio: CropAspectRatioPreset.square,
        ),
        IOSUiSettings(
          title: '画像をトリミング',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: false,
        ),
      ],
    );
    if (cropped == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'sub_images'));
    if (!imagesDir.existsSync()) imagesDir.createSync(recursive: true);
    final dest = p.join(imagesDir.path,
        'icon_${DateTime.now().millisecondsSinceEpoch}.png');
    final saved = await File(cropped.path).copy(dest);
    return saved.path;
  }
}
