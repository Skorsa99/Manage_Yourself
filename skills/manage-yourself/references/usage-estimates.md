# Usage estimates

These are **rough starting guesses**. Real usage depends heavily on how many files a task reads, how long it runs, and how big the context gets. Replace them with your own measurements as soon as the usage log has a few entries.

## Starting guesses: % of a **Pro** 5-hour window

| Task size | `haiku` | `sonnet` | `opus` | `fable` |
|---|---|---|---|---|
| Tiny: one file, a few lines | 1–2% | 2–4% | 5–10% | not used |
| Small: a few files, clear scope | 2–4% | 5–10% | 10–25% | not used |
| Medium: a feature with tests, some debugging | not used | 10–25% | 25–50% | not used |
| Large: many files, long-running | not used | 25–60% | 50–100%+ | 100%+ (spans windows) |

Usually a medium or large task in a single subagent on Pro won't fit into one 5-hour window. Split it, or plan for it to pause and continue after a reset.

## Converting to this user's plan

`check-usage.sh` reports the plan. Divide the Pro numbers by the plan's capacity relative to Pro:

| Plan | Relative capacity | Example: a 20% task on Pro becomes |
|---|---|---|
| `pro` | 1× | 20% |
| `max` (5×) | about 5× | about 4% |
| `max` (20×) | about 20× | about 1% |
| Other or unknown (e.g. `ultra`) | Ask the user, or measure | measure the first task |

If the plan is `max` and the tier isn't clear, ask the user once whether it's 5× or 20×.

## Weekly (7-day) window

One task uses a much smaller share of the weekly window than of the 5-hour window, but the weekly window is the one that can block work for days. Don't guess a ratio. Measure it: log both deltas for every task. Above about 90% weekly, treat the weekly window as the binding one and tell the user.

## The usage log

After each subagent finishes, add one JSON line to `~/.claude/manage-yourself/usage-history.jsonl`:

```bash
mkdir -p ~/.claude/manage-yourself
echo '{"date":"2026-11-17","plan":"pro","model":"sonnet","size":"small","task":"add input validation to signup form","five_hour_delta":6,"seven_day_delta":1,"concurrent":1}' >> ~/.claude/manage-yourself/usage-history.jsonl
```

- `five_hour_delta` and `seven_day_delta`: the change in `used_percentage` between your check before starting the task and your check after it finished.
- `concurrent`: how many subagents were running at the same time. When several run in parallel, the deltas overlap. Split them by your best guess, or only learn from the runs that ran alone.

Before estimating, read the log, look for entries with the same plan, model, and size, and use their typical values (lean toward the high end).
