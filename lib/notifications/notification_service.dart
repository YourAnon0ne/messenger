import 'dart:isolate';

static ReceivePort? receivePort;
static Future<void> initializeIsolateReceivePort() async {
  receivePort = ReceivePort('Silent action port in main isolate')
    ..listen((silentData) => mySilentDataHandle(silentData));

  // This initialization only happens on main isolate
  IsolateNameServer.registerPortWithName(
      receivePort!.sendPort, 'silent_action_port');
}

@pragma('vm:entry-point')
void mySilentDataHandle(FcmSilentData silentData) {
    // this process is only necessary when you need to have access to features
    // only available if you have a valid context. Since parallel isolates do not
    // have valid context, you need redirect the execution to main isolate.
    if (receivePort == null) {
      print(
          'onActionReceivedMethod was called inside a parallel dart isolate.');
      SendPort? sendPort =
          IsolateNameServer.lookupPortByName('silent_action_port');

      if (sendPort != null) {
        print('Redirecting the execution to main isolate process.');
        sendPort.send(receivedAction);
        return;
      }
    }

    // Execute the rest of your code
}