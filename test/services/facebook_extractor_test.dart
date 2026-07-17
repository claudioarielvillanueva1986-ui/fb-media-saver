// Tests del extractor con HTML de ejemplo fijado (fixtures), sin red real.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fb_media_saver/models/media_item.dart';
import 'package:fb_media_saver/services/facebook_extractor.dart';

String _fixture(String name) =>
    File('test/fixtures/$name').readAsStringSync();

http.Client _clientReturning(String body, {int statusCode = 200}) {
  return MockClient((request) async => http.Response(body, statusCode));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('validación de enlace', () {
    test('rechaza un enlace que no es de Facebook', () async {
      final extractor = FacebookExtractor(client: _clientReturning(''));
      await expectLater(
        extractor.extract('https://www.otrasitio.com/algo'),
        throwsA(isA<FacebookExtractorException>()),
      );
    });

    test('acepta m.facebook.com y fb.watch', () async {
      final extractor = FacebookExtractor(
        client: _clientReturning(_fixture('photo_single.html')),
      );
      final items = await extractor.extract('m.facebook.com/foto/123');
      expect(items, isNotEmpty);

      final extractor2 = FacebookExtractor(
        client: _clientReturning(_fixture('photo_single.html')),
      );
      final items2 = await extractor2.extract('https://fb.watch/abc123/');
      expect(items2, isNotEmpty);
    });
  });

  group('extracción de video', () {
    test('prioriza hd_src_no_ratelimit / sd_src_no_ratelimit', () async {
      final extractor = FacebookExtractor(
        client: _clientReturning(_fixture('video_no_ratelimit.html')),
      );
      final items = await extractor.extract('https://www.facebook.com/watch/?v=1');

      expect(items.length, 2);
      expect(items[0].type, MediaType.video);
      expect(items[0].quality, 'HD');
      expect(items[0].url, contains('hd_norate.mp4'));
      expect(items[0].url, contains('sig=1&tok=3')); // % y & bien decodificados
      expect(items[1].quality, 'SD');
      expect(items[1].url, contains('sd_norate.mp4'));
    });

    test('reconoce browser_native_hd_url / browser_native_sd_url', () async {
      final extractor = FacebookExtractor(
        client: _clientReturning(_fixture('video_native.html')),
      );
      final items = await extractor.extract('https://www.facebook.com/reel/123456');

      expect(items.length, 2);
      expect(items[0].url, contains('hd_clip.mp4'));
      expect(items[1].url, contains('sd_clip.mp4'));
    });

    test('reconoce playable_url_quality_hd / playable_url y deshace \\/ y &', () async {
      final extractor = FacebookExtractor(
        client: _clientReturning(_fixture('video_hd_sd.html')),
      );
      final items = await extractor.extract('https://www.facebook.com/share/v/xyz/');

      expect(items[0].url, startsWith('https://video-scontent'));
      expect(items[0].url, isNot(contains(r'\/')));
      expect(items[1].quality, 'SD');
    });

    test('no duplica cuando HD y SD son la misma URL', () async {
      const body = '''
        <script>{"playable_url_quality_hd":"https:\\/\\/x.test\\/only.mp4","playable_url":"https:\\/\\/x.test\\/only.mp4"}</script>
      ''';
      final extractor = FacebookExtractor(client: _clientReturning(body));
      final items = await extractor.extract('https://www.facebook.com/videos/1');
      expect(items.length, 1);
    });
  });

  group('extracción de fotos', () {
    test('usa og:image cuando no hay video', () async {
      final extractor = FacebookExtractor(
        client: _clientReturning(_fixture('photo_single.html')),
      );
      final items = await extractor.extract('https://www.facebook.com/photo/?fbid=1');

      expect(items.length, 1);
      expect(items.first.type, MediaType.image);
      expect(items.first.url, contains('foto_unica.jpg'));
      expect(items.first.url, isNot(contains('&amp;')));
    });

    test('elige la imagen de mayor resolución entre varias', () async {
      final extractor = FacebookExtractor(
        client: _clientReturning(_fixture('photo_multi_res.html')),
      );
      final items = await extractor.extract('https://www.facebook.com/photo/?fbid=2');

      expect(items.length, 1);
      expect(items.first.url, contains('foto_grande.jpg'));
    });
  });

  group('manejo de errores en español', () {
    test('post privado / muro de login', () async {
      final extractor = FacebookExtractor(
        client: _clientReturning(_fixture('login_wall.html')),
      );
      await expectLater(
        extractor.extract('https://www.facebook.com/algunpost/123'),
        throwsA(
          isA<FacebookExtractorException>().having(
            (e) => e.message,
            'message',
            contains('privado'),
          ),
        ),
      );
    });

    test('sin medios en el post', () async {
      final extractor = FacebookExtractor(
        client: _clientReturning(_fixture('no_media.html')),
      );
      await expectLater(
        extractor.extract('https://www.facebook.com/algunpost/456'),
        throwsA(
          isA<FacebookExtractorException>().having(
            (e) => e.message,
            'message',
            contains('No se encontraron'),
          ),
        ),
      );
    });

    test('rate limit (HTTP 429)', () async {
      final extractor = FacebookExtractor(
        client: _clientReturning('', statusCode: 429),
      );
      await expectLater(
        extractor.extract('https://www.facebook.com/watch/?v=999'),
        throwsA(
          isA<FacebookExtractorException>().having(
            (e) => e.message,
            'message',
            contains('rate limit'),
          ),
        ),
      );
    });
  });

  group('cookies de sesión', () {
    test('incluye el header Cookie cuando se pasan sessionCookies', () async {
      Map<String, String>? capturedHeaders;
      final client = MockClient((request) async {
        capturedHeaders = request.headers;
        return http.Response(_fixture('photo_single.html'), 200);
      });
      final extractor = FacebookExtractor(
        client: client,
        sessionCookies: {'c_user': '123', 'xs': 'abc'},
      );
      await extractor.extract('https://www.facebook.com/photo/?fbid=3');

      expect(capturedHeaders?['Cookie'], 'c_user=123; xs=abc');
    });

    test('usa las cookies guardadas en shared_preferences si no se pasan', () async {
      SharedPreferences.setMockInitialValues({
        FacebookExtractor.cookiesPrefsKey: 'c_user=999; xs=zzz',
      });
      Map<String, String>? capturedHeaders;
      final client = MockClient((request) async {
        capturedHeaders = request.headers;
        return http.Response(_fixture('photo_single.html'), 200);
      });
      final extractor = FacebookExtractor(client: client);
      await extractor.extract('https://www.facebook.com/photo/?fbid=4');

      expect(capturedHeaders?['Cookie'], 'c_user=999; xs=zzz');
    });
  });
}
