library dart_rpg.gui_party_menu;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/game_event/choice_game_event.dart';
import 'package:dart_rpg/src/font.dart';
import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';

class GuiPartyMenu {
  static final double
    textX = 21.0,
    textY = 9.0;
  
  static final int
    characterDescriptionWindowWidth = 10;
  
  static Character selectedCharacter;
  static Function selectCallback;
  static bool backEnabled = true;
  static bool storeMode = false;
  static Character character;
  static Character storeCharacter;
  
  static Function playerMoneyWindow = () {
    Gui.renderWindow(0, 10, 10, 2);
    Font.renderStaticText(1.0, 21.75, "Money: " + Main.player.getCurCharacter().inventory.money.toString());
  };
  
  static GameEvent selectCharacter = new GameEvent((Function callback) {
    //selectCallback(selectedCharacter);
    selectCallback();
  });
  
  static GameEvent party = new GameEvent((Function callback) {
    GameEvent callbackEvent = new GameEvent((Function c){
      callback();
    });
    selectCallback = callback;
    
    Map<String, List<GameEvent>> characterChoices = new Map<String, List<GameEvent>>();
    for(Character character in Main.player.characters) {
      characterChoices.addAll({character.name: [selectCharacter]});
    }
    
    if(backEnabled) {
      characterChoices.addAll({"Back": [callbackEvent]});
    }
    
    ChoiceGameEvent characterChoice;
    Function descriptionWindow;
    
    GameEvent onCancel = new GameEvent((Function a) {
      Gui.removeWindow(descriptionWindow);
      callbackEvent.trigger(Main.player.getCurCharacter());
    });
    
    GameEvent onChange = new GameEvent((Function callback) {
      Gui.removeWindow(descriptionWindow);
      
      if(characterChoice.curChoice < Main.player.characters.length) {
        selectedCharacter = Main.player.characters.toList().elementAt(characterChoice.curChoice);
        Sprite curSprite = new Sprite.int(selectedCharacter.pictureId, 13, 1);
        descriptionWindow = () {
          Gui.renderWindow(10, 0, characterDescriptionWindowWidth, 10);
          
          // TODO: calculate max lines based on window height
          List<String> textLines = Gui.splitText("Wheeee stats or something", characterDescriptionWindowWidth);
          for(int i=0; i<textLines.length && i<8; i++) {
            Font.renderStaticText(textX, textY + Gui.verticalLineSpacing*i, textLines[i]);
          }
          
          curSprite.renderStaticSized(3, 3);
        };
        
        Gui.addWindow(descriptionWindow);
      }
    });
    
    characterChoice = new ChoiceGameEvent.custom(
        Main.player.getCurCharacter(),
        ChoiceGameEvent.generateChoiceMap("start_menu_party", characterChoices),
        0, 0,
        10, 10,
        cancelEvent: onCancel,
        onChangeEvent: onChange
    );
    
    onChange.trigger(Main.player.getCurCharacter());
    
    characterChoice.trigger(Main.player.getCurCharacter());
  });
  
  static trigger(Function callback, [bool backEnabled = true]) {
    GuiPartyMenu.character = character;
    GuiPartyMenu.backEnabled = backEnabled;
    
    Gui.addWindow(playerMoneyWindow);
    
    party.callback = callback;
    party.trigger(Main.player.getCurCharacter());
  }
}