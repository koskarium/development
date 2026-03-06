import numpy as np
from netCDF4 import Dataset

# --- Configuration ---
# Replace with the actual path to your file
input_filename = r'D:\Atmosphere\Era5\temp\era5_2023.nc'
# The name of the new compressed file that will be created
output_filename = 'compressed_output.nc' 
# The main variable you want to compress
variable_to_compress = 't2m'

# --- Open files ---
# 'r' for read, 'w' for write. The 'with' statement ensures files are closed properly.
with Dataset(input_filename, 'r') as src, Dataset(output_filename, 'w', format='NETCDF4') as dst:
    
    # --- 1. Copy Global Attributes ---
    print("Copying global attributes...")
    dst.setncatts(src.__dict__)
    
    # --- 2. Copy Dimensions ---
    print("Copying dimensions...")
    for name, dimension in src.dimensions.items():
        dst.createDimension(
            name, (len(dimension) if not dimension.isunlimited() else None))
            
    # --- 3. Copy Variables ---
    print("Copying variables and applying compression...")
    for name, variable in src.variables.items():
        # Create the variable in the destination file
        if name == variable_to_compress:
            # --- Option A: Lossless Compression (Recommended) ---
            # zlib=True enables standard lossless compression.
            # complevel=5 is a good balance between speed and compression ratio (1-9).
            out_var = dst.createVariable(
                name, variable.datatype, variable.dimensions, 
                zlib=True, complevel=8
            )
            
            # --- Option B: Lossy Compression (for smaller files) ---
            # If you can accept a small loss in precision for much better compression.
            # 'least_significant_digit=2' will round the data to 2 decimal places.
            # UNCOMMENT the lines below to use lossy compression instead of lossless.
            # print(f"Applying lossy compression to '{name}'...")
            # out_var = dst.createVariable(
            #     name, variable.datatype, variable.dimensions, 
            #     zlib=True, complevel=5, least_significant_digit=2
            # )

        else:
            # For all other variables, copy them without compression
            out_var = dst.createVariable(name, variable.datatype, variable.dimensions)
            
        # Copy variable attributes
        out_var.setncatts(variable.__dict__)
        
        # Copy variable data
        # This is done last, and is the most time-consuming step
        print(f"  - Writing data for variable: {name}")
        out_var[:] = variable[:]

print(f"\nCompression complete. New file saved as '{output_filename}'")
