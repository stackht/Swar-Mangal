// Minimal Google Sheets v4 client for the mirror, authenticated as a service
// account. The key lives only on the server (never in the repo or the APK);
// the mirror workbook must be shared with the service account's email.
import { GoogleAuth } from "google-auth-library";

const SCOPE = "https://www.googleapis.com/auth/spreadsheets";

/** Read the service-account credentials from the environment. */
export function credentialsFromEnv(env = process.env) {
  const raw = env.GOOGLE_SERVICE_ACCOUNT_JSON;
  if (raw) {
    const text = raw.trim().startsWith("{") ? raw : Buffer.from(raw, "base64").toString("utf8");
    return { credentials: JSON.parse(text) };
  }
  if (env.GOOGLE_APPLICATION_CREDENTIALS) {
    return { keyFile: env.GOOGLE_APPLICATION_CREDENTIALS };
  }
  throw new Error("Set GOOGLE_SERVICE_ACCOUNT_JSON (JSON or base64) or GOOGLE_APPLICATION_CREDENTIALS (key file path)");
}

/** 'my tab' -> 'my tab' quoted for A1 notation. */
const sheetRef = (title) => `'${String(title).replace(/'/g, "''")}'`;

export function createSheetsClient({ spreadsheetId, auth }) {
  if (!spreadsheetId) throw new Error("SHEETS_MIRROR_SPREADSHEET_ID is not set");
  const googleAuth = new GoogleAuth({ ...auth, scopes: [SCOPE] });
  const base = `https://sheets.googleapis.com/v4/spreadsheets/${encodeURIComponent(spreadsheetId)}`;
  let titles = null;

  async function request(method, path, data) {
    const client = await googleAuth.getClient();
    try {
      const res = await client.request({ url: `${base}${path}`, method, data });
      return res.data;
    } catch (err) {
      const status = err?.response?.status;
      const detail = err?.response?.data?.error?.message ?? err?.message;
      throw new Error(`Sheets ${method} ${path.split("?")[0]} failed${status ? ` (${status})` : ""}: ${detail}`);
    }
  }

  async function loadTitles() {
    const data = await request("GET", "?fields=sheets.properties.title");
    titles = new Set((data.sheets ?? []).map((s) => s.properties.title));
    return titles;
  }

  return {
    async ensureTab(title) {
      if (!titles) await loadTitles();
      if (titles.has(title)) return;
      await request("POST", ":batchUpdate", { requests: [{ addSheet: { properties: { title } } }] });
      titles.add(title);
    },

    async getHeader(title) {
      const data = await request("GET", `/values/${encodeURIComponent(`${sheetRef(title)}!1:1`)}`);
      return data.values?.[0] ?? [];
    },

    async setHeader(title, header) {
      await request(
        "PUT",
        `/values/${encodeURIComponent(`${sheetRef(title)}!A1`)}?valueInputOption=RAW`,
        { values: [header] },
      );
    },

    /** Append rows after the last data row; returns the first row written. */
    async appendRows(title, rows) {
      const data = await request(
        "POST",
        `/values/${encodeURIComponent(`${sheetRef(title)}!A1`)}:append?valueInputOption=RAW&insertDataOption=INSERT_ROWS`,
        { values: rows },
      );
      const range = data.updates?.updatedRange ?? "";
      const m = /!([A-Z]+)(\d+)/.exec(range);
      if (!m) throw new Error(`Sheets append returned no range for ${title}`);
      return { firstRow: Number(m[2]) };
    },

    /** Many ranges in one request: [{ startCell: "A5", values: [[...]] }]. */
    async batchUpdate(title, updates) {
      await request("POST", "/values:batchUpdate", {
        valueInputOption: "RAW",
        data: updates.map((u) => ({ range: `${sheetRef(title)}!${u.startCell}`, values: u.values })),
      });
    },

    async readColumnA(title) {
      const data = await request("GET", `/values/${encodeURIComponent(`${sheetRef(title)}!A2:A`)}`);
      return (data.values ?? []).map((r) => r[0] ?? "");
    },
  };
}
