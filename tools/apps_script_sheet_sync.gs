/**
 * Automatically syncs the `fulfillment` column ("PayPal" / "Self-ordered" / "")
 * in `Blatt 1` from the live Firebase Realtime Database (READ-ONLY GET).
 *
 * - Leaves all other columns (including `delivery status` in Col I and
 *   `money received` in Col K) 100% untouched.
 * - Locates `url`, `Comment`, and `fulfillment` dynamically by header name,
 *   so inserting columns or sorting rows will never overwrite the wrong cells.
 *
 * Setup (takes ~30 seconds, runs 24/7 on Google's servers even while OOO):
 *   1. Open the Google Sheet -> Extensions -> Apps Script.
 *   2. Paste this file into `Code.gs` and click Save (Ctrl+S).
 *   3. In the toolbar dropdown next to "Run", select `installTrigger` and click Run
 *      (approve the one-time permission prompt).
 */

const RTDB_URL =
    'https://toy-appeal-muc-default-rtdb.europe-west1.firebasedatabase.app/.json';
const SHEET_NAME = 'Blatt 1';

function onOpen() {
  SpreadsheetApp.getUi()
      .createMenu('🎄 Toy Appeal')
      .addItem('Sync fulfillment status now', 'syncToyAppealFulfillment')
      .addToUi();
}

/**
 * Run this function ONCE in the Apps Script editor to install a background
 * trigger that syncs every 15 minutes (even when your laptop/Cloudtop is off
 * or you are OOO).
 */
function installTrigger() {
  // Remove any existing triggers for syncToyAppealFulfillment to avoid duplicates.
  for (const trigger of ScriptApp.getProjectTriggers()) {
    if (trigger.getHandlerFunction() === 'syncToyAppealFulfillment') {
      ScriptApp.deleteTrigger(trigger);
    }
  }
  ScriptApp.newTrigger('syncToyAppealFulfillment')
      .timeBased()
      .everyMinutes(15)
      .create();
  syncToyAppealFulfillment();
}

function syncToyAppealFulfillment() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) {
    throw new Error(`Sheet "${SHEET_NAME}" not found.`);
  }

  const lastRow = sheet.getLastRow();
  const lastCol = sheet.getLastColumn();
  if (lastRow < 2) return;

  const allValues = sheet.getRange(1, 1, lastRow, lastCol).getValues();
  const headers = allValues[0].map(h => String(h).trim());

  const urlCol = headers.indexOf('url');
  const commentCol = headers.indexOf('Comment');
  const fulfillmentCol = headers.indexOf('fulfillment');

  if (urlCol === -1 || fulfillmentCol === -1) {
    throw new Error(
        'Could not find required headers "url" and "fulfillment" in Row 1.');
  }

  // Strictly READ-ONLY GET against Firebase Realtime Database.
  const response = UrlFetchApp.fetch(RTDB_URL, {method: 'get'});
  const rtdb = JSON.parse(response.getContentText());

  // Build row entries (rows 2..lastRow with non-empty URL) and sort by (url, Comment)
  // in exact UTF-16 code-unit order to match tools/generate_hashes.dart.
  const entries = [];
  for (let r = 1; r < allValues.length; r++) {
    const url = String(allValues[r][urlCol] || '').trim();
    if (!url) continue;
    const comment =
        commentCol >= 0 ? String(allValues[r][commentCol] || '').trim() : '';
    entries.push({rowOffset: r - 1, url, comment});
  }

  entries.sort((a, b) => {
    if (a.url < b.url) return -1;
    if (a.url > b.url) return 1;
    if (a.comment < b.comment) return -1;
    if (a.comment > b.comment) return 1;
    return a.rowOffset - b.rowOffset;
  });

  const numDataRows = allValues.length - 1;
  const outputCol = Array.from({length: numDataRows}, (_, idx) => [
    String(allValues[idx + 1][fulfillmentCol] || ''),
  ]);

  for (let i = 0; i < entries.length; i++) {
    const entry = entries[i];
    const hash = computeSha1Hex_(`${entry.url}${i}`);
    const item = rtdb[hash];
    if (!item) continue;

    let status = '';
    if (item.isTaken) {
      const isPayPal =
          item.paypal === true ||
          String(item.paypal).toLowerCase() === 'true';
      status = isPayPal ? 'PayPal' : 'Self-ordered';
    }
    outputCol[entry.rowOffset] = [status];
  }

  // Write ONLY the `fulfillment` column (1-indexed: fulfillmentCol + 1).
  // Columns I (`delivery status`) and K (`money received`) are never touched.
  sheet.getRange(2, fulfillmentCol + 1, numDataRows, 1).setValues(outputCol);
}

function computeSha1Hex_(input) {
  const digest = Utilities.computeDigest(
      Utilities.DigestAlgorithm.SHA_1, input, Utilities.Charset.UTF_8);
  return digest
      .map(byte => ((byte < 0 ? byte + 256 : byte) & 0xff)
          .toString(16)
          .padStart(2, '0'))
      .join('');
}
