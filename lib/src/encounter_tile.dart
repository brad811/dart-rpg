library EncounterTile;

import 'dart:math' as math;

import 'package:dart_rpg/src/battle.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class EncounterTile extends Tile {
  math.Random rand = new math.Random();
  
  EncounterTile(Sprite sprite) : super(false, sprite) {
    
  }
  
  void enter() {
    double chance = rand.nextDouble();
    if(chance < 0.1) {
      Main.battle = new Battle();
      Main.battle.start();
    }
  }
}