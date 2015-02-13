library EncounterTile;

import 'dart:math' as math;

import 'package:dart_rpg/src/attack.dart';
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
            Main.player.battler,
            new Battler(
              237, "Monster",
              14, 8, 5, // health, attack, speed
              [
                new Attack("Poke", 2),
                new Attack("Headbutt", 4),
                new Attack("Flail", 3),
                new Attack("Attack 74b", 5)
              ],
              12 // experiencePayout
            )
        );
        
        Main.battle.start();
      };
    }
  }
}