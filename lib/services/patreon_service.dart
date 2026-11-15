import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

/// Patreon membership client. Secrets and OAuth token exchange stay on backend.
class PatreonService extends ChangeNotifier {
  static const _apiBase = String.fromEnvironment('PATREON_API_BASE_URL');
  static const _tokenKey = 'patreon_app_session';
  static const _installKey = 'seerah_installation_id';
  static const _callbackScheme = 'seerahtimeline';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  final AppLinks _links = AppLinks();
  StreamSubscription<Uri>? _linkSub;
  String? _sessionToken;
  String? installationId;
  bool premium = false;
  bool busy = false;
  bool connected = false;
  String? tierName;
  String? tierCode;
  Set<String> entitlements = {};
  DateTime? validUntil;
  String? error;

  bool get configured => _apiBase.isNotEmpty;

  Future<void> init() async {
    if (!configured) {
      error = 'Service Patreon non configuré : URL du serveur manquante.';
      notifyListeners();
      return;
    }
    installationId = await _secure.read(key: _installKey);
    if (installationId == null) {
      installationId = const Uuid().v4();
      await _secure.write(key: _installKey, value: installationId);
    }
    _sessionToken = await _secure.read(key: _tokenKey);
    _linkSub = _links.uriLinkStream.listen(_handleCallback, onError: (_) {});
    try {
      final initial = await _links.getInitialLink();
      if (initial != null) await _handleCallback(initial);
    } catch (_) {}
    if (_sessionToken != null) await refreshStatus();
    else {
      // No offline Premium cache: access is granted only after a fresh server check.
      premium = false;
      connected = false;
      entitlements.clear();
    }
  }

  Future<void> connect() async {
    if (!configured || installationId == null) {
      error = 'Connexion Patreon indisponible : configuration serveur manquante.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/v1/patreon/oauth/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'installation_id': installationId}),
      );
      if (response.statusCode != 200) throw Exception('Serveur (${response.statusCode})');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = Uri.parse(data['authorization_url'] as String);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Impossible d’ouvrir Patreon.');
      }
    } catch (e) {
      error = 'Connexion impossible : $e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _handleCallback(Uri uri) async {
    if (uri.scheme != _callbackScheme || uri.host != 'patreon') return;
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      error = 'La connexion Patreon n’a pas abouti.';
      notifyListeners();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/v1/patreon/oauth/exchange'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code, 'installation_id': installationId}),
      );
      if (response.statusCode != 200) throw Exception('Échange refusé (${response.statusCode})');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _sessionToken = data['session_token'] as String;
      await _secure.write(key: _tokenKey, value: _sessionToken);
      await refreshStatus();
    } catch (e) {
      error = 'Vérification Patreon impossible : $e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshStatus() async {
    if (_sessionToken == null || !configured) return;
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/v1/premium/status'),
        headers: {'Authorization': 'Bearer $_sessionToken'},
      );
      if (response.statusCode == 401) {
        await _secure.delete(key: _tokenKey);
        _sessionToken = null;
        premium = false;
        connected = false;
        entitlements.clear();
        notifyListeners();
        return;
      }
      if (response.statusCode != 200) throw Exception('Statut (${response.statusCode})');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      connected = data['patreon_connected'] == true;
      premium = data['premium'] == true;
      entitlements = ((data['entitlements'] as List?) ?? const []).whereType<String>().toSet();
      tierName = data['tier_name'] as String?;
      tierCode = data['tier_code'] as String?;
      final until = data['valid_until'] as String?;
      validUntil = until == null ? null : DateTime.tryParse(until)?.toLocal();
      error = null;
    } catch (e) {
      // Fail closed: if Patreon cannot be checked, do not keep stale Premium access.
      premium = false;
      entitlements.clear();
      error = 'Impossible de vérifier Patreon : $e';
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    try {
      if (_sessionToken != null && configured) {
        await http.post(Uri.parse('$_apiBase/v1/patreon/disconnect'),
            headers: {'Authorization': 'Bearer $_sessionToken'});
      }
    } catch (_) {}
    await _secure.delete(key: _tokenKey);
    _sessionToken = null;
    premium = false;
    connected = false;
    tierName = null;
    tierCode = null;
    entitlements.clear();
    validUntil = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }
}
