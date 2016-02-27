library dart_rpg.world;

import 'dart:convert';
import 'dart:html';
import 'dart:math' as math;

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/event_tile.dart';
import 'package:dart_rpg/src/game_map.dart';
import 'package:dart_rpg/src/game_type.dart';
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
  
  static Map<String, Attack> attacks = {};
  static Map<String, GameType> types = {};
  static Map<String, BattlerType> battlerTypes = {};
  static Map<String, Item> items = {};
  static Map<String, Character> characters = {};
  static Map<String, List<GameEvent>> gameEventChains = {};
  
  // used when saving the game
  static Map<String, Map> originalMaps = {};
  static Map<String, Map> originalCharacters = {};
  
  final int
    viewXSize = (Main.canvasWidth/(Sprite.pixelsPerSprite*Sprite.spriteScale)).round(),
    viewYSize = (Main.canvasHeight/(Sprite.pixelsPerSprite*Sprite.spriteScale)).round();
  
  World(Function callback) {
    loadGame(() {
      // move to the start map
      curMap = Main.player.character.map;
      
      callback();
    });
  }
  
  void loadGameProgress() {
    if(!window.localStorage.containsKey("saved_progress")) {
      print("No saved game found!");
      return;
    }
    
    Map<String, Map> obj = JSON.decode(window.localStorage["saved_progress"]);
    
    loadCharacterDifferences(obj["characters"]);
  }
  
  void loadCharacterDifferences(Map<String, Map<String, Object>> charactersJson) {
    charactersJson.forEach((String key, Map<String, Object> properties) {
      Character character = World.characters[key];
      
      if(properties.containsKey("spriteId"))
        character.spriteId = properties["spriteId"];
      
      if(properties.containsKey("pictureId"))
        character.pictureId = properties["pictureId"];
      
      if(properties.containsKey("sizeX"))
        character.sizeX = properties["sizeX"];
      
      if(properties.containsKey("sizeY"))
        character.sizeY = properties["sizeY"];
      
      if(properties.containsKey("map"))
        character.map = properties["map"];
      
      if(properties.containsKey("name"))
        character.name = properties["name"];
      
      // map information
      if(properties.containsKey("mapX"))
        character.warp(character.map, properties["mapX"], character.mapY, character.layer, character.direction);
      
      if(properties.containsKey("mapY"))
        character.warp(character.map, character.mapX, properties["mapY"], character.layer, character.direction);
      
      if(properties.containsKey("layer"))
        character.layer = properties["layer"];
      
      if(properties.containsKey("direction"))
        character.direction = properties["direction"];
      
      if(properties.containsKey("solid"))
        character.solid = properties["solid"];
      
      // inventory // TODO: differentiate per-item
      if(properties.containsKey("inventory")) {
        // TODO
      }
      
      if(properties.containsKey("money"))
        character.inventory.money = properties["money"];
      
      // game event chain
      if(properties.containsKey("gameEventChain"))
        character.setGameEventChain(properties["gameEventChain"], 0);
      
      // battle // TODO: exp, stats, etc.
      
      // TODO: battler type
      
      if(properties.containsKey("battlerLevel"))
        character.battler.level = properties["battlerLevel"];
      
      if(properties.containsKey("sightDistance"))
        character.sightDistance = properties["sightDistance"];
      
      if(properties.containsKey("player") && properties["player"] == true) {
        Main.player.character = character;
      }
    });
  }
  
  void saveGameProgress() {
    Map<String, Map> obj = {};
    
    // characters
    saveCharacterDifferences(obj);
    
    // tiles
    saveTileDifferences(obj);
    
    // TODO: store somewhere
    window.localStorage["saved_progress"] = JSON.encode(obj);
  }
  
  void saveTileDifferences(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> mapsJson = {};
    
    Main.world.maps.forEach((String key, GameMap map) {
      Map<String, Map<int, Map<int, Map<int, Map<String, Object>>>>> mapJson = {};
      
      for(int y=0; y<map.tiles.length; y++) {
        for(int x=0; x<map.tiles[y].length; x++) {
          for(int layer=0; layer<map.tiles[y][x].length; layer++) {
            Tile tile = map.tiles[y][x][layer];
            Map<String, Object> originalTile = originalMaps[key]["tiles"][y][x][layer];
            
            if(tile == null && originalTile == null) {
              continue;
            }
            
            if(tile == null && originalTile != null) {
              // TODO: indicated to set tile to null
              continue;
            }
            
            bool oneIsNull = false;
            if(
              (tile == null && originalTile != null) ||
              (tile != null && originalTile == null)
            ) {
              oneIsNull = true;
            }
            
            if(oneIsNull || tile.sprite.id != originalTile["spriteId"]) {
              saveTileDifference(mapJson, y, x, layer, "spriteId", tile.sprite.id);
            }
            
            // TODO: the rest of the tile properties
          }
        }
      }
    });
    
    exportJson["maps"] = mapsJson;
  }
  
  void saveTileDifference(Map mapJson, int y, int x, int layer, String property, Object value) {
    if(mapJson["tiles"] == null) {
      mapJson["tiles"] = {};
    }
    
    if(mapJson["tiles"][y] == null) {
      mapJson["tiles"][y] = {};
    }
    
    if(mapJson["tiles"][y][x] == null) {
      mapJson["tiles"][y][x] = {};
    }
    
    if(mapJson["tiles"][y][x][layer] == null) {
      mapJson["tiles"][y][x][layer] = {};
    }
    
    mapJson["tiles"][y][x][layer][property] = value;
  }
  
  void saveCharacterDifferences(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> charactersJson = {};
    World.characters.forEach((String key, Character character) {
      Map<String, Object> characterJson = {};
      
      Map<String, Object> originalCharacterJson = originalCharacters[key];
      
      if(character.spriteId != originalCharacterJson["spriteId"])
        characterJson["spriteId"] = character.spriteId;
      
      if(character.pictureId != originalCharacterJson["pictureId"])
        characterJson["pictureId"] = character.pictureId;
      
      if(character.sizeX != originalCharacterJson["sizeX"])
        characterJson["sizeX"] = character.sizeX;
      
      if(character.sizeY != originalCharacterJson["sizeY"])
        characterJson["sizeY"] = character.sizeY;
      
      if(character.map != originalCharacterJson["map"])
        characterJson["map"] = character.map;
      
      if(character.name != originalCharacterJson["name"])
        characterJson["name"] = character.name;
      
      // map information
      if(character.mapX != originalCharacterJson["mapX"])
        characterJson["mapX"] = character.mapX;
      
      if(character.mapY != originalCharacterJson["mapY"])
        characterJson["mapY"] = character.mapY;
      
      if(character.layer != originalCharacterJson["layer"])
        characterJson["layer"] = character.layer;
      
      if(character.direction != originalCharacterJson["direction"])
        characterJson["direction"] = character.direction;
      
      if(character.solid != originalCharacterJson["solid"])
        characterJson["solid"] = character.solid;
      
      // inventory // TODO: differentiate per-item
      List<Map<String, String>> inventoryJson = [];
      character.inventory.itemNames().forEach((String itemName) {
        Map<String, String> itemJson = {};
        itemJson["item"] = itemName;
        itemJson["quantity"] = character.inventory.getQuantity(itemName).toString();
        
        inventoryJson.add(itemJson);
      });
      
      if(inventoryJson.toString() != originalCharacterJson["inventory"].toString())
        characterJson["inventory"] = inventoryJson;
      
      if(character.inventory.money != originalCharacterJson["money"])
        characterJson["money"] = character.inventory.money;
      
      // game event chain
      if(character.getGameEventChain() != originalCharacterJson["gameEventChain"])
        characterJson["gameEventChain"] = character.getGameEventChain();
      
      // battle // TODO: exp, stats, etc.
      if(character.battler.battlerType.name != originalCharacterJson["battlerType"])
        characterJson["battlerType"] = character.battler.battlerType.name;
        
      if(character.battler.level.toString() != originalCharacterJson["battlerLevel"])
        characterJson["battlerLevel"] = character.battler.level.toString();
          
      if(character.sightDistance.toString() != originalCharacterJson["sightDistance"])
        characterJson["sightDistance"] = character.sightDistance.toString();
      
      if(Main.player.character.label == character.label) {
        if(originalCharacterJson["player"] != true)
          characterJson["player"] = true;
      } else if(originalCharacterJson["player"] == true) {
        characterJson["player"] = false;
      }
      
      if(characterJson.toString() != "{}")
       charactersJson[key] = characterJson;
    });
    
    exportJson["characters"] = charactersJson;
  }
  
  // TODO: rename? so it's not confused with save/load
  void loadGame(Function callback) {
    HttpRequest
      .getString("game.json")
      .then((String jsonString) {
        parseGame(jsonString, () {
          if(callback != null) {
            callback();
          }
        });
      })
      .catchError((Error err) {
        print("Error loading maps! (${err})");
        print(err.stackTrace);
        if(callback != null)
          callback();
      });
  }
  
  void parseGame(String jsonString, Function callback) {
    Map<String, Map> obj;
    TextAreaElement gameJson = querySelector("#game_json");
    
    if(gameJson == null) {
      gameJson = querySelector("#export_json");
    }
    
    if((gameJson == null || gameJson.value == "") && jsonString == "") {
      obj = {};
    } else if(gameJson != null && gameJson.value == "") {
      gameJson.value = jsonString;
      obj = JSON.decode(gameJson.value);
    } else {
      if(gameJson != null) {
        obj = JSON.decode(gameJson.value);
      } else {
        obj = JSON.decode(jsonString);
      }
    }
    
    parseSettings(obj["settings"], () {
      // set the original characters for saving purposes
      originalMaps = obj["maps"];
      originalCharacters = obj["characters"];
      
      parseTypes(obj["types"]);
      parseAttacks(obj["attacks"]);
      parseBattlerTypes(obj["battlerTypes"]);
      parseItems(obj["items"]);
      parseMaps(obj["maps"]);
      parseCharacters(obj["characters"]);
      parseGameEventChains(obj["gameEventChains"]);
      
      callback();
    });
  }
  
  void parseSettings(Map<String, String> settingsObject, Function callback) {
    if(settingsObject == null) {
      settingsObject = {
        "spriteSheetLocation": "sprite_sheet.png",
        "pixelsPerSprite": 16,
        "spriteScale": 2,
        "framesPerSecond": 40
      };
    }
    
    Main.spritesImageLocation = settingsObject["spriteSheetLocation"];
    Main.spritesImage = new ImageElement();
    
    Main.spritesImage.onLoad.listen((Event e) {
      Sprite.pixelsPerSprite = settingsObject["pixelsPerSprite"] as int;
      Sprite.spriteScale = settingsObject["spriteScale"] as int;
      
      Sprite.scaledSpriteSize = Sprite.pixelsPerSprite * Sprite.spriteScale;
      Sprite.spriteSheetWidth = (Main.spritesImage.width / Sprite.pixelsPerSprite).round();
      Sprite.spriteSheetHeight = (Main.spritesImage.height / Sprite.pixelsPerSprite).round();
      
      callback();
    });
    
    Main.spritesImage.onError.listen((Event e) {
      window.alert("Unable to load sprite sheet:\n\n${ Main.spritesImageLocation }\n\nSee the javascript console for more information.");
    });
    
    Main.spritesImage.crossOrigin = "anonymous";
    Main.spritesImage.src = Main.spritesImageLocation;
    
    Main.framesPerSecond = (settingsObject["framesPerSecond"] != null) ? settingsObject["framesPerSecond"] as int : 40;
    Main.timeDelay = (1000 / Main.framesPerSecond).round();
  }
  
  void parseAttacks(Map<String, Map> attacksObject) {
    attacks = {};
    
    if(attacksObject == null) {
      return;
    }
    
    for(String attackName in attacksObject.keys) {
      attacks[attackName] = new Attack(
        attackName,
        int.parse(attacksObject[attackName]["category"]),
        attacksObject[attackName]["type"],
        int.parse(attacksObject[attackName]["power"])
      );
    }
  }
  
  void parseTypes(Map<String, Map> typesObject) {
    types = {};
    
    if(typesObject == null) {
      types = {
        "normal": new GameType("normal")
      };
      return;
    }
    
    for(String typeName in typesObject.keys) {
      types[typeName] = new GameType(
        typeName
      );
      
      // add effectiveness pairings
      for(int i=0; i<typesObject[typeName]["effectiveness"].length; i++) {
        String defendingType = typesObject[typeName]["effectiveness"].keys.elementAt(i);
        
        types[typeName].setEffectiveness(defendingType, typesObject[typeName]["effectiveness"][defendingType]);
      }
    }
  }
  
  void parseBattlerTypes(Map<String, Map> battlerTypesObject) {
    battlerTypes = {};
    
    if(battlerTypesObject == null) {
      String battlerTypeName = "new battler type";
      
      battlerTypes[battlerTypeName] = new BattlerType(
          0, battlerTypeName, World.types.keys.first,
          1, 1, 1, 1, 1, 1,
          {}, 1.0
      );
      
      return;
    }
    
    for(String battlerTypeName in battlerTypesObject.keys) {
      battlerTypes[battlerTypeName] = new BattlerType(
          int.parse(battlerTypesObject[battlerTypeName]["spriteId"]),
          battlerTypeName,
          battlerTypesObject[battlerTypeName]["type"],
          int.parse(battlerTypesObject[battlerTypeName]["health"]),
          int.parse(battlerTypesObject[battlerTypeName]["physicalAttack"]),
          int.parse(battlerTypesObject[battlerTypeName]["magicalAttack"]),
          int.parse(battlerTypesObject[battlerTypeName]["physicalDefense"]),
          int.parse(battlerTypesObject[battlerTypeName]["magicalDefense"]),
          int.parse(battlerTypesObject[battlerTypeName]["speed"]),
          {},
          double.parse(battlerTypesObject[battlerTypeName]["rarity"])
      );
      
      Map<String, List<String>> levelAttacks = battlerTypesObject[battlerTypeName]["levelAttacks"];
      levelAttacks.forEach((String level, List<String> attackNames) {
        attackNames.forEach((String attackName) {
          if(battlerTypes[battlerTypeName].levelAttacks[int.parse(level)] == null) {
            battlerTypes[battlerTypeName].levelAttacks[int.parse(level)] = [];
          }
          
          battlerTypes[battlerTypeName].levelAttacks[int.parse(level)].add(World.attacks[attackName]);
        });
      });
    }
  }
  
  void parseMaps(Map<String, Map> mapsObject) {
    maps = {};
    
    if(mapsObject == null) {
      mapsObject = {
        "new map": {
          "startMap": true,
          "startX": 0,
          "startY": 0,
          "tiles": [[[null,null,null,null]]],
          "battlers": []
        }
      };
    }
    
    curMap = mapsObject.keys.first;
    
    for(String mapName in mapsObject.keys) {
      GameMap gameMap = new GameMap(mapName);
      maps[mapName] = gameMap;
      maps[mapName].tiles = [];
      
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
              } else if(curTile['event'] != null) {
                mapTiles[y][x][k] = new EventTile(
                  curTile['event']['gameEventChain'],
                  curTile['event']['runOnce'],
                  new Sprite.int(curTile['id'], x, y)
                  // TODO: layered
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
        String mapBattlerType = mapsObject[mapName]["battlers"][i]["type"];
        int mapBattlerLevel = mapsObject[mapName]["battlers"][i]["level"];
        double mapBattlerChance = mapsObject[mapName]["battlers"][i]["chance"];
        
        Battler battler = new Battler(
          mapBattlerType, World.battlerTypes[mapBattlerType],
          mapBattlerLevel, World.battlerTypes[mapBattlerType].getAttacksForLevel(mapBattlerLevel)
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
    
    if(itemsObject == null) {
      return;
    }
    
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
    
    if(charactersObject == null) {
      Character character = new Character(
        "player",
        0, 0, 0, 0,
        layer: 0,
        sizeX: 1,
        sizeY: 2,
        solid: true
      );

      character.name = "Player";
      character.battler = new Battler(null, World.battlerTypes.values.first, 1, []);
      character.map = Main.world.maps.keys.first;

      characters["player"] = character;

      return;
    }
    
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
      charactersObject[characterLabel]["mapX"],
      charactersObject[characterLabel]["mapY"],
      layer: charactersObject[characterLabel]["layer"],
      sizeX: charactersObject[characterLabel]["sizeX"] as int,
      sizeY: charactersObject[characterLabel]["sizeY"] as int,
      solid: charactersObject[characterLabel]["solid"]
    );
    
    character.name = charactersObject[characterLabel]["name"];
    
    character.map = charactersObject[characterLabel]["map"];
    character.startMap = character.map;
    
    character.direction = charactersObject[characterLabel]["direction"];
    
    String battlerTypeName = charactersObject[characterLabel]["battlerType"];
    BattlerType battlerType = World.battlerTypes[battlerTypeName];
    
    int level = int.parse(charactersObject[characterLabel]["battlerLevel"]);
    
    character.battler = new Battler(
        battlerType.name,
        battlerType,
        level,
        battlerType.getAttacksForLevel(level)
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
    
    // money
    if(charactersObject[characterLabel]["money"] != null) {
      character.inventory.money = charactersObject[characterLabel]["money"];
    } else {
      character.inventory.money = 0;
    }
    
    // game events
    character.setGameEventChain(charactersObject[characterLabel]["gameEventChain"], 0);
    
    if(charactersObject[characterLabel]["player"] == true) {
      Main.player = new Player(character);
    }
    
    return character;
  }
  
  void parseGameEventChains(Map<String, List<Map<String, String>>> gameEventChainsObject) {
    World.gameEventChains = {};
    
    if(gameEventChainsObject == null) {
      return;
    }
    
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
            character = Main.player.character;
          
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
            spriteId + x + (y*Sprite.spriteSheetWidth),
            posX+x, posY+y
          ),
          handler
        );
      }
    }
  }
  
  bool isSolid(int x, int y) {
    if(
        x < 0 || x >= Main.world.maps[Main.world.curMap].tiles[0].length ||
        y < 0 || y >= Main.world.maps[Main.world.curMap].tiles.length) {
      return true;
    }
    
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
    
    if(Main.player.character.mapX == x && Main.player.character.mapY == y) {
      return true;
    }
    
    return false;
  }
  
  bool isInteractable(int x, int y) {
    if(maps[curMap].tiles.length <= y) return false;
    if(maps[curMap].tiles[y].length <= x) return false;

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
        var y=math.max(Main.player.character.mapY-(viewYSize/2+1).round(), 0);
        y<Main.player.character.mapY+(viewYSize/2+1).round() && y<maps[curMap].tiles.length;
        y++) {
      for(
          var x=math.max(Main.player.character.mapX-(viewXSize/2).round(), 0);
          x<Main.player.character.mapX+(viewXSize/2+2).round() && x<maps[curMap].tiles[y].length;
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