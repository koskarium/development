from pathlib import Path
import xarray as xr
import pandas as pd
import os
import cdsapi
import urllib3

# =========================
# SETUP PATHS
# =========================

current_parent_dir = Path(__file__).resolve().parent

era5_folder = current_parent_dir / "Era5"
era5_temp_folder = era5_folder / "temp"
era5_cities_folder = era5_folder / "Cities"

era5_temp_folder.mkdir(parents=True, exist_ok=True)
era5_cities_folder.mkdir(parents=True, exist_ok=True)

# =========================
# CDS CONFIG
# =========================

config_file = current_parent_dir / ".cdsapirc"

if not config_file.exists():
    raise FileNotFoundError(".cdsapirc not found")

os.environ["CDSAPI_RC"] = str(config_file)

urllib3.disable_warnings()

# =========================
# LOAD CITIES (FIXED)
# =========================

cities_file = current_parent_dir / "cities.csv"

if not cities_file.exists():
    raise FileNotFoundError(f"Missing file: {cities_file}")

cities = pd.read_csv(cities_file)

# normalize column names
cities.columns = [c.strip().lower() for c in cities.columns]

required_cols = {"city", "latitude", "longitude"}
if not required_cols.issubset(set(cities.columns)):
    raise ValueError(f"cities.csv must contain: {required_cols}")

cities["city"] = cities["city"].astype(str).str.strip()
cities["latitude"] = cities["latitude"].astype(float)
cities["longitude"] = cities["longitude"].astype(float)

# =========================
# ERA5 CONFIG
# =========================

dataset = "reanalysis-era5-pressure-levels"
variables = ["temperature"]

start_year = 1940
end_year = 2025
years = range(start_year, end_year + 1)

months = [f"{m:02d}" for m in range(1, 13)]
days = [f"{d:02d}" for d in range(1, 32)]
hours = [f"{h:02d}:00" for h in range(24)]

client = cdsapi.Client()

# =========================
# DOWNLOAD FUNCTION
# =========================

def download_year(year):
    print(f"\n[DOWNLOAD] Year {year}")

    out_file = era5_temp_folder / f"era5_{year}.nc"

    if out_file.exists():
        print("Already exists, skipping")
        return out_file

    request = {
        "product_type": ["reanalysis"],
        "variable": variables,
        "year": [str(year)],
        "month": months,
        "day": days,
        "time": hours,
        "data_format": "netcdf",
    }

    try:
        client.retrieve(dataset, request).download(str(out_file))
        return out_file
    except Exception as e:
        print(f"Download failed {year}: {e}")
        return None

# =========================
# PROCESS FUNCTION
# =========================

def process_nc(nc_file):
    print(f"[PROCESS] {nc_file.name}")

    ds = xr.open_dataset(nc_file)

    if "valid_time" in ds.coords:
        ds = ds.rename({"valid_time": "time"})

    for _, row in cities.iterrows():

        city = row["city"]
        lat = float(row["latitude"])
        lon = float(row["longitude"])

        city_clean = city.replace(" ", "")

        if lon < 0:
            lon = 360 + lon

        try:
            city_data = ds.interp(latitude=lat, longitude=lon)
        except Exception as e:
            print(f"Skip {city}: {e}")
            continue

        df = city_data["t2m"].to_dataframe().reset_index()

        df["year"] = pd.to_datetime(df["time"]).dt.year
        df["month"] = pd.to_datetime(df["time"]).dt.month
        df["day"] = pd.to_datetime(df["time"]).dt.day
        df["hour"] = pd.to_datetime(df["time"]).dt.hour

        df = df[["year", "month", "day", "hour", "t2m"]]

        for y, g in df.groupby("year"):
            out_file = era5_cities_folder / f"ERA_{city_clean}_{y}.csv"

            if not out_file.exists():
                g.to_csv(out_file, index=False)
                print("Saved", out_file.name)

# =========================
# MAIN PIPELINE
# =========================

def run_pipeline():
    for year in years:
        nc_file = download_year(year)

        if nc_file is not None:
            process_nc(nc_file)

# =========================
# ENTRY POINT
# =========================

if __name__ == "__main__":
    run_pipeline()