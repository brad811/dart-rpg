library dart_rpg.input_handler;

import 'package:dart_rpg/src/input.dart';

abstract class InputHandler {
  void handleKeys(List<InputCode> keyCodes);
}