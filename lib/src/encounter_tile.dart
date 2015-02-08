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
            new Battler(
              238,
              100, 10,
              [
                new Attack("Punch", 10),
                new Attack("Kick", 10),
                new Attack("Meditate", 10),
                new Attack("Flinch", 10)
              ]
            ),
            new Battler(
              238,
              100, 8,
              [
                new Attack("Poke", 8),
                new Attack("Headbutt", 8),
                new Attack("Flail", 8),
                new Attack("Attack 74b", 8)
              ]
            )
        );
        
        Main.battle.start();
      };
    }
  }
}