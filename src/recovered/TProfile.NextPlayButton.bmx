' TProfile.NextPlayButton
' VA 0x005679A0   309 bytes
' byte-identical vs NSS5.exe (309/309, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
LogLine("NextPlayButton")
Self.playbuttontype :+ 1
If Self.playbuttontype > 5 Then Self.playbuttontype = 1
Select Self.playbuttontype
	Case 1
		If Self.bossreport = "" And Self.physioreport = "" And Self.coachreport = ""
			Self.NextPlayButton()
			Return 0
		End If
	Case 2
		If Self.webheadline = ""
			Self.NextPlayButton()
			Return 0
		End If
	Case 3
	Case 4
	Case 5
		If Self.newsheadline = ""
			Self.NextPlayButton()
			Return 0
		End If
End Select
Self.SetPlayButtonIcon()
