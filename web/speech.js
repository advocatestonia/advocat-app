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

    var _advocatRestartCount = 0;

    recognition.onresult = function(event) {
      // Reset restart counter on actual results.
      _advocatRestartCount = 0;
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
        _advocatRestartCount++;
        if (_advocatRestartCount > 3 && window._advocatSpeechResult === '') {
          // Restarted 3+ times with no recognition — language may not be
          // supported or mic is not picking up audio.
          console.warn('advocatSpeech: no recognition after', _advocatRestartCount, 'restarts, stopping');
          window._advocatSpeechError = 'no_recognition';
          window._advocatSpeechActive = false;
          return;
        }
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
// Google TTS: Full fetch + play flow in JS
// ---------------------------------------------------------------------------

/**
 * Full Google TTS flow: fetch audio from Supabase google-tts function and play it.
 * Called from Dart via js_interop. Accepts a JSON string with parameters:
 *   { text, langCode, supabaseUrl, anonKey }
 *
 * Returns a Promise<boolean> — true if audio started playing successfully.
 */
function advocatSpeakGoogleTtsJson(jsonStr) {
  return new Promise(function(resolve) {
    try {
      var params = JSON.parse(jsonStr);
      var text = params.text;
      var langCode = params.langCode || 'en';
      var gender = params.gender || 'female';
      var supabaseUrl = params.supabaseUrl;
      var anonKey = params.anonKey;

      if (!text || !supabaseUrl || !anonKey) {
        console.error('[Advocat TTS] Google TTS: missing required parameters:', Object.keys(params).join(', '));
        resolve(false);
        return;
      }

      var googleTtsUrl = supabaseUrl + '/functions/v1/google-tts';
      console.log('[Advocat TTS] Google TTS: fetching from:', googleTtsUrl,
        'lang:', langCode, 'gender:', gender, 'textLen:', text.length);

      fetch(googleTtsUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + anonKey
        },
        body: JSON.stringify({
          text: text,
          language: langCode,
          gender: gender
        })
      })
      .then(function(response) {
        if (!response.ok) {
          return response.text().then(function(errBody) {
            console.error('[Advocat TTS] Google TTS returned', response.status, ':', errBody);
            throw new Error('Google TTS error: ' + response.status);
          });
        }
        return response.blob();
      })
      .then(function(blob) {
        if (!blob || blob.size === 0) {
          console.error('[Advocat TTS] Google TTS: empty audio blob received');
          resolve(false);
          return;
        }
        console.log('[Advocat TTS] Google TTS: received audio blob, size:', blob.size, 'bytes');
        advocatPlayBlob(blob);
        resolve(true);
      })
      .catch(function(err) {
        console.error('[Advocat TTS] Google TTS fetch/play error:', err.message || err);
        window._advocatTtsSpeaking = false;
        resolve(false);
      });
    } catch (e) {
      console.error('[Advocat TTS] Google TTS JSON parse or setup error:', e);
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

// ---------------------------------------------------------------------------
// Whisper STT (v24.1): MediaRecorder + Supabase whisper-stt Edge Function
// ---------------------------------------------------------------------------
//
// Fallback / iOS-Safari-only STT path.  Records 15s max of webm/opus audio
// via MediaRecorder (supported on iOS 14.5+, all Android Chrome, Desktop),
// base64-encodes it, POSTs to the Supabase whisper-stt function which
// proxies to OpenAI Whisper-1, then exposes the transcribed text via the
// same _advocatSpeechResult/_advocatSpeechActive globals so the Dart poller
// picks it up unchanged.
//
// Voice Activity Detection (VAD): a simple energy-threshold detector fires
// a stop after 1.5s of silence, preventing the user from having to press
// "stop" manually.  Works on every browser that supports AudioContext
// (all evergreen browsers since 2020).

var _advocatWhisperRecorder = null;
var _advocatWhisperChunks = [];
var _advocatWhisperStream = null;
var _advocatWhisperAudioCtx = null;
var _advocatWhisperAnalyser = null;
var _advocatWhisperSilenceTimer = null;
var _advocatWhisperVadRaf = null;
var _advocatWhisperTimeout = null;

function _advocatPickMimeType() {
  var candidates = [
    'audio/webm;codecs=opus',
    'audio/webm',
    'audio/mp4',
    'audio/ogg;codecs=opus',
    'audio/ogg',
  ];
  for (var i = 0; i < candidates.length; i++) {
    if (typeof MediaRecorder !== 'undefined' &&
        MediaRecorder.isTypeSupported &&
        MediaRecorder.isTypeSupported(candidates[i])) {
      return candidates[i];
    }
  }
  return '';
}

/**
 * Start Whisper recording.
 * Params (JSON string):
 *   { supabaseUrl, anonKey, language?, maxSeconds?, silenceMs?, silenceLevel? }
 * Returns Promise<boolean>.
 */
function advocatWhisperStart(jsonStr) {
  return new Promise(function(resolve) {
    try {
      var params = JSON.parse(jsonStr || '{}');
      var supabaseUrl = params.supabaseUrl;
      var anonKey = params.anonKey;
      var language = params.language || null; // null → Whisper auto-detect
      var maxSeconds = params.maxSeconds || 15;
      var silenceMs = params.silenceMs || 1500;
      var silenceLevel = params.silenceLevel || 0.015; // normalised RMS
      if (!supabaseUrl || !anonKey) {
        window._advocatSpeechError = 'whisper_not_configured';
        resolve(false);
        return;
      }

      // Reset global state (shared with Web Speech API path).
      window._advocatSpeechResult = '';
      window._advocatSpeechFinal = false;
      window._advocatSpeechError = '';
      window._advocatSpeechActive = true;
      _advocatWhisperChunks = [];

      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        window._advocatSpeechError = 'no_media_devices';
        window._advocatSpeechActive = false;
        resolve(false);
        return;
      }

      navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        }
      }).then(function(stream) {
        _advocatWhisperStream = stream;
        var mime = _advocatPickMimeType();
        var options = mime ? { mimeType: mime, audioBitsPerSecond: 64000 } : {};
        var recorder;
        try {
          recorder = new MediaRecorder(stream, options);
        } catch (e) {
          // Some browsers reject options; retry without them.
          recorder = new MediaRecorder(stream);
        }
        _advocatWhisperRecorder = recorder;

        recorder.ondataavailable = function(ev) {
          if (ev.data && ev.data.size > 0) {
            _advocatWhisperChunks.push(ev.data);
          }
        };

        recorder.onstop = function() {
          _advocatWhisperTeardownVad();
          if (_advocatWhisperStream) {
            _advocatWhisperStream.getTracks().forEach(function(t) { t.stop(); });
            _advocatWhisperStream = null;
          }
          var blob = new Blob(_advocatWhisperChunks,
            { type: recorder.mimeType || 'audio/webm' });
          _advocatWhisperChunks = [];
          if (!blob || blob.size < 500) {
            // Too short — probably silence / no speech.
            window._advocatSpeechError = 'no_audio';
            window._advocatSpeechActive = false;
            return;
          }
          _advocatWhisperUploadAndDecode(blob, supabaseUrl, anonKey, language);
        };

        recorder.onerror = function(ev) {
          var e = (ev && ev.error && ev.error.name) || 'recorder_error';
          window._advocatSpeechError = e;
          window._advocatSpeechActive = false;
          _advocatWhisperTeardownVad();
        };

        recorder.start(250); // 250ms chunks
        _advocatWhisperSetupVad(stream, silenceMs, silenceLevel);

        // Hard cap: always stop after maxSeconds.
        clearTimeout(_advocatWhisperTimeout);
        _advocatWhisperTimeout = setTimeout(function() {
          try { if (recorder.state === 'recording') recorder.stop(); } catch(_) {}
        }, maxSeconds * 1000);

        resolve(true);
      }).catch(function(err) {
        console.warn('advocatWhisperStart getUserMedia denied:', err && err.name);
        window._advocatSpeechError = 'mic_permission_denied';
        window._advocatSpeechActive = false;
        resolve(false);
      });
    } catch (e) {
      console.error('advocatWhisperStart error:', e);
      window._advocatSpeechError = (e && e.message) || 'whisper_start_failed';
      window._advocatSpeechActive = false;
      resolve(false);
    }
  });
}

function _advocatWhisperTeardownVad() {
  if (_advocatWhisperVadRaf) {
    cancelAnimationFrame(_advocatWhisperVadRaf);
    _advocatWhisperVadRaf = null;
  }
  if (_advocatWhisperSilenceTimer) {
    clearTimeout(_advocatWhisperSilenceTimer);
    _advocatWhisperSilenceTimer = null;
  }
  if (_advocatWhisperTimeout) {
    clearTimeout(_advocatWhisperTimeout);
    _advocatWhisperTimeout = null;
  }
  if (_advocatWhisperAudioCtx) {
    try { _advocatWhisperAudioCtx.close(); } catch(_) {}
    _advocatWhisperAudioCtx = null;
  }
  _advocatWhisperAnalyser = null;
}

function _advocatWhisperSetupVad(stream, silenceMs, silenceLevel) {
  try {
    var AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) return;
    _advocatWhisperAudioCtx = new AudioCtx();
    var source = _advocatWhisperAudioCtx.createMediaStreamSource(stream);
    var analyser = _advocatWhisperAudioCtx.createAnalyser();
    analyser.fftSize = 1024;
    source.connect(analyser);
    _advocatWhisperAnalyser = analyser;

    var buffer = new Float32Array(analyser.fftSize);
    var lastSoundAt = Date.now();
    var hadSpeech = false;
    // Give the user 800ms warmup — don't treat initial silence as "done".
    var warmupUntil = Date.now() + 800;

    function tick() {
      if (!_advocatWhisperAnalyser) return;
      analyser.getFloatTimeDomainData(buffer);
      var sumSq = 0;
      for (var i = 0; i < buffer.length; i++) {
        sumSq += buffer[i] * buffer[i];
      }
      var rms = Math.sqrt(sumSq / buffer.length);
      window._advocatVoiceLevel = rms; // exposed for waveform UI
      var now = Date.now();
      if (rms > silenceLevel) {
        lastSoundAt = now;
        hadSpeech = true;
      } else if (hadSpeech && now > warmupUntil && (now - lastSoundAt) > silenceMs) {
        // User has been silent for silenceMs after speaking → stop.
        try {
          if (_advocatWhisperRecorder && _advocatWhisperRecorder.state === 'recording') {
            _advocatWhisperRecorder.stop();
          }
        } catch(_) {}
        return;
      }
      _advocatWhisperVadRaf = requestAnimationFrame(tick);
    }
    _advocatWhisperVadRaf = requestAnimationFrame(tick);
  } catch (e) {
    console.warn('VAD setup failed:', e);
  }
}

function _advocatWhisperUploadAndDecode(blob, supabaseUrl, anonKey, language) {
  var reader = new FileReader();
  reader.onload = function() {
    try {
      // reader.result is "data:audio/webm;base64,xxxx"
      var dataUrl = reader.result || '';
      var commaIdx = dataUrl.indexOf(',');
      var base64 = commaIdx >= 0 ? dataUrl.substring(commaIdx + 1) : '';
      var body = { audio_base64: base64 };
      if (language) body.language = language;

      fetch(supabaseUrl + '/functions/v1/whisper-stt', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + anonKey
        },
        body: JSON.stringify(body),
      }).then(function(resp) {
        if (!resp.ok) {
          return resp.text().then(function(t) {
            throw new Error('whisper ' + resp.status + ': ' + t);
          });
        }
        return resp.json();
      }).then(function(json) {
        var text = (json && json.text) || '';
        window._advocatSpeechResult = text.trim();
        window._advocatSpeechFinal = true;
        window._advocatSpeechActive = false;
      }).catch(function(err) {
        console.error('Whisper fetch error:', err && err.message);
        window._advocatSpeechError = 'whisper_fetch_failed';
        window._advocatSpeechActive = false;
      });
    } catch (e) {
      console.error('Whisper upload decode error:', e);
      window._advocatSpeechError = 'whisper_upload_failed';
      window._advocatSpeechActive = false;
    }
  };
  reader.onerror = function() {
    window._advocatSpeechError = 'whisper_read_failed';
    window._advocatSpeechActive = false;
  };
  reader.readAsDataURL(blob);
}

function advocatWhisperStop() {
  try {
    if (_advocatWhisperRecorder && _advocatWhisperRecorder.state === 'recording') {
      _advocatWhisperRecorder.stop();
    }
  } catch(_) {}
  _advocatWhisperTeardownVad();
}

function advocatWhisperSupported() {
  return (typeof MediaRecorder !== 'undefined') &&
         !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
}

function advocatGetVoiceLevel() {
  // Returns a number in [0, 1] roughly proportional to current mic volume.
  return typeof window._advocatVoiceLevel === 'number'
    ? window._advocatVoiceLevel : 0;
}

