#!/bin/sh

# A script to output lines from the first file that are not present in the second file.

# --- Check for the correct number of arguments ---
if [ "$#" -ne 3 ]; then
  echo "❌ Error: Invalid number of arguments."
  echo "Usage: $0 <source_file> <exclusion_file> <output_file>"
  exit 1
fi

SOURCE_FILE="$1"
EXCLUSION_FILE="$2"
OUTPUT_FILE="$3"

# --- Check if input files exist ---
if [ ! -f "$SOURCE_FILE" ]; then
  echo "❌ Error: Source file '$SOURCE_FILE' not found."
  exit 1
fi

if [ ! -f "$EXCLUSION_FILE" ]; then
  echo "❌ Error: Exclusion file '$EXCLUSION_FILE' not found."
  exit 1
fi

# --- Compare files and create the output ---
echo "⚙️  Processing..."
grep -v -x -f "$EXCLUSION_FILE" "$SOURCE_FILE" > "$OUTPUT_FILE"

echo "✅ Done! Output saved to '$OUTPUT_FILE'."
