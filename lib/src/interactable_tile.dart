library InteractableTile;

import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class InteractableTile extends Tile implements Interactable {
  InteractableTile(bool solid, Sprite sprite) : super(solid, sprite);
  
  void interact() {
    // TODO
  }
}