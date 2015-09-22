library dart_rpg.character;

import 'dart:math' as math;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/inventory.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

class Character extends Interactable {
  static final int
    DOWN = 0,
    RIGHT = 1,
    UP = 2,
    LEFT = 3;
  
  final int
    walkSpeed = 2 * Sprite.spriteScale,
    runSpeed = 4 * Sprite.spriteScale,
    
    // how far the character moves with each step, in pixels
    motionAmount = Sprite.pixelsPerSprite * Sprite.spriteScale,
    directionCooldownAmount = 2;
  
  int
    spriteId,
    pictureId,
    layer,
    sizeX, sizeY,
    
    // how far the character has left to move, in pixels
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
  
  String startMap;
  int startX, startY;
  
  bool solid;
  Function motionCallback;
  
  Battler battler;
  int sightDistance = 0;
  
  Inventory inventory = new Inventory([]);
  
  String name, type, map, label;
  
  // TODO: add wander behavior
  
  Character(this.label, this.spriteId, this.pictureId,
      this.mapX, this.mapY,
      {this.layer: World.LAYER_PLAYER, this.sizeX: 1, this.sizeY: 2, this.solid: true}) {
    curSpeed = walkSpeed;
    
    startX = mapX;
    startY = mapY;
    
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
      
      Tile tile;
      try {
        if(motionDirection == Character.LEFT) {
          motionX = -motionAmount;
          tile = Main.world.maps[Main.world.curMap].tiles[mapY][mapX-1][World.LAYER_GROUND];
        } else if(motionDirection == Character.RIGHT) {
          motionX = motionAmount;
          tile = Main.world.maps[Main.world.curMap].tiles[mapY][mapX+1][World.LAYER_GROUND];
        } else if(motionDirection == Character.UP) {
          motionY = -motionAmount;
          tile = Main.world.maps[Main.world.curMap].tiles[mapY-1][mapX][World.LAYER_GROUND];
        } else if(motionDirection == Character.DOWN) {
          motionY = motionAmount;
          tile = Main.world.maps[Main.world.curMap].tiles[mapY+1][mapX][World.LAYER_GROUND];
        }
      } catch(e) {
        
      }
      
      // handle entering null tiles
      if(tile != null) {
        // TODO: this shouldn't happen if a character encounter happens
        //   perhaps have the battle check happen here, and actually trigger as a motion callback
        tile.enter(this);
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
          if(this == Main.player.character) {
            Main.player.checkForBattle();
          }
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
          if(this == Main.player.character) {
            Main.player.checkForBattle();
          }
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
          if(this == Main.player.character) {
            Main.player.checkForBattle();
          }
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
          if(this == Main.player.character) {
            Main.player.checkForBattle();
          }
        }
      }
      
      // reverse walk cycle foot
      if(motionY == 0 && motionStep == 1)
        motionStep = 2;
      else if(motionY == 0 && motionStep == 2)
        motionStep = 1;
    }
  }
  
  void warp(String map, int mapX, int mapY, int layer, int direction) {
    if(this is Player) {
      Main.world.curMap = map;
    }
    
    // change the character's location
    this.map = map;
    this.mapX = mapX;
    this.mapY = mapY;
    this.layer = layer;
    this.direction = direction;
    
    // fix since x and y are only calculated in constructor
    x = mapX * motionAmount;
    y = mapY * motionAmount;
  }
  
  void render(List<List<Tile>> renderList) {
    int higherLayer = layer+1;
    if(higherLayer >= World.layers.last) {
      higherLayer = layer;
    }
    
    int curLayer = higherLayer;
    
    for(int j=0; j<sizeY; j++) {
      
      if(j >= sizeY/2)
        curLayer = layer;
      
      for(int i=0; i<sizeX; i++) {
        renderList[curLayer].add(
          new Tile(
            solid,
            new Sprite(
              spriteId + i + (direction * sizeX) + motionSpriteOffset + (Sprite.spriteSheetWidth * j),
              (x/motionAmount) + i, (y/motionAmount) - (sizeY - j - 1)
            )
          )
        );
      }
    }
  }
  
  void interact() {
    List<GameEvent> gameEvents = World.gameEventChains[getGameEventChain()].sublist(getGameEventChainOffset());
    if(gameEvents != null && gameEvents.length > 0) {
      Main.focusObject = null;
      Interactable.chainGameEvents(this, gameEvents).trigger(this);
    } else if(battler != null) {
      // talking to a player can make them face you and battle you
      if(Main.player.character.mapX < mapX)
        direction = LEFT;
      else if(Main.player.character.mapX > mapX)
        direction = RIGHT;
      else if(Main.player.character.mapY < mapY)
        direction = UP;
      else if(Main.player.character.mapY > mapY)
        direction = DOWN;
      
      Main.player.checkForBattle();
    }
  }
}