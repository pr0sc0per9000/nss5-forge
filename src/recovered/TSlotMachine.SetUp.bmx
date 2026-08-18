' TSlotMachine.SetUp  -- KIND=Function (static method on the Type), SLOT=0x30
' VA 0x005781B1   413 bytes   sig ()i
' byte-identical vs NSS5.exe (413/413, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=41)
'
' ASSUMPTIONS
'   * GLOBAL NAMES ARE OURS (module Globals have no debug record). Declared types are
'     load-bearing because they select the vtable slot / refcount behaviour:
'         0x00C6E950  g_pathPrefix :String   -- the shared asset path prefix, same Global
'                                               LoadImageChecked / LoadSoundChecked use
'         0x00C6C54C  g_slotglass  :TImage
'         0x00C6C550  g_slotwin    :TSound
'         0x00C6C554  g_slotarm    :TSound
'         0x00C6C558  g_slotstrip1 :TSlotStrip
'         0x00C6C55C  g_slotstrip2 :TSlotStrip
'         0x00C6C560  g_slotstrip3 :TSlotStrip
'   * The guard tests the SOUND Global (0x00C6C550), not the image, and it is the
'     `If Not x` spelling, not `If x = Null`: the original has
'     `cmp eax,0x5c9c80 / setne al / movzx eax,al / cmp eax,0 / jne` (21 bytes).
'     `If g_slotwin = Null` gives 404 bytes; `If Not g_slotwin` gives 413. (guide 10.3)
'   * Callees resolved: FUN_004BC372 = LoadImageChecked($,i), FUN_004BC564 =
'     LoadSoundChecked($,i), FUN_004A7C20 = String concat, FUN_004A8F20 = New <Type>,
'     FUN_004A8590 = the GC free inside inlined BBRELEASE (never written in source).
'   * TSlotStrip slot 0x30 = SetUp(i,i) from vtable_map.tsv.
'   * String literals read out of the exe with harness.read_string(); the oracle masks
'     literal ADDRESSES, so their contents are not certified by the MATCH.
'!Global g_pathPrefix:String
'!Global g_slotglass:TImage
'!Global g_slotwin:TSound
'!Global g_slotarm:TSound
'!Global g_slotstrip1:TSlotStrip
'!Global g_slotstrip2:TSlotStrip
'!Global g_slotstrip3:TSlotStrip
	Function SetUp()
		If Not g_slotwin
			g_slotglass = LoadImageChecked(g_pathPrefix + "GameMedia/Images/Casino/Slots/Glass.png", -1)
			g_slotwin = LoadSoundChecked(g_pathPrefix + "GameMedia/Sounds/Casino/SlotsWin.ogg", 0)
			g_slotarm = LoadSoundChecked(g_pathPrefix + "GameMedia/Sounds/Casino/SlotsArm.ogg", 0)
		EndIf
		g_slotstrip1 = New TSlotStrip
		g_slotstrip2 = New TSlotStrip
		g_slotstrip3 = New TSlotStrip
		g_slotstrip1.SetUp(253, 0)
		g_slotstrip2.SetUp(359, 0)
		g_slotstrip3.SetUp(465, 0)
	End Function
