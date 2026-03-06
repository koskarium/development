# era5_stream_pipeline.py
from pathlib import Path
import xarray as xr
import pandas as pd
import os
import zipfile as ZF
import cdsapi

#########################
# Configuration
#########################
# Base directory (where script is run)
# current_parent_dir = Path.cwd() would not be it if running from a folder that is not the current location where the .py is at 
current_parent_dir = Path(__file__).resolve().parent

# Create main folder
era5_folder = current_parent_dir / "Era5"
era5_folder.mkdir(exist_ok=True, parents=True)

# Create subfolders
era5_temp_folder = era5_folder / "temp"
era5_data_folder = era5_folder / "Data"
era5_cities_folder = era5_folder / "Cities"
era5_post_folder = era5_folder / "Postprocess"

era5_temp_folder.mkdir(exist_ok=True, parents=True)
era5_data_folder.mkdir(exist_ok=True, parents=True)
era5_cities_folder.mkdir(exist_ok=True, parents=True)
era5_post_folder.mkdir(exist_ok=True, parents=True)

# Config file
config_file = current_parent_dir / ".cdsapirc"
if config_file.exists():
	os.environ['CDSAPI_RC'] = str(config_file)
else:
	print('Error, config_file not found')
	exit()

# Since we are using verify: 0 so we can pypass SSL verification
import urllib3
from urllib3.exceptions import InsecureRequestWarning
urllib3.disable_warnings(InsecureRequestWarning)

# Cities
cities_file = current_parent_dir / "cities.txt"
cities = pd.read_csv(cities_file, header=None, names=["city","latitude","longitude"], skiprows=1)
cities["latitude"] = cities["latitude"].astype(float)
cities["longitude"] = cities["longitude"].astype(float)
cities["city"] = cities["city"].str.strip()

# ERA5 Config
dataset = "reanalysis-era5-single-levels"
variables = ["2m_temperature"]
download_format = "unarchived"  # "zip" or "unarchived"

start_year = 1940
end_year = 2025
years_to_download = [y for y in range(start_year, end_year+1)]

months = [f"{m:02d}" for m in range(1,13)]
days = [f"{d:02d}" for d in range(1,32)]
hours = [f"{h:02d}:00" for h in range(24)]

client = cdsapi.Client()

#########################
# Helper: download and extract
#########################
def download_year(year):
    print(f"\nDownloading year {year}...")
    output_file = era5_temp_folder / f"era5_{year}.nc"
    
    if output_file.exists():
        print(f"{output_file.name} already exists. Skipping download.")
        return output_file
    
    request = {
        "product_type": ["reanalysis"],
        "variable": variables,
        "year": [str(year)],
        "month": months,
        "day": days,
        "time": hours,
        "data_format": "netcdf",
        "download_format": download_format
    }
    
    try:
        client.retrieve(dataset, request).download(str(output_file))
        print(f"Downloaded {output_file.name}")
        return output_file
    except Exception as e:
        print(f"Download failed for {year}: {e}")
        return None

def process_nc(nc_file):
    print(f"\nProcessing {nc_file.name}")
    ds = xr.open_dataset(nc_file)
    
    # Rename valid_time -> time
    if "valid_time" in ds.coords:
        ds = ds.rename({"valid_time":"time"})
    
    for _, row in cities.iterrows():
        city = row["city"]
        lat = row["latitude"]
        lon = row["longitude"]
        city_clean = city.replace(" ","")
        # Convert negative longitude to 0-360
        lon = lon if lon >= 0 else 360 + lon

        try:
            city_data = ds.interp(latitude=lat, longitude=lon, method="linear")
        except Exception as e:
            print(f"Skipping {city}: interpolation error {e}")
            continue

        df_city = city_data["t2m"].to_dataframe().reset_index()
        df_city["date"] = pd.to_datetime(df_city["time"]).dt.date
        df_city["hour"] = pd.to_datetime(df_city["time"]).dt.hour
        df_city["day"] = pd.to_datetime(df_city["time"]).dt.day
        df_city["month"] = pd.to_datetime(df_city["time"]).dt.month
        df_city["year"] = pd.to_datetime(df_city["time"]).dt.year
        df_city_out = df_city[["year","month","day","hour","t2m"]]

        for year_val, df_year in df_city_out.groupby("year"):
            output_csv = era5_cities_folder / f"ERA_{city_clean}_{year_val}.csv"
            if output_csv.exists():
                print(f"{output_csv.name} exists. Skipping.")
                continue
            df_year.to_csv(output_csv, index=False)
            print(f"Saved {output_csv.name}")
    
    # Remove NC after processing to save space
    # ds.close()
    # del ds
    # gc.collect()
    # nc_file.unlink()
    print(f"Deleted {nc_file.name} after processing.")

#########################
# Main loop: download + process with 2-year queue
#########################
queue_limit = 2
download_queue = []

for year in years_to_download:
    # Download the year
    nc_path = download_year(year)
    if nc_path is not None:
        download_queue.append(nc_path)
    
    # Process queue if it exceeds limit
    while len(download_queue) > queue_limit:
        to_process = download_queue.pop(0)
        process_nc(to_process)

# Process remaining in queue
for nc_file in download_queue:
    process_nc(nc_file)