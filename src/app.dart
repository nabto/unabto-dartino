// This sample illustrates how to use the uNabto server library in combinations
// with the default HTML device driver client used in `developer.nabto.com`.

import 'dart:dartino';
import 'unabto.dart';

main() {
  // Configure the uNabto server with a server ID and a pre-shared key obtained
  // from `developer.nabto.com`.
  var unabto = new UNabto("devicename.demo.nab.to", "35d0dca...");

  // Get version information.
  print("uNabto version ${unabto.version}.");

  // Attempt to init and start the server.
  int result = unabto.init();
  if (result != 0) {
    print("Init error: $result.");
  } else {
    // Register two event handlers for the `light_write.json` and
    // `light_read.json` queries.
    unabto.registerReceiver(1, onLightWrite);
    unabto.registerReceiver(2, onLightRead);

    // This is where the main app code would usually run.
    // In this sample we just sleep a bit.
    sleep(10000);

    // Clean-up: Deallocate foreign memory and functions.
    unabto.close();
  }
}

/// The state of the virtual living room light.
int theLight = 0;

/// Set virtual light state to [onOff] and return the state.
/// This simple example uses only ID #1 so [id] has no effect.
int setLight(int id, int onOff) {
  theLight = onOff;
  print("Light $id turned ${theLight != 0 ? 'ON' : 'OFF'}!");
  return theLight;
}

/// Return virtual light's state.
/// This simple example uses only ID #1 so [id] has no effect.
int readLight(int id) {
  return theLight;
}

/// Dart callback functions invoked when new `light_write.json` query arrives.
///
///     <query name="light_write.json" description="Turn light on and off" id="1">
///       <request>
///         <parameter name="light_id" type="uint8"/>
///         <parameter name="light_on" type="uint8"/>
///       </request>
///       <response format="json">
///         <parameter name="light_state" type="uint8"/>
///       </response>
///     </query>
void onLightWrite(UNabtoRequest appRequest, UNabtoReadBuffer readBuffer,
    UNabtoWriteBuffer writeBuffer) {
  // Read the request parameters.
  int lightId = readBuffer.readUint8();
  int lightOn = readBuffer.readUint8();

  // Set the light state.
  int lightState = setLight(lightId, lightOn);

  // Write the response parameter.
  writeBuffer.writeUint8(lightState);
}

/// Dart callback functions invoked when new `light_read.json` query arrives.
///
///     <query name="light_read.json" description="Read light status" id="2">
///       <request>
///         <parameter name="light_id" type="uint8"/>
///       </request>
///       <response format="json">
///         <parameter name="light_state" type="uint8"/>
///       </response>
///     </query>
void onLightRead(UNabtoRequest appRequest, UNabtoReadBuffer readBuffer,
    UNabtoWriteBuffer writeBuffer) {
  // Read the request parameters.
  int lightId = readBuffer.readUint8();
  int lightState = readLight(lightId);

  // Write the response parameter.
  writeBuffer.writeUint8(lightState);
}
