#!/bin/bash

# Function to generate a random 8-digit number
generate_id() {
    echo $((RANDOM%100000000))
}

# Function to process a single file
process_file() {
    local file="$1"              # Input file path
    local output_dir="$2"        # Output directory path
    local relative_path="${file#$directory}"  # Relative path of file from input directory
    local output_path="$output_dir$relative_path"  # Output path for the processed file
    local error_log="$output_path/error.log"  # Error log path
    local progress_file="$output_path/progress.txt"  # Progress file path
    local line_count=$(wc -l < "$file")  # Total number of lines in the file
    local current_line=0  # Current line being processed
    
    # Create directory structure if it doesn't exist
    mkdir -p "$output_path"

    # Check if progress file exists and read the last processed line
    if [[ -f "$progress_file" ]]; then
        current_line=$(cat "$progress_file")
    fi
    
    # Get the total number of lines in the terminal window
    local total_lines=$(tput lines)
    
    # Loop through each line in the file
    while IFS= read -r line; do
        current_line=$((current_line+1))  # Increment the current line number
        
        # Calculate the line number to display at the bottom
        local bottom_line=$((total_lines - 1))
        
        # Move cursor to the bottom line and print the current line number
        tput cup $bottom_line 0
        echo "Processing $file: $current_line/$line_count"
        
        # Check for special characters in the email field excluding ', ., and -
problematic_char=$(echo "$line" | grep -oE '[!#$%&*+=~()<>,;\"\|ç'\'']' | grep -v "[.@:-\]" | head -n1)

        if [[ -n "$problematic_char" ]]; then
            echo "Skipped line $current_line in file $file due to special character $problematic_char in the email field: $line"
            continue
        fi
        
        # Parse email and password from line
        email=$(echo "$line" | cut -d ':' -f 1)
        password=$(echo "$line" | cut -d ':' -f 2)
        
         if [[ "$email" =~ [^[:space:]]\ +[^[:space:]] ]]; then
            echo "Skipped line $current_line in file $file due to spaces in the middle of the email field: $line (Email: $email)"
            continue
        fi
        
        # Check for spaces in the middle of the password field
        if [[ "$password" =~ [^[:space:]]\ +[^[:space:]] ]]; then
            echo "Skipped line $current_line in file $file due to spaces in the middle of the password field: $line (Password: $password)"
            continue
        fi
        
        # Determine if it's an email or username
        if [[ "$email" == *@* ]]; then
            id=$(generate_id)
            json="{\"id\": $id, \"email\": \"$email\", \"password\": \"$password\"}"
        else
            id=$(generate_id)
            json="{\"id\": $id, \"username\": \"$email\", \"password\": \"$password\"}"
        fi
        
        # Output JSON object to a file without extension
        filename=$(basename "$file")
        filename="${filename%.*}" # Remove extension
        echo "$json" >> "$output_path/$filename"
        
        # Update progress
        echo "$current_line" > "$progress_file"
    done < "$file"
    
    # Handle errors
    if [[ $? -ne 0 ]]; then
        echo "Error processing file $file" >> "$error_log"
    fi
}

# Main script starts here
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

directory="$1"  # Input directory path

# Create output directory if it doesn't exist
output_dir="$HOME/COMB"

# Find and process all files recursively
find "$directory" -type f -print0 | while IFS= read -r -d '' file; do
    process_file "$file" "$output_dir"
done

echo "Processing complete."

