' TKit.CreateKit
' VA 0x004DAE38   677 bytes   vtable slot 0x38   sig (:TKitStrings,$):TKit   KIND=Function
' byte-identical vs NSS5.exe (677/677, original length from Ghidra's inventory)
' Builds a TKit from a TKitStrings colour set, deriving two darker shades per garment.
'
' ASSUMPTIONS
'  Direct calls resolved: 0x004A6A30 _bbStringCompare, 0x004A75B0 _bbStringReplace
'    (-> String.Replace), 0x004A8F20 _bbObjectNew (-> New TKit), 0x004A8590 _bbGCFree
'    (inlined BBRELEASE, never written in source), 0x0050661A ShiftColourHex and
'    0x004BC46D LoadPixmapChecked (both src/recovered_module/).
'  Class-table slot calls: 0x00C5C4B0 TKit+0x30 SetUp(), 0x00C5C4D0 TKit+0x50
'    CheckBlack(*$) -- a Var String parameter, so the argument is written plainly;
'    TKitStrings slot 0x40 = GetFileName()$.
'  Module Global 0x00C5C1E4 declared String[]: globals_final says Object[], but element 0
'    is handed straight to _bbStringCompare against "" with no downcast, which types it.
'  Field offsets from extracted/object_model.json: TKitStrings style 0x08, shirt1 0x0C,
'    shirt2 0x10, shorts 0x14, socks 0x18; TKit pixmap 0x08, style 0x0C, newcol 0x10.
'    newcol data starts at +0x18, so [eax+0x1C] is newcol[1] -- index 0 is never written.
'  The '!Field pragma mirrors TKit.New: Field newcol:String[24].
'  ShiftColourHex deltas are the signed immediates 0xFFFFFFEC = -20 and 0xFFFFFFD8 = -40.
' SHAPE NOTES (byte-observable)
'  * The Replace result is stored back into the PARAMETER (`mov [ebp+0xc],eax`), not into a
'    new Local -- the prologue has no `sub esp` at all, so the function declares exactly one
'    Local (k, in ebx) and no stack slots.
'  * Each newcol shade is derived from the SLOT JUST WRITTEN (newcol[2] from newcol[1], not
'    from a0.shirt1) -- the original re-reads the array element every time; bcc does no CSE.
	Function CreateKit:TKit(a0:TKitStrings, a1:String)
		'!Field newcol:String[24]
		'!Global g_kitfiles:String[]
		If g_kitfiles[0] = "" Then TKit.SetUp()
		a1 = a1.Replace("Player.png", a0.GetFileName())
		TKit.CheckBlack(a0.shirt1)
		TKit.CheckBlack(a0.shirt2)
		TKit.CheckBlack(a0.shorts)
		TKit.CheckBlack(a0.socks)
		Local k:TKit = New TKit
		k.style = a0.style
		k.newcol[1] = a0.shirt1
		k.newcol[2] = ShiftColourHex(k.newcol[1], -20)
		k.newcol[3] = ShiftColourHex(k.newcol[2], -40)
		k.newcol[4] = a0.shirt2
		k.newcol[5] = ShiftColourHex(k.newcol[4], -20)
		k.newcol[6] = ShiftColourHex(k.newcol[5], -40)
		k.newcol[7] = a0.shorts
		k.newcol[8] = ShiftColourHex(k.newcol[7], -20)
		k.newcol[9] = ShiftColourHex(k.newcol[8], -40)
		k.newcol[10] = a0.socks
		k.newcol[11] = ShiftColourHex(k.newcol[10], -40)
		k.pixmap = LoadPixmapChecked(a1)
		Return k
	End Function
