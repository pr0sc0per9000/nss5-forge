' TTableData.LoadTableData  -- KIND=Function (static method on TTableData), slot 0x34
' VA 0x00526B75   576 bytes   sig ($):TTableData
' byte-identical vs NSS5.exe (576/576, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=36)
'
' ASSUMPTIONS
'  No module Globals.
'  Direct calls resolved:
'    0x00505BCB -> NextFieldInt($ Var,$)i (src/recovered_module/NextFieldInt.bmx)
'    0x00505C64 -> NextField($ Var,$)$    (src/recovered_module/NextField.bmx)
'    0x004A8F20 -> _bbObjectNew, i.e. `New TTableData`
'  The separator literal 0x00C6FCC0 is pushed as an absolute data address, so its TEXT is
'  not recoverable from the bytes. "," is a guess; what is proven is that ONE separator
'  constant is shared by all eleven calls.
'  Ghidra's `local_8 = param_1` plus the retain/release pairs around every call is the
'  String Var argument passing, not source-level code.
'  Field order (id, teamid, teamname, teamstrength, played, won, drawn, lost, goalsf,
'  goalsa, points) is the order of the stores and matches TTableData's declaration order;
'  randno (+0x34) and longlat (+0x38) are NOT touched here.

	Function LoadTableData:TTableData(a0:String)
		Local d:TTableData = New TTableData
		d.id = NextFieldInt(a0, "~t")
		d.teamid = NextFieldInt(a0, "~t")
		d.teamname = NextField(a0, "~t")
		d.teamstrength = NextFieldInt(a0, "~t")
		d.played = NextFieldInt(a0, "~t")
		d.won = NextFieldInt(a0, "~t")
		d.drawn = NextFieldInt(a0, "~t")
		d.lost = NextFieldInt(a0, "~t")
		d.goalsf = NextFieldInt(a0, "~t")
		d.goalsa = NextFieldInt(a0, "~t")
		d.points = NextFieldInt(a0, "~t")
		Return d
	End Function
