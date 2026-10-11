# Linux User Access Management

A hands-on Linux administration project for creating users and groups, configuring file permissions, testing access, and auditing account access with Bash.

## Project Overview

This project simulates three departments—IT Support, Security, and HR. Each department has a group and a directory, demonstrating the **principle of least privilege**: users should have only the access needed for their role.

### Objectives

- Create Linux users and department groups.
- Assign users to the appropriate groups.
- Configure directory ownership and permissions.
- Test allowed and denied access.
- Generate a basic access audit report with Bash.

## Environment and Prerequisites

- Ubuntu Linux on a computer or virtual machine
- A user account with `sudo` privileges
- Bash, `systemd`, and `journalctl`
- Optional: `acl` package for inspecting Access Control Lists

> **Safety:** Run these exercises in a test VM or another system you are authorized to administer. Do not modify production accounts or permissions without approval.

## Project Structure

```text
linux-user-access-management/
├── README.md
├── audit_access.sh
├── docs/
│   └── access-control-design.md
└── screenshots/
    └── .gitkeep
```

## 1. Verify Administrative Access

```bash
whoami
groups
sudo -v
```

## 2. Create Department Groups

```bash
sudo groupadd it_support
sudo groupadd security_team
sudo groupadd hr_team
```

Verify:

```bash
getent group it_support
getent group security_team
getent group hr_team
```

Group IDs vary between systems.

## 3. Create Test Users

```bash
sudo useradd -m -s /bin/bash support01
sudo useradd -m -s /bin/bash security01
sudo useradd -m -s /bin/bash hr01
```

Set passwords interactively:

```bash
sudo passwd support01
sudo passwd security01
sudo passwd hr01
```

Do not put passwords directly in scripts or GitHub files.

Verify the accounts:

```bash
getent passwd support01
getent passwd security01
getent passwd hr01
ls -ld /home/support01 /home/security01 /home/hr01
```

## 4. Assign Users to Groups

```bash
sudo usermod -aG it_support support01
sudo usermod -aG security_team security01
sudo usermod -aG hr_team hr01
```

The `-aG` options append a supplementary group without replacing existing supplementary group memberships.

Check membership:

```bash
id support01
id security01
id hr01
getent group it_support
```

## 5. Create Department Directories

```bash
sudo mkdir -p /srv/company/it_support
sudo mkdir -p /srv/company/security
sudo mkdir -p /srv/company/hr
```

Set group ownership:

```bash
sudo chown root:it_support /srv/company/it_support
sudo chown root:security_team /srv/company/security
sudo chown root:hr_team /srv/company/hr
```

Set permissions:

```bash
sudo chmod 2770 /srv/company/it_support
sudo chmod 2770 /srv/company/security
sudo chmod 2770 /srv/company/hr
```

Verify:

```bash
ls -ld /srv/company/*
```

### Understanding `2770`

- `2`: Setgid bit; new files and subdirectories normally inherit the directory's group.
- Owner `7`: read, write, and execute.
- Group `7`: read, write, and execute.
- Others `0`: no access through the standard Unix permission bits.

For directories, execute permission allows traversal. Setgid helps keep shared files associated with the department group.

## 6. Create and Secure a Test File

```bash
sudo touch /srv/company/it_support/ticket_notes.txt
sudo chown root:it_support /srv/company/it_support/ticket_notes.txt
sudo chmod 660 /srv/company/it_support/ticket_notes.txt
ls -l /srv/company/it_support/ticket_notes.txt
```

The `660` permission gives the owner and group read/write access, with no permissions for others.

## 7. Test Access

Test that the IT Support user can create a file in the IT Support directory:

```bash
sudo -u support01 touch /srv/company/it_support/test.txt
```

This should succeed when the user has the expected group membership and directory access.

Test that the HR user cannot create a file there:

```bash
sudo -u hr01 touch /srv/company/it_support/hr_test.txt
```

This should fail with `Permission denied` if `hr01` has no other group membership, ACL, or other permission granting access.

Check the exit status immediately after a test command:

```bash
echo $?
```

A status of `0` generally indicates success; a non-zero status indicates failure.

> Users with administrative privileges, additional group memberships, or ACL grants may have access beyond this example. Always evaluate the complete access context.

## 8. Audit User Access

### Check account and group information

```bash
id support01
getent group it_support
```

### Inspect directory permissions and ownership

```bash
stat /srv/company/it_support
namei -l /srv/company/it_support
```

`namei -l` helps inspect permissions on each component of a path.

### Review recent login records

```bash
last -n 10
```

On systems using the `ssh` systemd service, inspect recent service logs with:

```bash
sudo journalctl -u ssh -n 50 --no-pager
```

Available records depend on the system's logging configuration. Review logs only on systems you are authorized to administer, and do not commit sensitive logs to a public repository.

### Optional: Inspect ACLs

Install the ACL utilities if needed:

```bash
sudo apt update
sudo apt install -y acl
```

Inspect a directory:

```bash
getfacl /srv/company/it_support
```

ACL entries can grant additional access beyond the standard owner/group/other permission bits.

## 9. Generate an Audit Report

Create `audit_access.sh` in the project directory:

```bash
nano audit_access.sh
```

Paste:

```bash
#!/bin/bash

set -u

REPORT="$HOME/linux-user-access-management-audit.txt"

{
    echo "======================================"
    echo "Linux User Access Audit Report"
    date
    echo "======================================"
    echo

    echo "----- Test User Accounts -----"
    for user in support01 security01 hr01; do
        if id "$user" >/dev/null 2>&1; then
            id "$user"
        else
            echo "User not found: $user"
        fi
    done

    echo
    echo "----- Department Groups -----"
    for group in it_support security_team hr_team; do
        getent group "$group" || echo "Group not found: $group"
    done

    echo
    echo "----- Department Directory Permissions -----"
    for dir in         /srv/company/it_support         /srv/company/security         /srv/company/hr; do
        if [ -d "$dir" ]; then
            stat -c '%A %a %U:%G %n' "$dir"
        else
            echo "Directory not found: $dir"
        fi
    done

    echo
    echo "----- Audit Complete -----"
} > "$REPORT"

echo "Audit report saved to: $REPORT"
```

Make it executable and run it:

```bash
chmod +x audit_access.sh
./audit_access.sh
```

View the report:

```bash
cat ~/linux-user-access-management-audit.txt
```

The script records the configured test users, group memberships, and ownership and permission bits of the department directories. It is a basic audit aid, not a complete security assessment.

## Troubleshooting

| Issue | Checks |
|---|---|
| User cannot access a directory | Run `id username` and `namei -l /path`. |
| User is missing from a group | Check `getent group groupname` and review the `usermod` command. |
| Permission denied unexpectedly | Inspect ownership, permissions, parent directories, ACLs, and group memberships. |
| File has the wrong owner or group | Use `ls -l` and `stat`. |
| Script will not execute | Check the file path, shebang, and `chmod +x audit_access.sh`. |
| Login records are missing | Check which logging services are enabled and what records the system retains. |

## Learning Outcomes

- Create and inspect Linux users and groups.
- Apply group-based access control.
- Explain Linux ownership and permission bits.
- Test permitted and denied file access.
- Investigate access issues using `id`, `stat`, `namei`, and `getfacl`.
- Create a Bash script that produces an access audit report.

## Future Improvements

- Create users and groups from a validated input file.
- Report unexpected group memberships.
- Detect world-writable files in selected directories.
- Add controlled ACL examples and tests.
- Add a cleanup script that asks for confirmation before removing test accounts and files.
- Capture sanitized screenshots of successful and denied access tests.

## GitHub Notes

Before publishing:

- Never commit passwords, private keys, or sensitive authentication logs.
- Use test accounts and sanitized screenshots only.
- Review commands and remove environment-specific information.
- Do not include real company or customer data.

## License

For educational and personal portfolio use.
