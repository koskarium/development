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
# We find the working dir to be used to generate the subfolders
curernt_parent_dir = os.getcwd();

# Create main folder
era5_folder = Path(curernt_parent_dir) / "Era5"
era5_folder.mkdir(exist_ok=True)

# Create subfolders
era5_temp_folder = era5_folder / "temp"
era5_data_folder = era5_folder / "Data"
(era5_temp_folder).mkdir(exist_ok=True)
(era5_data_folder).mkdir(exist_ok=True)

#########################
###### CODE BEGINS ######
#########################
# Config file
config_file = './.cdsapirc'

if os.path.exists(config_file):
	os.environ['CDSAPI_RC'] = config_file
else:
	print('Error, config_file not found')
	exit()
### ERA5 datset that we are looking for 

# dataset = "reanalysis-era5-single-levels-timeseries"
# request = {
#     "variable": ["2m_temperature"],
#     "location": {"longitude": -119.5, "latitude": 36},
#     "date": ["1940-01-01/1945-01-04"],
#     "time": "12:00",
#     "data_format": "netcdf"
# }

dataset = "reanalysis-era5-single-levels"
request = {
    "product_type": ["reanalysis"],
    "variable": ["2m_temperature"],
    "year": ["2025"],
    "month": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12"
    ],
    "day": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12",
        "13", "14", "15",
        "16", "17", "18",
        "19", "20", "21",
        "22", "23", "24",
        "25", "26", "27",
        "28", "29", "30",
        "31"
    ],
    "time": [
        "00:00", "01:00", "02:00",
        "03:00", "04:00", "05:00",
        "06:00", "07:00", "08:00",
        "09:00", "10:00", "11:00",
        "12:00", "13:00", "14:00",
        "15:00", "16:00", "17:00",
        "18:00", "19:00", "20:00",
        "21:00", "22:00", "23:00"
    ],
    "data_format": "netcdf",
    "download_format": "zip",
    "area": [35, -120, 33, -111]
}

client = cdsapi.Client()

########################
###### Data Pull #######
########################
client = cdsapi.Client()
os.chdir(era5_temp_folder)
client.retrieve(dataset, request).download()


########################
#### ZIP Extraction ####
########################
# We list all the files in the temp that are zip 
current_directory_files = os.listdir();
current_zip_files = [];

for file in current_directory_files:
	if file.endswith('.zip'):
		current_zip_files.append(file);

print(f"We found {len(current_zip_files)} file and we will now search to see if there is a NC file");

for files in current_zip_files:
	print(f"Processing {files}")
	nc_files_in_zip = [];
	try:
		with ZF.ZipFile(files,'r') as current_zip: 
			for inner_file in current_zip.namelist():
				if inner_file.endswith('.nc'):
					nc_files_in_zip.append(inner_file);
			if not nc_files_in_zip:
				print(f"--No .nc files found")
			else:
				for nc_to_extract in nc_files_in_zip:
					if os.path.exists(nc_to_extract):
						print(f"----File already exist and so we SKIP")
					else:
						print(f"--We will extract {nc_to_extract}")
						current_zip.extract(nc_to_extract,era5_data_folder)
	except ZF.BadZipFile:
		print(f"--We could NOT OPEN")
	except Exception as e:
		print(f"--We found an exception {e}")