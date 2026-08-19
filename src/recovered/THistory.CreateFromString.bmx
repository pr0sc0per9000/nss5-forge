' THistory.CreateFromString
' VA 0x0056F4D6   341 bytes   mode=reloc   MATCH 341/341
' byte-identical vs NSS5.exe
' KIND=Function (static method on THistory), SIG ($):THistory, class-table slot 0x34.
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'  * 0x00505BCB = NextFieldInt and 0x00505C64 = NextField, both already verified in
'    src/recovered_module/. Their first parameter is String Var, which is why the
'    decompilation shows &local_8 and the retain/release pair around every call.
'  * The separator literal at 0x00C6FCC0 was read out of NSS5.exe with
'    harness.read_string() and is a single TAB, spelled "~t" here. The oracle masks the
'    literal's ADDRESS, so this spelling is not certified by the MATCH -- it is certified by
'    the read.
'  * Field names/offsets from object_model.json: year 0x08, clubid 0x0c, nationid 0x10,
'    text 0x14 ($), compid 0x18, winner 0x1c.
'  * No Globals used. reloc_masked=21 = the class table, the six literal addresses and the
'    runtime refcount helpers.
Local h:THistory = New THistory
h.year = NextFieldInt(a0, "~t")
h.clubid = NextFieldInt(a0, "~t")
h.nationid = NextFieldInt(a0, "~t")
h.text = NextField(a0, "~t")
h.compid = NextFieldInt(a0, "~t")
h.winner = NextFieldInt(a0, "~t")
Return h
