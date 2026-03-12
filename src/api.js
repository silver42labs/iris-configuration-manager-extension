/**
 * API layer — fetches migration export data from a server and provides
 * Atelier API helpers for backend bootstrapping.
 *
 * All requests include credentials: "include" and optionally a Basic Auth
 * header when an auth object { username, password } is supplied.
 */

import { browser } from './platform/browser-polyfill.js';

const EXPORT_PATH = '/api/v1/configuration-manager/export';
const ATELIER_BASE = '/api/atelier/v1/%25SYS';

const CLASS_NAME = 'Migration.Framework';
const CLASS_FILE = 'Migration.Framework.cls';

/**
 * Build request headers, optionally adding a Basic Auth Authorization header.
 * @param {{ username: string, password: string }} [auth]
 * @param {Record<string, string>} [extra]
 * @returns {Record<string, string>}
 */
function buildHeaders(auth, extra = {}) {
    const headers = { ...extra };
    if (auth) {
        headers['Authorization'] =
            `Basic ${btoa(`${auth.username}:${auth.password}`)}`;
    }
    return headers;
}

/**
 * Load the .cls file bundled with the extension and return its content
 * as an array of lines — the format expected by the Atelier PUT endpoint.
 *
 * @returns {Promise<string[]>} Lines of the class source.
 */
async function loadClassSource() {
    const url = browser.runtime.getURL(CLASS_FILE);
    const response = await fetch(url);

    if (!response.ok) {
        throw new Error(
            `Could not load class file "${CLASS_FILE}" from extension bundle.`
        );
    }

    const text = await response.text();
    return text.split('\n');
}

/* ================================================================== */
/*  Export endpoint                                                     */
/* ================================================================== */

/**
 * Fetch the configuration manager export JSON from a server.
 * @param {string} baseUrl - Origin URL (protocol + hostname + port).
 * @param {{ username: string, password: string }} [auth] - Optional Basic Auth credentials.
 * @returns {Promise<object>} Parsed JSON export data.
 */
export async function fetchExport(baseUrl, auth) {
    const url = `${baseUrl}${EXPORT_PATH}`;

    const response = await fetch(url, {
        credentials: 'include',
        headers: buildHeaders(auth)
    });

    if (!response.ok) {
        const err = new Error(`Server responded with ${response.status} ${response.statusText}`);
        if (response.status === 401) err.authFailed = true;
        throw err;
    }

    const contentType = response.headers.get('content-type') || '';
    if (!contentType.includes('application/json')) {
        throw new Error('Response is not JSON. Ensure the endpoint returns application/json.');
    }

    return response.json();
}

/**
 * Non-throwing probe: attempt to reach the export endpoint.
 * Returns { ok, status } so the caller can decide what to do.
 *
 * @param {string} baseUrl
 * @param {{ username: string, password: string }} [auth] - Optional Basic Auth credentials.
 * @returns {Promise<{ ok: boolean, status: number }>}
 */
export async function tryFetchExport(baseUrl, auth) {
    try {
        const response = await fetch(`${baseUrl}${EXPORT_PATH}`, {
            credentials: 'include',
            headers: buildHeaders(auth)
        });
        return { ok: response.ok, status: response.status };
    } catch {
        // Network error — treat as unavailable
        return { ok: false, status: 0 };
    }
}

/* ================================================================== */
/*  Atelier API helpers (used by bootstrap.js)                         */
/* ================================================================== */

/**
 * Fetch the existing document metadata to retrieve its timestamp.
 * The timestamp is required for the If-None-Match header when
 * overwriting an existing class (avoids 409 Conflict).
 *
 * @param {string} baseUrl
 * @param {{ username: string, password: string }} [auth]
 * @returns {Promise<string|null>} Document timestamp, or null if not found.
 */
async function getDocTimestamp(baseUrl, auth) {
    const url = `${baseUrl}${ATELIER_BASE}/doc/${CLASS_NAME}.cls`;

    const response = await fetch(url, {
        credentials: 'include',
        headers: buildHeaders(auth)
    });

    if (response.status === 404) {
        return null; // document does not exist yet
    }

    if (!response.ok && response.status !== 409) {
        return null;
    }

    try {
        const data = await response.json();
        return data?.result?.ts || null;
    } catch {
        return null;
    }
}

/**
 * Upload the backend class source to the server via Atelier PUT.
 * If the class already exists, its timestamp is fetched first and
 * sent as an If-None-Match header so the server accepts the overwrite.
 *
 * @param {string} baseUrl
 * @param {{ username: string, password: string }} [auth]
 */
export async function uploadClass(baseUrl, auth) {
    const url = `${baseUrl}${ATELIER_BASE}/doc/${CLASS_NAME}.cls`;
    const content = await loadClassSource();

    const body = {
        enc: false,
        content
    };

    const extra = { 'Content-Type': 'application/json' };

    // If the document already exists, include its timestamp so the
    // server allows overwriting instead of returning 409 Conflict.
    const timestamp = await getDocTimestamp(baseUrl, auth);
    if (timestamp) {
        extra['If-None-Match'] = timestamp;
    }

    const response = await fetch(url, {
        method: 'PUT',
        credentials: 'include',
        headers: buildHeaders(auth, extra),
        body: JSON.stringify(body)
    });

    if (!response.ok) {
        throw new Error(
            `Failed to upload class "${CLASS_NAME}" (HTTP ${response.status}).`
        );
    }
}

/**
 * Compile the previously uploaded class via Atelier POST.
 * @param {string} baseUrl
 * @param {{ username: string, password: string }} [auth]
 */
export async function compileClass(baseUrl, auth) {
    const url = `${baseUrl}${ATELIER_BASE}/action/compile?source=0&flags=cukb`;

    const body = [`${CLASS_NAME}.cls`];

    const response = await fetch(url, {
        method: 'POST',
        credentials: 'include',
        headers: buildHeaders(auth, { 'Content-Type': 'application/json' }),
        body: JSON.stringify(body)
    });

    if (!response.ok) {
        throw new Error(
            `Failed to compile class "${CLASS_NAME}" (HTTP ${response.status}).`
        );
    }

    const result = await response.json();

    // Atelier returns a status array — check for compile errors
    const hasErrors = result?.result?.content?.some(
        item => item.severity > 0
    );

    if (hasErrors) {
        throw new Error(
            `Compilation of "${CLASS_NAME}" produced errors. Check server logs.`
        );
    }
}

/**
 * Execute the framework setup stored procedure via Atelier Query.
 * @param {string} baseUrl
 * @param {{ username: string, password: string }} [auth]
 */
export async function executeSetupProcedure(baseUrl, auth) {
    const url = `${baseUrl}${ATELIER_BASE}/action/query`;

    const body = {
        query: 'CALL Migration.Framework_Setup()',
        parameters: []
    };

    const response = await fetch(url, {
        method: 'POST',
        credentials: 'include',
        headers: buildHeaders(auth, { 'Content-Type': 'application/json' }),
        body: JSON.stringify(body)
    });

    if (!response.ok) {
        throw new Error(
            `Failed to execute setup procedure (HTTP ${response.status}).`
        );
    }
}
