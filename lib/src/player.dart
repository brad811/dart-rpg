library dart_rpg.player;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/delayed_game_event.dart';

class Player implements InputHandler {
  bool inputEnabled = true;
  
  Character character;
  
  Player(this.character);
  
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
      character.curSpeed = character.runSpeed;
    else
      character.curSpeed = character.walkSpeed;
      
    if(keyCodes.contains(Input.LEFT)) {
      character.move(Character.LEFT);
      return;
    }
    if(keyCodes.contains(Input.RIGHT)) {
      character.move(Character.RIGHT);
      return;
    }
    if(keyCodes.contains(Input.UP)) {
      character.move(Character.UP);
      return;
    }
    if(keyCodes.contains(Input.DOWN)) {
      character.move(Character.DOWN);
      return;
    }
  }
  
  void checkForBattle() {
    // check for line-of-sight battles
    for(Character character in World.characters.values) {
      if(character.map != Main.world.curMap)
        continue;
      
      for(int i=1; i<=character.sightDistance; i++) {
        // check that character is facing the proper direction
        if(
          (
            character.direction == Character.UP &&
            (Main.player.character.mapX == character.mapX && Main.player.character.mapY + i == character.mapY)
          ) || (
            character.direction == Character.DOWN &&
            (Main.player.character.mapX == character.mapX && Main.player.character.mapY - i == character.mapY)
          ) || (
            character.direction == Character.LEFT &&
            (Main.player.character.mapX + i == character.mapX && Main.player.character.mapY == character.mapY)
          ) || (
            character.direction == Character.RIGHT &&
            (Main.player.character.mapX - i == character.mapX && Main.player.character.mapY == character.mapY)
          )
        ) {
          startCharacterEncounter(character);
          
          // TODO: should we not return in case you are in sight of more than
          // one character? This would allow for simple consecutive battles
          return;
        }
      }
    }
  }
  
  void startCharacterEncounter(Character otherCharacter) {
    Main.player.inputEnabled = false;
    
    Tile target = Main.world.maps[Main.world.curMap]
        .tiles[otherCharacter.mapY - otherCharacter.sizeY][otherCharacter.mapX][World.layers.length-1];
    
    Tile before = null;
    if(target != null)
      before = new Tile(target.solid, target.sprite, target.layered);
    
    List<DelayedGameEvent> delayedGameEvents = [
      new DelayedGameEvent(0, () {
        Main.timeScale = 0.0;
        // TODO: give this icon an assigned location on the sprite sheet
        Main.world.maps[Main.world.curMap]
          .tiles[otherCharacter.mapY - otherCharacter.sizeY][otherCharacter.mapX][World.layers.length-1] =
            new Tile(false, new Sprite.int(99, otherCharacter.mapX, otherCharacter.mapY - otherCharacter.sizeY));
      }),
      new DelayedGameEvent(500, () {
        Main.timeScale = 1.0;
        Main.world.maps[Main.world.curMap]
          .tiles[otherCharacter.mapY - otherCharacter.sizeY][otherCharacter.mapX][World.layers.length-1] = before;
        
        List<GameEvent> characterGameEvents = [];
        characterGameEvents.add(new GameEvent((callback) {
          int movementDirection, movementAmount;
          
          // Find out which direction the character should move in
          // and how far the character needs to move
          if(character.mapX > otherCharacter.mapX) {
            movementDirection = Character.RIGHT;
            movementAmount = character.mapX - otherCharacter.mapX;
          } else if(character.mapX < otherCharacter.mapX) {
            movementDirection = Character.LEFT;
            movementAmount = otherCharacter.mapX - character.mapX;
          } else if(character.mapY > otherCharacter.mapY) {
            movementDirection = Character.DOWN;
            movementAmount = character.mapY - otherCharacter.mapY;
          } else if(character.mapY < otherCharacter.mapY) {
            movementDirection = Character.UP;
            movementAmount = otherCharacter.mapY - character.mapY;
          }
          
          // So the character end up next to the tile the player is in
          movementAmount -= 1;
          
          Main.world.chainCharacterMovement(
            otherCharacter,
            new List<int>.generate(movementAmount, (int i) => movementDirection, growable: true),
            otherCharacter.interact
          );
        }));
        
        characterGameEvents[0].trigger(this.character);
      })
    ];
    
    DelayedGameEvent.executeDelayedEvents(delayedGameEvents);
  }
  
  void interact() {
    if(character.direction == Character.LEFT && Main.world.isInteractable(character.mapX-1, character.mapY)) {
      Main.world.interact(character.mapX-1, character.mapY);
    } else if(character.direction == Character.RIGHT && Main.world.isInteractable(character.mapX+1, character.mapY)) {
      Main.world.interact(character.mapX+1, character.mapY);
    } else if(character.direction == Character.UP && Main.world.isInteractable(character.mapX, character.mapY-1)) {
      Main.world.interact(character.mapX, character.mapY-1);
    } else if(character.direction == Character.DOWN && Main.world.isInteractable(character.mapX, character.mapY+1)) {
      Main.world.interact(character.mapX, character.mapY+1);
    }
  }
}