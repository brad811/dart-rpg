library dart_rpg.object_editor_items;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/object_editor/object_editor_game_events.dart';

import 'package:react/react.dart';

// TODO: when you can use items
// TODO: item targets
// TODO: max length of things

class ObjectEditorItems extends Component {
  List<Function> callbacks = [];
  bool shouldScrollIntoView = false;

  @override
  getInitialState() => {
    'selected': -1
  };

  @override
  componentDidMount() {
    initSpritePickers();
  }

  @override
  componentDidUpdate(Map prevProps, Map prevState) {
    initSpritePickers();
    callCallbacks();

    if(shouldScrollIntoView) {
      shouldScrollIntoView = false;
      querySelector('#item_row_${state['selected']}').scrollIntoView();
    }
  }

  void initSpritePickers() {
    for(int i=0; i<World.items.keys.length; i++) {
      Editor.initSpritePicker(
        "item_${i}_picture_id",
        World.items.values.elementAt(i).pictureId,
        3, 3,
        onInputChange
      );
    }
  }

  void callCallbacks() {
    if(callbacks != null) {
      for(Function callback in callbacks) {
        callback();
      }
    }
  }

  void update() {
    setState({});
  }

  @override
  render() {
    callbacks = [];
    
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
        tr({
          'id': 'item_row_${i}',
          'className': state['selected'] == i ? 'selected' : '',
          'onClick': (MouseEvent e) { setState({'selected': i}); },
          'onFocus': (MouseEvent e) { setState({'selected': i}); }
        },
          td({}, i),
          td({},
            Editor.generateSpritePickerHtml("item_${i}_picture_id", item.pictureId)
          ),
          td({},
            Editor.generateInput({
              'id': 'item_${i}_name',
              'type': 'text',
              'value': item.name,
              'onChange': onInputChange
            })
          ),
          td({},
            Editor.generateInput({
              'id': 'item_${i}_base_price',
              'type': 'text',
              'className': 'number',
              'value': item.basePrice,
              'onChange': onInputChange
            })
          ),
          td({},
            textarea({
              'id': 'item_${i}_description',
              'value': item.description,
              'onChange': onInputChange
            })
          ),
          td({},
            button({
              'id': 'delete_item_${i}',
              'onClick': Editor.generateConfirmDeleteFunction(World.items, item.name, "item", update)
            }, span({'className': 'fa fa-trash'}), " Delete")
          )
        )
      );
    }

    return
      div({'id': 'object_editor_items_container', 'className': 'object_editor_tab_container'},

        table({
          'id': 'object_editor_items_advanced',
          'className': 'object_editor_advanced_tab'}, tbody({},
          tr({},
            td({'className': 'tab_headers'},
              div({
                'id': 'item_game_event_tab_header',
                'className': 'tab_header selected'
              }, "Game Event")
            )
          ),
          tr({},
            td({'className': 'object_editor_tabs_container'},
              div({'className': 'tab'},
                div({'id': 'item_game_event_container'}, getGameEventTab())
              )
            )
          )
        )),

        div({'id': 'object_editor_items_tab', 'className': 'tab object_editor_tab'},
          div({'className': 'object_editor_inner_tab'}, [
            button({'id': 'add_item_button', 'onClick': addNewItem}, span({'className': 'fa fa-plus-circle'}), " Add new item"),
            hr({}),
            div({'id': 'battler_types_container'}, [
              table({'className': 'editor_table'}, tbody({}, tableRows))
            ])
          ])
        )

      );
  }

  JsObject getGameEventTab() {
    if(state['selected'] == -1 || World.items.values.length == 0 || state['selected'] >= World.items.values.length) {
      return div({});
    }

    List<JsObject> gameEventContainers = [];

    Item item = World.items.values.elementAt(state['selected']);

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
          ObjectEditorGameEvents.buildReadOnlyGameEventTableRowHtml(
            World.gameEventChains[item.gameEventChain][j],
            "item_${state['selected']}_game_event_${j}",
            j,
            callbacks
          )
        );
      }
    }

    gameEventContainers.add(
      div({'id': 'item_${state['selected']}_game_event_chain_container'}, [
        "Game Event Chain: ",
        select({
          'id': 'item_${state['selected']}_game_event_chain',
          'value': item.gameEventChain,
          'onChange': onInputChange
        }, options),
        hr({}),
        table({'id': 'item_${state['selected']}_game_event_table'}, tbody({}, tableRows))
      ])
    );

    return div({}, gameEventContainers);
  }
  
  void addNewItem(MouseEvent e) {
    String name = Editor.getUniqueName("New Item", World.items);
    World.items[name] = new Item(0, name, 100, "Description", World.gameEventChains.keys.first);

    shouldScrollIntoView = true;
    this.setState({
      'selected': World.items.keys.length - 1
    });
  }
  
  void onInputChange(Event e) {
    Editor.enforceValueFormat(e);
    Editor.avoidNameCollision(e, "_name", World.items);
    
    Map<String, Item> newItems = {};

    String oldName = World.items.keys.elementAt(state['selected']);
    String name = Editor.getTextInputStringValue('#item_${state['selected']}_name');

    World.items.forEach((String key, Item item) {
      if(key != oldName) {
        newItems[key] = World.items[key];
      } else {
        try {
          newItems[name] = new Item(
            Editor.getTextInputIntValue('#item_${state['selected']}_picture_id', 1),
            name,
            Editor.getTextInputIntValue('#item_${state['selected']}_base_price', 1),
            Editor.getTextAreaStringValue("#item_${state['selected']}_description"),
            Editor.getSelectInputStringValue("#item_${state['selected']}_game_event_chain")
          );
        } catch(e) {
          // could not update this item
          print("Error updating item: " + e.toString());
        }
      }
    });

    World.items = newItems;
    
    update();

    Editor.debounceExport();
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