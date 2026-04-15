import tkinter as tk
from tkinter import ttk
import subprocess
import threading

from cities_manager import open_cities_window
from era5_data_checker import open_checker_window

# -----------------------------
# PROCESS HANDLING
# -----------------------------
process = None

def run_command(cmd):
    global process

    def task():
        global process
        try:
            disable_buttons()
            process = subprocess.Popen(cmd)
            process.wait()
        finally:
            enable_buttons()
            process = None

    threading.Thread(target=task, daemon=True).start()


def stop_process():
    global process
    if process:
        try:
            process.terminate()
        except:
            pass


# -----------------------------
# MODULE CALLS (ONLY ENTRY POINTS)
# -----------------------------

def run_pipeline():
    run_command(["python", "era5_pipeline.py"])


def run_checker():
    run_command(["python", "era5_data_checker.py"])


def run_cities_manager():
    run_command(["python", "cities_manager.py"])


def run_matlab_analysis():
    run_command([
        "matlab",
        "-batch",
        "era5_mil310_analysis"
    ])


# -----------------------------
# GUI CONTROL
# -----------------------------
def disable_buttons():
    for b in buttons:
        b.config(state=tk.DISABLED)
    stop_button.config(state=tk.NORMAL)


def enable_buttons():
    for b in buttons:
        b.config(state=tk.NORMAL)
    stop_button.config(state=tk.DISABLED)


# -----------------------------
# GUI SETUP
# -----------------------------
window = tk.Tk()
window.title("ERA5 Control Panel")
window.geometry("700x400")

style = ttk.Style()
style.configure("TButton", font=("Helvetica", 12), padding=8)

frame = ttk.Frame(window, padding=20)
frame.pack(fill=tk.BOTH, expand=True)

title = ttk.Label(frame, text="ERA5 Research Dashboard", font=("Helvetica", 16, "bold"))
title.grid(row=0, column=0, columnspan=2, pady=10)

# -----------------------------
# BUTTONS
# -----------------------------
btn_cities = ttk.Button(frame, text="Manage Cities", command=lambda: open_cities_window(window))
btn_checker = ttk.Button(frame, text="Check Data", command=lambda: open_checker_window(window))
btn_pipeline = ttk.Button(frame, text="Run ERA5 Pipeline", command=run_pipeline)
btn_matlab = ttk.Button(frame, text="Run MIL-310 Analysis", command=run_matlab_analysis)
stop_button = ttk.Button(frame, text="STOP", command=stop_process)

buttons = [btn_pipeline, btn_checker, btn_cities, btn_matlab]

btn_cities.grid(row=1, column=0, sticky="ew", pady=5)
btn_checker.grid(row=2, column=0, sticky="ew", pady=5)
btn_pipeline.grid(row=3, column=0, sticky="ew", pady=5)
btn_matlab.grid(row=4, column=0, sticky="ew", pady=5)
stop_button.grid(row=5, column=0, sticky="ew", pady=10)

stop_button.config(state=tk.DISABLED)

window.mainloop()