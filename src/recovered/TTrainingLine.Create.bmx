' TTrainingLine.Create
' VA 0x00583FA3   170 bytes   mode=reloc
' byte-identical vs NSS5.exe
' Driven through the oracle from scratch with helper_map.record stubbed; MATCH over the
' full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_coneSplitSound:TSound
If Not g_coneSplitSound Then g_coneSplitSound = LoadSoundChecked("EngineMedia/Match/Sounds/ConeSplit.ogg", 0)
Local t:TTrainingLine = New TTrainingLine
t.alive = 1
t.x = a0
t.y = a1
t.x2 = a2
t.y2 = a3
t.colour = a4
Return t
