import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:dart_rpg/src/editor/editor.dart';
import 'package:dart_rpg/src/editor/map_editor/map_editor.dart';

import 'package:react/react.dart';

class GameStorage extends Component {
  static Timer fadeTimer;

  void update() {
    setState({});
  }

  render() {
    List<JsObject> options = [];
    window.localStorage.keys.forEach((String key) {
      if(key.startsWith("saved_game_")) {
        options.add(
          option({'value': key.substring("saved_game_".length)}, key.substring("saved_game_".length))
        );
      }
    });

    return
      div({},
        div({'id': 'game_storage_message'}),
        button({'id': 'new_game_button', 'onClick': newGame}, "New Game"),
        span({'className': 'vertical_divider'}),
        "Game Name: ",
        input({'id': 'save_local_game_name', 'type': 'text'}),
        button({'id': 'save_local_game_button', 'onClick': saveLocally}, "Save Game"),
        span({'className': 'vertical_divider'}),
        select({'id': 'load_local_game_name'}, options),
        button({'id': 'load_local_game_button', 'onClick': loadLocally}, "Load Game")
      );
  }

  void newGame(MouseEvent e) {
    bool confirm = window.confirm(
      "Are you sure you would like to start creating a new game? You will lose any unsaved progress on your current game."
    );

    if(confirm) {
      // replace the json in the export box
      (querySelector("#export_json") as TextAreaElement).value = "";
      
      // reload the editor
      Editor.loadGame(() {
        // make sure list of warps, signs, and events gets reset
        MapEditor.specialTilesLoaded = false;

        props['update']();
        querySelector("#game_storage_message").text = "New game started!";
        querySelector("#game_storage_message").style.opacity = "1.0";

        if(fadeTimer != null) {
          fadeTimer.cancel();
        }

        fadeTimer = new Timer(new Duration(seconds: 5), () => GameStorage.fadeMessage());
      });
    }
  }
  
  void saveLocally(MouseEvent e) {
    // get the game name
    TextInputElement gameNameInput = querySelector("#save_local_game_name");
    String gameName = gameNameInput.value.replaceAll(new RegExp(r'[^a-zA-Z0-9\._\ ,~!@#$%^&*()_+`\-=\[\]\\{}\|;:,./<>?]'), "_");
    
    // see if a game with this name already exists locally
    if(window.localStorage["saved_game_${gameName}"] != null) {
      bool confirm = window.confirm("There is already a map with this name saved locally. Would you like to overwrite it?");
      if(!confirm) {
        return;
      }
    }
    
    // save the game locally
    window.localStorage["saved_game_${gameName}"] = (querySelector("#export_json") as TextAreaElement).value;
    
    update();
    querySelector("#game_storage_message").text = "Game saved!";
    querySelector("#game_storage_message").style.opacity = "1.0";
    new Timer(new Duration(seconds: 5), () => fadeMessage());
  }
  
  void loadLocally(MouseEvent e) {
    // get the selected game name
    String gameName = Editor.getSelectInputStringValue("#load_local_game_name");
    
    // load saved game json
    String gameJson = window.localStorage["saved_game_${gameName}"];
    
    // replace the json in the export box
    (querySelector("#export_json") as TextAreaElement).value = gameJson;
    
    // reload the editor
    Editor.loadGame(() {
      props['update']();
      querySelector("#game_storage_message").text = "Game loaded!";
      querySelector("#game_storage_message").style.opacity = "1.0";

      if(fadeTimer != null) {
        fadeTimer.cancel();
      }

      fadeTimer = new Timer(new Duration(seconds: 5), () => GameStorage.fadeMessage());
    });
  }
  
  static void fadeMessage() {
    double opacity = double.parse(querySelector("#game_storage_message").style.opacity);
    
    opacity -= 0.01;
    
    if(opacity < 0.0) {
      opacity = 0.0;
    }
    
    querySelector("#game_storage_message").style.opacity = "${ opacity }";
    
    if(opacity > 0) {
      fadeTimer = new Timer(new Duration(milliseconds: 10), () => fadeMessage());
    }
  }
}