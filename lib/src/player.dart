library Player;

import 'dart:html';

import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

class Player implements InputHandler {
  static final int
    DOWN = 0,
    RIGHT = 1,
    UP = 2,
    LEFT = 3,
    walkSpeed = 4,
    runSpeed = 8,
    motionAmount = Sprite.pixelsPerSprite * Sprite.spriteScale,
    directionCooldownAmount = 4;
  
  static int 
    motionX = 0,
    motionY = 0,
    direction = DOWN,
    directionCooldown = 0,
    mapX = 8,
    mapY = 5,
    curSpeed = walkSpeed,
    x = mapX * motionAmount,
    y = mapY * motionAmount,
    motionStep = 1,
    motionSpriteOffset = 0;

  void render(List<List<Tile>> renderList) {
    renderList[World.LAYER_PLAYER].add(
      new Tile(
        true,
        new Sprite(
          Tile.PLAYER + direction + motionSpriteOffset,
          x/motionAmount, (y/motionAmount)-1
        )
      )
    );
    
    renderList[World.LAYER_PLAYER].add(
      new Tile(
        true,
        new Sprite(
          Tile.PLAYER + direction + motionSpriteOffset + Sprite.spriteSheetSize,
          x/motionAmount, y/motionAmount
        )
      )
    );
  }
  
  void handleKey(int keyCode, World world) {
    switch(keyCode) {
      case KeyCode.LEFT:
        move(Player.LEFT);
        break;
      case KeyCode.RIGHT:
        move(Player.RIGHT);
        break;
      case KeyCode.UP:
        move(Player.UP);
        break;
      case KeyCode.DOWN:
        move(Player.DOWN);
        break;
      case KeyCode.X:
        interact(world);
        break;
    }
  }
  
  void interact(World world) {
    if(direction == Player.LEFT && world.isInteractable(mapX-1, mapY)) {
      world.interact(mapX-1, mapY);
    } else if(direction == Player.RIGHT && world.isInteractable(mapX+1, mapY)) {
      world.interact(mapX+1, mapY);
    } else if(direction == Player.UP && world.isInteractable(mapX, mapY-1)) {
      world.interact(mapX, mapY-1);
    } else if(direction == Player.DOWN && world.isInteractable(mapX, mapY+1)) {
      world.interact(mapX, mapY+1);
    }
  }
  
  void move(motionDirection) {
    // only move if we're not already moving
    if(motionX == 0 && motionY == 0) {
      // allow the player to change directions without moving
      if(direction != motionDirection) {
        direction = motionDirection;
        directionCooldown = directionCooldownAmount;
        return;
      }
      
      // don't add motion until we've finished turning
      if(directionCooldown > 0)
        return;
      
      if(motionDirection == LEFT) {
        motionX = -motionAmount;
      } else if(motionDirection == RIGHT) {
        motionX = motionAmount;
      } else if(motionDirection == UP) {
        motionY = -motionAmount;
      } else if(motionDirection == DOWN) {
        motionY = motionAmount;
      }
    }
  }
  
  void tick(World world) {
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
      motionX += curSpeed;
      if(!world.isSolid(mapX-1, mapY)) {
        x -= curSpeed;
        
        if(motionX == 0)
          mapX -= 1;
      }
      
      // reverse walk cycle foot
      if(motionX == 0 && motionStep == 1)
        motionStep = 2;
      else if(motionX == 0 && motionStep == 2)
        motionStep = 1;
    } else if(motionX > 0) {
      motionX -= curSpeed;
      if(!world.isSolid(mapX+1, mapY)) {
        x += curSpeed;
        
        if(motionX == 0)
          mapX += 1;
      }
      
      // reverse walk cycle foot
      if(motionX == 0 && motionStep == 1)
        motionStep = 2;
      else if(motionX == 0 && motionStep == 2)
        motionStep = 1;
    } else if(motionY < 0) {
      motionY += curSpeed;
      if(!world.isSolid(mapX, mapY-1)) {
        y -= curSpeed;
        
        if(motionY == 0)
          mapY -= 1;
      }
      
      // reverse walk cycle foot
      if(motionY == 0 && motionStep == 1)
        motionStep = 2;
      else if(motionY == 0 && motionStep == 2)
        motionStep = 1;
    } else if(motionY > 0) {
      motionY -= curSpeed;
      if(!world.isSolid(mapX, mapY+1)) {
        y += curSpeed;
        
        if(motionY == 0)
          mapY += 1;
      }
      
      // reverse walk cycle foot
      if(motionY == 0 && motionStep == 1)
        motionStep = 2;
      else if(motionY == 0 && motionStep == 2)
        motionStep = 1;
    }
  }
}