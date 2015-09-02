library dart_rpg.game_type;

class GameType {
  String name;
  Map<String, double> _effectiveness = new Map<String, double>();
  
  GameType(this.name);
  
  void setEffectiveness(String gameTypeName, double effectiveness) {
    _effectiveness[gameTypeName] = effectiveness;
  }
  
  double getEffectiveness(String gameTypeName) {
    if(_effectiveness[gameTypeName] != null) {
      return _effectiveness[gameTypeName];
    } else {
      return 1.0;
    }
  }
}