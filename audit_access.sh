#!/bin/bash

set -u

REPORT="/home/bharath/linux-access-management-audit/linux-access-management-audit.txt"

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

    for dir in \
        /srv/company/it_support \
        /srv/company/security \
        /srv/company/hr; do

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
