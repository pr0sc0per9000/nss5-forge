' TSlotMachine.Spin
' VA 0x00578469   134 bytes   mode=reloc
' Driven through the oracle from scratch with helper_map.record stubbed; MATCH over the
' full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_slot_sound:TSound
'!Global g_slot_chan:TChannel
'!Global g_slot_strip1:TSlotStrip
'!Global g_slot_strip2:TSlotStrip
'!Global g_slot_strip3:TSlotStrip
'!Global g_slot_spinning:Int
'!Global g_slot_panel:TPanel
'!Global g_slot_btn1:TButton
'!Global g_slot_btn2:TButton
' byte-identical vs NSS5.exe
PlaySound(g_slot_sound, g_slot_chan)
g_slot_strip1.Spin(1)
g_slot_strip2.Spin(2)
g_slot_strip3.Spin(3)
g_slot_spinning = 1
g_slot_panel.Hide()
g_slot_btn1.Hide()
g_slot_btn2.Hide()
