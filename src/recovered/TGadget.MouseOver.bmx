' TGadget.MouseOver
' VA 0x00514113   201 bytes   vtable slot 0x60   sig ()i
' byte-identical vs NSS5.exe (201/201, original length from Ghidra's inventory)

'!Global g_screen_float01:Float
'!Global g_screen_float02:Float
'!Global g_screen_float03:Float
'!Global g_screen_float04:Float
Local mx:Int = Int(g_screen_float03 - g_screen_float01)
Local my:Int = Int(g_screen_float04 - g_screen_float02)
If mx >= x And mx < x + w And my >= y And my < y + h Then Return True
