import '../models/persona.dart';
import 'app_config_loader.dart';

/// Loads a character's [Persona] from `assets/data/personas/<id>.json`.
class PersonaLoader {
  const PersonaLoader._();

  static Future<Persona> load(String characterId) async {
    final json = await AppConfigLoader.load(
      'assets/data/personas/$characterId.json',
    );
    return Persona.fromJson(json);
  }
}
