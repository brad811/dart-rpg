library InteractableTile;

import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class InteractableTile extends Tile implements Interactable {
  var handler;
  
  InteractableTile(bool solid, Sprite sprite, void handler()) : super(solid, sprite) {
    this.handler = handler;
  }
  
  void interact() {
    handler();
  }
}