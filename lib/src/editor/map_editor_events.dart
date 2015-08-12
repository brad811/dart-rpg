library dart_rpg.map_editor_events;

import 'dart:html';

import 'package:dart_rpg/src/event_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/map_editor.dart';

import 'editor.dart';

class MapEditorEvents {
  static Map<String, List<EventTile>> events = {};
  
  static void setUp() {
    Editor.attachButtonListener("#add_event_button", addNewEvent);
    
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      List<List<List<Tile>>> mapTiles = Main.world.maps[key].tiles;
      events[key] = [];
      
      for(var y=0; y<mapTiles.length; y++) {
        for(var x=0; x<mapTiles[y].length; x++) {
          for(int layer in World.layers) {
            if(mapTiles[y][x][layer] is EventTile) {
              EventTile mapEventTile = mapTiles[y][x][layer];
              EventTile eventTile = new EventTile(
                  mapEventTile.gameEventChain,
                  mapEventTile.runOnce,
                  new Sprite(
                    mapEventTile.sprite.id,
                    mapEventTile.sprite.posX,
                    mapEventTile.sprite.posY
                  )
                );
              events[key].add(eventTile);
            }
          }
        }
      }
    }
  }
  
  static void addNewEvent(MouseEvent e) {
    if(World.gameEventChains.keys.length > 0) {
      events[Main.world.curMap].add( new EventTile(World.gameEventChains.keys.first, false, new Sprite.int(0, 0, 0), false) );
      Editor.update();
    }
  }
  
  static void update() {
    String html;
    html = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Num</td><td>X</td><td>Y</td><td>Game Event Chain</td><td>Run Once</td><td></td>"+
      "  </tr>";
    for(int i=0; i<events[Main.world.curMap].length; i++) {
      html +=
        "<tr>"+
        "  <td>${i}</td>"+
        "  <td><input id='map_event_${i}_posx' type='text' class='number' value='${ events[Main.world.curMap][i].sprite.posX.round() }' /></td>"+
        "  <td><input id='map_event_${i}_posy' type='text' class='number' value='${ events[Main.world.curMap][i].sprite.posY.round() }' /></td>"+
        "  <td>";
        
        "  <td><input id='map_event_${i}_game_event_chain' type='text' class='number' value='${ events[Main.world.curMap][i].gameEventChain }' /></td>";
        html += "<select id='map_event_${i}_game_event_chain'>";
        World.gameEventChains.keys.forEach((String gameEventChain) {
          html += "<option value='${gameEventChain}'";
          if(events[Main.world.curMap][i].gameEventChain == gameEventChain) {
            html += " selected";
          }
          
          html += ">${gameEventChain}</option>";
        });
        html += "</select>";
        html += "  </td>";
        
        html += "<td><input id='map_event_${i}_run_once' type='checkbox' ";
        if(events[Main.world.curMap][i].runOnce) {
          html += "checked='checked' ";
        }
        html += "/></td>";
        
        html += "  <td><button id='delete_event_${i}'>Delete</button></td>" +
        "</tr>";
    }
    html += "</table>";
    querySelector("#events_container").setInnerHtml(html);
    
    setEventDeleteButtonListeners();
    
    for(int i=0; i<events[Main.world.curMap].length; i++) {
      Editor.attachInputListeners("map_event_${i}", ["posx", "posy", "game_event_chain", "run_once"], onInputChange);
    }
  }
  
  static void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    
    for(int i=0; i<events[Main.world.curMap].length; i++) {
      try {
        events[Main.world.curMap][i] = new EventTile(
          Editor.getSelectInputStringValue("#map_event_${i}_game_event_chain"),
          Editor.getCheckboxInputBoolValue("#map_event_${i}_run_once"),
          new Sprite(
            0,
            Editor.getTextInputDoubleValue('#map_event_${i}_posx', 0.0),
            Editor.getTextInputDoubleValue('#map_event_${i}_posy', 0.0)
          )
        );
      } catch(e) {
        // could not update this event
      }
    }
    
    // TODO: catch out of bounds values
    //Editor.updateAndRetainValue(e);
    MapEditor.updateMap(shouldExport: true);
  }
  
  static void setEventDeleteButtonListeners() {
    for(int i=0; i<events[Main.world.curMap].length; i++) {
      Editor.attachButtonListener("#delete_event_${i}", (MouseEvent e) {
        bool confirm = window.confirm('Are you sure you would like to delete this event?');
        if(confirm) {
          events[Main.world.curMap].removeAt(i);
          Editor.update();
        }
      });
    }
  }
  
  static void shift(int xAmount, int yAmount) {
    for(EventTile event in events[Main.world.curMap]) {
      if(event == null)
        continue;
      
      // shift
      if(event.sprite != null) {
        event.sprite.posX += xAmount;
        event.sprite.posY += yAmount;
      }
      
      if(event.topSprite != null) {
        event.topSprite.posX += xAmount;
        event.topSprite.posY += yAmount;
      }
      
      // delete if off map
      if(
          event.sprite.posX < 0 ||
          event.sprite.posX >= Main.world.maps[Main.world.curMap].tiles[0].length ||
          event.sprite.posY < 0 ||
          event.sprite.posY >= Main.world.maps[Main.world.curMap].tiles.length) {
        // delete it
        events[Main.world.curMap].remove(event);
      }
    }
  }
  
  static void export(List<List<List<Map>>> jsonMap, String key) {
    for(EventTile event in events[key]) {
      int
        x = event.sprite.posX.round(),
        y = event.sprite.posY.round();
      
      // do not export events that are outside of the bounds of the map
      if(jsonMap.length - 1 < y || jsonMap[0].length - 1 < x) {
        continue;
      }
      
      if(jsonMap[y][x][0] != null) {
        jsonMap[y][x][0]["event"] = {
          "gameEventChain": event.gameEventChain,
          "runOnce": event.runOnce
        };
      }
    }
  }
}