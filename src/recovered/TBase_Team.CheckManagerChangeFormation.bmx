' TBase_Team.CheckManagerChangeFormation  (KIND=Method)
' VA 0x004BD2A6   376 bytes   sig ()i
' byte-identical vs NSS5.exe (376/376, original length from Ghidra's inventory, mode=reloc)
' Three source-form facts the decompilation hides:
'   1. TWO early-return guards, not one compound If (`If l <> Null And l.Count() > 4`
'      is 7 bytes short).
'   2. `Self.id = w`, not `w = Self.id` -- the original is `cmp [edx+0xc], eax` (39/),
'      ours-with-w-first is `cmp eax, [edx+0xc]` (3B/).  Same length, diff at byte 192.
'   3. The five-element sum is a LOCAL evaluated before the condition: bcc emits the
'      whole add-chain into ebx first, then loads res[4].  Inlining it into the And-chain
'      reorders those two and misses at byte 230.
' Rand(3) supplies BRL's maxValue default of 1, which is the `push 1` before `push 3`.
Local res:Int[] = New Int[5]
Local l:TList = Self.GetFixtureList(-1, 0)
If Not l Then Return 0
If l.Count() < 5 Then Return 0
For Local f:TFixture = EachIn l
	res[0] = res[1]
	res[1] = res[2]
	res[2] = res[3]
	res[3] = res[4]
	Local w:Int = f.GetWinningTeamId()
	If w = 0
		res[4] = 1
	ElseIf Self.id = w
		res[4] = 3
	Else
		res[4] = 0
	EndIf
Next
Local total:Int = res[0] + res[1] + res[2] + res[3] + res[4]
If res[4] = 0 And Rand(3) = 1 And total < 5
	LogLine(Self.labelname + ": changing formation")
	Local old:Int = Self.formation
	Self.formation = TFormation.PickRandomFormation()
	If old <> Self.formation Then Return 1
EndIf
