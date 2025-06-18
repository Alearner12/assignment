#!/usr/bin/env python3
"""
OLX Car Cover Scraper
Scrapes car cover listings from OLX India and saves results to a file
"""

import requests
from bs4 import BeautifulSoup
import json
import csv
import time
import re
from urllib.parse import urljoin
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class OLXCarCoverScraper:
    def __init__(self):
        self.base_url = "https://www.olx.in"
        self.search_url = "https://www.olx.in/items/q-car-cover"
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
        }
        self.session = requests.Session()
        self.session.headers.update(self.headers)

    def get_page_content(self, url):
        """Fetch page content with error handling"""
        try:
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            return response.content
        except requests.RequestException as e:
            logger.error(f"Error fetching {url}: {e}")
            return None

    def parse_listing(self, listing_element):
        """Parse individual listing element"""
        try:
            listing_data = {}
            
            # Title
            title_elem = listing_element.find('span', {'data-aut-id': 'itemTitle'})
            listing_data['title'] = title_elem.get_text(strip=True) if title_elem else 'N/A'
            
            # Price
            price_elem = listing_element.find('span', {'data-aut-id': 'itemPrice'})
            listing_data['price'] = price_elem.get_text(strip=True) if price_elem else 'N/A'
            
            # Location
            location_elem = listing_element.find('span', {'data-aut-id': 'item-location'})
            listing_data['location'] = location_elem.get_text(strip=True) if location_elem else 'N/A'
            
            # Link
            link_elem = listing_element.find('a', href=True)
            if link_elem:
                listing_data['link'] = urljoin(self.base_url, link_elem['href'])
            else:
                listing_data['link'] = 'N/A'
            
            # Date
            date_elem = listing_element.find('span', {'data-aut-id': 'itemDate'})
            listing_data['date'] = date_elem.get_text(strip=True) if date_elem else 'N/A'
            
            # Description (if available)
            desc_elem = listing_element.find('span', {'data-aut-id': 'itemDescription'})
            listing_data['description'] = desc_elem.get_text(strip=True) if desc_elem else 'N/A'
            
            return listing_data
        except Exception as e:
            logger.error(f"Error parsing listing: {e}")
            return None

    def scrape_listings(self, max_pages=3):
        """Scrape car cover listings from OLX"""
        all_listings = []
        
        for page in range(1, max_pages + 1):
            logger.info(f"Scraping page {page}...")
            
            if page == 1:
                url = self.search_url
            else:
                url = f"{self.search_url}?page={page}"
            
            content = self.get_page_content(url)
            if not content:
                logger.warning(f"Failed to fetch page {page}")
                continue
            
            soup = BeautifulSoup(content, 'html.parser')
            
            # Find listing containers (OLX structure may vary)
            listings = soup.find_all('div', {'data-aut-id': 'itemBox'})
            
            if not listings:
                # Try alternative selectors
                listings = soup.find_all('div', class_=re.compile(r'.*item.*', re.I))
                
            if not listings:
                logger.warning(f"No listings found on page {page}")
                break
            
            logger.info(f"Found {len(listings)} listings on page {page}")
            
            for listing in listings:
                parsed_listing = self.parse_listing(listing)
                if parsed_listing and parsed_listing['title'] != 'N/A':
                    all_listings.append(parsed_listing)
            
            # Be respectful with delays
            time.sleep(2)
        
        return all_listings

    def save_to_json(self, listings, filename='olx_car_covers.json'):
        """Save listings to JSON file"""
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(listings, f, indent=2, ensure_ascii=False)
            logger.info(f"Saved {len(listings)} listings to {filename}")
        except Exception as e:
            logger.error(f"Error saving to JSON: {e}")

    def save_to_csv(self, listings, filename='olx_car_covers.csv'):
        """Save listings to CSV file"""
        try:
            if not listings:
                logger.warning("No listings to save")
                return
            
            fieldnames = listings[0].keys()
            with open(filename, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(listings)
            logger.info(f"Saved {len(listings)} listings to {filename}")
        except Exception as e:
            logger.error(f"Error saving to CSV: {e}")

def main():
    """Main function to run the scraper"""
    logger.info("Starting OLX Car Cover Scraper...")
    
    scraper = OLXCarCoverScraper()
    
    try:
        # Scrape listings
        listings = scraper.scrape_listings(max_pages=3)
        
        if listings:
            logger.info(f"Successfully scraped {len(listings)} listings")
            
            # Save in multiple formats
            scraper.save_to_json(listings, 'olx_car_covers.json')
            scraper.save_to_csv(listings, 'olx_car_covers.csv')
            
            # Print summary
            print(f"\n=== SCRAPING SUMMARY ===")
            print(f"Total listings found: {len(listings)}")
            print(f"Files saved: olx_car_covers.json, olx_car_covers.csv")
            
            # Print first few listings
            print(f"\n=== SAMPLE LISTINGS ===")
            for i, listing in enumerate(listings[:3]):
                print(f"\n{i+1}. {listing['title']}")
                print(f"   Price: {listing['price']}")
                print(f"   Location: {listing['location']}")
                print(f"   Date: {listing['date']}")
                print(f"   Link: {listing['link']}")
        else:
            logger.warning("No listings found")
            
    except Exception as e:
        logger.error(f"Error in main execution: {e}")

if __name__ == "__main__":
    main() 