#!/usr/bin/env bash

set -euo pipefail

BASE_REF="${1:-origin/main}"
SRC_ROOT="src"

declare -A changed_ips

echo "Comparing HEAD against ${BASE_REF}..." >&2

mapfile -t changed_files < <(
    git diff --name-only "${BASE_REF}...HEAD"
)

if [[ ${#changed_files[@]} -eq 0 ]]; then
    exit 0
fi


# -----------------------------------------------------------------------------
# Check whether repository-wide infrastructure changed
# -----------------------------------------------------------------------------

infrastructure_changed=false

for file in "${changed_files[@]}"; do
    case "${file}" in
        Makefile|\
        .rules.verible_lint|\
        scripts/*|\
        .github/workflows/*)
            infrastructure_changed=true
            break
            ;;
    esac
done


# -----------------------------------------------------------------------------
# Infrastructure changes affect every IP core
# -----------------------------------------------------------------------------

if [[ "${infrastructure_changed}" == "true" ]]; then
    find "${SRC_ROOT}" \
        -type f \
        -name ip.mk \
        -printf '%h\n' \
        | sed "s|^${SRC_ROOT}/||" \
        | sort

    exit 0
fi


# -----------------------------------------------------------------------------
# Find the IP root containing each modified file
# -----------------------------------------------------------------------------

for file in "${changed_files[@]}"; do

    # Ignore files outside src/.
    if [[ "${file}" != "${SRC_ROOT}/"* ]]; then
        continue
    fi

    dir="$(dirname "${file}")"

    while [[ "${dir}" == "${SRC_ROOT}"* ]]; do

        if [[ -f "${dir}/ip.mk" ]]; then
            ip="${dir#${SRC_ROOT}/}"
            changed_ips["${ip}"]=1
            break
        fi

        if [[ "${dir}" == "${SRC_ROOT}" ]]; then
            break
        fi

        dir="$(dirname "${dir}")"
    done
done


# -----------------------------------------------------------------------------
# Print one IP per line
# -----------------------------------------------------------------------------

if [[ ${#changed_ips[@]} -gt 0 ]]; then
    printf '%s\n' "${!changed_ips[@]}" | sort
fi
