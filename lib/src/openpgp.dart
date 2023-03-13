// Copyright 2022-present by Nguyen Van Nguyen <nguyennv1981@gmail.com>. All rights reserved.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.

import 'dart:typed_data';

import 'enum/compression_algorithm.dart';
import 'enum/curve_info.dart';
import 'enum/dh_key_size.dart';
import 'enum/key_type.dart';
import 'enum/rsa_key_size.dart';
import 'enum/symmetric_algorithm.dart';

import 'type/cleartext_message.dart';
import 'type/message.dart';
import 'type/private_key.dart';
import 'type/public_key.dart';
import 'type/signature.dart';
import 'type/signed_message.dart';

export 'type/cleartext_message.dart';
export 'type/message.dart';
export 'type/private_key.dart';
export 'type/public_key.dart';
export 'type/signature.dart';
export 'type/signed_message.dart';

/// Export high level API for Dart developers.
class OpenPGP {
  static const version = 'Dart PG v1.0.0';

  static const comment = 'Dart Privacy Guard';

  static const showVersion = true;

  static const showComment = false;

  static const checksumRequired = true;

  static const allowUnauthenticatedMessages = false;

  /// Public key packet version
  static const keyVersion = 4;

  /// Public key encrypted session key packet version
  static const pkeskVersion = 3;

  /// Symmetrically encrypted session key packet version
  static const skeskVersion = 4;

  /// Encrypted integrity protected data packet version
  static const seipVersion = 1;

  /// Default zip/zlib compression level, between 1 and 9
  static const deflateLevel = 6;

  /// RSA public exponent
  static const rsaPublicExponent = 65537;

  /// Generate a new OpenPGP key pair. Supports RSA and ECC keys.
  /// By default, primary and subkeys will be of same type.
  /// The generated primary key will have signing capabilities.
  /// By default, one subkey with encryption capabilities is also generated.
  static Future<PrivateKey> generateKey(
    final Iterable<String> userIDs,
    final String passphrase, {
    final KeyType type = KeyType.rsa,
    final RSAKeySize rsaKeySize = RSAKeySize.s4096,
    final DHKeySize dhKeySize = DHKeySize.l2048n224,
    final CurveInfo curve = CurveInfo.secp521r1,
    final int keyExpirationTime = 0,
    final String? subkeyPassphrase,
    final DateTime? date,
  }) async =>
      PrivateKey.generate(
        userIDs,
        passphrase,
        type: type,
        rsaKeySize: rsaKeySize,
        dhKeySize: dhKeySize,
        curve: curve,
        keyExpirationTime: keyExpirationTime,
        subkeyPassphrase: subkeyPassphrase,
        date: date,
      );

  /// Read an armored & unlock OpenPGP private key with the given passphrase.
  static Future<PrivateKey> decryptPrivateKey(
    final String armored,
    final String passphrase, [
    final Iterable<String> subkeyPassphrases = const [],
  ]) async =>
      PrivateKey.fromArmored(armored).decrypt(passphrase, subkeyPassphrases);

  /// Read an armored OpenPGP private key and returns a PrivateKey object
  static Future<PrivateKey> readPrivateKey(final String armored) async => PrivateKey.fromArmored(armored);

  /// Read an armored OpenPGP public key and returns a PublicKey object
  static Future<PublicKey> readPublicKey(final String armored) async => PublicKey.fromArmored(armored);

  /// Sign a cleartext message.
  static Future<SignedMessage> sign(
    final String text,
    final Iterable<PrivateKey> signingKeys, {
    final DateTime? date,
  }) async =>
      SignedMessage.signCleartext(text, signingKeys, date: date);

  /// Sign a cleartext message & return detached signature
  static Future<Signature> signDetached(
    final String text,
    final Iterable<PrivateKey> signingKeys, {
    final DateTime? date,
  }) async =>
      SignedMessage.signCleartext(text, signingKeys, date: date).signature;

  /// Verify signatures of cleartext signed message
  /// Return signed message with verifications
  static Future<SignedMessage> verify(
    final String armored,
    final Iterable<PublicKey> verificationKeys, {
    final DateTime? date,
  }) async =>
      SignedMessage.fromArmored(armored).verify(verificationKeys, date: date);

  /// Verify detached signatures of cleartext message
  /// Returns cleartext message with verifications
  static Future<CleartextMessage> verifyDetached(
    final String text,
    final String armored,
    final Iterable<PublicKey> verificationKeys, {
    final DateTime? date,
  }) async =>
      CleartextMessage(text).verifySignature(Signature.fromArmored(armored), verificationKeys, date: date);

  /// Read an armored OpenPGP signature and returns a Signature object
  static Future<Signature> readSignature(final String armored) async => Signature.fromArmored(armored);

  /// Read an armored OpenPGP signed message and returns a SignedMessage object
  static Future<SignedMessage> readSignedMessage(final String armored) async => SignedMessage.fromArmored(armored);

  /// Read an armored OpenPGP message and returns a Message object
  static Future<Message> readMessage(final String armored) async => Message.fromArmored(armored);

  /// Create new message object from text
  static Future<Message> createTextMessage(
    final String text, {
    final DateTime? time,
  }) async =>
      Message.createTextMessage(text, time: time);

  /// Create new message object from binary data.
  static Future<Message> createBinaryMessage(
    final Uint8List data, {
    final String filename = '',
    final DateTime? time,
  }) async =>
      Message.createBinaryMessage(data, filename: filename, time: time);

  /// Encrypt a message using public keys, passwords or both at once.
  /// At least one of `encryptionKeys`, `passwords`must be specified.
  /// If signing keys are specified, those will be used to sign the message.
  static Future<Message> encrypt(
    final Message message, {
    final Iterable<PublicKey> encryptionKeys = const [],
    final Iterable<PrivateKey> signingKeys = const [],
    final Iterable<String> passwords = const [],
    final SymmetricAlgorithm sessionKeySymmetric = SymmetricAlgorithm.aes256,
    final SymmetricAlgorithm encryptionKeySymmetric = SymmetricAlgorithm.aes256,
    final CompressionAlgorithm compression = CompressionAlgorithm.uncompressed,
    final DateTime? date,
  }) async =>
      (signingKeys.isNotEmpty)
          ? message.sign(signingKeys, date: date).compress(compression).encrypt(
                encryptionKeys: encryptionKeys,
                passwords: passwords,
                sessionKeySymmetric: sessionKeySymmetric,
                encryptionKeySymmetric: encryptionKeySymmetric,
              )
          : message.compress(compression).encrypt(
                encryptionKeys: encryptionKeys,
                passwords: passwords,
                sessionKeySymmetric: sessionKeySymmetric,
                encryptionKeySymmetric: encryptionKeySymmetric,
              );

  /// Decrypt a message with the user's private key, or a password.
  /// One of `decryptionKeys` or `passwords` must be specified
  /// return object containing decrypted message with verifications
  static Future<Message> decrypt(
    final Message message, {
    final Iterable<PrivateKey> decryptionKeys = const [],
    final Iterable<PublicKey> verificationKeys = const [],
    final Iterable<String> passwords = const [],
    final bool allowUnauthenticatedMessages = OpenPGP.allowUnauthenticatedMessages,
    final DateTime? date,
  }) async =>
      (verificationKeys.isNotEmpty)
          ? message
              .decrypt(
                decryptionKeys: decryptionKeys,
                passwords: passwords,
                allowUnauthenticatedMessages: allowUnauthenticatedMessages,
              )
              .verify(verificationKeys, date: date)
          : message.decrypt(
              decryptionKeys: decryptionKeys,
              passwords: passwords,
              allowUnauthenticatedMessages: allowUnauthenticatedMessages,
            );
}
