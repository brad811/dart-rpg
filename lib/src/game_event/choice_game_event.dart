library dart_rpg.choice_game_event;

import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class ChoiceGameEvent implements GameEvent, InputHandler {
  static final String type = "choice";
  final String name = "Choice";
  Function function, callback;
  
  Interactable interactable;
  final Map<String, String> choiceGameEventChains;
  GameEvent cancelEvent;
  GameEvent onChangeEvent;
  Function window;
  bool
    remove = true,
    isCustom = false;
  
  int
    curChoice = 0,
    addWidth,
    posX = 16,
    posY = 9,
    sizeX = 3,
    sizeY = 2;
  
  ChoiceGameEvent(this.choiceGameEventChains, {this.cancelEvent, this.onChangeEvent}) : super() {
    int maxLength = 0;
    for(int i=0; i<choiceGameEventChains.keys.toList().length; i++) {
      if(choiceGameEventChains.keys.toList()[i].length > maxLength)
        maxLength = choiceGameEventChains.keys.toList()[i].length;
    }
    
    addWidth = ((maxLength - 3) / 2).round();
  }
  
  factory ChoiceGameEvent.custom(
      Interactable interactable,
      Map<String, String> choiceGameEventChains,
      int posX, int posY, int sizeX, int sizeY, {GameEvent cancelEvent, GameEvent onChangeEvent}) {
    ChoiceGameEvent choiceGameEvent = new ChoiceGameEvent(
        choiceGameEventChains,
        cancelEvent: cancelEvent,
        onChangeEvent: onChangeEvent
      );
    choiceGameEvent.addWidth = 0;
    choiceGameEvent.posX = posX;
    choiceGameEvent.posY = posY;
    choiceGameEvent.sizeX = sizeX;
    choiceGameEvent.sizeY = sizeY;
    
    choiceGameEvent.isCustom = true;
    
    return choiceGameEvent;
  }
  
  void trigger(Interactable interactable, [Function function]) {
    this.interactable = interactable;
    Main.focusObject = this;
    
    // reverse the list so they get rendered in order
    List<String> myChoices = choiceGameEventChains.keys.toList().reversed.toList();
    
    window = () {
      if(isCustom) {
        Gui.renderWindow(
          posX, posY,
          sizeX, sizeY
        );
        
        for(int i=myChoices.length-1; i>=0; i--) {
          Font.renderStaticText(
            posX*2 + 2 - addWidth*1.45,
            posY*2 - (i-myChoices.length-0.25)*1.75,
            myChoices[i]
          );
        }
        
        Font.renderStaticText(
          posX*2 + 0.75 - addWidth*1.45,
          posY*2 + 1.75 + (curChoice+0.25)*1.75,
          new String.fromCharCode(128)
        );
      } else {
        Gui.renderWindow(
          posX - (addWidth*0.75).round(), posY + 1 - myChoices.length + (0.15 * myChoices.length).floor(),
          sizeX + (addWidth*0.75).round(), myChoices.length + 1 - (0.15 * myChoices.length).floor()
        );
        
        for(int i=myChoices.length-1; i>=0; i--) {
          Font.renderStaticText(posX*2 + 2 - addWidth*1.45, posY*2 - (i-1)*1.75, myChoices[i]);
        }
        
        Font.renderStaticText(
          posX*2 + 0.75 - addWidth*1.45,
          posY*2 + 1.75 - (myChoices.length - curChoice - 1)*1.75,
          new String.fromCharCode(128)
        );
      }
    };
    
    Gui.addWindow(window);
  }
  
  @override
  void handleKeys(List<int> keyCodes) {
    if(keyCodes.contains(Input.UP)) {
      curChoice--;
      if(curChoice < 0) {
        curChoice = choiceGameEventChains.keys.toList().length - 1;
      }
      
      if(onChangeEvent != null)
        onChangeEvent.trigger(interactable);
    } else if(keyCodes.contains(Input.DOWN)) {
      curChoice++;
      if(curChoice > choiceGameEventChains.keys.toList().length - 1) {
        curChoice = 0;
      }
      
      if(onChangeEvent != null)
        onChangeEvent.trigger(interactable);
    } else if(keyCodes.contains(Input.CONFIRM)) {
      if(remove)
        Gui.removeWindow(window);
      
      List<GameEvent> choice = World.gameEventChains[choiceGameEventChains.values.toList()[curChoice]];
      
      Interactable.chainGameEvents(interactable, choice).trigger(interactable);
    } else if(keyCodes.contains(Input.BACK) && cancelEvent != null) {
      Gui.removeWindow(window);
      
      Interactable.chainGameEvents(interactable, [cancelEvent]).trigger(interactable);
    }
  }
  
  static Map<String, String> generateChoiceMap(String prefix, Map<String, List<GameEvent>> gameEventChainMap) {
    int i = 0;
    
    Map<String, String> generatedChoiceMap = new Map<String, String>();
    
    gameEventChainMap.forEach((String choiceName, List<GameEvent> chain) {
      String chainName = "____${prefix}_choice_${i}";
      
      World.gameEventChains[chainName] = chain;
      
      generatedChoiceMap[choiceName] = chainName;
      
      i += 1;
    });
    
    return generatedChoiceMap;
  }
  
  // Editor functions
  
  @override
  String getType() => type;
  
  @override
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange, Function update) {
    List<JsObject> tableRows = [];

    tableRows.add(
      tr({},
        td({}, "Choice Name"),
        td({}, "Game Event Chain"),
        td({})
      )
    );
    
    int i = 0;
    choiceGameEventChains.forEach((String choiceName, String chainName) {
      List<JsObject> options = [];
      World.gameEventChains.keys.forEach((String key) {
        options.add(
          option({'value': key}, key)
        );
      });

      tableRows.add(
        tr({},
          td({},
            Editor.generateInput({
              'type': 'text',
              'id': '${prefix}_choice_name_${i}',
              'value': choiceName,
              'readOnly': readOnly,
              'onChange': onInputChange
            })
          ),
          td({},
            select({
              'id': '${prefix}_chain_name_${i}',
              'disabled': readOnly,
              'value': chainName,
              'onChange': onInputChange
            }, options)
          ),
          td({},
            button({
              'id': 'delete_${prefix}_choice_${i}',
              'onClick': Editor.generateConfirmDeleteFunction(choiceGameEventChains, choiceName, "option", update)
            }, "Delete")
          )
        )
      );
      
      i += 1;
    });

    return div({},
      table({}, tbody({}, tableRows)),
      br({}),
      button({
        'id': '${prefix}_add_choice',
        'onClick': (MouseEvent e) { addChoice(update); }
      }, "Add choice")
    );
  }

  void addChoice(Function update) {
    if(choiceGameEventChains["New choice"] == null) {
      choiceGameEventChains["New choice"] = World.gameEventChains.keys.first;
      update();
    }
  }
  
  static GameEvent buildGameEvent(String prefix) {
    Map<String, String> choices = new Map<String, String>();
    for(int i=0; querySelector("#${prefix}_choice_name_${i}") != null; i++) {
      String choiceName = Editor.getTextInputStringValue("#${prefix}_choice_name_${i}");
      String chainName = Editor.getSelectInputStringValue("#${prefix}_chain_name_${i}");
      
      choices[choiceName] = chainName;
    }
    
    ChoiceGameEvent choiceGameEvent = new ChoiceGameEvent(choices);
    
    return choiceGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["choices"] = choiceGameEventChains;
    gameEventJson["cancelEvent"] = cancelEvent;
    
    return gameEventJson;
  }
}