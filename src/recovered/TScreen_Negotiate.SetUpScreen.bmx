' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_Negotiate.SetUpScreen  -- KIND=Function (static method on TScreen_Negotiate), slot 0x34
' VA 0x0057A477   581 bytes   sig (:TContractOffer)i
' byte-identical vs NSS5.exe (581/581, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=45)
'
' ASSUMPTIONS
'  Module Globals declared (names are ours; the TYPES are load-bearing -- each one selects
'  the vtable slot for the calls made through it):
'    0x00C6CC3C g_offer      : TContractOffer  (table says "Object"; the parameter is
'                              :TContractOffer and the store is a plain retain/release
'                              assignment of a0, so the type follows from the signature)
'    0x00C5B1C8 g_font       : TBitmapFont     (table: construction, medium)
'    0x00C6EFE4 g_screen_w   : Int   0x00C6EFE8 g_screen_h : Int  (bare movs, no refcounts;
'      named with the underscore to match the address family TScreen_Negotiate.Fail.bmx and
'      TScreen_Negotiate.Success.bmx already use for the same TScreenMessage.Create pattern --
'      "g_screenw"/"g_screenh" without the underscore is a different pair, 0x00C6EFDC/E0, the
'      800x600 design-resolution constant TScreen.Draw@00510dfc reads for its own viewport)
'    0x00C6CC40 g_selected   : Int
'    0x00C6CC50 g_nums       : Int[]   (table says Object[]; every element is used as an
'                              array subscript and assigned from Rand -> Int[], cf. 11.2)
'    0x00C6CC38 g_btns       : TButton[]  (slots 0x90 SetIcon / 0x6C SetColour / 0x70
'                              SetAlph all resolve on TButton/TGadget)
'    0x00C6CC1C g_icons      : TImage[]   (indexed by g_nums, passed to SetIcon)
'    0x00C6CC20 g_icon       : TImage
'    0x00C6CBFC g_btnAccept  : TButton   0x00C6CC00 g_btnReject : TButton
'    0x00C6CC10 g_btnWait    : TButton   0x00C6CC0C g_btnMore   : TButton
'    0x00C6F028 g_profile    : TProfile  (table: construction, high, 3 sites; +0x1C8 is
'                              TProfile.helppages:Int[], which corroborates it)
'  Class-table slots resolved:
'    [0x00C61C88] = TScreen + 0x5C          = SetActive($,$):TScreen (result discarded)
'    [0x00C6B264] = TScreenMessage + 0x30   = Create(i,i,$,i,:TBitmapFont,:TImage,f,$)i
'    [0x00C6CDC4] = TScreen_Negotiate + 0x4C = UpdateInstrucs()i
'    [0x00C61CE0] = TScreen + 0xB4          = Tutorial()i
'    TButton 0x90 SetIcon(:TImage), 0x70 SetAlph(f); TGadget 0x6C SetColour($,$),
'    0x54 Hide(); TGadget.alive is +0x38.
'  Direct calls resolved: 0x004C5549 -> GetText; 0x0059F089 -> Rand.
'    Rand is pushed as (11, 1); `Rand(11)` and `Rand(11, 1)` are byte-identical because 1
'    is max_value's default, so which was written cannot be decided from the bytes.
'  helppages[9]: the element read is at array-object +0x3C and BBArray data starts at
'  +0x18, so the index is (0x3C-0x18)/4 = 9.
'  All string literals are absolute data addresses, so their TEXT is not recoverable --
'  "negotiate", "negotiate_msg" and "FFFF00" are guesses. What IS proven: the two
'  SetColour arguments inside the loop are the SAME constant that is used as the trailing
'  argument of TScreenMessage.Create, and the highlighted button gets a DIFFERENT first
'  colour constant.
'  Ghidra prints Create() with six arguments; the disassembly shows eight pushes and a
'  separate one-argument GetText call in the middle -- the merged-argument trap of the
'  guide's preamble.

	Function SetUpScreen:Int(a0:TContractOffer)
		'!Global g_offer:TContractOffer
		'!Global g_screen_w:Int
		'!Global g_screen_h:Int
		'!Global g_font:TBitmapFont
		'!Global g_selected:Int
		'!Global g_nums:Int[]
		'!Global g_btns:TButton[]
		'!Global g_icon:TImage
		'!Global g_icons:TImage[]
		'!Global g_btnAccept:TButton
		'!Global g_btnReject:TButton
		'!Global g_btnWait:TButton
		'!Global g_btnMore:TButton
		'!Global g_profile:TProfile
		g_offer = a0
		TScreen.SetActive("negotiate", "")
		TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2, GetText("Negotiate!"), ..
			1500, g_font, Null, 1.0, "FFFFFF")
		g_selected = 1
		For Local i:Int = 1 To 5
			g_nums[i] = 0
		Next
		Local ok:Int
		For Local i:Int = 1 To 5
			Repeat
				ok = 1
				g_nums[i] = Rand(11)
				For Local j:Int = 1 To i - 1
					If g_nums[i] = g_nums[j] Then ok = 0
				Next
			Until ok
			g_btns[i].SetIcon(g_icon)
			g_btns[i].SetColour("FFFFFF", "FFFFFF")
		Next
		g_btns[g_selected].SetColour("00FF00", "FFFFFF")
		g_btns[g_selected].SetIcon(g_icons[g_nums[g_selected]])
		g_btnAccept.alive = 1
		g_btnAccept.SetAlph(1.0)
		g_btnReject.alive = 1
		g_btnReject.SetAlph(1.0)
		g_btnWait.Hide()
		g_btnMore.alive = 0
		g_btnMore.SetAlph(0.5)
		TScreen_Negotiate.UpdateInstrucs()
		If g_profile.helppages[9] = 0
			TScreen.Tutorial()
			g_profile.helppages[9] = 1
		End If
	End Function
