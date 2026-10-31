# Script Corrections & Review

Review of `SCRIPTS.md`, `init_all.sh`, and everything in `aux_scripts/`.

## Part 1 — Syntax bugs fixed in place

### `aux_scripts/key_setup.sh` (line 4)
```diff
- cd $KEY_PATH || echo "Authorized key path DNE" && exit
+ cd "$KEY_PATH" || { echo "Authorized key path DNE"; exit 1; }
```
`&&`/`||` are left-associative with equal precedence, so `A || B && C` parses as
`(A || B) && C`, not `A || (B && C)`. Whenever `cd` **succeeded**, `(A || B)` was
already true, so `&& exit` fired — the script exited immediately on the
*success* path and never ran `ssh-keygen`. Braces force `echo`+`exit` to run
only when `cd` fails. Also quoted `$KEY_PATH`.

### `aux_scripts/lockdown.sh` (lines 4, 6)
```diff
- cd KEY_PATH
+ cd "$KEY_PATH"
...
- cd PROJECT_PATH
+ cd "$PROJECT_PATH"
```
Missing `$` — this was literally trying to `cd` into a directory named
`KEY_PATH`/`PROJECT_PATH`, which doesn't exist, instead of expanding the
variables. Not an interpretation issue, just a typo.

### `aux_scripts/check_git_pull.sh` (line 3, same bug)
```diff
- cd PROJECT_PATH
+ cd "$PROJECT_PATH"
```

### `aux_scripts/check_git_pull.sh` (line 10)
```diff
- if [ "$local_hash"=="$repo_hash" ]; then
+ if [ "$local_hash" == "$repo_hash" ]; then
```
With no spaces, `[ ]` saw one concatenated string argument
(`"hashA==hashB"`), which is always non-empty → the test was **always true**
regardless of the actual hashes. Fixed the spacing so it's a real comparison.
(See Part 2 — the comparison direction itself still looks backwards.)

### `aux_scripts/deploy.sh` (line 14)
```diff
- ${COMMAND} "cd DSCS553 && export PROJECT_PATH = $(pwd)"
+ ${COMMAND} "cd DSCS553 && export PROJECT_PATH=$(pwd)"
```
`export NAME = VALUE` with spaces is invalid assignment syntax — `export`
would just be handed the three bare words `PROJECT_PATH`, `=`, and the `pwd`
output, none of which sets anything.

### `aux_scripts/set_cronjobs.sh` (line 9)
```diff
- ${COMMAND} "(crontab -l 2>/dev/null | grep -Fv "/path/to/backup.sh"; echo "$JOB") | crontab -"
+ ${COMMAND} "(crontab -l 2>/dev/null | grep -Fv \"/path/to/backup.sh\"; echo \"$JOB\") | crontab -"
```
Unescaped inner `"..."` inside the outer `"..."` closes the outer string
early. The unquoted `(`, `|`, `;` that fall outside quotes are shell
metacharacters, so this wasn't being sent to `ssh` as one argument — bash was
trying to parse/run pieces of it *locally* (e.g. opening `(crontab -l ...)`
as a local subshell) instead of running it on the runner. Escaping the inner
quotes keeps it one argument while still letting `$JOB` expand locally
(intentional, since `JOB` is a local variable).

### `aux_scripts/red_team_attack.sh` (lines 19, 30)
```diff
- OTHER_PORT=$(sed -n"${i}p" )
+ OTHER_PORT=$(sed -n "${i}p")
```
`-n` is a boolean flag; jamming `"${i}p"` directly onto it (`-n5p`) makes
`sed` try to parse `5p` as more flags and error out.
```diff
- sleep $((RANDOM%30))[s]
+ sleep $((RANDOM % 30))
```
The trailing `[s]` is not shell syntax `sleep` understands — it gets
concatenated onto the number (e.g. `sleep 15[s]`), which `sleep` rejects as
an invalid time interval.

## Part 2 — Logic issues NOT fixed (flagged only)

- **`check_secure.sh` — the big one.** On detecting the runner was reset, it
  calls `bash init_all.sh`. But `init_all.sh` re-clones the repo,
  regenerates `mykey` (invalidating the old key), and re-runs
  `set_cronjobs.sh`. SCRIPTS.md explicitly says `init_main.sh` skips
  `set_cronjobs.sh` "otherwise every time there's an error we'd get more cron
  jobs" — but `check_secure.sh` bypasses that guard entirely. It almost
  certainly should call `init_main.sh`, not `init_all.sh`. Also, `git clone`
  into an already-existing `DSCS553` dir will just fail outright on any
  repeat run.

- **Nothing ever clones the repo onto the `runner`.** `deploy.sh` opens with
  `${COMMAND} "ls DSCS553"`, assuming it's already there, but no script
  performs a `git clone` on the runner side. As written, `deploy.sh` will
  fail at the first line.

- **Relative key paths, wrong cwd.** `deploy.sh`'s `COMMAND` uses `-i mykey`
  and `check_secure.sh` uses `-i student-admin_key` — both relative. Neither
  script `cd`s into `$KEY_PATH` first (`deploy.sh` runs from
  `$PROJECT_PATH`, and `check_secure.sh` on cron typically runs from
  `$HOME`), so ssh will report "no such identity file" in both cases. These
  need `"${KEY_PATH}mykey"` / `"${KEY_PATH}student-admin_key"`.

- **`export PROJECT_PATH` in `deploy.sh` never actually reaches anywhere
  useful**, even once the `=` spacing is fixed: (1) `$(pwd)` inside the
  double-quoted string is expanded **locally** before being sent over ssh,
  not remotely, so it captures the monitor's `pwd`, not the runner's; (2)
  each `${COMMAND} "..."` is a separate ssh session/process, so an export in
  one has no effect on the next command; (3) nothing persists it into the
  runner's environment for cron to see later. `check_git_pull.sh` depends on
  `$PROJECT_PATH` being set when cron runs it on the runner, but nothing ever
  establishes that variable there.

- **`set_cronjobs.sh` cron job names/paths are placeholder text**, not real
  paths: `/path/to/check_seccre.sh` (typo for `check_secure.sh`) and
  `/path/to/check_get_pull.sh` (typo for `check_git_pull.sh`), and neither
  uses `$PROJECT_PATH`. As-is, cron would try to execute files that don't
  exist.

- **Same file's de-dup filters don't match their own jobs.** Both
  `grep -Fv "/path/to/backup.sh"` lines are meant to strip a previous copy of
  the job before re-adding it, but they filter for `backup.sh` while the
  jobs being added reference `check_seccre.sh`/`check_get_pull.sh`.
  Re-running `set_cronjobs.sh` will just pile up duplicate cron entries
  instead of replacing the old one.

- **`check_git_pull.sh` comparison direction looks backwards.** Even after
  the syntax fix, `if [ "$local_hash" == "$repo_hash" ]` triggers `git pull`
  when the hashes **match** (nothing changed) and stays quiet when they
  **differ** (there's actually a new commit) — the opposite of "if there's a
  new commit, pull." Suggest `!=`.

- **`key_setup.sh`'s `ssh-keygen` will prompt interactively** for a
  passphrase (no `-N ""`), which will hang if this is ever invoked
  non-interactively (e.g. via the `check_secure.sh` → `init_all.sh` chain
  above). Also, each re-run appends a fresh `mykey.pub` to `authorized_keys`
  without ever removing the previous one, so stale (but harmless) keys
  accumulate over time.

- **`connect_mykey.sh` doesn't connect with "mykey"** — despite its
  name/SCRIPTS.md description, it uses `student_admin_key` (underscore, and
  also inconsistent with the hyphenated `student-admin_key` used everywhere
  else), and relies on `$PORT`/`$MACHINE` being set externally with no
  fallback. Looks like it was meant to mirror `connect_student_admin_key.sh`
  but got the wrong key baked in.

- **`connect_student_admin_key.sh` hardcodes `PORT=21003`**, while
  everything else in the system (`init_all.sh`, `red_team_attack.sh`) uses
  `22002`/`22000` — likely a leftover from a different course/term; worth
  double-checking before relying on it.

- **`red_team_attack.sh`'s `sed`** still has no input file — even after the
  spacing fix, `sed -n "${i}p"` reads from stdin (no `$FILE` argument
  passed), so it'll hang waiting for input rather than reading `ports.txt`.
  Needs `sed -n "${i}p" "$FILE"`.

- **Minor SCRIPTS.md documentation drift** (not code, just noting): it
  references `connect_student_admin.sh`, `git_pull.sh`, and
  `set_cronsjobs.sh`, none of which match the actual filenames
  (`connect_student_admin_key.sh`, `check_git_pull.sh`, `set_cronjobs.sh`).

## Part 3 — ssh-agent vs. `-i`/cwd dependence

`ssh-agent` + `ssh-add` is exactly the mechanism meant to make `-i` and
working-directory unnecessary: once a key is loaded into a running agent,
any `ssh`/`scp` call that can *see* that agent offers the loaded keys
automatically. It didn't help here because later scripts couldn't find the
agent, not because the agent lacked the key.

`eval "$(ssh-agent -s)"` starts the agent as a background daemon and sets
`SSH_AUTH_SOCK`/`SSH_AGENT_PID` so ssh clients know where its socket is.
Those variables only exist in the process that ran the `eval`. Since
`key_setup.sh` was originally invoked as `bash key_setup.sh` (a child
process), its exports died with it and never reached sibling scripts
(`deploy.sh`, `lockdown.sh`, `check_secure.sh`), which are separate `bash
x.sh` processes.

Two fixes, solving different halves of the problem:

1. **Within one `init_all.sh` run:** `source key_setup.sh` instead of
   `bash key_setup.sh`, so the exports land in `init_all.sh`'s own shell.
   Env vars flow normally parent → child, so anything `init_all.sh` forks
   *after* that line (`init_main.sh`, `set_cronjobs.sh`, and everything they
   in turn call) inherits `SSH_AUTH_SOCK` and can reach the agent. **This
   fix was applied and is correct** — see Part 4.

2. **Across independent invocations** (e.g. `check_secure.sh` run later by
   cron, with no relation to the process tree that started the agent):
   sourcing doesn't bridge that gap. The standard pattern is to have
   `key_setup.sh` persist the agent's connection info to a file, and have
   every script that needs ssh source that file first:
   ```bash
   # in key_setup.sh, after starting the agent:
   eval "$(ssh-agent -s)" > /dev/null
   env | grep -E '^SSH_AUTH_SOCK=|^SSH_AGENT_PID=' > "${KEY_PATH}agent.env"
   ssh-add mykey
   ssh-add student-admin_key
   ```
   ```bash
   # at the top of lockdown.sh, deploy.sh, check_secure.sh, etc.:
   [ -f "${KEY_PATH}agent.env" ] && source "${KEY_PATH}agent.env"
   ```
   Then those scripts can drop `-i mykey` / `-i student-admin_key` entirely
   and rely on the agent. **Not yet applied** — still needed for
   `check_secure.sh` specifically (see Part 4, item 5).

Nuance: OpenSSH doesn't stop at a missing `-i` file by default — it just
warns ("Identity file mykey not accessible") and still falls through to
agent-offered keys *if* the agent is reachable. So the `-i` relative-path bug
and the agent-visibility problem are two symptoms of the same root cause.

## Part 4 — Review of corrections made after Part 1/2

### Correctly fixed
- `init_all.sh` — `source key_setup.sh` instead of `bash key_setup.sh` (see
  Part 3).
- `key_setup.sh` — added `-N ""` to `ssh-keygen`, avoiding an interactive
  passphrase prompt that would hang any non-interactive invocation.
- `check_secure.sh` — now calls `bash init_main.sh` instead of
  `bash init_all.sh`, fixing the most important Part 2 issue (no more
  re-cloning/re-keying/duplicate cron jobs on every red-team reset).
- `check_git_pull.sh` — `==` changed to `!=`, now matching the stated intent
  ("pull if there's a new commit").
- `set_cronjobs.sh` — real `$PROJECT_PATH`-based paths instead of
  `/path/to/...` placeholders (right direction, though see below for
  remaining bugs in how it's used).

### New syntax bug introduced, fixed — `deploy.sh` line 16
```diff
- ${COMMAND} "cd DSCS553 && "export PROJECT_PATH=$(pwd)">>~/.bashrc"
+ ${COMMAND} "cd DSCS553 && echo \"export PROJECT_PATH=\$(pwd)\" >> ~/.bashrc"
```
The quotes didn't balance: `"cd DSCS553 && "` closed, then
`export PROJECT_PATH=$(pwd)` and `>>~/.bashrc` sat unquoted, then a stray
trailing `"` opened a string that was never closed — bash would either
error with "unexpected EOF while looking for matching '\"'" or silently
swallow every subsequent line into one string. Separately, the unquoted
`$(pwd)` and `>>~/.bashrc` were being evaluated/redirected **locally on the
monitor** before ever reaching `ssh`, not on the runner — so this would have
captured the monitor's own `pwd` and appended output to the *monitor's*
`~/.bashrc`, not the runner's. The fix balances the quoting and escapes
`\$(pwd)` so both the substitution and the redirect happen on the remote
side, exactly as the line originally intended.

This is only the syntax repair, though — the underlying approach still
won't achieve the goal, which is a logic call left open: cron jobs don't
source `~/.bashrc` (cron runs with a minimal, non-login environment), so
`check_git_pull.sh`'s `cd "$PROJECT_PATH"` will still find `$PROJECT_PATH`
unset when cron invokes it on the runner. A more reliable fix would be for
`check_git_pull.sh` to derive its own location instead of depending on an
inherited env var, e.g. `cd "$(dirname "$0")"`, since cron always invokes it
by full absolute path anyway.

### Still open in `set_cronjobs.sh`

1. **Double `aux_scripts/` nesting.** `PROJECT_PATH` is already the
   `aux_scripts` directory (`init_all.sh` does `cd DSCS553/aux_scripts`
   *then* `export PROJECT_PATH=$(pwd)`). But the `check_secure.sh` job
   builds:
   ```
   JOB="0 /3 * * * $PROJECT_PATH/aux_scripts/check_secure.sh"
   ```
   which resolves to `.../DSCS553/aux_scripts/aux_scripts/check_secure.sh` —
   a path that doesn't exist. The `check_git_pull` job gets this part right
   (`$PROJECT_PATH/check_git_pull.sh`, no extra segment).

2. **The `grep -Fv` dedup filters don't match their own jobs**, so
   re-running this script will pile up duplicate crontab lines instead of
   replacing the old one:
   - The `check_secure` filter is `"$PROJECT_PATH/check_secure.s"` (missing
     `aux_scripts/`, and truncated `.s` instead of `.sh`) — doesn't match
     the actual JOB string either way.
   - The `check_git_pull` filter is
     `"$PROJECT_PATH/aux_scripts/check_git_pull.sh"` (has the extra
     `aux_scripts/`) while the actual JOB is
     `"$PROJECT_PATH/check_git_pull.sh"` (no extra segment) — mismatched in
     the *other* direction.

3. **Cron step syntax `0 /3 * * *`.** The conventional, portable form is
   `*/3` (with the leading asterisk). A bare `/3` is accepted by some cron
   implementations as shorthand but isn't POSIX-specified, and `crontab -`
   will reject the *entire* crontab if the daemon doesn't like one line —
   meaning no cron entries get updated at all, not just this one. Consider
   changing to `*/3` unless the target cron's acceptance of the bare form
   has been confirmed.

4. **`$PROJECT_PATH` for the runner's cron job is the monitor's path, not
   the runner's.** It gets expanded locally on the monitor before ever
   reaching `ssh`, which is fine in principle (it becomes a literal
   absolute path baked into the crontab line) — but only correct if the
   monitor and runner happen to have identical directory layouts under
   `$HOME` (same username, same clone location). If those differ, e.g.
   monitor is a personal account and runner is `student-admin`, this path
   will be wrong on the runner. Safer: capture the runner's actual path by
   sshing in and running `pwd` there, rather than reusing the monitor's
   local variable.

5. **The agent-persistence gap from Part 3 is still real for
   `check_secure.sh` specifically** — it's a standalone cron job on the
   monitor, launched independent of `init_all.sh`'s process tree, so it has
   no access to the ssh-agent that `source key_setup.sh` set up. Its
   `-i student-admin_key` (relative, no `$KEY_PATH`) will fail to find the
   key. This is the one place the `agent.env` file approach described in
   Part 3 is still needed.

### Bottom line before pushing to main
Not ready yet: the `deploy.sh` unterminated-quote bug alone would likely
break that script on execution (fixed above), and the `set_cronjobs.sh`
path/dedup issues (items 1–2 above) mean re-running it will silently
misfire — wrong path for `check_secure.sh`, duplicate entries piling up for
both jobs. Recommend resolving at least items 1–2 (they break behavior, not
just style) before pushing.
