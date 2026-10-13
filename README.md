# PrintSplit & Pin 🧩

> **The Fastest Native Mac Tool to Split Large 3D Prints & Auto-Carve Alignment Dowel Pins.**
>
> Sits oversized STL files flat on your printer bed, generates mechanical alignment pins with customizable clearances, and transfers directly into OrcaSlicer & Bambu Studio with 1 click.

---

## ⚡️ Key Highlights

* **Instant Splitting:** Slice models along X, Y, or Z axes (or enter precise millimeter heights) in milliseconds.
* **Smart Dowel Pin & Socket Generator:** Automatically places alignment dowels along the cut plane and carves mating socket cavities with configurable tolerance clearance (default 0.2 mm).
* **Bed-Ready Printable Pins:** Generates standalone upright dowel pins resting at $Z = 0$ on the build plate with top and bottom entry chamfers (0.6 mm) for easy push-fit assembly.
* **100% Watertight Manifold Meshes:** Uses Delaunay cap triangulation linked directly to exact boundary vertices—guaranteeing **0 open edges** and **0 non-manifold edges** (no slicer repair warnings).
* **1-Click OrcaSlicer & Bambu Studio Bridge:** Automatically spaces Part A, Part B, and pins side-by-side to fit your printer's build volume (Elegoo Neptune 4, Ender 3, Bambu X1/P1/A1, Prusa MK4) and opens them directly.
* **Blazingly Fast & Lightweight:** 100% native Swift & SceneKit/Metal. Cold starts in **0.1 seconds**. Total DMG size is **under 1 MB** (no Electron, no web wrappers).
* **100% Offline & Private:** Runs entirely locally on your Mac SSD. No login, no cloud queue, no subscriptions.

---

## 📥 Download & Pricing

* **Download 14-Day Free Trial (Universal DMG, 951 KB):**
  [PrintSplit-1.0.dmg](https://github.com/pietini69/printsplit/releases/download/v1.0.0/PrintSplit-1.0.dmg)
* **Official Website:**
  [https://pietini69.github.io/printsplit/](https://pietini69.github.io/printsplit/)
* **Buy Pro Lifetime License (29 €):**
  [Pay Securely via PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=niko.pietinen%40gmail.com&item_name=PrintSplit+Pro+Lifetime+License&amount=29.00&currency_code=EUR&no_shipping=1)
* **Maker Pro Bundle (PrintCAD + PrintSplit & Pin) for 39 €:**
  [Get Both Apps via PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=niko.pietinen%40gmail.com&item_name=Maker+Pro+Bundle+(PrintCAD+++PrintSplit)&amount=39.00&currency_code=EUR&no_shipping=1)

---

## 🛠️ Requirements & Installation

* **Operating System:** macOS 14 Sonoma, macOS 15 Sequoia (or newer)
* **Hardware:** Apple Silicon (M1, M2, M3, M4) & Intel Macs (Universal 64-bit binary)
* **Installation:**
  1. Download [`PrintSplit-1.0.dmg`](https://github.com/pietini69/printsplit/releases/download/v1.0.0/PrintSplit-1.0.dmg).
  2. Open the DMG and drag **PrintSplit** into your `/Applications` folder.
  3. Double-click to launch.

---

## 💡 How It Works

1. **Import:** Drag & drop any `.stl` file or click **Demo Model**.
2. **Set Cut Plane:** Choose an axis (Z, Y, or X) and adjust the slice height.
3. **Generate Pins:** Click **Generate Alignment Pins** to calculate pin positions and socket cavities.
4. **Export or Slicer:** Click **Open in OrcaSlicer** or **Export Part A / Part B / Dowel Pins**. Parts are automatically laid flat on the build plate with zero collisions.

---

## 📄 License

PrintSplit & Pin is distributed under a commercial license with an unrestricted free trial. Developed by Niko Pietinen / PNP Software.
