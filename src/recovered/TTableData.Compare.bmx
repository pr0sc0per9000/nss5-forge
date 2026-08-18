' TTableData.Compare
' VA 0x0052708a   1501 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (1501/1501, original length from Ghidra's inventory)
' oracle: status MATCH, mode 'reloc' (52 absolute addresses masked), matched 1501/1501
'
' Assumptions:
'   - module global at 0x00c649a0 declared as Int; name taken from globals_named.tsv
'     (g_teampool_int01 -- it is the sort key set by TTeamPool.SortTableBy).
'     Declared in the body via the harness pragma:  '!Global g_teampool_int01:Int
'   - Local variable names are invented (the exe carries no debug names). Their
'     DECLARATION ORDER is load-bearing and is recovered from the initialiser order.
'   - Case 16: ppg2/ppg1 must be declared Locals, not inline expressions. bcc keeps
'     them x87-resident, which is why the original compares them with a non-popping
'     'fucom st(1)' (+ two 'fstp st(0)' on the Return path) and then re-uses the same
'     two stack values for the second comparison. Inlining the two divisions costs
'     10 extra bytes and shifts the Float slot allocation.
'   - The trailing runtime call FUN_004a8e70(Self, a0) is Super.Compare(a0).
'   - Both string comparisons read literally as 'other < Self' / 'other > Self'
'     (bbStringCompare arg order in the original fixes this orientation).

	Method Compare:Int(a0:Object)
		'!Global g_teampool_int01:Int
		If a0 = Self Return 0
		Select g_teampool_int01
			Case 1
				If Self.id > TTableData(a0).id Return 1
				If Self.id < TTableData(a0).id Return -1
			Case 2
				If TTableData(a0).teamname < Self.teamname Return 1
				If TTableData(a0).teamname > Self.teamname Return -1
			Case 5
				If Self.randno > TTableData(a0).randno Return 1
				If Self.randno < TTableData(a0).randno Return -1
			Case 4
				Local name2:String = TTableData(a0).teamname
				Local points2:Int = TTableData(a0).points
				Local goalsf2:Int = TTableData(a0).goalsf
				Local goalsa2:Int = TTableData(a0).goalsa
				Local won2:Int = TTableData(a0).won
				Local name1:String = Self.teamname
				Local points1:Int = Self.points
				Local goalsf1:Int = Self.goalsf
				Local goalsa1:Int = Self.goalsa
				Local won1:Int = Self.won
				If points2 > points1 Return 1
				If points2 < points1 Return -1
				If goalsf2 - goalsa2 > goalsf1 - goalsa1 Return 1
				If goalsf2 - goalsa2 < goalsf1 - goalsa1 Return -1
				If goalsf2 > goalsf1 Return 1
				If goalsf2 < goalsf1 Return -1
				If won2 > won1 Return 1
				If won2 < won1 Return -1
				If Self.id > TTableData(a0).id Return 1
				If Self.id < TTableData(a0).id Return -1
				If name2 < name1 Return 1
				If name2 > name1 Return -1
			Case 16
				Local played2:Float = TTableData(a0).played
				Local played1:Float = Self.played
				Local pts2:Float = TTableData(a0).points
				Local pts1:Float = Self.points
				Local gf2:Float = TTableData(a0).goalsf
				Local gf1:Float = Self.goalsf
				Local ga2:Float = TTableData(a0).goalsa
				Local ga1:Float = Self.goalsa
				Local nm2:String = TTableData(a0).teamname
				Local nm1:String = Self.teamname
				Local ppg2:Float = pts2 / played2
				Local ppg1:Float = pts1 / played1
				If ppg2 > ppg1 Return 1
				If ppg2 < ppg1 Return -1
				If (gf2 - ga2) / played2 > (gf1 - ga1) / played1 Return 1
				If (gf2 - ga2) / played2 < (gf1 - ga1) / played1 Return -1
				If gf2 > gf1 Return 1
				If gf2 < gf1 Return -1
				If nm2 < nm1 Return 1
				If nm2 > nm1 Return -1
			Case 24
				If Self.longlat > TTableData(a0).longlat Return -1
				If Self.longlat < TTableData(a0).longlat Return 1
			Case 25
				If Self.longlat > TTableData(a0).longlat Return 1
				If Self.longlat < TTableData(a0).longlat Return -1
		End Select
		Return Super.Compare(a0)
	End Method
