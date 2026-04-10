// Native Web Speech API bridge for Flutter web.
// Called from Dart via js_interop when the speech_to_text plugin fails.

var _advocatRecognition = null;
var _advocatMicPermissionGranted = false;
// Whether the user explicitly requested to stop (vs browser auto-stopping).
var _advocatUserStopped = false;
// Accumulated final transcript across all recognition results.
var _advocatAccumulatedTranscript = '';

/**
 * Detect if running on a mobile browser.
 */
function _advocatIsMobile() {
  return /Android|iPhone|iPad|iPod|Mobile|webOS|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
}

/**
 * Detect iOS Safari (Web Speech API is NOT supported there).
 */
function _advocatIsIOSSafari() {
  var ua = navigator.userAgent;
  var isIOS = /iPad|iPhone|iPod/.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  var isSafari = /^((?!chrome|android|CriOS|FxiOS).)*safari/i.test(ua);
  return isIOS && isSafari;
}

/**
 * Request microphone permission explicitly.
 * On mobile browsers, calling getUserMedia before SpeechRecognition
 * ensures the permission prompt fires reliably.
 * Returns a Promise that resolves to true/false.
 */
function advocatRequestMicPermission() {
  if (_advocatMicPermissionGranted) {
    return Promise.resolve(true);
  }
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
    return Promise.resolve(false);
  }
  return navigator.mediaDevices.getUserMedia({ audio: true })
    .then(function(stream) {
      // Stop the tracks immediately — we just needed the permission.
      stream.getTracks().forEach(function(track) { track.stop(); });
      _advocatMicPermissionGranted = true;
      return true;
    })
    .catch(function(err) {
      console.warn('advocatRequestMicPermission denied:', err.name, err.message);
      window._advocatSpeechError = 'mic_permission_denied';
      return false;
    });
}

function advocatStartSpeech(lang) {
  // iOS Safari does not support Web Speech API at all.
  if (_advocatIsIOSSafari()) {
    window._advocatSpeechError = 'ios_safari_not_supported';
    return false;
  }

  var SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!SpeechRecognition) {
    window._advocatSpeechError = 'not_supported';
    return false;
  }

  try {
    advocatStopSpeech(); // Stop any previous session.

    var recognition = new SpeechRecognition();
    recognition.lang = lang || 'en-US';

    // CONTINUOUS MODE: keep listening until user explicitly stops.
    recognition.continuous = true;
    recognition.interimResults = true;
    recognition.maxAlternatives = 1;

    // Reset state.
    _advocatUserStopped = false;
    _advocatAccumulatedTranscript = '';
    window._advocatSpeechResult = '';
    window._advocatSpeechFinal = false;
    window._advocatSpeechError = '';
    window._advocatSpeechActive = true;

    recognition.onresult = function(event) {
      // Build full transcript from all results (final + interim).
      var finalPart = '';
      var interimPart = '';
      for (var i = 0; i < event.results.length; i++) {
        if (event.results[i].isFinal) {
          finalPart += event.results[i][0].transcript;
        } else {
          interimPart += event.results[i][0].transcript;
        }
      }
      // Expose accumulated final + current interim to Dart.
      window._advocatSpeechResult = (finalPart + interimPart).trim();
      window._advocatSpeechFinal = false; // Never signal final — user decides when to stop.
    };

    recognition.onend = function() {
      // If user did NOT explicitly stop, auto-restart (browser sometimes
      // stops recognition after silence or network hiccup).
      if (!_advocatUserStopped && window._advocatSpeechActive) {
        try {
          recognition.start();
          return;
        } catch (e) {
          // Could not restart — fall through to deactivate.
          console.warn('advocatSpeech: auto-restart failed:', e.message);
        }
      }
      window._advocatSpeechActive = false;
    };

    recognition.onerror = function(event) {
      var err = event.error || 'unknown';
      // "no-speech" and "aborted" are not fatal — keep listening.
      if (err === 'no-speech' || err === 'aborted') {
        // Browser fires these on silence timeout; onend will auto-restart.
        return;
      }
      // Provide better messages for mobile-specific errors.
      if (err === 'not-allowed') {
        window._advocatSpeechError = 'mic_permission_denied';
      } else if (err === 'network') {
        window._advocatSpeechError = 'network_error';
      } else if (err === 'service-not-allowed') {
        window._advocatSpeechError = 'service_not_allowed';
      } else {
        window._advocatSpeechError = err;
      }
      _advocatUserStopped = true; // Prevent auto-restart on real errors.
      window._advocatSpeechActive = false;
    };

    recognition.start();
    _advocatRecognition = recognition;
    return true;
  } catch (e) {
    window._advocatSpeechError = e.message || 'start_failed';
    window._advocatSpeechActive = false;
    return false;
  }
}

function advocatStopSpeech() {
  _advocatUserStopped = true; // Prevent auto-restart in onend.
  if (_advocatRecognition) {
    try { _advocatRecognition.stop(); } catch(e) {}
    _advocatRecognition = null;
  }
  window._advocatSpeechActive = false;
}

function advocatIsSpeechSupported() {
  // iOS Safari does not support Web Speech API.
  if (_advocatIsIOSSafari()) {
    return false;
  }
  return !!(window.SpeechRecognition || window.webkitSpeechRecognition);
}

// ---------------------------------------------------------------------------
// ElevenLabs TTS Audio Playback
// ---------------------------------------------------------------------------

// Reference to the currently playing audio element.
window._advocatCurrentAudio = null;
// Whether ElevenLabs TTS is currently speaking.
window._advocatTtsSpeaking = false;

/**
 * Play an audio blob (MP3) through an HTML5 Audio element.
 * Sets window._advocatTtsSpeaking while playing.
 * Volume is always set to 1.0 for consistent output.
 */
function advocatPlayBlob(blob) {
  advocatStopAudio();
  var url = URL.createObjectURL(blob);
  var audio = new Audio(url);
  audio.volume = 1.0;
  window._advocatCurrentAudio = audio;
  window._advocatTtsSpeaking = true;
  audio.onended = function() {
    console.log('[Advocat TTS] Audio playback ended');
    URL.revokeObjectURL(url);
    window._advocatCurrentAudio = null;
    window._advocatTtsSpeaking = false;
  };
  audio.onerror = function(e) {
    console.error('[Advocat TTS] Audio playback error:', e.type || e);
    URL.revokeObjectURL(url);
    window._advocatCurrentAudio = null;
    window._advocatTtsSpeaking = false;
  };
  audio.play().catch(function(err) {
    console.error('[Advocat TTS] Audio play() rejected:', err.message || err);
    window._advocatCurrentAudio = null;
    window._advocatTtsSpeaking = false;
  });
}

/**
 * Stop any currently playing ElevenLabs audio.
 */
function advocatStopAudio() {
  if (window._advocatCurrentAudio) {
    try {
      window._advocatCurrentAudio.pause();
      window._advocatCurrentAudio.currentTime = 0;
      console.log('[Advocat TTS] Audio stopped');
    } catch(e) {
      console.warn('[Advocat TTS] Error stopping audio:', e);
    }
    window._advocatCurrentAudio = null;
  }
  window._advocatTtsSpeaking = false;
}

/**
 * Returns true if ElevenLabs TTS audio is currently playing.
 */
function advocatIsTtsSpeaking() {
  return !!window._advocatTtsSpeaking;
}

/**
 * Decode a base64-encoded MP3 string and play it as audio.
 * This avoids the need to pass Blob objects across the JS-Dart boundary.
 */
function advocatPlayBase64Audio(base64Str) {
  try {
    var binaryStr = atob(base64Str);
    var len = binaryStr.length;
    var bytes = new Uint8Array(len);
    for (var i = 0; i < len; i++) {
      bytes[i] = binaryStr.charCodeAt(i);
    }
    var blob = new Blob([bytes], { type: 'audio/mpeg' });
    advocatPlayBlob(blob);
  } catch (e) {
    console.error('[Advocat TTS] advocatPlayBase64Audio error:', e);
    window._advocatTtsSpeaking = false;
  }
}

// ---------------------------------------------------------------------------
// ElevenLabs TTS: Full fetch + play flow in JS
// ---------------------------------------------------------------------------

/**
 * Full ElevenLabs TTS flow: fetch audio from Supabase tts-proxy and play it.
 * Called from Dart via js_interop. Accepts a JSON string with parameters:
 *   { text, voiceId, langCode, supabaseUrl, anonKey }
 *
 * Returns a Promise<boolean> — true if audio started playing successfully.
 */
function advocatSpeakElevenLabsJson(jsonStr) {
  return new Promise(function(resolve) {
    try {
      var params = JSON.parse(jsonStr);
      var text = params.text;
      var voiceId = params.voiceId;
      var langCode = params.langCode;
      var supabaseUrl = params.supabaseUrl;
      var anonKey = params.anonKey;

      if (!text || !voiceId || !supabaseUrl || !anonKey) {
        console.error('[Advocat TTS] Missing required parameters:', Object.keys(params).join(', '));
        resolve(false);
        return;
      }

      var proxyUrl = supabaseUrl + '/functions/v1/tts-proxy';
      console.log('[Advocat TTS] Fetching from:', proxyUrl,
        'voice:', voiceId, 'lang:', langCode, 'textLen:', text.length);

      fetch(proxyUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + anonKey
        },
        body: JSON.stringify({
          text: text,
          voice_id: voiceId,
          language_code: langCode
        })
      })
      .then(function(response) {
        if (!response.ok) {
          return response.text().then(function(errBody) {
            console.error('[Advocat TTS] Proxy returned', response.status, ':', errBody);
            throw new Error('TTS proxy error: ' + response.status);
          });
        }
        return response.blob();
      })
      .then(function(blob) {
        if (!blob || blob.size === 0) {
          console.error('[Advocat TTS] Empty audio blob received');
          resolve(false);
          return;
        }
        console.log('[Advocat TTS] Received audio blob, size:', blob.size, 'bytes');
        advocatPlayBlob(blob);
        resolve(true);
      })
      .catch(function(err) {
        console.error('[Advocat TTS] Fetch/play error:', err.message || err);
        window._advocatTtsSpeaking = false;
        resolve(false);
      });
    } catch (e) {
      console.error('[Advocat TTS] JSON parse or setup error:', e);
      window._advocatTtsSpeaking = false;
      resolve(false);
    }
  });
}

// ---------------------------------------------------------------------------
// Audio Unlock: ensure AudioContext is unlocked on first user interaction
// ---------------------------------------------------------------------------

(function() {
  var _advocatAudioUnlocked = false;

  function _advocatUnlockAudio() {
    if (_advocatAudioUnlocked) return;
    _advocatAudioUnlocked = true;

    // Create a silent AudioContext and resume it (required by Chrome/Safari).
    try {
      var AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) {
        var ctx = new AudioCtx();
        // Play a silent buffer to unlock.
        var buffer = ctx.createBuffer(1, 1, 22050);
        var source = ctx.createBufferSource();
        source.buffer = buffer;
        source.connect(ctx.destination);
        source.start(0);
        if (ctx.state === 'suspended') {
          ctx.resume();
        }
        console.log('[Advocat TTS] Audio context unlocked');
      }
    } catch (e) {
      console.warn('[Advocat TTS] Audio unlock failed:', e);
    }

    // Also try to play+pause a silent HTML5 Audio element.
    try {
      var silentAudio = new Audio('data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAIA+AAACABAAZGF0YQAAAAA=');
      silentAudio.volume = 0;
      silentAudio.play().then(function() {
        silentAudio.pause();
      }).catch(function() {});
    } catch (e) {}

    // Remove listeners after unlock.
    ['click', 'touchstart', 'touchend', 'keydown'].forEach(function(evt) {
      document.removeEventListener(evt, _advocatUnlockAudio, { capture: true });
    });
  }

  // Register unlock on all user interaction events.
  ['click', 'touchstart', 'touchend', 'keydown'].forEach(function(evt) {
    document.addEventListener(evt, _advocatUnlockAudio, { capture: true, passive: true });
  });
})();
