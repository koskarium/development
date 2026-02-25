# https://cds.climate.copernicus.eu/how-to-api

import xarray as xr
import pandas as pd
import os
from pathlib import Path 
import zipfile as ZF
import dask
import fsspec
import cdsapi

#########################
###### Initialize  ######
#########################
# Base directory (where script is run)
# current_parent_dir = Path.cwd() would not be it if running from a folder that is not the current location where the .py is at 
current_parent_dir = Path(__file__).resolve().parent


# Create main folder
era5_folder = current_parent_dir / "Era5"
era5_folder.mkdir(exist_ok=True)

# Create subfolders
era5_temp_folder = era5_folder / "temp"
era5_data_folder = era5_folder / "Data"

era5_temp_folder.mkdir(exist_ok=True)
era5_data_folder.mkdir(exist_ok=True)


#########################
###### Config File ######
#########################
# Config file
config_file = current_parent_dir / ".cdsapirc"

if config_file.exists():
	os.environ['CDSAPI_RC'] = str(config_file)
else:
	print('Error, config_file not found')
	exit()
	
#########################
###### ERA5 Request #####
#########################

dataset = "reanalysis-era5-single-levels"
downloadformat = "unarchived" # "zip" or "unarchived"
variables = ["2m_temperature"]
#area = [35, -120, 33, -111]  # [North, West, South, East]

start_year = 2021
end_year = 2023  
# Build list of years
if start_year == end_year:
    years_to_download = [str(start_year)]
else:
    years_to_download = [str(y) for y in range(start_year, end_year + 1)]

print("Years to download:", years_to_download)

months = [f"{m:02d}" for m in range(1, 13)]
days = [f"{d:02d}" for d in range(1, 32)]
hours = [f"{h:02d}:00" for h in range(24)]

client = cdsapi.Client()

print(months)

########################
###### Data Pull #######
########################

for year in years_to_download:

    print(f"\n===== Processing year {year} =====")

    # Decide file extension based on format
    if downloadformat.lower() == "zip":
        output_file = era5_temp_folder / f"era5_{year}.zip"
        cds_download_format = "zip"

    elif downloadformat.lower() == "unarchived":
        output_file = era5_temp_folder / f"era5_{year}.nc"
        cds_download_format = "unarchived"   # CDS API keyword

    else:
        print("Invalid downloadformat. Use 'zip' or 'unarchived'.")
        continue

    # Skip if already downloaded
    if output_file.exists():
        print(f"{output_file.name} already exists. Skipping.")
        continue

    # Prepare request
    request = {
        "product_type": ["reanalysis"],
        "variable": variables,
        "year": [year],
        "month": months,
        "day": days,
        "time": hours,
        "data_format": "netcdf",
        "download_format": cds_download_format,
        # "area": area  # Uncomment if needed
    }

    # Download
    try:
        print(f"Downloading {year} as {downloadformat}...")
        client.retrieve(dataset, request).download(str(output_file))
        print(f"Saved -> {output_file.name}")

    except Exception as e:
        print(f"Download failed for {year}: {e}")
        continue


## Debugg
# print("Working path:", current_parent_dir)
# print("Temp folder path:", era5_temp_folder)
# print("Exists?", era5_temp_folder.exists())
# print("Files inside:", list(era5_temp_folder.iterdir()))


########################
#### ZIP Extraction ####
########################

# Process all files in temp folder
temp_files = list(era5_temp_folder.iterdir())
for file_path in temp_files:
    if file_path.suffix == ".zip":
        # Process zip
        print(f"\nProcessing ZIP: {file_path.name}")
        try:
            with ZF.ZipFile(file_path, 'r') as z:
                nc_files = [f for f in z.namelist() if f.endswith('.nc')]

                if not nc_files:
                    print("-- No .nc files in zip. Possibly embargoed. Skipping.")
                    continue

                for idx, ncfile in enumerate(nc_files):
                    extracted_path = era5_data_folder / ncfile

                    if extracted_path.exists():
                        print(f"---- {ncfile} already exists. Skipping extraction.")
                        continue

                    z.extract(ncfile, era5_data_folder)

                    # Rename extracted file
                    try:
                        year_in_name = file_path.stem.split("_")[1]
                    except IndexError:
                        year_in_name = "unknown_year"

                    variable_name = variables[idx] if idx < len(variables) else f"var{idx+1}"
                    new_name = f"ERA5_{year_in_name}_{variable_name}.nc"
                    new_path = era5_data_folder / new_name

                    extracted_path.rename(new_path)
                    print(f"---- Renamed {ncfile} -> {new_name}")

        except ZF.BadZipFile:
            print(f"-- Could not open zip: {file_path.name}")
        except Exception as e:
            print(f"-- Exception during extraction: {e}")

    elif file_path.suffix == ".nc":
        # Direct NetCDF file
        print(f"\nProcessing direct NC: {file_path.name}")
        try:
            # Determine year from file name
            try:
                year_in_name = file_path.stem.split("_")[1]
            except IndexError:
                year_in_name = "unknown_year"

            # Use variable from request (single variable assumed)
            variable_name = variables[0] if len(variables) == 1 else "var1"
            new_name = f"ERA5_{year_in_name}_{variable_name}.nc"
            new_path = era5_data_folder / new_name

            if new_path.exists():
                print(f"{new_name} already exists. Skipping.")
                continue

            file_path.rename(new_path)
            print(f"Moved and renamed -> {new_name}")

        except Exception as e:
            print(f"Error renaming {file_path.name}: {e}")

    else:
        print(f"Unknown file type: {file_path.name}")