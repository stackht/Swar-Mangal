// Typed RPC client for the Swar Mangal gateway (`POST /api/rpc`).
//
// Mirrors lib/core/api.dart: form-encoded
//   function=<name>&token=<token>&arg=<json>
// with a 45 second timeout, and classifies non-ok bodies the same way the
// Flutter app does.
//
// The raw device token is NEVER stored in client JavaScript. In the browser
// `token` is left empty and the server gateway resolves the session from the
// httpOnly `sm_rpc_token` cookie (see src/app/api/auth/token/route.ts), sent
// automatically because the request includes credentials.

import type { RpcEnvelope } from "./rpc-types";

export const ERR_INVALID_CONFIG = "INVALID_CONFIG";
export const ERR_NETWORK_UNREACHABLE = "NETWORK_UNREACHABLE";
export const ERR_HTTP_ERROR = "HTTP_ERROR";
export const ERR_WRONG_BACKEND = "WRONG_BACKEND";
export const ERR_AUTH_FAILED = "AUTH_FAILED";
export const ERR_ROLE_FORBIDDEN = "ROLE_FORBIDDEN";
export const ERR_BRANCH_FORBIDDEN = "BRANCH_FORBIDDEN";
export const ERR_BACKEND = "BACKEND_ERROR";

export const RPC_TIMEOUT_MS = 45_000;
export const DEFAULT_RPC_URL = "/api/rpc";

export type RpcArg = Record<string, unknown>;

/** A backend refusal, an HTTP error or malformed payload. */
export class RpcError extends Error {
  readonly code: string;
  readonly payload?: Record<string, unknown>;

  constructor(message: string, code: string = ERR_BACKEND, payload?: Record<string, unknown>) {
    super(code ? `${message} [${code}]` : message);
    this.name = "RpcError";
    this.code = code;
    this.payload = payload;
  }
}

/** Transport failure: offline, unreachable, timeout, DNS. */
export class RpcUnreachable extends Error {
  readonly code: string;

  constructor(message: string, code: string = ERR_NETWORK_UNREACHABLE) {
    super(message);
    this.name = "RpcUnreachable";
    this.code = code;
  }
}

/** Map a backend `code` to the classification the UI hints on. */
export function classifyRpcCode(code: string): string {
  const upper = (code || "").toUpperCase();
  if (upper.includes("UNAUTHORIZED") || upper.includes("INVALID_TOKEN") || upper.includes("AUTH_FAILED")) {
    return ERR_AUTH_FAILED;
  }
  if (upper.includes("ROLE") || (upper.includes("FORBIDDEN") && upper.includes("FOUNDER"))) {
    return ERR_ROLE_FORBIDDEN;
  }
  if (upper.includes("BRANCH")) {
    return ERR_BRANCH_FORBIDDEN;
  }
  if (upper.includes("BAD_BODY") || upper.includes("BAD_SHAPE") || upper.includes("WRONG_BACKEND")) {
    return ERR_WRONG_BACKEND;
  }
  return ERR_BACKEND;
}

export class RpcClient {
  readonly baseUrl: string;
  readonly token: string;

  /**
   * @param baseUrl  Gateway URL, default `/api/rpc` (same origin).
   * @param token    Device token for server-side callers. Browser callers pass
   *                 "" and rely on the httpOnly cookie.
   */
  constructor(baseUrl: string = DEFAULT_RPC_URL, token: string = "") {
    this.baseUrl = baseUrl;
    this.token = token;
  }

  async call<T = RpcEnvelope>(fn: string, arg?: RpcArg): Promise<T> {
    const body = new URLSearchParams();
    body.set("function", fn);
    if (this.token) body.set("token", this.token);
    if (arg !== undefined) body.set("arg", JSON.stringify(arg));

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), RPC_TIMEOUT_MS);

    let res: Response;
    try {
      res = await fetch(this.baseUrl, {
        method: "POST",
        credentials: "include",
        cache: "no-store",
        headers: { "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8" },
        body,
        signal: controller.signal,
      });
    } catch (e) {
      if (controller.signal.aborted) {
        throw new RpcUnreachable("Server timed out. Check your connection and retry.");
      }
      const detail = e instanceof Error ? e.message : String(e);
      throw new RpcUnreachable(`Could not reach server. Check your connection.\nDetail: ${detail}`);
    } finally {
      clearTimeout(timer);
    }

    if (res.status !== 200) {
      throw new RpcError(`Server returned HTTP ${res.status}.`, ERR_HTTP_ERROR);
    }

    const text = await res.text();
    let data: unknown;
    try {
      data = JSON.parse(text);
    } catch {
      throw new RpcError("Server answered in an unexpected format. Wrong backend URL?", ERR_WRONG_BACKEND);
    }
    if (typeof data !== "object" || data === null || Array.isArray(data)) {
      throw new RpcError("Unexpected server payload.", ERR_WRONG_BACKEND);
    }

    const payload = data as Record<string, unknown>;
    if (payload.ok === true) return payload as T;

    const rawCode = String(payload.code ?? payload.reason ?? "");
    const message = String(payload.error ?? "Request failed.");
    throw new RpcError(message, classifyRpcCode(rawCode), payload);
  }
}

let sharedClient: RpcClient | null = null;

/** Same-origin browser client. Token resolved from the httpOnly cookie. */
export function getRpcClient(): RpcClient {
  if (!sharedClient) sharedClient = new RpcClient();
  return sharedClient;
}

/** One-shot helper for the shared cookie-authenticated client. */
export function rpc<T = RpcEnvelope>(fn: string, arg?: RpcArg): Promise<T> {
  return getRpcClient().call<T>(fn, arg);
}
