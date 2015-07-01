library dart_rpg.item;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

class Item {
  final int pictureId;
  final String name;
  final int basePrice;
  final String description;
  
  Item([
    this.pictureId = 237,
    this.name = "Item",
    this.basePrice = 100,
    this.description = "This is an item!"
  ]);
  
  TextGameEvent use(Battler target) {
    return null;
  }
}