library dart_rpg.map_editor_signs;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sign.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';

import 'package:react/react.dart';

class MapEditorSigns extends Component {
  static Map<String, List<Sign>> signs = {};

  attachListeners() {
    setSignDeleteButtonListeners();
    
    for(int i=0; i<signs[Main.world.curMap].length; i++) {
      Editor.attachInputListeners("sign_${i}", ["posx", "posy", "pic", "text"], onInputChange);
    }
  }

  componentWillMount() {
    for(int i=0; i<Main.world.maps.length; i++) {
      String key = Main.world.maps.keys.elementAt(i);
      List<List<List<Tile>>> mapTiles = Main.world.maps[key].tiles;
      signs[key] = [];
      
      for(var y=0; y<mapTiles.length; y++) {
        for(var x=0; x<mapTiles[y].length; x++) {
          for(int layer in World.layers) {
            if(mapTiles[y][x][layer] is Sign) {
              Sign mapSignTile = mapTiles[y][x][layer];
              Sign signTile = new Sign(
                  mapSignTile.solid,
                  new Sprite(
                    mapSignTile.sprite.id,
                    mapSignTile.sprite.posX,
                    mapSignTile.sprite.posY
                  ),
                  mapSignTile.textEvent.pictureSpriteId,
                  mapSignTile.textEvent.text
                );
              signs[key].add(signTile);
            }
          }
        }
      }
    }
  }

  componentDidMount(Element rootNode) {
    Editor.attachButtonListener("#add_sign_button", addNewSign);
    attachListeners();
  }

  componentDidUpdate(Map prevProps, Map prevState, Element rootNode) {
    attachListeners();
  }

  render() {
    List<JsObject> tableRows = [
      tr({},
        td({}, "Num"),
        td({}, "X"),
        td({}, "Y"),
        td({}, "Pic"),
        td({}, "Text"),
        td({})
      )
    ];

    for(int i=0; i<signs[Main.world.curMap].length; i++) {
      tableRows.add(
        tr({}, [
          td({}, i),
          td({},
            input({
              'id': 'sign_${i}_posx',
              'type': 'text',
              'className': 'number',
              'value': signs[Main.world.curMap][i].sprite.posX.round()
            })
          ),
          td({},
            input({
              'id': 'sign_${i}_posy',
              'type': 'text',
              'className': 'number',
              'value': signs[Main.world.curMap][i].sprite.posY.round()
            })
          ),
          td({},
            input({
              'id': 'sign_${i}_pic',
              'type': 'text',
              'className': 'number',
              'value': signs[Main.world.curMap][i].textEvent.pictureSpriteId
            })
          ),
          td({},
            textarea({'id': 'sign_${i}_text', 'value': signs[Main.world.curMap][i].textEvent.text})
          ),
          td({},
            button({'id': 'delete_sign_${i}'}, "Delete")
          )
        ])
      );
    }

    return
      div({'id': 'signs_tab', 'className': 'tab'}, [
        button({'id': 'add_sign_button', 'onClick': addNewSign}, "Add new sign"),
        hr({}),
        div({'id': 'signs_container'}, [
          table({'className': 'editor_table'}, tbody({}, tableRows))
        ])
      ]);
  }
  
  void addNewSign(MouseEvent e) {
    signs[Main.world.curMap].add( new Sign(false, new Sprite.int(0, 0, 0), 234, "Text") );
    props['update']();
  }
  
  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    
    for(int i=0; i<signs[Main.world.curMap].length; i++) {
      try {
        signs[Main.world.curMap][i] = new Sign(
          false,
          new Sprite(
            0,
            Editor.getTextInputIntValue("#sign_${i}_posx", 0) * 1.0,
            Editor.getTextInputIntValue("#sign_${i}_posy", 0) * 1.0
          ),
          Editor.getTextInputIntValue("#sign_${i}_pic", 0),
          Editor.getTextAreaStringValue("#sign_${i}_text")
        );
      } catch(e) {
        // could not update this sign
        print("Error updating sign: ${ e }");
      }
    }
    
    MapEditor.updateMap(shouldExport: true);
  }
  
  void setSignDeleteButtonListeners() {
    for(int i=0; i<signs[Main.world.curMap].length; i++) {
      Editor.attachButtonListener("#delete_sign_${i}", (MouseEvent e) {
        bool confirm = window.confirm('Are you sure you would like to delete this sign?');
        if(confirm) {
          signs[Main.world.curMap].removeAt(i);
          props['update']();
        }
      });
    }
  }
  
  void shift(int xAmount, int yAmount) {
    for(Sign sign in signs[Main.world.curMap]) {
      if(sign == null)
        continue;
      
      // shift
      if(sign.sprite != null) {
        sign.sprite.posX += xAmount;
        sign.sprite.posY += yAmount;
      }
      
      if(sign.topSprite != null) {
        sign.topSprite.posX += xAmount;
        sign.topSprite.posY += yAmount;
      }
      
      // delete if off map
      if(
          sign.sprite.posX < 0 ||
          sign.sprite.posX >= Main.world.maps[Main.world.curMap].tiles[0].length ||
          sign.sprite.posY < 0 ||
          sign.sprite.posY >= Main.world.maps[Main.world.curMap].tiles.length) {
        // delete it
        signs[Main.world.curMap].remove(sign);
      }
    }
  }
  
  static void export(List<List<List<Map>>> jsonMap, String key) {
    for(Sign sign in signs[key]) {
      int
        x = sign.sprite.posX.round(),
        y = sign.sprite.posY.round();
      
      // do not export signs that are outside of the bounds of the map
      if(jsonMap.length - 1 < y || jsonMap[0].length - 1 < x) {
        continue;
      }
      
      if(jsonMap[y][x][0] != null) {
        jsonMap[y][x][0]["sign"] = {
          "posX": x,
          "posY": y,
          "pic": sign.textEvent.pictureSpriteId,
          "text": sign.textEvent.text
        };
      }
    }
  }
}