import 'package:envied/envied.dart';

part 'config.g.dart';

@Envied(path: ".env")
abstract class Config {
  @EnviedField(varName: 'appId', obfuscate: true)
  static String appId = _Config.appId;
  @EnviedField(varName: 'channelName')
  static String channelName = _Config.channelName;
  @EnviedField(varName: 'token', obfuscate: true)
  static String token = _Config.token;
}
