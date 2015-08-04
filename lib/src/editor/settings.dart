library dart_rpg.settings;

import 'dart:html';

class Settings {
  static List<String> tabs = [];
  static Map<String, DivElement> tabDivs = {};
  static Map<String, DivElement> tabHeaderDivs = {};
  
  static void init() {
  }
  
  static void setUp() {
  }
  
  static void update() {
    buildMainHtml();
  }
  
  static void buildMainHtml() {
    String html = "";
    
    html += "Settings will go here.";
    
    querySelector("#settings_main_tab").setInnerHtml(html);
  }
  
  static void export(Map<String, Map<String, Map<String, Object>>> exportJson) {
  }
}