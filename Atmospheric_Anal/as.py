import xarray as xr

# Open the file
ds = xr.open_dataset("MERRA2_400.tavg1_2d_slv_Nx.20251201.nc4")

# Print a summary
print(ds)