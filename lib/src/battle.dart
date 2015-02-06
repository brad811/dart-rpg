library Battle;

import 'package:dart_rpg/src/animation_game_event.dart';
import 'package:dart_rpg/src/choice_game_event.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';

class Battle implements InteractableInterface {
  GameEvent gameEvent;
  List<List<Tile>> tiles = [];
  
  ChoiceGameEvent main, fight, powers, bag, run;
  AnimationGameEvent exit;
  
  int health = 100;
  
  void start() {
    for(int y=0; y<Main.world.viewYSize; y++) {
      tiles.add([]);
      for(int x=0; x<Main.world.viewXSize; x++) {
        tiles[y].add(new Tile(false, new Sprite.int(Tile.GROUND, x, y)));
      }
    }
    
    exit = new AnimationGameEvent((callback) {
      Main.focusObject = Main.player;
      Gui.windows.removeRange(0, Gui.windows.length);
      Main.inBattle = false;
    });
    
    fight = new ChoiceGameEvent.custom(
      this,
      ["Punch", "Kick", "Throw", "Fire"],
      [
        [new AnimationGameEvent((callback) { attack(); })],
        [new AnimationGameEvent((callback) { attack(); })],
        [new AnimationGameEvent((callback) { attack(); })],
        [new AnimationGameEvent((callback) { attack(); })],
      ],
      5, 14, 10, 2
    );
    fight.remove = false;
    
    main = new ChoiceGameEvent.custom(
      this,
      ["Fight", "Powers", "Bag", "Run"],
      [[fight], [fight], [fight], [fight]],
      15, 14, 5, 2
    );
    main.remove = false;
    
    Main.inBattle = true;
    main.trigger();
  }
  
  void attack() {
    health -= 10;
    if(health <= 0) {
      exit.trigger();
    } else {
      Gui.windows.removeRange(0, Gui.windows.length);
      main.trigger();
    }
  }
  
  void tick() {
    
  }
  
  void render() {
    for(int y=0; y<Main.world.viewYSize; y++) {
      for(int x=0; x<Main.world.viewXSize; x++) {
        tiles[y][x].sprite.renderStatic();
      }
    }
    
    Main.ctx.fillRect(
      10 * Sprite.spriteScale, 10 * Sprite.spriteScale,
      health * Sprite.spriteScale, 4 * Sprite.spriteScale
    );
  }
}