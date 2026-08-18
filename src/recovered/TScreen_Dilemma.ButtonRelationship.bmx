' TScreen_Dilemma.ButtonRelationship
' VA 0x00557bfa   402 bytes
' byte-identical vs NSS5.exe (402/402, original length from Ghidra's inventory, mode=reloc, 36 masked)
' Body-only format: statements only; parameters are a0, a1, ...
' Function ()i, vtable slot 0x50 (per workset).
' ASSUMPTIONS: two Case literals masked. Globals 0x00C6805C / 0x00C68060 are Int (bare
' dword compares against 4 and 5, no refcount traffic) -- globals_final.tsv calls 0x00C6805C
' a TScreen, which the code contradicts (codegen-patterns 11.2). 0x00C68064 / 0x00C68068 are
' object Globals set to Null. Select on a String subject, not If/ElseIf (10.2).
'!Global g_profile:TProfile
'!Global g_dilemma_a:Int
'!Global g_dilemma_b:Int
'!Global g_dilemma_o1:Object
'!Global g_dilemma_o2:Object
Select TGadget.GetActiveGadgetName()
	Case "btn_relationship1"
		TScreen_Relationships.SetUpScreen(1)
		g_profile.UpdateRelationship(g_dilemma_a, 10)
		g_profile.UpdateRelationship(g_dilemma_b, -10)
		If g_dilemma_a = 4
			g_profile.lastspendtimefriends = g_profile.date.sdate
		End If
		If g_dilemma_a = 5
			g_profile.lastspendtimegirlfriend = g_profile.date.sdate
		End If
	Case "btn_relationship2"
		TScreen_Relationships.SetUpScreen(1)
		g_profile.UpdateRelationship(g_dilemma_a, -10)
		g_profile.UpdateRelationship(g_dilemma_b, 10)
		If g_dilemma_b = 4
			g_profile.lastspendtimefriends = g_profile.date.sdate
		End If
		If g_dilemma_b = 5
			g_profile.lastspendtimegirlfriend = g_profile.date.sdate
		End If
End Select
g_dilemma_o1 = Null
g_dilemma_o2 = Null
TScreen_Relationships.SetUpScreen(0)
