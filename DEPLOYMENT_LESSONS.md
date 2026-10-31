# Deployment Scripts — Lessons & Process Improvements

A retrospective on the `aux_scripts/` deployment work, based on the commit
history and `SCRIPT_CORRECTIONS.md`. The goal: understand *why* the scripts
needed so many test-and-revise cycles, and how to make the process feel more
like a production workflow.

## What the commit history is telling you

The log reads like a debugging session done *on* `main`: `AAAAAAAAAAAAA`,
`typo`, `typo...`, `whoops`, `hopefully this fixes issues`, `redploy`,
`really, config.env wasn't added?`. Roughly 20 commits over three days,
almost every one a one- or two-line fix to a bug that only surfaced when the
script was run live against the remote.

That's the core problem to fix — not any single script.

The bugs themselves fall into a small number of repeating categories:

1. **Shell quoting / expansion mistakes** — `cd PROJECT_PATH` (missing `$`),
   `export PROJECT_PATH = $(pwd)` (spaces around `=`), `[ "$a"=="$b" ]`
   (no spaces → always true), nested unescaped quotes in the cron one-liners,
   `sed -n"${i}p"`. These are *detectable before running*.
2. **Local-vs-remote confusion** — `$(pwd)`, `>> ~/.bashrc`, and `export`
   evaluated on the monitor when you meant the runner; relative `-i mykey`
   paths that only work from one cwd; cron running from `$HOME` instead of
   the script dir.
3. **Idempotency / re-run safety** — `git clone` into an existing dir, cron
   jobs piling up because the `grep -Fv` dedup filter didn't match the job
   string, `check_secure.sh` calling the full `init_all.sh` and re-keying
   every cycle.
4. **Env not surviving process boundaries** — `ssh-agent` vars dying with the
   child `bash x.sh`; `$PROJECT_PATH` not existing under cron.

Categories 1 and 4 are the ones eating the most time, and both are largely
preventable without ever touching the remote.

## The process changes that matter most

### 1. Lint every script before you commit

The single highest-leverage change. `shellcheck` would have caught almost
every Part 1 bug in `SCRIPT_CORRECTIONS.md` instantly — the missing `$`, the
`==` spacing, the unescaped quotes, the `export NAME = VALUE`, the unquoted
variables.

```bash
sudo apt install shellcheck        # once
shellcheck aux_scripts/*.sh init_all.sh
```

Pair it with `bash -n script.sh` (parse-only, no execution) as a fast syntax
gate. PyCharm also has a shellcheck integration. Lint is the difference
between finding a bug in 2 seconds locally vs. a full clone-deploy cycle
against the remote.

### 2. Add `set -euo pipefail` to the top of every script

Right now failures are silent — a bad `cd` continues into the next command
operating in the wrong directory, which is exactly how `rm -r` / `scp` went
to the wrong place. With this:

- `-e` stops on the first failed command instead of charging ahead,
- `-u` turns `cd $UNSET_VAR` into an immediate error instead of `cd` to `$HOME`,
- `-o pipefail` makes a failure anywhere in a pipeline count.

This alone converts a whole class of "silently did the wrong thing" bugs into
loud, early failures. Handle the intentional "it's okay if this fails" cases
explicitly with `|| true`.

### 3. Stop debugging on `main`. Use a branch and test locally first

Every one of those `hopefully this works` commits went straight to main and
triggered the HF sync workflow. Instead:

```bash
git checkout -b deploy-fixes
# edit, shellcheck, bash -n, dry-run locally
git commit
# only merge to main once it actually deploys
```

A branch costs nothing and means main always reflects a known-good state.
Combine with `git commit --amend` / interactive squashing so the final
history reads as intent ("fix ssh-agent propagation across cron invocations")
rather than a keystroke log.

### 4. Make the inner loop local

Most of the bugs don't need the WPI remote at all. Two cheap techniques:

- **`bash -x script.sh`** (or `set -x` in the script) prints each command
  *with variables expanded* before running it. You'd have seen `cd
  PROJECT_PATH` and `ssh -i mykey ...` (no path) printed out, immediately
  obvious.
- **Echo-dry-run the remote commands.** You already build `COMMAND="ssh ..."`.
  Put `DRYRUN=${DRYRUN:-0}` at the top and wrap remote calls so
  `DRYRUN=1 bash deploy.sh` *prints* what it would send instead of sending
  it. You verify the fully-expanded command string — catching the
  local-vs-remote `$(pwd)` expansion bugs — without a round trip.

### 5. Write scripts to be idempotent (safe to run twice)

This is a production mindset, and `check_secure.sh` re-running on a timer
makes it mandatory. Patterns you needed:

- clone-or-pull instead of bare clone:
  `[ -d DSCS553 ] && git -C DSCS553 pull || git clone … DSCS553`
- the dedup `grep -Fv` filter string must be *identical* to the job string
  you add (yours drifted — `.s` vs `.sh`, extra `aux_scripts/`). Better:
  install cron from a file with a stable marker, or drop a file in
  `/etc/cron.d` rather than editing `crontab -` in place.
- guard key generation (you did eventually add `if [ ! -f mykey ]`, though
  note the current `key_setup.sh` still has a stray second
  `cat mykey.pub >> authorized_keys` outside the guard — it re-appends every
  run).

### 6. Don't depend on inherited env across process/cron boundaries

You hit this twice (ssh-agent, `$PROJECT_PATH`). The robust pattern for a
script that must know its own location:

```bash
cd "$(dirname "$(readlink -f "$0")")"
```

Cron always invokes by absolute path, so this is reliable where
`$PROJECT_PATH` (set in a parent shell that cron never saw) is not. Sourcing
`config.env` explicitly at the top of each script — which you converged on —
is the right instinct; apply it uniformly rather than relying on exports
flowing downward.

## Commands/tools you should be using and (mostly) aren't

| Tool | Why it helps you here |
|---|---|
| `shellcheck` | Catches ~all your Part-1 syntax/quoting bugs before running. The biggest single win. |
| `bash -n` | Parse-only syntax check; instant, no side effects. |
| `bash -x` / `set -x` | Trace execution with variables expanded — shows local-vs-remote expansion bugs. |
| `set -euo pipefail` | Fail fast and loud instead of silently doing the wrong thing. |
| git feature branches + `--amend`/squash | Keep main deployable; history reflects intent, not keystrokes. |
| a pre-commit hook | Run shellcheck + `bash -n` automatically on every commit so you can't forget. |
| `ssh -o BatchMode=yes` for tests | You use this in `check_secure.sh` already — good; it makes a dead key fail fast instead of hanging on a prompt. Apply the same non-interactive discipline everywhere. |
| `ssh host 'bash -s' < local.sh` or `scp`+run | Cleaner than cramming multi-command logic into nested-quoted `ssh "..."` strings (the source of your cron-quoting bug). Send a real script, run it remotely. |

A `.git/hooks/pre-commit` (or the `pre-commit` framework) that runs:

```bash
#!/bin/bash
shellcheck aux_scripts/*.sh init_all.sh && \
for f in aux_scripts/*.sh init_all.sh; do bash -n "$f" || exit 1; done
```

…would have blocked most of your bad commits at the door.

## The one-line version

The scripts failing wasn't bad luck — it was a missing *verification layer*.
You were using the remote server as your linter and your test suite. Move
three cheap checks to the left of "commit + deploy": **shellcheck**,
**`bash -n`/`bash -x` local dry-runs**, and **`set -euo pipefail`**, all on a
**branch** that only merges to main when it works. Write each script to be
**idempotent** and to **not rely on inherited env**. That turns a 20-commit
"hopefully this works" cycle into a couple of reviewed, deployable commits.
