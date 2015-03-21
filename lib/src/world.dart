library World;

import 'dart:convert';
import 'dart:html';
import 'dart:math' as math;

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/choice_game_event.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/game_map.dart';
import 'package:dart_rpg/src/gui.dart';
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
  
  Map<String, GameMap> maps = {};
  String curMap = "";
  
  static final Map<String, Attack> attacks = {
    "Punch": new Attack("Punch", Attack.CATEGORY_PHYSICAL, 10),
    "Kick": new Attack("Kick", Attack.CATEGORY_PHYSICAL, 10),
    "Poke": new Attack("Poke", Attack.CATEGORY_PHYSICAL, 6),
    "Headbutt": new Attack("Headbutt", Attack.CATEGORY_PHYSICAL, 8),
    "Flail": new Attack("Flail", Attack.CATEGORY_PHYSICAL, 4),
    "Jab": new Attack("Jab", Attack.CATEGORY_PHYSICAL, 7),
    "Attack 74b": new Attack("Attack 74b", Attack.CATEGORY_MAGICAL, 9)
  };
  
  static final Map<String, BattlerType> battlerTypes = {
    "Player": new BattlerType(
      237, "Player", 8, 8, 8, 8, 8, 8,
      {
        1: attacks["Punch"],
        2: attacks["Kick"]
      },
      1.0
    ),
    
    "Common": new BattlerType(
      237, "Common", 4, 4, 4, 4, 4, 4,
      {
        1: attacks["Poke"],
        2: attacks["Headbutt"],
        3: attacks["Flail"]
      },
      0.8
    ),
    
    "Rare": new BattlerType(
      237, "Rare", 6, 6, 6, 6, 6, 6,
      {
        1: attacks["Jab"],
        2: attacks["Attack 74b"]
      },
      1.2
    )
  };
  
  final int
    viewXSize = (Main.canvasWidth/(Sprite.pixelsPerSprite*Sprite.spriteScale)).round(),
    viewYSize = (Main.canvasHeight/(Sprite.pixelsPerSprite*Sprite.spriteScale)).round();
  
  World(Function callback) {
    Main.player = new Player(19, 19);
    Main.player.battler = new Battler(
      battlerTypes["Player"], 3,
      battlerTypes["Player"].levelAttacks.values.toList()
    );
    
    // TODO: improve editor so less is needed in world class
    loadMaps(() {
      
      Battler common = new Battler(battlerTypes["Common"], 5, battlerTypes["Common"].levelAttacks.values.toList());
      Battler rare = new Battler(battlerTypes["Rare"], 5, battlerTypes["Rare"].levelAttacks.values.toList());
      maps["main"].battlerChances = [
        new BattlerChance(common, 0.8),
        new BattlerChance(rare, 0.2)
      ];
      
      // Character
      Character character = addCharacter(
        "main",
        //Tile.PLAYER - 64,
        Tile.PLAYER + 17,
        237,
        11, 15, LAYER_BELOW,
        1, 2,
        true
      );
      
      character.sightDistance = 5;
      character.direction = Character.RIGHT;
      character.battler = new Battler(
        battlerTypes["Player"], 4,
        battlerTypes["Player"].levelAttacks.values.toList()
      );
      
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
          new ChoiceGameEvent(character, {
            "Yes": [
              new TextGameEvent(231, "That's fine."),
              new TextGameEvent(237, "If you say so!"),
              new GameEvent((callback) {
                character.gameEvent = characterGameEvents[0];
              })
            ],
            "No": [
              new TextGameEvent(231, "I hate you."),
              new TextGameEvent(237, "::sniff sniff:: Meanie!")
            ]
          })
        )
      ];
      
      Interactable.chainGameEvents(character, characterGameEvents);
      
      // add character that heals you
      Character healer = addCharacter(
        "house",
        Tile.PLAYER,
        237,
        5, 1, LAYER_BELOW,
        1, 2,
        true
      );
      
      List<GameEvent> healerGameEvents = [];
      healerGameEvents = [
        new TextGameEvent(237, "Allow me to heal your wounds."),
        new GameEvent((callback) {
          Gui.fadeLightAction(() {
            Main.player.battler.curHealth = Main.player.battler.startingHealth;
            Main.player.battler.displayHealth = Main.player.battler.startingHealth;
          }, callback);
          //Main.player.inputEnabled = false;
        }),
        new TextGameEvent(237, "You should feel much better now.")
      ];
      
      Interactable.chainGameEvents(healer, healerGameEvents);
      
      callback();
    });
  }
  
  void loadMaps(Function callback) {
    HttpRequest
      .getString("maps.json")
      .then(parseMaps)
      .then((dynamic f) { if(callback != null) { callback(); } })
      .catchError((Error err) {
        print("Error loading maps! (${err})");
        print(err.stackTrace);
        if(callback != null)
          callback();
      });
  }
  
  void parseMaps(String jsonString) {
    Map<String, Map> obj = JSON.decode(jsonString);
    
    maps = {};
    curMap = obj.keys.first;
    
    for(String mapName in obj.keys) {
      GameMap gameMap = new GameMap(mapName);
      maps[mapName] = gameMap;
      maps[mapName].tiles = [];
      maps[mapName].characters = [];
      List<List<List<Tile>>> mapTiles = maps[mapName].tiles;
      
      for(int y=0; y<obj[mapName]['tiles'].length; y++) {
        mapTiles.add([]);
        
        for(int x=0; x<obj[mapName]['tiles'][y].length; x++) {
          mapTiles[y].add([]);
          
          for(int k=0; k<obj[mapName]['tiles'][y][x].length; k++) {
            mapTiles[y][x].add(null);
            
            var curTile = obj[mapName]['tiles'][y][x][k];
            
            if(curTile != null) {
              if(curTile['warp'] != null) {
                mapTiles[y][x][k] = new WarpTile(
                  curTile['solid'] == true,
                  new Sprite.int(curTile['id'], x, y),
                  curTile['warp']['destMap'],
                  curTile['warp']['destX'],
                  curTile['warp']['destY']
                );
              } else if(curTile['sign'] != null) {
                mapTiles[y][x][k] = new Sign(
                  curTile['solid'] == true,
                  new Sprite.int(curTile['id'], x, y),
                  curTile['sign']['pic'],
                  curTile['sign']['text']
                );
              } else if(curTile['encounter'] == true) {
                mapTiles[y][x][k] = new EncounterTile(
                  new Sprite.int(curTile['id'], x, y),
                  curTile['layered'] == true
                );
              } else {
                mapTiles[y][x][k] = new Tile(
                  curTile['solid'] == true,
                  new Sprite.int(curTile['id'], x, y),
                  curTile['layered'] == true
                );
              }
            }
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
      String map,
      int spriteId, int pictureId,
      int posX, int posY, int layer, int sizeX, int sizeY, bool solid) {
    Character character = new Character(
      spriteId, pictureId, posX, posY, layer, sizeX, sizeY, solid
    );
    maps[map].characters.add(character);
    return character;
  }
  
  void addInteractableObject(
      int spriteId, int posX, int posY, int layer, int sizeX, int sizeY, bool solid,
      void handler(List<int> keyCodes)) {
    for(var y=0; y<sizeY; y++) {
      for(var x=0; x<sizeX; x++) {
        maps[curMap].tiles[posY+y][posX+x][layer] = new InteractableTile(
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
  
  bool isSolid(int x, int y) {
    for(int layer in layers) {
      if(maps[curMap].tiles[y][x][layer] is Tile && maps[curMap].tiles[y][x][layer].solid) {
        return true;
      }
    }
    
    for(Character character in maps[curMap].characters) {
      if(character.mapX == x && character.mapY == y) {
        return true;
      }
    }
    
    if(Main.player.mapX == x && Main.player.mapY == y)
      return true;
    
    return false;
  }
  
  bool isInteractable(int x, int y) {
    for(int layer in layers) {
      if(maps[curMap].tiles[y][x][layer] is InteractableTile) {
        return true;
      }
    }
    
    for(Character character in maps[curMap].characters) {
      if(character.mapX == x && character.mapY == y) {
        return true;
      }
    }
    
    return false;
  }
  
  void interact(int x, int y) {
    for(int layer in layers) {
      if(maps[curMap].tiles[y][x][layer] is InteractableTile) {
        InteractableTile tile = maps[curMap].tiles[y][x][layer] as InteractableTile;
        tile.interact();
        return;
      }
    }
    
    for(Character character in maps[curMap].characters) {
      if(character.mapX == x && character.mapY == y) {
        character.interact();
        return;
      }
    }
  }

  void render(List<List<Tile>> renderList) {
    if(maps[curMap] == null)
      return;
    
    for(
        var y=math.max(Main.player.mapY-(viewYSize/2+1).round(), 0);
        y<Main.player.mapY+(viewYSize/2+1).round() && y<maps[curMap].tiles.length;
        y++) {
      for(
          var x=math.max(Main.player.mapX-(viewXSize/2).round(), 0);
          x<Main.player.mapX+(viewXSize/2+2).round() && x<maps[curMap].tiles[y].length;
          x++) {
        for(int layer in layers) {
          if(maps[curMap].tiles[y][x][layer] is Tile) {
            renderList[layer].add(
              maps[curMap].tiles[y][x][layer]
            );
          }
        }
      }
    }
  }
}