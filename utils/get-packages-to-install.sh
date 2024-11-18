#!/bin/bash

# Function to check if a package is a dependency
is_dependency() {
    local pkg="$1"
    # skip kernel packages
    if [[ ${pkg:0:6} == "kernel" ]]; then
        return 0
    fi
    if [[ ${pkg} == "firewalld" ]]; then
        return 0
    fi
    # Check direct package name dependencies
    if rpm -q --whatrequires "$pkg" &>/dev/null; then
        return 0  # It is a dependency
    fi
    return 1
}

# Create a temporary file to store standalone packages
tmp_file=$(mktemp)
trap 'rm -f $tmp_file' EXIT

# Get all packages and find standalone ones
all_packages=$(rpm -qa --qf "%{NAME}\n" | sort -u)
while read -r pkg; do
    if ! is_dependency "$pkg"; then
        echo "$pkg" >> "$tmp_file"
    fi
done <<< "$all_packages"

# Generate dnf install commands with max 10 packages each
counter=0
packages=""

dnf install -y epel-release
crb enable

while read -r pkg; do
    if [ $counter -eq 0 ]; then
        packages="$pkg"
    else
        packages="$packages $pkg"
    fi
    
    counter=$((counter + 1))
    
    # When we reach 10 packages or the last line, output the dnf command
    if [ $counter -eq 10 ] || [ $(wc -l < "$tmp_file") -eq $(grep -n "^$pkg$" "$tmp_file" | cut -d: -f1) ]; then
        echo "dnf install -y --skip-broken $packages"
        counter=0
        packages=""
    fi
done < "$tmp_file"

