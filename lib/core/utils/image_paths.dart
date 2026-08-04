import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves subscription icon images.
///
/// Images are stored inside the app's documents directory, but on iOS the
/// absolute container path changes on every reinstall / dev build — so an
/// absolute path saved earlier stops resolving and the icon "disappears".
/// To survive that, we persist only the **file name** and resolve it against
/// the *current* documents directory at read time.
class ImagePaths {
  ImagePaths._();

  static const folder = 'sub_images';

  /// Cached absolute path of the images folder. Populated once at startup by
  /// [init] so widgets can resolve paths synchronously (e.g. `existsSync`).
  static String? _dir;

  /// Absolute path of the images directory, creating it if needed.
  static Future<String> ensureDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, folder));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _dir = dir.path;
    return dir.path;
  }

  /// Must be awaited once during app startup so [resolve] works synchronously.
  static Future<void> init() => ensureDir();

  /// Turns a stored value into a concrete [File], or null when unset.
  ///
  /// Accepts both the new relative form (just a file name) and any legacy
  /// absolute path that still happens to resolve.
  static File? resolve(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    // Legacy absolute path that still exists on disk.
    if (p.isAbsolute(stored) && File(stored).existsSync()) {
      return File(stored);
    }
    // Relative form (file name) resolved against the current images dir.
    final base = _dir;
    if (base != null) {
      final f = File(p.join(base, p.basename(stored)));
      if (f.existsSync()) return f;
    }
    // Last resort: maybe it's an absolute path we can still point at.
    return p.isAbsolute(stored) ? File(stored) : null;
  }
}
