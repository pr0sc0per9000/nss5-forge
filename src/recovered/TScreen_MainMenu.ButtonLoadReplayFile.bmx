' TScreen_MainMenu.ButtonLoadReplayFile
' VA 0x0051D7F8   219 bytes   vtable slot 0x60   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (219/219, original length from Ghidra's inventory, mode=reloc)
' assumptions (module Globals, names ours):
'   0x00C639E4 : TTable  -- the replay-file list table (globals_final: TTable, construction)
'   0x00C6E808 : Object  -- "profile subsystem initialised" sentinel (globals_final: Object)
' slots resolved:
'   0x00C639E4 vcall +0xD8 = TTable.GetSelectedText(i)$
'   [0x00C6A4F0] = TProfile classtable + 0x30 = TProfile.SetUp()
'   [0x00C5FE8C] = TReplay classtable + 0x34 = TReplay.LoadReplayFile($):TReplay
'   [0x00C6B274] = TScreenMessage classtable + 0x40 = TScreenMessage.ClearAll(i)
'   [0x00C61CC0] = TScreen classtable + 0x94 = TScreen.DoMessage($,i,i)
'   [0x00C5BA70] = TEngine classtable + 0x40 = TEngine.SetUpReplay(:TReplay,()i)
'   [0x00C63CA0] = TScreen_MainMenu classtable + 0x34 = SetUpScreen (own type -> bare name)
' runtime helpers: 0x004A6A30 _bbStringCompare, 0x004A7C20 _bbStringConcat,
'                  0x004A75B0 _bbStringReplace, 0x004C5549 GetText (recovered module fn)
' string literals read out of .rdata: 0x00C7B84C ".rep", 0x00C7EF30
' "CMESSAGE_COULDNOTLOADFILE", 0x00C704A4 "$filename", 0x00C5D284 "".
' Shape notes: the `Not rep` arm ends in an explicit `Return 0` (mov eax,0 / jmp epilogue),
' not an Else -- the tail after it falls through. `If Not x` (setne/movzx) per guide 10.3.
	Function ButtonLoadReplayFile:Int()
		'!Global g_screen_mainmenu_table:TTable
		'!Global g_profile_obj:Object
		Local s:String = g_screen_mainmenu_table.GetSelectedText(0)
		If s <> ""
			If Not g_profile_obj Then TProfile.SetUp()
			Local rep:TReplay = TReplay.LoadReplayFile(s + ".rep")
			If Not rep
				TScreenMessage.ClearAll(1)
				TScreen.DoMessage(GetText("CMESSAGE_COULDNOTLOADFILE").Replace("$filename", s), 0, 0)
				Return 0
			EndIf
			TScreenMessage.ClearAll(0)
			TEngine.SetUpReplay(rep, SetUpScreen)
		EndIf
	End Function
