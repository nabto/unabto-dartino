# uNabto Dartino Library
This library enables the usage of the uNabto framework from within [Dartino](https://dartino.org/). The accompanying example [app.dart](./src/app.dart) controls a virtual light using the framework.

*NOTE: Due to limitations of the Dartino FFI library, included in the latest Dartino SDK, this is currently only working on a local PC.*

Please also refer to [this article](https://blog.nabto.com/2016/05/18/dartino-unabto/) on the [Nabto blog](http://blog.nabto.com/) for more information.

# How to set it up
## Step 1: Clone the repository
```shell
git clone --recursive https://github.com/nabto/unabto-dartino
cd unabto-dartino
```
## Step 2: Download and unzip the Dartino SDK
Linux
```shell
curl "https://storage.googleapis.com/dartino-archive/channels/dev/release/latest/sdk/dartino-sdk-linux-x64-release.zip" -o "/tmp/dartino-sdk.zip"
unzip /tmp/dartino-sdk.zip
```
Mac OS
```shell
curl "https://storage.googleapis.com/dartino-archive/channels/dev/release/latest/sdk/dartino-sdk-macos-x64-release.zip" -o "/tmp/dartino-sdk.zip"
unzip /tmp/dartino-sdk.zip
```
## Step 3: Build the C library
```shell
mkdir build
cd build
cmake ..
make
cd ..
```

# How to use the example application
Add a new device on [developer.nabto.com](https://developer.nabto.com/) and enter it's *Device ID* and *Key* in line 10 of the [src/app.dart](./src/app.dart) file.

Now you can run the example application with the dartino tool
```shell
./dartino-sdk/bin/dartino run src/app.dart
```

You should see a log printout similar to this:

```
15:18:54:118 unabto_common_main.c(127) Device id: 'devicename.demo.nab.to'
15:18:54:118 unabto_common_main.c(128) Program Release 123.456
15:18:54:118 unabto_app_adapter.c(698) Application event framework using SYNC model
15:18:54:118 unabto_context.c(55) SECURE ATTACH: 1, DATA: 1
15:18:54:118 unabto_context.c(63) NONCE_SIZE: 32, CLEAR_TEXT: 0
15:18:54:118 unabto_common_main.c(206) Nabto was successfully initialized
15:18:54:118 unabto_context.c(55) SECURE ATTACH: 1, DATA: 1
15:18:54:118 unabto_context.c(63) NONCE_SIZE: 32, CLEAR_TEXT: 0
15:18:54:118 unabto_attach.c(787) State change from IDLE to WAIT_DNS
15:18:54:118 unabto_attach.c(788) Resolving dns: devicename.demo.nab.to
uNabto version 123.456.
15:18:54:330 unabto_attach.c(809) State change from WAIT_DNS to WAIT_BS
15:18:54:353 unabto_attach.c(474) State change from WAIT_BS to WAIT_GSP
15:18:54:364 unabto_attach.c(266) ########    U_INVITE with LARGE nonce sent, version: - URL: -
15:18:54:375 unabto_attach.c(575) State change from WAIT_GSP to ATTACHED
```

We can now connect to the uNabto server by going to `devicename.demo.nab.to` in the browser of your choice. (`devicename` is the unique name created at [developer.nabto.com](https://developer.nabto.com/)).
The browser will present us a login prompt, simply click `guest`. We can now control the virtual light by moving the slider.

```
Light 1 turned OFF!
Light 1 turned ON!
```

For demonstration purposes, the example application closes the server connection after ~10 seconds.
