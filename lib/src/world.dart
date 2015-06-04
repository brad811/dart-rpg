library dart_rpg.world;

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
import 'package:dart_rpg/src/inventory.dart';
import 'package:dart_rpg/src/item_potion.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/sign.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/store_character.dart';
import 'package:dart_rpg/src/text_game_event.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/warp_tile.dart';

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
  
  static Map<String, BattlerType> battlerTypes = {};
  
  final int
    viewXSize = (Main.canvasWidth/(Sprite.pixelsPerSprite*Sprite.spriteScale)).round(),
    viewYSize = (Main.canvasHeight/(Sprite.pixelsPerSprite*Sprite.spriteScale)).round();
  
  World(Function callback) {
    // TODO: improve editor so less is needed in world class
    loadGame(() {
      Main.player = new Player(3, 3);
      Main.player.battler = new Battler(
        "Player",
        battlerTypes["Player"], 3,
        battlerTypes["Player"].levelAttacks.values.toList()
      );
      
      Main.player.inventory.addItem(new ItemPotion(), 2);
      
      curMap = "apartment";
      
      Battler common = new Battler(null, battlerTypes["Common"], 5, battlerTypes["Common"].levelAttacks.values.toList());
      Battler rare = new Battler(null, battlerTypes["Rare"], 5, battlerTypes["Rare"].levelAttacks.values.toList());
      maps["main"].battlerChances = [
        new BattlerChance(common, 0.8),
        new BattlerChance(rare, 0.2)
      ];
      
      // Character
      Character someKid = addCharacter(
        "main",
        new Character(
          Tile.PLAYER,
          237,
          11, 15,
          layer: LAYER_BELOW
        )
      );
      
      someKid.direction = Character.RIGHT;
      
      List<GameEvent> characterGameEvents = [];
      characterGameEvents = [
        new TextGameEvent(237, "I'm like a kid, right?"),
        new GameEvent((callback) {
          Main.player.inputEnabled = false;
          chainCharacterMovement(
            someKid,
            [Character.LEFT, Character.LEFT, Character.LEFT,
              Character.RIGHT, Character.RIGHT, Character.RIGHT],
            () {
              Main.player.inputEnabled = true;
              callback();
            }
          );
        }),
        new TextGameEvent.choice(237, "See?",
          new ChoiceGameEvent(someKid, {
            "Yes": [
              new TextGameEvent(231, "That's fine."),
              new TextGameEvent(237, "If you say so!"),
              new GameEvent((callback) {
                someKid.gameEvent = characterGameEvents[0];
              })
            ],
            "No": [
              new TextGameEvent(231, "I hate you."),
              new TextGameEvent(237, "::sniff sniff:: Meanie!")
            ]
          })
        )
      ];
      
      Interactable.chainGameEvents(someKid, characterGameEvents);
      
      // add character that heals you
      Character healer = addCharacter(
        "house",
        new Character(
          Tile.PLAYER,
          237,
          5, 1, layer: LAYER_BELOW
        )
      );
      
      List<GameEvent> healerGameEvents = [];
      healerGameEvents = [
        new TextGameEvent(237, "Take a quick rest, you'll feel much better."),
        new GameEvent((callback) {
          Gui.fadeLightAction(() {
            Main.player.battler.curHealth = Main.player.battler.startingHealth;
            Main.player.battler.displayHealth = Main.player.battler.startingHealth;
          }, callback);
          //Main.player.inputEnabled = false;
        }),
        new TextGameEvent(237, "There you go, good as new.")
      ];
      
      Interactable.chainGameEvents(healer, healerGameEvents);
      
      Character fighter = addCharacter(
        "main",
        new Character(
          Tile.PLAYER,
          237,
          35, 13, layer: LAYER_BELOW
        )
      );
      
      fighter.sightDistance = 2;
      fighter.preBattleText = "Hey, before you leave, let's see how strong you are!";
      fighter.direction = Character.DOWN;
      fighter.battler = new Battler(
        "Player",
        battlerTypes["Player"], 4,
        battlerTypes["Player"].levelAttacks.values.toList()
      );
      fighter.postBattleEvent = new GameEvent((Function a) {
        new TextGameEvent(237, "Ouch! Clearly I have more training to do...", () {
          Main.focusObject = Main.player;
        }).trigger();
      });
      
      // add store clerk
      addStoreCharacter(
        "store",
        new StoreCharacter(
          Tile.PLAYER, 237,
          "Welcome! What are you looking for today?",
          "Thanks for coming in!",
          [
            new ItemStack(new ItemPotion(), 10)
          ],
          5, 1, layer: LAYER_BELOW
        )
      );
      
      Main.player.inventory.money = 500;
      
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
    Map<String, Map> obj = JSON.decode(jsonString);
    
    parseAttacks(obj["attacks"]);
    parseBattlerTypes(obj["battlerTypes"]);
    parseMaps(obj["maps"]);
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
  
  void parseMaps(Map<String, Map> mapsObject) {
    maps = {};
    curMap = mapsObject.keys.first;
    
    for(String mapName in mapsObject.keys) {
      GameMap gameMap = new GameMap(mapName);
      maps[mapName] = gameMap;
      maps[mapName].tiles = [];
      maps[mapName].characters = [];
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
  
  Character addCharacter(String map, Character character) {
    maps[map].characters.add(character);
    return character;
  }
  
  StoreCharacter addStoreCharacter(String map, StoreCharacter storeCharacter) {
    maps[map].characters.add(storeCharacter);
    return storeCharacter;
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