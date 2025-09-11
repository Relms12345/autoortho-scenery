#!/bin/sh

# A script to find lines in a second file that are not present in a first file.

# --- Sanity Checks ---
# Ensure three arguments (file1, file2, output_file) are provided.
if [ "$#" -ne 3 ]; then
    echo "❌ Incorrect number of arguments."
    echo "Usage: ./compare_files.sh <first_file.txt> <second_file.txt> <output_file.txt>"
    exit 1
fi

# Assign arguments to variables for clarity
file1="$1"
file2="$2"
output_file="$3"

# Check if the input files exist and are readable.
if [ ! -f "$file1" ]; then
    echo "Error: Base file '$file1' not found."
    exit 1
fi

if [ ! -f "$file2" ]; then
    echo "Error: Comparison file '$file2' not found."
    exit 1
fi


# --- Core Logic ---
# Use grep to find unique lines.
# -v : Selects non-matching lines.
# -x : Matches the entire line exactly.
# -f : Obtains patterns from the first file.
# The command reads patterns from file1 and prints any line from file2
# that does NOT match any of those patterns.
echo "⚙️  Comparing files..."
grep -v -x -f "$file1" "$file2" > "$output_file"

# Count the number of unique lines found
line_count=$(wc -l < "$output_file")

echo "✅ Done! Found $line_count unique line(s)."
echo "Results have been saved to '$output_file'."
