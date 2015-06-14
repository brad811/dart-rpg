library dart_rpg.item;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/text_game_event.dart';

class Item {
  final int pictureId = 237;
  final String name = "Item";
  final int basePrice = 100;
  final String description = "This is an item!";
  
  TextGameEvent use(Battler target) {
    return null;
  }
}