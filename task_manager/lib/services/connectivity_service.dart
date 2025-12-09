import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectionStatus {
  online,
  offline,
  unknown,
}

class ConnectivityService {
  // Singleton instance
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectionStatus> _connectionChangeController =
      StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _currentStatus = ConnectionStatus.unknown;

  // Expose the stream for status changes
  Stream<ConnectionStatus> get connectionStatus => _connectionChangeController.stream;

  // Initialize the service and start listening for changes
  void initialize() {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialConnection();
  }

  // Get the current connection status
  ConnectionStatus get currentStatus => _currentStatus;

  Future<void> _checkInitialConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    ConnectionStatus newStatus;
    // If the list contains ANY connection type other than none, we are online
    if (result.contains(ConnectivityResult.none) && result.length == 1) {
      newStatus = ConnectionStatus.offline;
    } else if (result.isEmpty) {
       newStatus = ConnectionStatus.offline;
    } else {
      newStatus = ConnectionStatus.online;
    }

    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _connectionChangeController.add(newStatus);
    }
  }

  // Dispose of the stream controller when no longer needed
  void dispose() {
    _connectionChangeController.close();
  }
}