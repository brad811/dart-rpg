library dart_rpg.world;

import 'dart:convert';
import 'dart:html';
import 'dart:math' as math;

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/game_map.dart';
import 'package:dart_rpg/src/interactable_tile.dart';
import 'package:dart_rpg/src/inventory.dart';
import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/sign.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/warp_tile.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/battle_game_event.dart';
import 'package:dart_rpg/src/game_event/chain_game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/game_event/delay_game_event.dart';
import 'package:dart_rpg/src/game_event/fade_game_event.dart';
import 'package:dart_rpg/src/game_event/heal_game_event.dart';
import 'package:dart_rpg/src/game_event/move_game_event.dart';
import 'package:dart_rpg/src/game_event/store_game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';
import 'package:dart_rpg/src/game_event/warp_game_event.dart';

// TODO: maybe make player just another character so player can control multiple different people?

class World {
  static const int
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
  
  String startMap = "";
  int startX = 0, startY = 0;
  
  static Map<String, Attack> attacks = {};
  static Map<String, BattlerType> battlerTypes = {};
  static Map<String, Item> items = {};
  static Map<String, Character> characters = {};
  static Map<String, List<GameEvent>> gameEventChains = {};
  
  final int
    viewXSize = (Main.canvasWidth/(Sprite.pixelsPerSprite*Sprite.spriteScale)).round(),
    viewYSize = (Main.canvasHeight/(Sprite.pixelsPerSprite*Sprite.spriteScale)).round();
  
  World(Function callback) {
    loadGame(() {
      // move to the start map
      curMap = startMap;
      
      callback();
    });
  }
  
  void loadGame(Function callback) {
    HttpRequest
      .getString("game.json")
      .then(parseGame)
      .then((dynamic f) { if(callback != null) { callback(); } })
      .catchError((Error err) {
        print("Error loading maps! (${err})");
        print(err.stackTrace);
        if(callback != null)
          callback();
      });
  }
  
  void parseGame(String jsonString) {
    Map<String, Map> obj;
    TextAreaElement gameJson = querySelector("#game_json");
    
    if(gameJson == null) {
      gameJson = querySelector("#export_json");
    }
    
    if(gameJson != null && gameJson.value == "") {
      gameJson.value = jsonString;
      obj = JSON.decode(gameJson.value);
    } else {
      if(gameJson != null) {
        obj = JSON.decode(gameJson.value);
      } else {
        obj = JSON.decode(jsonString);
      }
    }
    
    parseAttacks(obj["attacks"]);
    parseBattlerTypes(obj["battlerTypes"]);
    parseItems(obj["items"]);
    parseMaps(obj["maps"], obj["characters"]);
    parsePlayer(obj["player"]);
    parseGameEventChains(obj["gameEventChains"]);
    
    parseCharacters(obj["characters"]);
  }
  
  void parseAttacks(Map<String, Map> attacksObject) {
    attacks = {};
    for(String attackName in attacksObject.keys) {
      attacks[attackName] = new Attack(
          attackName,
          int.parse(attacksObject[attackName]["category"]),
          int.parse(attacksObject[attackName]["power"])
      );
    }
  }
  
  void parseBattlerTypes(Map<String, Map> battlerTypesObject) {
    battlerTypes = {};
    for(String battlerTypeName in battlerTypesObject.keys) {
      battlerTypes[battlerTypeName] = new BattlerType(
          int.parse(battlerTypesObject[battlerTypeName]["spriteId"]),
          battlerTypeName,
          int.parse(battlerTypesObject[battlerTypeName]["health"]),
          int.parse(battlerTypesObject[battlerTypeName]["physicalAttack"]),
          int.parse(battlerTypesObject[battlerTypeName]["magicalAttack"]),
          int.parse(battlerTypesObject[battlerTypeName]["physicalDefense"]),
          int.parse(battlerTypesObject[battlerTypeName]["magicalDefense"]),
          int.parse(battlerTypesObject[battlerTypeName]["speed"]),
          {},
          double.parse(battlerTypesObject[battlerTypeName]["rarity"])
      );
      
      Map<String, String> levelAttacks = battlerTypesObject[battlerTypeName]["levelAttacks"];
      levelAttacks.forEach((String level, String attackName) {
        battlerTypes[battlerTypeName].levelAttacks[int.parse(level)] = World.attacks[attackName];
      });
    }
  }
  
  void parseMaps(Map<String, Map> mapsObject, Map<String, Map> charactersObject) {
    maps = {};
    curMap = mapsObject.keys.first;
    
    for(String mapName in mapsObject.keys) {
      GameMap gameMap = new GameMap(mapName);
      maps[mapName] = gameMap;
      maps[mapName].tiles = [];
      
      // set the map the game will start on
      if(mapsObject[mapName]["startMap"] == true) {
        startMap = mapName;
        startX = mapsObject[mapName]["startX"];
        startY = mapsObject[mapName]["startY"];
      }
      
      List<List<List<Tile>>> mapTiles = maps[mapName].tiles;
      
      for(int y=0; y<mapsObject[mapName]['tiles'].length; y++) {
        mapTiles.add([]);
        
        for(int x=0; x<mapsObject[mapName]['tiles'][y].length; x++) {
          mapTiles[y].add([]);
          
          for(int k=0; k<mapsObject[mapName]['tiles'][y][x].length; k++) {
            mapTiles[y][x].add(null);
            
            var curTile = mapsObject[mapName]['tiles'][y][x][k];
            
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
      
      maps[mapName].battlerChances = [];
      
      double totalChance = 0.0;
      for(int i=0; i<mapsObject[mapName]["battlers"].length; i++) {
        //String mapBattlerName = mapsObject[mapName]["battlers"][i]["name"];
        String mapBattlerType = mapsObject[mapName]["battlers"][i]["type"];
        int mapBattlerLevel = mapsObject[mapName]["battlers"][i]["level"];
        double mapBattlerChance = mapsObject[mapName]["battlers"][i]["chance"];
        
        Battler battler = new Battler(
          mapBattlerType, World.battlerTypes[mapBattlerType],
          mapBattlerLevel, World.battlerTypes[mapBattlerType].levelAttacks.values.toList()
        );
        
        BattlerChance battlerChance = new BattlerChance(
          battler,
          mapBattlerChance
        );
        
        totalChance += mapBattlerChance;
        
        maps[mapName].battlerChances.add(battlerChance);
      }
      
      // normalize the chances
      maps[mapName].battlerChances.forEach((BattlerChance battlerChance) {
        battlerChance.chance /= totalChance;
      });
    }
  }
  
  void parseItems(Map<String, Map> itemsObject) {
    items = {};
    for(String itemName in itemsObject.keys) {
      items[itemName] = new Item(
          int.parse(itemsObject[itemName]["pictureId"]),
          itemName,
          int.parse(itemsObject[itemName]["basePrice"]),
          itemsObject[itemName]["description"],
          itemsObject[itemName]["gameEventChain"]
      );
    }
  }
  
  void parseCharacters(Map<String, Map> charactersObject) {
    // for character editor
    characters = {};
    
    for(String characterLabel in charactersObject.keys) {
      Character character = parseCharacter(charactersObject, characterLabel);
      characters[characterLabel] = character;
    }
  }
  
  Character parseCharacter(Map<String, Map> charactersObject, String characterLabel) {
    Character character = new Character(
      characterLabel,
      charactersObject[characterLabel]["spriteId"] as int,
      charactersObject[characterLabel]["pictureId"] as int,
      1, 1,
      layer: World.LAYER_PLAYER,
      sizeX: charactersObject[characterLabel]["sizeX"] as int,
      sizeY: charactersObject[characterLabel]["sizeY"] as int,
      solid: true
    );
    
    character.name = charactersObject[characterLabel]["name"];
    
    character.map = charactersObject[characterLabel]["map"];
    character.mapX = charactersObject[characterLabel]["mapX"];
    character.mapY = charactersObject[characterLabel]["mapY"];
    character.layer = charactersObject[characterLabel]["layer"];
    character.direction = charactersObject[characterLabel]["direction"];
    character.solid = charactersObject[characterLabel]["solid"];
    
    character.x = character.mapX * character.motionAmount;
    character.y = character.mapY * character.motionAmount;
    
    String battlerTypeName = charactersObject[characterLabel]["battlerType"];
    BattlerType battlerType = World.battlerTypes[battlerTypeName];
    character.battler = new Battler(
        battlerType.name,
        battlerType,
        int.parse(charactersObject[characterLabel]["battlerLevel"]),
        battlerType.levelAttacks.values.toList()
      );
    
    character.sightDistance = int.parse(charactersObject[characterLabel]["sightDistance"]);
    
    // inventory
    character.inventory = new Inventory([]);
    List<Map<String, String>> characterItems = charactersObject[characterLabel]["inventory"];
    for(int i=0; i<characterItems.length; i++) {
      String itemName = characterItems.elementAt(i)["item"];
      int itemQuantity = int.parse(characterItems.elementAt(i)["quantity"]);
      character.inventory.addItem(World.items[itemName], itemQuantity);
    }
    
    // game events
    character.gameEventChain = charactersObject[characterLabel]["gameEventChain"];
    
    return character;
  }
  
  void parsePlayer(Map<String, Object> playerObject) {
    Main.player = new Player(startX, startY, startMap);
    Main.player.battler = new Battler(
      playerObject["name"],
      battlerTypes[playerObject["battlerType"]], playerObject["level"] as int,
      battlerTypes[playerObject["battlerType"]].levelAttacks.values.toList()
    );
    
    // inventory
    Main.player.inventory = new Inventory([]);
    List<Map<String, String>> characterItems = playerObject["inventory"];
    for(int i=0; i<characterItems.length; i++) {
      String itemName = characterItems.elementAt(i)["item"];
      int itemQuantity = int.parse(characterItems.elementAt(i)["quantity"]);
      Main.player.inventory.addItem(World.items[itemName], itemQuantity);
    }
    
    Main.player.inventory.money = playerObject["money"] as int;
    
    Main.player.name = playerObject["name"];
  }
  
  void parseGameEventChains(Map<String, List<Map<String, String>>> gameEventChainsObject) {
    gameEventChainsObject.forEach((String key, List<Map<String, String>> gameEvents) {
      List<GameEvent> gameEventChain = [];
      for(int i=0; i<gameEvents.length; i++) {
        if(gameEvents[i]["type"] == "text") {
          TextGameEvent textGameEvent = new TextGameEvent(
              gameEvents[i]["pictureId"] as int,
              gameEvents[i]["text"]
            );
          
          gameEventChain.add(textGameEvent);
        } else if(gameEvents[i]["type"] == "move") {
          MoveGameEvent moveGameEvent = new MoveGameEvent(
              gameEvents[i]["direction"] as int,
              gameEvents[i]["distance"] as int
            );
          
          gameEventChain.add(moveGameEvent);
        } else if(gameEvents[i]["type"] == "delay") {
          DelayGameEvent delayGameEvent = new DelayGameEvent(
              gameEvents[i]["milliseconds"] as int
            );
          
          gameEventChain.add(delayGameEvent);
        } else if(gameEvents[i]["type"] == "fade") {
          FadeGameEvent fadeGameEvent = new FadeGameEvent(
              gameEvents[i]["fadeType"] as int
            );
          
          gameEventChain.add(fadeGameEvent);
        } else if(gameEvents[i]["type"] == "heal") {
          Character character = World.characters[gameEvents[i]["character"]];
          if(character == null)
            character = Main.player;
          
          HealGameEvent healGameEvent = new HealGameEvent(
              character,
              gameEvents[i]["amount"] as int
            );
          
          gameEventChain.add(healGameEvent);
        } else if(gameEvents[i]["type"] == "store") {
          StoreGameEvent storeGameEvent = new StoreGameEvent();
          
          gameEventChain.add(storeGameEvent);
        } else if(gameEvents[i]["type"] == "battle") {
          BattleGameEvent battleGameEvent = new BattleGameEvent();
          
          gameEventChain.add(battleGameEvent);
        } else if(gameEvents[i]["type"] == "chain") {
          ChainGameEvent chainGameEvent = new ChainGameEvent(
              gameEvents[i]["gameEventChain"],
              gameEvents[i]["makeDefault"] as bool == true
            );
          
          gameEventChain.add(chainGameEvent);
        } else if(gameEvents[i]["type"] == "choice") {
          ChoiceGameEvent choiceGameEvent = new ChoiceGameEvent(
              gameEvents[i]["choices"] as Map<String, String>
            );
          
          gameEventChain.add(choiceGameEvent);
        } else if(gameEvents[i]["type"] == "warp") {
          WarpGameEvent warpGameEvent = new WarpGameEvent(
              gameEvents[i]["character"],
              gameEvents[i]["newMap"],
              gameEvents[i]["x"] as int,
              gameEvents[i]["y"] as int,
              gameEvents[i]["layer"] as int,
              gameEvents[i]["direction"] as int
            );
          
          gameEventChain.add(warpGameEvent);
        }
        
        World.gameEventChains[key] = gameEventChain;
      }
    });
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
    
    for(Character character in World.characters.values) {
      // TODO: account for character size
      if(character.map == Main.world.curMap && character.mapX == x && character.mapY == y && character.solid) {
        return true;
      }
    }
    
    if(Main.player.mapX == x && Main.player.mapY == y) {
      return true;
    }
    
    return false;
  }
  
  bool isInteractable(int x, int y) {
    for(int layer in layers) {
      if(maps[curMap].tiles[y][x][layer] is InteractableTile) {
        return true;
      }
    }
    
    for(Character character in World.characters.values) {
      if(character.map == Main.world.curMap && character.mapX == x && character.mapY == y) {
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
    
    for(Character character in World.characters.values) {
      if(character.map == Main.world.curMap && character.mapX == x && character.mapY == y) {
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