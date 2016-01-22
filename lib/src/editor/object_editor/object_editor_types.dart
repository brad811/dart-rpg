library dart_rpg.object_editor_types;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/game_type.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor.dart';

import 'package:react/react.dart';

class ObjectEditorTypesComponent extends Component {
  void onInputChange() {
    // TODO: implement!
    print("ObjectEditorTypesComponent.onInputChange not yet implemented!");
  }

  render() {
    List<JsObject> tableRows = [
      tr({},
        td({}, "Num"),
        td({}, "Name"),
        td({})
      )
    ];

    for(int i=0; i<World.types.keys.length; i++) {
      GameType gameType = World.types.values.elementAt(i);

      tableRows.add(
        tr({'id': 'type_row_${i}'}, [
          td({}, i),
          td({},
            input({'id': 'type_${i}_name', 'type': 'text', 'value': gameType.name})
          ),
          td({},
            button({'id': 'delete_type_${i}'}, "Delete")
          )
        ])
      );
    }

    return table({'className': 'editor_table'}, tbody({}, tableRows));
  }
}

var objectEditorTypesComponent = registerComponent(() => new ObjectEditorTypesComponent());

class ObjectEditorTypesEffectivenessComponent extends Component {
  int selected = -1;

  void onInputChange() {
    // TODO: implement!
    print("ObjectEditorTypesEffectivenessComponent.onInputChange not yet implemented!");
  }

  render() {
    List<JsObject> typeContainers = [];

    for(int i=0; i<World.types.keys.length; i++) {
      GameType gameType = World.types.values.elementAt(i);

      List<JsObject> tableRows = [
        tr({}, [
          td({}, "Num"),
          td({}, "Defending Type"),
          td({}, "Effectiveness")
        ])
      ];

      for(int j=0; j<World.types.keys.length; j++) {
        GameType defendingGameType = World.types.values.elementAt(j);

        tableRows.add(
          tr({}, [
            td({}, j),
            td({}, defendingGameType.name),
            td({},
              input({
                'id': 'type_${i}_effectiveness_${j}',
                'type': 'text',
                'className': 'number decimal',
                'value': gameType.getEffectiveness(defendingGameType.name)
              })
            )
          ])
        );
      }

      typeContainers.add(
        div({'id': 'type_${i}_effectiveness_container', 'className': selected == i ? '' : 'hidden'},
          table({}, tableRows)
        )
      );
    }

    return div({}, typeContainers);
  }
}

var objectEditorTypesEffectivenessComponent = registerComponent(() => new ObjectEditorTypesEffectivenessComponent());

class ObjectEditorTypes {
  static List<String> advancedTabs = ["type_effectiveness"];
  
  static int selected;
  
  static void setUp() {
    Editor.setUpTabs(advancedTabs);
    Editor.attachButtonListener("#add_type_button", addNewType);
    
    querySelector("#object_editor_types_tab_header").onClick.listen((MouseEvent e) {
      ObjectEditorTypes.selectRow(0);
    });
  }
  
  static void addNewType(MouseEvent e) {
    World.types["New Type"] = new GameType("New Type");
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    render(objectEditorTypesComponent({}), querySelector('#types_container'));
    render(objectEditorTypesEffectivenessComponent({}), querySelector('#type_effectiveness_container'));
    
    // highlight the selected row
    if(querySelector("#type_row_${selected}") != null) {
      querySelector("#type_row_${selected}").classes.add("selected");
      querySelector("#object_editor_types_advanced").classes.remove("hidden");
    }
    
    Editor.setMapDeleteButtonListeners(World.types, "type", () { /* TODO: fix */ });
    
    List<String> attrs = [
      "name"
    ];
    for(int i=0; i<World.types.keys.length; i++) {
      Editor.attachInputListeners("type_${i}", attrs, onInputChange);
      
      // when a row is clicked, set it as selected and highlight it
      Editor.attachButtonListener("#type_row_${i}", (Event e) {
        if(querySelector("#type_row_${i}") != null) {
          selectRow(i);
        }
      });
      
      List<String> advancedAttrs = [];
      for(int j=0; j<World.types.keys.length; j++) {
        advancedAttrs.add("effectiveness_${j}");
      }
      
      Editor.attachInputListeners("type_${i}", advancedAttrs, onInputChange);
    }
  }
  
  static void selectRow(int i) {
    selected = i;
    
    for(int j=0; j<World.types.keys.length; j++) {
      // un-highlight other rows
      querySelector("#type_row_${j}").classes.remove("selected");
      
      // hide the advanced containers for other rows
      querySelector("#type_${j}_effectiveness_container").classes.add("hidden");
    }
    
    if(querySelector("#type_row_${i}") == null) {
      return;
    }
    
    // hightlight the selected row
    querySelector("#type_row_${i}").classes.add("selected");
    
    // show the advanced area
    querySelector("#object_editor_types_advanced").classes.remove("hidden");
    
    // show the advanced tables for the selected row
    querySelector("#type_${i}_effectiveness_container").classes.remove("hidden");
  }
  
  static void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_name", World.types);
    
    World.types = new Map<String, GameType>();
    for(int i=0; querySelector('#type_${i}_name') != null; i++) {
      try {
        String name = Editor.getTextInputStringValue("#type_${i}_name");
        World.types[name] = new GameType(name);
      } catch(e) {
        // could not update this type
        print("Error updating type: " + e.toString());
      }
    }
    
    for(int i=0; i<World.types.keys.length; i++) {
      try {
        GameType attackingType = World.types.values.elementAt(i);
        
        // iterate through effectiveness
        for(int j=0; j<World.types.keys.length; j++) {
          attackingType.setEffectiveness(
            World.types.keys.elementAt(j),
            Editor.getTextInputDoubleValue("#type_${i}_effectiveness_${j}", 1.0)
          );
        }
      } catch(e) {
        // could not update this type
        print("Error updating type effectiveness: " + e.toString());
      }
    }
    
    Editor.updateAndRetainValue(e, () { /* TODO: fix */ });
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> typesJson = {};
    for(int i=0; i<World.types.keys.length; i++) {
      GameType gameType = World.types.values.elementAt(i);
      
      Map<String, Object> typeJson = {};
      typeJson["name"] = gameType.name;
      
      Map<String, double> typeEffectivenessJson = {};
      
      // iterate through effectiveness
      for(int j=0; j<World.types.length; j++) {
        typeEffectivenessJson[World.types.keys.elementAt(j)] = gameType.getEffectiveness(World.types.keys.elementAt(j));
      }
      
      typeJson["effectiveness"] = typeEffectivenessJson;
      
      typesJson[gameType.name] = typeJson;
    }
    
    exportJson["types"] = typesJson;
  }
}