#!/bin/bash

set -euo pipefail

while getopts hap opt
do
	case $opt in
		h)
			echo "Usage: git-fixup.sh [-h] [-a] [-p]" >&2
			exit 1
			;;
		a)
			git add -u
			;;
		p)
			git add -p
			;;
	esac
done
if git diff --cached --quiet; then
	git status
	exit 1
fi

filename=
declare -a ranges
ranges=()

INDEX_COMMIT=$(git commit-tree -p HEAD $(git write-tree) < /dev/null)
# echo "Index commit: '$INDEX_COMMIT'"

best_commit=""
best_time=0
best_summary=""

handle_file() {
	filename="$1"
	shift
	# echo "Filename=$filename"
	# echo "Args=${#@}"
	# echo "Args=$@"
	commit=""
	summary=""
	committer_time=""
	while read line
	do
		set -- $line
		if [ -z "$commit" ]; then
			commit=$1
			summary=""
			committer_time=""
			continue
		fi
		if [ "$1" == "committer-time" ]; then
			committer_time="$2"
		fi
		if [ "$1" == "summary" ]; then
			summary="${line#summary }"
		fi
		if [ "$1" == "filename" ]; then
			if [ -n "$committer_time" ] && [ "$committer_time" -gt "$best_time" ]; then
				best_commit="$commit"
				best_time="$committer_time"
				best_summary="$summary"
			fi
			commit=
			continue
		fi
	done < <(git blame --incremental "$@" $INDEX_COMMIT^ -- "$filename")
}

while read line
do
	case "$line" in
		:*)
			if [ -n "$filename" -a ${#ranges[@]} -gt 0 ]; then
				handle_file "$filename" "${ranges[@]}"
			fi
			set -- $line
			filename="$6"
			ranges=()
			;;
		@@\ *)
			set -- $line
			case "$2" in
				-[0-9]*,0)
					;;
				-*,*)
					ab="${2#-}"
					a="${ab#*,}"
					b="${ab%,*}"
					ranges+=(-L "$a,+$b")
					;;
				-*)
					ranges+=(-L "${2#-},+1")
					;;
			esac
			;;
	esac
done < <(git diff --cached --raw -U0)
if [ -n "$filename" -a ${#ranges[@]} -gt 0 ]; then
	handle_file "$filename" "${ranges[@]}"
fi
# echo "Best commit: '$best_commit'"
git commit -m "fixup! $best_commit" -m "Committed using git-fixup.sh"
