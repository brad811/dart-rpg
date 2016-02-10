library dart_rpg.map_editor_warps;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/warp_tile.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';

import 'package:react/react.dart';

class MapEditorWarps extends Component {
  void update() {
    setState({});
    MapEditor.updateMap();
    Editor.debounceExport();
  }

  render() {
    List<JsObject> tableRows = [
      tr({}, [
        td({}, "Num"),
        td({}, "X"),
        td({}, "Y"),
        td({}, "Dest Map"),
        td({}, "Dest X"),
        td({}, "Dest Y"),
        td({})
      ])
    ];

    List<JsObject> destMapOptions = [];
    for(String key in Main.world.maps.keys) {
      destMapOptions.add(
        option({'value': key}, key)
      );
    }

    for(int i=0; i<MapEditor.warps[Main.world.curMap].length; i++) {
      tableRows.add(
        tr({}, [
          td({}, i),
          td({},
            input({
              'id': 'warp_${i}_posx',
              'type': 'text',
              'className':'number',
              'value': MapEditor.warps[Main.world.curMap][i].sprite.posX.round(),
              'onChange': onInputChange
            })
          ),
          td({},
            input({
              'id': 'warp_${i}_posy',
              'type': 'text',
              'className':'number',
              'value': MapEditor.warps[Main.world.curMap][i].sprite.posY.round(),
              'onChange': onInputChange
            })
          ),
          td({},
            select({
              'id': 'warp_${i}_dest_map',
              'onChange': onInputChange
            }, destMapOptions)
          ),
          td({},
            input({
              'id': 'warp_${i}_dest_x',
              'type': 'text',
              'className':'number',
              'value': MapEditor.warps[Main.world.curMap][i].destX,
              'onChange': onInputChange
            })
          ),
          td({},
            input({
              'id': 'warp_${i}_dest_y',
              'type': 'text',
              'className':'number',
              'value': MapEditor.warps[Main.world.curMap][i].destY,
              'onChange': onInputChange
            })
          ),
          td({},
            button({
              'id': 'delete_warp_${i}',
              'onClick': Editor.generateConfirmDeleteFunction(MapEditor.warps[Main.world.curMap], i, "warp", update)
            }, 'Delete')
          )
        ])
      );
    }

    return
      div({'id': 'warps_tab', 'className': 'tab'}, [
        button({'id': 'add_warp_button', 'onClick': addNewWarp}, "Add new warp"),
        hr({}),
        div({'id': 'warps_container'}, [
          table({'className': 'editor_table'}, tbody({}, tableRows))
        ])
      ]);
  }
  
  void addNewWarp(MouseEvent e) {
    MapEditor.warps[Main.world.curMap].add(
      new WarpTile(
        false,
        new Sprite.int(0, 0, 0),
        Main.world.curMap, 0, 0
      )
    );
    
    update();
  }
  
  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    
    for(int i=0; i<MapEditor.warps[Main.world.curMap].length; i++) {
      try {
        MapEditor.warps[Main.world.curMap][i].sprite.posX = Editor.getTextInputDoubleValue('#warp_${i}_posx', 0.0);
        MapEditor.warps[Main.world.curMap][i].sprite.posY = Editor.getTextInputDoubleValue('#warp_${i}_posy', 0.0);
        MapEditor.warps[Main.world.curMap][i].destMap = Editor.getSelectInputStringValue('#warp_${i}_dest_map');
        MapEditor.warps[Main.world.curMap][i].destX = Editor.getTextInputIntValue('#warp_${i}_dest_x', 0);
        MapEditor.warps[Main.world.curMap][i].destY = Editor.getTextInputIntValue('#warp_${i}_dest_y', 0);
      } catch(e) {
        // could not update this warp
        print("Error while updating warp: ${e}");
      }
    }
    
    update();
  }
  
  static void shift(int xAmount, int yAmount) {
    MapEditor.warps.forEach((String mapName, List<WarpTile> warpTiles) {
      warpTiles.forEach((WarpTile warpTile) {
        if(warpTile == null)
          return;
        
        // shift warps on the current map
        if(mapName == Main.world.curMap) {
          // shift
          if(warpTile.sprite != null) {
            warpTile.sprite.posX += xAmount;
            warpTile.sprite.posY += yAmount;
          }
          
          if(warpTile.topSprite != null) {
            warpTile.topSprite.posX += xAmount;
            warpTile.topSprite.posY += yAmount;
          }
          
          // delete if off map
          if(
              warpTile.sprite.posX < 0 ||
              warpTile.sprite.posX >= Main.world.maps[Main.world.curMap].tiles[0].length ||
              warpTile.sprite.posY < 0 ||
              warpTile.sprite.posY >= Main.world.maps[Main.world.curMap].tiles.length) {
            // delete it
            MapEditor.warps[Main.world.curMap].remove(warpTile);
          }
        }
        
        // shift warp destinations on the current map
        if(warpTile.destMap == Main.world.curMap) {
          // shift the destination
          warpTile.destX += xAmount;
          warpTile.destY += yAmount;
        }
      });
    });
  }
  
  static void export(List<List<List<Map>>> jsonMap, String key) {
    for(WarpTile warp in MapEditor.warps[key]) {
      int
        x = warp.sprite.posX.round(),
        y = warp.sprite.posY.round();
      
      // handle the map shrinking until a warp is out of bounds
      if(jsonMap.length - 1 < y || jsonMap[0].length - 1 < x) {
        continue;
      }
      
      if(jsonMap[y][x][0] != null) {
        jsonMap[y][x][0]["warp"] = {
          "posX": x,
          "posY": y,
          "destMap": warp.destMap,
          "destX": warp.destX,
          "destY": warp.destY
        };
      }
    }
  }
}