import 'dart:async';
import 'dart:math';

/// Scale reading with weight in grams and stability flag
class ScaleReading {
  final int weightGrams;
  final bool isStable;
  final DateTime timestamp;

  const ScaleReading({
    required this.weightGrams,
    required this.isStable,
    required this.timestamp,
  });

  ScaleReading copyWith({int? weightGrams, bool? isStable}) => ScaleReading(
    weightGrams: weightGrams ?? this.weightGrams,
    isStable: isStable ?? this.isStable,
    timestamp: DateTime.now(),
  );

  static final zero = ScaleReading(weightGrams: 0, isStable: true, timestamp: DateTime.fromMillisecondsSinceEpoch(0));
}

/// Scale connection status
enum ScaleStatus { disconnected, connecting, connected, error }

/// Scale protocol types
enum ScaleProtocol { simulated, cas, mettlerToledo }

/// Service for reading weight from scales.
/// Supports simulated mode for development and CAS protocol for production.
class ScaleService {
  ScaleProtocol _protocol = ScaleProtocol.simulated;
  ScaleStatus _status = ScaleStatus.disconnected;
  Timer? _pollTimer;
  Timer? _simulationTimer;

  final _readingController = StreamController<ScaleReading>.broadcast();
  final _statusController = StreamController<ScaleStatus>.broadcast();

  // Simulation state
  int _simulatedWeight = 0;
  int _targetWeight = 0;
  bool _simulatedStable = true;

  /// Stream of weight readings
  Stream<ScaleReading> get readings => _readingController.stream;

  /// Stream of connection status changes
  Stream<ScaleStatus> get statusStream => _statusController.stream;

  /// Current connection status
  ScaleStatus get status => _status;

  /// Current protocol
  ScaleProtocol get protocol => _protocol;

  /// Connect to scale with given protocol
  Future<void> connect({ScaleProtocol protocol = ScaleProtocol.simulated}) async {
    _protocol = protocol;
    _setStatus(ScaleStatus.connecting);

    switch (protocol) {
      case ScaleProtocol.simulated:
        await _connectSimulated();
      case ScaleProtocol.cas:
      case ScaleProtocol.mettlerToledo:
        // Real hardware would use platform channels here
        _setStatus(ScaleStatus.error);
    }
  }

  /// Disconnect from scale
  void disconnect() {
    _pollTimer?.cancel();
    _simulationTimer?.cancel();
    _pollTimer = null;
    _simulationTimer = null;
    _setStatus(ScaleStatus.disconnected);
  }

  /// Simulate placing an item on the scale (dev/testing only)
  void simulatePlace(int weightGrams) {
    if (_protocol != ScaleProtocol.simulated) return;
    _targetWeight = weightGrams;
    _simulatedStable = false;
  }

  /// Simulate removing item from scale
  void simulateRemove() {
    if (_protocol != ScaleProtocol.simulated) return;
    _targetWeight = 0;
    _simulatedStable = false;
  }

  /// Tare (zero) the scale
  void tare() {
    _simulatedWeight = 0;
    _targetWeight = 0;
    _simulatedStable = true;
    _emitReading(0, true);
  }

  void dispose() {
    disconnect();
    _readingController.close();
    _statusController.close();
  }

  // --- Simulated scale ---

  Future<void> _connectSimulated() async {
    // Simulate brief connection delay
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _setStatus(ScaleStatus.connected);

    // Poll at 10Hz (typical scale update rate)
    _pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateSimulatedWeight();
    });
  }

  void _updateSimulatedWeight() {
    if (_simulatedWeight == _targetWeight) {
      if (!_simulatedStable) {
        _simulatedStable = true;
        _emitReading(_simulatedWeight, true);
      }
      return;
    }

    // Simulate weight settling with small random jitter
    final diff = _targetWeight - _simulatedWeight;
    final step = (diff * 0.3).round().clamp(-50, 50);
    final jitter = Random().nextInt(5) - 2; // ±2g jitter
    _simulatedWeight += step + jitter;

    // Snap to target when close enough
    if ((_simulatedWeight - _targetWeight).abs() < 5) {
      _simulatedWeight = _targetWeight;
      _simulatedStable = true;
    } else {
      _simulatedStable = false;
    }

    _emitReading(_simulatedWeight.clamp(0, 99999), _simulatedStable);
  }

  void _emitReading(int weightGrams, bool stable) {
    if (_readingController.isClosed) return;
    _readingController.add(ScaleReading(
      weightGrams: weightGrams,
      isStable: stable,
      timestamp: DateTime.now(),
    ));
  }

  void _setStatus(ScaleStatus s) {
    _status = s;
    if (!_statusController.isClosed) {
      _statusController.add(s);
    }
  }
}
