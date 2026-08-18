' TCompetition.GetStringArray
' VA 0x0050C2CE   1624 bytes   mode=reloc   byte-identical vs NSS5.exe (1624/1624, reloc_masked=83)
' Verified under NSS5_NO_LEARN=1 -- nothing was masked by a helper name this probe taught.
' KIND=Method, SIG ()[]$, class-table slot 0x40
'
' NOTES
'   New String[17] -- bbArrayNew1D(0x00C7CE1E, 0x11); indices 0..16 are +0x18..+0x58.
'   FIVE of the six dispatches are `Select` (locale, level, comptype, legs, townregion):
'     each loads the subject ONCE into eax and emits every Case compare back to back
'     (codegen-patterns 10.2). `level` looks like a two-arm If/ElseIf in Ghidra's output but
'     is NOT -- as If/ElseIf the body is 1619 bytes, as Select it is 1624 (the whole -5).
'   TNation extends TBase_Team, so the +0x18 read after TNation.SelectById is `.tla`;
'   TContinent declares its own `tla` at +0x10.
'   "Y" + GetYear() + " W" + GetWeek(): the concat operands are evaluated RIGHTMOST-FIRST
'   (16.2), which is how the emitted GetWeek-before-GetYear order is reproduced. TMyDate is
'   a real Local -- bcc does no CSE and Create is called once.
'   String literals read out of NSS5.exe with harness.read_string at the addresses the
'   original pushes at the same code offsets.
Local arr:String[] = New String[17]
arr[0] = Self.id
arr[1] = Self.name
arr[2] = Self.tla
Select Self.locale
	Case 0
		arr[5] = "Nat"
		If Self.based <> 0
			arr[3] = TNation.SelectById(Self.based).tla
		End If
	Case 1
		arr[5] = "Cnt"
		If Self.based <> 0
			arr[3] = TContinent.SelectById(Self.based).tla
		End If
	Case 2
		arr[3] = ""
		arr[5] = "Wrl"
End Select
Select Self.level
	Case 0
		arr[4] = "Club"
	Case 1
		arr[4] = "Int"
End Select
Select Self.comptype
	Case 0
		arr[6] = "Lge"
	Case 1
		arr[6] = "KO"
	Case 2
		arr[6] = "BsP"
	Case 3
		arr[6] = "Pool"
	Case 4
		arr[6] = "LgCn"
	Case 15
		arr[6] = "RgSr"
End Select
arr[7] = "0"
If Self.startyear > 0
	Local d:TMyDate = TMyDate.Create(1, Self.startweek, Self.startyear)
	arr[7] = "Y" + d.GetYear() + " W" + d.GetWeek()
End If
arr[8] = Self.recurring
arr[9] = Self.duration
arr[10] = GetText("Any")
If Self.primarymatchday > 0 And Self.primarymatchday < 99
	arr[10] = TDate.GetStringWeekday(Self.primarymatchday - 1, 3)
End If
arr[11] = GetText("Any")
If Self.secondarymatchday > 0 And Self.secondarymatchday < 99
	arr[11] = TDate.GetStringWeekday(Self.secondarymatchday - 1, 3)
End If
arr[12] = Self.groups
arr[13] = Self.rounds
Select Self.legs
	Case 0
		arr[14] = "ET/P"
	Case 1
		arr[14] = "R/ET/P"
	Case 2
		arr[14] = "2L/ET/P"
End Select
Select Self.townregion
	Case 0
		arr[15] = "None"
	Case 1
		arr[15] = "North"
	Case 2
		arr[15] = "East"
	Case 3
		arr[15] = "South"
	Case 4
		arr[15] = "West"
	Case 5
		arr[15] = "Combn"
End Select
arr[16] = Self.compstatus
Return arr
