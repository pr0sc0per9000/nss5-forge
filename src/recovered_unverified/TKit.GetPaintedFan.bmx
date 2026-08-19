' TKit.GetPaintedFan
' VA 0x004db79e   1569 bytes   vtable slot 0x40   sig (i,i):TPixmap   KIND=Method
' byte-identical vs NSS5.exe
'
' Paints a COPY of Self.pixmap (the crowd/"fan" base mask image): every pixel whose RGB
' matches one of the 24 base/mask colours g_kit_arr02[0..23] (built by TKit.SetUp from
' Engine.ini's base*/mask keys, see TKit.SetUp.bmx) is replaced by the matching real
' colour. Index 0 is the background mask colour (left untouched). Indices 1..11 map to
' Self.newcol[1..11] (this kit's own shirt/shorts/socks shades -- exactly the slots
' TKit.CreateKit populates). Indices 12..14 map to a 3-shade grey "boot" ramp seeded
' from the same literal "444444" TKit.CheckBlack substitutes (base, -30, -60). Indices
' 15..17 map to a 3-shade hair ramp seeded from GetHexHairCol(a1) (base, -20, -40 --
' identical deltas to CreateKit's own shading). Indices 18..23 map to a 6-shade skin
' ramp seeded from GetHexSkinColour(a0) (base, then -8,-16,-24,-32,-40 cumulative).
'
' ASSUMPTIONS
'  Self-method calls dispatch through *Self+slot (bare, unqualified -- calling a sibling
'  Function of the same Type from within a Method goes through the vtable, unlike a
'  Function-to-Function call which uses a fixed class-table address; see TKit.CreateKit
'  vs this body): 0x44 GetRandHexHairColour(i)$ (result discarded), 0x48
'  GetHexHairCol(i)$, 0x4c GetHexSkinColour(i)$, 0x54 ColorInt(i,i,i,i)i.
'  Module Functions: 0x0050661a ShiftColourHex(String,Int)String (src/recovered_module).
'  BRL Functions, named via extracted/decomp_annotated's per-function legend: 0x005b2109
'  CopyPixmap(:TPixmap):TPixmap, 0x005b2173 PixmapPixelPtr(:TPixmap,i,i):Byte Ptr.
'  The hex-component pattern `px[n] = Int("$"+colstr[a..b])` mirrors ParseColourHex.bmx
'  exactly (_bbStringSlice/_bbStringConcat/_bbStringToInt through the same "$" constant
'  at 0x00C7529C).
'  Global 0x00C5C1EC = g_kit_arr02:Int[] (TKit.SetUp.bmx already banked this Global).
'  The literal "444444" at 0x00C752AC decodes via harness.read_string -- the same
'  literal TKit.CheckBlack.bmx substitutes for "000000".
'  Two magic ColorInt results appear as raw CMP immediates (not calls, so they must be
'  literal constants, not runtime ColorInt(...) calls): -8388480 ($FF800080, ColorInt
'  for RGB 128,0,128) and -65281 ($FFFF00FF, ColorInt for RGB 255,0,255) -- in-image
'  directives painted into the source pixmap. -8388480 forces "x = pm.width" (the
'  outer/x For-loop's own bound, re-read fresh, not the cached loop-entry value) plus
'  "y :+ 128"; the loop mechanics alone then behave as an immediate stop (both loops
'  exit past their bounds, falling straight to Return). -65281 is "x :+ 128" alone --
'  skip 128 pixels ahead in this row, presumably to jump a padding/frame-boundary block.
'
' SHAPE NOTES
'  The three shade ramps are Local fixed-size array declarations (`Local x:String[N]`),
'  NOT array literals -- each shade is read back FROM the array it was just written
'  into (`skin[1] = ShiftColourHex(skin[0], -8)`), exactly the "re-reads the array
'  element every time" idiom documented in TKit.CreateKit.bmx (bcc does no CSE).
'  Construction order is boot(3), then skin(6, seeded from the skin-colour Local),
'  then hair(3, seeded from the hair-colour Local).
'  Parameter names are harness placeholders (a0, a1); not recoverable from the binary.
'
' SCORE-GUIDED FIX (this pass, superseding the previous one): status/score showed our
' body 78 bytes SHORTER than the original and, per codegen-patterns.md #10.2 ("If the
' decompilation shows a run of cmp/je with every target past the LAST compare, it is a
' Select"), disassembling the original directly (bytematch.disasm_original) proves the
' whole 26-way colour dispatch -- BOTH sentinel checks AND all 24 g_kit_arr02 indices --
' is ONE flat `Select c`, not the nested If/ElseIf the previous draft used:
'   * every one of the 26 tests (2 sentinel cmp's, then 24 back-to-back
'     `mov edx,[g_kit_arr02]; cmp eax,[edx+off]; je Body_n` reloading the Global fresh
'     each time, index ascending 0x18,0x1C,...,0x74) runs BEFORE any handler body, ending
'     in one unconditional `jmp` for the no-match default -- textbook Select shape.
'   * all handler bodies live AFTER the test cluster. Cases matching g_kit_arr02[1..23]
'     each do only `newc = <source>` (no incref/decref at all -- newc is never spilled,
'     it stays live in a register, EBX, freed up once a0's own last use has passed) and
'     fall out of the Select (implicit break) into ONE shared, single copy of the
'     `px[0]=Int("$"+newc[0..2])` / `px[1]=...` / `px[2]=...` tail placed right after
'     `End Select` -- proof the source really has one `newc` read three times after the
'     Select, not 23 duplicated px-write blocks.
'   * the two sentinel cases and `Case g_kit_arr02[0]` (the mask colour) each jump to a
'     DIFFERENT, later address than the Case-1..23 fallthrough -- the true y-loop
'     continuation point, past the px-write tail entirely -- so each of those three
'     bodies ends with an explicit `Continue`, and so does `Default` (no match among all
'     26 tests): the decompiled tail `if (c != g_kit_arr02[23]) goto <loop-continue>` is
'     literally the Select's own default-case exit, not a residual `Else`.
'!Global g_kit_arr02:Int[]
		Local basecol:String = "444444"
		Local skincol:String = GetHexSkinColour(a0)
		If a1 = -1 Then GetRandHexHairColour(a0)
		Local haircol:String = GetHexHairCol(a1)

		Local boot:String[3]
		boot[0] = basecol
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

		Local pm:TPixmap = CopyPixmap(pixmap)
		For Local x:Int = 0 To pm.width - 1
			For Local y:Int = 0 To pm.height - 1
				Local px:Byte Ptr = PixmapPixelPtr(pm, x, y)
				Local c:Int = ColorInt(px[0], px[1], px[2], 255)
				Local newc:String
				Select c
					Case -8388480
						x = pm.width
						y :+ 128
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
					Default
						Continue
				End Select
				px[0] = Int("$" + newc[0..2])
				px[1] = Int("$" + newc[2..4])
				px[2] = Int("$" + newc[4..6])
			Next
		Next
		Return pm
