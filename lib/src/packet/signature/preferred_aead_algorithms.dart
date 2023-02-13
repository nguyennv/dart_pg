// Copyright 2022-present by Nguyen Van Nguyen <nguyennv1981@gmail.com>. All rights reserved.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.

import 'dart:typed_data';

import '../../enums.dart';
import '../signature_subpacket.dart';

class PreferredAEADAlgorithms extends SignatureSubpacket {
  PreferredAEADAlgorithms(Uint8List data, {super.critical, super.isLongLength})
      : super(SignatureSubpacketType.preferredAEADAlgorithms, data);

  List<int> get preferences => data.toList();
}