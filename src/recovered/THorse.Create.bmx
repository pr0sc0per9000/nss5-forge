' THorse.Create
' VA 0x0058a36b   1372 bytes   class-table slot 0x30   sig (i,$,f,f,f,[]i,i,i,i,i):THorse   KIND=Function (static)
' ORACLE: mode=reloc  matched=1372/1372  STATUS=MATCH.  NSS5_NO_LEARN not set (default corpus run).
'
' Lazy static asset init (guarded by g_horse_shadow, the FIRST global touched) followed by a
' plain field-by-field constructor. Two codegen lessons paid for the byte count:
'   * `If Not g_horse_shadow` (NOT `If g_horse_shadow = Null`) -- the 21-byte setne/movzx/cmp
'     form (guide 10.3), confirmed against the original's own inverted-branch shape.
'   * The colour dispatch at the end is a `Select`, not `If/ElseIf` -- textbook tell from
'     10.2: four `cmp eax,N`/`je` back to back with every jump target PAST the last compare,
'     then a single `jmp` to the shared "else" (Null) path. As If/ElseIf this body was
'     1366/1372 (6 bytes short, one `cmp [mem],N` per case instead of a cached `cmp eax,N`).
' No explicit `Return h` -- the original genuinely discards the constructed instance and
' falls through to `Return Null` (bcc's default for a bare-`Return`-less ()i-shaped method,
' guide 6). ORIGINAL BUG: the freshly-built THorse is never handed back to the caller through
' the return value; whatever THorse.Create's caller relies on, it is not this return.
'
' Globals (NAMES OURS; declared TYPE is load-bearing -- ClassTable+0x18/1c/20/24 element
' loads with real retain/release traffic type both arrays TImage[], matching every write site
' -- LoadAnimImageChecked's own return type):
'   0x00C6E950 g_pathPrefix:String        (same slot every asset-loader in the corpus uses)
'   0x00C6E2A8 g_horse_arr:TImage[]        4 elements, Horse_01..04
'   0x00C6E2B8 g_screen_stable_arr05:TImage[]  6 elements, Jockey_01..06 (TScreen_Stable's own)
'   0x00C6E2BC g_horse_shadow:TImage       (globals_final.tsv: g_Object852, guard variable)
'   0x00C6E2C0 g_horse_arrowd:TImage       (g_Object853)
'   0x00C6E2C4 g_horse_star:TImage         (g_Object854)
' Field offsets (object_model.json THorse): +0x34 id, +0x38 name, +0x3c energy, +0x40 health,
' +0x44 strength, +0x48 form([]i), +0x4c prize, +0x50 owned, +0x54 lastran, +0x58 colour,
' +0x08 image (the Select target).
' LoadAnimImageChecked/LoadImageChecked (src/recovered_module) supply the Loading/incbin
' machinery; every literal path below was read out of NSS5.exe with harness.read_string.
'!Global g_pathPrefix:String
'!Global g_horse_arr:TImage[]
'!Global g_screen_stable_arr05:TImage[]
'!Global g_horse_shadow:TImage
'!Global g_horse_arrowd:TImage
'!Global g_horse_star:TImage
	Function Create:THorse(a0:Int, a1:String, a2:Float, a3:Float, a4:Float, a5:Int[], a6:Int, a7:Int, a8:Int, a9:Int)
		If Not g_horse_shadow
			g_horse_shadow = LoadAnimImageChecked(g_pathPrefix + "GameMedia/Images/Stable/Horse/Shadow.png", 128, 100, 0, 8, -1)
			SetImageHandle(g_horse_shadow, 128.0, 0)
			g_horse_arr[0] = LoadAnimImageChecked(g_pathPrefix + "GameMedia/Images/Stable/Horse/Horse_01.png", 128, 80, 0, 8, -1)
			g_horse_arr[1] = LoadAnimImageChecked(g_pathPrefix + "GameMedia/Images/Stable/Horse/Horse_02.png", 128, 80, 0, 8, -1)
			g_horse_arr[2] = LoadAnimImageChecked(g_pathPrefix + "GameMedia/Images/Stable/Horse/Horse_03.png", 128, 80, 0, 8, -1)
			g_horse_arr[3] = LoadAnimImageChecked(g_pathPrefix + "GameMedia/Images/Stable/Horse/Horse_04.png", 128, 80, 0, 8, -1)
			For Local i:Int = 0 To 3
				SetImageHandle(g_horse_arr[i], 128.0, 0)
			Next
			g_screen_stable_arr05[0] = LoadAnimImageChecked(g_pathPrefix + "GameMedia/Images/Stable/Jockey/Jockey_01.png", 128, 80, 0, 8, -1)
			g_screen_stable_arr05[1] = LoadAnimImageChecked(g_pathPrefix + "GameMedia/Images/Stable/Jockey/Jockey_02.png", 128, 80, 0, 8, -1)
			g_screen_stable_arr05[2] = LoadAnimImageChecked(g_pathPrefix + "GameMedia/Images/Stable/Jockey/Jockey_03.png", 128, 80, 0, 8, -1)
			g_screen_stable_arr05[3] = LoadAnimImageChecked(g_pathPrefix + "GameMedia/Images/Stable/Jockey/Jockey_04.png", 128, 80, 0, 8, -1)
			g_screen_stable_arr05[4] = LoadAnimImageChecked(g_pathPrefix + "GameMedia/Images/Stable/Jockey/Jockey_05.png", 128, 80, 0, 8, -1)
			g_screen_stable_arr05[5] = LoadAnimImageChecked(g_pathPrefix + "GameMedia/Images/Stable/Jockey/Jockey_06.png", 128, 80, 0, 8, -1)
			For Local i:Int = 0 To 5
				SetImageHandle(g_screen_stable_arr05[i], 128.0, 0)
			Next
			g_horse_arrowd = LoadImageChecked(g_pathPrefix + "GameMedia/Images/Stable/ArrowD.png", -1)
			g_horse_star = LoadImageChecked(g_pathPrefix + "GameMedia/Images/Stable/Star.png", -1)
		EndIf
		Local h:THorse = New THorse
		h.id = a0
		h.name = a1
		h.energy = a2
		h.health = a3
		h.strength = a4
		h.form = a5
		h.prize = a6
		h.owned = a7
		h.lastran = a8
		h.colour = a9
		Select h.colour
			Case 1
				h.image = g_horse_arr[0]
			Case 2
				h.image = g_horse_arr[1]
			Case 3
				h.image = g_horse_arr[2]
			Case 4
				h.image = g_horse_arr[3]
		End Select
	End Function
