# How a nation flag becomes a button

> **Source:** `TNation.ButtonizeFlag` @ 0x004bf221 (VERIFIED) · `TScreen_Continents.ComboTeam` @ 0x0051bc09 (READ) · `TNation.LoadData` @ 0x004bd649 (READ)
> **Confidence:** HIGH
> **Last checked:** 2026-08-23

The nation flags in New Star Soccer 5 are shipped as plain rectangles. The rounded,
shaded flag buttons you see in the continent and nation pickers are not artwork - the
game generates them at load time from the flat flag image, with one function, and it
edits the flag's own pixels in place. This is the whole of that recipe, with the numbers.

## The two things it does

`ButtonizeFlag` takes a flag image and does exactly two passes over its pixels:

**1. A vertical light-to-dark gradient.** Every pixel in a row gets the *same* brightness
offset added to its red, green and blue channels alike. The offset is **-50 on the bottom
row** and climbs by **+3 for every row going up**. So on a 34-pixel-tall flag the bottom
row is darkened by 50 and the top row is brightened by 49; the crossover to "brighter than
the original" happens 17 rows up. The offset does not depend on the column, so every column
gets the identical ramp - this is a flat top-lit sheen, not a highlight or a bevel.

Each channel is clamped back into 0-255 *after* the add, so a white flag's top simply
saturates to white rather than wrapping round to black. Alpha is forced to **255** across
this whole pass, so whatever transparency the source flag had is discarded.

**2. Rounded corners, done with alpha.** A fixed 6x6 table of alpha values is stamped into
each of the four corners. Indexed as `[distance from the corner's edge column][distance
from the corner's edge row]`, the table is:

|             | row 0 | row 1 | row 2 | row 3 | row 4 | row 5 |
|---|---|---|---|---|---|---|
| **col 0**   | 0   | 0   | 0   | 0   | 128 | 192 |
| **col 1**   | 0   | 0   | 64  | 192 | 255 | 255 |
| **col 2**   | 0   | 64  | 255 | 255 | 255 | 255 |
| **col 3**   | 0   | 192 | 255 | 255 | 255 | 255 |
| **col 4**   | 128 | 255 | 255 | 255 | 255 | 255 |
| **col 5**   | 192 | 255 | 255 | 255 | 255 | 255 |

Zero means fully transparent. The outermost column and the outermost row are transparent
for their first four pixels, and the mask is fully opaque from three pixels in - so the
visible result is a corner radius of roughly 3-4 pixels with a one-pixel soft edge. RGB is
read and written back unchanged here; only alpha moves.

The same table serves all four corners: the code walks x and/or y backwards from
`width - 1` / `height - 1` for the right-hand and bottom corners, so the mask is mirrored
rather than duplicated. That means the rounding is identical on all four corners
regardless of the flag's size, and a flag narrower than 12 pixels or shorter than 12 pixels
would have its corner masks overlap in the middle.

## It modifies the flag you passed in

There is no copy and no return value. The function locks the image's pixmap for read and
write, edits it, and unlocks - so after the call the caller's `TImage` *is* the button.
Any code still expecting the raw rectangular flag after this point gets the button instead.
That is why a flag is buttonised once, on load, rather than per draw.

## The debug dump

The second parameter is a developer switch. When it is non-zero the finished pixmap is
written out as
`GameMedia/Images/ButtonNationIm_<n>.png`, where `n` comes from BlitzMax's `Rand(999)` -
that is `Rand(minValue:999, maxValue:1)` with the default second argument, so `n` lands
somewhere in 1-999 and successive dumps overwrite each other roughly one time in a
thousand. Both call sites are in the continent/nation screen setup path
(`0x0051be9f` and `0x0051fc88`); we have not confirmed what either passes, so whether
this ever fires in the shipped game is **unverified** - but nothing in the retail
`GameMedia/Images/` directory is named this way, which is consistent with it being off.
