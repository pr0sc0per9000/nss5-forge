' TFormation.UpdateLabels
' VA 0x004d83cc   951 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (951/951, original length from Ghidra's inventory, mode=reloc)
' Assumptions: eight module globals holding the label fragments.  globals_named.tsv
' types them "Int"; they are in fact String -- the slots at 0xc5bb6c/0xc5bb80/
' 0xc5bb94/0xc5bbbc/0xc5bbd0/0xc5bbe4/0xc5bbf8/0xc5bc0c each point at a string
' object living immediately in front of them, holding (in that order)
'   "L" "C" "R" "D" "DM" "M" "AM" "F".
' Names kept from globals_named.tsv so cross-references still resolve.
' Matched in 'reloc' mode (global/string addresses masked).
'
' Verified from scratch with the eight '!Global pragmas below -> MATCH
' 951/951, reloc_masked=41. A BUILD_FAIL without them is a harness limitation
' (it cannot bind a Global from prose alone), not a body defect.
	Method UpdateLabels:Int()
		'!Global g_formation_int01:String
		'!Global g_formation_int02:String
		'!Global g_formation_int03:String
		'!Global g_formation_int05:String
		'!Global g_formation_int06:String
		'!Global g_formation_int07:String
		'!Global g_formation_int08:String
		'!Global g_formation_int09:String
		m_Defenders = 0
		m_DefensiveMidfielders = 0
		m_Midfielders = 0
		m_AttackingMidfielders = 0
		m_Attackers = 0
		For Local i:Int = 0 To 34
			m_TacLabel[i] = g_formation_int09
			If i < 28 Then m_TacLabel[i] = g_formation_int08
			If i < 21 Then m_TacLabel[i] = g_formation_int07
			If i < 14 Then m_TacLabel[i] = g_formation_int06
			If i < 7 Then m_TacLabel[i] = g_formation_int05
			If m_TacPos[i] = 1
				If m_TacLabel[i] = g_formation_int09 Then m_Attackers = m_Attackers + 1
				If m_TacLabel[i] = g_formation_int08 Then m_AttackingMidfielders = m_AttackingMidfielders + 1
				If m_TacLabel[i] = g_formation_int07 Then m_Midfielders = m_Midfielders + 1
				If m_TacLabel[i] = g_formation_int06 Then m_DefensiveMidfielders = m_DefensiveMidfielders + 1
				If m_TacLabel[i] = g_formation_int05 Then m_Defenders = m_Defenders + 1
			EndIf
			If i Mod 7 = 0 Then m_TacLabel[i] = m_TacLabel[i] + g_formation_int01
			If i Mod 7 = 1 Then m_TacLabel[i] = m_TacLabel[i] + g_formation_int01
			If i Mod 7 = 2 Then m_TacLabel[i] = m_TacLabel[i] + g_formation_int02
			If i Mod 7 = 3 Then m_TacLabel[i] = m_TacLabel[i] + g_formation_int02
			If i Mod 7 = 4 Then m_TacLabel[i] = m_TacLabel[i] + g_formation_int02
			If i Mod 7 = 5 Then m_TacLabel[i] = m_TacLabel[i] + g_formation_int03
			If i Mod 7 = 6 Then m_TacLabel[i] = m_TacLabel[i] + g_formation_int03
		Next
	End Method
