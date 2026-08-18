' THistory.WriteData
' VA 0x0056F3DA   252 bytes
' byte-identical vs NSS5.exe (252/252, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
LogLine("THistory.WriteData")
Local s:String = Self.year+"~t"
s = s + (Self.clubid+"~t")
s = s + (Self.nationid+"~t")
s = s + (Self.text+"~t")
s = s + (Self.compid+"~t")
s = s + (Self.winner+"~t")
WriteLine(a0, s)
