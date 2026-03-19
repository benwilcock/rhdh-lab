# Backup and Restore

## Overview

The backup system creates portable archives of your RHDH configuration that can be restored on any system, allowing team members to replicate your setup.

## What Gets Backed Up

**Included:**
- `rhdh-customizations/` -- all configuration files, scripts, and documentation
- `backup.sh` -- the backup script itself
- Auto-generated `RESTORE.md` -- step-by-step restore instructions

**Not included:**
- `rhdh-local/` -- users clone this fresh (or it arrives as a git submodule)
- Container volumes and runtime data -- recreated when RHDH starts
- System files (`.DS_Store`, temp files)

## Creating a Backup

```bash
./backup.sh
```

Backups are stored in `~/rhdh-local-backups/` with timestamped filenames:

```
~/rhdh-local-backups/
└── rhdh-local-setup-backup_2026-03-19_10-30-15.tar.gz
```

## Restoring on a New System

1. **Clone the repository** (includes `rhdh-local/` as a submodule):

   ```bash
   git clone --recurse-submodules <your-repo-url> rhdh-lab
   cd rhdh-lab
   ```

2. **Extract the backup** into the workspace:

   ```bash
   tar -xzf rhdh-local-setup-backup_*.tar.gz
   ```

3. **Create your `.env`** from the example and fill in your credentials:

   ```bash
   cp rhdh-customizations/.env.example rhdh-customizations/.env
   # Edit .env with your GitHub, Jenkins, email credentials, etc.
   ```

4. **Apply customizations and start RHDH:**

   ```bash
   ./up.sh --customized
   ```

5. **Access RHDH** at <http://localhost:7007>

## Use Cases

### Team Distribution

Share your setup with colleagues:

```bash
./backup.sh
# Send the archive to a team member
# They clone the repo, extract the backup, configure .env, and start
```

### Multi-Machine Setup

Maintain identical environments across machines:

```bash
# On machine A
./backup.sh
scp ~/rhdh-local-backups/rhdh-local-setup-backup_*.tar.gz user@machineB:~/

# On machine B -- clone, extract, configure, start
```

### Pre-Change Safety Net

Back up before making experimental changes:

```bash
./backup.sh
# Make changes...
# If something breaks, restore from the archive
```

## Backup Strategy

| Frequency | When |
|-----------|------|
| Before changes | Before modifying configuration or updating RHDH |
| Weekly | For stable, actively-used environments |
| Daily | If actively developing and experimenting |

### Retention

Clean up old backups periodically:

```bash
cd ~/rhdh-local-backups
ls -t rhdh-local-setup-backup_*.tar.gz | tail -n +8 | xargs rm -f
```

## Security Considerations

Backup archives may contain sensitive data (API tokens, OAuth secrets, email passwords) if your `.env` is included. Best practices:

1. **Do not store backups in public locations** -- use encrypted storage or private channels
2. **Remove `.env` before sharing** if the recipient will use their own credentials
3. **Encrypt archives** for off-site storage:

   ```bash
   gpg -c ~/rhdh-local-backups/rhdh-local-setup-backup_*.tar.gz
   ```

4. **Rotate credentials** after sharing backups that contain them

## Viewing Backup Contents

```bash
tar -tzf ~/rhdh-local-backups/rhdh-local-setup-backup_*.tar.gz
```

## Troubleshooting

**Backup fails with "permission denied":**

```bash
chmod +x backup.sh
```

**Restore: customizations not applied:**

```bash
cd rhdh-customizations && ./apply-customizations.sh
```

**Restore: RHDH won't start:**

Check that all required environment variables in `.env` are set correctly (GitHub credentials, email, Jenkins, etc.).
