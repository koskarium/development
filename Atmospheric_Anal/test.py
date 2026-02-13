"""
MERRA-2 multi-day access via OPeNDAP
- No NetCDF files saved
- Earthdata login handled inside code
- Works reliably on Windows / macOS / Linux

Requirements:
    pip install xarray pydap netCDF4 dask
"""

import xarray as xr
from pydap.client import open_url
from pydap.cas.urs import setup_session
from datetime import date, timedelta

# =====================================================
# EARTHDATA CREDENTIALS (PUT YOURS HERE)
# =====================================================
EARTHDATA_USERNAME = "koskarium"
EARTHDATA_PASSWORD = "Kev!nnegron07"

session = setup_session(EARTHDATA_USERNAME, EARTHDATA_PASSWORD)

# =====================================================
# USER SETTINGS
# =====================================================
START_DATE = date(2025, 1, 1)
END_DATE   = date(2025, 1, 5)

VARIABLES = ["T2M", "U10M", "V10M", "PS"]

LAT_MIN, LAT_MAX = -10, 10
LON_MIN, LON_MAX = 260, 300   # 0–360 longitude convention

# =====================================================
# BUILD DATE LIST
# =====================================================
dates = [
    START_DATE + timedelta(days=i)
    for i in range((END_DATE - START_DATE).days + 1)
]

# =====================================================
# BUILD OPeNDAP URLS
# =====================================================
base_url = (
    "https://goldsmr4.gesdisc.eosdis.nasa.gov/opendap/"
    "MERRA2/M2I1NXASM.5.12.4/2025/01"
)

urls = [
    f"{base_url}/MERRA2_400.inst1_2d_asm_Nx.{d:%Y%m%d}.nc4"
    for d in dates
]

# =====================================================
# OPEN EACH DAY VIA PYDAP (AUTHENTICATED)
# =====================================================
datasets = []

for url in urls:
    print(f"Opening: {url}")
    ds_day = xr.open_dataset(
        open_url(url, session=session),
        engine="pydap"
    )
    datasets.append(ds_day)
# =====================================================
# CONCATENATE INTO SINGLE DATASET
# =====================================================
ds = xr.concat(datasets, dim="time")

# =====================================================
# SUBSET (STILL NO DATA DOWNLOADED)
# =====================================================
ds = ds[VARIABLES].sel(
    lat=slice(LAT_MIN, LAT_MAX),
    lon=slice(LON_MIN, LON_MAX)
)

# =====================================================
# EXAMPLE ANALYSIS (TRIGGERS DOWNLOAD)
# =====================================================
# Daily mean 2-meter temperature
daily_t2m = (
    ds["T2M"]
    .resample(time="1D")
    .mean()
    .compute()
)

print("\nDaily mean T2M:")
print(daily_t2m)
