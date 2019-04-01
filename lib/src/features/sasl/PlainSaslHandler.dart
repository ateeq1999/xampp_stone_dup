import 'dart:async';
import 'dart:convert';

import 'package:cryptoutils/utils.dart';
import 'package:xmppstone/src/Connection.dart';
import 'package:xmppstone/src/elements/XmppAttribute.dart';
import 'package:xmppstone/src/elements/nonzas/Nonza.dart';
import 'package:xmppstone/src/features/sasl/AbstractSaslHandler.dart';

class PlainSaslHandler implements AbstractSaslHandler{
  Connection _connection;
  StreamSubscription<Nonza> subscription;
  var _completer = new Completer<AuthenticationResult>();

  String _password;

  PlainSaslHandler(Connection connection, String password) {
    _password = password;
    _connection = connection;

  }

  Future<AuthenticationResult> start() {
    subscription = _connection.nonzasStream.listen(_parseAnswer);
    sendPlainAuthMessage();
    return _completer.future;
  }

  void _parseAnswer(Nonza nonza) {
    if (nonza.name == 'failure') {
      subscription.cancel();
      _completer.complete(AuthenticationResult(false, "Invalid username or password"));
    } else if (nonza.name == 'success'){
      subscription.cancel();
      _completer.complete(AuthenticationResult(true, ""));
    }
  }
  void sendPlainAuthMessage() {
    var authString = '\u0000' + _connection.fullJid.local + '\u0000' + _password;
    var bytes = utf8.encode(authString);
    var base64 = CryptoUtils.bytesToBase64(bytes);
    Nonza nonza = new Nonza();
    nonza.name = "auth";
    nonza.addAttribute(new XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-sasl'));
    nonza.addAttribute(new XmppAttribute('mechanism', 'PLAIN'));
    nonza.textValue = base64;
    _connection.writeNonza(nonza);
  }
}