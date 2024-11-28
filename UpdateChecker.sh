#!/usr/bin/bash

# realpath gets the path to this file, dirname removes the filename from the path.
script_dir="$(dirname "$(realpath "$0")")"

# Creates this config file if it doesn't exist.
if [[ ! -e "$script_dir/ImportantPackages.txt" ]]
then
    touch "$script_dir/ImportantPackages.txt"
fi

# --nocolor necessary due to characters that break the output on notification.
checkupdates --nocolor > "$script_dir/PackageList.txt"
auracle outdated --color=never >  "$script_dir/ForeignList.txt"


# get counts of package updates
full_update_count=$(wc -l < "$script_dir/PackageList.txt")

if [[ -s "$script_dir/ImportantPackages.txt" ]] # If file empty, then consider all packages important.
then
	important_update_count=$(grep -f "$script_dir/ImportantPackages.txt" "$script_dir/PackageList.txt" | wc -l)
else
	important_update_count=$(wc -l < "$script_dir/PackageList.txt")
fi

foreign_update_count=$(wc -l < "$script_dir/ForeignList.txt")


# Cut down file to just important packages here
if [[ -s "$script_dir/ImportantPackages.txt" ]]
then
	# hack to allow input to be output rather than using tmp file.
	cat "$script_dir/PackageList.txt" | grep -f "$script_dir/ImportantPackages.txt" | tee "$script_dir/PackageList.txt" >> /dev/null
fi


# Display notification using notify-send with counts and details from file.
if [[ "$important_update_count" -gt 0 ]]
then
	notify-send -a "Update Checker" -t 10000 "$important_update_count Important Package Updates Available" "$full_update_count packages total, important packages:\n$(cat "$script_dir/PackageList.txt")"
fi

if [[ "$foreign_update_count" -gt 0 ]]
then
	notify-send -a "Update Checker" -t 10000 "$foreign_update_count Foreign Packages out of date" "$(cat "$script_dir/ForeignList.txt")"
fi


# Check if mirrorlist file is old.
mirrorlist_age="$(( $(date +%s) - $(stat -c '%Y' /etc/pacman.d/mirrorlist) ))" # Use $(( 10 + 10 )) method of calculation

if [[ "$mirrorlist_age" -gt 2629743 ]]
then
	notify-send -a "Update Checker" -t 10000 "Mirrorlist is old" "Mirror list over a month old, consider refreshing with rate-mirrors"
fi


# Check for large pacman cache that could be cleared using paccache dryrun.


# IDEA: Can use paccache -d -v to get a file list, could then try sending that to du to get file size.
