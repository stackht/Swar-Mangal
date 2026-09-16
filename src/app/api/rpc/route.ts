import { NextRequest, NextResponse } from "next/server";
import { authenticateToken } from "@/lib/rpc/auth";
import { rpcDispatch } from "@/lib/rpc/handlers";
import { dispatch2 } from "@/lib/rpc/handlers2";
import { authorizeRpc, authorizeBranch } from "@/lib/rpc/authorization";
import { isDbConfigured } from "@/lib/db";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const rpcOkResponse = (body: Record<string, unknown>) => {
  const json = JSON.stringify(body);
  return new NextResponse(json, {
    status: 200,
    headers: { "Content-Type": "application/json; charset=UTF-8" },
  });
};

const rpcError = (code: string, message: string) =>
  rpcOkResponse({ ok: false, code, error: message });

function logDeny(sessionEmail: string, role: string, fn: string, code: string, branch: string) {
  // SAFE logging: no token, no password, no payload, no PII.
  console.warn(`[rpc-deny] ts=${new Date().toISOString()} role=${role} email=${sessionEmail} fn=${fn} code=${code} branch=${branch || "none"}`);
}

export async function POST(req: NextRequest) {
  if (!isDbConfigured) {
    return rpcError("NO_DB", "Database not configured");
  }

  let functionName = "";
  let token = "";
  let argMap: Record<string, unknown> = {};

  const formData = await req.formData().catch(() => null);
  if (formData && formData.entries().next().done === false) {
    functionName = String(formData.get("function") ?? "");
    token = String(formData.get("token") ?? "");
    const argRaw = String(formData.get("arg") ?? "");
    if (argRaw) {
      try {
        argMap = JSON.parse(argRaw);
      } catch {
        argMap = {};
      }
    }
  } else {
    try {
      const j = await req.json();
      functionName = String(j?.function ?? "");
      token = String(j?.token ?? "");
      argMap = typeof j?.arg === "object" && j?.arg !== null ? j.arg : {};
    } catch {
      return rpcError("BAD_BODY", "Expected form (function/token/arg) or JSON body");
    }
  }

  if (!functionName) {
    return rpcError("UNKNOWN_API", "No function given");
  }

  // ---- authenticate ----
  const session = authenticateToken(token);
  if (!session) {
    return rpcError("AUTH_FAILED", "Invalid or missing token");
  }

  // ---- authorize (fail-closed, BEFORE handler execution) ----
  const roleCheck = authorizeRpc(session, functionName);
  if (!roleCheck.ok) {
    logDeny(session.email, session.role, functionName, roleCheck.code, "");
    return rpcError(roleCheck.code, roleCheck.message || "Not authorised");
  }

  const branchCheck = authorizeBranch(session, argMap);
  if (!branchCheck.ok) {
    logDeny(session.email, session.role, functionName, branchCheck.code, "");
    return rpcError(branchCheck.code, branchCheck.message || "Branch not authorised");
  }

  // ---- execute handler (only after authz) ----
  const inHandlers1 = [
    "api_bootstrap", "api_staff_boot",
    "api_searchStudent", "api_staff_searchStudents", "api_staff_getStudentProfile", "api_studentProfile",
    "api_staff_studentHub", "api_addStudent", "api_staff_saveStudentDraft", "api_founder_setStudentStatus", "api_founder_mergeStudentDraft",
    "api_searchReceipt", "api_receiptPreflight", "api_addFeePayment", "api_staff_prepareReceiptDraft",
    "api_founder_listPaymentDrafts", "api_founder_paymentDraftApprove", "api_founder_paymentDraftReject",
    "api_founder_finalisePaymentDraft", "api_staff_finalisePaymentDraft",
  ];
  try {
    const handler = inHandlers1.includes(functionName) ? rpcDispatch : dispatch2;
    const result = await handler(session.role, functionName, argMap);
    return rpcOkResponse(result);
  } catch (e) {
    return rpcError("SERVER_ERROR", "Backend error");
  }
}