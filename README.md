# Web Scraping and Data Extraction Assignment

This repository contains two main programs for web scraping and data extraction:

## 1. OLX Car Cover Scraper (`olx_car_cover_scraper.py`)

A Python script that scrapes car cover listings from OLX India and saves the results in both JSON and CSV formats.

### Features:
- Scrapes car cover listings from `www.olx.in/items/q-car-cover`
- Extracts title, price, location, date, description, and link for each listing
- Saves data in both JSON and CSV formats
- Includes error handling and respectful scraping delays
- Provides detailed logging and summary statistics

### Usage:
```bash
# Install dependencies
pip install -r requirements.txt

# Run the scraper
python olx_car_cover_scraper.py
```

### Output Files:
- `olx_car_covers.json` - JSON format with all scraped listings
- `olx_car_covers.csv` - CSV format for easy analysis

## 2. AMFI Mutual Fund Data Extractor (`extract_mutual_fund_data.sh`)

A shell script that extracts mutual fund scheme names and asset values from AMFI NAV data.

### Features:
- Downloads NAV data from `https://www.amfiindia.com/spages/NAVAll.txt`
- Extracts scheme codes, names, NAV values, and dates
- Outputs data in both TSV and JSON formats
- Includes data validation and error handling
- Provides colored output and progress indicators

### Usage:
```bash
# On Linux/macOS
./extract_mutual_fund_data.sh

# On Windows (using Git Bash or WSL)
bash extract_mutual_fund_data.sh
```

### Output Files:
- `mutual_fund_data.tsv` - Tab-separated values format
- `mutual_fund_data.json` - JSON format with metadata

## Data Format Recommendation

**Both TSV and JSON formats are provided**, but for different use cases:

- **TSV Format**: Best for data analysis, Excel import, and database operations
- **JSON Format**: Best for web applications, APIs, and programmatic processing

The JSON format includes additional metadata like extraction timestamp and source URL, making it more suitable for data provenance and API responses.

## Dependencies

### Python Requirements:
- requests >= 2.25.1
- beautifulsoup4 >= 4.9.3
- lxml >= 4.6.3

### Shell Script Requirements:
- bash
- curl
- awk
- sed (standard Unix tools)

## Notes

1. The OLX scraper includes respectful delays to avoid overwhelming the server
2. Asset values in the mutual fund data are calculated estimates
3. Both scripts include comprehensive error handling
4. The shell script works on Linux, macOS, and Windows (with Git Bash/WSL)

## License

This project is for educational purposes only. Please respect the terms of service of the websites being scraped. 