# Swar Mangal — Flutter APK → Backend Setup

The native app (`swar_mangal`) talks to the **existing** Google Apps Script
backend over HTTPS. No database was rewritten, no rule duplicated: money
computation, counters, locks, idempotency guards and audits stay server-side.

## Architecture

```
[ Flutter APK ]  ──POST function=<api>&token=<deviceToken>&arg=<json>──▶  [ Apps Script doPost ]
                                                                            └─ MobileApiGateway
                                                                               └─ bounded by role
                                                                                  └─ runs existing api_*
```

The apps authenticate with the *browser* Google session (`Session.getActiveUser()`
in `Code.js:226`). A native app has no browser session, so the gateway bridges
it with a **device token** the founder issues.

## 1. Required backend change (one file, held pending approval)

File already written to the repo (NOT deployed, NOT pushed):

```
docs/held/MobileApiGateway.gs
```

It adds `doPost` keyed on `function=` / `token=` / `arg=`, validates the token
against a `MOBILE_ACCESS` tab, checks the calling role against a per-role
endpoint allow list, then calls the existing `api_*` functions unchanged.

### Setup steps

1. In the master workbook add a tab **`MOBILE_ACCESS`**:
   `Token | Email | Role | Status | Created At | Note`
   - `Status` must be `ACTIVE`
   - `Role` → `FOUNDER_ADMIN` or `STAFF_OPS`
   - Generate tokens (e.g. `openssl rand -hex 24`) — give one per device/operator.
2. Set the master workbook id at `mobileAuthorize_()` (the `04-master` placeholder).
3. Deploy the founder/smart project with a **NEW deployment**:
   - `Execute as: Me (deployer)`
   - `Who has access: Anyone`
   - ⚠️ Under ANYONE the script resolves identity to the owner. The token is the
     only boundary. Do NOT point money-capable `FOUNDER_ADMIN` tokens at a plain
     person's phone; treat each token as the equivalent of the device holder.
4. `clasp push` + deploy only through the repo's guarded deploy flow with the
   founder's explicit approval (CLAUDE.md: no unattended push/deploy).

### Endpoint allow list (extend in `mobileRoute_`)

| Role | Allowed |
|---|---|
| FOUNDER_ADMIN + STAFF_OPS | `api_bootstrap`, `api_searchStudent`, `api_searchReceipt`, `api_dashboard`, `api_dueReminders`, `api_listTeachers`, `api_searchStudentsV2`, `api_receiptPreflight` |
| FOUNDER_ADMIN only | `api_addStudent`, `api_addFeePayment`, `api_addExpenseEntry`, `api_addTeacher`, `api_cashbookReport` |
| STAFF_OPS only | `api_staff_prepareReceiptDraft`, `api_staff_submitExpenseDraft`, `api_staff_saveStudentDraft` |

## 2. Point the app at the deployment URL

1. Open the app → Login screen → gear icon → "API server".
2. Paste the `/exec` URL of the *gateway* deployment (`…/s/<SCRIPT_ID>/exec`).
3. Enter the device token issued above.
4. Pick Founder or Staff surface.

The URL + token persist on the device (`shared_preferences`).

## 3. What the app covers today (v1.0.0)

**Founder surface**
- Home: collections, fee buckets, recent receipts
- Students: search + profile + receipts history
- Add Student (checked founder path → draft+merge)
- Add Fee (server-authoritative `api_addFeePayment`)
- Receipts (search + detail)
- Teachers (list + add)
- Expenses (record + cashbook)

**Staff surface**
- Branch gate (Goregaon / Kandivali), branch-isolated reads
- Today (task cards from `api_staff_todaysTasks`)
- Students (search + profile), Add Student → draft for founder merge
- Attendance (roster + mark)
- Add Fee (draft → routine self-serve or founder approval)
- Expenses (draft → founder approval)
- Inquiries (quick add + follow-up queue)
- Receipts (branch-isolated)

## 4. Build the APK

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

## 5. Security notes (read before issuing tokens)

- A `STAFF_OPS` token cannot ship money: the gateway routes its calls only to
  staff *draft* endpoints. None of them writes STUDENTS/STUDENT_RECEIPTS
  directly; founder approval keeps the existing bar.
- A `FOUNDER_ADMIN` token is equivalent to the founder account on that device:
  it can record receipts and expenses. Issue only to devices Sharvil owns.
- Never log tokens. The app posts them in the request body; Apps Script does
  not echo them back.
- Revoke by flipping `Status` in `MOBILE_ACCESS` to `DISABLED` — takes effect
  immediately (the gateway re-reads the tab per request).