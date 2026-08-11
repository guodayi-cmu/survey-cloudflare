/**
 * Lightweight i18n engine — zero dependencies
 */
class I18nEngine {
  constructor() {
    this.dict = {};
    this.lang = 'zh-CN';
    this.loaded = false;
    this.cache = new Map();
  }

  async load(lang) {
    if (this.cache.has(lang)) {
      this.dict = this.cache.get(lang);
      this.lang = lang;
      this.loaded = true;
      return;
    }
    try {
      const res = await fetch(`./locales/${lang}.json`);
      if (!res.ok) throw new Error('Locale not found: ' + lang);
      const data = await res.json();
      this.cache.set(lang, data);
      this.dict = data;
      this.lang = lang;
      this.loaded = true;
    } catch (e) {
      console.error('[i18n] Failed to load locale:', lang, e);
      if (lang !== 'zh-CN') await this.load('zh-CN');
    }
  }

  detect() {
    const urlParams = new URLSearchParams(location.search);
    const urlLang = urlParams.get('lang');
    if (urlLang && this.isSupported(urlLang)) return urlLang;
    const saved = localStorage.getItem('survey-lang');
    if (saved && this.isSupported(saved)) return saved;
    const nav = navigator.language || navigator.userLanguage || 'zh-CN';
    const normalized = this.normalizeLang(nav);
    if (this.isSupported(normalized)) return normalized;
    return 'zh-CN';
  }

  normalizeLang(raw) {
    const map = {
      'zh': 'zh-CN', 'zh-cn': 'zh-CN', 'zh-tw': 'zh-TW',
      'zh-hk': 'zh-HK', 'zh-hant': 'zh-TW',
      'en': 'en', 'en-us': 'en', 'en-gb': 'en',
      'ja': 'ja', 'jp': 'ja', 'ko': 'ko', 'kr': 'ko'
    };
    return map[raw.toLowerCase()] || raw;
  }

  isSupported(lang) {
    return ['zh-CN', 'zh-TW', 'zh-HK', 'en', 'ja', 'ko'].includes(lang);
  }

  async setLang(lang) {
    if (!this.isSupported(lang)) return;
    await this.load(lang);
    localStorage.setItem('survey-lang', lang);
    document.documentElement.lang = lang;
    this.applyDOM();
    this.renderAllDynamic();
    window.dispatchEvent(new CustomEvent('i18n:changed', { detail: { lang } }));
  }

  t(key, vars = {}) {
    if (!this.loaded) return key;
    const parts = key.split('.');
    let val = this.dict;
    for (const p of parts) {
      if (val && typeof val === 'object' && p in val) val = val[p];
      else return key;
    }
    if (typeof val !== 'string') return key;
    return val.replace(/\{(\w+)\}/g, (_, k) => vars[k] !== undefined ? vars[k] : `{${k}}`);
  }

  raw(key) {
    const parts = key.split('.');
    let val = this.dict;
    for (const p of parts) {
      if (val && typeof val === 'object' && p in val) val = val[p];
      else return undefined;
    }
    return val;
  }

  applyDOM(root = document) {
    // Handle elements with data-i18n-placeholder (placeholder only, no text content)
    root.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
      const key = el.getAttribute('data-i18n-placeholder');
      const text = this.t(key);
      el.setAttribute('placeholder', text);
      el.removeAttribute('data-i18n-placeholder');
    });
    root.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      const vars = {};
      for (const attr of el.attributes) {
        if (attr.name.startsWith('data-i18n-')) {
          vars[attr.name.slice(10)] = attr.value;
        }
      }
      const text = this.t(key, vars);
      if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
        if (el.getAttribute('placeholder') !== null || el.hasAttribute('data-i18n-placeholder')) {
          el.setAttribute('placeholder', text);
          el.removeAttribute('data-i18n-placeholder');
        } else {
          el.value = text;
        }
      } else {
        el.textContent = text;
      }
    });
  }

  // Render <option> elements for a select field
  renderOptions(fieldName, selectEl, includeEmpty = true) {
    if (!this.loaded || !selectEl) return;
    const avail = this.raw(`available_options.${fieldName}`);
    const allOpts = this.raw('options');
    const emptyLabel = this.t('ui.common.select_placeholder');
    let html = '';
    if (includeEmpty) html += `<option value="">${emptyLabel}</option>`;
    const keys = avail || Object.keys(allOpts || {});
    for (const k of keys) {
      if (allOpts && k in allOpts) html += `<option value="${k}">${allOpts[k]}</option>`;
    }
    selectEl.innerHTML = html;
  }

  // Render checkbox/radio group
  renderCheckboxGroup(fieldName, containerEl, inputType = 'checkbox', inputName = fieldName) {
    if (!this.loaded || !containerEl) return;
    const avail = this.raw(`available_options.${fieldName}`);
    const allOpts = this.raw('options');
    const keys = avail || Object.keys(allOpts || {});
    let html = '';
    for (const k of keys) {
      if (allOpts && k in allOpts) {
        html += `<label><input type="${inputType}" name="${inputName}" value="${k}" /> ${allOpts[k]}</label>`;
      }
    }
    containerEl.innerHTML = html;
  }

  getDefault(fieldName) {
    const defs = this.raw('defaults');
    return defs ? defs[fieldName] : undefined;
  }

  renderAllDynamic() {
    document.querySelectorAll('[data-i18n-options]').forEach(el => {
      const field = el.getAttribute('data-i18n-options');
      const includeEmpty = el.getAttribute('data-i18n-empty') !== 'false';
      if (el.tagName === 'SELECT') {
        this.renderOptions(field, el, includeEmpty);
      } else {
        const type = el.getAttribute('data-i18n-input-type') || 'checkbox';
        const name = el.getAttribute('data-i18n-input-name') || field;
        this.renderCheckboxGroup(field, el, type, name);
      }
    });
  }
}

const I18n = new I18nEngine();
