import tkinter as tk
from tkinter import ttk
import csv

def load_cities_sorted(tree, file_path="cities.txt"):
    try:
        data = []

        # --- Read file ---
        with open(file_path, "r") as f:
            reader = csv.DictReader(f)

            for row in reader:
                city = row.get("cities") or row.get("city")
                lat = row.get("latitude")
                lon = row.get("longitude")

                data.append((city, lat, lon))

        # --- SORT by city name ---
        data.sort(key=lambda x: x[0].lower() if x[0] else "")

        # --- Insert into table ---
        for city, lat, lon in data:
            tree.insert("", tk.END, values=(city, lat, lon))

    except Exception as e:
        print(f"Error loading file: {e}")


def main():
    window = tk.Tk()
    window.title("Cities Table (Sorted)")
    window.geometry("500x400")

    frame = ttk.Frame(window)
    frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

    # --- Table ---
    columns = ("city", "latitude", "longitude")
    tree = ttk.Treeview(frame, columns=columns, show="headings")

    tree.heading("city", text="City")
    tree.heading("latitude", text="Latitude")
    tree.heading("longitude", text="Longitude")

    tree.column("city", width=200)
    tree.column("latitude", width=120)
    tree.column("longitude", width=120)

    # --- Scrollbar ---
    scrollbar = ttk.Scrollbar(frame, orient="vertical", command=tree.yview)
    tree.configure(yscrollcommand=scrollbar.set)

    tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
    scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

    # --- Load + sort ---
    load_cities_sorted(tree)

    window.mainloop()


if __name__ == "__main__":
    main()