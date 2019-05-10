library dart_rpg.map_editor_battlers;

import 'dart:html';
import "dart:js";

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/encounter_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class MapEditorBattlers extends Component {
  void update() {
    this.setState({});
    Editor.debounceExport();
  }

  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    
    Main.world.maps[Main.world.curMap].battlerChances = new List<BattlerChance>();
    for(int i=0; querySelector('#map_battler_${i}_type') != null; i++) {
      try {
        String battlerTypeName = Editor.getSelectInputStringValue('#map_battler_${i}_type');
        int battlerTypeLevel = Editor.getTextInputIntValue('#map_battler_${i}_level', 1);
        double battlerTypeChance = double.parse(
          Editor.getTextInputDoubleValue('#map_battler_${i}_chance', 1.0).toStringAsFixed(9)
        );
        
        Battler battler = new Battler(
          null,
          World.battlerTypes[battlerTypeName],
          battlerTypeLevel,
          World.battlerTypes[battlerTypeName].getAttacksForLevel(battlerTypeLevel)
        );
        
        BattlerChance battlerChance = new BattlerChance(battler, battlerTypeChance);
        Main.world.maps[Main.world.curMap].battlerChances.add(battlerChance);
      } catch(e) {
        // could not update this map battler
        print("Error updating map battler: " + e.toString());
      }
    }
    
    //Editor.updateAndRetainValue(e);
    update();
  }

  void addNewBattler(MouseEvent e) {
    Main.world.maps[Main.world.curMap].battlerChances.add(
      new BattlerChance(
        new Battler( World.battlerTypes.keys.first, World.battlerTypes.values.first, 1, [] ),
        1.0
      )
    );
    
    update();
  }

  @override
  void render() {
    double totalChance = 0.0;
    for(int i=0; i<Main.world.maps[Main.world.curMap].battlerChances.length; i++) {
      totalChance += Main.world.maps[Main.world.curMap].battlerChances[i].chance;
    }

    List<JsObject> battlerTableRows = [];

    battlerTableRows.add(
      tr({},
        td({}, "Num"),
        td({}, "Battler Type"),
        td({}, "Level"),
        td({}, "Chance"),
        td({}, "")
      )
    );

    for(int i=0; i<Main.world.maps[Main.world.curMap].battlerChances.length; i++) {
      int percentChance = 0;
      if(totalChance != 0) {
        percentChance = (Main.world.maps[Main.world.curMap].battlerChances[i].chance / totalChance * 100).round();
      }

      List<JsObject> battlerTypeOptions = [];
      World.battlerTypes.forEach((String name, BattlerType battlerType) {
        battlerTypeOptions.add(
          option({'value': battlerType.name}, battlerType.name)
        );
      });

      battlerTableRows.add(
        tr({},
          td({}, i),
          td({},
            select({
              'id': 'map_battler_${i}_type',
              'value': Main.world.maps[Main.world.curMap].battlerChances[i].battler.name,
              'onChange': onInputChange
            }, battlerTypeOptions)
          ),
          td({},
            Editor.generateInput({
              'id': 'map_battler_${i}_level',
              'type': 'text',
              'className': 'number',
              'value': Main.world.maps[Main.world.curMap].battlerChances[i].battler.level,
              'onChange': onInputChange
            })
          ),
          td({},
            Editor.generateInput({
              'id': 'map_battler_${i}_chance',
              'type': 'text',
              'className': 'number decimal',
              'value': Main.world.maps[Main.world.curMap].battlerChances[i].chance,
              'onChange': onInputChange
            }),
            span({'id': 'map_battler_${i}_percent_chance'}, " ${percentChance}%")
          ),
          td({},
            button({
              'id': 'delete_map_battler_${i}',
              'onClick': Editor.generateConfirmDeleteFunction(
                Main.world.maps[Main.world.curMap].battlerChances, i, "battler", update
              )
            }, span({'className': 'fa fa-trash'}), " Delete")
          )
        )
      );
    }

    return
      div({'id': 'battlers_tab', 'className': 'tab'},
        div({'id': 'battlers_container'},
          button({'id': 'add_battler_button', 'onClick': addNewBattler}, span({'className': 'fa fa-plus-circle'}), " Add battler to map"),
          hr({}),
          div({'id': 'battlers_container'},
            table(
              {'className': 'editor_table'},
              tbody({}, battlerTableRows)
            )
          )
        )
      );
  }

  static void export(Map jsonMap, String key) {
    jsonMap["battlers"] = [];
    for(BattlerChance battlerChance in Main.world.maps[key].battlerChances) {
      jsonMap["battlers"].add({
        "name": battlerChance.battler.name,
        "type": battlerChance.battler.name,
        "level": battlerChance.battler.level,
        "chance": battlerChance.chance
      });
    }
  }
}
