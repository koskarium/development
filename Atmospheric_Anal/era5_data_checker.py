import tkinter as tk
from tkinter import ttk, messagebox
import os
import csv
import re
import datetime

# -----------------------------
# PATHS / CONFIG
# -----------------------------
DATA_DIR = os.path.join("Era5", "Cities")
CITIES_FILE = os.path.join(os.path.dirname(__file__), "cities.csv")

# -----------------------------
# YEAR RANGE (DYNAMIC)
# -----------------------------
current_year = datetime.datetime.now().year
last_year = current_year - 1
YEAR_RANGE = range(1940, current_year)


# -----------------------------
# HELPERS
# -----------------------------
def normalize(name):
    return name.lower().replace(" ", "")


# -----------------------------
# LOAD CITIES
# -----------------------------
def load_cities():
    cities = []

    if not os.path.exists(CITIES_FILE):
        return cities

    with open(CITIES_FILE, "r", newline="") as f:
        reader = csv.DictReader(f)

        for row in reader:
            if "city" in row:
                cities.append(row["city"].strip())

    return cities


# -----------------------------
# SCAN FILES
# -----------------------------
def scan_files():
    pattern = re.compile(r"ERA_(.+)_(\d{4})\.csv")

    data = {}

    if not os.path.exists(DATA_DIR):
        return data

    for file in os.listdir(DATA_DIR):
        match = pattern.match(file)
        if match:
            city = normalize(match.group(1))
            year = int(match.group(2))

            if city not in data:
                data[city] = set()

            data[city].add(year)

    return data


# -----------------------------
# COMPUTE MISSING YEARS
# -----------------------------
def compute_missing(cities, data):
    results = []

    for city in cities:
        key = normalize(city)

        years_present = data.get(key, set())
        missing = [y for y in YEAR_RANGE if y not in years_present]

        results.append({
            "city": city,
            "key": key,
            "missing_count": len(missing),
            "missing_years": missing
        })

    return results


# -----------------------------
# GUI WINDOW
# -----------------------------
def open_checker_window(parent):
    win = tk.Toplevel(parent)
    win.title("ERA5 Data Checker")
    win.geometry("850x550")

    # -------------------------
    # HEADER INFO
    # -------------------------
    info_label = ttk.Label(
        win,
        text=f"Checking ERA5 completeness: 1940 → {last_year}",
        font=("Helvetica", 11, "bold")
    )
    info_label.pack(pady=5)

    # -------------------------
    # FRAME
    # -------------------------
    frame = ttk.Frame(win)
    frame.pack(fill=tk.BOTH, expand=True)

    tree = ttk.Treeview(frame, columns=("city", "missing"), show="headings")

    tree.heading("city", text="City")
    tree.heading("missing", text="Missing Years Count")

    tree.column("city", width=350)
    tree.column("missing", width=150)

    scrollbar = ttk.Scrollbar(frame, orient="vertical", command=tree.yview)
    tree.configure(yscrollcommand=scrollbar.set)

    tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
    scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

    tree.tag_configure("bad", background="#ffcccc")

    # -------------------------
    # LOAD DATA
    # -------------------------
    cities = load_cities()
    data = scan_files()
    results = compute_missing(cities, data)

    city_map = {}

    for r in results:
        city_map[r["city"]] = r["missing_years"]

        tag = "bad" if r["missing_count"] > 0 else ""
        tree.insert("", "end", values=(r["city"], r["missing_count"]), tags=(tag,))

    # -------------------------
    # CLICK EVENT
    # -------------------------
    def on_click(event):
        sel = tree.focus()
        if not sel:
            return

        item = tree.item(sel)
        city = item["values"][0]

        missing = city_map.get(city, [])

        if not missing:
            messagebox.showinfo("OK", f"{city} has no missing data.")
            return

        messagebox.showinfo(
            f"{city} Missing Years",
            "\n".join(map(str, missing))
        )

    tree.bind("<<TreeviewSelect>>", on_click)