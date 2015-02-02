library Battle;

import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/gui.dart';

class Battle {
  static void tick() {
    Gui.renderWindow(12, 12, 8, 4);
    Font.renderStaticText(26.0, 26.0, "Fight");
  }
}