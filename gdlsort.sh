#!/bin/bash

# Define the old and new URLs as readonly associative arrays for clarity
declare -Ar URL_MAP=(
  ["https://www.abc.com"]="https://www.newabc.com"
  ["https://www.xyz.com"]="https://www.newxyz.com"
)

# Define usage function
usage() {
  printf "Usage: %s -i INPUT_FILE [OPTIONS]\n" "$0"
  printf "Description: This script reads an input file, removes 'www.' from URLs, changes 'http://' to 'https://', replaces old URLs with new URLs based on an associative array, finds URLs that end with a number or a number and a /, copies them to a new row with a new number between 1-20, removes empty lines, and saves the result to a new file.\n"
  printf "Options:\n"
  printf "  -i INPUT_FILE   Set the input file name\n"
  printf "  -o OUTPUT_FILE  Set the output file name (default: <input_filename>_TIMESTAMP.txt)\n"
  printf "  -n              Perform a dry run (print commands without executing)\n"
  printf "  -h              Show this help message\n"
  exit 1
}

# Parse command line arguments using getopts
while getopts "i:o:nh" opt; do
  case "$opt" in
    i) readonly INPUT_FILE="$OPTARG" ;;
    o) readonly OUTPUT_FILE="$OPTARG" ;;
    n) readonly DRY_RUN=true ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Print help message if no input file is provided
if [[ -z "$INPUT_FILE" ]]; then
  usage
fi

# Set default output file if none is specified
if [[ -z "$OUTPUT_FILE" ]]; then
  readonly TIMESTAMP=$(date +"%Y%m%d%H%M%S")
  OUTPUT_FILE="${INPUT_FILE%.*}_$TIMESTAMP.txt"
fi

# Validate input file
if [[ ! -r "$INPUT_FILE" ]]; then
  printf "Error: input file '%s' cannot be read\n" "$INPUT_FILE" >&2
  exit 1
fi

# Remove "www." and change "http://" to "https://"
sed -e 's/^www\.//' -e 's/^http:/https:/' "$INPUT_FILE" > tmp.txt

# Replace old URLs with new URLs using the URL_MAP array
for old_url in "${!URL_MAP[@]}"; do
  new_url="${URL_MAP[$old_url]}"
  sed -i "s|$old_url|$new_url|g" tmp.txt
done

# Find URLs that end with a number or a number and a / and copy them to a new row with a new number between 1-20
while read -r line; do
  if [[ "$line" =~ [0-9]+/?$ ]]; then
    for i in {1..20}; do
      new_line=$(sed "s/[0-9]\+\/?$/${i}\//" <<< "$line")
      printf "%s\n" "$new_line"
    done
  else
    printf "%s\n" "$line"
  fi
done < "$INPUT_FILE"

# Remove empty lines from the output file and save the result to a new file
sed -i '/^$/d' "$OUTPUT_FILE"

# Count the number of rows in the input and output files
NUM_INPUT_ROWS=$(wc -l < "$INPUT_FILE")
NUM_OUTPUT_ROWS=$(wc -l < "$OUTPUT_FILE")

# Print the number of rows
echo "Input file contains $NUM_INPUT_ROWS unique rows."
echo "Output file contains $NUM_OUTPUT_ROWS unique rows."

# Print the location of the output file
echo "Output written to $OUTPUT_FILE"

# Clean up temporary file
rm tmp.txt
