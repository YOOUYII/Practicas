import 'dart:async';
import 'dart:math';

class SensorSimulator {
  final _random = Random();

  int    _steps     = 0;
  int    _heartRate = 72;
  double _calories  = 0.0;
  String _status    = 'reposo';

  final _stepsCtrl     = StreamController<int>.broadcast();
  final _heartRateCtrl = StreamController<int>.broadcast();
  final _caloriesCtrl  = StreamController<int>.broadcast();
  final _statusCtrl    = StreamController<String>.broadcast();

  Stream<int>    get stepsStream     => _stepsCtrl.stream;
  Stream<int>    get heartRateStream => _heartRateCtrl.stream;
  Stream<int>    get caloriesStream  => _caloriesCtrl.stream;
  Stream<String> get statusStream    => _statusCtrl.stream;

  int    get steps     => _steps;
  int    get heartRate => _heartRate;
  int    get calories  => _calories.toInt();
  String get status    => _status;

  Timer? _timer;

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  // stop() SOLO cancela el timer, NO cierra streams
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  // dispose() cierra los streams al final de todo
  void dispose() {
    _timer?.cancel();
    _stepsCtrl.close();
    _heartRateCtrl.close();
    _caloriesCtrl.close();
    _statusCtrl.close();
  }

  void _update() {
    if (_random.nextInt(30) == 0) _changeActivity();

    switch (_status) {
      case 'caminando': _steps += _random.nextInt(2) + 1; break;
      case 'corriendo': _steps += _random.nextInt(4) + 3; break;
      default: break;
    }

    final target = _status == 'corriendo' ? 145
                : _status == 'caminando' ? 95 : 72;
    _heartRate += (_random.nextInt(7) - 3);
    _heartRate  = _heartRate.clamp(target - 10, target + 10);

    _calories += _steps * 0.00004;

    _stepsCtrl.add(_steps);
    _heartRateCtrl.add(_heartRate);
    _caloriesCtrl.add(_calories.toInt());
    _statusCtrl.add(_status);
  }

  void _changeActivity() {
    const activities = ['reposo', 'caminando', 'corriendo'];
    _status = activities[_random.nextInt(activities.length)];
  }
}