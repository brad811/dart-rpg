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
  
  Set<Character> characters;
  int curCharacterNum = 0;
  
  Player(this.characters);

  Character getCurCharacter() {
    return characters.elementAt(curCharacterNum);
  }
  
  @override
  void handleInput(List<InputCode> inputCodes) {
    if(!inputEnabled)
      return;
    
    if(inputCodes.contains(InputCode.CONFIRM))
      interact();
    
    if(inputCodes.contains(InputCode.START)) {
      Gui.showStartMenu();
    }

    Character curCharacter = getCurCharacter();
    
    if(inputCodes.contains(InputCode.BACK))
      curCharacter.curSpeed = curCharacter.runSpeed;
    else
      curCharacter.curSpeed = curCharacter.walkSpeed;
      
    if(inputCodes.contains(InputCode.LEFT)) {
      curCharacter.move(Character.LEFT);
      return;
    }
    if(inputCodes.contains(InputCode.RIGHT)) {
      curCharacter.move(Character.RIGHT);
      return;
    }
    if(inputCodes.contains(InputCode.UP)) {
      curCharacter.move(Character.UP);
      return;
    }
    if(inputCodes.contains(InputCode.DOWN)) {
      curCharacter.move(Character.DOWN);
      return;
    }
  }
  
  void checkForBattle() {
    // check for line-of-sight battles
    for(Character character in World.characters.values) {
      if(character.map != Main.world.curMap)
        continue;
      
      Character curCharacter = getCurCharacter();

      for(int i=1; i<=character.sightDistance; i++) {
        // check that character is facing the proper direction
        if(
          (
            character.direction == Character.UP &&
            (curCharacter.mapX == character.mapX && curCharacter.mapY + i == character.mapY)
          ) || (
            character.direction == Character.DOWN &&
            (curCharacter.mapX == character.mapX && curCharacter.mapY - i == character.mapY)
          ) || (
            character.direction == Character.LEFT &&
            (curCharacter.mapX + i == character.mapX && curCharacter.mapY == character.mapY)
          ) || (
            character.direction == Character.RIGHT &&
            (curCharacter.mapX - i == character.mapX && curCharacter.mapY == character.mapY)
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

          Character curCharacter = getCurCharacter();
          
          // Find out which direction the character should move in
          // and how far the character needs to move
          if(curCharacter.mapX > otherCharacter.mapX) {
            movementDirection = Character.RIGHT;
            movementAmount = curCharacter.mapX - otherCharacter.mapX;
          } else if(curCharacter.mapX < otherCharacter.mapX) {
            movementDirection = Character.LEFT;
            movementAmount = otherCharacter.mapX - curCharacter.mapX;
          } else if(curCharacter.mapY > otherCharacter.mapY) {
            movementDirection = Character.DOWN;
            movementAmount = curCharacter.mapY - otherCharacter.mapY;
          } else if(curCharacter.mapY < otherCharacter.mapY) {
            movementDirection = Character.UP;
            movementAmount = otherCharacter.mapY - curCharacter.mapY;
          }
          
          // So the character end up next to the tile the player is in
          movementAmount -= 1;
          
          Main.world.chainCharacterMovement(
            otherCharacter,
            new List<int>.generate(movementAmount, (int i) => movementDirection, growable: true),
            otherCharacter.interact
          );
        }));
        
        characterGameEvents[0].trigger(getCurCharacter());
      })
    ];
    
    DelayedGameEvent.executeDelayedEvents(delayedGameEvents);
  }
  
  void interact() {
    Character curCharacter = getCurCharacter();

    if(curCharacter.direction == Character.LEFT && Main.world.isInteractable(curCharacter.mapX-1, curCharacter.mapY)) {
      Main.world.interact(curCharacter.mapX-1, curCharacter.mapY);
    } else if(curCharacter.direction == Character.RIGHT && Main.world.isInteractable(curCharacter.mapX+1, curCharacter.mapY)) {
      Main.world.interact(curCharacter.mapX+1, curCharacter.mapY);
    } else if(curCharacter.direction == Character.UP && Main.world.isInteractable(curCharacter.mapX, curCharacter.mapY-1)) {
      Main.world.interact(curCharacter.mapX, curCharacter.mapY-1);
    } else if(curCharacter.direction == Character.DOWN && Main.world.isInteractable(curCharacter.mapX, curCharacter.mapY+1)) {
      Main.world.interact(curCharacter.mapX, curCharacter.mapY+1);
    }
  }
}