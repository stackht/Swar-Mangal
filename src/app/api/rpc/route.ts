import { NextRequest, NextResponse } from "next/server";
import { authenticateToken } from "@/lib/rpc/auth";
import { rpcDispatch } from "@/lib/rpc/handlers";
import { dispatch2 } from "@/lib/rpc/handlers2";
import { isDbConfigured } from "@/lib/db";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const sheetOkResponse = (body: Record<string, unknown>) => {
  const json = JSON.stringify(body);
  return new NextResponse(json, {
    status: 200,
    headers: { "Content-Type": "application/json; charset=UTF-8" },
  });
};

export async function POST(req: NextRequest) {
  if (!isDbConfigured) {
    return sheetOkResponse({ ok: false, code: "NO_DB", error: "Database not configured" });
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
      return sheetOkResponse({ ok: false, code: "BAD_BODY", error: "Expected form (function/token/arg) or JSON body" });
    }
  }

  if (!functionName) return sheetOkResponse({ ok: false, code: "UNKNOWN_API", error: "No function given" });

  const session = authenticateToken(token);
  if (!session) return sheetOkResponse({ ok: false, code: "UNAUTHORIZED", error: "Invalid or missing token" });

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
    return sheetOkResponse(result);
  } catch (e) {
    return sheetOkResponse({ ok: false, code: "SERVER_ERROR", error: e instanceof Error ? e.message : String(e) });
  }
}