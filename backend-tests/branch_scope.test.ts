import { test } from "node:test";
import assert from "node:assert/strict";

import {
  makeScope,
  inScope,
  moneyInScope,
  recordBranch,
  matchesRequestedBranch,
  defaultBranch,
} from "../src/lib/rpc/scope.ts";

const kandivaliOnly = makeScope(["KANDIVALI"]);
const bothBranches = makeScope(["GOREGAON", "KANDIVALI"]);
const noBranches = makeScope([]);

test("recordBranch normalises the stored values the import uses", () => {
  assert.equal(recordBranch("GOREGAON"), "GOREGAON");
  assert.equal(recordBranch("goregaon west"), "GOREGAON");
  assert.equal(recordBranch("KANDIVALI"), "KANDIVALI");
  // Blank branch has always meant Kandivali in this data.
  assert.equal(recordBranch(""), "KANDIVALI");
  assert.equal(recordBranch(null), "KANDIVALI");
});

test("staff scoped to one branch cannot see the other", () => {
  assert.equal(inScope(kandivaliOnly, "KANDIVALI"), true);
  assert.equal(inScope(kandivaliOnly, ""), true);
  assert.equal(inScope(kandivaliOnly, "GOREGAON"), false);
});

test("a scope covering every branch is unrestricted", () => {
  assert.equal(bothBranches.unrestricted, true);
  assert.equal(inScope(bothBranches, "GOREGAON"), true);
  assert.equal(inScope(bothBranches, "ANYTHING"), true);
});

test("an empty scope sees nothing (fail closed)", () => {
  assert.equal(noBranches.unrestricted, false);
  assert.equal(inScope(noBranches, "KANDIVALI"), false);
  assert.equal(inScope(noBranches, ""), false);
});

test("unassigned money rows are hidden from restricted staff, shown to founder", () => {
  assert.equal(moneyInScope(kandivaliOnly, ""), false);
  assert.equal(moneyInScope(kandivaliOnly, null), false);
  assert.equal(moneyInScope(kandivaliOnly, "KANDIVALI"), true);
  assert.equal(moneyInScope(kandivaliOnly, "GOREGAON"), false);
  assert.equal(moneyInScope(bothBranches, ""), true);
});

test("requested branch filter treats ALL/blank as no filter", () => {
  assert.equal(matchesRequestedBranch("ALL", "GOREGAON"), true);
  assert.equal(matchesRequestedBranch("", "GOREGAON"), true);
  assert.equal(matchesRequestedBranch("KANDIVALI", "GOREGAON"), false);
  assert.equal(matchesRequestedBranch("KANDIVALI", ""), true);
});

test("new records default to the staff branch, not a hardcoded one", () => {
  assert.equal(defaultBranch(kandivaliOnly, undefined), "KANDIVALI");
  assert.equal(defaultBranch(makeScope(["GOREGAON"]), undefined), "GOREGAON");
  assert.equal(defaultBranch(makeScope(["GOREGAON"]), "ALL"), "GOREGAON");
  // An explicit request still wins, and the caller checks it against scope.
  assert.equal(defaultBranch(kandivaliOnly, "GOREGAON"), "GOREGAON");
  assert.equal(defaultBranch(bothBranches, undefined), "KANDIVALI");
});
