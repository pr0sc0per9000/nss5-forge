' GLOBAL RENAMED (2026-08-15): g_currentscreen -> g_curscreen. Same slot, 0x00C61700,
' stated in this file's own header and in TScreen.SetActive's. SetActive WRITES the
' active screen as g_curscreen and this file READ it as g_currentscreen, so in the
' assembled program they were two Globals and the reader always saw Null -- the boot
' died in SetActiveGadget on `g_currentscreen.gadgetlist` while setting up the very
' first screen. 8 files already spell 0x00C61700 g_curscreen; only these 2 did not.
' Byte-neutral (Global names never appear in the compiled bytes; the oracle masks the
' address) -- confirmed with scripts/reverify.py.
' CAUTION for anyone extending this: g_curscreen is ALSO used for a DIFFERENT slot,
' 0x00C6764C, in TScreen_MatchPaused.ButtonSkipTime and others. The name->address map
' is many-to-many, so never sweep-rename it globally; see scripts/unify_globals.py.
' TScreen.SetActiveGadget
' VA 0x00510B53   345 bytes   mode=reloc   MATCH 345/345
' KIND=Function (static method on TScreen), SIG=($)i, SLOT=0x60
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'   Globals declared here (names are ours; originals are unrecoverable):
'     0x00C61700 -> g_curscreen:TScreen
'         globals_final says type=Object/usage/low. Typed TScreen from the code: the body
'         reads its field at +0xc and calls TList.ObjectEnumerator (slot 0x8c) on it, and
'         TScreen+0xc is gadgetlist:TList in object_model.json.
'     0x00C61CF8 -> g_activegadget:TGadget
'         globals_final says type=Object/usage/low. Typed TGadget from the code: the stored
'         value is the downcast-to-TGadget loop variable, with full retain/release traffic
'         (11.2), so it holds a reference.
'   Fields (object_model.json): TScreen+0x0c gadgetlist:TList,
'                               TGadget+0x08 children:TList, TGadget+0x0c name$
'   Runtime helpers (extracted/runtime_helpers.tsv):
'     0x004A74E0 = _brl_retro_Upper   -> Upper()
'     0x004A6A30 = _bbStringCompare   -> String '=' comparison
'   Slot resolved: [0xC61C90] = TScreen+0x64 -> TScreen.FindNewActiveGadget()i. It is this
'     Type's own class table, so it is written unprefixed (guide 3d).
'   Comparison operand order is byte-observable (10.1): Upper(g.name) = Upper(a0) is the
'     form that matches -- Upper(a0) is evaluated and pushed first.
'!Global g_curscreen:TScreen
'!Global g_activegadget:TGadget
' byte-identical vs NSS5.exe
For Local g:TGadget = EachIn g_curscreen.gadgetlist
	If Upper(g.name) = Upper(a0)
		g_activegadget = g
		Return 0
	EndIf
	For Local c:TGadget = EachIn g.children
		If Upper(c.name) = Upper(a0)
			g_activegadget = c
			Return 0
		EndIf
	Next
Next
FindNewActiveGadget()
