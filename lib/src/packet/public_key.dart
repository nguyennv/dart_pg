// Copyright 2022-present by Nguyen Van Nguyen <nguyennv1981@gmail.com>. All rights reserved.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.

import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../enums.dart';
import '../helpers.dart';
import '../key/dsa_public_pgp_key.dart';
import '../key/ecdh_public_pgp_key.dart';
import '../key/ecdsa_public_pgp_key.dart';
import '../key/elgamal_public_pgp_key.dart';
import '../key/pgp_key.dart';
import '../key/rsa_public_pgp_key.dart';
import 'contained_packet.dart';

/// PublicKey represents an OpenPGP public key.
/// See RFC 4880, section 5.5.2.
class PublicKey extends ContainedPacket {
  final int version;

  final DateTime creationTime;

  final int expirationDays;

  final KeyAlgorithm algorithm;

  final PgpKey pgpKey;

  late final Uint8List _fingerprint;

  late final int _keyID;

  PublicKey(
    this.version,
    this.creationTime,
    this.pgpKey, {
    this.expirationDays = 0,
    this.algorithm = KeyAlgorithm.rsaEncryptSign,
    super.tag = PacketTag.publicKey,
  }) {
    _calculateFingerprintAndKeyID();
  }

  factory PublicKey.fromPacketData(final Uint8List bytes) {
    var pos = 0;

    /// A one-octet version number (3, 4 or 5).
    final version = bytes[pos++];

    /// A four-octet number denoting the time that the key was created.
    final creationTime = bytes.sublist(pos, pos + 4).toDateTime();
    pos += 4;

    /// A two-octet number denoting the time in days that this key is valid.
    /// If this number is zero, then it does not expire.
    final expirationDays = (version == 3) ? bytes.sublist(pos, pos + 2).toIn16() : 0;
    if (version == 3) {
      pos += 2;
    }

    // A one-octet number denoting the public-key algorithm of this key.
    final algorithm = KeyAlgorithm.values.firstWhere((algo) => algo.value == bytes[pos++]);
    if (version == 5) {
      /// - A four-octet scalar octet count for the following key material.
      pos += 4;
    }

    /// A series of values comprising the key material.
    /// This is algorithm-specific and described in section XXXX.
    final PgpKey pgpKey;
    switch (algorithm) {
      case KeyAlgorithm.rsaEncryptSign:
      case KeyAlgorithm.rsaEncrypt:
      case KeyAlgorithm.rsaSign:
        pgpKey = RsaPublicPgpKey.fromPacketData(bytes.sublist(pos));
        break;
      case KeyAlgorithm.elgamal:
        pgpKey = ElGamalPublicPgpKey.fromPacketData(bytes.sublist(pos));
        break;
      case KeyAlgorithm.dsa:
        pgpKey = DsaPublicPgpKey.fromPacketData(bytes.sublist(pos));
        break;
      case KeyAlgorithm.ecdh:
        pgpKey = ECDHPublicPgpKey.fromPacketData(bytes.sublist(pos));
        break;
      case KeyAlgorithm.ecdsa:
        pgpKey = ECDsaPublicPgpKey.fromPacketData(bytes.sublist(pos));
        break;
      default:
        throw UnsupportedError('Unknown PGP public key algorithm encountered');
    }
    return PublicKey(
      version,
      creationTime,
      pgpKey,
      expirationDays: expirationDays,
      algorithm: algorithm,
    );
  }

  /// Computes and set the fingerprint of the key
  void _calculateFingerprintAndKeyID() {
    final List<int> toHash = [];
    if (version <= 3) {
      final pk = pgpKey as RsaPublicPgpKey;
      final bytes = pk.modulus!.toBytes();

      toHash.addAll(bytes);
      toHash.addAll(pk.publicExponent!.toBytes());

      _fingerprint = Uint8List.fromList(md5.convert(toHash).bytes);
      _keyID = bytes.sublist(bytes.length - 8).toInt64();
    } else {
      final bytes = toPacketData();
      if (version == 5) {
        toHash.add(0x9A);
        toHash.addAll(bytes.length.unpack32());
        toHash.addAll(bytes);

        _fingerprint = Uint8List.fromList(sha256.convert(toHash).bytes);
        _keyID = _fingerprint.sublist(0, 8).toInt64();
      } else if (version == 4) {
        toHash.add(0x99);
        toHash.addAll(bytes.length.unpack16());
        toHash.addAll(bytes);

        _fingerprint = Uint8List.fromList(sha1.convert(toHash).bytes);
        _keyID = _fingerprint.sublist(12, 20).toInt64();
      } else {
        _fingerprint = Uint8List.fromList([]);
        _keyID = 0;
      }
    }
  }

  Uint8List get fingerprint => _fingerprint;

  int get keyID => _keyID;

  @override
  Uint8List toPacketData() {
    final List<int> bytes = [version & 0xff, ...creationTime.toBytes()];
    if (version <= 3) {
      bytes.addAll(expirationDays.unpack16());
    }
    bytes.add(algorithm.value & 0xff);

    final keyData = pgpKey.encode();
    if (version == 5) {
      bytes.addAll(keyData.length.unpack32());
    }
    bytes.addAll(keyData);

    return Uint8List.fromList(bytes);
  }
}
