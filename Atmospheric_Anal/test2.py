# interpolate_era5_cities.py
from pathlib import Path
import xarray as xr
import pandas as pd

#########################
# Folders and files
#########################
current_dir = Path(__file__).resolve().parent

era5_data_folder = current_dir / "Era5" / "Data"
cities_file = current_dir / "cities.txt"
output_folder = current_dir / "Era5" / "Cities"
output_folder.mkdir(exist_ok=True, parents=True)

#########################
# Load cities
#########################
# Expecting: city,latitude,longitude
cities = pd.read_csv(
    cities_file,
    header=None,
    names=["city","latitude","longitude"],
    skiprows=1  # skip header line if present
)
print("Cities loaded:")
print(cities)

# Ensure numeric lat/lon
cities["latitude"] = cities["latitude"].astype(float)
cities["longitude"] = cities["longitude"].astype(float)
cities["city"] = cities["city"].str.strip()

#########################
# Find all .nc files
#########################
nc_files = list(era5_data_folder.glob("*.nc"))
if not nc_files:
    raise FileNotFoundError(f"No .nc files found in {era5_data_folder}")

print(f"Found {len(nc_files)} .nc file(s): {[f.name for f in nc_files]}")

#########################
# Process each .nc file
#########################
for nc_file in nc_files:
    print(f"\nProcessing file: {nc_file.name}")
    ds = xr.open_dataset(nc_file)
    print("Dataset opened.")

    # Rename valid_time to time if needed
    if "valid_time" in ds.coords:
        ds = ds.rename({"valid_time": "time"})

    # Loop through cities
    for _, row in cities.iterrows():
        city = row["city"]
        lat = row["latitude"]
        lon = row["longitude"]
        city_clean = city.replace(" ", "")

        # Convert negative longitude to 0-360
        lon = lon if lon >= 0 else 360 + lon

        # Interpolate t2m to city location (bilinear)
        try:
            city_data = ds.interp(latitude=lat, longitude=lon, method="linear")
        except Exception as e:
            print(f"Skipping {city}: interpolation error: {e}")
            continue

        # Convert to DataFrame with time and t2m (in Kelvin)
        df_city = city_data["t2m"].to_dataframe().reset_index()

        # Split time into date and hour
        df_city["date"] = pd.to_datetime(df_city["time"]).dt.date
        df_city["hour"] = pd.to_datetime(df_city["time"]).dt.hour
        df_city_out = df_city[["date", "hour", "t2m"]]

        # Save one CSV per city per year
        df_city_out["year"] = pd.to_datetime(df_city_out["date"]).dt.year
        for year, df_year in df_city_out.groupby("year"):
            output_csv = output_folder / f"ERA_{city_clean}_{year}.csv"
            if output_csv.exists():
                print(f"{output_csv.name} already exists. Skipping.")
                continue

            df_year.to_csv(output_csv, index=False)
            print(f"Saved {output_csv.name}")