// Firebase Cloud Messaging transport. Only ever imported from RPC handlers
// (server-side route code), never from client components. Never throws into
// a caller: a push failure must never fail (or even slow down noticeably)
// the write it reports on. Disabled cleanly when no service account is
// configured, so the rest of the app works before Firebase is set up.
type SendResult = { attempted: number; success: number; failure: number; disabled: boolean };

let appPromise: Promise<import("firebase-admin/app").App | null> | null = null;

function loadCredentialsJson(): Record<string, unknown> | null {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw || !raw.trim()) return null;
  try {
    // Accept either the raw JSON or a base64-encoded copy of it (base64 is
    // easier to paste into a single-line .env value without escaping).
    const text = raw.trim().startsWith("{") ? raw : Buffer.from(raw, "base64").toString("utf8");
    return JSON.parse(text);
  } catch {
    console.error("[push] FIREBASE_SERVICE_ACCOUNT_JSON is set but is not valid JSON (or valid base64-of-JSON).");
    return null;
  }
}

async function getApp(): Promise<import("firebase-admin/app").App | null> {
  if (appPromise) return appPromise;
  appPromise = (async () => {
    const creds = loadCredentialsJson();
    if (!creds) return null;
    const { initializeApp, cert, getApps } = await import("firebase-admin/app");
    const existing = getApps();
    if (existing.length) return existing[0];
    try {
      return initializeApp({ credential: cert(creds as import("firebase-admin/app").ServiceAccount) });
    } catch (e) {
      console.error(`[push] Firebase Admin init failed: ${e instanceof Error ? e.message : "unknown"}`);
      return null;
    }
  })();
  return appPromise;
}

/** Is a Firebase project configured? Callers use this to skip the DB work of gathering tokens when push is off. */
export async function pushEnabled(): Promise<boolean> {
  return (await getApp()) != null;
}

/**
 * Sends one notification to up to 500 tokens (FCM's multicast limit) in one
 * batch, splitting larger lists. `data` values must be strings (FCM
 * requirement) — pass only ids, never names, amounts or phone numbers, same
 * rule as the audit log.
 */
export async function sendPush(tokens: string[], title: string, body: string, data: Record<string, string> = {}): Promise<SendResult> {
  const unique = Array.from(new Set(tokens.filter(Boolean)));
  if (!unique.length) return { attempted: 0, success: 0, failure: 0, disabled: false };
  const app = await getApp();
  if (!app) return { attempted: unique.length, success: 0, failure: 0, disabled: true };

  const { getMessaging } = await import("firebase-admin/messaging");
  const messaging = getMessaging(app);
  let success = 0;
  let failure = 0;
  const staleTokens: string[] = [];

  for (let i = 0; i < unique.length; i += 500) {
    const batch = unique.slice(i, i + 500);
    try {
      const res = await messaging.sendEachForMulticast({
        tokens: batch,
        notification: { title, body },
        data,
        android: { priority: "high", notification: { channelId: "swarmangal_updates" } },
      });
      success += res.successCount;
      failure += res.failureCount;
      res.responses.forEach((r, idx) => {
        const code = r.error?.code ?? "";
        if (code.includes("registration-token-not-registered") || code.includes("invalid-argument")) {
          staleTokens.push(batch[idx]);
        }
      });
    } catch (e) {
      failure += batch.length;
      console.error(`[push] send failed: ${e instanceof Error ? e.message : "unknown"}`);
    }
  }

  if (staleTokens.length) {
    const { query } = await import("@/lib/db");
    await query(`delete from push_tokens where fcm_token = any($1::text[])`, [staleTokens]).catch(() => {});
  }

  return { attempted: unique.length, success, failure, disabled: false };
}
