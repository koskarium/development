import tkinter as tk
from tkinter import ttk
import pandas as pd
import os

# -----------------------------
# FILE PATH
# -----------------------------
CITIES_FILE = "cities.csv"


# -----------------------------
# LOAD / SAVE
# -----------------------------
def load_data():
    if not os.path.exists(CITIES_FILE):
        return pd.DataFrame(columns=["city", "latitude", "longitude"])

    df = pd.read_csv(CITIES_FILE)

    # safety: ensure correct columns exist
    expected = {"city", "latitude", "longitude"}
    if not expected.issubset(df.columns):
        return pd.DataFrame(columns=["city", "latitude", "longitude"])

    return df


def save_data(df):
    df.to_csv(CITIES_FILE, index=False)


# -----------------------------
# MAIN WINDOW
# -----------------------------
def open_cities_window(parent):
    win = tk.Toplevel(parent)
    win.title("Cities Manager")
    win.geometry("650x400")

    # -------------------------
    # LOAD DATA
    # -------------------------
    df = load_data()

    # -------------------------
    # TREEVIEW
    # -------------------------
    frame = ttk.Frame(win)
    frame.pack(fill=tk.BOTH, expand=True)

    tree = ttk.Treeview(frame, columns=("city", "lat", "lon"), show="headings")

    tree.heading("city", text="City")
    tree.heading("lat", text="Latitude")
    tree.heading("lon", text="Longitude")

    tree.column("city", width=200)
    tree.column("lat", width=120)
    tree.column("lon", width=120)

    tree.pack(fill=tk.BOTH, expand=True)

    # -------------------------
    # REFRESH TABLE
    # -------------------------
    def refresh():
        tree.delete(*tree.get_children())

        for _, row in df.iterrows():
            tree.insert(
                "",
                "end",
                values=(row["city"], row["latitude"], row["longitude"])
            )

    refresh()

    # -------------------------
    # RELOAD DATA FROM FILE
    # -------------------------
    def reload_data():
        nonlocal df
        df = load_data()
        refresh()

    # -------------------------
    # INPUT FIELDS
    # -------------------------
    form = ttk.Frame(win)
    form.pack(fill=tk.X, pady=10)

    city_var = tk.StringVar()
    lat_var = tk.StringVar()
    lon_var = tk.StringVar()

    ttk.Label(form, text="City").grid(row=0, column=0)
    ttk.Entry(form, textvariable=city_var, width=15).grid(row=0, column=1)

    ttk.Label(form, text="Lat").grid(row=0, column=2)
    ttk.Entry(form, textvariable=lat_var, width=10).grid(row=0, column=3)

    ttk.Label(form, text="Lon").grid(row=0, column=4)
    ttk.Entry(form, textvariable=lon_var, width=10).grid(row=0, column=5)

    # -------------------------
    # ADD CITY
    # -------------------------
    def add_city():
        nonlocal df

        city = city_var.get().strip()
        lat = lat_var.get().strip()
        lon = lon_var.get().strip()

        if not city:
            return

        try:
            df.loc[len(df)] = [city, float(lat), float(lon)]
            save_data(df)
            reload_data()
        except ValueError:
            print("Invalid latitude/longitude")

    # -------------------------
    # DELETE CITY
    # -------------------------
    def delete_city():
        selected = tree.selection()
        if not selected:
            return

        city = tree.item(selected[0])["values"][0]

        df2 = load_data()
        df2 = df2[df2["city"] != city]

        save_data(df2)
        reload_data()

    # -------------------------
    # EDIT CITY
    # -------------------------
    def edit_city():
        selected = tree.selection()
        if not selected:
            return

        old_city = tree.item(selected[0])["values"][0]

        city = city_var.get().strip()
        lat = lat_var.get().strip()
        lon = lon_var.get().strip()

        try:
            df2 = load_data()
            df2.loc[df2["city"] == old_city, ["city", "latitude", "longitude"]] = [
                city, float(lat), float(lon)
            ]

            save_data(df2)
            reload_data()
        except ValueError:
            print("Invalid input for edit")

    # -------------------------
    # BUTTONS
    # -------------------------
    btn_frame = ttk.Frame(win)
    btn_frame.pack(pady=10)

    ttk.Button(btn_frame, text="Add", command=add_city).grid(row=0, column=0, padx=5)
    ttk.Button(btn_frame, text="Edit", command=edit_city).grid(row=0, column=1, padx=5)
    ttk.Button(btn_frame, text="Delete", command=delete_city).grid(row=0, column=2, padx=5)