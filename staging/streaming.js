// Streaming fetch helper for Flutter Web
// Uses browser's native fetch() with ReadableStream for real SSE streaming.
// Dio on Flutter Web uses XMLHttpRequest which buffers the entire response.

// Global state for streaming — Dart polls these via JS interop.
window._advocatStreamText = '';
window._advocatStreamDone = true;
window._advocatStreamError = '';

/**
 * Start streaming a Claude API call via browser fetch().
 * Dart calls this, then polls _advocatStreamText / _advocatStreamDone.
 *
 * @param {string} url       - Full endpoint URL
 * @param {string} bodyJson  - JSON-encoded request body
 * @param {string} authToken - Supabase anon key (Bearer token) or empty
 * @param {string} apiKey    - Direct Anthropic API key or empty
 * @returns {Promise<string>} - Resolves with full text when done, or error JSON
 */
async function advocatStreamChat(url, bodyJson, authToken, apiKey) {
  // Reset state
  window._advocatStreamText = '';
  window._advocatStreamDone = false;
  window._advocatStreamError = '';

  const headers = { 'Content-Type': 'application/json' };
  if (authToken) {
    headers['Authorization'] = 'Bearer ' + authToken;
    headers['apikey'] = authToken;
  }
  if (apiKey) {
    headers['x-api-key'] = apiKey;
    headers['anthropic-version'] = '2023-06-01';
  }

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: headers,
      body: bodyJson,
    });

    if (!response.ok) {
      const errorText = await response.text();
      const errMsg = 'HTTP ' + response.status + ': ' + errorText;
      window._advocatStreamError = errMsg;
      window._advocatStreamDone = true;
      return '';
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value, { stream: true });
      buffer += chunk;

      // Process complete SSE lines
      while (buffer.includes('\n')) {
        const lineEnd = buffer.indexOf('\n');
        const line = buffer.substring(0, lineEnd).trim();
        buffer = buffer.substring(lineEnd + 1);

        if (!line.startsWith('data: ')) continue;
        const data = line.substring(6);

        try {
          const parsed = JSON.parse(data);
          if (parsed.type === 'content_block_delta' &&
              parsed.delta && parsed.delta.type === 'text_delta') {
            window._advocatStreamText += parsed.delta.text;
          } else if (parsed.type === 'message_stop') {
            window._advocatStreamDone = true;
          }
        } catch (e) {
          // Skip unparseable SSE lines
        }
      }
    }
  } catch (e) {
    window._advocatStreamError = e.message || String(e);
  }

  window._advocatStreamDone = true;
  return window._advocatStreamText;
}
