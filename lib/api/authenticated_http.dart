import 'dart:convert';

import 'package:http/http.dart' as native;
import 'package:my_app/services/auth_service.dart';
export 'package:http/http.dart' show Client, ClientException, Response;

native.Client authenticatedClient({
  native.Client? transport,
  AuthService? auth,
}) => AuthenticatedClient(transport: transport, auth: auth);

class AuthenticatedClient extends native.BaseClient {
  AuthenticatedClient({native.Client? transport, AuthService? auth})
    : _transport = transport ?? native.Client(),
      _auth = auth ?? AuthService.instance;
  final native.Client _transport;
  final AuthService _auth;

  @override
  Future<native.StreamedResponse> send(native.BaseRequest request) async {
    if (request.url.origin != _auth.baseUri.origin) {
      throw const AuthException('untrusted_api_origin');
    }
    await _auth.initialize();
    final identity = _auth.userId;
    final generation = _auth.generation;
    final token = _auth.accessToken;
    if (identity == null || token == null) {
      throw const AuthException('session_expired');
    }
    final bytes = await request.finalize().toBytes();
    Future<native.StreamedResponse> dispatch(String bearer) {
      final copy =
          native.Request(request.method, request.url)
            ..headers.addAll(request.headers)
            ..headers['Authorization'] = 'Bearer $bearer'
            ..followRedirects = false
            ..bodyBytes = bytes;
      return _transport.send(copy);
    }

    var response = await dispatch(token);
    if (response.statusCode == 401) {
      await response.stream.drain<void>();
      if (!await _auth.refresh(expectedAccess: token) ||
          _auth.userId != identity ||
          _auth.generation != generation) {
        throw const AuthException('session_expired');
      }
      response = await dispatch(_auth.accessToken!);
      if (response.statusCode == 401) {
        await response.stream.drain<void>();
        await _auth.expire();
        throw const AuthException('session_expired');
      }
    }
    final responseBytes = await response.stream.toBytes();
    if (_auth.userId != identity || _auth.generation != generation) {
      throw const AuthException('session_expired');
    }
    return native.StreamedResponse(
      Stream.value(responseBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }

  @override
  void close() => _transport.close();
}

Future<native.Response> _withClient(
  Future<native.Response> Function(native.Client) call,
) async {
  final client = authenticatedClient();
  try {
    return await call(client);
  } finally {
    client.close();
  }
}

Future<native.Response> get(Uri url, {Map<String, String>? headers}) =>
    _withClient((client) => client.get(url, headers: headers));
Future<native.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _withClient(
  (client) =>
      client.post(url, headers: headers, body: body, encoding: encoding),
);
Future<native.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _withClient(
  (client) => client.put(url, headers: headers, body: body, encoding: encoding),
);
Future<native.Response> delete(Uri url, {Map<String, String>? headers}) =>
    _withClient((client) => client.delete(url, headers: headers));
