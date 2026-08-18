' TDate.GetWeekdayDates
' VA 0x0053719C   209 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
Local dates:TDate[]
Local wd:Int = a0.GetWeekday()
Local lim:Int = a1.GetJulian() - a0.GetJulian()
Local d:Int = a2 + (a2 < wd) * 7 - wd
While d < lim
	dates = dates[..dates.Length + 1]
	dates[dates.Length - 1] = TDate.Create(d + a0.GetJulian(), 0, 0)
	d :+ 7
Wend
Return dates
