import tkinter as tk
from tkinter import ttk
import subprocess 
import threading
import os 



# --- GUI Setup ---

window = tk.Tk()
window.title("Script Runner GUI")
window.geometry("850x500") # Made window wider for longer description
window.configure(bg="#f0f0f0")

style = ttk.Style()
style.configure("TButton", font=("Helvetica", 12), padding=10)
style.configure("TFrame", background="#f0f0f0")
style.configure("TLabel", background="#f0f0f0", font=("Helvetica", 14, "bold"))
style.configure("Desc.TLabel", background="#f0f0f0", font=("Helvetica", 11))

main_frame = ttk.Frame(window, padding="20")
main_frame.pack(fill=tk.BOTH, expand=True)

main_frame.columnconfigure(1, weight=1) 
main_frame.rowconfigure(4, weight=1) # Changed to row 4 for output box

title_label = ttk.Label(main_frame, text="Script Launcher")
title_label.grid(row=0, column=0, columnspan=2, pady=(0, 20), sticky="ew")

# --- Row 1: Script 1 ---
button1 = ttk.Button(main_frame, text="Run Quick Script", command=lambda: run_script("script1.py", output_text))
button1.grid(row=1, column=0, padx=(0, 10), pady=5, sticky="ew")
description1 = ttk.Label(main_frame, text="Runs script1.py. A quick demo script.", style="Desc.TLabel")
description1.grid(row=1, column=1, padx=(10, 0), pady=5, sticky="w")

# --- Row 2: Script 2 ---
button2 = ttk.Button(main_frame, text="Run Long Script", command=lambda: run_script("script2.py", output_text))
button2.grid(row=2, column=0, padx=(0, 10), pady=5, sticky="ew")
description2 = ttk.Label(main_frame, text="Runs script2.py. A longer script that simulates work.", style="Desc.TLabel")
description2.grid(row=2, column=1, padx=(10, 0), pady=5, sticky="w")

# --- Row 3: MATLAB Script (NEW) ---
matlab_button = ttk.Button(main_frame, text="Analyze Atmosphere Data", command=lambda: 
    subprocess.run(
        [
            "matlab",
            "-nodesktop",
            "-nosplash",
            "-r",
            "run('tes1.m'); exit"
        ],
            capture_output=False,  # Capture stdout and stderr
            text=True,            # Decode stdout/stderr as text
            check=True   
    )
)
matlab_button.grid(row=3, column=0, padx=(0, 10), pady=5, sticky="ew")
matlab_description = ttk.Label(main_frame, text="Runs analyze_atmosphere_data.m. Processes ERA5 data according to MIL-310-HBK.", style="Desc.TLabel")
matlab_description.grid(row=3, column=1, padx=(10, 0), pady=5, sticky="w")

# --- Row 4: Output Text Box ---
output_text = tk.Text(main_frame, height=15, state=tk.DISABLED, bg="#ffffff", relief="solid", borderwidth=1, font=("Courier New", 10))
output_text.grid(row=4, column=0, columnspan=2, pady=(20, 0), sticky="nsew")

window.mainloop()



# result = subprocess.run(
#     [
#         "matlab",
#         "-nodesktop",
#         "-nosplash",
#         "-r",
#         "run('tes1.m'); exit"
#     ],
#         capture_output=True,  # Capture stdout and stderr
#         text=True,            # Decode stdout/stderr as text
#         check=True   
# )