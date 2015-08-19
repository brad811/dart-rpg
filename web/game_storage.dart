import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/editor/editor.dart';

class GameStorage {
  static void init() {
    GameStorage.update();
  }
  
  static void update() {
    String html = "";
    
    html += "<div id='game_storage_message'></div>&nbsp;&nbsp;";
    
    html += "<select id='load_local_game_name'>";
    window.localStorage.keys.forEach((String key) {
      html += "<option>${key}</option>";
    });
    html += "</select>&nbsp;";
    
    html += "<button id='load_local_game_button'>Load Game</button>";
    html += "&nbsp;&nbsp;&nbsp;&nbsp;";
    html += "<input id='save_local_game_name' type='text' />&nbsp;";
    html += "<button id='save_local_game_button'>Save Game</button>";
    
    querySelector("#game_storage_container").setInnerHtml(html);
    
    querySelector("#save_local_game_button").onClick.listen((MouseEvent e) {
      saveLocally();
    });
    
    querySelector("#load_local_game_button").onClick.listen((MouseEvent e) {
      loadLocally(e);
    });
  }
  
  static void saveLocally() {
    // get the game name
    TextInputElement gameNameInput = querySelector("#save_local_game_name");
    String gameName = gameNameInput.value.replaceAll(new RegExp(r'[^a-zA-Z0-9\._\ ,~!@#$%^&*()_+`\-=\[\]\\{}\|;:,./<>?]'), "_");
    
    // see if a game with this name already exists locally
    if(window.localStorage[gameName] != null) {
      bool confirm = window.confirm("There is already a map with this name saved locally. Would you like to overwrite it?");
      if(!confirm) {
        return;
      }
    }
    
    // save the game locally
    window.localStorage[gameName] = (querySelector("#export_json") as TextAreaElement).value;
    
    GameStorage.update();
    querySelector("#game_storage_message").text = "Game saved!";
    querySelector("#game_storage_message").style.opacity = "1.0";
    new Timer(new Duration(seconds: 5), () => fadeMessage());
  }
  
  static void loadLocally(MouseEvent e) {
    // get the selected game name
    String gameName = Editor.getSelectInputStringValue("#load_local_game_name");
    
    // load saved game json
    String gameJson = window.localStorage[gameName];
    
    // replace the json in the export box
    (querySelector("#export_json") as TextAreaElement).value = gameJson;
    
    // reload the editor
    Editor.loadGame(e);
    
    GameStorage.update();
    querySelector("#game_storage_message").text = "Game loaded!";
    querySelector("#game_storage_message").style.opacity = "1.0";
    new Timer(new Duration(seconds: 5), () => fadeMessage());
  }
  
  static void fadeMessage() {
    double opacity = double.parse(querySelector("#game_storage_message").style.opacity);
    
    opacity -= 0.01;
    
    if(opacity < 0.0) {
      opacity = 0.0;
    }
    
    querySelector("#game_storage_message").style.opacity = "${ opacity }";
    
    if(opacity > 0) {
      new Timer(new Duration(milliseconds: 10), () => fadeMessage());
    }
  }
}