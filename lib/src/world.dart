library World;

import 'dart:html';
import 'dart:math' as math;
import 'dart:convert';

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/choice_game_event.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/interactable_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/sign.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/text_game_event.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/warp_tile.dart';

class World {
  static final int
    LAYER_GROUND = 0,
    LAYER_BELOW = 1,
    LAYER_PLAYER = 2,
    LAYER_ABOVE = 3;
  
  static final List<int> layers = [
    LAYER_GROUND,
    LAYER_BELOW,
    LAYER_PLAYER,
    LAYER_ABOVE
  ];
  
  List<List<List<Tile>>> map = [];
  List<Character> characters = [];
  
  final int
    viewXSize = (Main.canvasWidth/(Sprite.pixelsPerSprite*Sprite.spriteScale)).round(),
    viewYSize = (Main.canvasHeight/(Sprite.pixelsPerSprite*Sprite.spriteScale)).round();
  
  World() {
    int xSize = 50;
    int ySize = 50;
    
    for(int y=0; y<ySize; y++) {
      map.add([]);
      for(int x=0; x<xSize; x++) {
        map[y].add([]);
        for(int i=0; i<layers.length; i++) {
          map[y][x].add(null);
        }
      }
    }
    
    for(int y=0; y<18; y++) {
      for(int x=0; x<30; x++) {
        if(y == 0 || y == 17 || x == 0 || x == 29) {
          map[y][x][LAYER_GROUND] = new Tile(
            true,
            new Sprite.int(Tile.WALL, x, y)
          );
        } else {
          map[y][x][LAYER_GROUND] = new Tile(
            false,
            new Sprite.int(Tile.GROUND, x, y)
          );
        }
      }
    }
    
    Battler battlerCommon = new Battler(
      237, "Common Monster",
      14, 8, 5, // health, attack, speed
      [
        new Attack("Poke", 2),
        new Attack("Headbutt", 4),
        new Attack("Flail", 3)
      ],
      12 // experiencePayout
    );
    
    Battler battlerRare = new Battler(
      237, "Rare Monster",
      14, 8, 5, // health, attack, speed
      [
        new Attack("Jab", 4),
        new Attack("Attack 74b", 6)
      ],
      18 // experiencePayout
    );
    
    List<BattlerChance> battlerChances = [
      new BattlerChance(battlerCommon, 0.8),
      new BattlerChance(battlerRare, 0.2)
    ];
    
    for(int y=3; y<9; y++) {
      for(int x=18; x<27; x++) {
        map[y][x][LAYER_GROUND] = new EncounterTile(
          new Sprite.int(Tile.TALL_GRASS, x, y),
          battlerChances
        );
      }
    }
    
    // Top half of the house, which you can walk behind
    addObject(
      Tile.HOUSE,
      10, 6, LAYER_ABOVE,
      6, 2,
      false
    );
    
    // Bottom half of the house
    addObject(
      Tile.HOUSE + 64,
      10, 8, LAYER_BELOW,
      6, 3,
      true
    );
    
    map[13][8][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_RIGHT_BOTTOM, 8, 13) );
    map[13][9][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_RIGHT_LEFT, 9, 13) );
    map[13][10][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_RIGHT_BOTTOM_LEFT, 10, 13) );
    map[13][11][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_RIGHT_LEFT, 11, 13) );
    map[13][12][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_RIGHT_BOTTOM_LEFT, 12, 13) );
    map[13][13][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_RIGHT_LEFT, 13, 13) );
    map[13][14][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_RIGHT_LEFT, 14, 13) );
    map[13][15][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_RIGHT_LEFT, 15, 13) );
    map[13][16][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_RIGHT_LEFT, 16, 13) );
    map[13][17][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_TOP_LEFT, 17, 13) );
    
    map[14][8][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_TOP_BOTTOM, 8, 14) );
    map[14][10][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_TOP_BOTTOM, 10, 14) );
    map[15][8][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_TOP_RIGHT, 8, 15) );
    map[15][9][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_RIGHT_LEFT, 9, 15) );
    map[15][10][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_TOP_LEFT, 10, 15) );
    
    map[14][12][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_TOP, 12, 14) );
    map[15][14][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE, 14, 15) );
    map[12][17][LAYER_BELOW] = new Tile( true, new Sprite.int(Tile.FENCE_BOTTOM, 17, 12) );
    
    // Inside of house
    for(int y=25; y<=32; y++) {
      for(int x=0; x<=8; x++) {
        if(x == 0 || x == 8 || y == 25 || y == 32) {
          map[y][x][LAYER_GROUND] = new Tile(
            true,
            new Sprite.int(Tile.WALL, x, y)
          );
        } else {
          map[y][x][LAYER_GROUND] = new Tile(
            false,
            new Sprite.int(Tile.WOOD_FLOOR, x, y)
          );
        }
      }
    }
    
    // Outside door warp
    addWarp(
      Tile.HOUSE + 128 + 1,
      11, 10, // Pos
      4, 32 // Dest
    );
    
    // Inside door warp
     addWarp(
       Tile.HOUSE + 128 + 1,
       4, 32, // Pos
       11, 10 // Dest
     );
    
    // Sign
    addSign(
      Tile.SIGN,
      234,
      9, 10, LAYER_BELOW,
      1, 1,
      true,
      "This is only a test. This is a sign that has way too much text. " +
        "We'll see how the sign handles having this much text on it. " +
        "It really takes a lot of text to fill them up!"
    );
    
    // Sign
    addSign(
      Tile.SIGN,
      234,
      8, 10, LAYER_BELOW,
      1, 1,
      true,
      "This is a second sign."
    );
    
    // Character
    Character character = addCharacter(
      //Tile.PLAYER - 64,
      Tile.PLAYER,
      237,
      4, 6, LAYER_BELOW,
      1, 2,
      true
    );
    
    character.direction = Character.RIGHT;
    
    List<GameEvent> characterGameEvents = [];
    characterGameEvents = [
      new TextGameEvent(237, "I'm like a kid, right?"),
      new GameEvent((callback) {
        Main.player.inputEnabled = false;
        chainCharacterMovement(
          character,
          [Character.LEFT, Character.LEFT, Character.LEFT,
            Character.RIGHT, Character.RIGHT, Character.RIGHT],
          () {
            Main.player.inputEnabled = true;
            callback();
          }
        );
      }),
      new TextGameEvent.choice(237, "See?",
        new ChoiceGameEvent(character, ["Yes", "No"], [
          [
            new TextGameEvent(231, "That's fine."),
            new TextGameEvent(237, "If you say so!"),
            new GameEvent((callback) {
              character.gameEvent = characterGameEvents[0];
            })
          ],
          [
            new TextGameEvent(231, "I hate you."),
            new TextGameEvent(237, "::sniff sniff:: Meanie!")
          ]
        ])
      )
    ];
    
    Interactable.chainGameEvents(character, characterGameEvents);
    
    Main.player = new Player(15, 4);
    Main.player.battler = new Battler(
      237, "Player",
      20, 4, 6, // health, attack, speed
      [
        new Attack("Punch", 10),
        new Attack("Kick", 10),
      ],
      0 // experiencePayout
    );
    
    // TODO: improve editor so less is needed in world class
    //loadMap();
  }
  
  void loadMap() {
    HttpRequest
      .getString("map.json")
      .then(parseMap)
      .catchError((Error error) {
        print("Error loading map! (${error})");
      });
  }
  
  void parseMap(String jsonString) {
    List<List<List<int>>> obj = JSON.decode(jsonString);
    
    map = [];
    
    for(int y=0; y<obj.length; y++) {
      map.add([]);
      
      for(int x=0; x<obj[y].length; x++) {
        map[y].add([]);
        
        for(int k=0; k<obj[y][x].length; k++) {
          map[y][x].add(null);
          
          if(obj[y][x][k] != -1) {
            map[y][x][k] = new Tile(
              false,
              new Sprite.int(obj[y][x][k], x, y)
            );
          }
        }
      }
    }
  }
  
  void chainCharacterMovement(Character character, List<int> directions, Function callback) {
    if(directions.length == 0) {
      callback();
    } else {
      int direction = directions.removeAt(0);
      character.move(direction);
      character.motionCallback = () {
        chainCharacterMovement(character, directions, callback);
      };
    }
  }
  
  Character addCharacter(
      int spriteId, int pictureId,
      int posX, int posY, int layer, int sizeX, int sizeY, bool solid) {
    Character character = new Character(
      spriteId, pictureId, posX, posY, layer, sizeX, sizeY, solid
    );
    characters.add(character);
    return character;
  }
  
  void addWarp(int spriteId, int posX, int posY, int destX, int destY) {
    map[posY][posX][LAYER_GROUND] = new WarpTile(
      true,
      new Sprite.int(spriteId, posX, posY),
      destX, destY
    );
  }
  
  void addSign(
      int spriteId, int pictureId,
      int posX, int posY, int layer, int sizeX, int sizeY, bool solid,
      String text) {
    for(int y=posY; y<posY+sizeY; y++) {
      for(int x=posX; x<posX+sizeX; x++) {
        map[y][x][layer] = new Sign(
          solid,
          new Sprite.int(spriteId, x, y),
          pictureId,
          text
        );
      }
    }
  }
  
  void addInteractableObject(
      int spriteId, int posX, int posY, int layer, int sizeX, int sizeY, bool solid,
      void handler(List<int> keyCodes)) {
    for(var y=0; y<sizeY; y++) {
      for(var x=0; x<sizeX; x++) {
        map[posY+y][posX+x][layer] = new InteractableTile(
          solid,
          new Sprite.int(
            spriteId + x + (y*Sprite.spriteSheetSize),
            posX+x, posY+y
          ),
          handler
        );
      }
    }
  }
  
  void addObject(
      int spriteId,
      int posX, int posY, int layer, int sizeX, int sizeY, bool solid) {
    for(var y=0; y<sizeY; y++) {
      for(var x=0; x<sizeX; x++) {
        map[posY+y][posX+x][layer] = new Tile(
          solid,
          new Sprite.int(
            spriteId + x + (y*Sprite.spriteSheetSize),
            posX+x, posY+y
          )
        );
      }
    }
  }
  
  bool isSolid(int x, int y) {
    for(int layer in layers) {
      if(map[y][x][layer] is Tile && map[y][x][layer].solid) {
        return true;
      }
    }
    
    for(Character character in characters) {
      if(character.mapX == x && character.mapY == y) {
        return true;
      }
    }
    
    return false;
  }
  
  bool isInteractable(int x, int y) {
    for(int layer in layers) {
      if(map[y][x][layer] is InteractableTile) {
        return true;
      }
    }
    
    for(Character character in characters) {
      if(character.mapX == x && character.mapY == y) {
        return true;
      }
    }
    
    return false;
  }
  
  void interact(int x, int y) {
    for(int layer in layers) {
      if(map[y][x][layer] is InteractableTile) {
        InteractableTile tile = map[y][x][layer] as InteractableTile;
        tile.interact();
        return;
      }
    }
    
    for(Character character in characters) {
      if(character.mapX == x && character.mapY == y) {
        character.interact();
        return;
      }
    }
  }

  void render(List<List<Tile>> renderList) {
    for(
        var y=math.max(Main.player.mapY-(viewYSize/2+1).round(), 0);
        y<Main.player.mapY+(viewYSize/2+1).round() && y<map.length;
        y++) {
      for(
          var x=math.max(Main.player.mapX-(viewXSize/2).round(), 0);
          x<Main.player.mapX+(viewXSize/2+2).round() && x<map[y].length;
          x++) {
        for(int layer in layers) {
          if(map[y][x][layer] is Tile) {
            renderList[layer].add(
              map[y][x][layer]
            );
          }
        }
      }
    }
  }
}