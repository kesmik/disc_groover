![DiscGroover Logo](doc/images/logo.png)

# DISC Groover

An **unofficial educational and personal-restoration project** for generating
printable, two-color optical identifier discs used by some children's screen-free
music and storytelling players.

The purpose is to understand the encoding, experiment with 3D printing, and,
where authorized, replace lost or damaged discs for content already legitimately
available on your device.

The project began by examining discs from a **SKILSAS SK5** player, but similar
disc-based products are sold by other brands and OEM/ODM suppliers.
**Compatibility with other players has not been established.**

The project **does not contain, copy, download, or modify songs, stories, or
firmware**. A generated disc contains only a physical barcode/identifier.

## Related products and research references

These Alibaba listings were supplied as visual references for related screen-free
talking phonograph/story-player products:

- [Custom Screen-Free Talking Phonograph Story — Alibaba listing 1601975821282](https://www.alibaba.com/product-detail/Custom-Screen-Free-Talking-Phonograph-Story_1601975821282.html)
- [ODM Screen-Free Talking Phonograph Story — Alibaba listing 1601975732868](https://www.alibaba.com/product-detail/ODM-Screen-Free-Talking-Phonograph-Story_1601975732868.html)

**Model-number status:** `1601975821282` and `1601975732868` are **Alibaba
listing/product identifiers**, not confirmed manufacturer model numbers. An
authoritative model designation for either listing could not be verified.

Another related supplier reference:
- [Shenzhen Xinditai Electronic — Children's Screen-Free Phonograph Story Toy](https://www.kidsoundbook.com/ai-interactive-toy/children-s-screen-free-phonograph-story-toy.html)

This is a similar product category, but do not assume every product with a
similar appearance uses the same center hole or optical encoding.

## How it works

Current **experimental** interpretation of the photographed discs:

- Each disc has **10 data positions** in **11 angular slots**, leaving one empty
synchronization gap.
- **Narrow black stripe = 1**; **wide black stripe = 0**.
- The 10-bit identifier can represent decimal values **0–1023**.
- Example: `44 = 32 + 8 + 4` (`0000101100` in 10-bit notation).
- The photographic analysis suggests that recording discs may occupy a reserved
high-numbered ID range (990, 991, 992, 993, 994)
- The exact barcode interpretation, alignment, and player compatibility remain
**unverified by manufacturer documentation**.

Each generated disc has **two STL parts**:

1. **White face:** keyed center hole and ten barcode cutouts.
2. **Black backing:** same keyed hole, plus raised black barcode inserts that
enter the white cutouts.


## Dimensions and defaults

All distances are millimeters.

| Variable | Default | Meaning |
| --- | ---: | --- |
| `disc_d` | 70 | Outer diameter |
| `main_hole_d` | 10 | Keyed-hole central circle diameter |
| `lobe_d` | 5 | Diameter of each of two opposite lobes |
| `lock_span` | 14 | Full keyed-hole span, end to end |
| `lobe_angle` | 90 | Lobe-axis orientation in degrees |
| `barcode_length` | 15.5 | Radial stripe length |
| `edge_margin` | 0.7 | Distance from stripe outer end to disc edge |
| `wide_width` | 12 | Width of a binary 0 stripe |
| `narrow_width` | 5 | Width of a binary 1 stripe |
| `wide_corner_radius` | 3.1 | Corner radius of wide stripe |
| `narrow_corner_radius` | 1.5 | Corner radius of narrow stripe |
| `white_t` | 0.30 | White-layer thickness |
| `black_t` | 0.30 | Black-backing thickness |
| `use_raised_inserts` | false | **Only the black inserts** raise id inserts. false will not make them aligned with white layer, but allow to print by changing color manually |
| `fit_clearance` | 0.15 | **Only the black inserts** shrink by this amount per side |
| `show_id` | true | Enable mirrored decimal-number through-cut on black layer |
| `id_font_size` | 6 | Number text size |
| `id_y` | -12 | Number location in local model Y coordinates |
| `id_digit_spacing` | 5 | Digit center-to-center spacing |
| `id_bridge` | 0.4 | Stencil bridge width |
| `$fn` | 120 | Circle approximation resolution |

Center-lobe offset from disc center:

`(lock_span - lobe_d) / 2 = (14 - 5) / 2 = 4.5 mm`

The **0.5 mm edge margin**, encoded angular positions, and binary mapping are working assumptions; test them against a known original disc.

## Generate using Docker (Linux)

Build once:

```bash
docker build -t disc_groover .
```

Generate IDs 1–60:

```bash
mkdir -p output
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD/output:/output" \
  disc_groover --start 1 --end 60
```

Generate selected IDs, including five experimental recording-disc IDs:

```bash
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD/output:/output" \
  disc_groover --ids 1,2,44,990-994
```

Override parameters without editing the SCAD source:

```bash
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD/output:/output" \
  disc_groover --ids 44 \
  --set fit_clearance=0.10 \
  --set white_t=0.30 \
  --set wide_corner_radius=3.1 \
  --set show_id=true \
  --overwrite
```

The ID range `990–994` is based on photographic decoding and should be checked
before relying on it.

## Run without Docker

Requires **Python 3.10+**, **OpenSCAD CLI**, and the **Liberation Sans** font for
decimal labels.

```bash
python3 generate.py --ids 1,2,44,990-994
python3 generate.py --start 1 --end 60
```

Useful flags:

- `--ids`
- `--start`
- `--end`
- `--output`
- `--set NAME=VALUE` (repeatable)
- `--overwrite`
- `--dry-run`
- `--openscad`

The Python generator overrides variables using OpenSCAD's `-D` option: **the
master SCAD file is never modified**.

The current supported parameter names include `wide_corner_radius`,
`narrow_corner_radius`, and `show_id` (not the superseded `corner_radius` or
`insert_recess`).

## Manual OpenSCAD usage

Open `disc_groover.scad`, set `disc_id`, and select `part`:

- `assembled`: both parts in their mating position.
- `exploded`: white layer lifted for inspection.
- `white`: white part only, exported at its model Z position.
- `black`: black part only.
- `side_by_side`: both parts separated for inspection.

Press **F5** for preview, **F6** for full render, then export individual STL
parts.

To inspect the mirrored decimal number, look at the **black underside**, not
the white face.

## Printing and fit checks

- Print **one known ID first** before generating a complete collection.
- Confirm the **70 mm outer diameter**, **keyed-hole dimensions**, **clearances**,
and orientation on the actual player.
- The combined part thickness defaults to **0.60 mm** (0.30 + 0.30 mm); ensure
the slicer represents both layers and the number cutout correctly.
- Printing black and white as separate STL parts requires suitable filament
assignment and assembly. The number opening should expose white plastic, not a
through-hole in the completed disc.
- Ensure the disc rotates freely; the center lock should not bind or produce
sharp edges.
- The project has been tested for OpenSCAD STL generation, **not physically
validated on every compatible-looking player**.

## Legal and safety notes

This project is for **learning, lawful personal experimentation, and
repair/restoration**, including replacing lost discs that select content already
authorized on a legitimately owned device.

It does **not** grant permission to unlock unlicensed content, bypass effective
protection measures, or distribute copyrighted recordings. Local copyright and
other applicable laws may vary.

The project is **unofficial**, not endorsed by any OEM supplier. It
does not claim an official device/format standard.

When intended for children, check print quality, safe edges, detachable parts,
and device fit; home-printed components are not automatically certified as toys.


## License

This project's original OpenSCAD model, Python generator,
and supporting source files are released under the
MIT License.

See [LICENSE](LICENSE) for the full license text.

The MIT License permits modification, redistribution,
private use, and commercial use, subject to preservation
of the required copyright and license notices.

The software is provided without warranty.

This license applies only to the original project code
and documentation. It does not grant rights to third-party
trademarks, copyrighted audio, firmware, proprietary
designs, or protected content.

The project is independently developed and is not
affiliated with any device manufacturer.


