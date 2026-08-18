' TScreen_Stable.WriteData
' VA 0x005880E4   652 bytes   mode=reloc   byte-identical vs NSS5.exe (652/652)
' KIND=Function (static), SIG (:TStream)i, slot 0x3C
' ASSUMPTIONS
'   0x00C6E294 -> g_horses:TList  (slot 0x70 = Count, 0x8C = ObjectEnumerator)
'   0x005B8307 alias set resolved to WriteLine (a TStream is the first argument), 3h.
'   The record is ONE left-associative `+` expression, not a `:+` accumulator: all 13
'   bbStringFromInt/FromFloat conversions are emitted first and the 26 concats follow in an
'   unbroken run (16.1 -- a `:+` would interleave concat(literal,value) with
'   concat(accumulator,result)).
'   14 fields, 13 commas -> 26 concats, which is exactly what the original emits.
'   THorse.form is `[]i`; form[0..4] are the five `[base+0x18 .. base+0x28]` loads (BBArray
'   data starts at +0x18, 11.1). `name` is already a String and gets no conversion, which is
'   why there are 10 FromInt and 3 FromFloat rather than 11 and 3.
'   Field offsets from object_model.json: id +0x34, name +0x38, energy +0x3C, health +0x40,
'   strength +0x44, form +0x48, prize +0x4C, owned +0x50, lastran +0x54, colour +0x58.
'!Global g_horses:TList
LogLine("HorseCount:" + g_horses.Count())
For Local h:THorse = EachIn g_horses
	WriteLine(a0, h.id + "," + h.name + "," + h.energy + "," + h.health + "," + h.strength + "," + h.form[0] + "," + h.form[1] + "," + h.form[2] + "," + h.form[3] + "," + h.form[4] + "," + h.prize + "," + h.owned + "," + h.lastran + "," + h.colour)
Next
WriteLine(a0, "//")
