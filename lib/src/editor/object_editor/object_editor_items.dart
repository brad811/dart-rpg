library dart_rpg.object_editor_items;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor_game_events.dart';

import 'package:react/react.dart';

// TODO: when you can use items
// TODO: item targets
// TODO: max length of things

class ObjectEditorItemsComponent extends Component {
  void onInputChange() {
    // TODO: implement!
    print("ObjectEditorItemComponent.onInputChange not yet implemented!");
  }

  componentDidMount(a) {
    initSpritePickers();
  }

  componentDidUpdate(a, b, c) {
    initSpritePickers();
  }

  initSpritePickers() {
    for(int i=0; i<World.items.keys.length; i++) {
      Editor.initSpritePicker(
        "item_${i}_picture_id",
        World.items.values.elementAt(i).pictureId,
        3, 3,
        onInputChange
      );
    }
  }

  render() {
    List<JsObject> tableRows = [
      tr({}, [
        td({}, "Num"),
        td({}, "Picture Id"),
        td({}, "Name"),
        td({}, "Base Price"),
        td({}, "Description")
      ])
    ];

    for(int i=0; i<World.items.keys.length; i++) {
      Item item = World.items.values.elementAt(i);

      tableRows.add(
        tr({'id': 'item_row_${i}'}, [
          td({}, i),
          td({},
            Editor.generateSpritePickerHtml("item_${i}_picture_id", item.pictureId)
          ),
          td({},
            input({'id': 'item_${i}_name', 'type': 'text', 'value': item.name})
          ),
          td({},
            input({'id': 'item_${i}_base_price', 'type': 'text', 'className': 'number', 'value': item.basePrice})
          ),
          td({},
            textarea({'id': 'item_${i}_description', 'value': item.description})
          ),
          td({},
            button({'id': 'delete_item_${i}'}, "Delete")
          ),
        ])
      );
    }

    return table({'className': 'editor_table'}, tableRows);
  }
}

var objectEditorItemsComponent = registerComponent(() => new ObjectEditorItemsComponent());

class ObjectEditorItemGameEventComponent extends Component {
  int selected = -1;
  List<Function> callbacks = [];

  componentDidMount(a) {
    callCallbacks();
  }

  componentDidUpdate(a, b, c) {
    callCallbacks();
  }

  void callCallbacks() {
    if(callbacks != null) {
      for(Function callback in callbacks) {
        callback();
      }
    }
  }

  render() {
    List<JsObject> gameEventContainers = [];

    for(int i=0; i<World.items.keys.length; i++) {
      Item item = World.items.values.elementAt(i);

      List<JsObject> options = [
        option({'value': ''}, "None")
      ];

      for(int j=0; j<World.gameEventChains.keys.length; j++) {
        String name = World.gameEventChains.keys.elementAt(j);

        options.add(
          option({'value': name}, name)
        );
      }

      List<JsObject> tableRows = [];

      if(item.gameEventChain != null && item.gameEventChain != ""
          && World.gameEventChains[item.gameEventChain] != null) {
        for(int j=0; j<World.gameEventChains[item.gameEventChain].length; j++) {
          tableRows.add(
            ObjectEditorGameEvents.buildGameEventTableRowHtml(
              World.gameEventChains[item.gameEventChain][j],
              "item_${i}_game_event_${j}",
              j,
              readOnly: true, callbacks: callbacks
            )
          );
        }
      }

      gameEventContainers.add(
        div({'id': 'item_${i}_game_event_chain_container', 'className': selected == i ? '' : 'hidden'}, [
          "Game Event Chain: ",
          select({'id': 'item_${i}_game_event_chain', 'value': item.gameEventChain}, options),
          hr({}),
          table({'id': 'item_${i}_game_event_table'}, tbody({}, tableRows))
        ])
      );
    }

    return div({}, gameEventContainers);
  }
}

var objectEditorItemGameEventComponent = registerComponent(() => new ObjectEditorItemGameEventComponent());

class ObjectEditorItems {
  static List<String> advancedTabs = ["item_game_event"];
  
  static int selected;
  
  static void setUp() {
    Editor.setUpTabs(advancedTabs);
    Editor.attachButtonListener("#add_item_button", addNewItem);
    
    querySelector("#object_editor_items_tab_header").onClick.listen((MouseEvent e) {
      ObjectEditorItems.selectRow(0);
    });
  }
  
  static void addNewItem(MouseEvent e) {
    World.items["Item"] = new Item();
    update();
    ObjectEditor.update();
  }
  
  static void update() {
    render(objectEditorItemsComponent({}), querySelector('#items_container'));
    render(objectEditorItemGameEventComponent({}), querySelector('#item_game_event_container'));
    
    // highlight the selected row
    if(querySelector("#item_row_${selected}") != null) {
      querySelector("#item_row_${selected}").classes.add("selected");
      querySelector("#object_editor_items_advanced").classes.remove("hidden");
    }
    
    Editor.setMapDeleteButtonListeners(World.items, "item");
    
    List<String> attrs = [
      "picture_id", "name", "base_price", "description",
      
      // game event chain
      "game_event_chain"
    ];
    for(int i=0; i<World.items.keys.length; i++) {
      Editor.attachInputListeners("item_${i}", attrs, onInputChange);
      
      // when a row is clicked, set it as selected and highlight it
      Editor.attachButtonListener("#item_row_${i}", (Event e) {
        if(querySelector("#item_row_${i}") != null) {
          selectRow(i);
        }
      });
    }
  }
  
  static void selectRow(int i) {
    selected = i;
    
    for(int j=0; j<World.items.keys.length; j++) {
      // un-highlight other item rows
      querySelector("#item_row_${j}").classes.remove("selected");
      
      // hide the advanced containers for other rows
      querySelector("#item_${j}_game_event_chain_container").classes.add("hidden");
    }
    
    if(querySelector("#item_row_${i}") == null) {
      return;
    }
    
    // hightlight the selected row
    querySelector("#item_row_${i}").classes.add("selected");
    
    // show the advanced area
    querySelector("#object_editor_items_advanced").classes.remove("hidden");
    
    // show the advanced tables for the selected row
    querySelector("#item_${i}_game_event_chain_container").classes.remove("hidden");
  }
  
  static void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_name", World.items);
    
    World.items = new Map<String, Item>();
    for(int i=0; querySelector('#item_${i}_name') != null; i++) {
      try {
        String name = Editor.getTextInputStringValue("#item_${i}_name");
        World.items[name] = new Item(
          Editor.getTextInputIntValue('#item_${i}_picture_id', 1),
          name,
          Editor.getTextInputIntValue('#item_${i}_base_price', 1),
          Editor.getTextAreaStringValue("#item_${i}_description"),
          Editor.getSelectInputStringValue("#item_${i}_game_event_chain")
        );
      } catch(e) {
        // could not update this item
        print("Error updating item: " + e.toString());
      }
    }
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Map<String, String>> itemsJson = {};
    World.items.forEach((String key, Item item) {
      Map<String, String> itemJson = {};
      itemJson["pictureId"] = item.pictureId.toString();
      itemJson["basePrice"] = item.basePrice.toString();
      itemJson["description"] = item.description;
      itemJson["gameEventChain"] = item.gameEventChain;
      itemsJson[item.name] = itemJson;
    });
    
    exportJson["items"] = itemsJson;
  }
}