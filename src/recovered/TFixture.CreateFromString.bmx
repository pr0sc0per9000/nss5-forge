' TFixture.CreateFromString
' VA 0x004c2b8a   744 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static on TFixture), SIG ($):TFixture, class-table slot 0x34
' ASSUMPTIONS
'   No module Globals.
'   0x00505BCB = NextFieldInt, already verified in src/recovered_module/. Its first
'   parameter is String Var, which is what produces the &local / retain + bbGCFree pair
'   Ghidra shows around every call -- that traffic is compiler-generated, not source.
'   Field names/offsets from object_model.json: sdate 0x08 .. compid 0x40, all Int.
'   The separator literal at 0x00C6FCC0 is a single TAB, read with harness.read_string.
'   The oracle masks the literal's ADDRESS, so "~t" is certified by that read, not by the
'   MATCH.
' Recovered as the READ twin of TFixture.WriteData (0x004C2E72, already banked): identical
' field list in identical order, which is where the whole segmentation came from (16.4).
	Function CreateFromString:TFixture(a0:String Var)
		Local f:TFixture = New TFixture
		f.sdate = NextFieldInt(a0, "~t")
		f.matchtype = NextFieldInt(a0, "~t")
		f.round = NextFieldInt(a0, "~t")
		f.groupno = NextFieldInt(a0, "~t")
		f.leg = NextFieldInt(a0, "~t")
		f.hometeam = NextFieldInt(a0, "~t")
		f.awayteam = NextFieldInt(a0, "~t")
		f.result = NextFieldInt(a0, "~t")
		f.resulttype = NextFieldInt(a0, "~t")
		f.score1 = NextFieldInt(a0, "~t")
		f.score2 = NextFieldInt(a0, "~t")
		f.penscore1 = NextFieldInt(a0, "~t")
		f.penscore2 = NextFieldInt(a0, "~t")
		f.level = NextFieldInt(a0, "~t")
		f.compid = NextFieldInt(a0, "~t")
		Return f
	End Function
