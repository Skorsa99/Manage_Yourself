# Subagent briefing template

Fill in the `<...>` parts and delete any section that doesn't apply. Subagents start with none of the supervisor's context, so be specific.

---

```
You are a subagent working for a supervising session. Do the task below,
then report back in the format at the end.

## Task
<what to do, and why>

## Done when
<concrete finish criteria, e.g. "tests in tests/foo pass", "function X handles Y">

## Context
- Relevant files: <paths>
- Decisions already made: <...>
- Don't touch: <files or areas owned by other subagents>

## Usage limits
<Keep ONE of the blocks below, or delete this section if usage is no concern.>

[CHECK-INS]
Usage is tight. Every 3–5 tool calls, run:
  <absolute path to>/scripts/check-usage.sh
If the 5-hour OR 7-day window shows 95% used or more, finish your current
small step, then pause as described under "How to pause".

[PAUSE FIRST]
Don't start yet. The usage window resets at <unix timestamp> (<local time>).
Pause right away as described under "How to pause". Once it resets, run
check-usage.sh, then start the task.

## How to pause
Don't treat a pause as a failure, and don't return early. Wait like this:
1. Make sure your work so far is saved to disk. Note the next step for yourself.
2. Run ONE wait command that lasts until 2 minutes after the reset time.
   Run it in the background (Bash with run_in_background, or the Monitor tool)
   so it isn't stopped by the 10-minute limit on normal commands:
     until [ "$(date +%s)" -ge $(( <reset timestamp> + 120 )) ]; do sleep 60; done; echo "usage window reset"
   Use one long wait, not many short ones. Each extra turn costs usage, and
   near the limit those turns can fail.
3. When the wait finishes, run check-usage.sh, then continue.

If you can't wait (for example, background commands are blocked), stop and
reply starting with "PAUSED until <local time>", then say what's done and the
exact next step, so the work can be resumed later.

## Report format
- Status: done / partial / paused
- What changed (files and a one-line summary each)
- How you verified it (tests run, output checked)
- Open questions or risks
Keep it short. The supervisor reviews the diff itself.
```
