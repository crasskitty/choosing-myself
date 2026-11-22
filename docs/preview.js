// Day count matches StreakMath: the start date is day 1, and the next local
// midnight is day 2. The UTC conversion keeps a daylight-saving boundary
// from shifting the count by a day.

const KEY = "choosing-myself-preview-v1";
const MILESTONES = [7, 30, 60, 90, 365];
const FREE_LIMIT = 3;
const FALLBACK_LINES = [
  "you chose yourself. that still counts.",
  "the urge will crest. you do not have to follow it.",
  "silence is a promise you kept today.",
  "missing them is not an instruction."
];
const THEMES = {
  rain: { title: "Rain", caption: "Glass, weather, a still room.", colors: ["#070B10", "#101820", "#1A3144"] },
  nightDrive: { title: "Night Drive", caption: "Amber lights on a long road.", colors: ["#070605", "#120E0B", "#1C140E"] },
  ocean: { title: "Ocean", caption: "Dark water, a slow tide.", colors: ["#041016", "#06242E", "#0C3A44"] }
};
const MILESTONE_COPY = {
  7: "A week of keeping your word.",
  30: "A month of choosing yourself.",
  60: "Two months on your side of the quiet.",
  90: "A season of not going back.",
  365: "A year. You stayed."
};

let lines = FALLBACK_LINES.slice();
let state = load();
let breathFrame = 0;
let focusDraft = false;

const app = document.getElementById("app");

function fresh() {
  return {
    onboarded: false,
    page: 0,
    startDate: todayISO(),
    nickname: "",
    theme: "rain",
    ownedTheme: "rain",
    unlocked: false,
    letters: [],
    bestStreak: 1,
    tab: "home",
    overlay: null,
    urgeStage: "breathe",
    breathStart: 0,
    draft: "",
    openLetterId: null,
    shareDays: null,
    confirm: null,
    reminderOn: false,
    reminderTime: "21:00",
    paywallIntent: null,
    notice: ""
  };
}

function load() {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return fresh();
    const data = JSON.parse(raw);
    const next = { ...fresh(), ...data, confirm: null };
    next.letters = Array.isArray(data.letters) ? data.letters.filter((item) => item && item.text) : [];
    if (!THEMES[next.theme]) next.theme = "rain";
    if (!THEMES[next.ownedTheme]) next.ownedTheme = "rain";
    if (!next.startDate) next.startDate = todayISO();
    return next;
  } catch {
    return fresh();
  }
}

function save() {
  const copy = { ...state, confirm: null };
  localStorage.setItem(KEY, JSON.stringify(copy));
}

function esc(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function todayISO(date = new Date()) {
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${date.getFullYear()}-${month}-${day}`;
}

function parseDay(iso) {
  const [year, month, day] = iso.split("-").map(Number);
  return new Date(year, month - 1, day);
}

function daysBetween(start, end) {
  const utcStart = Date.UTC(start.getFullYear(), start.getMonth(), start.getDate());
  const utcEnd = Date.UTC(end.getFullYear(), end.getMonth(), end.getDate());
  return Math.round((utcEnd - utcStart) / 86400000);
}

function clampStart(iso) {
  const today = todayISO();
  if (!iso || iso > today) return today;
  const earliest = new Date();
  earliest.setFullYear(earliest.getFullYear() - 20);
  const floor = todayISO(earliest);
  return iso < floor ? floor : iso;
}

function dayCount(startISO, date = new Date()) {
  const start = parseDay(clampStart(startISO));
  const end = parseDay(todayISO(date));
  return Math.max(1, daysBetween(start, end) + 1);
}

function lineIndex(date, source) {
  const count = Math.max(source.length, 1);
  const anchor = new Date(2001, 0, 1);
  const delta = daysBetween(anchor, parseDay(todayISO(date)));
  const remainder = delta % count;
  return remainder >= 0 ? remainder : remainder + count;
}

function lineFor(date = new Date()) {
  const source = lines.length ? lines : FALLBACK_LINES;
  return source[lineIndex(date, source)];
}

function cleanNickname(raw) {
  return String(raw).replace(/\n/g, " ").trim().slice(0, 24);
}

function personReference(raw) {
  const cleaned = cleanNickname(raw);
  return cleaned || "them";
}

function urgeTitle(raw) {
  const name = personReference(raw);
  return name.endsWith(".") ? `I want to text ${name}` : `I want to text ${name}.`;
}

function unit(days) {
  return days === 1 ? "day" : "days";
}

function since(iso) {
  const formatted = parseDay(iso).toLocaleDateString("en-US", {
    month: "long",
    day: "numeric",
    year: "numeric"
  });
  return `since ${formatted}`;
}

function letterDate(iso) {
  return new Date(iso).toLocaleDateString("en-US", {
    day: "numeric",
    month: "short",
    year: "numeric"
  });
}

function effectiveTheme() {
  return state.unlocked ? state.theme : state.ownedTheme;
}

function canSave(count = state.letters.length) {
  return state.unlocked || count < FREE_LIMIT;
}

function icon(name) {
  const paths = {
    home: '<path fill="currentColor" d="M14.6 3.4a7.2 7.2 0 1 0 5.5 11.6A6.4 6.4 0 0 1 14.6 3.4z"/>',
    letters: '<path fill="none" stroke="currentColor" stroke-width="1.6" d="M3.5 7h17v10.5h-17zM4 7.6 12 13l8-5.4"/>',
    milestones: '<circle cx="12" cy="12" r="7" fill="none" stroke="currentColor" stroke-width="1.6"/><circle cx="12" cy="12" r="2" fill="currentColor"/>',
    settings: '<path fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" d="M4 8h16M4 12h16M4 16h16"/><circle cx="9" cy="8" r="1.6" fill="currentColor"/><circle cx="15" cy="12" r="1.6" fill="currentColor"/><circle cx="8" cy="16" r="1.6" fill="currentColor"/>',
    rain: '<path fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" d="M7 15a4 4 0 1 1 .7-7.9A5 5 0 0 1 17 9a3.2 3.2 0 0 1 .2 6.4M9 18.5v.5M12 18.5v.5M15 18.5v.5"/>',
    nightDrive: '<path fill="currentColor" d="M4 14.5 6 10h8l3 2h3v2.5H4zM7 16.2a1.4 1.4 0 1 0 0 .1zM16.5 16.2a1.4 1.4 0 1 0 0 .1z"/>',
    ocean: '<path fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" d="M3 14c2 0 2-2 4-2s2 2 4 2 2-2 4-2 2 2 4 2M3 18c2 0 2-2 4-2s2 2 4 2 2-2 4-2 2 2 4 2"/>',
    check: '<path fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" d="M5 12.5 9.2 17 19 7"/>'
  };
  return `<svg viewBox="0 0 24 24" aria-hidden="true">${paths[name] || ""}</svg>`;
}

function swatch(id) {
  const colors = THEMES[id].colors.join(", ");
  return `style="background: linear-gradient(135deg, ${colors})"`;
}

function shownBest() {
  const current = state.onboarded ? dayCount(state.startDate) : 1;
  return Math.max(state.bestStreak, current);
}

function syncBest() {
  if (!state.onboarded) return;
  const current = dayCount(state.startDate);
  if (current > state.bestStreak) state.bestStreak = current;
}

function render() {
  syncBest();
  save();
  app.dataset.theme = state.onboarded ? effectiveTheme() : (THEMES[state.theme] ? state.theme : "rain");
  app.innerHTML = state.onboarded ? shell() : onboarding();
  const draft = document.getElementById("draft");
  if (draft) {
    draft.value = state.draft;
    const ghost = document.getElementById("ghost");
    if (ghost) ghost.style.visibility = state.draft ? "hidden" : "visible";
    if (focusDraft) {
      draft.focus();
      focusDraft = false;
    }
  }
  const nickname = document.getElementById("nickname");
  if (nickname) nickname.value = state.nickname;
  const settingsName = document.getElementById("settings-name");
  if (settingsName) settingsName.value = state.nickname;
  startBreath();
}

function onboarding() {
  const pages = [introPage(), datePage(), moodPage()];
  return `
    <div class="view">
      <div class="scroll">${pages[state.page] || pages[0]}</div>
      <div class="dock">
        <div class="dots" aria-hidden="true">
          ${[0, 1, 2].map((index) => `<i class="${index === state.page ? "on" : ""}"></i>`).join("")}
        </div>
        <button class="solid" data-action="advance">${state.page < 2 ? "Continue" : "Begin"}</button>
      </div>
    </div>`;
}

function introPage() {
  return `
    <div class="stack center-copy">
      <p class="handle">choosing.myself</p>
      <h1 class="display">You chose yourself.</h1>
      <p class="prose">A private count of the days. A place for the message you don't send. Nothing here leaves this phone.</p>
    </div>`;
}

function datePage() {
  const earliest = new Date();
  earliest.setFullYear(earliest.getFullYear() - 20);
  const days = dayCount(state.startDate);
  return `
    <div class="stack">
      <h1 class="display small">When did the quiet start?</h1>
      <label class="field" for="start-date">No contact started
        <input id="start-date" type="date" min="${todayISO(earliest)}" max="${todayISO()}" value="${esc(clampStart(state.startDate))}">
      </label>
      <p class="hint" id="day-preview">That is day ${days} today.</p>
      <label class="field" for="nickname">What do you call them?
        <input id="nickname" type="text" maxlength="24" placeholder="him" autocomplete="off" autocapitalize="off" spellcheck="false">
      </label>
      <p class="hint">Optional. Only so the button can say “I want to text him.” It stays on this phone.</p>
    </div>`;
}

function moodPage() {
  const choices = Object.entries(THEMES).map(([id, theme]) => `
    <button class="choice ${state.theme === id ? "on" : ""}" data-action="pick-theme" data-theme="${id}">
      <span class="swatch" ${swatch(id)}>${icon(id === "nightDrive" ? "nightDrive" : id)}</span>
      <span><b>${esc(theme.title)}</b><small>${esc(theme.caption)}</small></span>
      ${state.theme === id ? `<span class="tick">${icon("check")}</span>` : ""}
    </button>`).join("");
  return `
    <div class="stack">
      <h1 class="display small">Where should this feel like?</h1>
      <p class="hint">You can keep this one. The others wait with the unlock.</p>
      ${choices}
    </div>`;
}

function shell() {
  return `
    <div class="view">${tabBody()}</div>
    ${state.overlay ? "" : tabBar()}
    ${overlay()}
    ${confirmSheet()}`;
}

function tabBar() {
  const tabs = [
    ["home", "Home"],
    ["letters", "Letters"],
    ["milestones", "Milestones"],
    ["settings", "Settings"]
  ];
  return `<nav class="tabbar">${tabs.map(([id, label]) => `
    <button class="tab ${state.tab === id ? "on" : ""}" data-action="tab" data-tab="${id}" aria-label="${label}">
      ${icon(id)}<span>${label}</span>
    </button>`).join("")}</nav>`;
}

function tabBody() {
  if (state.tab === "letters") return lettersTab();
  if (state.tab === "milestones") return milestonesTab();
  if (state.tab === "settings") return settingsTab();
  return homeTab();
}

function homeTab() {
  const days = dayCount(state.startDate);
  const showBest = state.unlocked && state.bestStreak > days;
  const marked = MILESTONES.includes(days)
    ? `<p class="mark">Today marks ${days} ${unit(days)}.</p>`
    : "";
  return `
    <div class="home">
      <p class="handle">choosing.myself</p>
      <div class="grow"></div>
      <p class="day">${days}</p>
      <p class="day-label">${unit(days)} of choosing yourself</p>
      <p class="since">${esc(since(state.startDate))}</p>
      ${showBest ? `<p class="best">best ${state.bestStreak}</p>` : ""}
      ${marked}
      <div class="grow"></div>
      <p class="eyebrow">today</p>
      <p class="line">${esc(lineFor())}</p>
      <div class="grow"></div>
      <button class="solid" data-action="open-urge">${esc(urgeTitle(state.nickname))}</button>
      <p class="quiet">The count stays. Nothing sends.</p>
    </div>`;
}

function lettersTab() {
  const header = `
    <div class="header">
      <p class="eyebrow">unsent</p>
      <h2>Letters</h2>
      <p>What you didn't send.</p>
    </div>`;
  if (!state.letters.length) {
    return `
      <div class="scroll">
        ${header}
        <div class="empty">
          <h2>Nothing locked away</h2>
          <p>When the urge comes, write it here instead of sending it.</p>
        </div>
      </div>`;
  }
  const rows = [...state.letters].reverse().map((letter) => `
    <button class="letter" data-action="open-letter" data-id="${esc(letter.id)}">
      <time>${esc(letterDate(letter.at))}</time>
      <span>${esc(letter.text)}</span>
    </button>`).join("");
  const footer = state.unlocked
    ? "These stay on this phone."
    : `${state.letters.length} kept. The free version holds ${FREE_LIMIT}.`;
  return `<div class="scroll">${header}${rows}<p class="footer-note">${footer}</p></div>`;
}

function milestonesTab() {
  const days = dayCount(state.startDate);
  const next = MILESTONES.find((item) => days < item);
  const subtitle = next
    ? `Day ${days}. ${next - days} ${unit(next - days)} until ${next}.`
    : `Day ${days}. A year, and the days after.`;
  const rows = MILESTONES.map((milestone, index) => {
    const earned = days >= milestone;
    const extra = earned
      ? `<button class="go" data-action="share-or-unlock" data-days="${milestone}">${state.unlocked ? "Share card" : "Unlock to share"}</button>`
      : `<p>${milestone - days} to go</p>`;
    return `
      <div class="mile">
        <div class="rail"><i class="${earned ? "on" : ""}"></i>${index < MILESTONES.length - 1 ? "<b></b>" : ""}</div>
        <div class="${earned ? "" : "dim"}" style="padding-bottom: 22px">
          <h3>${milestone} ${unit(milestone)}</h3>
          <p>${MILESTONE_COPY[milestone]}</p>
          ${extra}
        </div>
      </div>`;
  }).join("");
  return `
    <div class="scroll">
      <div class="header">
        <p class="eyebrow">kept</p>
        <h2>Milestones</h2>
        <p>${subtitle}</p>
      </div>
      ${rows}
    </div>`;
}

function settingsTab() {
  const days = dayCount(state.startDate);
  const moods = Object.entries(THEMES).map(([id, theme]) => `
    <button class="choice ${effectiveTheme() === id ? "on" : ""}" data-action="settings-theme" data-theme="${id}">
      <span class="swatch" ${swatch(id)}>${icon(id === "nightDrive" ? "nightDrive" : id)}</span>
      <span><b>${esc(theme.title)}</b><small>${esc(theme.caption)}</small></span>
      ${effectiveTheme() === id ? `<span class="tick">${icon("check")}</span>` : ""}
    </button>`).join("");
  const time = state.reminderOn
    ? `<label class="field" for="reminder-time">Time
         <input id="reminder-time" type="time" value="${esc(state.reminderTime)}">
       </label>
       <p class="note">The iPhone app asks permission and schedules the next 14 days. This browser cannot notify you.</p>`
    : `<p class="note">The reminder is today's line, not your letters. It can show on the Lock Screen.</p>`;
  const lock = state.unlocked
    ? `<p class="note">Face ID or your passcode locks the iPhone app. This browser cannot lock the screen, so the preview stays open.</p>`
    : `<button class="toggle" data-action="open-paywall">Passcode lock <span class="switch" aria-hidden="true"><i></i></span></button>
       <p class="note">On iPhone, after the unlock.</p>`;
  const purchase = state.unlocked
    ? `<div class="row"><span>Status</span><b>Unlocked</b></div>`
    : `<button class="text-btn" data-action="open-paywall" style="justify-content: flex-start">Unlock the rest</button>`;
  return `
    <div class="scroll">
      <div class="header">
        <p class="eyebrow">this phone</p>
        <h2>Settings</h2>
        <p>Nothing here is an account.</p>
      </div>
      ${state.unlocked ? "" : `
        <button class="card-link" data-action="open-paywall">
          <strong>The rest of the room</strong>
          <span>All moods, unlimited letters, the lock, share cards, and the widget.</span>
          <em>One-time unlock</em>
        </button>`}
      <section class="block">
        <h3>Mood</h3>
        ${moods}
        <p class="note">The mood you picked at the start stays free.</p>
      </section>
      <section class="block">
        <h3>Daily line</h3>
        <button class="toggle" data-action="toggle-reminder">Reminder
          <span class="switch ${state.reminderOn ? "on" : ""}" aria-hidden="true"><i></i></span>
        </button>
        ${time}
      </section>
      <section class="block">
        <h3>Privacy</h3>
        ${lock}
        <button class="danger" data-action="ask-erase">Erase everything on this phone</button>
      </section>
      <section class="block">
        <h3>The count</h3>
        <div class="row"><span>Now</span><b>Day ${days}</b></div>
        <div class="row"><span>Best</span><b>${shownBest()} ${unit(shownBest())}</b></div>
        <label class="field" for="settings-name">What you call them
          <input id="settings-name" type="text" maxlength="24" autocomplete="off" autocapitalize="off">
        </label>
        <p class="note">${state.unlocked
          ? "If you slip, your best stays."
          : "If you slip, this record starts over. Unlock to keep the best."}</p>
        <button class="danger" data-action="ask-slip">I slipped</button>
      </section>
      <section class="block">
        <h3>Purchase</h3>
        ${purchase}
        <button class="text-btn" data-action="restore" style="justify-content: flex-start">Restore purchases</button>
        ${state.notice ? `<p class="status">${esc(state.notice)}</p>` : ""}
      </section>
      <section class="block">
        <h3>About</h3>
        <p class="about">Choosing Myself is a private counter for no contact. It is not medical care.</p>
        <p class="handle" style="margin-top: 10px">choosing.myself</p>
        <a class="link" href="https://www.iasp.info/suicidalthoughts/" target="_blank" rel="noopener noreferrer">If you need more than quiet, find local help</a>
      </section>
    </div>`;
}

function overlay() {
  if (state.overlay === "urge") return urgeOverlay();
  if (state.overlay === "letter") return letterOverlay();
  if (state.overlay === "paywall") return paywallOverlay();
  if (state.overlay === "share") return shareOverlay();
  return "";
}

function urgeOverlay() {
  if (state.urgeStage === "write") {
    const limit = state.unlocked
      ? "It stays on this phone. Nothing sends."
      : `It stays on this phone. Nothing sends. ${state.letters.length} of ${FREE_LIMIT} letters kept.`;
    return `
      <div class="overlay">
        <button class="close" data-action="close-urge" aria-label="Close">×</button>
        <div class="write">
          <div class="scroll">
            <p class="eyebrow">unsent</p>
            <h2 class="display small">Say it here.</h2>
            <p class="hint">${limit}</p>
          </div>
          <div class="composer">
            <div class="ghost" id="ghost">Write what you would have sent.</div>
            <textarea id="draft" aria-label="Unsent letter" maxlength="12000"></textarea>
          </div>
          <div class="dock">
            <button class="solid" id="lock-btn" data-action="lock" ${state.draft.trim() ? "" : "disabled"}>${canSave() ? "Lock it away" : "Unlock to lock this away"}</button>
            <button class="text-btn" data-action="close-urge">Let it go</button>
          </div>
        </div>
      </div>`;
  }
  return `
    <div class="overlay">
      <button class="close" data-action="close-urge" aria-label="Close">×</button>
      <div class="breathe">
        <h2>Stay with this.</h2>
        <p class="sub">One minute. Then you can write it.</p>
        <div class="ring-wrap">
          <svg viewBox="0 0 220 220" aria-hidden="true">
            <circle cx="110" cy="110" r="104" fill="none" stroke="rgba(255,255,255,0.14)" stroke-width="2"></circle>
            <circle id="ring-progress" cx="110" cy="110" r="104" fill="none" stroke="rgba(255,255,255,0.85)" stroke-width="2" stroke-linecap="round" stroke-dasharray="653.45" stroke-dashoffset="653.45" transform="rotate(-90 110 110)"></circle>
          </svg>
          <div class="core" id="breath-core"><span id="breath-phase">inhale</span></div>
        </div>
        <p class="remain" id="breath-remaining">60</p>
        <button class="skip" data-action="skip-breath">I need to write now</button>
      </div>
    </div>`;
}

function letterOverlay() {
  const letter = state.letters.find((item) => item.id === state.openLetterId);
  if (!letter) return "";
  return `
    <div class="overlay">
      <button class="close" data-action="close-overlay" aria-label="Close">×</button>
      <div class="scroll" style="padding-top: 64px">
        <p class="eyebrow">${esc(letterDate(letter.at))}</p>
        <p class="detail">${esc(letter.text)}</p>
        <button class="danger" data-action="ask-release" data-id="${esc(letter.id)}">Release</button>
      </div>
    </div>`;
}

function paywallOverlay() {
  const features = [
    "Every mood. Rain, night drive, ocean.",
    "Letters without a limit of three.",
    "A lock on the door. Face ID, or your passcode.",
    "Milestone cards for Stories.",
    "A widget for the Home Screen and the Lock Screen.",
    "If you slip, your best streak stays."
  ];
  return `
    <div class="overlay">
      <div class="scroll" style="padding-top: 28px">
        <p class="handle">choosing.myself</p>
        <h2 class="display small" style="margin-top: 18px">${state.unlocked ? "This phone is unlocked." : "The rest of the room"}</h2>
        <p class="hint">The day counter and today's line stay free. This is everything else, once.</p>
        <div style="margin-top: 18px">
          ${features.map((feature) => `<p class="feature">${feature}</p>`).join("")}
        </div>
        ${state.unlocked ? "" : `<p class="note">On iPhone this is a one-time App Store unlock. This browser cannot charge you.</p>`}
      </div>
      <div class="dock">
        ${state.unlocked
          ? `<button class="solid" data-action="close-paywall">Done</button>`
          : `<button class="solid" data-action="preview-unlock">Preview the unlocked room</button>
             <button class="text-btn" data-action="close-paywall">Not now</button>`}
      </div>
    </div>`;
}

function shareOverlay() {
  const days = state.shareDays;
  const theme = effectiveTheme();
  return `
    <div class="overlay">
      <button class="close" data-action="close-overlay" aria-label="Close">×</button>
      <div class="share-wrap">
        <div class="story" data-theme="${theme}">
          <p class="handle">choosing.myself</p>
          <p class="day">${days}</p>
          <p class="unit">${unit(days)}</p>
          <p class="of">of choosing myself</p>
          <hr>
          <p class="line">${esc(lineFor())}</p>
        </div>
        <button class="solid" data-action="native-share">Share card</button>
      </div>
    </div>`;
}

function confirmSheet() {
  if (!state.confirm) return "";
  const copy = {
    slip: {
      title: "Start today over?",
      body: state.unlocked
        ? `Today becomes day 1. Your letters stay. Your best of ${shownBest()} ${unit(shownBest())} stays.`
        : "Today becomes day 1. Your letters stay. The record of this run does not.",
      action: "do-slip",
      label: "I slipped"
    },
    erase: {
      title: "Erase everything on this phone?",
      body: "Your days and letters on this phone will be deleted. An unlock stays with your Apple ID.",
      action: "do-erase",
      label: "Erase"
    },
    leave: {
      title: "Leave this unsent?",
      body: "It won't be saved, and your count stays.",
      action: "do-leave",
      label: "Leave"
    },
    release: {
      title: "Release this letter?",
      body: "It will be deleted from this phone.",
      action: "do-release",
      label: "Release"
    }
  }[state.confirm.kind];
  if (!copy) return "";
  return `
    <div class="dialog-back">
      <div class="dialog" role="dialog" aria-modal="true">
        <h2>${copy.title}</h2>
        <p>${esc(copy.body)}</p>
        <button class="solid" data-action="${copy.action}">${copy.label}</button>
        <button class="text-btn" data-action="cancel-confirm">Cancel</button>
      </div>
    </div>`;
}

function startBreath() {
  cancelAnimationFrame(breathFrame);
  if (state.overlay !== "urge" || state.urgeStage !== "breathe") return;
  const tick = () => {
    if (state.overlay !== "urge" || state.urgeStage !== "breathe") return;
    const elapsed = Math.min(60, Math.max(0, (Date.now() - state.breathStart) / 1000));
    paintBreath(elapsed);
    if (elapsed >= 60) {
      state.urgeStage = "write";
      focusDraft = true;
      render();
      return;
    }
    breathFrame = requestAnimationFrame(tick);
  };
  breathFrame = requestAnimationFrame(tick);
}

function paintBreath(elapsed) {
  const cycle = elapsed % 12;
  const phase = cycle < 4 ? "inhale" : cycle < 8 ? "hold" : "exhale";
  let scale = 1;
  if (cycle < 4) scale = 0.72 + (cycle / 4) * 0.28;
  else if (cycle >= 8) scale = 1 - ((cycle - 8) / 4) * 0.28;
  const phaseNode = document.getElementById("breath-phase");
  const remain = document.getElementById("breath-remaining");
  const ring = document.getElementById("ring-progress");
  const core = document.getElementById("breath-core");
  if (phaseNode) phaseNode.textContent = phase;
  if (remain) remain.textContent = String(Math.max(0, Math.ceil(60 - elapsed)));
  if (ring) ring.setAttribute("stroke-dashoffset", String(653.45 * (1 - elapsed / 60)));
  if (core && !window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    core.style.transform = `scale(${scale})`;
  }
}

function openUrge() {
  state.overlay = "urge";
  state.urgeStage = "breathe";
  state.breathStart = Date.now();
  state.draft = "";
  render();
}

function finishBreath() {
  state.urgeStage = "write";
  focusDraft = true;
  render();
}

function closeUrge() {
  if (state.urgeStage === "write" && state.draft.trim()) {
    state.confirm = { kind: "leave" };
    render();
    return;
  }
  state.overlay = null;
  state.draft = "";
  render();
}

function lockLetter() {
  const text = state.draft.trim();
  if (!text) return;
  if (!canSave()) {
    state.paywallIntent = "save";
    state.overlay = "paywall";
    render();
    return;
  }
  saveLetter(text);
}

function saveLetter(text) {
  state.letters.push({ id: `${Date.now()}-${Math.random().toString(16).slice(2)}`, text, at: new Date().toISOString() });
  state.draft = "";
  state.overlay = null;
  state.paywallIntent = null;
  state.tab = "home";
  render();
}

function slip() {
  const current = dayCount(state.startDate);
  const recorded = shownBest();
  state.startDate = todayISO();
  const restarted = dayCount(state.startDate);
  state.bestStreak = state.unlocked
    ? Math.max(recorded, current, restarted)
    : Math.max(1, restarted);
  state.confirm = null;
  render();
}

function erase() {
  const unlocked = state.unlocked;
  state = fresh();
  state.unlocked = unlocked;
  render();
}

app.addEventListener("click", (event) => {
  if (event.target.classList.contains("dialog-back")) {
    state.confirm = null;
    render();
    return;
  }
  const button = event.target.closest("[data-action]");
  if (!button || button.disabled) return;
  const action = button.dataset.action;
  if (action === "advance") {
    if (state.page < 2) {
      state.page += 1;
    } else {
      state.startDate = clampStart(state.startDate);
      state.nickname = cleanNickname(state.nickname);
      state.ownedTheme = state.theme;
      state.bestStreak = dayCount(state.startDate);
      state.onboarded = true;
      state.tab = "home";
      state.overlay = null;
    }
    render();
    return;
  }
  if (action === "pick-theme") {
    state.theme = button.dataset.theme;
    render();
    return;
  }
  if (action === "tab") {
    state.tab = button.dataset.tab;
    state.notice = "";
    render();
    return;
  }
  if (action === "open-urge") return openUrge();
  if (action === "skip-breath") return finishBreath();
  if (action === "close-urge") return closeUrge();
  if (action === "lock") return lockLetter();
  if (action === "open-letter") {
    state.openLetterId = button.dataset.id;
    state.overlay = "letter";
    render();
    return;
  }
  if (action === "close-overlay") {
    state.overlay = null;
    render();
    return;
  }
  if (action === "open-paywall") {
    state.paywallIntent = null;
    state.overlay = "paywall";
    render();
    return;
  }
  if (action === "close-paywall") {
    const intent = state.paywallIntent;
    state.paywallIntent = null;
    state.overlay = intent === "save" ? "urge" : null;
    if (state.overlay === "urge") state.urgeStage = "write";
    render();
    return;
  }
  if (action === "preview-unlock") {
    state.unlocked = true;
    state.notice = "";
    if (state.paywallIntent === "save" && state.draft.trim()) {
      saveLetter(state.draft.trim());
      return;
    }
    state.paywallIntent = null;
    state.overlay = null;
    render();
    return;
  }
  if (action === "settings-theme") {
    const picked = button.dataset.theme;
    if (!state.unlocked && picked !== state.ownedTheme) {
      state.paywallIntent = null;
      state.overlay = "paywall";
    } else {
      state.theme = picked;
    }
    render();
    return;
  }
  if (action === "toggle-reminder") {
    state.reminderOn = !state.reminderOn;
    render();
    return;
  }
  if (action === "share-or-unlock") {
    const days = Number(button.dataset.days);
    if (!state.unlocked) {
      state.paywallIntent = null;
      state.overlay = "paywall";
    } else {
      state.shareDays = days;
      state.overlay = "share";
    }
    render();
    return;
  }
  if (action === "native-share") {
    const days = state.shareDays;
    const text = `${days} ${unit(days)} of choosing myself\n${lineFor()}\nchoosing.myself`;
    if (navigator.share) {
      navigator.share({ title: `${days} ${unit(days)} of choosing myself`, text }).catch(() => {});
    } else {
      state.notice = text;
      state.overlay = null;
      state.tab = "settings";
    }
    render();
    return;
  }
  if (action === "restore") {
    state.notice = state.unlocked
      ? "This browser is already previewing the unlocked room. On iPhone, restore checks the Apple ID."
      : "On iPhone, restore checks your Apple ID. This browser has no purchase to restore.";
    render();
    return;
  }
  if (action === "ask-slip") {
    state.confirm = { kind: "slip" };
    render();
    return;
  }
  if (action === "ask-erase") {
    state.confirm = { kind: "erase" };
    render();
    return;
  }
  if (action === "ask-release") {
    state.confirm = { kind: "release", id: button.dataset.id };
    render();
    return;
  }
  if (action === "do-slip") return slip();
  if (action === "do-erase") return erase();
  if (action === "do-leave") {
    state.confirm = null;
    state.overlay = null;
    state.draft = "";
    render();
    return;
  }
  if (action === "do-release") {
    state.letters = state.letters.filter((item) => item.id !== state.confirm.id);
    state.confirm = null;
    state.overlay = null;
    render();
    return;
  }
  if (action === "cancel-confirm") {
    state.confirm = null;
    render();
  }
});

app.addEventListener("input", (event) => {
  const target = event.target;
  if (target.id === "start-date") {
    state.startDate = clampStart(target.value);
    target.value = state.startDate;
    const preview = document.getElementById("day-preview");
    if (preview) preview.textContent = `That is day ${dayCount(state.startDate)} today.`;
    save();
    return;
  }
  if (target.id === "nickname" || target.id === "settings-name") {
    const cleaned = cleanNickname(target.value);
    if (cleaned !== target.value) target.value = cleaned;
    state.nickname = cleaned;
    save();
    return;
  }
  if (target.id === "draft") {
    state.draft = target.value.slice(0, 12000);
    if (state.draft !== target.value) target.value = state.draft;
    const ghost = document.getElementById("ghost");
    if (ghost) ghost.style.visibility = state.draft ? "hidden" : "visible";
    const lock = document.getElementById("lock-btn");
    if (lock) lock.disabled = !state.draft.trim();
    save();
    return;
  }
  if (target.id === "reminder-time") {
    state.reminderTime = target.value || "21:00";
    save();
  }
});

function selfTest() {
  const results = [];
  const check = (name, pass) => results.push(`${pass ? "ok" : "FAIL"} ${name}`);
  const fixed = new Date(2026, 10, 22);
  check("day 1 is the start date", dayCount(todayISO(fixed), fixed) === 1);
  const weekAgo = new Date(2026, 10, 16);
  check("six midnights later is day 7", dayCount(todayISO(weekAgo), fixed) === 7);
  check("future start clamps later via dayCount of today", dayCount("2099-01-01", fixed) === 1);
  check("line index in range", lineIndex(fixed, lines) === 36);
  check("today's sample line", lineFor(fixed) === "you can want them and choose you in the same hour.");
  check("empty name", personReference("  ") === "them");
  check("period name", urgeTitle("Dr.") === "I want to text Dr.");
  check("plain name", urgeTitle("him") === "I want to text him.");
  const previous = state.unlocked;
  state.unlocked = false;
  check("free cap", canSave(2) && !canSave(3));
  state.unlocked = true;
  check("unlocked cap", canSave(9));
  state.unlocked = previous;
  const root = document.createElement("pre");
  root.id = "selftest";
  root.textContent = results.join("\n");
  document.body.prepend(root);
}

async function boot() {
  try {
    const response = await fetch("lines.json");
    if (response.ok) {
      const data = await response.json();
      const next = (data.lines || []).map((line) => String(line).trim()).filter(Boolean);
      if (next.length) lines = next;
    }
  } catch {
    lines = FALLBACK_LINES.slice();
  }
  if (state.overlay === "urge" && state.urgeStage === "breathe" && state.breathStart) {
    if ((Date.now() - state.breathStart) / 1000 >= 60) state.urgeStage = "write";
  }
  render();
  if (new URLSearchParams(location.search).has("selftest")) selfTest();
}

boot();
