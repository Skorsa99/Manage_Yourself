# Manage Yourself

A [Claude Code skill](https://code.claude.com/docs/en/skills) that plans work, delegates it to subagents on the right model, and stays within your 5-hour and weekly usage limits by pausing until the next reset.

## What it does

- **Plans and delegates.** The main session stays light. Subagents do the actual work.
- **Picks the right model for each task:**
  - **Haiku** for tiny, mechanical changes
  - **Sonnet** for quick, everyday work (the default)
  - **Opus** for heavy work: hard bugs, big refactors, design
  - **Fable** only for the heaviest, longest tasks, and **only after you approve each Fable subagent**
- **Budgets usage.** Before starting subagents, it checks your plan (Pro, Max, ...) and how much of the 5-hour and weekly windows is left, then estimates what each task will cost on *your* plan.
- **Pauses subagents instead of stopping.** When usage gets tight, the supervisor still starts the work but tells the subagent to wait until the window resets. It staggers tasks when it isn't sure they'll all fit, and has risky subagents check usage every few turns and pause at 95%.
- **Learns from history.** It logs what each task actually cost, so later estimates get better.

## Installation

### As a plugin (recommended)

```
/plugin marketplace add Skorsa99/Manage_Yourself
/plugin install manage-yourself@manage-yourself
```

### Manually

```bash
git clone https://github.com/Skorsa99/Manage_Yourself.git
cp -r Manage_Yourself/skills/manage-yourself ~/.claude/skills/
```

## Setup: let the skill see your usage

Claude Code only shares usage limits with your **status line** script, so the skill comes with a small wrapper that saves them to `~/.claude/manage-yourself/usage-snapshot.json`.

1. Install the wrapper:

   ```bash
   mkdir -p ~/.claude/manage-yourself
   curl -fsSL https://raw.githubusercontent.com/Skorsa99/Manage_Yourself/main/skills/manage-yourself/scripts/usage-snapshot.sh \
     -o ~/.claude/manage-yourself/usage-snapshot.sh
   chmod +x ~/.claude/manage-yourself/usage-snapshot.sh
   ```

2. Point your status line at it in `~/.claude/settings.json`:

   ```json
   "statusLine": {
     "type": "command",
     "command": "~/.claude/manage-yourself/usage-snapshot.sh",
     "refreshInterval": 60
   }
   ```

   **Already have a status line?** Keep it by passing its command as the first argument. The wrapper saves the usage data, then runs your command as before:

   ```json
   "command": "~/.claude/manage-yourself/usage-snapshot.sh '<your existing command>'"
   ```

Requires `jq` (preinstalled on recent macOS; otherwise `brew install jq` / `apt install jq`). Usage data only exists on claude.ai subscriptions (Pro, Max, ...). On API-key billing the skill still delegates, but it has no limits to budget against.

Without this setup, the skill still works, in a more conservative mode: it starts one task at a time and has every subagent check usage as it goes.

## Usage

Start a session and say something like:

- "Manage yourself: build the settings page, add tests, and update the docs."
- "Be the supervisor for this refactor and delegate the pieces."
- `/manage-yourself` followed by your task

You can check your usage yourself at any time:

```bash
~/.claude/skills/manage-yourself/scripts/check-usage.sh
```

## Repository structure

```
.
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest
│   └── marketplace.json         # Lets this repo be added as a plugin marketplace
├── skills/
│   └── manage-yourself/
│       ├── SKILL.md             # The skill: supervisor role, model choice, budgeting rules
│       ├── references/
│       │   ├── subagent-briefing.md   # Briefing template incl. check-in and pause instructions
│       │   └── usage-estimates.md     # Per-model estimates, plan conversion, usage log
│       └── scripts/
│           ├── usage-snapshot.sh      # Status line wrapper that saves usage limits
│           └── check-usage.sh         # Prints plan + 5-hour / 7-day usage
├── LICENSE
└── README.md
```

## Limitations

- The usage snapshot is only as fresh as the last status line update, so the skill keeps a safety margin.
- Usage estimates start as rough guesses and improve as the usage log fills up.

## Fair use

This skill does not get around usage limits. It reads them and respects them: when a window is nearly used up, work waits for the reset. It's meant for your own, ordinary use of Claude Code, as assumed by Anthropic's plan limits, not for running Claude around the clock. Anthropic can change limits at any time.

## License

[MIT](LICENSE)
