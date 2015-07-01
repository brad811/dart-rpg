library dart_rpg.player;

import 'package:dart_rpg/src/battle.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/game_event/delayed_game_event.dart';
import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

class Player extends Character implements InputHandler {
  bool inputEnabled = true;
  
  Player(int posX, int posY) : super(Tile.PLAYER, 238, posX, posY, layer: World.LAYER_PLAYER);
  
  @override
  void handleKeys(List<int> keyCodes) {
    if(!inputEnabled)
      return;
    
    if(keyCodes.contains(Input.CONFIRM))
      interact();
    
    if(keyCodes.contains(Input.START)) {
      Gui.showStartMenu();
    }
    
    if(keyCodes.contains(Input.BACK))
      curSpeed = runSpeed;
    else
      curSpeed = walkSpeed;
      
    if(keyCodes.contains(Input.LEFT)) {
      move(Character.LEFT);
      return;
    }
    if(keyCodes.contains(Input.RIGHT)) {
      move(Character.RIGHT);
      return;
    }
    if(keyCodes.contains(Input.UP)) {
      move(Character.UP);
      return;
    }
    if(keyCodes.contains(Input.DOWN)) {
      move(Character.DOWN);
      return;
    }
  }
  
  @override
  void checkForBattle() {
    // check for line-of-sight battles
    for(Character character in Main.world.maps[Main.world.curMap].characters) {
      for(int i=1; i<=character.sightDistance; i++) {
        // check that character is facing the proper direction
        if(
          (
            character.direction == Character.UP &&
            (Main.player.mapX == character.mapX && Main.player.mapY + i == character.mapY)
          ) || (
            character.direction == Character.DOWN &&
            (Main.player.mapX == character.mapX && Main.player.mapY - i == character.mapY)
          ) || (
            character.direction == Character.LEFT &&
            (Main.player.mapX + i == character.mapX && Main.player.mapY == character.mapY)
          ) || (
            character.direction == Character.RIGHT &&
            (Main.player.mapX - i == character.mapX && Main.player.mapY == character.mapY)
          )
        ) {
          startCharacterBattle(character);
          
          // TODO: should we not return in case you are in sight of more than
          // one character? This would allow for simple consecutive battles
          return;
        }
      }
    }
  }
  
  void startCharacterBattle(Character character) {
    // TODO: make a helper class to chain together complex game events
    //   like chaining character movements, delayed game events, etc.
    Main.player.inputEnabled = false;
    
    Tile target = Main.world.maps[Main.world.curMap]
        .tiles[character.mapY - character.sizeY][character.mapX][World.LAYER_ABOVE];
    
    Tile before = null;
    if(target != null)
      before = new Tile(target.solid, target.sprite, target.layered);
    
    List<DelayedGameEvent> delayedGameEvents = [
      new DelayedGameEvent(0, () {
        Main.timeScale = 0.0;
        Main.world.maps[Main.world.curMap]
          .tiles[character.mapY - character.sizeY][character.mapX][World.LAYER_ABOVE] =
            new Tile(false, new Sprite.int(99, character.mapX, character.mapY - character.sizeY));
      }),
      new DelayedGameEvent(500, () {
        Main.timeScale = 1.0;
        Main.world.maps[Main.world.curMap]
          .tiles[character.mapY - character.sizeY][character.mapX][World.LAYER_ABOVE] = before;
        
        List<GameEvent> characterGameEvents = [];
        characterGameEvents.add(new GameEvent((callback) {
          int movementDirection, movementAmount;
          
          // Find out which direction the character should move in
          // and how far the character needs to move
          if(mapX > character.mapX) {
            movementDirection = Character.RIGHT;
            movementAmount = mapX - character.mapX;
          } else if(mapX < character.mapX) {
            movementDirection = Character.LEFT;
            movementAmount = character.mapX - mapX;
          } else if(mapY > character.mapY) {
            movementDirection = Character.DOWN;
            movementAmount = mapY - character.mapY;
          } else if(mapY < character.mapY) {
            movementDirection = Character.UP;
            movementAmount = character.mapY - mapY;
          }
          
          // So the character end up next to the tile the player is in
          movementAmount -= 1;
          
          Main.world.chainCharacterMovement(
            character,
            new List<int>.generate(movementAmount, (int i) => movementDirection, growable: true),
            () {
              new TextGameEvent(237, character.preBattleText, () {
                Gui.fadeLightAction((){},(){
                  Gui.fadeDarkAction((){}, (){
                    // start the battle!
                    character.battler.reset();
                    
                    Main.battle = new Battle(
                        Main.player.battler,
                        character.battler,
                        character.postBattleEvent
                    );
                    
                    Main.battle.start();
                    Main.player.inputEnabled = true;
                  });
                });
              }).trigger();
            }
          );
        }));
        
        characterGameEvents[0].trigger();
      })
    ];
    
    DelayedGameEvent.executeDelayedEvents(delayedGameEvents);
  }
  
  @override
  void interact() {
    if(direction == Character.LEFT && Main.world.isInteractable(mapX-1, mapY)) {
      Main.world.interact(mapX-1, mapY);
    } else if(direction == Character.RIGHT && Main.world.isInteractable(mapX+1, mapY)) {
      Main.world.interact(mapX+1, mapY);
    } else if(direction == Character.UP && Main.world.isInteractable(mapX, mapY-1)) {
      Main.world.interact(mapX, mapY-1);
    } else if(direction == Character.DOWN && Main.world.isInteractable(mapX, mapY+1)) {
      Main.world.interact(mapX, mapY+1);
    }
  }
}