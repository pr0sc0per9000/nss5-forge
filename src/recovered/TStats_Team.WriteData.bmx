' TStats_Team.WriteData -- VA 0x0056ECB7, 735 bytes, vtable slot 0x38, sig (:TStream)i
' ORACLE: MATCH mode=reloc  735/735  reloc_masked=74
'
' ASSUMPTIONS / RESOLUTIONS
'   FUN_00505B91 = LogLine (src/recovered_module/LogLine.bmx)
'   FUN_004A7AC0 = _bbStringFromInt   FUN_004A7C20 = _bbStringConcat
'   FUN_005B8307 = _brl_stream_WriteLine
'   String literals read out of NSS5.exe BBString headers (harness.read_string):
'     0x00C8F3FC "TStats_Team.WriteData"   0x00C6FCC0 = a single TAB character -> "~t"
'   No module Globals are involved.
'   Field names/offsets from object_model.json (0x08 statlevel .. 0x48 manofthematch,
'   0x4C form:Int[]).
'
' The associativity is load-bearing.  Each field emits
'     Concat( s , Concat( FromInt(field), "~t" ) )
' i.e. the RIGHT-hand pair is built first.  Plain `s = s + field + "~t"` is left-associative
' and would emit Concat(Concat(s,field),"~t") -- different bytes.  `s :+ field + "~t"` is
' the form that produces the original.
'
' The trailing loop is a bare array EachIn: Ghidra prints the pointer walk
' `p = form+0x18; end = p + *(form+0x10); while (p != end) p++`, which is exactly what
' `For Local v:Int = EachIn Self.form` lowers to (data at +0x18, size at +0x10).
Method WriteData:Int(a0:TStream)
	LogLine("TStats_Team.WriteData")
	Local s:String = Self.statlevel + "~t"
	s :+ Self.teamid + "~t"
	s :+ Self.year + "~t"
	s :+ Self.appearances + "~t"
	s :+ Self.subs + "~t"
	s :+ Self.shots + "~t"
	s :+ Self.goals + "~t"
	s :+ Self.hattricks + "~t"
	s :+ Self.passes + "~t"
	s :+ Self.assists + "~t"
	s :+ Self.headers + "~t"
	s :+ Self.tackles + "~t"
	s :+ Self.fouls + "~t"
	s :+ Self.yellowcards + "~t"
	s :+ Self.redcards + "~t"
	s :+ Self.distance + "~t"
	s :+ Self.manofthematch + "~t"
	For Local v:Int = EachIn Self.form
		s :+ v + "~t"
	Next
	WriteLine(a0, s)
End Method
