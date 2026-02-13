import os
import zipfile as ZF

current_directory_files = os.listdir();
curernt_working_dir = os.getcwd();

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
						current_zip.extract(nc_to_extract,curernt_working_dir)
	except ZF.BadZipFile:
		print(f"--We could NOT OPEN")
	except Exception as e:
		print(f"--We found an exception {e}")