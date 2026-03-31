/**
 * ADVOCAT Live Call Assistant — Enhanced Intelligence Layer
 * Real-time call transcription with AI legal advice
 *
 * Supports:
 *   - Deepgram Nova-3 (WebSocket, best quality, diarization)
 *   - Demo Mode (Web Speech API, free, no key needed)
 *   - Claude AI legal analysis with smart pause detection
 *   - Speaker diarization with color labels
 *   - Urgency detection for deadlines and legal terms
 *   - Auto-translation of transcript segments
 *   - Legal term glossary with tooltips
 *   - Smart key points extraction with timestamps
 *   - Conversation summary generation
 *   - Context-aware AI prompts
 *   - Quick response templates
 *   - Enhanced export (TXT + HTML)
 *   - Audio quality indicator
 *   - WebSocket reconnection resilience
 */

// ============================================
// State
// ============================================
const state = {
    isListening: false,
    mode: 'deepgram',        // 'deepgram' | 'demo'
    language: 'fi',
    userLanguage: 'ru',      // language for AI responses
    transcript: [],          // { time, text, speaker, isFinal, confidence }
    fullTranscriptText: '',  // accumulated final text
    keyPoints: [],           // { time, text }
    timerInterval: null,
    timerSeconds: 0,
    aiInterval: null,
    lastAiRequestAt: 0,
    lastTranscriptLen: 0,
    // Audio
    stream: null,
    mediaRecorder: null,
    audioContext: null,
    analyser: null,
    volumeAnimFrame: null,
    // Deepgram
    dgSocket: null,
    // Demo mode (Web Speech API)
    recognition: null,
    // Smart pause detection
    pauseTimer: null,
    lastSpeechAt: 0,
    pendingSegments: [],         // segments accumulated since last AI call
    currentTopicSegments: [],    // segments in current topic
    // Speaker diarization
    speakerWordCounts: {},       // { speakerId: wordCount }
    speakerLabels: {},           // { speakerId: 'Lawyer' | 'You' }
    // Audio quality tracking
    recentConfidences: [],       // last N confidence scores
    audioQuality: 'good',       // 'good' | 'fair' | 'poor'
    // Translation batching
    pendingTranslations: [],     // segments awaiting translation
    translationTimer: null,
    // Context
    callContext: '',             // user-provided context before call
    // Reconnection
    reconnectAttempts: 0,
    maxReconnectAttempts: 10,
    transcriptBuffer: [],        // buffer during reconnection
    isReconnecting: false,
    // Summary
    aiSummary: '',
    aiResponses: [],             // all AI responses for export
};

// ============================================
// Legal Term Glossary — Finnish legal terms
// ============================================
const LEGAL_GLOSSARY = {
    // Finnish legal terms
    'oikeusapu': { fi: 'Oikeusapu', en: 'Legal aid', ru: 'Юридическая помощь', desc_en: 'Free or subsidized legal assistance provided by the state', desc_ru: 'Бесплатная или субсидированная юридическая помощь от государства' },
    'oikeusaputoimisto': { fi: 'Oikeusaputoimisto', en: 'Legal aid office', ru: 'Бюро правовой помощи', desc_en: 'Government office providing free legal aid', desc_ru: 'Государственное бюро, предоставляющее бесплатную правовую помощь' },
    'hallinto-oikeus': { fi: 'Hallinto-oikeus', en: 'Administrative court', ru: 'Административный суд', desc_en: 'Court handling appeals against government decisions', desc_ru: 'Суд, рассматривающий жалобы на решения государственных органов' },
    'korkein hallinto-oikeus': { fi: 'Korkein hallinto-oikeus', en: 'Supreme Administrative Court', ru: 'Верховный административный суд', desc_en: 'Highest court for administrative matters in Finland', desc_ru: 'Высший суд по административным делам в Финляндии' },
    'syyteharkinta': { fi: 'Syyteharkinta', en: 'Prosecution consideration', ru: 'Рассмотрение обвинения', desc_en: 'Prosecutor\'s assessment whether to press charges', desc_ru: 'Оценка прокурором, стоит ли предъявлять обвинение' },
    'käännyttäminen': { fi: 'Käännyttäminen', en: 'Deportation/Refusal of entry', ru: 'Депортация/Отказ во въезде', desc_en: 'Removal of a person from the country or refusal to allow entry', desc_ru: 'Удаление лица из страны или отказ в разрешении на въезд' },
    'valitus': { fi: 'Valitus', en: 'Appeal', ru: 'Жалоба/Апелляция', desc_en: 'Formal complaint against a legal decision', desc_ru: 'Официальная жалоба на юридическое решение' },
    'valituslupa': { fi: 'Valituslupa', en: 'Leave to appeal', ru: 'Разрешение на апелляцию', desc_en: 'Permission required to appeal to a higher court', desc_ru: 'Разрешение, необходимое для подачи апелляции в вышестоящий суд' },
    'oleskelulupa': { fi: 'Oleskelulupa', en: 'Residence permit', ru: 'Вид на жительство', desc_en: 'Official permission to reside in Finland', desc_ru: 'Официальное разрешение на проживание в Финляндии' },
    'turvapaikka': { fi: 'Turvapaikka', en: 'Asylum', ru: 'Убежище', desc_en: 'Protection granted to refugees', desc_ru: 'Защита, предоставляемая беженцам' },
    'migri': { fi: 'Migri (Maahanmuuttovirasto)', en: 'Finnish Immigration Service', ru: 'Миграционная служба Финляндии', desc_en: 'Finnish authority handling immigration and asylum', desc_ru: 'Финский орган, занимающийся иммиграцией и убежищем' },
    'maahanmuuttovirasto': { fi: 'Maahanmuuttovirasto', en: 'Finnish Immigration Service', ru: 'Миграционная служба Финляндии', desc_en: 'Finnish authority handling immigration and asylum', desc_ru: 'Финский орган, занимающийся иммиграцией и убежищем' },
    'ulkomaalaisrekisteri': { fi: 'Ulkomaalaisrekisteri', en: 'Register of Aliens', ru: 'Реестр иностранцев', desc_en: 'Database of foreign nationals in Finland', desc_ru: 'База данных иностранных граждан в Финляндии' },
    'maahantulokielto': { fi: 'Maahantulokielto', en: 'Entry ban', ru: 'Запрет на въезд', desc_en: 'Prohibition from entering Finland/Schengen area', desc_ru: 'Запрет на въезд в Финляндию/Шенгенскую зону' },
    'täytäntöönpanokielto': { fi: 'Täytäntöönpanokielto', en: 'Prohibition of enforcement', ru: 'Запрет на исполнение', desc_en: 'Court order stopping enforcement of a decision', desc_ru: 'Судебный приказ о приостановке исполнения решения' },
    'käräjäoikeus': { fi: 'Käräjäoikeus', en: 'District court', ru: 'Районный суд', desc_en: 'Court of first instance for most cases', desc_ru: 'Суд первой инстанции для большинства дел' },
    'hovioikeus': { fi: 'Hovioikeus', en: 'Court of Appeal', ru: 'Апелляционный суд', desc_en: 'Second level court handling appeals', desc_ru: 'Суд второй инстанции, рассматривающий апелляции' },
    'asianajaja': { fi: 'Asianajaja', en: 'Attorney/Lawyer', ru: 'Адвокат', desc_en: 'Licensed legal professional', desc_ru: 'Лицензированный юрист' },
    'avustaja': { fi: 'Avustaja', en: 'Legal counsel/Assistant', ru: 'Юридический помощник', desc_en: 'Legal assistant or public defender', desc_ru: 'Юридический помощник или государственный защитник' },
    'päätös': { fi: 'Päätös', en: 'Decision', ru: 'Решение', desc_en: 'Official administrative or court decision', desc_ru: 'Официальное административное или судебное решение' },
    'määräaika': { fi: 'Määräaika', en: 'Deadline', ru: 'Срок/Крайний срок', desc_en: 'Time limit for filing appeals or documents', desc_ru: 'Срок подачи апелляций или документов' },
    'muutoksenhaku': { fi: 'Muutoksenhaku', en: 'Appeal process', ru: 'Процедура обжалования', desc_en: 'Process of challenging a decision', desc_ru: 'Процедура оспаривания решения' },
    'kuuleminen': { fi: 'Kuuleminen', en: 'Hearing', ru: 'Слушание', desc_en: 'Official hearing where parties present their case', desc_ru: 'Официальное слушание, где стороны представляют свою позицию' },
    'suullinen käsittely': { fi: 'Suullinen käsittely', en: 'Oral hearing', ru: 'Устное слушание', desc_en: 'In-person court hearing', desc_ru: 'Личное судебное слушание' },
    'kirjallinen käsittely': { fi: 'Kirjallinen käsittely', en: 'Written proceedings', ru: 'Письменное производство', desc_en: 'Court proceedings based on written submissions', desc_ru: 'Судебное производство на основе письменных заявлений' },
    'poliisi': { fi: 'Poliisi', en: 'Police', ru: 'Полиция', desc_en: 'Law enforcement authority', desc_ru: 'Правоохранительный орган' },
    'säilöönotto': { fi: 'Säilöönotto', en: 'Detention', ru: 'Задержание', desc_en: 'Holding a person in custody', desc_ru: 'Содержание лица под стражей' },
    'karkottaminen': { fi: 'Karkottaminen', en: 'Expulsion/Deportation', ru: 'Высылка/Депортация', desc_en: 'Forced removal from the country', desc_ru: 'Принудительное удаление из страны' },
    'viimeinen päivä': { fi: 'Viimeinen päivä', en: 'Last day/Deadline', ru: 'Последний день/Крайний срок', desc_en: 'Final date for action', desc_ru: 'Последняя дата для действия' },
};

// ============================================
// Urgency detection keywords
// ============================================
const URGENCY_KEYWORDS = [
    // Finnish
    'määräaika', 'viimeinen päivä', 'deadline', 'viimeistään',
    'heti', 'kiireellinen', 'välittömästi', 'pakko', 'ehdottomasti',
    'ennen', 'mennessä', 'huomenna', 'tänään',
    // English
    'must', 'deadline', 'urgent', 'immediately', 'last day',
    'expires', 'expiring', 'critical', 'by tomorrow', 'today',
    'final notice', 'last chance',
    // Russian
    'срок', 'крайний срок', 'срочно', 'немедленно', 'обязательно',
    'до завтра', 'сегодня', 'последний день', 'дедлайн',
];

// Date pattern: matches dates like 15.3.2026, 2026-03-15, March 15, etc.
const DATE_PATTERNS = [
    /\b\d{1,2}\.\d{1,2}\.\d{4}\b/,
    /\b\d{4}-\d{2}-\d{2}\b/,
    /\b\d{1,2}\.\d{1,2}\.\b/,
    /\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}/i,
    /\b(tammikuu|helmikuu|maaliskuu|huhtikuu|toukokuu|kesäkuu|heinäkuu|elokuu|syyskuu|lokakuu|marraskuu|joulukuu)/i,
];

// ============================================
// Quick Response Templates
// ============================================
const QUICK_RESPONSES = {
    repeat: {
        ru: 'Можете повторить, пожалуйста?',
        en: 'Can you repeat that, please?',
        fi: 'Voitteko toistaa sen?',
        et: 'Kas saaksite seda korrata?',
        uk: 'Чи можете повторити?',
        ar: 'هل يمكنك تكرار ذلك؟',
        de: 'Können Sie das wiederholen?',
        sv: 'Kan du upprepa det?',
        fr: 'Pouvez-vous répéter?',
    },
    think: {
        ru: 'Мне нужно подумать минуту.',
        en: 'I need a moment to think.',
        fi: 'Tarvitsen hetken aikaa miettiä.',
        et: 'Mul on vaja hetk mõelda.',
        uk: 'Мені потрібна хвилинка подумати.',
        ar: 'أحتاج لحظة للتفكير.',
        de: 'Ich brauche einen Moment zum Nachdenken.',
        sv: 'Jag behöver en stund att tänka.',
        fr: 'J\'ai besoin d\'un moment pour réfléchir.',
    },
    simpler: {
        ru: 'Можете объяснить проще?',
        en: 'Can you explain that in simpler terms?',
        fi: 'Voitteko selittää sen yksinkertaisemmin?',
        et: 'Kas saaksite seda lihtsamalt selgitada?',
        uk: 'Чи можете пояснити простіше?',
        ar: 'هل يمكنك شرح ذلك بعبارات أبسط؟',
        de: 'Können Sie das einfacher erklären?',
        sv: 'Kan du förklara det enklare?',
        fr: 'Pouvez-vous expliquer plus simplement?',
    },
    options: {
        ru: 'Какие у меня варианты?',
        en: 'What are my options?',
        fi: 'Mitkä ovat vaihtoehtoni?',
        et: 'Millised on minu valikud?',
        uk: 'Які мої варіанти?',
        ar: 'ما هي خياراتي؟',
        de: 'Was sind meine Optionen?',
        sv: 'Vilka är mina alternativ?',
        fr: 'Quelles sont mes options?',
    },
};

// ============================================
// DOM References
// ============================================
const $ = (id) => document.getElementById(id);

const dom = {
    settingsModal: $('settings-modal'),
    deepgramKey: $('deepgram-key'),
    claudeKey: $('claude-key'),
    proxyUrl: $('proxy-url'),
    saveSettings: $('save-settings'),
    cancelSettings: $('cancel-settings'),
    settingsBtn: $('settings-btn'),
    languageSelect: $('language-select'),
    userLanguageSelect: $('user-language-select'),
    modeSelect: $('mode-select'),
    statusDot: $('status-dot'),
    statusText: $('status-text'),
    transcriptArea: $('transcript-area'),
    transcriptPlaceholder: $('transcript-placeholder'),
    interimArea: $('interim-area'),
    interimText: $('interim-text'),
    wordCount: $('word-count'),
    clearTranscript: $('clear-transcript'),
    aiArea: $('ai-area'),
    aiPlaceholder: $('ai-placeholder'),
    askAiNow: $('ask-ai-now'),
    keypointsList: $('keypoints-list'),
    keypointsPlaceholder: $('keypoints-placeholder'),
    keypointsCount: $('keypoints-count'),
    startBtn: $('start-btn'),
    startBtnText: $('start-btn-text'),
    recordDot: $('record-dot'),
    testMicBtn: $('test-mic-btn'),
    exportBtn: $('export-btn'),
    volumeBar: $('volume-bar'),
    callTimer: $('call-timer'),
};

// ============================================
// Dynamic UI Injection
// Injects new UI elements that the enhanced
// features need (context input, quick responses,
// summary button, audio quality badge, etc.)
// ============================================
function injectEnhancedUI() {
    // --- Context Input (before call starts) ---
    // Inserted at top of transcript panel, hidden once call starts
    const contextDiv = document.createElement('div');
    contextDiv.id = 'call-context-area';
    contextDiv.className = 'call-context-area';
    contextDiv.innerHTML = `
        <label for="call-context-input" class="context-label">Call context (optional):</label>
        <textarea id="call-context-input" class="call-context-input" rows="2"
            placeholder="E.g.: This is a call about my deportation appeal, case 1858/2026, lawyer from oikeusaputoimisto..."></textarea>
    `;
    // Insert before transcript area
    const transcriptPanel = dom.transcriptArea.parentElement;
    transcriptPanel.insertBefore(contextDiv, dom.transcriptArea);

    // --- Audio Quality Badge ---
    const qualityBadge = document.createElement('span');
    qualityBadge.id = 'audio-quality-badge';
    qualityBadge.className = 'audio-quality-badge quality-good';
    qualityBadge.textContent = 'Audio: --';
    qualityBadge.title = 'Audio quality based on Deepgram confidence scores';
    // Insert next to word count
    const panelActions = dom.wordCount.parentElement;
    panelActions.insertBefore(qualityBadge, dom.wordCount);

    // --- Quick Response Templates ---
    const quickDiv = document.createElement('div');
    quickDiv.id = 'quick-responses';
    quickDiv.className = 'quick-responses';
    quickDiv.style.display = 'none'; // shown when listening
    quickDiv.innerHTML = `
        <div class="quick-label">Quick phrases:</div>
        <div class="quick-buttons">
            <button class="btn btn-quick" data-key="repeat" title="Can you repeat that?">Repeat?</button>
            <button class="btn btn-quick" data-key="think" title="I need a moment">Moment...</button>
            <button class="btn btn-quick" data-key="simpler" title="Explain simpler">Simpler?</button>
            <button class="btn btn-quick" data-key="options" title="What are my options?">Options?</button>
        </div>
        <div class="quick-output" id="quick-output" style="display:none;"></div>
    `;
    // Insert above the interim area
    transcriptPanel.insertBefore(quickDiv, dom.interimArea);

    // --- Summary Button ---
    const summaryBtn = document.createElement('button');
    summaryBtn.id = 'summary-btn';
    summaryBtn.className = 'btn btn-secondary';
    summaryBtn.title = 'Generate conversation summary';
    summaryBtn.innerHTML = '<span class="btn-icon-text">&#128221;</span> Summary';
    // Insert next to export button
    dom.exportBtn.parentElement.insertBefore(summaryBtn, dom.exportBtn.nextSibling);

    // --- Reconnection Flash ---
    const reconnectFlash = document.createElement('div');
    reconnectFlash.id = 'reconnect-flash';
    reconnectFlash.className = 'reconnect-flash';
    reconnectFlash.style.display = 'none';
    reconnectFlash.textContent = 'Reconnecting...';
    document.body.appendChild(reconnectFlash);

    // --- Urgency Flash Overlay ---
    const urgencyFlash = document.createElement('div');
    urgencyFlash.id = 'urgency-flash';
    urgencyFlash.className = 'urgency-flash';
    urgencyFlash.style.display = 'none';
    document.body.appendChild(urgencyFlash);

    // --- Glossary Tooltip (single reusable element) ---
    const tooltip = document.createElement('div');
    tooltip.id = 'glossary-tooltip';
    tooltip.className = 'glossary-tooltip';
    tooltip.style.display = 'none';
    document.body.appendChild(tooltip);

    // Store references to new elements
    dom.callContextArea = $('call-context-area');
    dom.callContextInput = $('call-context-input');
    dom.audioQualityBadge = $('audio-quality-badge');
    dom.quickResponses = $('quick-responses');
    dom.quickOutput = $('quick-output');
    dom.summaryBtn = $('summary-btn');
    dom.reconnectFlash = $('reconnect-flash');
    dom.urgencyFlash = $('urgency-flash');
    dom.glossaryTooltip = $('glossary-tooltip');
}

// ============================================
// Inject Enhanced CSS
// ============================================
function injectEnhancedCSS() {
    const style = document.createElement('style');
    style.textContent = `
        /* Context area */
        .call-context-area {
            padding: 8px 12px;
            border-bottom: 1px solid rgba(255,255,255,0.08);
        }
        .context-label {
            display: block;
            font-size: 11px;
            color: #888;
            margin-bottom: 4px;
        }
        .call-context-input {
            width: 100%;
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 6px;
            color: #ddd;
            padding: 6px 8px;
            font-size: 12px;
            resize: none;
            font-family: inherit;
        }
        .call-context-input:focus {
            outline: none;
            border-color: #6C63FF;
        }
        .call-context-area.hidden { display: none; }

        /* Audio quality badge */
        .audio-quality-badge {
            font-size: 11px;
            padding: 2px 8px;
            border-radius: 10px;
            margin-right: 8px;
            font-weight: 600;
        }
        .quality-good { background: #065F46; color: #34D399; }
        .quality-fair { background: #78350F; color: #FBBF24; }
        .quality-poor { background: #7F1D1D; color: #F87171; }

        /* Speaker colors for diarization */
        .transcript-segment.speaker-lawyer {
            border-left-color: #6C63FF !important;
        }
        .transcript-segment.speaker-you {
            border-left-color: #34D399 !important;
        }
        .speaker-label {
            font-size: 10px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 2px;
            display: block;
        }
        .speaker-label.label-lawyer { color: #6C63FF; }
        .speaker-label.label-you { color: #34D399; }

        /* Translation line under transcript segment */
        .segment-translation {
            display: block;
            font-size: 11px;
            color: #777;
            font-style: italic;
            margin-top: 3px;
            padding-left: 2px;
        }

        /* Legal term highlight */
        .legal-term {
            border-bottom: 1px dotted #FBBF24;
            cursor: help;
            color: #FBBF24;
        }

        /* Glossary tooltip */
        .glossary-tooltip {
            position: fixed;
            z-index: 10000;
            background: #1E1E2E;
            border: 1px solid #6C63FF;
            border-radius: 8px;
            padding: 10px 14px;
            max-width: 320px;
            font-size: 12px;
            color: #E0E0E0;
            box-shadow: 0 8px 32px rgba(0,0,0,0.5);
            pointer-events: none;
        }
        .glossary-tooltip .gt-term {
            font-weight: 700;
            color: #FBBF24;
            display: block;
            margin-bottom: 4px;
        }
        .glossary-tooltip .gt-translation {
            color: #A5B4FC;
            margin-bottom: 4px;
        }
        .glossary-tooltip .gt-desc {
            color: #999;
            font-size: 11px;
        }

        /* Quick responses */
        .quick-responses {
            padding: 6px 12px;
            border-bottom: 1px solid rgba(255,255,255,0.08);
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 6px;
        }
        .quick-label {
            font-size: 10px;
            color: #888;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .quick-buttons {
            display: flex;
            gap: 4px;
            flex-wrap: wrap;
        }
        .btn-quick {
            font-size: 11px !important;
            padding: 3px 10px !important;
            border-radius: 12px !important;
            background: rgba(108, 99, 255, 0.15) !important;
            border: 1px solid rgba(108, 99, 255, 0.3) !important;
            color: #A5B4FC !important;
            cursor: pointer;
            transition: all 0.2s;
        }
        .btn-quick:hover {
            background: rgba(108, 99, 255, 0.3) !important;
            color: #fff !important;
        }
        .quick-output {
            width: 100%;
            margin-top: 6px;
            padding: 8px 10px;
            background: rgba(108, 99, 255, 0.08);
            border-radius: 8px;
            font-size: 13px;
            line-height: 1.5;
            animation: quickFadeIn 0.3s ease;
        }
        .quick-output .quick-user-lang {
            color: #E0E0E0;
            font-weight: 600;
        }
        .quick-output .quick-call-lang {
            color: #34D399;
        }
        @keyframes quickFadeIn {
            from { opacity: 0; transform: translateY(-4px); }
            to { opacity: 1; transform: translateY(0); }
        }

        /* Urgency flash */
        .urgency-flash {
            position: fixed;
            top: 0; left: 0; right: 0;
            height: 3px;
            background: linear-gradient(90deg, #EF4444, #F97316, #EF4444);
            z-index: 9999;
            animation: urgencyPulse 1.5s ease-in-out;
        }
        @keyframes urgencyPulse {
            0% { opacity: 0; }
            20% { opacity: 1; }
            80% { opacity: 1; }
            100% { opacity: 0; }
        }

        /* Urgency badge on transcript segment */
        .urgency-badge {
            display: inline-block;
            font-size: 9px;
            font-weight: 700;
            background: #7F1D1D;
            color: #F87171;
            padding: 1px 6px;
            border-radius: 8px;
            margin-left: 6px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            animation: urgentBlink 1s ease-in-out 3;
        }
        @keyframes urgentBlink {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.4; }
        }

        /* Reconnect flash */
        .reconnect-flash {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(30, 30, 46, 0.95);
            border: 1px solid #FBBF24;
            border-radius: 12px;
            padding: 16px 32px;
            color: #FBBF24;
            font-weight: 600;
            font-size: 14px;
            z-index: 9998;
            box-shadow: 0 8px 32px rgba(0,0,0,0.5);
            animation: reconnectPulse 1s ease-in-out infinite;
        }
        @keyframes reconnectPulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.6; }
        }

        /* Summary modal */
        .summary-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0,0,0,0.7);
            z-index: 10000;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .summary-modal {
            background: #1E1E2E;
            border: 1px solid rgba(108, 99, 255, 0.3);
            border-radius: 12px;
            width: 90%;
            max-width: 700px;
            max-height: 80vh;
            overflow-y: auto;
            padding: 24px;
            color: #E0E0E0;
        }
        .summary-modal h2 {
            color: #A5B4FC;
            margin-top: 0;
        }
        .summary-modal .summary-content {
            line-height: 1.7;
            font-size: 14px;
        }
        .summary-modal .summary-content strong {
            color: #FBBF24;
        }
        .summary-close {
            margin-top: 16px;
            text-align: right;
        }
    `;
    document.head.appendChild(style);
}

// ============================================
// Crypto: AES-GCM encryption for API keys
// ============================================
let _cachedPin = '';
let _cachedDgKey = '';
let _cachedClaudeKey = '';

async function _deriveKey(pin) {
    const enc = new TextEncoder();
    const keyMaterial = await crypto.subtle.importKey(
        'raw', enc.encode(pin), 'PBKDF2', false, ['deriveKey']
    );
    return crypto.subtle.deriveKey(
        { name: 'PBKDF2', salt: enc.encode('advocat-salt-v1'), iterations: 100000, hash: 'SHA-256' },
        keyMaterial,
        { name: 'AES-GCM', length: 256 },
        false,
        ['encrypt', 'decrypt']
    );
}

async function _encryptValue(pin, plaintext) {
    if (!plaintext) return '';
    const key = await _deriveKey(pin);
    const iv = crypto.getRandomValues(new Uint8Array(12));
    const ct = await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, new TextEncoder().encode(plaintext));
    const combined = new Uint8Array(iv.length + ct.byteLength);
    combined.set(iv);
    combined.set(new Uint8Array(ct), iv.length);
    return 'ENC:' + btoa(String.fromCharCode(...combined));
}

async function _decryptValue(pin, stored) {
    if (!stored || !stored.startsWith('ENC:')) return stored || '';
    try {
        const key = await _deriveKey(pin);
        const raw = Uint8Array.from(atob(stored.slice(4)), c => c.charCodeAt(0));
        const decrypted = await crypto.subtle.decrypt({ name: 'AES-GCM', iv: raw.slice(0, 12) }, key, raw.slice(12));
        return new TextDecoder().decode(decrypted);
    } catch { return ''; }
}

async function _unlockKeys(pin) {
    _cachedDgKey = await _decryptValue(pin, localStorage.getItem('advocat_dg_key') || '');
    _cachedClaudeKey = await _decryptValue(pin, localStorage.getItem('advocat_claude_key') || '');
    _cachedPin = pin;
    if (dom.deepgramKey) dom.deepgramKey.value = _cachedDgKey;
    if (dom.claudeKey) dom.claudeKey.value = _cachedClaudeKey;
}

function _updatePinWarning() {
    const el = document.getElementById('pin-warning');
    if (!el) return;
    const hasPin = localStorage.getItem('advocat_has_pin') === '1';
    const hasKeys = !!(localStorage.getItem('advocat_dg_key') || localStorage.getItem('advocat_claude_key'));
    el.style.display = (hasKeys && !hasPin) ? 'block' : 'none';
}

// ============================================
// Settings (localStorage) — with PIN encryption
// ============================================
function loadSettings() {
    const hasPin = localStorage.getItem('advocat_has_pin') === '1';
    const storedDg = localStorage.getItem('advocat_dg_key') || '';
    const storedClaude = localStorage.getItem('advocat_claude_key') || '';
    if (!hasPin) {
        dom.deepgramKey.value = storedDg;
        dom.claudeKey.value = storedClaude;
        _cachedDgKey = storedDg;
        _cachedClaudeKey = storedClaude;
    } else {
        dom.deepgramKey.value = _cachedDgKey || '';
        dom.claudeKey.value = _cachedClaudeKey || '';
    }
    dom.proxyUrl.value = localStorage.getItem('advocat_proxy_url') || '';
    state.language = localStorage.getItem('advocat_language') || 'fi';
    state.userLanguage = localStorage.getItem('advocat_user_language') || 'ru';
    state.mode = localStorage.getItem('advocat_mode') || 'deepgram';
    state.secureMode = localStorage.getItem('advocat_secure_mode') === '1';
    dom.languageSelect.value = state.language;
    if (dom.userLanguageSelect) {
        dom.userLanguageSelect.value = state.userLanguage;
    }
    dom.modeSelect.value = state.mode;
    const smToggle = document.getElementById('settings-secure-mode');
    if (smToggle) smToggle.checked = state.secureMode;
    const pinInput = document.getElementById('pin-code');
    if (pinInput) pinInput.value = '';
    _updatePinWarning();
}

async function saveSettings() {
    const pinInput = document.getElementById('pin-code');
    const pin = pinInput ? pinInput.value.trim() : '';
    const dgKey = dom.deepgramKey.value.trim();
    const claudeKey = dom.claudeKey.value.trim();

    if (pin && pin.length >= 4) {
        localStorage.setItem('advocat_dg_key', await _encryptValue(pin, dgKey));
        localStorage.setItem('advocat_claude_key', await _encryptValue(pin, claudeKey));
        localStorage.setItem('advocat_has_pin', '1');
        _cachedPin = pin;
    } else {
        localStorage.setItem('advocat_dg_key', dgKey);
        localStorage.setItem('advocat_claude_key', claudeKey);
        localStorage.removeItem('advocat_has_pin');
    }
    _cachedDgKey = dgKey;
    _cachedClaudeKey = claudeKey;
    localStorage.setItem('advocat_proxy_url', dom.proxyUrl.value.trim());
    const smToggle = document.getElementById('settings-secure-mode');
    if (smToggle) {
        state.secureMode = smToggle.checked;
        localStorage.setItem('advocat_secure_mode', state.secureMode ? '1' : '0');
    }
    _updatePinWarning();
    dom.settingsModal.style.display = 'none';
}

function getDgKey() { return _cachedDgKey || localStorage.getItem('advocat_dg_key') || ''; }
function getClaudeKey() { return _cachedClaudeKey || localStorage.getItem('advocat_claude_key') || ''; }
function getProxyUrl() { return localStorage.getItem('advocat_proxy_url') || ''; }

// ============================================
// Status & UI helpers
// ============================================
function setStatus(status, text) {
    dom.statusDot.className = 'status-dot ' + status;
    dom.statusText.textContent = text;
}

function formatTime(seconds) {
    const h = String(Math.floor(seconds / 3600)).padStart(2, '0');
    const m = String(Math.floor((seconds % 3600) / 60)).padStart(2, '0');
    const s = String(seconds % 60).padStart(2, '0');
    return `${h}:${m}:${s}`;
}

function getTimestamp() {
    return formatTime(state.timerSeconds);
}

function updateWordCount() {
    const words = state.fullTranscriptText.trim().split(/\s+/).filter(w => w.length > 0).length;
    dom.wordCount.textContent = words + ' words';
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ============================================
// Audio Quality Indicator
// Tracks Deepgram confidence scores and shows
// a rolling average quality badge.
// ============================================
function updateAudioQuality(confidence) {
    if (typeof confidence !== 'number' || confidence <= 0) return;

    state.recentConfidences.push(confidence);
    // Keep last 20 scores for a rolling window
    if (state.recentConfidences.length > 20) {
        state.recentConfidences.shift();
    }

    const avg = state.recentConfidences.reduce((a, b) => a + b, 0) / state.recentConfidences.length;

    let quality, label, cssClass;
    if (avg >= 0.85) {
        quality = 'good';
        label = 'Audio: Good';
        cssClass = 'quality-good';
    } else if (avg >= 0.65) {
        quality = 'fair';
        label = 'Audio: Fair';
        cssClass = 'quality-fair';
    } else {
        quality = 'poor';
        label = 'Audio: Poor';
        cssClass = 'quality-poor';
    }

    state.audioQuality = quality;
    if (dom.audioQualityBadge) {
        dom.audioQualityBadge.textContent = label;
        dom.audioQualityBadge.className = 'audio-quality-badge ' + cssClass;
    }
}

// ============================================
// Speaker Diarization
// Tracks word counts per speaker ID and assigns
// labels: the speaker with more words is "Lawyer"
// (assumes the professional talks more), the
// other is "You".
// ============================================
function updateSpeakerLabels(speakerId, wordCount) {
    if (!state.speakerWordCounts[speakerId]) {
        state.speakerWordCounts[speakerId] = 0;
    }
    state.speakerWordCounts[speakerId] += wordCount;

    // Reassign labels: speaker with most words = Lawyer, others = You
    const speakers = Object.entries(state.speakerWordCounts);
    if (speakers.length < 2) {
        // Only one speaker so far — label as "You" by default
        state.speakerLabels = { [speakers[0][0]]: 'You' };
        return;
    }

    speakers.sort((a, b) => b[1] - a[1]);
    const newLabels = {};
    newLabels[speakers[0][0]] = 'Lawyer';
    for (let i = 1; i < speakers.length; i++) {
        newLabels[speakers[i][0]] = 'You';
    }
    state.speakerLabels = newLabels;
}

function getSpeakerLabel(speakerId) {
    return state.speakerLabels[speakerId] || (speakerId === 0 ? 'You' : `Speaker ${speakerId}`);
}

// ============================================
// Legal Term Highlighting
// Scans text for known legal terms and wraps
// them in <span class="legal-term"> elements
// for glossary tooltip display.
// ============================================
function highlightLegalTerms(text) {
    let html = escapeHtml(text);
    const lowerText = text.toLowerCase();

    // Sort terms by length (longest first) to avoid partial matches
    const sortedTerms = Object.keys(LEGAL_GLOSSARY).sort((a, b) => b.length - a.length);

    for (const term of sortedTerms) {
        const idx = lowerText.indexOf(term);
        if (idx !== -1) {
            // Find the actual text in original casing
            const originalTerm = text.substring(idx, idx + term.length);
            const escaped = escapeHtml(originalTerm);
            // Replace only first occurrence to avoid double-wrapping
            html = html.replace(
                escaped,
                `<span class="legal-term" data-term="${term}">${escaped}</span>`
            );
        }
    }
    return html;
}

// Show glossary tooltip on hover/tap
function showGlossaryTooltip(event) {
    const target = event.target;
    if (!target.classList.contains('legal-term')) return;

    const termKey = target.dataset.term;
    const entry = LEGAL_GLOSSARY[termKey];
    if (!entry) return;

    const lang = state.userLanguage;
    const translation = entry[lang] || entry.en || '';
    const description = entry[`desc_${lang}`] || entry.desc_en || entry.desc_ru || '';

    dom.glossaryTooltip.innerHTML = `
        <span class="gt-term">${entry.fi}</span>
        <span class="gt-translation">${translation}</span>
        <span class="gt-desc">${description}</span>
    `;
    dom.glossaryTooltip.style.display = 'block';

    // Position near the element
    const rect = target.getBoundingClientRect();
    let top = rect.bottom + 8;
    let left = rect.left;

    // Keep tooltip on screen
    if (top + 100 > window.innerHeight) {
        top = rect.top - 80;
    }
    if (left + 320 > window.innerWidth) {
        left = window.innerWidth - 330;
    }

    dom.glossaryTooltip.style.top = top + 'px';
    dom.glossaryTooltip.style.left = left + 'px';
}

function hideGlossaryTooltip() {
    if (dom.glossaryTooltip) {
        dom.glossaryTooltip.style.display = 'none';
    }
}

// ============================================
// Urgency Detection
// Checks transcript text for urgent keywords
// and date patterns. Fires a red flash if found.
// ============================================
function checkUrgency(text) {
    const lower = text.toLowerCase();

    // Check keywords
    const hasUrgentKeyword = URGENCY_KEYWORDS.some(kw => lower.includes(kw));
    // Check date patterns
    const hasDate = DATE_PATTERNS.some(pattern => pattern.test(text));

    return hasUrgentKeyword || hasDate;
}

function flashUrgency(text) {
    // Show top-bar red flash
    const flash = dom.urgencyFlash;
    if (flash) {
        flash.style.display = 'block';
        // Reset animation
        flash.style.animation = 'none';
        void flash.offsetWidth; // trigger reflow
        flash.style.animation = 'urgencyPulse 1.5s ease-in-out';
        setTimeout(() => { flash.style.display = 'none'; }, 1600);
    }
}

// ============================================
// Transcript Rendering (Enhanced)
// Now includes speaker labels, legal term
// highlighting, urgency badges, and translation
// placeholders.
// ============================================
function addTranscriptSegment(text, speaker = 0, isFinal = true, confidence = 1.0) {
    if (!text.trim()) return;

    // Hide placeholder
    if (dom.transcriptPlaceholder) {
        dom.transcriptPlaceholder.style.display = 'none';
    }

    // Update speaker word counts for diarization
    const wordCount = text.trim().split(/\s+/).length;
    updateSpeakerLabels(speaker, wordCount);

    const label = getSpeakerLabel(speaker);
    const isLawyer = label === 'Lawyer';

    const segment = document.createElement('div');
    segment.className = `transcript-segment ${isLawyer ? 'speaker-lawyer' : 'speaker-you'}`;
    segment.dataset.segmentIndex = state.transcript.length;

    // Speaker label
    const labelEl = document.createElement('span');
    labelEl.className = `speaker-label ${isLawyer ? 'label-lawyer' : 'label-you'}`;
    labelEl.textContent = label;
    segment.appendChild(labelEl);

    // Timestamp
    const timeEl = document.createElement('span');
    timeEl.className = 'segment-time';
    timeEl.textContent = getTimestamp();
    segment.appendChild(timeEl);

    // Urgency check
    const isUrgent = checkUrgency(text);
    if (isUrgent) {
        const urgBadge = document.createElement('span');
        urgBadge.className = 'urgency-badge';
        urgBadge.textContent = 'URGENT';
        segment.appendChild(urgBadge);
        flashUrgency(text);
    }

    // Text with legal term highlighting
    const textEl = document.createElement('span');
    textEl.className = 'segment-text';
    textEl.innerHTML = highlightLegalTerms(text);
    segment.appendChild(textEl);

    // Translation placeholder (filled by batch translation)
    const transEl = document.createElement('span');
    transEl.className = 'segment-translation';
    transEl.id = `translation-${state.transcript.length}`;
    segment.appendChild(transEl);

    dom.transcriptArea.appendChild(segment);

    // Performance: prune old DOM nodes to prevent memory leaks on long calls (2+ hours)
    const allSegments = dom.transcriptArea.querySelectorAll('.transcript-segment');
    if (allSegments.length > 500) {
        const toRemove = allSegments.length - 500;
        for (let i = 0; i < toRemove; i++) allSegments[i].remove();
    }

    // Auto-scroll
    dom.transcriptArea.scrollTop = dom.transcriptArea.scrollHeight;

    if (isFinal) {
        state.fullTranscriptText += text + ' ';
        const entry = { time: getTimestamp(), text, speaker, label, confidence, isUrgent };
        state.transcript.push(entry);
        state.pendingSegments.push(entry);
        state.currentTopicSegments.push(entry);
        updateWordCount();
        updateAudioQuality(confidence);

        // Queue for translation if call language differs from user language
        if (state.language !== state.userLanguage) {
            state.pendingTranslations.push({
                index: state.transcript.length - 1,
                text: text,
            });
            scheduleBatchTranslation();
        }

        // Smart pause detection: reset timer on new speech
        state.lastSpeechAt = Date.now();
        resetPauseTimer();
    }
}

function showInterim(text) {
    if (text.trim()) {
        dom.interimArea.style.display = 'block';
        dom.interimText.textContent = text;
    } else {
        dom.interimArea.style.display = 'none';
    }
}

// ============================================
// Batch Translation
// Collects segments and translates them in
// batches every 10 seconds via Claude, to avoid
// per-word API calls.
// ============================================
function scheduleBatchTranslation() {
    if (state.translationTimer) return; // already scheduled

    state.translationTimer = setTimeout(async () => {
        state.translationTimer = null;
        await runBatchTranslation();
    }, 10000); // 10 seconds
}

async function runBatchTranslation() {
    if (state.pendingTranslations.length === 0) return;

    const claudeKey = getClaudeKey();
    const proxyUrl = getProxyUrl();
    if (!claudeKey && !proxyUrl) return;

    // Take the pending batch
    const batch = [...state.pendingTranslations];
    state.pendingTranslations = [];

    const userLang = LANG_NAMES[state.userLanguage] || 'Russian';
    const callLang = LANG_NAMES[state.language] || 'Finnish';

    // Build batch prompt
    const lines = batch.map((item, i) => `[${i}] ${item.text}`).join('\n');
    const prompt = `Translate each line from ${callLang} to ${userLang}. Return ONLY the translations, one per line, in the same order. Keep it concise and natural.\n\n${lines}`;

    try {
        let responseText;
        if (proxyUrl) {
            const res = await fetch(proxyUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ transcript: prompt, language: state.language, type: 'translate' }),
            });
            const data = await res.json();
            responseText = data.response || data.content || data.text || '';
        } else {
            const res = await fetch('https://api.anthropic.com/v1/messages', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'x-api-key': claudeKey,
                    'anthropic-version': '2023-06-01',
                    'anthropic-dangerous-direct-browser-access': 'true',
                },
                body: JSON.stringify({
                    model: 'claude-sonnet-4-20250514',
                    max_tokens: 400,
                    messages: [{ role: 'user', content: prompt }],
                }),
            });
            if (!res.ok) return; // silently fail for translations
            const data = await res.json();
            responseText = data.content?.[0]?.text || '';
        }

        // Parse translations — one per line
        const translations = responseText.split('\n')
            .map(line => line.replace(/^\[\d+\]\s*/, '').trim())
            .filter(line => line.length > 0);

        // Apply translations to DOM
        batch.forEach((item, i) => {
            const translation = translations[i] || '';
            if (translation) {
                const el = document.getElementById(`translation-${item.index}`);
                if (el) {
                    el.textContent = translation;
                }
            }
        });
    } catch (err) {
        console.warn('Batch translation failed:', err);
    }
}

// ============================================
// Microphone & Audio Analysis
// ============================================
async function startMicrophone() {
    try {
        state.stream = await navigator.mediaDevices.getUserMedia({
            audio: {
                echoCancellation: true,
                noiseSuppression: true,
                autoGainControl: true,
                sampleRate: 16000
            }
        });

        // Set up audio analyser for volume meter
        state.audioContext = new (window.AudioContext || window.webkitAudioContext)();
        const source = state.audioContext.createMediaStreamSource(state.stream);
        state.analyser = state.audioContext.createAnalyser();
        state.analyser.fftSize = 256;
        source.connect(state.analyser);

        startVolumeMeter();
        return true;
    } catch (err) {
        console.error('Microphone error:', err.name);
        if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
            setStatus('error', 'Microphone permission denied');
            alert('Microphone Access Denied\n\nPlease allow microphone access in your browser settings:\n1. Click the lock/camera icon in the address bar\n2. Set Microphone to "Allow"\n3. Reload the page and try again');
        } else if (err.name === 'NotFoundError') {
            setStatus('error', 'No microphone found');
            alert('No Microphone Detected\n\nPlease connect a microphone and try again.');
        } else if (err.name === 'NotReadableError') {
            setStatus('error', 'Microphone busy');
            alert('Microphone In Use\n\nYour microphone is being used by another application. Please close it and try again.');
        } else {
            setStatus('error', 'Microphone error');
            alert('Could not access the microphone. Please check your browser settings and try again.');
        }
        return false;
    }
}

function startVolumeMeter() {
    const dataArray = new Uint8Array(state.analyser.frequencyBinCount);

    function update() {
        if (!state.analyser) return;
        state.analyser.getByteFrequencyData(dataArray);
        const average = dataArray.reduce((a, b) => a + b, 0) / dataArray.length;
        const percent = Math.min(100, (average / 128) * 100);
        dom.volumeBar.style.width = percent + '%';
        state.volumeAnimFrame = requestAnimationFrame(update);
    }
    update();
}

function stopMicrophone() {
    if (state.volumeAnimFrame) {
        cancelAnimationFrame(state.volumeAnimFrame);
        state.volumeAnimFrame = null;
    }
    if (state.audioContext) {
        state.audioContext.close().catch(() => {});
        state.audioContext = null;
        state.analyser = null;
    }
    if (state.stream) {
        state.stream.getTracks().forEach(t => t.stop());
        state.stream = null;
    }
    dom.volumeBar.style.width = '0%';
}

// ============================================
// Test Microphone
// ============================================
async function testMicrophone() {
    dom.testMicBtn.textContent = 'Testing...';
    dom.testMicBtn.disabled = true;

    try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        const audioContext = new (window.AudioContext || window.webkitAudioContext)();
        const source = audioContext.createMediaStreamSource(stream);
        const analyser = audioContext.createAnalyser();
        analyser.fftSize = 256;
        source.connect(analyser);

        const dataArray = new Uint8Array(analyser.frequencyBinCount);
        let maxLevel = 0;
        let checks = 0;

        const interval = setInterval(() => {
            analyser.getByteFrequencyData(dataArray);
            const avg = dataArray.reduce((a, b) => a + b, 0) / dataArray.length;
            maxLevel = Math.max(maxLevel, avg);
            dom.volumeBar.style.width = Math.min(100, (avg / 128) * 100) + '%';
            checks++;

            if (checks >= 20) { // 2 seconds
                clearInterval(interval);
                stream.getTracks().forEach(t => t.stop());
                audioContext.close();
                dom.volumeBar.style.width = '0%';

                if (maxLevel > 5) {
                    dom.testMicBtn.innerHTML = '<span class="btn-icon-text">&#127908;</span> Mic OK!';
                    dom.testMicBtn.style.borderColor = '#4ADE80';
                } else {
                    dom.testMicBtn.innerHTML = '<span class="btn-icon-text">&#127908;</span> No audio detected';
                    dom.testMicBtn.style.borderColor = '#EF4444';
                }
                dom.testMicBtn.disabled = false;
                setTimeout(() => {
                    dom.testMicBtn.innerHTML = '<span class="btn-icon-text">&#127908;</span> Test Mic';
                    dom.testMicBtn.style.borderColor = '';
                }, 3000);
            }
        }, 100);
    } catch (err) {
        dom.testMicBtn.innerHTML = '<span class="btn-icon-text">&#127908;</span> Access denied!';
        dom.testMicBtn.style.borderColor = '#EF4444';
        dom.testMicBtn.disabled = false;
        setTimeout(() => {
            dom.testMicBtn.innerHTML = '<span class="btn-icon-text">&#127908;</span> Test Mic';
            dom.testMicBtn.style.borderColor = '';
        }, 3000);
    }
}

// ============================================
// Timer
// ============================================
function startTimer() {
    state.timerSeconds = 0;
    dom.callTimer.textContent = '00:00:00';
    state.timerInterval = setInterval(() => {
        state.timerSeconds++;
        dom.callTimer.textContent = formatTime(state.timerSeconds);
    }, 1000);
}

function stopTimer() {
    if (state.timerInterval) {
        clearInterval(state.timerInterval);
        state.timerInterval = null;
    }
}

// ============================================
// Deepgram WebSocket (Enhanced)
// Now includes: diarization, confidence tracking,
// and fast reconnection resilience.
// ============================================
function startDeepgram() {
    const key = getDgKey();
    if (!key) {
        dom.settingsModal.style.display = 'flex';
        alert('API Key Required\n\nPlease enter your Deepgram API key in Settings.\nAlternatively, switch to Demo Mode (free, no key needed).');
        return false;
    }

    setStatus('connecting', 'Connecting to Deepgram...');

    const lang = state.language === 'multi' ? 'multi' : state.language;
    const params = new URLSearchParams({
        model: 'nova-3',
        language: lang,
        smart_format: 'true',
        punctuate: 'true',
        interim_results: 'true',
        utterance_end_ms: '1500',
        vad_events: 'true',
        endpointing: '300',
        // Feature #2: Enable speaker diarization
        diarize: 'true',
    });

    // Deepgram uses the token as a WebSocket subprotocol
    const url = `wss://api.deepgram.com/v1/listen?${params.toString()}`;

    try {
        state.dgSocket = new WebSocket(url, ['token', key]);
    } catch (err) {
        console.error('WebSocket creation failed');
        setStatus('error', 'Connection failed');
        return false;
    }

    state.dgSocket.onopen = () => {
        setStatus('listening', 'Listening (Deepgram)');
        state.reconnectAttempts = 0;
        state.isReconnecting = false;
        hideReconnectFlash();

        // Flush any buffered transcript segments from reconnection gap
        if (state.transcriptBuffer.length > 0) {
            state.transcriptBuffer.forEach(seg => {
                addTranscriptSegment(seg.text, seg.speaker, true, seg.confidence);
            });
            state.transcriptBuffer = [];
        }

        startMediaRecorder();
    };

    state.dgSocket.onmessage = (event) => {
        try {
            const data = JSON.parse(event.data);
            handleDeepgramMessage(data);
        } catch (err) {
            console.warn('Failed to parse Deepgram message:', err);
        }
    };

    state.dgSocket.onerror = () => {
        // Don't log the raw error object — may contain sensitive token info
        setStatus('error', 'Connection error');
    };

    // Feature #12: Fast reconnection resilience (+ auth/rate-limit detection)
    state.dgSocket.onclose = (event) => {
        if (state.isListening) {
            // Detect authentication errors — do NOT expose key
            if (event.code === 1008 || event.code === 4001 || event.code === 401 || (event.reason && event.reason.toLowerCase().includes('auth'))) {
                setStatus('error', 'Invalid API key');
                displayAiError('Deepgram: Invalid API key. Please check your key in Settings.');
                return;
            }
            // Detect rate limiting
            if (event.code === 4009 || event.code === 429) {
                setStatus('error', 'Rate limited — please wait');
                displayAiError('Deepgram: Rate limit reached. Will retry in a few seconds.');
                setTimeout(() => { if (state.isListening) startDeepgram(); }, 5000);
                return;
            }

            state.isReconnecting = true;
            state.reconnectAttempts++;
            showReconnectFlash();

            if (state.reconnectAttempts <= state.maxReconnectAttempts) {
                const delay = Math.min(1000 * state.reconnectAttempts, 5000);
                setStatus('error', `Disconnected — reconnecting (${state.reconnectAttempts})...`);
                setTimeout(() => {
                    if (state.isListening) {
                        startDeepgram();
                    }
                }, delay);
            } else {
                setStatus('error', 'Connection lost — please restart');
                hideReconnectFlash();
            }
        }
    };

    return true;
}

function showReconnectFlash() {
    if (dom.reconnectFlash) {
        dom.reconnectFlash.style.display = 'block';
    }
}

function hideReconnectFlash() {
    if (dom.reconnectFlash) {
        dom.reconnectFlash.style.display = 'none';
    }
}

// Enhanced Deepgram message handler with confidence + diarization
function handleDeepgramMessage(data) {
    if (data.type === 'Results') {
        const alt = data.channel?.alternatives?.[0];
        if (!alt) return;

        const transcript = alt.transcript || '';
        const isFinal = data.is_final;
        const confidence = alt.confidence || 0;

        // Extract speaker from diarization data (word-level speaker IDs)
        const words = alt.words || [];
        let speaker = 0;
        if (words.length > 0) {
            // Use the most common speaker ID in this segment
            const speakerCounts = {};
            words.forEach(w => {
                const s = w.speaker !== undefined ? w.speaker : 0;
                speakerCounts[s] = (speakerCounts[s] || 0) + 1;
            });
            speaker = parseInt(Object.entries(speakerCounts)
                .sort((a, b) => b[1] - a[1])[0][0], 10);
        }

        if (isFinal && transcript.trim()) {
            showInterim('');
            addTranscriptSegment(transcript, speaker, true, confidence);
        } else if (!isFinal && transcript.trim()) {
            showInterim(transcript);
        }
    } else if (data.type === 'UtteranceEnd') {
        showInterim('');
        // UtteranceEnd is a strong signal that speaker finished a thought
        // Trigger AI analysis if enough content accumulated
        onUtteranceEnd();
    }
}

function startMediaRecorder() {
    if (!state.stream) return;

    // Stop existing recorder if reconnecting
    if (state.mediaRecorder && state.mediaRecorder.state !== 'inactive') {
        try { state.mediaRecorder.stop(); } catch (e) {}
    }

    // Determine supported mime type
    const mimeType = MediaRecorder.isTypeSupported('audio/webm;codecs=opus')
        ? 'audio/webm;codecs=opus'
        : MediaRecorder.isTypeSupported('audio/webm')
            ? 'audio/webm'
            : 'audio/mp4'; // Safari fallback

    try {
        state.mediaRecorder = new MediaRecorder(state.stream, { mimeType });
    } catch (err) {
        // Fallback: let browser choose
        state.mediaRecorder = new MediaRecorder(state.stream);
    }

    state.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0 && state.dgSocket && state.dgSocket.readyState === WebSocket.OPEN) {
            state.dgSocket.send(event.data);
        }
    };

    state.mediaRecorder.start(250); // 250ms chunks
}

function stopDeepgram() {
    if (state.mediaRecorder && state.mediaRecorder.state !== 'inactive') {
        state.mediaRecorder.stop();
        state.mediaRecorder = null;
    }
    if (state.dgSocket) {
        // Send close frame to Deepgram
        if (state.dgSocket.readyState === WebSocket.OPEN) {
            state.dgSocket.send(JSON.stringify({ type: 'CloseStream' }));
        }
        state.dgSocket.close();
        state.dgSocket = null;
    }
}

// ============================================
// Demo Mode (Web Speech API)
// ============================================
function startDemoMode() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SpeechRecognition) {
        alert('Speech Recognition Not Supported\n\nWeb Speech API is not available in this browser.\nPlease use Google Chrome for Demo Mode, or switch to Deepgram mode with an API key.');
        return false;
    }

    state.recognition = new SpeechRecognition();
    state.recognition.continuous = true;
    state.recognition.interimResults = true;

    // Map language codes
    const langMap = {
        'fi': 'fi-FI',
        'en': 'en-US',
        'ru': 'ru-RU',
        'multi': 'en-US' // Web Speech API doesn't support multi
    };
    state.recognition.lang = langMap[state.language] || 'fi-FI';

    state.recognition.onstart = () => {
        setStatus('listening', 'Listening (Demo Mode)');
    };

    state.recognition.onresult = (event) => {
        let interimTranscript = '';
        for (let i = event.resultIndex; i < event.results.length; i++) {
            const result = event.results[i];
            if (result.isFinal) {
                showInterim('');
                addTranscriptSegment(result[0].transcript, 0, true, result[0].confidence || 0.8);
            } else {
                interimTranscript += result[0].transcript;
            }
        }
        if (interimTranscript) {
            showInterim(interimTranscript);
        }
    };

    state.recognition.onerror = (event) => {
        if (event.error === 'no-speech') return;
        if (event.error === 'aborted' && !state.isListening) return;
        if (event.error === 'not-allowed') {
            setStatus('error', 'Microphone permission denied');
            alert('Speech recognition needs microphone access.\nPlease allow it in your browser settings and reload.');
            return;
        }
        if (event.error === 'network') {
            setStatus('error', 'Network error');
            displayAiError('Speech recognition: Network error. Check your internet connection.');
            return;
        }
        setStatus('error', 'Speech recognition error');
    };

    state.recognition.onend = () => {
        // Auto-restart if still listening (Web Speech API stops after silence)
        if (state.isListening) {
            try {
                state.recognition.start();
            } catch (e) {
                // Already started
            }
        }
    };

    try {
        state.recognition.start();
        return true;
    } catch (err) {
        console.error('Failed to start speech recognition:', err);
        return false;
    }
}

function stopDemoMode() {
    if (state.recognition) {
        try {
            state.recognition.stop();
        } catch (e) {}
        state.recognition = null;
    }
}

// ============================================
// Claude AI Integration (Enhanced)
// Context-aware prompts, smart trigger logic,
// and structured response parsing.
// ============================================
const LANG_NAMES = {
    ru: 'Russian', en: 'English', fi: 'Finnish', et: 'Estonian', uk: 'Ukrainian',
    ar: 'Arabic', de: 'German', sv: 'Swedish', fr: 'French', tr: 'Turkish',
    fa: 'Persian', es: 'Spanish', pl: 'Polish', lt: 'Lithuanian', lv: 'Latvian',
    it: 'Italian', ro: 'Romanian'
};

const LANG_LABELS = {
    ru: { keyPoints: 'Ключевые моменты', ask: 'Спросите', terms: 'Термины', warning: 'Внимание', summary: 'Краткое содержание', decisions: 'Решения', actions: 'Действия', deadlines: 'Сроки', followUp: 'Дальнейшие шаги' },
    en: { keyPoints: 'Key Points', ask: 'Ask', terms: 'Terms', warning: 'Warning', summary: 'Summary', decisions: 'Decisions', actions: 'Action Items', deadlines: 'Deadlines', followUp: 'Follow-up' },
    fi: { keyPoints: 'Avainasiat', ask: 'Kysy', terms: 'Termit', warning: 'Huomio', summary: 'Yhteenveto', decisions: 'Päätökset', actions: 'Toimet', deadlines: 'Määräajat', followUp: 'Jatkotoimet' },
    et: { keyPoints: 'Põhipunktid', ask: 'Küsi', terms: 'Terminid', warning: 'Tähelepanu', summary: 'Kokkuvõte', decisions: 'Otsused', actions: 'Tegevused', deadlines: 'Tähtajad', followUp: 'Jätkutegevused' },
    uk: { keyPoints: 'Ключові моменти', ask: 'Запитайте', terms: 'Терміни', warning: 'Увага', summary: 'Зміст', decisions: 'Рішення', actions: 'Дії', deadlines: 'Терміни', followUp: 'Наступні кроки' },
    ar: { keyPoints: 'النقاط الرئيسية', ask: 'اسأل', terms: 'المصطلحات', warning: 'تحذير', summary: 'ملخص', decisions: 'القرارات', actions: 'الإجراءات', deadlines: 'المواعيد', followUp: 'المتابعة' },
    de: { keyPoints: 'Kernpunkte', ask: 'Fragen', terms: 'Begriffe', warning: 'Achtung', summary: 'Zusammenfassung', decisions: 'Entscheidungen', actions: 'Aufgaben', deadlines: 'Fristen', followUp: 'Nachverfolgung' },
    sv: { keyPoints: 'Nyckelpunkter', ask: 'Fråga', terms: 'Termer', warning: 'Varning', summary: 'Sammanfattning', decisions: 'Beslut', actions: 'Åtgärder', deadlines: 'Tidsfrister', followUp: 'Uppföljning' },
    fr: { keyPoints: 'Points clés', ask: 'Demandez', terms: 'Termes', warning: 'Attention', summary: 'Résumé', decisions: 'Décisions', actions: 'Actions', deadlines: 'Délais', followUp: 'Suivi' },
};

// Feature #8: Context-aware AI prompt
function getAiSystemPrompt() {
    const userLang = LANG_NAMES[state.userLanguage] || 'Russian';
    const listenLang = LANG_NAMES[state.language] || 'the call language';
    const labels = LANG_LABELS[state.userLanguage] || LANG_LABELS.en;

    let contextBlock = '';
    if (state.callContext.trim()) {
        contextBlock = `\n\nCALL CONTEXT (provided by the user before the call):\n${state.callContext}\nUse this context to provide more targeted and relevant advice.\n`;
    }

    return `You are a legal assistant helping an immigrant during a live phone call. The call is in ${listenLang}. You MUST respond in ${userLang}.${contextBlock}

Based on the transcript provided, give:

1. **${labels.keyPoints}** — What important things were just discussed (2-3 bullet points max)
2. **${labels.ask}** — What should the user ask right now (1-2 questions max)
3. **${labels.terms}** — Explain any legal terms mentioned in simple ${userLang}
4. **${labels.warning}** — Anything to watch out for or clarify

CRITICAL RULES:
- Keep responses SHORT and ACTIONABLE — the user is in a LIVE call
- ALWAYS respond in ${userLang} — this is the user's language
- The call may be in a DIFFERENT language (${listenLang}) — translate and explain for the user
- Focus on the most RECENT part of the conversation
- If the lawyer says something important about deadlines, rights, or documents — HIGHLIGHT IT
- Use simple bullet points, no long paragraphs
- Mark the most important key point with [IMPORTANT] prefix
- If you detect a deadline or date, mark it with [DEADLINE] prefix
- If something requires immediate action, mark with [ACTION] prefix

Format your response EXACTLY like this:
**${labels.keyPoints}:**
• point 1
• point 2

**${labels.ask}:**
• question

**${labels.terms}:**
• term — explanation

**${labels.warning}:**
• warning`;
}

async function requestAiAnalysis(segmentText) {
    const text = segmentText || state.fullTranscriptText.trim();
    if (!text || text.length < 20) return;
    if (!segmentText && text.length === state.lastTranscriptLen) return; // No new text

    const claudeKey = getClaudeKey();
    const proxyUrl = getProxyUrl();

    if (!claudeKey && !proxyUrl) return; // No AI configured

    if (!segmentText) {
        state.lastTranscriptLen = text.length;
    }

    // Show loading
    showAiLoading();

    // Take last 2000 chars for context efficiency
    const recentText = text.length > 2000 ? '...' + text.slice(-2000) : text;

    try {
        let aiResponse;

        if (proxyUrl) {
            // Use proxy
            const res = await fetch(proxyUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    transcript: recentText,
                    language: state.language,
                })
            });
            const data = await res.json();
            aiResponse = data.response || data.content || data.text || JSON.stringify(data);
        } else {
            // Direct Anthropic API call
            const res = await fetch('https://api.anthropic.com/v1/messages', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'x-api-key': claudeKey,
                    'anthropic-version': '2023-06-01',
                    'anthropic-dangerous-direct-browser-access': 'true',
                },
                body: JSON.stringify({
                    model: 'claude-sonnet-4-20250514',
                    max_tokens: 600,
                    system: getAiSystemPrompt(),
                    messages: [{
                        role: 'user',
                        content: `Here is the live call transcript so far:\n\n${recentText}\n\nProvide your analysis of the most recent discussion.`
                    }]
                })
            });

            if (!res.ok) {
                // Sanitize error — never expose raw API body (may echo back key)
                if (res.status === 401 || res.status === 403) throw new Error('Invalid API key. Please check your Claude API key in Settings.');
                if (res.status === 429) throw new Error('Rate limit exceeded. AI analysis will resume shortly.');
                if (res.status >= 500) throw new Error('AI service temporarily unavailable. Will retry automatically.');
                throw new Error('AI service error (' + res.status + '). Please try again.');
            }

            const data = await res.json();
            aiResponse = data.content?.[0]?.text || 'No response from AI';
        }

        displayAiResponse(aiResponse);
        extractKeyPoints(aiResponse);
        state.aiResponses.push({ time: getTimestamp(), text: aiResponse });

    } catch (err) {
        console.error('AI analysis error');
        hideAiLoading();
        // Show friendly message, never the raw error which might contain API key fragments
        const msg = (err.message && !err.message.includes('key=') && !err.message.includes('x-api-key'))
            ? err.message
            : 'AI service error. Please check your settings and try again.';
        displayAiError(msg);
    }
}

function showAiLoading() {
    // Remove previous loading indicator if any
    const existing = dom.aiArea.querySelector('.ai-loading');
    if (existing) existing.remove();

    const loading = document.createElement('div');
    loading.className = 'ai-loading';
    loading.innerHTML = `
        <div class="ai-loading-dots"><span></span><span></span><span></span></div>
        <span>Claude is analyzing...</span>
    `;
    dom.aiArea.appendChild(loading);
    dom.aiArea.scrollTop = dom.aiArea.scrollHeight;
}

function hideAiLoading() {
    const loading = dom.aiArea.querySelector('.ai-loading');
    if (loading) loading.remove();
}

function displayAiResponse(text) {
    hideAiLoading();
    if (dom.aiPlaceholder) dom.aiPlaceholder.style.display = 'none';

    const msg = document.createElement('div');
    msg.className = 'ai-message';

    const timeEl = document.createElement('div');
    timeEl.className = 'ai-message-time';
    timeEl.textContent = getTimestamp();

    const contentEl = document.createElement('div');
    contentEl.className = 'ai-message-content';
    // Sanitize text first (escape HTML), then apply markdown-like formatting
    const safeText = escapeHtml(text);
    contentEl.innerHTML = safeText
        .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
        .replace(/\[IMPORTANT\]/g, '<span style="color:#F87171;font-weight:700;">[IMPORTANT]</span>')
        .replace(/\[DEADLINE\]/g, '<span style="color:#FBBF24;font-weight:700;">[DEADLINE]</span>')
        .replace(/\[ACTION\]/g, '<span style="color:#34D399;font-weight:700;">[ACTION]</span>')
        .replace(/\n/g, '<br>');

    msg.appendChild(timeEl);
    msg.appendChild(contentEl);
    dom.aiArea.appendChild(msg);
    dom.aiArea.scrollTop = dom.aiArea.scrollHeight;
}

function displayAiError(message) {
    hideAiLoading();
    const msg = document.createElement('div');
    msg.className = 'ai-message';
    msg.style.borderLeftColor = '#EF4444';

    const contentEl = document.createElement('div');
    contentEl.className = 'ai-message-content';
    contentEl.style.color = '#EF4444';
    // Never display raw error messages that might contain API keys
    const safeMsg = (message || 'Unknown error').replace(/key[=:]\s*\S+/gi, 'key=[hidden]');
    contentEl.textContent = safeMsg;

    msg.appendChild(contentEl);
    dom.aiArea.appendChild(msg);
    dom.aiArea.scrollTop = dom.aiArea.scrollHeight;
}

// ============================================
// Key Points Extraction (Enhanced)
// Now parses [IMPORTANT], [DEADLINE], [ACTION]
// tags and adds timestamps to each key point.
// ============================================
function extractKeyPoints(aiResponse) {
    const lines = aiResponse.split('\n');
    const importantLines = lines.filter(line => {
        const trimmed = line.trim();
        return trimmed.includes('[IMPORTANT]') ||
               trimmed.includes('[DEADLINE]') ||
               trimmed.includes('[ACTION]') ||
               (trimmed.startsWith('•') && (
                   trimmed.includes('срок') || trimmed.includes('deadline') ||
                   trimmed.includes('документ') || trimmed.includes('document') ||
                   trimmed.includes('право') || trimmed.includes('right') ||
                   trimmed.includes('обязательно') || trimmed.includes('must') ||
                   trimmed.includes('IMPORTANT') || trimmed.includes('важно') ||
                   trimmed.includes('определ') || trimmed.includes('определ') ||
                   trimmed.includes('действи') || trimmed.includes('action')
               ));
    });

    importantLines.forEach(line => {
        const text = line.replace(/^[•\-\*]\s*/, '')
            .replace('[IMPORTANT]', '')
            .replace('[DEADLINE]', '')
            .replace('[ACTION]', '')
            .trim();
        if (text && !state.keyPoints.some(kp => kp.text === text)) {
            addKeyPoint(text);
        }
    });
}

function addKeyPoint(text) {
    const timestamp = getTimestamp();
    state.keyPoints.push({ time: timestamp, text });
    if (dom.keypointsPlaceholder) dom.keypointsPlaceholder.style.display = 'none';

    const li = document.createElement('li');
    li.innerHTML = `<span class="kp-time">${timestamp}</span>${escapeHtml(text)}`;
    dom.keypointsList.appendChild(li);
    dom.keypointsCount.textContent = state.keyPoints.length;

    // Scroll key points
    dom.keypointsList.parentElement.scrollTop = dom.keypointsList.parentElement.scrollHeight;
}

// ============================================
// Smart Pause Detection (Feature #1)
// Instead of rigid 15-second intervals, detect
// when a speaker finishes a thought (2-3s pause)
// or when a new topic begins (UtteranceEnd from
// Deepgram). Analyze the accumulated segment.
// ============================================
function resetPauseTimer() {
    if (state.pauseTimer) clearTimeout(state.pauseTimer);

    state.pauseTimer = setTimeout(() => {
        // Speaker paused for 2.5 seconds — they finished a thought
        const now = Date.now();
        // Minimum 8 seconds between AI requests to avoid spam
        if (now - state.lastAiRequestAt >= 8000 && state.pendingSegments.length > 0) {
            state.lastAiRequestAt = now;
            // Send only the recent pending segments for focused analysis
            const recentText = state.pendingSegments.map(s => s.text).join(' ');
            state.pendingSegments = [];
            requestAiAnalysis(state.fullTranscriptText.trim());
        }
    }, 2500); // 2.5 second pause = thought completed
}

// Called when Deepgram fires UtteranceEnd event — strong topic boundary signal
function onUtteranceEnd() {
    const now = Date.now();
    // If enough segments accumulated and enough time passed, trigger analysis
    if (state.pendingSegments.length >= 2 && now - state.lastAiRequestAt >= 8000) {
        state.lastAiRequestAt = now;
        state.pendingSegments = [];
        requestAiAnalysis(state.fullTranscriptText.trim());
    }
}

// Detect new topic: if there's a long pause (>5s) between segments,
// treat it as a topic change and always trigger analysis
function checkTopicChange() {
    if (!state.lastSpeechAt) return false;
    const silence = Date.now() - state.lastSpeechAt;
    return silence > 5000; // 5+ seconds silence = likely new topic
}

// ============================================
// Conversation Summary (Feature #7)
// Sends full transcript to Claude and generates
// structured summary with decisions, actions,
// deadlines, and follow-ups.
// ============================================
async function generateSummary() {
    const text = state.fullTranscriptText.trim();
    if (!text || text.length < 50) {
        alert('Not enough transcript to summarize. Please record more of the conversation.');
        return;
    }

    const claudeKey = getClaudeKey();
    const proxyUrl = getProxyUrl();
    if (!claudeKey && !proxyUrl) {
        alert('Please configure Claude API key or proxy URL in Settings to use the summary feature.');
        return;
    }

    const labels = LANG_LABELS[state.userLanguage] || LANG_LABELS.en;
    const userLang = LANG_NAMES[state.userLanguage] || 'Russian';

    // Show loading overlay
    const overlay = document.createElement('div');
    overlay.className = 'summary-overlay';
    overlay.id = 'summary-overlay';
    overlay.innerHTML = `
        <div class="summary-modal">
            <h2>${labels.summary}</h2>
            <div class="summary-content">
                <div class="ai-loading">
                    <div class="ai-loading-dots"><span></span><span></span><span></span></div>
                    <span>Generating summary...</span>
                </div>
            </div>
        </div>
    `;
    document.body.appendChild(overlay);

    const summaryPrompt = `You are a legal assistant. Analyze this complete call transcript and provide a structured summary in ${userLang}.

TRANSCRIPT:
${text}

${state.callContext ? `CALL CONTEXT: ${state.callContext}\n` : ''}

Provide a structured summary with these sections:
1. **${labels.summary}** — Brief overview of the call (3-5 sentences)
2. **${labels.decisions}** — What was decided during the call
3. **${labels.actions}** — What the user needs to do (action items)
4. **${labels.deadlines}** — Any deadlines or dates mentioned
5. **${labels.followUp}** — What needs to happen next

RESPOND IN ${userLang}. Be specific and actionable.`;

    try {
        let summaryText;

        if (proxyUrl) {
            const res = await fetch(proxyUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ transcript: summaryPrompt, language: state.language, type: 'summary' }),
            });
            const data = await res.json();
            summaryText = data.response || data.content || data.text || '';
        } else {
            const res = await fetch('https://api.anthropic.com/v1/messages', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'x-api-key': claudeKey,
                    'anthropic-version': '2023-06-01',
                    'anthropic-dangerous-direct-browser-access': 'true',
                },
                body: JSON.stringify({
                    model: 'claude-sonnet-4-20250514',
                    max_tokens: 1500,
                    messages: [{ role: 'user', content: summaryPrompt }],
                }),
            });

            if (!res.ok) {
                throw new Error(`API error ${res.status}`);
            }

            const data = await res.json();
            summaryText = data.content?.[0]?.text || 'No summary generated';
        }

        state.aiSummary = summaryText;

        // Update overlay with summary
        const modal = overlay.querySelector('.summary-modal');
        modal.innerHTML = `
            <h2>${labels.summary}</h2>
            <div class="summary-content">${summaryText
                .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
                .replace(/\n/g, '<br>')}</div>
            <div class="summary-close">
                <button class="btn btn-primary" onclick="this.closest('.summary-overlay').remove()">Close</button>
            </div>
        `;
    } catch (err) {
        console.error('Summary generation error:', err);
        const modal = overlay.querySelector('.summary-modal');
        modal.innerHTML = `
            <h2>Error</h2>
            <p style="color:#EF4444;">Failed to generate summary: ${escapeHtml(err.message)}</p>
            <div class="summary-close">
                <button class="btn btn-primary" onclick="this.closest('.summary-overlay').remove()">Close</button>
            </div>
        `;
    }
}

// ============================================
// Quick Response Templates (Feature #9)
// Shows pre-written phrases in both user's
// language and call language side by side.
// ============================================
function showQuickResponse(key) {
    const template = QUICK_RESPONSES[key];
    if (!template) return;

    const userLang = state.userLanguage;
    const callLang = state.language;

    const userText = template[userLang] || template.en || '';
    const callText = template[callLang] || template.en || '';

    const output = dom.quickOutput;
    if (!output) return;

    // If both are the same language, just show one
    if (userLang === callLang) {
        output.innerHTML = `<span class="quick-user-lang">${escapeHtml(userText)}</span>`;
    } else {
        output.innerHTML = `
            <span class="quick-user-lang">${escapeHtml(userText)}</span><br>
            <span class="quick-call-lang">${escapeHtml(callText)}</span>
        `;
    }
    output.style.display = 'block';

    // Auto-hide after 8 seconds
    clearTimeout(output._hideTimer);
    output._hideTimer = setTimeout(() => {
        output.style.display = 'none';
    }, 8000);
}

// ============================================
// Export (Enhanced — Feature #10)
// Exports as both TXT and HTML with full
// transcript, speaker labels, key points,
// AI summary, and action items.
// ============================================
function exportTranscript() {
    const now = new Date().toLocaleString();
    const dateStr = new Date().toISOString().slice(0, 10);

    // ---- TXT Export ----
    const txtLines = [];
    txtLines.push('ADVOCAT — Call Transcript');
    txtLines.push('========================');
    txtLines.push(`Date: ${now}`);
    txtLines.push(`Duration: ${formatTime(state.timerSeconds)}`);
    txtLines.push(`Call Language: ${LANG_NAMES[state.language] || state.language}`);
    txtLines.push(`User Language: ${LANG_NAMES[state.userLanguage] || state.userLanguage}`);
    txtLines.push(`Mode: ${state.mode}`);
    if (state.callContext) {
        txtLines.push(`Context: ${state.callContext}`);
    }
    txtLines.push('');
    txtLines.push('TRANSCRIPT');
    txtLines.push('----------');

    state.transcript.forEach(seg => {
        const label = seg.label || getSpeakerLabel(seg.speaker);
        const urgMark = seg.isUrgent ? ' [URGENT]' : '';
        txtLines.push(`[${seg.time}] ${label}: ${seg.text}${urgMark}`);
    });

    txtLines.push('');
    txtLines.push('KEY POINTS');
    txtLines.push('----------');
    if (state.keyPoints.length === 0) {
        txtLines.push('(no key points recorded)');
    } else {
        state.keyPoints.forEach((kp, i) => {
            txtLines.push(`[${kp.time}] ${i + 1}. ${kp.text}`);
        });
    }

    if (state.aiSummary) {
        txtLines.push('');
        txtLines.push('AI SUMMARY');
        txtLines.push('----------');
        txtLines.push(state.aiSummary);
    }

    txtLines.push('');
    txtLines.push('AI ANALYSIS LOG');
    txtLines.push('---------------');
    state.aiResponses.forEach(ar => {
        txtLines.push(`[${ar.time}]`);
        txtLines.push(ar.text);
        txtLines.push('---');
    });

    txtLines.push('');
    txtLines.push('FULL TEXT');
    txtLines.push('--------');
    txtLines.push(state.fullTranscriptText || '(empty)');

    // Download TXT
    const txtBlob = new Blob([txtLines.join('\n')], { type: 'text/plain;charset=utf-8' });
    const txtUrl = URL.createObjectURL(txtBlob);
    const txtA = document.createElement('a');
    txtA.href = txtUrl;
    txtA.download = `advocat-transcript-${dateStr}.txt`;
    txtA.click();
    URL.revokeObjectURL(txtUrl);

    // ---- HTML Export ----
    const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>ADVOCAT Call Transcript — ${dateStr}</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; max-width: 800px; margin: 40px auto; padding: 20px; background: #0D0D1A; color: #E0E0E0; }
        h1 { color: #A5B4FC; border-bottom: 2px solid #6C63FF; padding-bottom: 8px; }
        h2 { color: #FBBF24; margin-top: 32px; }
        .meta { color: #888; font-size: 14px; margin-bottom: 24px; }
        .segment { margin: 8px 0; padding: 8px 12px; border-left: 3px solid #333; border-radius: 4px; }
        .segment.lawyer { border-left-color: #6C63FF; }
        .segment.you { border-left-color: #34D399; }
        .segment .label { font-size: 11px; font-weight: 700; text-transform: uppercase; }
        .segment .label.lawyer { color: #6C63FF; }
        .segment .label.you { color: #34D399; }
        .segment .time { color: #666; font-size: 12px; margin-left: 8px; }
        .segment .text { display: block; margin-top: 4px; }
        .urgent { color: #F87171; font-weight: 700; font-size: 10px; }
        .keypoint { margin: 6px 0; padding: 6px 12px; background: rgba(108,99,255,0.1); border-radius: 6px; }
        .keypoint .kp-time { color: #888; font-size: 12px; margin-right: 8px; }
        .summary { background: rgba(251,191,36,0.08); border: 1px solid rgba(251,191,36,0.2); border-radius: 8px; padding: 16px; margin-top: 16px; line-height: 1.7; }
        .ai-log { background: rgba(255,255,255,0.03); padding: 12px; border-radius: 6px; margin: 8px 0; font-size: 13px; }
        .ai-log .ai-time { color: #888; font-size: 11px; }
    </style>
</head>
<body>
    <h1>ADVOCAT Call Transcript</h1>
    <div class="meta">
        <p>Date: ${now} | Duration: ${formatTime(state.timerSeconds)}</p>
        <p>Call Language: ${LANG_NAMES[state.language] || state.language} | User Language: ${LANG_NAMES[state.userLanguage] || state.userLanguage}</p>
        ${state.callContext ? `<p>Context: ${escapeHtml(state.callContext)}</p>` : ''}
    </div>

    <h2>Transcript</h2>
    ${state.transcript.map(seg => {
        const label = seg.label || getSpeakerLabel(seg.speaker);
        const isLawyer = label === 'Lawyer';
        return `<div class="segment ${isLawyer ? 'lawyer' : 'you'}">
            <span class="label ${isLawyer ? 'lawyer' : 'you'}">${label}</span>
            <span class="time">${seg.time}</span>
            ${seg.isUrgent ? '<span class="urgent"> [URGENT]</span>' : ''}
            <span class="text">${escapeHtml(seg.text)}</span>
        </div>`;
    }).join('\n')}

    <h2>Key Points</h2>
    ${state.keyPoints.length === 0 ? '<p>(no key points recorded)</p>' :
        state.keyPoints.map((kp, i) =>
            `<div class="keypoint"><span class="kp-time">[${kp.time}]</span> ${i + 1}. ${escapeHtml(kp.text)}</div>`
        ).join('\n')}

    ${state.aiSummary ? `<h2>AI Summary</h2><div class="summary">${state.aiSummary.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>').replace(/\n/g, '<br>')}</div>` : ''}

    <h2>AI Analysis Log</h2>
    ${state.aiResponses.map(ar => `
        <div class="ai-log">
            <div class="ai-time">[${ar.time}]</div>
            <div>${ar.text.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>').replace(/\n/g, '<br>')}</div>
        </div>
    `).join('\n')}
</body>
</html>`;

    // Download HTML
    const htmlBlob = new Blob([htmlContent], { type: 'text/html;charset=utf-8' });
    const htmlUrl = URL.createObjectURL(htmlBlob);
    const htmlA = document.createElement('a');
    htmlA.href = htmlUrl;
    htmlA.download = `advocat-transcript-${dateStr}.html`;
    htmlA.click();
    URL.revokeObjectURL(htmlUrl);
}

// ============================================
// Clear Transcript
// ============================================
function clearTranscript() {
    if (!confirm('Clear all transcript data?')) return;
    state.transcript = [];
    state.fullTranscriptText = '';
    state.lastTranscriptLen = 0;
    state.keyPoints = [];
    state.pendingSegments = [];
    state.currentTopicSegments = [];
    state.speakerWordCounts = {};
    state.speakerLabels = {};
    state.recentConfidences = [];
    state.pendingTranslations = [];
    state.aiResponses = [];
    state.aiSummary = '';

    // Clear transcript area
    dom.transcriptArea.innerHTML = '';
    const placeholder = document.createElement('div');
    placeholder.className = 'transcript-placeholder';
    placeholder.id = 'transcript-placeholder';
    placeholder.innerHTML = '<p>Transcript will appear here when you start listening.</p><p class="hint">Press the <strong>Start Listening</strong> button below to begin.</p>';
    dom.transcriptArea.appendChild(placeholder);

    // Clear key points
    dom.keypointsList.innerHTML = '';
    dom.keypointsCount.textContent = '0';
    if (dom.keypointsPlaceholder) dom.keypointsPlaceholder.style.display = 'block';

    // Reset audio quality
    if (dom.audioQualityBadge) {
        dom.audioQualityBadge.textContent = 'Audio: --';
        dom.audioQualityBadge.className = 'audio-quality-badge quality-good';
    }

    updateWordCount();
}

// ============================================
// Start / Stop Listening
// ============================================
async function startListening() {
    if (state.isListening) return;

    // Capture context from input
    if (dom.callContextInput) {
        state.callContext = dom.callContextInput.value.trim();
    }

    // Start microphone first
    const micOk = await startMicrophone();
    if (!micOk) return;

    state.isListening = true;
    dom.startBtn.classList.add('active');
    dom.startBtn.setAttribute('aria-pressed', 'true');
    dom.startBtn.setAttribute('aria-label', 'Stop listening');
    dom.startBtnText.textContent = 'Stop Listening';

    // Hide context input, show quick responses
    if (dom.callContextArea) dom.callContextArea.classList.add('hidden');
    if (dom.quickResponses) dom.quickResponses.style.display = 'flex';

    startTimer();

    // Start transcription based on mode
    let started = false;
    if (state.mode === 'deepgram') {
        started = startDeepgram();
    } else {
        started = startDemoMode();
    }

    if (!started) {
        stopListening();
        return;
    }

    // Start periodic AI analysis as fallback (every 20 seconds)
    // Smart pause detection handles most triggers, but this ensures
    // analysis happens even with continuous speech (no pauses)
    state.lastAiRequestAt = Date.now();
    state.aiInterval = setInterval(() => {
        state.lastAiRequestAt = Date.now();
        requestAiAnalysis();
    }, 20000); // 20 seconds fallback (was 15s, now smarter pause takes over)
}

function stopListening() {
    state.isListening = false;
    dom.startBtn.classList.remove('active');
    dom.startBtn.setAttribute('aria-pressed', 'false');
    dom.startBtn.setAttribute('aria-label', 'Start listening');
    dom.startBtnText.textContent = 'Start Listening';

    setStatus('', 'Stopped');
    stopTimer();
    showInterim('');

    // Show context input again, hide quick responses
    if (dom.callContextArea) dom.callContextArea.classList.remove('hidden');
    if (dom.quickResponses) dom.quickResponses.style.display = 'none';
    if (dom.quickOutput) dom.quickOutput.style.display = 'none';

    // Stop transcription
    stopDeepgram();
    stopDemoMode();
    stopMicrophone();

    // Stop AI interval
    if (state.aiInterval) {
        clearInterval(state.aiInterval);
        state.aiInterval = null;
    }
    if (state.pauseTimer) {
        clearTimeout(state.pauseTimer);
        state.pauseTimer = null;
    }
    if (state.translationTimer) {
        clearTimeout(state.translationTimer);
        state.translationTimer = null;
    }

    // Final AI analysis
    requestAiAnalysis();

    // Flush pending translations
    runBatchTranslation();

    // Reset reconnection state
    state.reconnectAttempts = 0;
    state.isReconnecting = false;
    hideReconnectFlash();
}

// ============================================
// Language / Mode change
// ============================================
function onLanguageChange() {
    state.language = dom.languageSelect.value;
    localStorage.setItem('advocat_language', state.language);

    // If currently listening, restart with new language
    if (state.isListening) {
        stopDeepgram();
        stopDemoMode();

        if (state.mode === 'deepgram') {
            startDeepgram();
        } else {
            startDemoMode();
        }
    }
}

function onModeChange() {
    state.mode = dom.modeSelect.value;
    localStorage.setItem('advocat_mode', state.mode);

    // If currently listening, restart with new mode
    if (state.isListening) {
        stopDeepgram();
        stopDemoMode();

        if (state.mode === 'deepgram') {
            startDeepgram();
        } else {
            startDemoMode();
        }
    }
}

// ============================================
// Event Listeners
// ============================================
function initEventListeners() {
    // Settings
    dom.settingsBtn.addEventListener('click', () => {
        loadSettings();
        dom.settingsModal.style.display = 'flex';
    });
    dom.saveSettings.addEventListener('click', saveSettings);
    dom.cancelSettings.addEventListener('click', () => {
        dom.settingsModal.style.display = 'none';
    });
    dom.settingsModal.addEventListener('click', (e) => {
        if (e.target === dom.settingsModal) dom.settingsModal.style.display = 'none';
    });

    // Controls
    dom.startBtn.addEventListener('click', () => {
        if (state.isListening) {
            stopListening();
        } else {
            startListening();
        }
    });

    dom.testMicBtn.addEventListener('click', testMicrophone);
    dom.exportBtn.addEventListener('click', exportTranscript);
    dom.clearTranscript.addEventListener('click', clearTranscript);
    dom.askAiNow.addEventListener('click', () => {
        state.lastAiRequestAt = Date.now();
        requestAiAnalysis();
    });

    // Summary button
    if (dom.summaryBtn) {
        dom.summaryBtn.addEventListener('click', generateSummary);
    }

    // Quick response buttons
    document.addEventListener('click', (e) => {
        if (e.target.classList.contains('btn-quick')) {
            const key = e.target.dataset.key;
            if (key) showQuickResponse(key);
        }
    });

    // Glossary tooltip events (event delegation on transcript area)
    dom.transcriptArea.addEventListener('mouseover', showGlossaryTooltip);
    dom.transcriptArea.addEventListener('mouseout', (e) => {
        if (e.target.classList.contains('legal-term')) {
            hideGlossaryTooltip();
        }
    });
    // Touch support for mobile
    dom.transcriptArea.addEventListener('touchstart', (e) => {
        if (e.target.classList.contains('legal-term')) {
            showGlossaryTooltip(e);
            setTimeout(hideGlossaryTooltip, 3000);
        }
    });

    // Language / Mode
    dom.languageSelect.addEventListener('change', onLanguageChange);
    if (dom.userLanguageSelect) {
        dom.userLanguageSelect.addEventListener('change', () => {
            state.userLanguage = dom.userLanguageSelect.value;
            localStorage.setItem('advocat_user_language', state.userLanguage);
        });
    }
    dom.modeSelect.addEventListener('change', onModeChange);

    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
        // Space to toggle (when not focused on input)
        if (e.code === 'Space' && !['INPUT', 'TEXTAREA', 'SELECT'].includes(e.target.tagName)) {
            e.preventDefault();
            if (state.isListening) {
                stopListening();
            } else {
                startListening();
            }
        }
        // Escape to stop
        if (e.code === 'Escape' && state.isListening) {
            stopListening();
        }
        // Ctrl+E to export
        if (e.ctrlKey && e.code === 'KeyE') {
            e.preventDefault();
            exportTranscript();
        }
        // Ctrl+S to summary
        if (e.ctrlKey && e.code === 'KeyS') {
            e.preventDefault();
            generateSummary();
        }
    });
}

// ============================================
// Init
// ============================================
function init() {
    // === Security checks ===
    // 1. HTTPS enforcement
    if (location.protocol !== 'https:' && location.hostname !== 'localhost' && location.hostname !== '127.0.0.1' && location.hostname !== '0.0.0.0') {
        const httpsWarn = document.getElementById('https-warning');
        if (httpsWarn) httpsWarn.style.display = 'block';
        console.warn('ADVOCAT: Microphone requires HTTPS or localhost.');
    }

    // 2. Browser compatibility checks
    (function checkBrowserCompat() {
        const issues = [];
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) issues.push('getUserMedia (microphone) is not supported.');
        if (!window.WebSocket) issues.push('WebSocket is not supported (required for Deepgram).');
        if (typeof MediaRecorder === 'undefined') {
            issues.push('MediaRecorder is not supported. Safari users: use Chrome or Firefox for best results.');
        } else if (MediaRecorder.isTypeSupported && !MediaRecorder.isTypeSupported('audio/webm;codecs=opus') && !MediaRecorder.isTypeSupported('audio/webm')) {
            issues.push('audio/webm not supported. Some features may be limited in Safari.');
        }
        if (!window.AudioContext && !window.webkitAudioContext) issues.push('AudioContext not supported (needed for volume meter).');
        if (issues.length > 0) {
            const bwEl = document.getElementById('browser-warning');
            if (bwEl) {
                bwEl.innerHTML = '<strong>Browser Compatibility:</strong> ' + issues.join(' ');
                bwEl.style.display = 'block';
            }
        }
    })();

    // 3. Privacy notice (shown once)
    if (localStorage.getItem('advocat_privacy_accepted') !== '1') {
        const pn = document.getElementById('privacy-notice');
        if (pn) pn.style.display = 'flex';
    }
    const acceptBtn = document.getElementById('accept-privacy');
    if (acceptBtn) {
        acceptBtn.addEventListener('click', () => {
            const smCheck = document.getElementById('privacy-secure-mode');
            if (smCheck && smCheck.checked) {
                state.secureMode = true;
                localStorage.setItem('advocat_secure_mode', '1');
                const stCheck = document.getElementById('settings-secure-mode');
                if (stCheck) stCheck.checked = true;
            }
            localStorage.setItem('advocat_privacy_accepted', '1');
            const pn = document.getElementById('privacy-notice');
            if (pn) pn.style.display = 'none';
        });
    }

    // 4. Secure Mode: auto-delete transcript on page close
    window.addEventListener('beforeunload', () => {
        if (state.secureMode) {
            localStorage.removeItem('advocat_transcript');
            localStorage.removeItem('advocat_keypoints');
        }
    });
    window.addEventListener('pagehide', () => {
        if (state.secureMode) {
            localStorage.removeItem('advocat_transcript');
            localStorage.removeItem('advocat_keypoints');
        }
    });

    // 5. PIN unlock listener in settings
    const pinInput = document.getElementById('pin-code');
    if (pinInput) {
        pinInput.addEventListener('input', async () => {
            const pin = pinInput.value.trim();
            if (pin.length >= 4 && localStorage.getItem('advocat_has_pin') === '1') {
                await _unlockKeys(pin);
            }
            _updatePinWarning();
        });
    }

    // === Inject enhanced UI elements and styles ===
    injectEnhancedCSS();
    injectEnhancedUI();

    loadSettings();
    initEventListeners();

    // Load saved context if any
    const savedContext = localStorage.getItem('advocat_call_context') || '';
    if (dom.callContextInput && savedContext) {
        dom.callContextInput.value = savedContext;
    }
    if (dom.callContextInput) {
        dom.callContextInput.addEventListener('input', () => {
            localStorage.setItem('advocat_call_context', dom.callContextInput.value);
        });
    }

    console.log('ADVOCAT Live Call Assistant initialized (security-hardened).');
    console.log('Shortcuts: Space = Start/Stop, Escape = Stop, Ctrl+E = Export, Ctrl+S = Summary');
}

// Start when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
