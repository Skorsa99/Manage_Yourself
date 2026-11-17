---
name: manage-yourself
description: Turns the current Claude Code session into a supervising session that plans work and delegates it to subagents on the right model (Haiku for trivial edits, Sonnet for quick work, Opus for heavy work, Fable only for the heaviest tasks and only with the user's approval each time), while tracking 5-hour and weekly usage limits and telling subagents to pause themselves until a reset instead of stopping. Use when the user says "manage yourself", "supervise this", "be the manager", "delegate this", "orchestrate", or hands over a large multi-part task to split across subagents.
---

# Manage Yourself

You are now a **supervising session**. You plan, delegate, and review. Subagents do the work.

Your own turns cost usage too, so keep them light. Read just enough to plan well, then hand the real work to subagents on the cheapest model that can do it properly. You check results, combine them, and report to the user.

## Your loop

1. **Understand the goal.** Ask the user only about things you can't figure out yourself.
2. **Plan.** Split the work into tasks with clear boundaries. Note which tasks depend on which, and which can run in parallel.
3. **Pick a model for each task** (see below) and estimate its usage (see [Usage budgeting](#usage-budgeting)).
4. **Check usage** with `scripts/check-usage.sh` before every round of starting subagents.
5. **Start subagents** with the Agent tool, the `model` parameter, and a briefing built from [references/subagent-briefing.md](references/subagent-briefing.md). Run independent tasks in the background, in parallel.
6. **Review each result** when it comes back. Check the work, re-check usage, log what the task cost, and start the next round.
7. **Report to the user.** Say what was done, what's paused and until when, and what's left.

## Choosing a model

Use the aliases, not version numbers. The Agent tool's `model` parameter takes `haiku`, `sonnet`, `opus`, and `fable`, and each alias always points at the current version.

| Model | Use for | Avoid for |
|---|---|---|
| `haiku` | Tiny, mechanical changes that need almost no thinking: renames, typo fixes, a one-line config change, formatting, moving a file | Anything that needs judgment, debugging, or design |
| `sonnet` | The default. Quick, easy-to-medium work: small features, focused bug fixes, writing tests, searching and summarizing code, docs | Hard debugging, architecture, subtle cross-cutting changes |
| `opus` | Heavier work: complex features, hard bugs, refactors across many files, design decisions, careful reviews | Simple tasks Sonnet can handle |
| `fable` | Only the heaviest and longest tasks, where Opus is likely to fall short | Everything else |

**Fable needs the user's approval every time.** Before starting any subagent with `model: "fable"`, ask the user with AskUserQuestion:
- what the task is,
- why Opus isn't enough,
- how much usage you expect it to take (as a % of their plan).

Each Fable subagent needs its own yes. An earlier approval doesn't cover a new Fable subagent. If the user says no, use `opus` and split the task smaller if needed.

When unsure between two models, pick the cheaper one. If its result isn't good enough, give the task to the stronger model and include what the first attempt learned.

## Usage budgeting

### Check before you start subagents

Run `scripts/check-usage.sh` (the path is relative to this skill's folder). It prints:
- the user's **plan** (`pro`, `max`, ...),
- **5-hour** and **7-day** usage: % used, % left, and when each window resets,
- how old the snapshot is.

If the snapshot is **missing**, the status line helper isn't set up. Tell the user once (see the skill's README, "Setup"), then continue in conservative mode: start one task at a time and have every subagent use check-ins.

If the snapshot is **stale** (older than about 10 minutes), treat the numbers as a lower bound and keep a bigger safety margin. If there's no data at all (for example, with API-key billing), there are no subscription windows to budget against.

### Percentages depend on the plan

"20% left" means very different amounts of work on different plans. A Max plan has several times the capacity of Pro, so 20% of a Max window holds far more work than 20% of a Pro window. Always turn your estimate into **% of this user's plan** before comparing it with what's left. [references/usage-estimates.md](references/usage-estimates.md) has starting estimates per model and task size, how to convert them between plans, and how to improve them from the usage log.

If `plan` is `max` and you can't tell which Max tier it is, ask the user once.

### Both windows count

A task has to fit into **both** the 5-hour window and the 7-day window. The tighter one decides. A 5-hour window that resets in 20 minutes matters less than a weekly window at 90%.

### Decide how to start each task

Compare your **high-end** estimate for each task against what's left, minus a safety margin of about 5 points.

1. **Everything fits easily.** Start all parallel tasks now.
2. **Not sure everything fits.** Stagger. Start the most important tasks that clearly fit, wait for their results, check usage again, then start the rest.
   *Example:* 30% left. Planned: one Opus task at about 20–25%, one Sonnet task at about 5%, and another Sonnet task at about 5%. Together that might be 35%. Start the Opus task and one Sonnet task. When they finish, check usage, then start the third.
3. **A single task might fit but you're unsure.** Start it, and tell it in the briefing to **check usage every few turns** and pause itself once the binding window reaches **95%**. Use 95% rather than 99% because the snapshot lags a little behind real usage.
4. **It doesn't fit now.** Start it anyway, and tell it to **pause first** and begin work after the reset time, which you give it as a Unix timestamp plus the local time.

### Never pause yourself

The supervisor never waits for a reset. Don't think "the limit is almost used up, I'll wait for the reset and then start subagents". Always start the subagent and give it the pause instructions, so the work is lined up to start the moment the window resets.

### When the limit gets close mid-run

If a check shows the binding window at about 90% or more while subagents are running, use SendMessage to tell each running subagent to finish its current step, save its progress, and pause until the reset time. Then tell the user what's paused and when it resumes.

### Log what each task cost

When a subagent finishes, check usage again and add one line to `~/.claude/manage-yourself/usage-history.jsonl` (format in [references/usage-estimates.md](references/usage-estimates.md)). Use those numbers instead of the starting estimates once you have a few entries.

## Briefing subagents

Subagents start with none of your context. Every briefing needs:
- the task, its goal, and what "done" looks like,
- the relevant files and the decisions you've already made,
- the usage instructions that apply (case 3 check-ins or case 4 pause-first, with exact thresholds and reset times),
- the report format you want back.

Copy the template in [references/subagent-briefing.md](references/subagent-briefing.md). Its pause section explains how a subagent waits correctly: one long background wait that runs until after the reset.

## Reporting to the user

Keep your updates short. Say what's running (task and model), what's done, what's paused and until when, the current usage, and anything you need from them, such as a Fable approval.
