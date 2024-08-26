#!/bin/bash

# Define input and output directories
input_dir="./meetings/video"
output_dir="./meetings/audio"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Function to handle SIGINT signal (Ctrl+C)
handle_sigint() {
    echo "Script interrupted. Terminating ffmpeg and exiting..."
    pkill -P $$ ffmpeg # Terminate ffmpeg processes spawned by this script
    exit 1
}

# Register the SIGINT signal handler
trap handle_sigint SIGINT

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed. Please install ffmpeg and try again."
    exit 1
fi

# Get total number of video files
total_files=$(find "$input_dir" -type f \( -name "*.mp4" -o -name "*.avi" -o -name "*.mov" -o -name "*.mkv" \) | wc -l)
processed_files=0

# Process video files
find "$input_dir" -type f \( -name "*.mp4" -o -name "*.avi" -o -name "*.mov" -o -name "*.mkv" \) -print0 | while IFS= read -r -d '' video_file; do
    # Generate output file name
    rel_path=${video_file#$input_dir/}
    output_file="$output_dir/${rel_path%.*}.mp3"
    
    # Create subdirectories in output_dir if necessary
    mkdir -p "$(dirname "$output_file")"
    
    if [ -e "$output_file" ]; then
        echo "Skipping: $output_file (already exists)"
    else
        echo "Processing: $video_file"
        ffmpeg -i "$video_file" -vn -acodec libmp3lame -ar 44100 -ac 2 -b:a 128k "$output_file" 2>/dev/null
        echo "Extracted audio: $output_file"
    fi
    
    # Update progress
    processed_files=$((processed_files + 1))
    progress=$((processed_files * 100 / total_files))
    echo "Progress: $progress% ($processed_files/$total_files)"
done

echo "All video files processed."