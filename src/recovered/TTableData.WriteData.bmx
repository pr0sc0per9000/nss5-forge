' TTableData.WriteData  -- KIND=Method, slot 0x38, sig (:TStream)i
' VA 0x00526DB5   410 bytes
' byte-identical vs NSS5.exe (410/410, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=41)
'
' ASSUMPTIONS
'  * No Globals used.
'  * 0x004A7AC0 = _bbStringFromInt (the Int -> String coercion bcc emits for each field),
'    0x004A7C20 = _bbStringConcat, 0x005B8307 = _brl_stream_WriteLine.
'  * The separator literal at 0x00C6FCC0 is a one-character BBString whose single UTF-16
'    unit is 0x0009, i.e. a TAB -- written "~t".
'  * The association is `s :+ "~t" + field`, giving concat(s, concat(sep, Str(field))).
'    A flat `s = s + "~t" + field` would associate the other way and not match.
'  * Fields read in declaration order from object_model.json (id..points, +0x08..+0x30);
'    randno and longlat are NOT written.
	Method WriteData:Int(a0:TStream)
		Local s:String = Self.id
		s :+ "~t" + Self.teamid
		s :+ "~t" + Self.teamname
		s :+ "~t" + Self.teamstrength
		s :+ "~t" + Self.played
		s :+ "~t" + Self.won
		s :+ "~t" + Self.drawn
		s :+ "~t" + Self.lost
		s :+ "~t" + Self.goalsf
		s :+ "~t" + Self.goalsa
		s :+ "~t" + Self.points
		WriteLine(a0, s)
	End Method
