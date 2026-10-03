# Linux Server Automation Toolkit

A collection of 10 production-style Bash scripts for automating common Linux server operations — health monitoring, backups, user management, service control, and deployment with automatic rollback — unified under a single CLI wrapper, `cloudops.sh`.

Built to demonstrate real operational Bash scripting: consistent logging, meaningful exit codes, configuration-driven behavior, and safety checks (dry-run modes, protected-user guards, automatic rollback) — not just "a script that runs."

## Features

| Command | Script | What it does |
|---|---|---|
| `health` | health-check.sh | CPU/memory/disk check with PASS/FAIL summary |
| `disk` | disk-alert.sh | Disk usage check across all real mount points |
| `processes` | process-monitor.sh | Top CPU/memory processes, total process count |
| `logs` | log-cleanup.sh | Deletes logs older than retention period (`--dry-run` supported) |
| `backup` | backup.sh | Timestamped compressed backup with rotation |
| `db-backup` | database-backup.sh | MySQL dump + compression, least-privilege DB user |
| `user-create` | user-create.sh | Creates a Linux user (regex validation, `--dry-run`, `--sudo`) |
| `user-delete` | user-delete.sh | Deletes a Linux user (protected-user list, requires `--force`) |
| `services` | service-restart.sh | Restarts a systemd service, verifies it's active afterward |
| `deploy` | deployment.sh | Deploys with post-deploy health check and automatic rollback on failure |

## Architecture

linux-automation-toolkit/
├── cloudops.sh # unified CLI — dispatches to scripts/
├── config/cloudops.conf # central settings (thresholds, paths, DB config)
├── lib/common.sh # shared log(), error_exit(), require_command()
├── scripts/ # 10 standalone, individually runnable scripts
└── logs/ # runtime logs (gitignored)


Every script is independently runnable (`./scripts/health-check.sh`) **and** callable through the wrapper (`./cloudops.sh health`) — `cloudops.sh` is a thin dispatcher, not a reimplementation.

### Design decisions

- **Config-driven, not hardcoded**: thresholds and paths live in `config/cloudops.conf`, so deploying to a different server means editing one file, not ten scripts.
- **Consistent exit codes** across every script: `0` success, `1` general error, `2` bad usage, `3` missing dependency, `4` threshold breached — so `cloudops.sh`, cron, or a future CI pipeline can all make decisions based on exit status alone.
- **Least-privilege database access**: backups run as a dedicated MySQL user with only `SELECT`/`LOCK TABLES`/`SHOW VIEW` — not root.
- **Credentials never hardcoded**: database password lives in a permission-locked (`chmod 600`) `~/.my.cnf`, excluded from the repo.
- **Dry-run support** on destructive operations (`log-cleanup.sh`, `user-create.sh`) to preview before acting.
- **Deploy-with-rollback**: `deployment.sh` backs up the previous version, deploys the new one, runs a health check, and automatically restores the backup if the check fails.

## Usage

```bash
./cloudops.sh health
./cloudops.sh user-create alice --sudo
./cloudops.sh services mysql
./cloudops.sh logs --dry-run
```

## Automation

Five jobs run via cron: frequent disk checks, hourly health checks, nightly log cleanup, and nightly file + database backups (staggered to avoid I/O contention). See `crontab -l` entries / cron section below for schedule details.

## Challenges & Solutions

- **CRLF line endings breaking bash parsing**: VS Code saved the config file with Windows line endings, causing `$'\r': command not found` and corrupted paths. Fixed with `sed` and a `.vscode/settings.json` enforcing LF endings project-wide.
- **`$0` vs `${BASH_SOURCE[0]}`**: path resolution using `$0` broke when a script was sourced rather than executed. Switched to `${BASH_SOURCE[0]}`, which is correct in both cases.
- **stdout/stderr mixing in logging**: the shared `log()` function wrote to stdout via `tee`, which polluted command-substitution captures (`cpu_usage=$(check_cpu)` picked up log lines along with the number). Fixed by redirecting the terminal-visible copy to stderr (`>&2`), keeping the file write and leaving stdout clean for return values.
- **`sudo` changes `$HOME`**: scripts run with `sudo` resolved `$HOME` to `/root`, breaking config-driven log paths. Fixed by deriving the toolkit's root directory from the script's own location (`${BASH_SOURCE[0]}`) instead of the environment.
- **GNU `tar` silently ignoring `--exclude` after positional arguments**: `backup.sh` initially failed to exclude `.git`/`logs` because the excludes were placed after `-C`/the source path. Fixed by reordering flags before positional arguments.
- **`mysqldump` requiring the `PROCESS` privilege for tablespace metadata**: rather than widening the least-privilege backup user's grants, added `--no-tablespaces` to skip that unnecessary step.
- **Verified rollback logic with a real failure injection**: deliberately broke the source config to force a failing post-deploy health check, confirmed `deployment.sh` automatically rolled back to the last good version, then restored the source and redeployed cleanly.
- **Real disk alert caught in testing**: `disk-alert.sh` correctly flagged the host machine's `C:` drive (mounted into WSL2) at 89-92% usage during testing — genuine evidence the threshold logic works against real data, not just synthetic tests.

## Tech

Bash, systemd (`systemctl`), MySQL (`mysqldump`), `cron`, `rsync`, `tar`/`gzip`. Developed and tested on WSL2 Ubuntu.
