// Copyright 2022-present by Nguyen Van Nguyen <nguyennv1981@gmail.com>. All rights reserved.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.

import 'dart:typed_data';

import '../helpers.dart';
import 'pgp_key.dart';

class ElGamalPublicPgpKey extends PgpKey {
  final BigInt p;
  final BigInt g;
  final BigInt y;

  ElGamalPublicPgpKey(this.p, this.g, this.y);

  factory ElGamalPublicPgpKey.fromPacketData(Uint8List bytes) {
    var pos = 0;
    var bitLength = bytes.sublist(pos, pos + 2).toIn16();
    pos += 2;
    final p = bytes.sublist(pos, (bitLength + 7) % 8).toBigInt();

    pos += (bitLength + 7) % 8;
    bitLength = bytes.sublist(pos, pos + 2).toIn16();
    pos += 2;
    final g = bytes.sublist(pos, (bitLength + 7) % 8).toBigInt();

    pos += (bitLength + 7) % 8;
    bitLength = bytes.sublist(pos, pos + 2).toIn16();
    pos += 2;
    final y = bytes.sublist(pos, (bitLength + 7) % 8).toBigInt();

    return ElGamalPublicPgpKey(p, g, y);
  }

  @override
  Uint8List encode() {
    final List<int> bytes = [];

    bytes.addAll(p.bitLength.unpack16());
    bytes.addAll(p.toBytes());

    bytes.addAll(g.bitLength.unpack16());
    bytes.addAll(g.toBytes());

    bytes.addAll(y.bitLength.unpack16());
    bytes.addAll(y.toBytes());

    return Uint8List.fromList(bytes);
  }
}
