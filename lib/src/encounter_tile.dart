library EncounterTile;

import 'dart:math' as math;

import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class EncounterTile extends Tile {
  math.Random rand = new math.Random();
  
  EncounterTile(Sprite sprite) : super(false, sprite) {
    
  }
  
  void enter() {
    if(rand.nextDouble() < 0.1) {
      print("Encounter!");
    }
  }
}