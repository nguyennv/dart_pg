// Copyright 2022-present by Nguyen Van Nguyen <nguyennv1981@gmail.com>. All rights reserved.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.

import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

import '../enums.dart';
import 'ec_public_params.dart';

class ECDHPublicParams extends ECPublicParams {
  final int reserved;

  final HashAlgorithm hashAlgorithm;

  final SymmetricAlgorithm symmetricAlgorithm;

  ECDHPublicParams(super.publicKey, this.hashAlgorithm, this.symmetricAlgorithm, {this.reserved = 0x1});

  factory ECDHPublicParams.fromPacketData(Uint8List bytes) {
    var pos = 0;
    final length = bytes[pos++];
    if (length == 0 || length == 0xFF) {
      throw Exception('Future extensions not yet implemented');
    }
    if (length > 127) {
      throw UnsupportedError('Unsupported OID');
    }

    final derBytes = [0x06, length];
    derBytes.addAll(bytes.sublist(pos, pos + length));
    final oid = ASN1ObjectIdentifier.fromBytes(Uint8List.fromList(derBytes));

    pos += length;
    final parameters = ECPublicParams.parametersFromOid(oid);
    final point = parameters.curve.decodePoint(bytes.sublist(pos));

    final encodedLength = point!.getEncoded(false).length;
    pos += encodedLength;

    final kdfBytes = bytes.sublist(pos);
    final reserved = kdfBytes[1];
    final hashAlgorithm = HashAlgorithm.values.firstWhere((hash) => hash.value == kdfBytes[2]);
    final symmetricAlgorithm = SymmetricAlgorithm.values.firstWhere((sym) => sym.value == kdfBytes[3]);
    return ECDHPublicParams(
      ECPublicKey(point, parameters),
      hashAlgorithm,
      symmetricAlgorithm,
      reserved: reserved,
    );
  }

  @override
  Uint8List encode() {
    final List<int> bytes = [];
    bytes.addAll(super.encode());
    bytes.addAll([
      0x3,
      reserved,
      hashAlgorithm.value,
      symmetricAlgorithm.value,
    ]);
    return Uint8List.fromList(bytes);
  }
}