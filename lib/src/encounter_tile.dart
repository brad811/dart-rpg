library EncounterTile;

import 'dart:math' as math;

import 'package:dart_rpg/src/battle.dart';
import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class EncounterTile extends Tile {
  math.Random rand = new math.Random();
  
  EncounterTile(Sprite sprite) : super(false, sprite) {
    // TODO: add list of possible enemies with probabilities
  }
  
  void enter() {
    double chance = rand.nextDouble();
    if(chance < 0.8) {
      Main.player.motionCallback = () {
        Main.battle = new Battle(
            new Battler(100, 10, ["Punch", "Kick", "Meditate", "Flinch"]),
            new Battler(100, 8, ["Poke", "Headbutt", "Flail", "Attack 74b"])
        );
        Main.battle.start();
      };
    }
  }
}