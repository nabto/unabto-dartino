// uNabto server library.

library unabto;

import 'dart:dartino.ffi';
import 'package:ffi/ffi.dart';
import 'dart:convert';
import 'dart:async';

final ForeignLibrary _unabto =
    new ForeignLibrary.fromName(ForeignLibrary.bundleLibraryName('unabtolib'));

final _unabtoVersion = _unabto.lookup('unabtoVersion');
final _unabtoConfigure = _unabto.lookup('unabtoConfigure');
final _unabtoInit = _unabto.lookup('unabtoInit');
final _unabtoClose = _unabto.lookup('unabtoClose');
final _unabtoTick = _unabto.lookup('unabtoTick');
final _unabtoRegisterEventHandler =
    _unabto.lookup('unabtoRegisterEventHandler');

/// uNabto request event meta data.
class UNabtoRequest {
  /// The foreign `application_request` structure this wraps.
  final Struct _struct;

  /// Returns the ID of the query.
  int get queryId => _struct.getUint32(0);

  /// Returns the ID of the client.
  String get clientId {
    var ptr = new ForeignPointer(_struct.getField(1));
    return cStringToString(ptr);
  }

  /// Returns `true` if the request was issued from within the local network.
  bool get isLocal => _struct.getUint8(2 * _struct.wordSize) != 0;

  /// Returns `true` if the request was issued from within a remote network.
  bool get isLegacy => _struct.getUint8(3 * _struct.wordSize) != 0;

  /// Constructs a new request meta data object with a [pointer] to the foreign
  /// `application_request` structure this should wrap.
  const UNabtoRequest.fromAddress(int pointer)
      : _struct = new Struct.fromAddress(pointer, 4);
}

/// Wrapper for `buffer_read_t` and `buffer_write_t` structures.
///
/// Both `buffer_read_t` and `buffer_write_t` are typedefs for `unabto_abuffer`
/// which holds a pointer to the actual `unabto_buffer` data structure and the
/// current read/write position in the buffer.
class _UNabtoBuffer {
  /// Foreign memory holding the current read/write position in the buffer.
  ForeignMemory _pos;

  /// Foreign memory holding the buffer array.
  ForeignMemory _buffer;

  /// Size of the buffer array.
  int _size;

  /// Returns the current read/write position in the buffer.
  int get _position => _pos.getUint16(0);

  /// Sets the current read/write [position] in the buffer.
  ///
  /// Has no effect if the new [position] isn't within the bounds of the buffer.
  int set _position(int position) {
    if (0 <= position || position < _size) _pos.setUint16(0, position);
    return position;
  }

  /// Returns the unused space in the buffer.
  int get _unused => _size - _position;

  /// Constructs a new buffer wrapper object with a [pointer] to the foreign
  /// `buffer_read_t` or `buffer_write_t` structure this should wrap.
  _UNabtoBuffer.fromAddress(int pointer) {
    _pos = new ForeignMemory.fromAddress(pointer + Foreign.machineWordSize, 2);
    var unabto_buffer = new Struct.fromAddress(
        new Struct.fromAddress(pointer, 2).getField(0), 2);
    _size = unabto_buffer.getUint16(0);
    _buffer = new ForeignMemory.fromAddress(unabto_buffer.getField(1), _size);
  }
}

/// There is not enough data left in the request's read buffer.
class UNabtoRequestTooSmallError extends Error {
  UNabtoRequestTooSmallError() : super();
}

/// uNabto event read buffer.
class UNabtoReadBuffer extends _UNabtoBuffer {
  /// Interprets the binary value of an [unsigned] number with a specific number
  /// of [bits] as two's complement and returns the signed value.
  int _signed(int unsigned, int bits) {
    bool negative = (unsigned & (1 << (bits - 1))) != 0;
    if (negative)
      return unsigned | ~((1 << bits) - 1);
    else
      return unsigned;
  }

  /// Reads an unsigned integer value with a specific number of [bits] from the
  /// buffer and returns it.
  ///
  /// Throws an [UNabtoRequestTooSmallError] if there is not enough data left in
  /// the buffer.
  int _readUint(int bits) {
    if (_unused < (bits / 8)) throw new UNabtoRequestTooSmallError();
    var value = 0;
    for (int i = bits - 8; i >= 0; i -= 8)
      value |= _buffer.getUint8(_position++) << i;
    return value;
  }

  /// Reads an signed integer value with a specific number of [bits] from the
  /// buffer and returns it.
  ///
  /// Throws an [UNabtoRequestTooSmallError] if there is not enough data left in
  /// the buffer.
  int _readInt(int bits) => _signed(_readUint(bits), bits);

  /// Reads a 8-bit signed integer value from the buffer and returns it.
  ///
  /// Throws an [UNabtoRequestTooSmallError] if there is not enough data left in
  /// the buffer.
  int readInt8() => _readInt(8);

  /// Reads a 16-bit signed integer value from the buffer and returns it.
  ///
  /// Throws an [UNabtoRequestTooSmallError] if there is not enough data left in
  /// the buffer.
  int readInt16() => _readInt(16);

  /// Reads a 32-bit signed integer value from the buffer and returns it.
  ///
  /// Throws an [UNabtoRequestTooSmallError] if there is not enough data left in
  /// the buffer.
  int readInt32() => _readInt(32);

  /// Reads a 8-bit unsigned integer value from the buffer and returns it.
  ///
  /// Throws an [UNabtoRequestTooSmallError] if there is not enough data left in
  /// the buffer.
  int readUint8() => _readUint(8);

  /// Reads a 16-bit unsigned integer value from the buffer and returns it.
  ///
  /// Throws an [UNabtoRequestTooSmallError] if there is not enough data left in
  /// the buffer.
  int readUint16() => _readUint(16);

  /// Reads a 32-bit unsigned integer value from the buffer and returns it.
  ///
  /// Throws an [UNabtoRequestTooSmallError] if there is not enough data left in
  /// the buffer.
  int readUint32() => _readUint(32);

  /// Reads a list of unsigned integer values from the buffer and returns it.
  ///
  /// Throws an [UNabtoRequestTooSmallError] if there is not enough data left in
  /// the buffer.
  List<int> readUint8List() {
    var length = readUint16();
    var list = new List<int>(length);
    _buffer.copyBytesToList(list, _position, _position + length, 0);
    _position += length;
    return list;
  }

  /// Reads a string from the buffer and returns it.
  ///
  /// Throws an [UNabtoRequestTooSmallError] if there is not enough data left in
  /// the buffer.
  String readString() {
    var charCodes = readUint8List();
    return UTF8.decode(charCodes);
  }

  /// Constructs a new read buffer wrapper object with a [pointer] to the
  /// foreign `buffer_read_t` structure this should wrap.
  UNabtoReadBuffer.fromAddress(int ptr) : super.fromAddress(ptr);
}

/// There is not enough space left in the request's response write buffer.
class UNabtoResponseTooLargeError extends Error {
  UNabtoResponseTooLargeError() : super();
}

/// uNabto event write buffer.
class UNabtoWriteBuffer extends _UNabtoBuffer {
  /// Interprets the two's complement binary value of a [signed] number with a
  /// specific number of [bits] as unsigned value and returns it.
  int _unsigned(int signed, int bits) {
    if (signed < 0)
      return signed | ~((1 << bits) - 1);
    else
      return signed;
  }

  /// Writes an unsigned integer [value] with a specific number of [bits] to
  /// the buffer.
  ///
  /// Throws a [UNabtoResponseTooLargeError] if there is not enough space left
  /// in the buffer.
  void _writeUint(int value, int bits) {
    if (_unused < (bits / 8)) throw new UNabtoResponseTooLargeError();
    for (int i = bits - 8; i >= 0; i -= 8)
      _buffer.setUint8(_position++, value >> i);
  }

  /// Writes a signed integer [value] with a specific number of [bits] to
  /// the buffer.
  ///
  /// Throws an [UNabtoResponseTooLargeError] if there is not enough space left
  /// in the buffer.
  void _writeInt(value, bits) => _writeUint(_unsigned(value, bits), bits);

  /// Writes a signed 8-bit integer [value] to the buffer.
  ///
  /// Throws an [UNabtoResponseTooLargeError] if there is not enough space left
  /// in the buffer.
  void writeInt8(int value) => _writeInt(value, 8);

  /// Writes a signed 16-bit integer [value] to the buffer.
  ///
  /// Throws an [UNabtoResponseTooLargeError] if there is not enough space left
  /// in the buffer.
  void writeInt16(int value) => _writeInt(value, 16);

  /// Writes a signed 32-bit integer [value] to the buffer.
  ///
  /// Throws an [UNabtoResponseTooLargeError] if there is not enough space left
  /// in the buffer.
  void writeInt32(int value) => _writeInt(value, 32);

  /// Writes an unsigned 8-bit integer [value] to the buffer.
  ///
  /// Throws an [UNabtoResponseTooLargeError] if there is not enough space left
  /// in the buffer.
  void writeUint8(int value) => _writeUint(value, 8);

  /// Writes an unsigned 16-bit integer [value] to the buffer.
  ///
  /// Throws an [UNabtoResponseTooLargeError] if there is not enough space left
  /// in the buffer.
  void writeUint16(int value) => _writeUint(value, 16);

  /// Writes an unsigned 32-bit integer [value] to the buffer.
  ///
  /// Throws an [UNabtoResponseTooLargeError] if there is not enough space left
  /// in the buffer.
  void writeUint32(int value) => _writeUint(value, 32);

  /// Writes a [list] of unsigned 8-bit integer values to the buffer.
  ///
  /// Throws an [UNabtoResponseTooLargeError] if there is not enough space left
  /// in the buffer.
  void writeUint8List(List<int> list) {
    writeUint16(list.length);
    _buffer.copyBytesFromList(list, _position, _position + list.length, 0);
    _position += list.length;
  }

  /// Writes a [string] to the buffer.
  ///
  /// Throws an [UNabtoResponseTooLargeError] if there is not enough space left
  /// in the buffer.
  void writeString(String string) {
    var charCodes = UTF8.encode(string);
    writeUint8List(charCodes);
  }

  /// Constructs a new write buffer wrapper object with a [pointer] to the
  /// foreign `buffer_write_t` structure this should wrap.
  UNabtoWriteBuffer.fromAddress(int ptr) : super.fromAddress(ptr);
}

/// The uNabto server.
class UNabto {
  /// Single instance of this.
  static UNabto _instance = null;

  /// Nabto ID of the server.
  final String _id;

  /// Preshared key for the secure connection.
  final String _presharedKey;

  /// Duration of 2 msec used for the tick timer.
  static const _twoMillis = const Duration(milliseconds:2);

  /// The tick timer.
  Timer _tickTimer = null;

  /// List of registered event handling functions.
  List _handlerFunctions = new List<ForeignDartFunction>();

  /// Creates a new uNabto server with given [id] and [presharedKey].
  UNabto(this._id, this._presharedKey) {
    // Allow only one instance of the uNabto server.
    if (_instance != null)
      throw new StateError("There can only be one instance of UNabto.");

    // Create a structure that contains the configuration options.
    var configOptions = new Struct.finalized(2);
    ForeignMemory id = new ForeignMemory.fromStringAsUTF8(_id);
    configOptions.setField(0, id.address);
    ForeignMemory presharedKey =
        new ForeignMemory.fromStringAsUTF8(_presharedKey);
    configOptions.setField(1, presharedKey.address);

    // `unabtoConfigure` takes a struct argument, and returns void.
    _unabtoConfigure.vcall$1(configOptions.address);

    // Free allocated foreign memory for the configuration structure.
    id.free();
    presharedKey.free();
    configOptions.free();

    // Save current instance in static `_instance` variable to prevent to throw
    // an error on attempts to create a second instance.
    _instance = this;
  }

  /// Returns the version of the uNabto server.
  String get version {
    return cStringToString(_unabtoVersion.pcall$0());
  }

  /// Initializes and starts the server.
  ///
  /// Returns `0` on success or `-1` if something went wrong.
  int init() {
    if (_id == null || _presharedKey == null) return -1;
    int result = _unabtoInit.icall$0();
    if (result == 0) {
      // Allow uNabto to process any new incoming telegrams every 2 msec.
      _tickTimer =
          new Timer.periodic(_twoMillis, (Timer t) => _unabtoTick.vcall$0());
    }
    return result;
  }

  /// Wraps the consumer handler in a function the takes C struct pointers as
  /// it's arguments, like the uNabto library expects it.
  ///
  /// Furthermore it catches potentual errors in the handler caused for example
  /// by writing to much data to the response buffer and translates it to the
  /// appropriate return value for the callback function.
  Function _handlerWrapper(void handler(UNabtoRequest appRequest,
      UNabtoReadBuffer readBuffer, UNabtoWriteBuffer writeBuffer)) {
    return (int appRequestPtr, int readBufferPtr, int writeBufferPtr) {
      try {
        var appRequest = new UNabtoRequest.fromAddress(appRequestPtr);
        var readBuffer = new UNabtoReadBuffer.fromAddress(readBufferPtr);
        var writeBuffer = new UNabtoWriteBuffer.fromAddress(writeBufferPtr);
        handler(appRequest, readBuffer, writeBuffer);
        return 0; // AER_REQ_RESPONSE_READY
      } on UNabtoRequestTooSmallError catch (e) {
        print("The uNabto request is too small!");
        return 5; // AER_REQ_TOO_SMALL
      } on UNabtoResponseTooLargeError catch (e) {
        print("The uNabto response is larger than the space allocated!");
        return 8; // AER_REQ_RSP_TOO_LARGE
      } catch (e, stackTrace) {
        print("Error '$e' in callback handler!");
        return 10; // AER_REQ_SYSTEM_ERROR
      }
    };
  }

  /// Registers a new event [handler] for the [queryId].
  void registerReceiver(
      int queryId,
      void handler(UNabtoRequest request, UNabtoReadBuffer readbuf,
          UNabtoWriteBuffer writeBuffer)) {
    // The uNabto library expects a handler that takes C struct pointers as it's
    // arguments, but the consumer of this librarty will pass in a handler that
    // takes Dart wrapper objects. We adapt the types by wrapping the consumer
    // handler in a function that creates the Dart struct wrapper objects from
    // the C struct pointers.
    var newHandlerFunction = new ForeignDartFunction(_handlerWrapper(handler));
    // `unabtoRegisterEventHandler` takes an int, and a function pointer.
    _unabtoRegisterEventHandler.icall$2(queryId, newHandlerFunction);
    _handlerFunctions.add(newHandlerFunction);
  }

  // Closes the uNabto server, and frees all resources.
  void close() {
    if (_tickTimer != null) _tickTimer.cancel();
    _unabtoClose.vcall$0();
    _handlerFunctions.forEach((f) => f.free());
  }
}
