#!/usr/bin/env bash


# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

# Define the input and output file paths
input_file="$1"
output_file="$2"

# Define the Unicode to ASCII mapping
declare -A unicode_to_ascii=(
    [\u2500]="-"    # Box drawing horizontal line to ASCII hyphen
    [\u2502]="|"    # Box drawing vertical line to ASCII pipe
    [\u250C]="+"    # Box drawing top left corner to ASCII plus
    [\u2510]="+"    # Box drawing top right corner to ASCII plus
    [\u2514]="+"    # Box drawing bottom left corner to ASCII plus
    [\u2518]="+"    # Box drawing bottom right corner to ASCII plus
    # Add more mappings as needed
)

# Define the Unicode to ASCII mapping as hexadecimal values
declare -A unicode_to_ascii=(
    # Box drawing horizontal line to ASCII hyphen
    [$'\xE2\x94\x80']="-"
    # Box drawing vertical line to ASCII pipe
    [$'\xE2\x94\x82']="|"
    # Box drawing top left corner to ASCII plus
    [$'\xE2\x94\x8C']="+"
    # Box drawing top right corner to ASCII plus
    [$'\xE2\x94\x90']="+"
    # Box drawing bottom left corner to ASCII plus
    [$'\xE2\x94\x94']="+"
    # Box drawing bottom right corner to ASCII plus
    [$'\xE2\x94\x98']="+"
    # Box drawing left vertical to right line to ASCII plus
    [$'\xE2\x94\x9C']="+"
    # Add more mappings as needed
)

# Function to replace Unicode characters with ASCII equivalents
replace_unicode_with_ascii() {
    local input_file=$1
    local output_file=$2
    
    # Create a temporary file for the replacements
    temp_file=$(mktemp)
    
    # Copy the input file to the temporary file
    cp "$input_file" "$temp_file"
    
    # Perform the replacements
    for unicode_char in "${!unicode_to_ascii[@]}"; do
        ascii_char="${unicode_to_ascii[$unicode_char]}"
        LC_ALL=C sed -i -e "s/$unicode_char/$ascii_char/g" "$temp_file"
    done
    
    # Move the temporary file to the output file
    mv "$temp_file" "$output_file"
}

# Call the function with the input and output files
replace_unicode_with_ascii "$input_file" "$output_file"

echo "Replacements complete. Output written to $output_file"

