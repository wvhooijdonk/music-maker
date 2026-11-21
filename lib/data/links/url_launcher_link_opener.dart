import 'package:url_launcher/url_launcher.dart';

import '../../domain/repositories/link_opener.dart';

class UrlLauncherLinkOpener implements LinkOpener {
  const UrlLauncherLinkOpener();

  static const _newBrowserTab = '_blank';

  @override
  Future<void> open(Uri link) async {
    await launchUrl(link, webOnlyWindowName: _newBrowserTab);
  }
}
