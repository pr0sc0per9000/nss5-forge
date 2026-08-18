' TTeam.CreateSquadSimple  -- KIND=Method, slot 0x48
' VA 0x004dd954   317 bytes   sig ()i
' byte-identical vs NSS5.exe (317/317, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=13)
' Body-only format: statements only, Self implicit.
'
' ASSUMPTIONS
'  * Global 0x00C5D228 declared Int, named g_modeFlag (name is ours). globals_final.tsv
'    types it Int from usage (13 dword writes, no refcount traffic) -- consistent with
'    the bare `cmp [g],3` here.
'  * PTR_FUN_00C6D4D8 resolves to TTraining class table + slot 0x34 =
'    TTraining.IsPlayerNeededForTraining (i,i)i (KIND=Function, i.e. static).
'  * PTR_FUN_00C5F984 resolves to TPlayer class table + slot 0x38 =
'    TPlayer.CreatePlayerSimple (i,i,i,i,i,i):TPlayer (KIND=Function, i.e. static).
'  * Self.squad is :TList; slot 0x44 on it is TList.AddLast. CreateList comes from the
'    alias set at 0x005B40BF (CreateList|CreateMap|TGNetHost.Create); AddLast at 0x44
'    immediately after is the confirming tell (10.8).
'  * FUN_00505B91 = LogLine, FUN_00505F6D = ClampInt, both from src/recovered_module/.
'    LogLine takes ONE argument -- Ghidra merges the String-concat pushes into it.
'  * The null test is the `If Not x` emission (10.3), not `If x = Null`: the original has
'    cmp eax,0x5c9c80 / setne / movzx / cmp 0 / jne. The `= Null` form is 10 bytes shorter
'    and gave 307.
'  * BOTH loops are `To 10`, not `Until 11` (cmp esi,0xa / jle). Each cost one iteration
'    of the loop to find; the diff marched 207 -> 300 -> match.
'!Global g_modeFlag:Int
	Method CreateSquadSimple:Int()
		LogLine("CreateSquad:" + Self.id)
		If Not Self.squad
			Self.squad = CreateList()
		Else
			Self.squad.Clear()
		End If
		If Self.newstarselno = -1
			If g_modeFlag = 3
				Self.rating = Self.rating + 5
				ClampInt(Varptr Self.rating, 30, 100)
			End If
			For Local i:Int = 0 To 10
				If TTraining.IsPlayerNeededForTraining(i, 1)
					Self.squad.AddLast(TPlayer.CreatePlayerSimple(i, Self.id, Self.rating, 0, Self.skin1, Self.skin2))
				End If
			Next
		Else
			For Local i:Int = 0 To 10
				Local n:Int = (i = Self.newstarselno)
				If n = 0 Then n = TTraining.IsPlayerNeededForTraining(i, 0)
				If n <> 0
					Self.squad.AddLast(TPlayer.CreatePlayerSimple(i, Self.id, Self.rating, i = Self.newstarselno, Self.skin1, Self.skin2))
				End If
			Next
		End If
	End Method
