# 🚀 PrintSplit & Pin — Julkaisu- & Markkinointipaketti (Launch Kit)

Tämä paketti sisältää valmiit myynti- ja mainostekstit, julkaisupostaukset ja jakelulinkit **PrintSplit & Pin** -sovelluksen menestyksekkääseen julkaisuun.

---

## 📊 1. Tuotetiedot & Linkit

* **Sovelluksen nimi:** PrintSplit & Pin (macOS Universal arm64 + x86_64)
* **Asennuspaketti (DMG, 951 KB):** [`dist/PrintSplit-1.0.dmg`](file:///Volumes/Dataa/Ohjelmointi/ProjektitSwift/PrintSplitMac/dist/PrintSplit-1.0.dmg)
* **GitHub-repo:** `https://github.com/pietini69/printsplit`
* **Virallinen verkkosivusto:** `https://pietini69.github.io/printsplit/`
* **Latauslinkki (Direct DMG):** `https://github.com/pietini69/printsplit/releases/download/v1.0.0/PrintSplit-1.0.dmg`
* **Hinnat ja maksulinkit:**
  * **PrintSplit Pro Lifetime (29 €):**
    `https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=niko.pietinen%40gmail.com&item_name=PrintSplit+Pro+Lifetime+License&amount=29.00&currency_code=EUR&no_shipping=1`
  * **Maker Pro Bundle: PrintCAD + PrintSplit & Pin (39 €):**
    `https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=niko.pietinen%40gmail.com&item_name=Maker+Pro+Bundle+(PrintCAD+++PrintSplit)&amount=39.00&currency_code=EUR&no_shipping=1`
* **Lisenssiavainten luonti ostajille:**
  ```bash
  python3 scripts/generate_key.py "ostajan_email@domain.com"
  ```

---

## 📣 2. Valmiit mainos- ja julkaisupostaukset (Kopioi ja liitä)

### A. Reddit: `r/3Dprinting` & `r/OrcaSlicer` & `r/BambuLab`

**Otsikko (Title):**
> I got tired of non-manifold errors and awkward cuts on large models, so I built PrintSplit: a 950KB native Mac tool that auto-carves alignment dowel sockets and opens directly in OrcaSlicer/Bambu Studio

**Viesti (Body):**
```markdown
Hey everyone! 👋

Like many of you printing functional parts on Bambu Lab, Neptune 4, Ender, or Prusa beds, I constantly run into models that are just slightly too tall or wide to fit in one piece.

When splitting models in slicers or trying to carve alignment pin holes manually in CAD, I kept hitting three frustrating issues:
1. **Mesh Errors:** Boolean cuts and slicer peg tools frequently left non-manifold edges and hole defects that required mesh repairs.
2. **Manual Alignment Hassle:** Aligning connector pins, accounting for FDM clearance tolerances, and placing sockets manually took way too much time.
3. **Floating / Colliding Parts:** Exported parts had to be manually dropped, rotated, and spread across the build bed.

So I spent the last few weeks building **PrintSplit & Pin**—a lightweight, native macOS utility dedicated to splitting models cleanly for 3D printing.

### ✨ What it does:
- **1-Click Plane Split:** Slice along X, Y, or Z (or custom offset height) in milliseconds.
- **Smart Alignment Dowel Pins & Sockets:** Automatically calculates optimal pin positions across the cut face and carves physical socket cavities into Part A and Part B with configurable clearance (0.2 mm default).
- **Bed-Ready Printable Pins:** Generates standalone upright dowel pins resting flat on the build plate ($Z = 0$) with top and bottom entry chamfers (0.6 mm) for easy push-fit assembly.
- **Guaranteed 100% Watertight Manifold:** Built with custom Delaunay boundary triangulation linked directly to exact mesh vertices. **Zero open edges, zero non-manifold errors.**
- **1-Click OrcaSlicer & Bambu Studio Bridge:** One button auto-arranges Part A, Part B, and the pins side-by-side to fit your printer volume and loads them directly on your virtual build plate ready to slice.
- **Blazingly Fast (< 1 MB):** Native Swift + SceneKit/Metal. Cold starts in **0.1 seconds**. Zero Electron, zero webviews, zero cloud dependencies.

### 📥 Download & Pricing:
PrintSplit comes with an unrestricted **14-day free trial** (no credit card required).
If you find it useful, a lifetime Pro license is a one-time payment of **29 €** (no monthly subscriptions).

- 🌐 Website: https://pietini69.github.io/printsplit/
- 📥 Direct Universal DMG (951 KB): https://github.com/pietini69/printsplit/releases/download/v1.0.0/PrintSplit-1.0.dmg
- 💻 Requirements: macOS 14 Sonoma or macOS 15 Sequoia (Apple Silicon M1-M4 & Intel)

I'd love to hear your feedback, thoughts on tolerance clearances, and any feature requests!
```

---

### B. Reddit: `r/macapps`

**Otsikko (Title):**
> [Mac App] PrintSplit & Pin — A 950KB native Mac utility to split large 3D models with auto-generated alignment pins & 1-click slicer export

**Viesti (Body):**
```markdown
Hi r/macapps! 👋

I wanted to share **PrintSplit & Pin**, a native Mac tool designed specifically for makers and 3D printing enthusiasts.

Modern 3D CAD tools (Fusion 360, FreeCAD, Blender) take 20–40 seconds to launch and are hundreds of megabytes or gigabytes in size. Slicers have basic cut tools, but their peg joints often create non-manifold mesh errors or require tedious manual positioning.

I built PrintSplit from scratch in pure **Swift and SceneKit/Metal**:
- ⚡️ **Launch time:** ~100 ms cold start
- 📦 **Download size:** 951 KB universal binary (Apple Silicon + Intel)
- 📌 **Auto-pin generator:** Carves physical cavities with 0.2 mm clearance and exports chamfered printable dowels
- 🛡️ **Watertight:** Guaranteed 0 open edges and 0 non-manifold edges
- 🖨️ **1-Click Slicer Export:** Detects OrcaSlicer / Bambu Studio and loads pre-arranged parts on the build plate
- 🔒 **Privacy:** 100% offline, zero telemetry, no subscriptions

Download the 14-day trial here: https://github.com/pietini69/printsplit/releases/download/v1.0.0/PrintSplit-1.0.dmg
Website: https://pietini69.github.io/printsplit/

Would love any thoughts from fellow Mac makers!
```

---

### C. Hacker News: `Show HN`

**Otsikko (Title):**
> Show HN: PrintSplit – Native 950KB macOS tool to split 3D prints with auto-alignment pins

**Viesti (Body):**
```markdown
Hi HN,

I built PrintSplit (https://pietini69.github.io/printsplit/) to solve a common headache in 3D printing: splitting models that exceed your printer's build volume while maintaining clean mechanical alignment.

Most people either struggle with slicer boolean cut tools (which frequently produce non-manifold boundaries) or fire up a full CAD suite to manually model peg joints and subtract socket cavities.

PrintSplit is a native macOS application written in Swift and Metal/SceneKit:
- Sub-1MB universal binary (arm64 + x86_64)
- Cold boot under 100ms
- Delaunay-based planar cap triangulation linking directly to boundary cut vertices to ensure 2-manifold watertight geometry (0 open edges)
- Automatic dowel pin placement and clearance socket carving
- 1-click dispatch into OrcaSlicer and Bambu Studio with build plate auto-arrangement

Free trial download: https://github.com/pietini69/printsplit/releases/download/v1.0.0/PrintSplit-1.0.dmg

Feedback and questions on the geometric pipeline are very welcome!
```

---

### D. Suomalaiset 3D-tulostusryhmät (Facebook / Discord / Foorumit)

**Otsikko:**
> Tein kevyen macOS-työkalun liian suurten 3D-tulosteiden osittamiseen ja kohdistustappien tekoon (PrintSplit & Pin)

**Teksti:**
```text
Moi kaikille! 👋

Tiedättehän sen tilanteen, kun hieno malli on vain muutaman sentin liian suuri tulostusalustalle, ja slicerin omalla leikkaustyökalulla tapit jäävät hankaamaan tai tekevät reikäreunoihin non-manifold -virheitä?

Tein tähän ratkaisuksi natiivin macOS-työkalun nimeltä **PrintSplit & Pin**:
• Raahaa STL sisään ja valitse leikkauskorkeus.
• Klikkaa "Generate Alignment Pins", niin ohjelma laskee optimaaliset kohdistustappien paikat ja tekee vastakappaleisiin tarkat kolot säädettävällä välyksellä (oletus 0.2 mm).
• Generoi myös valmiit pystyssä tulostettavat kohdistustapit alustalle viisteillä (0.6 mm) helppoa painoliitosta varten.
• 100 % ehjä geometria: 0 avointa reunaa, 0 leikkausvirhettä.
• 1-klikkauksella osat aukeavat suoraan vierekkäin OrcaSliceriin tai Bambu Studioon tulostusalustalle valmiina viipaloitavaksi!

Sovellus on täysin natiivi Swift/Metal-sovellus, koko vain 950 KB (käynnistyy heti ilman pilvipalveluita tai odottelua).

Voit ladata ilmaisen 14 pv kokeiluversion tästä:
https://github.com/pietini69/printsplit/releases/download/v1.0.0/PrintSplit-1.0.dmg

Verkkosivut: https://pietini69.github.io/printsplit/

Antakaa ihmeessä palautetta ja ideoita jatkokehitykseen! 🚀
```

---

### E. Twitter / X / Threads (Lyhyt ja iskevä)

```text
Tired of failed multi-part 3D prints? 🧩

I built PrintSplit & Pin: a 950KB native Mac tool that splits oversized STLs, auto-carves alignment dowel sockets, and opens directly in OrcaSlicer & Bambu Studio.

✅ 0.1s startup
✅ 0 non-manifold errors
✅ 100% offline & private

Try it: https://github.com/pietini69/printsplit/releases/download/v1.0.0/PrintSplit-1.0.dmg
#3dprinting #orcaslicer #bambulab #macapps
```
