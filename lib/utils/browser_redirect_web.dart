import 'package:web/web.dart' as web;

Future<bool> redirectInSameTab(String url) async {
  web.window.location.assign(url);
  return true;
}
