' TProfile.StartCareer
' VA 0x00566107   424 bytes   mode=reloc   MATCH 424/424
' KIND=Method on TProfile, SIG=()i, SLOT=0x48
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'   Globals declared here (names are ours; originals are unrecoverable):
'     0x00C68BC8 -> g_savename:String
'         globals_final says Int/usage/medium -- WRONG. The code retains the incoming value
'         (FF 40 04) and releases the outgoing one with a conditional _bbGCFree on every
'         store, and reads [g+8] as a String length, so it holds a String (guide 11.2).
'     0x00C6E9A8 -> g_datapath:String
'         globals_final says Int/usage/medium -- also a String: it is the left operand of a
'         _bbStringConcat chain.
'   Slots resolved:
'     TProfile+0x50 CreateNewInternationalStats, +0x70 SetPlayButtonIcon, +0x40 SaveGame($)
'       (Self calls); field TProfile+0x130 playbuttontype
'     [0xC61618] = TCompetition+0x58     -> TCompetition.SetUpCompetitionsAll()i
'     [0xC61CC8] = TScreen+0x9C          -> TScreen.DoMessageGetText($,i)$
'     [0xC61CC0] = TScreen+0x94          -> TScreen.DoMessage($,i,i)i
'     [0xC66910] = TScreen_GameMenu+0x34 -> TScreen_GameMenu.SetUpScreen()i
'     [0xC645F0] = TScreen_Difficulty+0x34 -> TScreen_Difficulty.SetUpScreen()i
'   Calls into recovered module Functions: GetText (0x004C5549), PlayTrack (0x004BCB98).
'   0x005B5A99 = _brl_filesystem_FileType (brl_functions.tsv), 0x004A7C20 = _bbStringConcat,
'   0x004A6A30 = _bbStringCompare (runtime_helpers.tsv).
'   ARG COUNTS confirmed against harness.disasm_original: GetText takes ONE argument --
'   Ghidra printed GetText(&str,0) and GetText(&str,1,0) by merging the FOLLOWING call's
'   pushes (the 0 belongs to DoMessageGetText, the 1,0 to DoMessage).
'   String literals read with harness.read_string: 0xC8DAD0 "CMESSAGE_FILEGETSAVENAME",
'     0xC7DD40 "cancel", 0xC8DB0C "SaveFile", 0xC7ED10 ".sav", 0xC6EA20 "Save/",
'     0xC8DB28 "CMESSAGE_FILEEXISTSOVERWRITE", 0xC5D284 "".
'!Global g_savename:String
'!Global g_datapath:String
CreateNewInternationalStats()
TCompetition.SetUpCompetitionsAll()
Repeat
	g_savename = TScreen.DoMessageGetText(GetText("CMESSAGE_FILEGETSAVENAME"),0)
	If g_savename.Length < 1 Or g_savename = "cancel"
		g_savename = "SaveFile"
	EndIf
	g_savename = g_savename + ".sav"
	If FileType(g_datapath + "Save/" + g_savename) = 1
		If TScreen.DoMessage(GetText("CMESSAGE_FILEEXISTSOVERWRITE"),1,0) = 0
			g_savename = ""
		EndIf
	EndIf
Until g_savename <> ""
Self.playbuttontype = 2
SaveGame("")
SetPlayButtonIcon()
TScreen_GameMenu.SetUpScreen()
TScreen_Difficulty.SetUpScreen()
PlayTrack(2)
