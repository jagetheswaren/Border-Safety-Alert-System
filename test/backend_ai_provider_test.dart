import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:border_safety_alert/services/backend_ai_provider.dart';
import 'package:border_safety_alert/services/ai_provider.dart';

const messages = [{'role': 'user', 'content': 'Test question'}];
http.Response reply() => http.Response(jsonEncode({'reply':'Generated test reply','provider':'test-model','source':'ai'}),200);
void main() {
  test('renews an expired locally acquired session once', () async {
    var logins = 0; var chats = 0;
    final provider = BackendAiProvider(baseUrl:'http://127.0.0.1:8000',clientFactory:()=>MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) return http.Response(jsonEncode({'access_token':'test-token-${++logins}'}),200);
      chats++;
      return chats == 2 ? http.Response('{}',401) : reply();
    }));
    expect((await provider.generateChatStream(messages:messages).toList()).join(),contains('Generated test reply'));
    expect((await provider.generateChatStream(messages:messages).toList()).join(),contains('Generated test reply'));
    expect(logins,2); expect(chats,3); expect(provider.status,AiProviderStatus.ready);
  });
  test('never replaces an explicitly supplied user token with development login', () async {
    var logins = 0;
    final provider = BackendAiProvider(baseUrl:'http://127.0.0.1:8000',authToken:'explicit-user-token',clientFactory:()=>MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) logins++;
      return http.Response('{}',401);
    }));
    expect((await provider.generateChatStream(messages:messages).toList()).join(),contains('Authentication Required'));
    expect(logins,0); expect(provider.authToken,'explicit-user-token'); expect(provider.status,AiProviderStatus.error);
  });
  test('never sends bundled development credentials to a remote host', () async {
    var logins = 0;
    final provider = BackendAiProvider(baseUrl:'https://example.test',clientFactory:()=>MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) logins++;
      return http.Response('{}',401);
    }));
    await provider.generateChatStream(messages:messages).toList();
    expect(logins,0);
  });
  test('connection failures mark the gateway offline', () async {
    final provider = BackendAiProvider(baseUrl:'http://127.0.0.1:8000',authToken:'test',clientFactory:()=>MockClient((request) async => throw http.ClientException('test outage')));
    expect((await provider.generateChatStream(messages:messages).toList()).join(),contains('Connection Issue'));
    expect(provider.status,AiProviderStatus.offline);
  });
  test('canceled request does not emit a late reply', () async {
    final response = Completer<http.Response>();
    final provider = BackendAiProvider(baseUrl:'http://127.0.0.1:8000',authToken:'test',clientFactory:()=>MockClient((request)=>response.future));
    final result = provider.generateChatStream(messages:messages).toList();
    await Future<void>.delayed(Duration.zero);
    provider.cancel(); response.complete(reply());
    expect(await result,isEmpty);
  });
}
