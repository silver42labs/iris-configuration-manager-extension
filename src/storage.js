/**
 * Storage layer — abstracts browser.storage.local for snapshots and reports.
 *
 * Uses the compatibility layer so the same code works on Chrome and Firefox.
 */

import { browser } from './platform/browser-polyfill.js';

const SNAPSHOT_KEY = 'savedSnapshot';
const REPORT_KEY = 'comparisonReport';
const CREDENTIALS_KEY = 'serverCredentials';

/**
 * Get the session-scoped storage area.
 * Falls back to an in-memory Map when browser.storage.session is
 * unavailable (older Firefox builds).
 */
const memoryStore = new Map();
function getSessionStorage() {
    if (browser.storage.session) {
        return browser.storage.session;
    }
    // In-memory fallback that mimics the storage API surface we need.
    return {
        async get(key) {
            return { [key]: memoryStore.get(key) ?? null };
        },
        async set(items) {
            for (const [k, v] of Object.entries(items)) {
                memoryStore.set(k, v);
            }
        },
        async remove(keys) {
            for (const k of [].concat(keys)) {
                memoryStore.delete(k);
            }
        }
    };
}

/**
 * Persist a server snapshot.
 * @param {{ snapshot: object, serverUrl: string }} data
 */
export async function saveSnapshot(data) {
    return browser.storage.local.set({
        [SNAPSHOT_KEY]: {
            snapshot: data.snapshot,
            serverUrl: data.serverUrl,
            timestamp: new Date().toISOString()
        }
    });
}

/**
 * Load the previously saved snapshot.
 * @returns {Promise<{ snapshot: object, serverUrl: string, timestamp: string } | null>}
 */
export async function loadSnapshot() {
    const result = await browser.storage.local.get(SNAPSHOT_KEY);
    return result[SNAPSHOT_KEY] || null;
}

/**
 * Persist a comparison report for the report page to read.
 * @param {object} report
 */
export async function saveReport(report) {
    return browser.storage.local.set({ [REPORT_KEY]: report });
}

/**
 * Load the most recent comparison report.
 * @returns {Promise<object | null>}
 */
export async function loadReport() {
    const result = await browser.storage.local.get(REPORT_KEY);
    return result[REPORT_KEY] || null;
}

/**
 * Remove all stored data (snapshot and report).
 * @returns {Promise<void>}
 */
export async function clearAllData() {
    return browser.storage.local.remove([SNAPSHOT_KEY, REPORT_KEY]);
}

/* ================================================================== */
/*  Credentials (session-scoped — cleared when the browser closes)     */
/* ================================================================== */

/**
 * Persist Basic Auth credentials for a server origin.
 * Stored in session storage so they never survive a browser restart.
 *
 * @param {string} baseUrl - Server origin.
 * @param {{ username: string, password: string }} auth
 */
export async function saveCredentials(baseUrl, auth) {
    const store = getSessionStorage();
    const result = await store.get(CREDENTIALS_KEY);
    const map = result[CREDENTIALS_KEY] || {};
    map[baseUrl] = { username: auth.username, password: auth.password };
    return store.set({ [CREDENTIALS_KEY]: map });
}

/**
 * Load stored credentials for a server origin, if any.
 *
 * @param {string} baseUrl
 * @returns {Promise<{ username: string, password: string } | null>}
 */
export async function loadCredentials(baseUrl) {
    const store = getSessionStorage();
    const result = await store.get(CREDENTIALS_KEY);
    const map = result[CREDENTIALS_KEY] || {};
    return map[baseUrl] || null;
}

/**
 * Remove stored credentials for a server origin.
 * @param {string} baseUrl
 */
export async function clearCredentials(baseUrl) {
    const store = getSessionStorage();
    const result = await store.get(CREDENTIALS_KEY);
    const map = result[CREDENTIALS_KEY] || {};
    delete map[baseUrl];
    return store.set({ [CREDENTIALS_KEY]: map });
}
