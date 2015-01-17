library InputHandler;

import 'package:dart_rpg/src/world.dart';

abstract class InputHandler {
  void handleKey(int keyCode, World world);
}
