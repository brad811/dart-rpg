library dart_rpg.map_editor_signs;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sign.dart';
import 'package:dart_rpg/src/sprite.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';

import 'package:react/react.dart';

class MapEditorSigns extends Component {
  update() {
    setState({});
    MapEditor.updateMap();
    Editor.debounceExport();
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

    for(int i=0; i<MapEditor.signs[Main.world.curMap].length; i++) {
      tableRows.add(
        tr({},
          td({}, i),
          td({},
            Editor.generateInput({
              'id': 'sign_${i}_posx',
              'type': 'text',
              'className': 'number',
              'value': MapEditor.signs[Main.world.curMap][i].sprite.posX.round(),
              'onChange': onInputChange
            })
          ),
          td({},
            Editor.generateInput({
              'id': 'sign_${i}_posy',
              'type': 'text',
              'className': 'number',
              'value': MapEditor.signs[Main.world.curMap][i].sprite.posY.round(),
              'onChange': onInputChange
            })
          ),
          td({},
            Editor.generateInput({
              'id': 'sign_${i}_pic',
              'type': 'text',
              'className': 'number',
              'value': MapEditor.signs[Main.world.curMap][i].textEvent.pictureSpriteId,
              'onChange': onInputChange
            })
          ),
          td({},
            textarea({
              'id': 'sign_${i}_text',
              'value': MapEditor.signs[Main.world.curMap][i].textEvent.text,
              'onChange': onInputChange
            })
          ),
          td({},
            button({
              'id': 'delete_sign_${i}',
              'onClick': Editor.generateConfirmDeleteFunction(
                MapEditor.signs[Main.world.curMap], i, "sign", update
              )
            }, span({'className': 'fa fa-trash'}), " Delete")
          )
        )
      );
    }

    return
      div({'id': 'signs_tab', 'className': 'tab'},
        button({'id': 'add_sign_button', 'onClick': addNewSign}, span({'className': 'fa fa-plus-circle'}), " Add new sign"),
        hr({}),
        div({'id': 'signs_container'},
          table({'className': 'editor_table'}, tbody({}, tableRows))
        )
      );
  }
  
  void addNewSign(MouseEvent e) {
    MapEditor.signs[Main.world.curMap].add( new Sign(false, new Sprite.int(0, 0, 0), 234, "Text") );
    props['update']();
  }
  
  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    
    for(int i=0; i<MapEditor.signs[Main.world.curMap].length; i++) {
      try {
        MapEditor.signs[Main.world.curMap][i] = new Sign(
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
    
    update();
  }
  
  static void shift(int xAmount, int yAmount) {
    for(Sign sign in MapEditor.signs[Main.world.curMap]) {
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
        MapEditor.signs[Main.world.curMap].remove(sign);
      }
    }
  }
  
  static void export(List<List<List<Map>>> jsonMap, String key) {
    for(Sign sign in MapEditor.signs[key]) {
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