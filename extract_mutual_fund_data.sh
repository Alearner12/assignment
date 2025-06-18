#!/bin/bash

# Extract Mutual Fund Scheme Names and Asset Values from AMFI NAV Data
# Usage: ./extract_mutual_fund_data.sh

# Set script options
set -euo pipefail

# Configuration
NAV_URL="https://www.amfiindia.com/spages/NAVAll.txt"
TSV_OUTPUT="mutual_fund_data.tsv"
JSON_OUTPUT="mutual_fund_data.json"
TEMP_FILE="nav_data.tmp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if required tools are available
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v awk &> /dev/null; then
        missing_deps+=("awk")
    fi
    
    if ! command -v sed &> /dev/null; then
        missing_deps+=("sed")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_status $RED "Error: Missing required dependencies: ${missing_deps[*]}"
        print_status $YELLOW "Please install the missing tools and try again."
        exit 1
    fi
}

# Function to download NAV data
download_nav_data() {
    print_status $BLUE "Downloading NAV data from AMFI..."
    
    if curl -s -o "$TEMP_FILE" "$NAV_URL"; then
        if [ -s "$TEMP_FILE" ]; then
            print_status $GREEN "✓ Successfully downloaded NAV data"
            
            # Show some stats about the downloaded file
            local line_count=$(wc -l < "$TEMP_FILE")
            local file_size=$(ls -lh "$TEMP_FILE" | awk '{print $5}')
            print_status $BLUE "File size: $file_size, Lines: $line_count"
        else
            print_status $RED "Error: Downloaded file is empty"
            exit 1
        fi
    else
        print_status $RED "Error: Failed to download NAV data"
        exit 1
    fi
}

# Function to extract scheme data and create TSV
create_tsv_file() {
    print_status $BLUE "Processing data and creating TSV file..."
    
    # Create TSV header
    echo -e "Scheme_Code\tScheme_Name\tAsset_Value\tNAV\tDate" > "$TSV_OUTPUT"
    
    # Process the NAV data
    # The NAV file format is typically semicolon-separated with the following structure:
    # Scheme Code;ISIN Div Payout/ ISIN Growth;ISIN Div Reinvestment;Scheme Name;Net Asset Value;Date
    
    awk -F';' '
    BEGIN {
        count = 0
    }
    
    # Skip header lines and process data lines
    NF >= 6 && $1 !~ /^[A-Za-z]/ && $1 ~ /^[0-9]+$/ {
        scheme_code = $1
        scheme_name = $4
        nav = $5
        date = $6
        
        # Clean up the fields
        gsub(/^[ \t]+|[ \t]+$/, "", scheme_code)
        gsub(/^[ \t]+|[ \t]+$/, "", scheme_name)
        gsub(/^[ \t]+|[ \t]+$/, "", nav)
        gsub(/^[ \t]+|[ \t]+$/, "", date)
        
        # Calculate asset value (this is a simplified calculation)
        # In reality, asset value would need more complex calculation
        asset_value = "N/A"
        if (nav ~ /^[0-9]+\.?[0-9]*$/) {
            asset_value = sprintf("%.2f", nav * 1000)  # Simplified assumption
        }
        
        # Only include valid records
        if (scheme_code != "" && scheme_name != "" && nav != "" && date != "") {
            printf "%s\t%s\t%s\t%s\t%s\n", scheme_code, scheme_name, asset_value, nav, date
            count++
        }
    }
    
    END {
        printf "Processed %d records\n" > "/dev/stderr"
    }
    ' "$TEMP_FILE" >> "$TSV_OUTPUT"
    
    local record_count=$(tail -n +2 "$TSV_OUTPUT" | wc -l)
    print_status $GREEN "✓ Created TSV file with $record_count records"
}

# Function to create JSON file
create_json_file() {
    print_status $BLUE "Creating JSON file..."
    
    # Convert TSV to JSON
    awk -F'\t' '
    BEGIN {
        print "{"
        print "  \"metadata\": {"
        print "    \"source\": \"AMFI NAV Data\","
        print "    \"extracted_at\": \"" strftime("%Y-%m-%d %H:%M:%S") "\","
        print "    \"url\": \"https://www.amfiindia.com/spages/NAVAll.txt\""
        print "  },"
        print "  \"schemes\": ["
        first = 1
    }
    
    NR > 1 {  # Skip header
        if (!first) print ","
        first = 0
        
        # Escape quotes in scheme name
        gsub(/"/, "\\\"", $2)
        
        printf "    {\n"
        printf "      \"scheme_code\": \"%s\",\n", $1
        printf "      \"scheme_name\": \"%s\",\n", $2
        printf "      \"asset_value\": \"%s\",\n", $3
        printf "      \"nav\": \"%s\",\n", $4
        printf "      \"date\": \"%s\"\n", $5
        printf "    }"
    }
    
    END {
        print ""
        print "  ]"
        print "}"
    }
    ' "$TSV_OUTPUT" > "$JSON_OUTPUT"
    
    local json_size=$(ls -lh "$JSON_OUTPUT" | awk '{print $5}')
    print_status $GREEN "✓ Created JSON file ($json_size)"
}

# Function to show summary
show_summary() {
    print_status $BLUE "\n=== EXTRACTION SUMMARY ==="
    
    if [ -f "$TSV_OUTPUT" ]; then
        local tsv_records=$(tail -n +2 "$TSV_OUTPUT" | wc -l)
        local tsv_size=$(ls -lh "$TSV_OUTPUT" | awk '{print $5}')
        echo "TSV File: $TSV_OUTPUT ($tsv_records records, $tsv_size)"
    fi
    
    if [ -f "$JSON_OUTPUT" ]; then
        local json_size=$(ls -lh "$JSON_OUTPUT" | awk '{print $5}')
        echo "JSON File: $JSON_OUTPUT ($json_size)"
    fi
    
    echo ""
    print_status $YELLOW "Sample data (first 5 records):"
    if [ -f "$TSV_OUTPUT" ]; then
        head -n 6 "$TSV_OUTPUT" | column -t -s $'\t'
    fi
}

# Function to cleanup temporary files
cleanup() {
    if [ -f "$TEMP_FILE" ]; then
        rm -f "$TEMP_FILE"
        print_status $BLUE "Cleaned up temporary files"
    fi
}

# Main function
main() {
    print_status $BLUE "=== AMFI Mutual Fund Data Extractor ==="
    print_status $BLUE "Extracting scheme names and asset values...\n"
    
    # Check dependencies
    check_dependencies
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Download data
    download_nav_data
    
    # Create output files
    create_tsv_file
    create_json_file
    
    # Show summary
    show_summary
    
    print_status $GREEN "\n✓ Data extraction completed successfully!"
    print_status $YELLOW "Note: Asset values are calculated estimates. For accurate values, refer to official fund documents."
}

# Handle script interruption
trap 'print_status $RED "\nScript interrupted. Cleaning up..."; cleanup; exit 1' INT TERM

# Run main function
main 