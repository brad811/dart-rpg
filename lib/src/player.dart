library Player;

import 'package:dart_rpg/src/battle.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/choice_game_event.dart';
import 'package:dart_rpg/src/delayed_game_event.dart';
import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/text_game_event.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

class Player extends Character implements InputHandler {
  bool inputEnabled = true;
  
  Player(int posX, int posY) : super(Tile.PLAYER + 17, 238, posX, posY, World.LAYER_PLAYER, 1, 2, true);
  
  @override
  void handleKeys(List<int> keyCodes) {
    if(!inputEnabled)
      return;
    
    if(keyCodes.contains(Input.CONFIRM))
      interact();
    
    if(keyCodes.contains(Input.START)) {
      // TODO: move start menu code somewhere else
      //   and have it only declared once
      ChoiceGameEvent start;
      
      // show start menu
      GameEvent exit = new GameEvent( (Function a) { Main.focusObject = this; } );
      
      GameEvent powers = new GameEvent((Function a) {
        Gui.windows.add(() {
          Gui.renderWindow(
            0, 0,
            12, 8
          );
          
          Font.renderStaticText(2.0, 2.0, "Player");
          Font.renderStaticText(2.75, 3.5, "Health: ${battler.startingHealth}");
          Font.renderStaticText(2.75, 5.0, "Physical Attack: ${battler.startingPhysicalAttack}");
          Font.renderStaticText(2.75, 6.5, "Physical Defence: ${battler.startingPhysicalDefense}");
          Font.renderStaticText(2.75, 8.0, "Magical Attack: ${battler.startingMagicalAttack}");
          Font.renderStaticText(2.75, 9.5, "Magical Defense: ${battler.startingMagicalDefense}");
          Font.renderStaticText(2.75, 11.0, "Speed: ${battler.startingSpeed}");
          
          Font.renderStaticText(2.75, 13.0, "Next Level: ${battler.nextLevelExperience() - battler.experience}");
        });
        
        GameEvent powersBack = new GameEvent((Function a) {
          Gui.windows = [];
          start.trigger();
        });
        
        new ChoiceGameEvent.custom(
            this, {"Back": [powersBack]},
            15, 0,
            5, 2
        ).trigger();
      });
      
      start = new ChoiceGameEvent.custom(
        this,
        {
          "Stats": [exit],
          "Powers": [powers],
          "Items": [exit],
          "Save": [exit],
          "Exit": [exit]
        },
        15, 0,
        5, 6
      );
      
      start.trigger();
    }
    
    for(int key in keyCodes) {
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
  }
  
  @override
  void checkForBattle() {
    // TODO: make it so that talking to a player can make them battle you
    
    // check for line-of-sight battles
    for(Character character in Main.world.maps[Main.world.curMap].characters) {
      for(int i=1; i<=character.sightDistance; i++) {
        // TODO: check that character is facing the proper direction
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
              // TODO: this text should be input
              new TextGameEvent(237, "Hey, before you leave, let's see how strong you are!", () {
                Gui.fadeLightAction((){},(){
                  Gui.fadeDarkAction((){}, (){
                    // start the battle!
                    character.battler.reset();
                    
                    Main.battle = new Battle(
                        Main.player.battler,
                        character.battler
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