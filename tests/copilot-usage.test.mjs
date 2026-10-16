import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import {
	formatPlanUsage,
	formatProgressBar,
	formatTokens,
	formatUsageSummary,
	getUsageProgress,
	parseCopilotUsage,
	summarizeSession,
	writeClipboard,
} from "../pi/extensions/lib/copilot-usage-core.ts";

const enterpriseUsage = {
	copilot_plan: "enterprise",
	token_based_billing: true,
	quota_reset_date_utc: "2026-11-01T00:00:00.000Z",
	quota_snapshots: {
		premium_interactions: {
			token_based_billing: true,
			percent_remaining: 24,
			credits_used: 15192,
			entitlement: 20000,
			quota_remaining: 4810.5,
			unlimited: false,
			has_quota: true,
		},
	},
};

test("parses Copilot internal account quota, plan, and reset date", () => {
	assert.deepEqual(parseCopilotUsage(enterpriseUsage), {
		plan: "Copilot Enterprise",
		unit: "AI credits",
		used: 15192,
		limit: 20000,
		remaining: 4810.5,
		percentUsed: 76,
		resetAt: "2026-11-01T00:00:00.000Z",
		unlimited: false,
	});
});

test("parses legacy premium-request quota and unlimited account", () => {
	const legacy = parseCopilotUsage({
		copilot_plan: "pro",
		quota_snapshots: { premium_interactions: { percent_remaining: 80, entitlement: 300, quota_remaining: 240 } },
	});
	assert.equal(legacy.unit, "premium requests");
	assert.equal(legacy.percentUsed, 20);
	assert.equal(legacy.plan, "Copilot Pro");

	const unlimited = parseCopilotUsage({
		copilot_plan: "enterprise",
		quota_snapshots: { premium_interactions: { unlimited: true, has_quota: false } },
	});
	assert.equal(unlimited.unlimited, true);
	assert.equal(unlimited.percentUsed, undefined);
});

test("rejects missing quota data", () => {
	assert.throws(() => parseCopilotUsage({ copilot_plan: "enterprise" }), /no Copilot usage quota/);
});

test("formats plan, quota, reset, progress, and clean clipboard text", () => {
	const usage = parseCopilotUsage(enterpriseUsage);
	assert.equal(formatPlanUsage(), "");
	assert.equal(formatPlanUsage(usage), "Copilot Enterprise 76%");
	assert.deepEqual(formatUsageSummary(usage), [
		"Copilot usage and plan",
		"Plan: Copilot Enterprise",
		"AI credits (resets monthly): 15,192 / 20,000 (76% used)",
		"Resets: Nov 1 UTC",
	]);
	assert.equal(getUsageProgress(usage), 76);

	const unlimited = parseCopilotUsage({ copilot_plan: "enterprise", quota_snapshots: { premium_interactions: { unlimited: true } } });
	assert.equal(formatPlanUsage(unlimited), "Copilot Enterprise ∞");
	assert.equal(getUsageProgress(unlimited), undefined);
	assert.deepEqual(formatUsageSummary(unlimited), [
		"Copilot usage and plan",
		"Plan: Copilot Enterprise",
		"premium requests: unlimited",
		"Resets monthly",
	]);

	assert.equal(formatProgressBar(50, 8), "████░░░░");
	assert.equal(formatProgressBar(125, 3), "███");
	assert.equal(formatProgressBar(75, 0), "");
});

test("writes clipboard text and rejects command failures", async () => {
	const directory = await mkdtemp(join(tmpdir(), "copilot-usage-test-"));
	try {
		const clipboard = join(directory, "clipboard.txt");
		const successCommand = join(directory, "pbcopy-success");
		const failureCommand = join(directory, "pbcopy-failure");
		await writeFile(successCommand, `#!${process.execPath}\nconst fs = require("node:fs"); process.stdin.pipe(fs.createWriteStream(${JSON.stringify(clipboard)}));\n`, { mode: 0o755 });
		await writeFile(failureCommand, `#!${process.execPath}\nprocess.stdin.resume(); process.stdin.on("end", () => process.exit(7));\n`, { mode: 0o755 });
		const text = "Copilot usage and plan\nPlan: Copilot Enterprise";
		await writeClipboard(text, successCommand);
		assert.equal(await readFile(clipboard, "utf8"), text);
		await assert.rejects(writeClipboard(text, failureCommand));
	} finally {
		await rm(directory, { recursive: true, force: true });
	}
});

test("formats tokens", () => {
	assert.equal(formatTokens(999), "999");
	assert.equal(formatTokens(17_000), "17.0K");
	assert.equal(formatTokens(1_200_000), "1.2M");
});

test("summarizes provider usage and whole-session footer stats", () => {
	const entries = [
		{
			type: "message",
			message: {
				role: "assistant",
				provider: "github-copilot",
				usage: { input: 10, output: 2, cacheRead: 5, cacheWrite: 1, cost: { total: 0.03 } },
			},
		},
		{ type: "usage", provider: "github-copilot", usage: { input: 4, output: 1, cost: { total: 0.01 } } },
		{ type: "message", message: { role: "assistant", provider: "openai", usage: { input: 100, output: 100, cost: { total: 1 } } } },
	];
	assert.deepEqual(summarizeSession(entries, "github-copilot"), {
		input: 14,
		output: 3,
		cacheRead: 5,
		cacheWrite: 1,
		cost: 0.04,
	});
	assert.equal(summarizeSession(entries).input, 114);
});
