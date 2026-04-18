// Web implementation: calls advocatStreamChat() from web/streaming.js
// and polls window._advocatStreamText for incremental text deltas.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Start a streaming chat request via browser fetch() and return a
/// [Stream<String>] of text deltas as they arrive.
///
/// This bypasses Dio entirely — Dio on Flutter Web uses XMLHttpRequest
/// which does NOT support streaming (it buffers the entire response).
Stream<String> webSendMessageStreaming({
  required String url,
  required String bodyJson,
  required String authToken,
  required String apiKey,
}) {
  late StreamController<String> controller;

  controller = StreamController<String>(
    onCancel: () {
      // Nothing to abort — the JS fetch will finish on its own,
      // but we stop polling.
    },
  );

  _pollStream(controller, url, bodyJson, authToken, apiKey);

  return controller.stream;
}

Future<void> _pollStream(
  StreamController<String> controller,
  String url,
  String bodyJson,
  String authToken,
  String apiKey,
) async {
  // Reset JS globals before starting
  globalContext.setProperty('_advocatStreamText'.toJS, ''.toJS);
  globalContext.setProperty('_advocatStreamDone'.toJS, true.toJS);
  globalContext.setProperty('_advocatStreamError'.toJS, ''.toJS);

  // Fire off the JS streaming function (returns a Promise)
  try {
    final promise = globalContext.callMethod(
      'advocatStreamChat'.toJS,
      url.toJS,
      bodyJson.toJS,
      authToken.toJS,
      apiKey.toJS,
    );

    // Don't await the promise — we poll instead for incremental updates.
    // But we DO want to catch errors when it finally resolves.
    final future = (promise as JSPromise).toDart;

    // Poll every 50ms for new text
    String previousText = '';
    while (!controller.isClosed) {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      if (controller.isClosed) break;

      // Check for errors
      final errorVal = globalContext['_advocatStreamError'];
      final error = (errorVal as JSString?)?.toDart ?? '';
      if (error.isNotEmpty) {
        controller.addError(Exception('Streaming error: $error'));
        break;
      }

      // Read current accumulated text
      final textVal = globalContext['_advocatStreamText'];
      final currentText = (textVal as JSString?)?.toDart ?? '';

      // Yield the delta (new text since last poll)
      if (currentText.length > previousText.length) {
        final delta = currentText.substring(previousText.length);
        controller.add(delta);
        previousText = currentText;
      }

      // Check if done
      final doneVal = globalContext['_advocatStreamDone'];
      final done = (doneVal as JSBoolean?)?.toDart ?? false;
      if (done) {
        // One final check for any remaining text
        final finalTextVal = globalContext['_advocatStreamText'];
        final finalText = (finalTextVal as JSString?)?.toDart ?? '';
        if (finalText.length > previousText.length) {
          controller.add(finalText.substring(previousText.length));
        }
        break;
      }
    }

    // Await the promise to catch any unhandled errors
    await future;
  } catch (e) {
    if (!controller.isClosed) {
      controller.addError(e);
    }
  } finally {
    if (!controller.isClosed) {
      await controller.close();
    }
  }
}
