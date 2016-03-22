library dart_rpg.text_game_event;

import "dart:js";

import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class TextGameEvent implements GameEvent {
  static final String type = "text";
  Function function, callback;
  
  int pictureSpriteId;
  String text;
  ChoiceGameEvent choiceGameEvent;
  Interactable interactable;
  
  static List<String>
      originalTextLines = [],
      textLines = [];
  
  static final int
    conversationWindowWidth = 15,
    maxLines = 4;
  
  static final double
    textX = 9.0,
    textY = 23.5;
  
  TextGameEvent(this.pictureSpriteId, this.text, [this.callback]);
  
  factory TextGameEvent.choice(int pictureSpriteId, String text, ChoiceGameEvent choice) {
    TextGameEvent textGameEvent = new TextGameEvent(pictureSpriteId, text);
    textGameEvent.choiceGameEvent = choice;
    return textGameEvent;
  }
  
  @override
  void trigger(Interactable interactable, [Function function]) {
    this.interactable = interactable;
    textLines = Gui.splitText(text, conversationWindowWidth);
    
    // Take input focus and show the GUI window
    Gui.inConversation = true;
    Gui.textLines = textLines;
    Gui.pictureSpriteId = pictureSpriteId;
    Main.focusObject = this;
    
    if(textLines.length <= Gui.maxLines && choiceGameEvent != null) {
      choiceGameEvent.trigger(interactable);
    }
  }
  
  void continueText() {
    if(textLines.length > Gui.maxLines) {
      // Remove the top lines so the next lines will show
      textLines.removeRange(0, Gui.maxLines);
      
      if(textLines.length <= Gui.maxLines && choiceGameEvent != null) {
        choiceGameEvent.trigger(interactable);
      }
    } else {
      // Close the text box
      close();
    }
  }
  
  static void renderConversationWindow() {
    // Text window
    Gui.renderWindow(4, 11, conversationWindowWidth, 4);
    
    // Picture window
    Gui.renderWindow(1, 11, 3, 3);
    
    // Picture
    for(int row=0; row<3; row++) {
      for(int col=0; col<3; col++) {
        new Sprite.int(Gui.pictureSpriteId + Sprite.spriteSheetWidth*row + col, 1 + col, 11 + row).renderStatic();
      }
    }
    
    // Text
    for(int i=0; i<textLines.length && i<maxLines; i++) {
      Font.renderStaticText(textX, textY + Gui.verticalLineSpacing*i, textLines[i]);
    }
    
    if(textLines.length > maxLines) {
      // draw arrow indicating there is more text
      Font.renderStaticText(36.25, 28.5, new String.fromCharCode(127));
    }
  }
  
  @override
  void handleKeys(List<int> keyCodes) {
    if(keyCodes.contains(Input.CONFIRM) || keyCodes.contains(Input.BACK)) {
      continueText();
    }
  }
  
  void close() {
    // Set focus back on the player and hide the GUI window
    Gui.inConversation = false;
    Main.focusObject = Main.player;
    if(callback != null) {
      callback();
    }
  }
  
  // Editor functions
  
  @override
  String getType() => type;
  
  @override
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange, Function update) {
    if(callbacks != null) {
      callbacks.add(() {
        Editor.initSpritePicker("${prefix}_picture_id", pictureSpriteId, 3, 3, onInputChange, readOnly: readOnly);
      });
    }
    
    return table({}, tbody({},
      tr({},
        td({}, "Picture Id"),
        td({}, "Text")
      ),
      tr({},
        td({}, Editor.generateSpritePickerHtml("${prefix}_picture_id", pictureSpriteId, readOnly: readOnly)),
        td({}, textarea({'id': '${prefix}_text', 'readOnly': readOnly, 'value': text, 'onChange': onInputChange}))
      )
    ));
  }
  
  static GameEvent buildGameEvent(String prefix) {
    TextGameEvent textGameEvent = new TextGameEvent(
        Editor.getTextInputIntValue("#${prefix}_picture_id", 1),
        Editor.getTextAreaStringValue("#${prefix}_text")
      );
    
    return textGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["pictureId"] = pictureSpriteId;
    gameEventJson["text"] = text;
    
    return gameEventJson;
  }
}