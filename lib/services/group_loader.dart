import '../models/group_info.dart';
import 'app_config_loader.dart';

/// Loads the shared idol-group info from `assets/data/group.json`.
class GroupLoader {
  const GroupLoader._();

  static const _configPath = 'assets/data/group.json';

  static Future<GroupInfo> load() async {
    final json = await AppConfigLoader.load(_configPath);
    return GroupInfo.fromJson(json);
  }
}
