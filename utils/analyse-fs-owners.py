#!/usr/bin/env python3
import os
import pwd
import grp
from pathlib import Path
import sys
from collections import defaultdict
import getpass

def get_user_groups(username):
    """Get all groups for a user using only Python standard library"""
    try:
        # Get user's password database entry for primary group
        pw_entry = pwd.getpwnam(username)
        primary_gid = pw_entry.pw_gid
        primary_group = grp.getgrgid(primary_gid).gr_name

        # Get all groups the user is in using os.getgrouplist
        gids = os.getgrouplist(username, primary_gid)
        
        # Convert GIDs to group names, excluding primary group
        secondary_groups = []
        for gid in gids:
            try:
                group_name = grp.getgrgid(gid).gr_name
                if group_name != primary_group:
                    secondary_groups.append(group_name)
            except KeyError:
                continue
        
        return primary_group, sorted(secondary_groups)
    except (KeyError, AttributeError):
        return None, []

def analyze_ownership(directory):
    current_user = getpass.getuser()
    users = defaultdict(set)    # {username: {uid}}
    groups = defaultdict(set)   # {groupname: {gid}}
    user_groups = {}           # {username: (primary_group, [secondary_groups])}
    
    # Get entries in directory (excluding hidden files)
    dir_path = Path(directory)
    entries = [e for e in dir_path.iterdir() if not e.name.startswith('.')]
    
    for entry in entries:
        stat = entry.stat()
        uid, gid = stat.st_uid, stat.st_gid
        
        try:
            username = pwd.getpwuid(uid).pw_name
            if username == current_user:  # Only process current user
                users[username].add(uid)
                
                # Get all groups for this user
                primary_group, secondary_groups = get_user_groups(username)
                if primary_group:
                    user_groups[username] = (primary_group, secondary_groups)
                    
                    # Add primary group to groups dict
                    try:
                        groups[primary_group].add(grp.getgrnam(primary_group).gr_gid)
                    except KeyError:
                        pass
                    
                    # Add secondary groups to groups dict
                    for group in secondary_groups:
                        try:
                            groups[group].add(grp.getgrnam(group).gr_gid)
                        except KeyError:
                            pass
        except KeyError:
            pass
    
    return users, groups, user_groups

def generate_script(users, groups, user_groups, output_file="create_users_groups.sh"):
    with open(output_file, 'w') as f:
        # Write script header
        f.write('#!/bin/bash\n\n')
        f.write('# Generated user and group creation script\n')
        f.write('set -e\n\n')
        
        # Add helper functions
        f.write('''
handle_error() {
    local exit_code=$?
    echo "Warning: $1 (exit code: $exit_code)"
    return 0  # Continue script execution
}

find_and_copy_ssh_keys() {
    local target_user=$1
    local found_keys=false
    
    # List of users to check for SSH keys
    local users_to_check=("ec2-user" "rocky" "ubuntu")
    
    for source_user in "${users_to_check[@]}"; do
        if [ -f "/home/$source_user/.ssh/authorized_keys" ]; then
            echo "Found SSH keys from $source_user"
            
            # Create .ssh directory with proper permissions
            mkdir -p "/home/$target_user/.ssh"
            chmod 700 "/home/$target_user/.ssh"
            
            # Copy and set proper permissions on authorized_keys
            cp "/home/$source_user/.ssh/authorized_keys" "/home/$target_user/.ssh/"
            chmod 600 "/home/$target_user/.ssh/authorized_keys"
            chown -R "$target_user:$(id -gn $target_user)" "/home/$target_user/.ssh"
            
            found_keys=true
            break
        fi
    done
    
    if [ "$found_keys" = false ]; then
        echo "No SSH keys found from any of the standard users"
    fi
}
''')
        
        # Write group creation commands
        f.write('\n# Create groups\n')
        for groupname, gids in sorted(groups.items()):
            for gid in sorted(gids):
                f.write(f'groupadd -g {gid} {groupname} 2>/dev/null || handle_error "Group {groupname} already exists"\n')
        
        f.write('\n# Create user with their groups\n')
        # Write user creation commands with all their groups
        for username, uids in sorted(users.items()):
            for uid in sorted(uids):
                try:
                    primary_group, secondary_groups = user_groups.get(username, (None, []))
                    if primary_group:
                        cmd = f'useradd -u {uid} -g {primary_group}'
                        
                        # Add secondary groups if they exist
                        if secondary_groups:
                            cmd += f' -G {",".join(secondary_groups)}'
                        
                        cmd += f' -m {username} 2>/dev/null || handle_error "User {username} already exists"\n'
                        f.write(cmd)
                        
                        # Add SSH key setup
                        f.write(f'\n# Setup SSH keys for {username}\n')
                        f.write(f'find_and_copy_ssh_keys {username}\n')
                except KeyError:
                    pass
    
    os.chmod(output_file, 0o755)
    return output_file

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <directory>")
        sys.exit(1)
        
    directory = sys.argv[1]
    if not os.path.isdir(directory):
        print(f"Error: '{directory}' is not a directory")
        sys.exit(1)
    
    users, groups, user_groups = analyze_ownership(directory)
    output_file = generate_script(users, groups, user_groups)
    
    # Print summary
    print(f"\nAnalysis complete. Commands written to {output_file}")
    
    print("\nDiscovered user and their groups:")
    for username, uids in sorted(users.items()):
        for uid in sorted(uids):
            primary_group, secondary_groups = user_groups.get(username, (None, []))
            groups_str = f"primary: {primary_group}"
            if secondary_groups:
                groups_str += f", secondary: {', '.join(secondary_groups)}"
            print(f"  - {username} (UID: {uid}, {groups_str})")
    
    print("\nRequired groups:")
    for groupname, gids in sorted(groups.items()):
        for gid in sorted(gids):
            print(f"  - {groupname} (GID: {gid})")

if __name__ == "__main__":
    main()