import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/battlefield.dart';
import '../models/game_map.dart';
import '../models/terrain.dart';

/// Small authoritative LAN room for the first Rush 1v1 mode.
/// The host owns the state; the guest sends commands and receives snapshots.
class LocalDuelRoom {
  LocalDuelRoom._(this.isHost, this.localSide);

  static const int port = 45454;
  static const int preparationSeconds = 60;
  static const int turnSeconds = 60;
  static const int armySize = 4;
  static final GameMap _rushMap = GameMap.rush();
  static const List<Map<String, dynamic>> roster = [
    {'id': 'guard', 'label': 'Garde', 'hp': 4, 'move': 1, 'range': 1, 'damage': 2},
    {'id': 'archer', 'label': 'Archer', 'hp': 2, 'move': 1, 'range': 2, 'damage': 1},
    {'id': 'rider', 'label': 'Cavalier', 'hp': 3, 'move': 2, 'range': 1, 'damage': 2},
    {'id': 'scout', 'label': 'Éclaireur', 'hp': 2, 'move': 2, 'range': 1, 'damage': 1},
  ];

  final bool isHost;
  final String localSide;
  final StreamController<Map<String, dynamic>> _updates = StreamController.broadcast();
  Stream<Map<String, dynamic>> get updates => _updates.stream;

  ServerSocket? _server;
  Socket? _client;
  Socket? _guest;
  Timer? _clock;
  bool _closed = false;
  String ipAddress = '';
  Map<String, dynamic> _state = {};
  Map<String, dynamic> get state => _copy(_state);

  static Map<String, dynamic> _copy(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

  static Future<LocalDuelRoom> createHost() async {
    final room = LocalDuelRoom._(true, 'host');
    room._state = {
      'phase': 'preparation',
      'connected': false,
      'ready': {'host': false, 'guest': false},
      'remaining': preparationSeconds,
      'turn': 'host',
      'turnNumber': 1,
      'winner': '',
      'fortHold': {'host': 0, 'guest': 0},
      'units': <Map<String, dynamic>>[],
      'message': 'En attente du deuxième joueur',
    };
    room._server = await ServerSocket.bind(InternetAddress.anyIPv4, port, shared: false);
    room.ipAddress = await room._findLocalIp();
    room._server!.listen(room._acceptGuest);
    room._emit();
    return room;
  }

  static Future<LocalDuelRoom> join(String address) async {
    final room = LocalDuelRoom._(false, 'guest');
    final socket = await Socket.connect(address.trim(), port, timeout: const Duration(seconds: 8));
    room._client = socket;
    socket.setOption(SocketOption.tcpNoDelay, true);
    socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        try {
          final decoded = jsonDecode(line);
          if (decoded is Map) {
            room._state = Map<String, dynamic>.from(decoded);
            room._emit();
          }
        } catch (_) {
          // Ignore an incomplete or malformed network frame.
        }
      },
      onDone: () {
        room._state = {...room._state, 'connected': false, 'message': 'Connexion interrompue'};
        room._emit();
      },
      onError: (_) {
        room._state = {...room._state, 'connected': false, 'message': 'Connexion interrompue'};
        room._emit();
      },
      cancelOnError: false,
    );
    return room;
  }

  Future<String> _findLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      final addresses = <String>[];
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final value = address.address;
          if (!value.startsWith('169.254.') && value != '0.0.0.0') addresses.add(value);
        }
      }
      addresses.sort((a, b) {
        int score(String s) => s.startsWith('192.168.') ? 0 : (s.startsWith('10.') ? 1 : 2);
        return score(a).compareTo(score(b));
      });
      return addresses.isEmpty ? 'Adresse IP indisponible' : addresses.first;
    } catch (_) {
      return 'Adresse IP indisponible';
    }
  }

  void _acceptGuest(Socket socket) {
    if (_guest != null || _closed) {
      socket.destroy();
      return;
    }
    _guest = socket;
    socket.setOption(SocketOption.tcpNoDelay, true);
    _state['connected'] = true;
    _state['message'] = 'Adversaire connecté';
    _startClock();
    _broadcast();
    socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        try {
          final frame = jsonDecode(line);
          if (frame is Map && frame['action'] is String && frame['data'] is Map) {
            _apply('guest', frame['action'] as String, Map<String, dynamic>.from(frame['data'] as Map));
          }
        } catch (_) {
          // Ignore invalid client commands; the host remains authoritative.
        }
      },
      onDone: () {
        _guest = null;
        _state['connected'] = false;
        _state['message'] = 'Adversaire déconnecté';
        _broadcast();
      },
      onError: (_) {
        _guest = null;
        _state['connected'] = false;
        _state['message'] = 'Connexion interrompue';
        _broadcast();
      },
      cancelOnError: false,
    );
  }

  void sendAction(String action, [Map<String, dynamic> data = const {}]) {
    if (_closed) return;
    if (isHost) {
      _apply('host', action, data);
    } else {
      _client?.write('${jsonEncode({'action': action, 'data': data})}\n');
    }
  }

  void _apply(String side, String action, Map<String, dynamic> data) {
    if (_state['winner'] != '') return;
    final phase = _state['phase'];
    if (action == 'place' && phase == 'preparation') {
      final id = data['id']?.toString() ?? '';
      final x = data['x'] is int ? data['x'] as int : -1;
      final y = data['y'] is int ? data['y'] as int : -1;
      final def = _firstOrNull(roster.where((u) => u['id'] == id));
      final units = List<Map<String, dynamic>>.from((_state['units'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      final already = units.any((u) => u['side'] == side && u['type'] == id);
      final inZone = side == 'host' ? x <= 5 : x >= 13;
      if (def != null && !already && x >= 0 && x < 19 && y >= 0 && y < 14 && inZone &&
          _passable(x, y) && !units.any((u) => u['x'] == x && u['y'] == y)) {
        units.add({'id': '${side}_$id', 'type': id, 'side': side, 'x': x, 'y': y,
          'hp': def['hp'], 'acted': false});
        _state['units'] = units;
        _state['message'] = '$side a placé ${def['label']}';
      }
    } else if (action == 'ready' && phase == 'preparation') {
      final units = _state['units'] as List;
      if (units.where((u) => (u as Map)['side'] == side).length == armySize) {
        final ready = Map<String, dynamic>.from(_state['ready'] as Map)..[side] = true;
        _state['ready'] = ready;
        _state['message'] = side == 'host' ? 'Joueur 1 prêt' : 'Joueur 2 prêt';
        if (ready['host'] == true && ready['guest'] == true) _beginBattle();
      }
    } else if (action == 'move' && phase == 'battle' && _state['turn'] == side) {
      final units = _mutableUnits();
      final unit = _firstOrNull(units.where((u) => u['id'] == data['id'] && u['side'] == side));
      final x = data['x'] is int ? data['x'] as int : -1;
      final y = data['y'] is int ? data['y'] as int : -1;
      final maxMove = unit == null ? 0 : _definition(unit['type'])['move'] as int;
      if (unit != null && unit['acted'] != true && x >= 0 && x < 19 && y >= 0 && y < 14 &&
          _passable(x, y) && !units.any((u) => u['x'] == x && u['y'] == y) &&
          ((unit['x'] as int) - x).abs() + ((unit['y'] as int) - y).abs() <= maxMove) {
        unit['x'] = x;
        unit['y'] = y;
        unit['acted'] = true;
        _state['units'] = units;
        _state['message'] = 'Déplacement effectué';
      }
    } else if (action == 'attack' && phase == 'battle' && _state['turn'] == side) {
      final units = _mutableUnits();
      final attacker = _firstOrNull(units.where((u) => u['id'] == data['id'] && u['side'] == side));
      final target = _firstOrNull(units.where((u) => u['id'] == data['target'] && u['side'] != side));
      if (attacker != null && target != null && attacker['acted'] != true) {
        final distance = ((attacker['x'] as int) - (target['x'] as int)).abs() +
            ((attacker['y'] as int) - (target['y'] as int)).abs();
        final def = _definition(attacker['type']);
        if (distance <= (def['range'] as int)) {
          target['hp'] = (target['hp'] as int) - (def['damage'] as int);
          attacker['acted'] = true;
          if ((target['hp'] as int) <= 0) units.remove(target);
          _state['units'] = units;
          _state['message'] = 'Attaque !';
          final remaining = units.where((u) => u['side'] != side).length;
          if (remaining == 0) _finish(side, 'Armée adverse éliminée');
        }
      }
    } else if (action == 'endTurn' && phase == 'battle' && _state['turn'] == side) {
      _advanceTurn(side);
    }
    _broadcast();
  }

  List<Map<String, dynamic>> _mutableUnits() =>
      List<Map<String, dynamic>>.from((_state['units'] as List).map((e) => Map<String, dynamic>.from(e as Map)));

  Map<String, dynamic> _definition(dynamic id) =>
      roster.firstWhere((u) => u['id'] == id, orElse: () => roster.first);

  bool _passable(int x, int y) {
    final t = _rushMap.terrainAt(Pos(x, y));
    return t != Terrain.mountain && t != Terrain.river && t != Terrain.sea && t != Terrain.cliff;
  }

  void _autoPlace(String side) {
    final units = _mutableUnits();
    final used = units.where((u) => u['side'] == side).map((u) => '${u['x']},${u['y']}').toSet();
    for (final def in roster) {
      if (units.any((u) => u['side'] == side && u['type'] == def['id'])) continue;
      var placed = false;
      for (var y = 4; y <= 9 && !placed; y++) {
        for (var step = 0; step < 6 && !placed; step++) {
          final x = side == 'host' ? step : 18 - step;
          final key = '$x,$y';
          if (_passable(x, y) && !used.contains(key)) {
            units.add({'id': '${side}_${def['id']}', 'type': def['id'], 'side': side,
              'x': x, 'y': y, 'hp': def['hp'], 'acted': false});
            used.add(key);
            placed = true;
          }
        }
      }
    }
    _state['units'] = units;
  }

  void _beginBattle() {
    _state['phase'] = 'battle';
    _state['turn'] = 'host';
    _state['remaining'] = turnSeconds;
    _state['message'] = 'La bataille commence !';
  }

  void _advanceTurn(String endingSide) {
    final fortOwners = (_state['units'] as List).where((u) => (u as Map)['x'] == 9 && u['y'] == 6)
        .map((u) => (u as Map)['side'] as String);
    final fortOwner = _firstOrNull(fortOwners);
    final holds = Map<String, dynamic>.from(_state['fortHold'] as Map);
    holds[endingSide] = fortOwner == endingSide ? (holds[endingSide] as int) + 1 : 0;
    if (fortOwner == endingSide) {
      holds[endingSide == 'host' ? 'guest' : 'host'] = 0;
    } else if (fortOwner == null) {
      holds['host'] = 0;
      holds['guest'] = 0;
    }
    _state['fortHold'] = holds;
    if ((holds[endingSide] as int) >= 2) {
      _finish(endingSide, 'Le fort central a été tenu pendant deux tours');
      return;
    }
    final next = endingSide == 'host' ? 'guest' : 'host';
    _state['turn'] = next;
    _state['turnNumber'] = (_state['turnNumber'] as int) + (next == 'host' ? 1 : 0);
    _state['remaining'] = turnSeconds;
    final units = _mutableUnits();
    for (final u in units.where((u) => u['side'] == next)) {
      u['acted'] = false;
    }
    _state['units'] = units;
    _state['message'] = next == 'host' ? 'Au joueur 1 de jouer' : 'Au joueur 2 de jouer';
  }

  void _finish(String winner, String reason) {
    _state['winner'] = winner;
    _state['phase'] = 'finished';
    _state['message'] = reason;
    _clock?.cancel();
  }

  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_closed || _state['winner'] != '' || _state['connected'] != true) return;
      final left = (_state['remaining'] as int) - 1;
      _state['remaining'] = left < 0 ? 0 : left;
      if (left <= 0) {
        if (_state['phase'] == 'preparation') {
          _autoPlace('host');
          if (_state['connected'] == true) _autoPlace('guest');
          if (_state['connected'] == true) {
            _beginBattle();
          } else {
            _state['remaining'] = preparationSeconds;
          }
        } else if (_state['phase'] == 'battle') {
          _advanceTurn(_state['turn'] as String);
        }
      }
      _broadcast();
    });
  }

  void _broadcast() {
    _emit();
    if (isHost && _guest != null) {
      try {
        _guest!.write('${jsonEncode(_state)}\n');
      } catch (_) {
        // Socket closure is reflected by its onDone callback.
      }
    }
  }

  void _emit() {
    if (!_updates.isClosed) _updates.add(_copy(_state));
  }

  Future<void> close() async {
    _closed = true;
    _clock?.cancel();
    await _guest?.close();
    await _client?.close();
    await _server?.close();
    await _updates.close();
  }
}

T? _firstOrNull<T>(Iterable<T> values) => values.isEmpty ? null : values.first;
