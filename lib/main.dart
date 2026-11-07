import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';

import 'app/wbs_player_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initializes the libmpv based playback backend; required before any
  // Player instance is created.
  MediaKit.ensureInitialized();
  runApp(const WbsPlayerApp());
}
