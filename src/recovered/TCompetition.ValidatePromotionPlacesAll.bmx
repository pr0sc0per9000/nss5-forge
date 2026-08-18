' TCompetition.ValidatePromotionPlacesAll  (KIND=Function -- static)
' VA 0x0050FE43   280 bytes   sig ()i
' byte-identical vs NSS5.exe (280/280, original length from Ghidra's inventory, mode=reloc)
' 0x00C6099C is the module list of TCompetition (name ours, TList
' load-bearing).  Concat order in the decompilation forces `s :+ c.id + " "`, not
' `s = s + c.id + " "`.  The trailing call goes through TScreen's class table + 0x94.
'!Global g_competitions:TList
LogLine("ValidatePromotionPlacesAll")
Local s:String = ""
For Local c:TCompetition = EachIn g_competitions
	If c.level = 0 And c.locale = 0 And c.comptype = 0
		If c.ValidatePromotionPlaces()
			s :+ c.id + " "
		EndIf
	EndIf
Next
If s <> "" Then TScreen.DoMessage("WARNING! Promotion place errors in competition(s): " + s, 0, 0)
