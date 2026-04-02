import 'package:url_launcher/url_launcher.dart';

Future<void> launchCallAssistant({
  String? userLang,
  String? listenLang,
  String? caseType,
  String? context,
}) async {
  final params = <String, String>{};
  if (userLang != null) params['lang'] = userLang;
  if (listenLang != null) params['listen'] = listenLang;
  if (caseType != null) params['case'] = caseType;
  if (context != null) params['context'] = context;
  final uri = Uri.https('advocat.ee', '/call-assistant/setup.html', params.isEmpty ? null : params);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
