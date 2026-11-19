import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

/// Patreon membership client. Secrets and OAuth token exchange stay on backend.
///
/// Deux chemins permettent de finaliser la connexion :
/// 1. le deep link `seerahtimeline://patreon/callback?code=…` (rapide, mais
///    parfois bloqué par le navigateur ou absent si le manifeste n'est pas configuré) ;
/// 2. le « polling » : quand l'utilisateur revient dans l'app, on demande au
///    serveur si l'autorisation a abouti, avec un secret connu de l'app seule.
/// Le premier qui aboutit gagne ; l'autre est ignoré.
class PatreonService extends ChangeNotifier with WidgetsBindingObserver {
  static const _apiBase = String.fromEnvironment('PATREON_API_BASE_URL');
  static const _tokenKey = 'patreon_app_session';
  static const _installKey = 'seerah_installation_id';
  static const _pendingKey = 'patreon_pending_oauth';
  static const _callbackScheme = 'seerahtimeline';
  static const _pendingLifetime = Duration(minutes: 30);
  static const _timeout = Duration(seconds: 20);

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

  /// Une connexion a été lancée dans le navigateur et attend la validation Patreon.
  bool get awaitingAuthorization => _pendingSecret != null;
  String? _pendingSecret;
  DateTime? _pendingSince;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  bool _pollInFlight = false;
  final Set<String> _handledCodes = {};

  bool get configured => _apiBase.isNotEmpty;

  Future<void> init() async {
    if (!configured) {
      error = 'Service Patreon non configuré : URL du serveur manquante.';
      notifyListeners();
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    installationId = await _secure.read(key: _installKey);
    if (installationId == null) {
      installationId = const Uuid().v4();
      await _secure.write(key: _installKey, value: installationId);
    }
    _sessionToken = await _secure.read(key: _tokenKey);
    await _restorePending();

    // app_links ≥ 6 renvoie aussi le lien initial dans le flux : la déduplication
    // par code dans _handleCallback évite un double échange (le 2e échouait en 400).
    _linkSub = _links.uriLinkStream.listen(_handleCallback, onError: (_) {});
    try {
      final initial = await _links.getInitialLink();
      if (initial != null) await _handleCallback(initial);
    } catch (_) {}

    if (_sessionToken != null) {
      await refreshStatus();
    } else {
      // No offline Premium cache: access is granted only after a fresh server check.
      premium = false;
      connected = false;
      entitlements.clear();
    }
    // Si Android a tué l'app pendant que l'utilisateur était sur Patreon.
    if (awaitingAuthorization) _startPolling();
  }

  // ---------------------------------------------------------------------------
  // Démarrage de la connexion
  // ---------------------------------------------------------------------------

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
      final secret = _randomSecret();
      final response = await http
          .post(
            Uri.parse('$_apiBase/v1/patreon/oauth/start'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'installation_id': installationId, 'poll_secret': secret}),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) throw Exception('Serveur (${response.statusCode})');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = Uri.parse(data['authorization_url'] as String);
      await _setPending(secret);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await _clearPending();
        throw Exception('Impossible d’ouvrir Patreon.');
      }
    } catch (e) {
      error = 'Connexion impossible : ${_clean(e)}';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// L'utilisateur abandonne la connexion en cours.
  Future<void> cancelPending() async {
    await _clearPending();
    notifyListeners();
  }

  /// Bouton « J'ai autorisé, vérifier » : une vérification immédiate.
  Future<void> checkPendingNow() async {
    if (!awaitingAuthorization) return refreshStatus();
    _pollAttempts = 0;
    await _pollOnce(manual: true);
    if (awaitingAuthorization) _startPolling();
  }

  // ---------------------------------------------------------------------------
  // Chemin 1 : deep link
  // ---------------------------------------------------------------------------

  Future<void> _handleCallback(Uri uri) async {
    if (uri.scheme != _callbackScheme || uri.host != 'patreon') return;
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      // Liens « status=done/pending » envoyés quand l'utilisateur a cliqué deux fois :
      // la session se récupère par polling.
      if (awaitingAuthorization) {
        _startPolling();
      } else if (_sessionToken != null) {
        await refreshStatus();
      }
      return;
    }
    if (!_handledCodes.add(code)) return; // déjà traité (lien initial + flux)
    busy = true;
    notifyListeners();
    try {
      final response = await http
          .post(
            Uri.parse('$_apiBase/v1/patreon/oauth/exchange'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code, 'installation_id': installationId}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveSession(data['session_token'] as String);
      } else if (awaitingAuthorization) {
        // Code expiré ou déjà utilisé : le polling prend le relais sans afficher d'erreur.
        await _pollOnce();
      } else if (_sessionToken == null) {
        throw Exception('Échange refusé (${response.statusCode})');
      }
    } catch (e) {
      error = 'Vérification Patreon impossible : ${_clean(e)}';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Chemin 2 : polling au retour dans l'app
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && awaitingAuthorization) {
      _pollAttempts = 0;
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    unawaited(_pollOnce());
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (t) {
      // ~2 minutes après chaque retour dans l'app, puis on attend le prochain retour
      // ou un appui sur « J'ai autorisé, vérifier ».
      if (!awaitingAuthorization || ++_pollAttempts > 40) {
        t.cancel();
        return;
      }
      unawaited(_pollOnce());
    });
  }

  Future<void> _pollOnce({bool manual = false}) async {
    final secret = _pendingSecret;
    if (secret == null || _pollInFlight || installationId == null) return;
    if (_pendingSince != null && DateTime.now().difference(_pendingSince!) > _pendingLifetime) {
      await _clearPending();
      error = 'La demande de connexion a expiré. Relance la connexion Patreon.';
      notifyListeners();
      return;
    }
    _pollInFlight = true;
    if (manual) {
      busy = true;
      notifyListeners();
    }
    try {
      final response = await http
          .post(
            Uri.parse('$_apiBase/v1/patreon/oauth/poll'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'installation_id': installationId, 'poll_secret': secret}),
          )
          .timeout(_timeout);
      if (response.statusCode == 404) {
        await _clearPending();
        error = 'Demande de connexion introuvable. Relance la connexion Patreon.';
        return;
      }
      if (response.statusCode != 200) throw Exception('Serveur (${response.statusCode})');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      switch (data['status']) {
        case 'done':
          await _saveSession(data['session_token'] as String);
        case 'already_delivered':
          // Le deep link a déjà livré la session.
          await _clearPending();
          if (_sessionToken != null) await refreshStatus();
        case 'failed':
          await _clearPending();
          error = 'Patreon n’a pas pu confirmer ton compte. Réessaie la connexion.';
        case 'expired':
          await _clearPending();
          error = 'La demande de connexion a expiré. Relance la connexion Patreon.';
        default: // pending
          if (manual) {
            error = 'Patreon n’a pas encore confirmé l’autorisation. Termine l’étape sur Patreon puis reviens ici.';
          }
      }
    } catch (e) {
      if (manual) error = 'Vérification impossible : ${_clean(e)}';
    } finally {
      _pollInFlight = false;
      if (manual) busy = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Statut
  // ---------------------------------------------------------------------------

  /// Vérification déclenchée par un bouton : indicateur de chargement + message de résultat.
  Future<String> checkSubscription() async {
    if (awaitingAuthorization) {
      await checkPendingNow();
      return premium ? 'Accès Premium activé ✓' : (error ?? 'En attente de la validation Patreon.');
    }
    if (_sessionToken == null) return 'Aucun compte Patreon connecté. Appuie sur « Connecter mon compte Patreon ».';
    busy = true;
    notifyListeners();
    try {
      await refreshStatus();
    } finally {
      busy = false;
      notifyListeners();
    }
    if (error != null) return error!;
    if (premium) return 'Accès Premium actif${tierName != null ? ' : $tierName' : ''} ✓';
    return 'Vérifié : aucun niveau Premium (Explorer ou Companion) actif sur ce compte Patreon.';
  }

  Future<void> refreshStatus() async {
    if (_sessionToken == null || !configured) return;
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/v1/premium/status'),
        headers: {'Authorization': 'Bearer $_sessionToken'},
      ).timeout(_timeout);
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
      error = 'Impossible de vérifier Patreon : ${_clean(e)}';
    }
    notifyListeners();
  }

  /// Ouvre patreon.com dans le navigateur (pour s'y déconnecter avant de changer de compte).
  Future<void> openPatreonWebsite() async {
    await launchUrl(Uri.parse('https://www.patreon.com/home'), mode: LaunchMode.externalApplication);
  }

  /// Délie le compte actuel puis relance la connexion. Patreon utilise le compte ouvert
  /// dans le navigateur : l'utilisateur doit s'y être déconnecté pour en choisir un autre.
  Future<void> switchAccount() async {
    await disconnect();
    await connect();
  }

  Future<void> disconnect() async {
    try {
      if (_sessionToken != null && configured) {
        await http.post(Uri.parse('$_apiBase/v1/patreon/disconnect'),
            headers: {'Authorization': 'Bearer $_sessionToken'}).timeout(_timeout);
      }
    } catch (_) {}
    await _secure.delete(key: _tokenKey);
    await _clearPending();
    _sessionToken = null;
    premium = false;
    connected = false;
    tierName = null;
    tierCode = null;
    entitlements.clear();
    validUntil = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Utilitaires
  // ---------------------------------------------------------------------------

  Future<void> _saveSession(String token) async {
    _sessionToken = token;
    await _secure.write(key: _tokenKey, value: token);
    await _clearPending();
    error = null;
    await refreshStatus();
  }

  Future<void> _setPending(String secret) async {
    _pendingSecret = secret;
    _pendingSince = DateTime.now();
    _pollAttempts = 0;
    await _secure.write(
      key: _pendingKey,
      value: jsonEncode({'secret': secret, 'since': _pendingSince!.toIso8601String()}),
    );
  }

  Future<void> _restorePending() async {
    try {
      final raw = await _secure.read(key: _pendingKey);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final since = DateTime.tryParse(data['since'] as String? ?? '');
      if (since == null || DateTime.now().difference(since) > _pendingLifetime) {
        await _secure.delete(key: _pendingKey);
        return;
      }
      _pendingSecret = data['secret'] as String?;
      _pendingSince = since;
    } catch (_) {
      await _secure.delete(key: _pendingKey);
    }
  }

  Future<void> _clearPending() async {
    _pollTimer?.cancel();
    _pendingSecret = null;
    _pendingSince = null;
    await _secure.delete(key: _pendingKey);
  }

  static String _randomSecret() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _clean(Object e) {
    if (e is TimeoutException) return 'le serveur ne répond pas (délai dépassé).';
    return e.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }
}
