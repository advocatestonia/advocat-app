// Native Web Speech API bridge for Flutter web.
// Called from Dart via js_interop when the speech_to_text plugin fails.

var _advocatRecognition = null;
var _advocatMicPermissionGranted = false;

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

    // On mobile, use simpler settings for reliability.
    var isMobile = _advocatIsMobile();
    recognition.interimResults = !isMobile;
    recognition.continuous = false;
    recognition.maxAlternatives = 1;

    // Reset state.
    window._advocatSpeechResult = '';
    window._advocatSpeechFinal = false;
    window._advocatSpeechError = '';
    window._advocatSpeechActive = true;

    recognition.onresult = function(event) {
      var last = event.results[event.results.length - 1];
      window._advocatSpeechResult = last[0].transcript;
      window._advocatSpeechFinal = last.isFinal;
    };

    recognition.onend = function() {
      window._advocatSpeechActive = false;
    };

    recognition.onerror = function(event) {
      var err = event.error || 'unknown';
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
 */
function advocatPlayBlob(blob) {
  advocatStopAudio();
  var url = URL.createObjectURL(blob);
  var audio = new Audio(url);
  window._advocatCurrentAudio = audio;
  window._advocatTtsSpeaking = true;
  audio.onended = function() {
    URL.revokeObjectURL(url);
    window._advocatCurrentAudio = null;
    window._advocatTtsSpeaking = false;
  };
  audio.onerror = function() {
    URL.revokeObjectURL(url);
    window._advocatCurrentAudio = null;
    window._advocatTtsSpeaking = false;
  };
  audio.play().catch(function() {
    window._advocatCurrentAudio = null;
    window._advocatTtsSpeaking = false;
  });
}

/**
 * Stop any currently playing ElevenLabs audio.
 */
function advocatStopAudio() {
  if (window._advocatCurrentAudio) {
    try { window._advocatCurrentAudio.pause(); } catch(e) {}
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
    console.error('advocatPlayBase64Audio error:', e);
    window._advocatTtsSpeaking = false;
  }
}
