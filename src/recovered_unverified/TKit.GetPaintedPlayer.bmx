' TKit.GetPaintedPlayer
' VA 0x004db0dd   1729 bytes   vtable slot 0x3c   sig ($,i,i,$):TPixmap   KIND=Method
' MATCH 1729/1729 (mode=reloc, reloc_masked=75) verified via harness.try_method under
' NSS5_WORKER=refine2_gpp. Still filed in recovered_unverified pending promotion by the
' pipeline; nothing else in this header block needs re-checking.
'
' REFINEMENT PASS (this session): prior body scored 48.1% (791/1643), 86 bytes short,
' first difference at byte 29 (a spilled Local's stack slot). scripts/localise_diff.py
' isolated the ENTIRE deficit to one place: the "which of the 26 known colours is this
' pixel" dispatch. The prior body wrote it as a flat If/ElseIf (mirroring Ghidra's C,
' which always normalises Select back to If/ElseIf -- see codegen-patterns.md 10.2). The
' original disassembly shows all 27 tests (two sentinels, the mask colour, then
' g_kit_arr02[1..25]) emitted back-to-back as `mov edx,[g_kit_arr02]; cmp eax,[edx+off];
' je <body>`, THEN every matched body afterward as a short `mov ...; jmp <shared tail>` --
' textbook Select/Case codegen, not interleaved test+body. Converting the cascade to a
' real `Select c` (below) dropped the length delta from -86 to 0 and, as a side effect,
' also fixed every one of the 22 stack-slot substitutions the old If/ElseIf shape had
' caused elsewhere in the frame (skincol, the array-pointer Locals, pm) -- confirming
' those were downstream consequences of the wrong control-flow shape, not independent
' bugs. `Default: Continue` is required (not "no Default"): the no-match path is its own
' distinct `jmp` in the original, separate from the mask colour's `Case g_kit_arr02[0]:
' Continue`, which is also its own distinct case rather than being folded into Default.
'
' Paints a COPY of Self.pixmap (the player base/mask image): every pixel whose RGB
' matches one of the 26 base/mask colours g_kit_arr02[0..25] (built by TKit.SetUp) is
' replaced by the matching real colour. Index 0 is the background mask colour (left
' untouched). Indices 1..11 map to Self.newcol[1..11] (this kit's own shirt/shorts/socks
' shades -- exactly the slots TKit.CreateKit populates). Indices 12..14 map to a 3-shade
' boot ramp seeded from a0 (bootcol, supplied by the caller -- TPlayer.PaintPlayer.bmx
' passes Self.bootcol here, unlike sibling GetPaintedFan, whose boot ramp is seeded from
' the fixed literal "444444" since a fan has no boots). Indices 15..17 map to a 3-shade
' hair ramp seeded from GetHexHairCol(a2) (base, -20, -40). Indices 18..23 map to a
' 6-shade skin ramp seeded from GetHexSkinColour(a1) (base, then -8,-16,-24,-32,-40
' cumulative). Indices 24..25 map to a 2-shade glove ramp seeded from a3 (glovecol,
' base, -20) -- the one part of the palette GetPaintedFan has no equivalent for.
'
' ASSUMPTIONS
'  Self-method calls dispatch through *Self+slot (bare, unqualified -- calling a sibling
'  Function of the same Type from within a Method goes through the vtable, same as
'  GetPaintedFan.bmx and TKit.SetUp.bmx): 0x44 GetRandHexHairColour(i)$ (result
'  discarded), 0x48 GetHexHairCol(i)$, 0x4c GetHexSkinColour(i)$, 0x54 ColorInt(i,i,i,i)i.
'  Module Functions: 0x0050661a ShiftColourHex(String,Int)String, 0x00505b91
'  LogLine(String) (both src/recovered_module).
'  BRL Functions, per extracted/decomp_annotated's per-function legend: 0x005b2109
'  CopyPixmap(:TPixmap):TPixmap, 0x005b2173 PixmapPixelPtr(:TPixmap,i,i):Byte Ptr.
'  The hex-component pattern `px[n] = Int("$"+colstr[a..b])` mirrors GetPaintedFan
'  exactly (_bbStringSlice/_bbStringConcat/_bbStringToInt through the "$" constant at
'  0x00C7529C).
'  Global 0x00C5C1EC = g_kit_arr02:Int[] (explain_global.py: STRONG tier, forced in the
'  one body that declares it, TKit.SetUp.bmx).
'  The literal at 0x00C75278 decodes to "BOOTCOL:" per decomp_annotated's SYM table
'  (harness.read_string) -- LogLine("BOOTCOL:" + a0) is a debug line logging the boot
'  colour used; its own result is otherwise unused.
'  0x00C75294/96/98/9A are just the _bbArrayNew1D type-tag operands for the four Local
'  fixed-size String arrays (sizes 3, 6, 3, 2) -- not user-meaningful data, so they need
'  no source-level representation beyond the array declarations themselves.
'
' SHAPE NOTES
'  Signature params, in order: a0:$ = bootcol, a1:i = skincol index, a2:i = haircol
'  index, a3:$ = glovecol -- matches TPlayer.PaintPlayer.bmx's own call,
'  `a0.GetPaintedPlayer(bootcol, skincol, haircol, glovecol)`.
'  `If a2 = -1 Then GetRandHexHairColour(a1)` -- note the arg passed is a1 (the SKIN
'  index), not a2, exactly mirroring GetPaintedFan's own odd
'  `If a1 = -1 Then GetRandHexHairColour(a0)`; the call's return value is discarded
'  either way, and GetHexHairCol(a2) is always evaluated afterward regardless of the
'  a2 = -1 branch having run.
'  The four shade ramps are Local fixed-size array declarations (`Local x:String[N]`),
'  NOT array literals -- each shade is read back FROM the array it was just written
'  into, the same "re-reads the array element every time" idiom as TKit.CreateKit and
'  GetPaintedFan (bcc does no CSE). Construction order is boot(3), skin(6, seeded from
'  skincol), hair(3, seeded from haircol), glove(2, seeded from a3) -- NOT
'  declaration/use order.
'  UNLIKE GetPaintedFan (X-outer / Y-inner), this loop nests Y-outer / X-inner: the
'  outer bound is Self.pixmap's height (pixmap+0x10), the inner bound is its width
'  (pixmap+0xc), and PixmapPixelPtr is called (pm, x, y) with x the INNER loop variable.
'  Consequently the two sentinel colours only ever touch x: c=-8388480 sets
'  `x = pm.width` (ends the CURRENT row's inner loop only -- the outer loop then simply
'  moves on to the next y, unlike GetPaintedFan's X-outer version where the same trick
'  aborts the whole double loop) and c=-65281 does `x :+ 128` alone (GetPaintedFan's
'  -8388480 branch also bumps its own inner var; this one does not touch y at all).
'  The WHOLE per-pixel dispatch -- both sentinels, the mask colour, and all 25 real
'  g_kit_arr02 indices -- is ONE `Select c`, not an outer If wrapping an inner cascade
'  (see the REFINEMENT PASS note above). `newc` is declared once, immediately before the
'  Select, so it is visible both inside the Case bodies and in the three px[] statements
'  that follow `End Select` -- those three statements run only for Cases 1..25, which
'  fall out of the Select normally; the two sentinel Cases, the mask-colour Case, and
'  Default all bypass them with an explicit `Continue`, matching the inner for-loop's
'  own continuation point one-for-one with the original's four independent jumps there.
'  A pixel equal to the mask colour (index 0) or to none of the 26 known colours is left
'  untouched (Case g_kit_arr02[0] and Default both do nothing but Continue).
'  Parameter names are harness placeholders (a0..a3); not recoverable from the binary.
'!Global g_kit_arr02:Int[]
		Local skincol:String = GetHexSkinColour(a1)
		If a2 = -1 Then GetRandHexHairColour(a1)
		Local haircol:String = GetHexHairCol(a2)
		LogLine("BOOTCOL:" + a0)

		Local boot:String[3]
		boot[0] = a0
		boot[1] = ShiftColourHex(boot[0], -30)
		boot[2] = ShiftColourHex(boot[1], -60)

		Local skin:String[6]
		skin[0] = skincol
		skin[1] = ShiftColourHex(skin[0], -8)
		skin[2] = ShiftColourHex(skin[1], -16)
		skin[3] = ShiftColourHex(skin[2], -24)
		skin[4] = ShiftColourHex(skin[3], -32)
		skin[5] = ShiftColourHex(skin[4], -40)

		Local hair:String[3]
		hair[0] = haircol
		hair[1] = ShiftColourHex(hair[0], -20)
		hair[2] = ShiftColourHex(hair[1], -40)

		Local glove:String[2]
		glove[0] = a3
		glove[1] = ShiftColourHex(glove[0], -20)

		Local pm:TPixmap = CopyPixmap(pixmap)
		For Local y:Int = 0 To pm.height - 1
			For Local x:Int = 0 To pm.width - 1
				Local px:Byte Ptr = PixmapPixelPtr(pm, x, y)
				Local c:Int = ColorInt(px[0], px[1], px[2], 255)
				Local newc:String
				Select c
				Case -8388480
					x = pm.width
					Continue
				Case -65281
					x :+ 128
					Continue
				Case g_kit_arr02[0]
					Continue
				Case g_kit_arr02[1]
					newc = newcol[1]
				Case g_kit_arr02[2]
					newc = newcol[2]
				Case g_kit_arr02[3]
					newc = newcol[3]
				Case g_kit_arr02[4]
					newc = newcol[4]
				Case g_kit_arr02[5]
					newc = newcol[5]
				Case g_kit_arr02[6]
					newc = newcol[6]
				Case g_kit_arr02[7]
					newc = newcol[7]
				Case g_kit_arr02[8]
					newc = newcol[8]
				Case g_kit_arr02[9]
					newc = newcol[9]
				Case g_kit_arr02[10]
					newc = newcol[10]
				Case g_kit_arr02[11]
					newc = newcol[11]
				Case g_kit_arr02[12]
					newc = boot[0]
				Case g_kit_arr02[13]
					newc = boot[1]
				Case g_kit_arr02[14]
					newc = boot[2]
				Case g_kit_arr02[15]
					newc = hair[0]
				Case g_kit_arr02[16]
					newc = hair[1]
				Case g_kit_arr02[17]
					newc = hair[2]
				Case g_kit_arr02[18]
					newc = skin[0]
				Case g_kit_arr02[19]
					newc = skin[1]
				Case g_kit_arr02[20]
					newc = skin[2]
				Case g_kit_arr02[21]
					newc = skin[3]
				Case g_kit_arr02[22]
					newc = skin[4]
				Case g_kit_arr02[23]
					newc = skin[5]
				Case g_kit_arr02[24]
					newc = glove[0]
				Case g_kit_arr02[25]
					newc = glove[1]
				Default
					Continue
				End Select
				px[0] = Int("$" + newc[0..2])
				px[1] = Int("$" + newc[2..4])
				px[2] = Int("$" + newc[4..6])
			Next
		Next
		Return pm
