#!/usr/bin/bash

# Arrays to keep track of successes and failures
successes=()
failures=()

# Loop through all subdirectories
for dir in */ ; do
    if [ -d "$dir/.git" ]; then
        echo "Processing $dir"
        (
            cd "$dir" || exit 1

            echo "Running git fetch in $dir..."
            if ! git fetch; then
                echo "git fetch failed in $dir"
                exit 1
            fi

            echo "Running git pull in $dir..."
            if ! git pull; then
                echo "git pull failed in $dir"
                exit 1
            fi

            # If this repo has submodules, update them to the pinned commits
            if [ -f .gitmodules ]; then
                echo "Updating submodules in $dir..."
                if ! git submodule sync --recursive; then
                    echo "git submodule sync failed in $dir"
                    exit 1
                fi
                if ! git submodule update --init --recursive; then
                    echo "git submodule update failed in $dir"
                    exit 1
                fi
            fi
        )
        # Capture exit code from subshell
        if [ $? -ne 0 ]; then
            failures+=("$dir")
        else
            successes+=("$dir")
        fi
    else
        echo "Skipping $dir (not a git repository)"
    fi
done

echo
echo "===================="
if [ ${#successes[@]} -gt 0 ]; then
    echo "✅ Successes:"
    for s in "${successes[@]}"; do
        echo "  - $s"
    done
fi

if [ ${#failures[@]} -gt 0 ]; then
    echo
    echo "❌ Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
else
    echo
    echo "🎉 No failures — all repositories updated successfully."
fi

