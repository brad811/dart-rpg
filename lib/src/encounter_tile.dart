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
  
  EncounterTile(Sprite sprite, [bool layered]) : super(false, sprite, layered);
  
  void enter() {
    double chance = rand.nextDouble();
    if(chance < 0.15) {
      chance = rand.nextDouble();
      
      double curWeight = 0.0;
      Battler battler;
      for(BattlerChance battlerChance in Main.world.maps[Main.world.curMap].battlerChances) {
        curWeight += battlerChance.chance;
        if(curWeight > chance) {
          battler = battlerChance.battler;
          break;
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