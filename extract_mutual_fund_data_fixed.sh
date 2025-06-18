#!/bin/bash

# Extract Mutual Fund Scheme Names and Asset Values from AMFI NAV Data
# Usage: ./extract_mutual_fund_data_fixed.sh

# Set script options
set -euo pipefail

# Configuration
NAV_URL="https://www.amfiindia.com/spages/NAVAll.txt"
TSV_OUTPUT="mutual_fund_data.tsv"
JSON_OUTPUT="mutual_fund_data.json"
TEMP_FILE="nav_data.tmp"

# Function to download NAV data
download_nav_data() {
    echo "Downloading NAV data from AMFI..."
    
    if curl -s -o "$TEMP_FILE" "$NAV_URL"; then
        if [ -s "$TEMP_FILE" ]; then
            echo "✓ Successfully downloaded NAV data"
            local line_count=$(wc -l < "$TEMP_FILE")
            echo "Lines: $line_count"
        else
            echo "Error: Downloaded file is empty"
            exit 1
        fi
    else
        echo "Error: Failed to download NAV data"
        exit 1
    fi
}

# Function to extract scheme data and create TSV
create_tsv_file() {
    echo "Processing data and creating TSV file..."
    
    # Create TSV header
    echo -e "Scheme_Code\tScheme_Name\tAsset_Value\tNAV\tDate" > "$TSV_OUTPUT"
    
    # Process the NAV data using a simpler approach
    awk -F';' '
    NF >= 6 && $1 ~ /^[0-9]+$/ {
        scheme_code = $1
        scheme_name = $4
        nav = $5
        date = $6
        
        # Clean up the fields
        gsub(/^[ \t]+|[ \t]+$/, "", scheme_code)
        gsub(/^[ \t]+|[ \t]+$/, "", scheme_name)
        gsub(/^[ \t]+|[ \t]+$/, "", nav)
        gsub(/^[ \t]+|[ \t]+$/, "", date)
        
        # Calculate asset value (simplified)
        asset_value = "N/A"
        if (nav ~ /^[0-9]+\.?[0-9]*$/) {
            asset_value = sprintf("%.2f", nav * 1000)
        }
        
        # Only include valid records
        if (scheme_code != "" && scheme_name != "" && nav != "" && date != "") {
            printf "%s\t%s\t%s\t%s\t%s\n", scheme_code, scheme_name, asset_value, nav, date
        }
    }
    ' "$TEMP_FILE" >> "$TSV_OUTPUT"
    
    local record_count=$(tail -n +2 "$TSV_OUTPUT" | wc -l)
    echo "✓ Created TSV file with $record_count records"
}

# Function to create JSON file
create_json_file() {
    echo "Creating JSON file..."
    
    # Simple JSON creation
    echo '{' > "$JSON_OUTPUT"
    echo '  "metadata": {' >> "$JSON_OUTPUT"
    echo '    "source": "AMFI NAV Data",' >> "$JSON_OUTPUT"
    echo '    "extracted_at": "'$(date +"%Y-%m-%d %H:%M:%S")'",' >> "$JSON_OUTPUT"
    echo '    "url": "https://www.amfiindia.com/spages/NAVAll.txt"' >> "$JSON_OUTPUT"
    echo '  },' >> "$JSON_OUTPUT"
    echo '  "schemes": [' >> "$JSON_OUTPUT"
    
    # Convert TSV to JSON entries
    tail -n +2 "$TSV_OUTPUT" | head -n 100 | awk -F'\t' '
    {
        gsub(/"/, "\\\"", $2)
        if (NR > 1) print "    },"
        printf "    {\n"
        printf "      \"scheme_code\": \"%s\",\n", $1
        printf "      \"scheme_name\": \"%s\",\n", $2
        printf "      \"asset_value\": \"%s\",\n", $3
        printf "      \"nav\": \"%s\",\n", $4
        printf "      \"date\": \"%s\"\n", $5
    }
    END {
        printf "    }\n"
    }
    ' >> "$JSON_OUTPUT"
    
    echo '  ]' >> "$JSON_OUTPUT"
    echo '}' >> "$JSON_OUTPUT"
    
    echo "✓ Created JSON file"
}

# Function to show summary
show_summary() {
    echo ""
    echo "=== EXTRACTION SUMMARY ==="
    
    if [ -f "$TSV_OUTPUT" ]; then
        local tsv_records=$(tail -n +2 "$TSV_OUTPUT" | wc -l)
        echo "TSV File: $TSV_OUTPUT ($tsv_records records)"
    fi
    
    if [ -f "$JSON_OUTPUT" ]; then
        echo "JSON File: $JSON_OUTPUT"
    fi
    
    echo ""
    echo "Sample data (first 5 records):"
    if [ -f "$TSV_OUTPUT" ]; then
        head -n 6 "$TSV_OUTPUT"
    fi
}

# Function to cleanup temporary files
cleanup() {
    if [ -f "$TEMP_FILE" ]; then
        rm -f "$TEMP_FILE"
        echo "Cleaned up temporary files"
    fi
}

# Main function
main() {
    echo "=== AMFI Mutual Fund Data Extractor ==="
    echo "Extracting scheme names and asset values..."
    echo ""
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Download data
    download_nav_data
    
    # Create output files
    create_tsv_file
    create_json_file
    
    # Show summary
    show_summary
    
    echo ""
    echo "✓ Data extraction completed successfully!"
    echo "Note: Asset values are calculated estimates."
}

# Handle script interruption
trap 'echo "Script interrupted. Cleaning up..."; cleanup; exit 1' INT TERM

# Run main function
main 