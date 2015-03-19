library Character;

import 'dart:math' as math;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/delayed_game_event.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

class Character implements InteractableInterface, InputHandler {
  static final int
    DOWN = 0,
    RIGHT = 1,
    UP = 2,
    LEFT = 3;
  
  final int
    walkSpeed = 4,
    runSpeed = 8,
    motionAmount = Sprite.pixelsPerSprite * Sprite.spriteScale,
    directionCooldownAmount = 2;
  
  int
    spriteId,
    pictureId,
    layer,
    sizeX, sizeY,
    motionX = 0,
    motionY = 0,
    direction = DOWN,
    directionCooldown = 0,
    curSpeed,
    motionStep = 1,
    motionSpriteOffset = 0,
    mapX, mapY,
    x, y,
    movementAmount;
  
  bool solid;
  GameEvent gameEvent;
  Function motionCallback;
  
  Battler battler;
  int sightDistance = 0;
  
  // TODO: perhaps add name field
  // TODO: add wander behavior
  // TODO: add line-of-sight battle encounters?
  // TODO: add battle event with callback
  //   (to fight a character and then have them react to the battle)
  
  Character(this.spriteId, this.pictureId,
      this.mapX, this.mapY, this.layer, this.sizeX, this.sizeY, this.solid) {
    curSpeed = walkSpeed;
    x = mapX * motionAmount;
    y = mapY * motionAmount;
  }
  
  bool motionCallbackCheck() {
    // call our motion callback if we have one and have stopped moving
     if(motionCallback != null &&
         directionCooldown == 0 &&
         motionX == 0 && motionY == 0) {
       Function curCallback = motionCallback;
       motionCallback = null;
       curCallback();
       return true;
     }
     
     return false;
  }
  
  void move(motionDirection) {
    if(motionCallbackCheck())
      return;
    
    // only move if we're not already moving
    if(motionX == 0 && motionY == 0) {
      // allow the player to change directions without moving
      if(direction != motionDirection) {
        direction = motionDirection;
        
        // turn faster if we're running
        if(curSpeed != runSpeed)
          directionCooldown = directionCooldownAmount;
        
        return;
      }
      
      // don't add motion until we've finished turning
      if(directionCooldown > 0)
        return;
      
      // TODO: handle entering null tiles
      if(motionDirection == Character.LEFT) {
        motionX = -motionAmount;
        Main.world.maps[Main.world.curMap].tiles[mapY][mapX-1][World.LAYER_GROUND].enter();
      } else if(motionDirection == Character.RIGHT) {
        motionX = motionAmount;
        Main.world.maps[Main.world.curMap].tiles[mapY][mapX+1][World.LAYER_GROUND].enter();
      } else if(motionDirection == Character.UP) {
        motionY = -motionAmount;
        Main.world.maps[Main.world.curMap].tiles[mapY-1][mapX][World.LAYER_GROUND].enter();
      } else if(motionDirection == Character.DOWN) {
        motionY = motionAmount;
        Main.world.maps[Main.world.curMap].tiles[mapY+1][mapX][World.LAYER_GROUND].enter();
      }
    }
  }
  
  void tick() {
    if(motionCallbackCheck())
      return;
      
    if(directionCooldown > 0) {
      directionCooldown -= 1;
      
      // use walk cycle sprite when turning
      if(directionCooldown >= directionCooldownAmount/2) {
        motionSpriteOffset = motionStep + 3 + direction;
      } else if(directionCooldown == 0) {
        if(motionStep == 1)
          motionStep = 2;
        else if(motionStep == 2)
          motionStep = 1;
      }
      
      return;
    }
    
    // set walk cycle sprite for first half of motion
    if(
        (motionX != 0 && (motionX).abs() > motionAmount/2)
        || (motionY != 0 && (motionY).abs() > motionAmount/2)) {
      motionSpriteOffset = motionStep + 3 + direction;
    } else {
      motionSpriteOffset = 0;
    }
    
    if(motionX < 0) {
      movementAmount = math.min(motionX.abs(), curSpeed);
      motionX += movementAmount;
      
      if(!Main.world.isSolid(mapX-1, mapY)) {
        x -= movementAmount;
        
        if(motionX == 0) {
          mapX -= 1;
          checkForBattle();
        }
      }
      
      // reverse walk cycle foot
      if(motionX == 0 && motionStep == 1)
        motionStep = 2;
      else if(motionX == 0 && motionStep == 2)
        motionStep = 1;
    } else if(motionX > 0) {
      movementAmount = math.min(motionX.abs(), curSpeed);
      motionX -= movementAmount;
      
      if(!Main.world.isSolid(mapX+1, mapY)) {
        x += movementAmount;
        
        if(motionX == 0) {
          mapX += 1;
          checkForBattle();
        }
      }
      
      // reverse walk cycle foot
      if(motionX == 0 && motionStep == 1)
        motionStep = 2;
      else if(motionX == 0 && motionStep == 2)
        motionStep = 1;
    } else if(motionY < 0) {
      movementAmount = math.min(motionY.abs(), curSpeed);
      motionY += movementAmount;
      
      if(!Main.world.isSolid(mapX, mapY-1)) {
        y -= movementAmount;
        
        if(motionY == 0) {
          mapY -= 1;
          checkForBattle();
        }
      }
      
      // reverse walk cycle foot
      if(motionY == 0 && motionStep == 1)
        motionStep = 2;
      else if(motionY == 0 && motionStep == 2)
        motionStep = 1;
    } else if(motionY > 0) {
      movementAmount = math.min(motionY.abs(), curSpeed);
      motionY -= movementAmount;
      
      if(!Main.world.isSolid(mapX, mapY+1)) {
        y += movementAmount;
        
        if(motionY == 0) {
          mapY += 1;
          checkForBattle();
        }
      }
      
      // reverse walk cycle foot
      if(motionY == 0 && motionStep == 1)
        motionStep = 2;
      else if(motionY == 0 && motionStep == 2)
        motionStep = 1;
    }
  }
  
  void checkForBattle() {
    // check for line-of-sight battles
    // TODO: move this into player class
    if(this == Main.player) {
      for(Character character in Main.world.maps[Main.world.curMap].characters) {
        for(int i=1; i<=character.sightDistance; i++) {
          if(
              (Main.player.mapX == character.mapX && Main.player.mapY + i == character.mapY) ||
              (Main.player.mapX == character.mapX && Main.player.mapY - i == character.mapY) ||
              (Main.player.mapX + i == character.mapX && Main.player.mapY == character.mapY) ||
              (Main.player.mapX - i == character.mapX && Main.player.mapY == character.mapY)
          ) {
            print("A battle should now ensue!");
            
            Tile target = Main.world.maps[Main.world.curMap]
                .tiles[character.mapY - character.sizeY][character.mapX][World.LAYER_ABOVE];
            
            Tile before = null;
            if(target != null)
              before = new Tile(target.solid, target.sprite, target.layered);
            
            DelayedGameEvent.executeDelayedEvents([
              new DelayedGameEvent(0, () {
                Main.timeScale = 0.0;
                Main.world.maps[Main.world.curMap]
                  .tiles[character.mapY - character.sizeY][character.mapX][World.LAYER_ABOVE] =
                    new Tile(false, new Sprite.int(99, character.mapX, character.mapY - character.sizeY));
              }),
              new DelayedGameEvent(500, () {
                Main.world.maps[Main.world.curMap]
                  .tiles[character.mapY - character.sizeY][character.mapX][World.LAYER_ABOVE] = before;
                Main.timeScale = 1.0;
              })
            ]);
          }
        }
      }
    }
  }
  
  void render(List<List<Tile>> renderList) {
    renderList[layer+1].add(
      new Tile(
        true,
        new Sprite(
          spriteId + direction + motionSpriteOffset,
          x/motionAmount, (y/motionAmount)-1
        )
      )
    );
    
    renderList[layer].add(
      new Tile(
        true,
        new Sprite(
          spriteId + direction + motionSpriteOffset + Sprite.spriteSheetSize,
          x/motionAmount, y/motionAmount
        )
      )
    );
  }
  
  void handleKeys(List<int> keyCodes) {
    if(gameEvent != null) {
      gameEvent.handleKeys(keyCodes);
    }
  }
  
  void interact() {
    if(gameEvent != null) {
      Main.focusObject = this;
      gameEvent.trigger();
    }
  }
}