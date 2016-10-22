library dart_rpg.input_handler;

import 'package:dart_rpg/src/input.dart';

abstract class InputHandler {
  void handleInput(List<InputCode> inputCodes);
}