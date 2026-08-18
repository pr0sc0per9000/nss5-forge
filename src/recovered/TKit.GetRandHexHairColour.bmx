' TKit.GetRandHexHairColour
' VA 0x004DBDBF   281 bytes
' byte-identical vs NSS5.exe (281/281, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
Select a0
	Case 1
		Select Rand(4)
			Case 1
				Return GetHexHairCol(Rand(1,3))
			Case 2
				Return GetHexHairCol(Rand(1,3))
			Case 3
				Return GetHexHairCol(Rand(1,3))
			Case 4
				Return GetHexHairCol(Rand(4,7))
		End Select
	Case 2
		Return GetHexHairCol(Rand(1,3))
	Case 3
		Return GetHexHairCol(Rand(1,2))
	Case 4
		Return GetHexHairCol(1)
	Case 5
		Return GetHexHairCol(1)
End Select
Return GetHexHairCol(1)
