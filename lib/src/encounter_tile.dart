library EncounterTile;

import 'dart:math' as math;

import 'package:dart_rpg/src/battle.dart';
import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class BattlerChance<Battler, double> {
  Battler battler;
  double chance;
  
  BattlerChance(this.battler, this.chance);
}

class EncounterTile extends Tile {
  math.Random rand = new math.Random();
  List<BattlerChance> battlerChances;
  
  EncounterTile(Sprite sprite, this.battlerChances) : super(false, sprite);
  
  void enter() {
    double chance = rand.nextDouble();
    if(chance < 0.2) {
      chance = rand.nextDouble();
      
      double minDiff = 1.0;
      Battler battler;
      for(BattlerChance battlerChance in battlerChances) {
        // find the closest battler chance over the selected chance
        if((1-battlerChance.chance) < chance && chance - (1-battlerChance.chance) < minDiff) {
          minDiff = chance - (1-battlerChance.chance);
          battler = battlerChance.battler;
        }
      }
      
      battler.reset();
      
      Main.player.motionCallback = () {
        Main.battle = new Battle(
            Main.player.battler,
            battler
        );
        
        Main.battle.start();
      };
    }
  }
}