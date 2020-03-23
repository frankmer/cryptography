// Copyright 2019 Gohilla Ltd (https://gohilla.com).
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/utils.dart';
import 'package:meta/meta.dart';

/// _Chacha20_ cipher ([RFC 7539](https://tools.ietf.org/html/rfc7539)).
///
/// Remember that:
///   * Secret key and nonce combination must be unique.
///   * The message is not authenticated. If you want to use chacha20 as
///     cipher, you may want to use [chacha20Poly1305Aead].
///
/// An example:
/// ```dart
/// import 'package:cryptography/cryptography.dart';
///
/// Future<void> main() async {
///   // Generate a random 256-bit secret key
///   final secretKey = await chacha20.newSecretKey();
///
///   // Generate a random 96-bit nonce.
///   final nonce = chacha20.newNonce();
///
///   // Encrypt
///   final result = await chacha20Poly1305Aead.encrypt(
///     [1, 2, 3],
///     secretKey: secretKey,
///     nonce: nonce, // The same secretKey/nonce combination should not be used twice
///     aad: const <int>[], // You can authenticate additional data here
///   );
///   print('Ciphertext: ${result.cipherText}');
///   print('MAC: ${result.mac}');
/// }
/// ```
const _Chacha20 chacha20 = _Chacha20._();

/// API for [chacha20].
class _Chacha20 extends SyncKeyStreamCipher {
  const _Chacha20._();

  @override
  SecretKeyGenerator get secretKeyGenerator => const SecretKeyGenerator(
        validLengths: <int>{32},
        defaultLength: 32,
      );

  @override
  String get name => 'chacha20';

  @override
  int get nonceLength => 12;

  @override
  SyncKeyStreamCipherState newState({
    @required SecretKey secretKey,
    int keyStreamIndex = 0,
    @required Nonce nonce,
  }) {
    SyncKeyStreamCipher.checkNewStateArguments(
      this,
      secretKey: secretKey,
      keyStreamIndex: keyStreamIndex,
      nonce: nonce,
    );
    final state = _Chacha20State(this);
    state.initialize(
      key: secretKey.bytes,
      nonce: nonce.bytes,
      keyStreamIndex: keyStreamIndex,
    );
    return state;
  }

  void _encryptState(Uint32List state, Uint32List initialState) {
    // Validate that we have a proper initial state.
    _validateInitialState(initialState);

    // -------------------------------------------------------------------------
    // Step 1: Initialize
    // -------------------------------------------------------------------------
    var v0 = initialState[0],
        v1 = initialState[1],
        v2 = initialState[2],
        v3 = initialState[3],
        v4 = initialState[4],
        v5 = initialState[5],
        v6 = initialState[6],
        v7 = initialState[7],
        v8 = initialState[8],
        v9 = initialState[9],
        v10 = initialState[10],
        v11 = initialState[11],
        v12 = initialState[12],
        v13 = initialState[13],
        v14 = initialState[14],
        v15 = initialState[15];

    // -------------------------------------------------------------------------
    // Step 2: Do 20 column/diagonal rounds
    //
    // We inlined the 'quarterRound' function because benchmarks showed
    // significant enough difference to non-inlined version.
    // -------------------------------------------------------------------------
    for (var i = 0; i < 10; i++) {
      // -------
      // Columns
      // -------
      v0 = uint32mask & (v0 + v4);
      v12 = rotateLeft32(v12 ^ v0, 16);
      v8 = uint32mask & (v8 + v12);
      v4 = rotateLeft32(v4 ^ v8, 12);
      v0 = uint32mask & (v0 + v4);
      v12 = rotateLeft32(v12 ^ v0, 8);
      v8 = uint32mask & (v8 + v12);
      v4 = rotateLeft32(v4 ^ v8, 7);

      v1 = uint32mask & (v1 + v5);
      v13 = rotateLeft32(v13 ^ v1, 16);
      v9 = uint32mask & (v9 + v13);
      v5 = rotateLeft32(v5 ^ v9, 12);
      v1 = uint32mask & (v1 + v5);
      v13 = rotateLeft32(v13 ^ v1, 8);
      v9 = uint32mask & (v9 + v13);
      v5 = rotateLeft32(v5 ^ v9, 7);

      v2 = uint32mask & (v2 + v6);
      v14 = rotateLeft32(v14 ^ v2, 16);
      v10 = uint32mask & (v10 + v14);
      v6 = rotateLeft32(v6 ^ v10, 12);
      v2 = uint32mask & (v2 + v6);
      v14 = rotateLeft32(v14 ^ v2, 8);
      v10 = uint32mask & (v10 + v14);
      v6 = rotateLeft32(v6 ^ v10, 7);

      v3 = uint32mask & (v3 + v7);
      v15 = rotateLeft32(v15 ^ v3, 16);
      v11 = uint32mask & (v11 + v15);
      v7 = rotateLeft32(v7 ^ v11, 12);
      v3 = uint32mask & (v3 + v7);
      v15 = rotateLeft32(v15 ^ v3, 8);
      v11 = uint32mask & (v11 + v15);
      v7 = rotateLeft32(v7 ^ v11, 7);

      // ---------
      // Diagonals
      // ---------
      v0 = uint32mask & (v0 + v5);
      v15 = rotateLeft32(v15 ^ v0, 16);
      v10 = uint32mask & (v10 + v15);
      v5 = rotateLeft32(v5 ^ v10, 12);
      v0 = uint32mask & (v0 + v5);
      v15 = rotateLeft32(v15 ^ v0, 8);
      v10 = uint32mask & (v10 + v15);
      v5 = rotateLeft32(v5 ^ v10, 7);

      v1 = uint32mask & (v1 + v6);
      v12 = rotateLeft32(v12 ^ v1, 16);
      v11 = uint32mask & (v11 + v12);
      v6 = rotateLeft32(v6 ^ v11, 12);
      v1 = uint32mask & (v1 + v6);
      v12 = rotateLeft32(v12 ^ v1, 8);
      v11 = uint32mask & (v11 + v12);
      v6 = rotateLeft32(v6 ^ v11, 7);

      v2 = uint32mask & (v2 + v7);
      v13 = rotateLeft32(v13 ^ v2, 16);
      v8 = uint32mask & (v8 + v13);
      v7 = rotateLeft32(v7 ^ v8, 12);
      v2 = uint32mask & (v2 + v7);
      v13 = rotateLeft32(v13 ^ v2, 8);
      v8 = uint32mask & (v8 + v13);
      v7 = rotateLeft32(v7 ^ v8, 7);

      v3 = uint32mask & (v3 + v4);
      v14 = rotateLeft32(v14 ^ v3, 16);
      v9 = uint32mask & (v9 + v14);
      v4 = rotateLeft32(v4 ^ v9, 12);
      v3 = uint32mask & (v3 + v4);
      v14 = rotateLeft32(v14 ^ v3, 8);
      v9 = uint32mask & (v9 + v14);
      v4 = rotateLeft32(v4 ^ v9, 7);
    }

    // -------------------------------------------------------------------------
    // Step 3: Addition
    // -------------------------------------------------------------------------
    state[0] = uint32mask & (v0 + initialState[0]);
    state[1] = uint32mask & (v1 + initialState[1]);
    state[2] = uint32mask & (v2 + initialState[2]);
    state[3] = uint32mask & (v3 + initialState[3]);
    state[4] = uint32mask & (v4 + initialState[4]);
    state[5] = uint32mask & (v5 + initialState[5]);
    state[6] = uint32mask & (v6 + initialState[6]);
    state[7] = uint32mask & (v7 + initialState[7]);
    state[8] = uint32mask & (v8 + initialState[8]);
    state[9] = uint32mask & (v9 + initialState[9]);
    state[10] = uint32mask & (v10 + initialState[10]);
    state[11] = uint32mask & (v11 + initialState[11]);
    state[12] = uint32mask & (v12 + initialState[12]);
    state[13] = uint32mask & (v13 + initialState[13]);
    state[14] = uint32mask & (v14 + initialState[14]);
    state[15] = uint32mask & (v15 + initialState[15]);
  }

  void _validateInitialState(Uint32List initialState) {
    if (initialState[0] != 0x61707865) {
      throw StateError(
          "Initial state is invalid. Did you forget to call 'initialize'?");
    }
  }
}

class _Chacha20State extends SyncKeyStreamCipherState {
  // ---------------------------------------------------------------------------
  // Some constants
  // ---------------------------------------------------------------------------
  static const int _keyLengthInBytes = 32;
  static const int _nonceLengthInBytes = 12;
  static const int _stateLength = 16;

  // ---------------------------------------------------------------------------
  // Static buffers.
  //
  // They are cleared after every operation so sensitive data
  // will not remain in the heap.
  // ---------------------------------------------------------------------------
  static final Uint32List _state = Uint32List(_stateLength);
  static final ByteData _stateByteData = ByteData.view(
    _state.buffer,
    _state.offsetInBytes,
    _state.lengthInBytes,
  );

  final _Chacha20 _chacha;

  final Uint32List initialState = Uint32List(_stateLength);

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
  int _keyStreamIndex = 0;

  _Chacha20State(this._chacha);

  @override
  int get keyStreamIndex => _keyStreamIndex;

  @override
  set keyStreamIndex(int value) {
    if (value < 0) {
      throw ArgumentError.value(value);
    }
    _keyStreamIndex = value;
    initialState[12] = value ~/ 64;
  }

  /// Removes secrets from the heap.
  ///
  /// After invoking this method, encryption operations will fail unless
  /// [initialize] is called.
  @override
  void close() {
    initialState.fillRange(0, initialState.length, 0);
    super.close();
  }

  @override
  void fillWithKeyStream(List<int> result, int start, {int length}) {
    SyncKeyStreamCipherState.checkNotClosed(this);
    if (start < 0) {
      throw ArgumentError.value(start, 'start');
    }
    if (length == null) {
      length = result.length - start;
    } else if (length < 0 || length > result.length - start) {
      throw ArgumentError.value(length, 'length');
    }
    _chacha._validateInitialState(initialState);

    // ----------------------------
    // Special case for empty lists
    // ----------------------------
    if (length == 0) {
      return;
    }

    // -----------------
    // Declare variables
    // -----------------
    final state = _state;
    final stateByteData = _stateByteData;
    var keyStreamIndex = this.keyStreamIndex;

    // -----------------------------
    // Prepare for optimized copying
    // -----------------------------
    // For key streams over 256 bytes:
    // Whole blocks will be copied using 16 uint32 assignments
    // (including host endian to little endian conversion).
    //
    // Benchmarks indicated this has a surprisingly high (>30%) impact
    // on converting long streams.
    //
    // Minimum length 256 bytes is just a guess of a good value.
    ByteData resultByteData;
    if (length > 256 && keyStreamIndex % 64 == 0 && result is Uint8List) {
      resultByteData = ByteData.view(
        result.buffer,
        result.offsetInBytes,
        result.lengthInBytes,
      );
    }

    try {
      // -----------------------------------------------------------------------
      // For each byte
      // -----------------------------------------------------------------------
      while (length > 0) {
        // Encrypt state
        _chacha._encryptState(state, initialState);

        // Should we copy
        if (resultByteData != null && length >= 64) {
          // ---------------------------------
          // Optimized method for whole blocks
          // ---------------------------------

          // Copy whole block using 16 uint32 assignments
          for (var i = 0; i < 16; i++) {
            resultByteData.setUint32(start, state[i], Endian.little);
            start += 4;
          }

          // Increment variables
          keyStreamIndex += 64;
          length -= 64;
        } else {
          // -------------------
          // Byte-by-byte method
          // -------------------

          // Convert state:
          // Host endian --> little endian
          for (var i = 0; i < state.length; i++) {
            stateByteData.setUint32(4 * i, state[i], Endian.little);
          }

          // Do uint8 assignments
          for (var i = keyStreamIndex % 64; i < 64 && length > 0; i++) {
            result[start] = stateByteData.getUint8(i);

            // Increment key stream index
            keyStreamIndex++;
            length--;
            start++;
          }
        }

        // Store current 'keyStreamIndex'
        this.keyStreamIndex = keyStreamIndex;
      }
    } finally {
      // Clear static state buffer.
      // This is not strictly necessary, but it's good for data protection.
      for (var i = 0; i < state.length; i++) {
        state[i] = 0;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Other methods
  // ---------------------------------------------------------------------------

  /// Sets initial state using the key, nonce, and counter.
  ///
  /// A few rules:
  ///   * You must define key. You can generate a random key with
  ///     [Chacha20.randomKey].
  ///   * If nonce is null, zeroes will be used.
  ///   * It's important that you never use the same (key, nonce) combination
  ///     for two different message.
  void initialize({
    @required List<int> key,
    @required List<int> nonce,
    int keyStreamIndex = 0,
  }) {
    if (key == null) {
      throw ArgumentError.notNull('key');
    } else if (key.length != _keyLengthInBytes) {
      throw ArgumentError.value(
        key,
        'key',
        'Key length ${key.length} is invalid: should be ${_keyLengthInBytes}',
      );
    }
    if (nonce != null && nonce.length != _nonceLengthInBytes) {
      throw ArgumentError.value(
        nonce,
        'nonce',
        'Nonce length ${nonce.length} is invalid: should be ${_nonceLengthInBytes}',
      );
    }

    // Mark as uninitialized so encryption will fail if this method throws.
    final state = initialState;
    state[0] = 0x61707865;
    state[1] = 0x3320646e;
    state[2] = 0x79622d32;
    state[3] = 0x6b206574;

    final stateByteData = ByteData.view(
      state.buffer,
      state.offsetInBytes,
      state.lengthInBytes,
    );

    //
    // Key
    //
    var stateBytesIndex = 4 * 4;
    for (var i = 0; i < key.length; i++) {
      stateByteData.setUint8(stateBytesIndex, key[i]);
      stateBytesIndex++;
    }
    // Convert little endian --> host endian
    for (var i = 4; i < 12; i++) {
      state[i] = stateByteData.getUint32(4 * i, Endian.little);
    }

    //
    // Counter
    //
    this.keyStreamIndex = keyStreamIndex;

    //
    // Nonce
    //
    if (nonce == null) {
      for (var i = 13; i < 16; i++) {
        initialState[i] = 0;
      }
    } else {
      stateBytesIndex = 13 * 4;
      for (var i = 0; i < nonce.length; i++) {
        stateByteData.setUint8(stateBytesIndex, nonce[i]);
        stateBytesIndex++;
      }
      // Convert little endian --> host endian
      for (var i = 13; i < 16; i++) {
        state[i] = stateByteData.getUint32(4 * i, Endian.little);
      }
    }
  }
}
