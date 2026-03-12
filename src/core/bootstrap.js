/**
 * Bootstrap module — ensures the migration export API is available on the
 * target server. If the endpoint does not exist, it installs the backend
 * framework class via the Atelier API, then retries.
 *
 * Entry point: ensureExportApiAvailable(baseUrl, onStatus?)
 *
 * This module does NOT contain IRIS business logic or class source code
 * beyond a placeholder constant. It orchestrates the installation steps
 * through the API layer helpers defined in api.js.
 */

import {
    tryFetchExport,
    uploadClass,
    compileClass,
    executeSetupProcedure
} from '../api.js';

/**
 * Ensure the export endpoint is reachable on the given server.
 * If the endpoint returns 404 / non-ok, attempt to install the backend
 * framework, then retry once.
 *
 * @param {string} baseUrl - Server origin (protocol + host + port).
 * @param {(msg: string) => void} [onStatus] - Optional progress callback.
 * @param {() => Promise<boolean>} [onRequestConsent] - Optional consent callback.
 *        Must return true to proceed with installation, false to cancel.
 * @param {{ username: string, password: string }} [auth] - Optional Basic Auth credentials.
 * @returns {Promise<void>} Resolves when endpoint is confirmed available.
 * @throws {Error} If installation or retry fails.
 */
export async function ensureExportApiAvailable(baseUrl, onStatus, onRequestConsent, auth) {
    const status = onStatus || (() => { });
    const requestConsent = onRequestConsent || (() => Promise.resolve(true));

    // --- Probe the export endpoint ---
    status('Checking export API availability...');
    const probeResult = await tryFetchExport(baseUrl, auth);

    if (probeResult.ok) {
        return; // Endpoint exists — nothing to install.
    }

    // --- Endpoint missing — ask for consent before installing ---
    const userConsented = await requestConsent();
    if (!userConsented) {
        throw new Error('Installation cancelled. The export API is required to proceed.');
    }

    status('Installing backend framework...');
    await installFramework(baseUrl, status, auth);

    // --- Retry probe after installation ---
    status('Verifying export API after installation...');
    const retryResult = await tryFetchExport(baseUrl, auth);

    if (!retryResult.ok) {
        const webAppUrl =
            `${baseUrl}/csp/sys/sec/%25CSP.UI.Portal.Applications.Web.zen` +
            `?PID=%2Fapi%2Fv1%2Fmigration%2Fframework`;

        const err = new Error(
            `Export API still unavailable after installation (HTTP ${retryResult.status}). ` +
            'Open the web application config page, click Save, then try again.'
        );
        err.webAppUrl = webAppUrl;
        throw err;
    }
}

/* ------------------------------------------------------------------ */
/*  Installation orchestration                                         */
/* ------------------------------------------------------------------ */

/**
 * Install the configuration manager on the target server.
 * Steps:
 *   1. Upload the backend class source via Atelier
 *   2. Compile the uploaded class
 *   3. Execute the setup stored procedure
 *
 * @param {string} baseUrl
 * @param {(msg: string) => void} status
 * @param {{ username: string, password: string }} [auth]
 */
async function installFramework(baseUrl, status, auth) {
    status('Step 1/3 — Uploading backend class...');
    await uploadClass(baseUrl, auth);

    status('Step 2/3 — Compiling backend class...');
    await compileClass(baseUrl, auth);

    status('Step 3/3 — Executing setup procedure...');
    await executeSetupProcedure(baseUrl, auth);

    status('Backend framework installation complete.');
}
