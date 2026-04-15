import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import csv

process = None  # Global process reference

# -----------------------------
# PROCESS FUNCTIONS
# -----------------------------

def run_command(command):
    global process

    def task():
        global process
        try:
            disable_buttons()

            process = subprocess.Popen(command)
            process.wait()

        except Exception as e:
            print(f"Error: {e}")

        finally:
            enable_buttons()
            process = None

    threading.Thread(target=task, daemon=True).start()


def run_python(script):
    run_command(["python", script])


def run_matlab(script):
    run_command([
        "matlab",
        "-batch",
        script.replace(".m", "")
    ])


def stop_process():
    global process
    if process:
        try:
            process.kill()
        except:
            pass


# -----------------------------
# BUTTON STATE CONTROL
# -----------------------------

def disable_buttons():
    config_button.config(state=tk.DISABLED)
    button2.config(state=tk.DISABLED)
    matlab_button.config(state=tk.DISABLED)
    stop_button.config(state=tk.NORMAL)


def enable_buttons():
    config_button.config(state=tk.NORMAL)
    button2.config(state=tk.NORMAL)
    matlab_button.config(state=tk.NORMAL)
    stop_button.config(state=tk.DISABLED)


# -----------------------------
# CITIES WINDOW (CONFIG)
# -----------------------------

def open_cities_window():
    win = tk.Toplevel(window)
    win.title("Cities Config")
    win.geometry("500x400")

    frame = ttk.Frame(win)
    frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

    tree = ttk.Treeview(frame, columns=("city", "lat", "lon"), show="headings")

    tree.heading("city", text="City")
    tree.heading("lat", text="Latitude")
    tree.heading("lon", text="Longitude")

    tree.column("city", width=200)
    tree.column("lat", width=120)
    tree.column("lon", width=120)

    scrollbar = ttk.Scrollbar(frame, orient="vertical", command=tree.yview)
    tree.configure(yscrollcommand=scrollbar.set)

    tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
    scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

    # --- Load + sort ---
    try:
        data = []

        with open("cities.txt", "r") as f:
            reader = csv.DictReader(f)

            for row in reader:
                city = row.get("cities") or row.get("city")
                lat = row.get("latitude")
                lon = row.get("longitude")
                data.append((city, lat, lon))

        data.sort(key=lambda x: x[0].lower() if x[0] else "")

        for city, lat, lon in data:
            tree.insert("", tk.END, values=(city, lat, lon))

    except Exception as e:
        print(f"Error loading cities: {e}")


# -----------------------------
# GUI SETUP
# -----------------------------

window = tk.Tk()
window.title("Script Launcher")
window.geometry("650x320")
window.configure(bg="#f0f0f0")

style = ttk.Style()
style.configure("TButton", font=("Helvetica", 12), padding=10)
style.configure("TLabel", background="#f0f0f0", font=("Helvetica", 14, "bold"))
style.configure("Desc.TLabel", background="#f0f0f0", font=("Helvetica", 11))

main_frame = ttk.Frame(window, padding="20")
main_frame.pack(fill=tk.BOTH, expand=True)

main_frame.columnconfigure(1, weight=1)

title_label = ttk.Label(main_frame, text="Script Launcher")
title_label.grid(row=0, column=0, columnspan=2, pady=(0, 20))


# -----------------------------
# BUTTONS
# -----------------------------

# 🔥 REPLACED BUTTON (Config → Cities)
config_button = ttk.Button(
    main_frame,
    text="Config (Cities)",
    command=open_cities_window
)
config_button.grid(row=1, column=0, padx=10, pady=5, sticky="ew")

ttk.Label(
    main_frame,
    text="View cities configuration table",
    style="Desc.TLabel"
).grid(row=1, column=1, sticky="w")


button2 = ttk.Button(
    main_frame,
    text="Run Long Script",
    command=lambda: run_python("script2.py")
)
button2.grid(row=2, column=0, padx=10, pady=5, sticky="ew")

ttk.Label(
    main_frame,
    text="Runs script2.py",
    style="Desc.TLabel"
).grid(row=2, column=1, sticky="w")


matlab_button = ttk.Button(
    main_frame,
    text="Analyze Atmosphere Data",
    command=lambda: run_matlab("tes1.m")
)
matlab_button.grid(row=3, column=0, padx=10, pady=5, sticky="ew")

ttk.Label(
    main_frame,
    text="Runs MATLAB ERA5 analysis",
    style="Desc.TLabel"
).grid(row=3, column=1, sticky="w")


stop_button = ttk.Button(
    main_frame,
    text="Stop",
    command=stop_process,
    state=tk.DISABLED
)
stop_button.grid(row=4, column=0, padx=10, pady=15, sticky="ew")


# -----------------------------
# START APP
# -----------------------------
window.mainloop()