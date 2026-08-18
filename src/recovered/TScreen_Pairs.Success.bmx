' TScreen_Pairs.Success
' VA 0x00579658   368 bytes
' byte-identical vs NSS5.exe (368/368, original length from Ghidra's inventory, mode=reloc, 34 masked)
' Body-only format: statements only; parameters are a0, a1, ...
' Function (i)i, vtable slot 0x54.
' ASSUMPTIONS: six string literals masked. Case ORDER 1,3,2,4,5,6 is taken from the
' compare sequence and is byte-observable. Select (not If/ElseIf) per codegen-patterns 10.2.
' 0x00C66D04 = TScreen_Relationships classtable+0x34 (SetUpScreen), 0x00C6C828 an Int Global.
'!Global g_pairs_snd:TSound
'!Global g_pairs_chan:TChannel
'!Global g_profile:TProfile
'!Global g_pairs_id:Int
PlaySound(g_pairs_snd, g_pairs_chan)
TScreen_Relationships.SetUpScreen(1)
g_profile.UpdateRelationship(g_pairs_id, 10)
TScreen_Relationships.SetUpScreen(0)
Local s:String
Select g_pairs_id
	Case 1
		s = GetText("CDILEMMA_BOSS" + String(a0))
	Case 3
		s = GetText("CDILEMMA_FANS" + String(a0))
	Case 2
		s = GetText("CDILEMMA_TEAM" + String(a0))
	Case 4
		s = GetText("CDILEMMA_FRIENDS" + String(a0))
	Case 5
		s = GetText("CDILEMMA_GIRL" + String(a0))
	Case 6
		s = GetText("CDILEMMA_SPONSORS" + String(a0))
End Select
TScreen.DoMessage(s, 0, 0)
