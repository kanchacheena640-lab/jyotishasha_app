import 'package:share_plus/share_plus.dart';

class ShareUtils {
  static Future<void> shareText(String text) async {
    await Share.share(text);
  }

  static Future<void> shareImage(String path, {String? text}) async {
    await Share.shareXFiles([XFile(path)], text: text);
  }
}
