' TWeather.UpdateRain
' VA 0x005051A2   294 bytes   vtable slot 0x3c   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (294/294, original length from Ghidra's inventory, mode=reloc)
' assumptions: Globals 0x00C600D0=TSound, 0x00C600D4=TChannel (both listed only as "Object"
' in globals_final.tsv; the pair is fixed by PlaySound(sound,channel) at 0x0059B25E and by
' slot 0x38=TChannel.SetVolume(f) / 0x48=TChannel.Playing() in vtable_map.tsv).
' 0x00C5D220 is the Float Global g_options_float01 (100.0 in the image); the divisor at
' 0x00C7BAB8 is a separate literal 100.0. 0x00505F90 is module Function ClampFloat.
'
' TWO FORMS DECIDED THIS ONE:
'  * the first compare is `cmp [0xC6EFD4], eax`, so the Global must be the LHS in source
'    (If g_screentime > g_raintime + 70). The reversed spelling emits cmp eax,[mem]/jge.
'  * `If g_rainmode And ...`, not `If g_rainmode <> 0 And ...` -- the original feeds the raw
'    Int into the And and saves the setne/movzx/cmp triple (exactly the 9 missing bytes).
	Function UpdateRain:Int()
		'!Global g_rainsound:TSound
		'!Global g_rainchannel:TChannel
		'!Global g_rainmode:Int
		'!Global g_raintime:Int
		'!Global g_rainframe:Int
		'!Global g_rainvol:Float
		'!Global g_rainpan:Float
		'!Global g_options_sfxvol:Float = 100.0
		'!Global g_screentime:Int
		If g_screentime > g_raintime + 70
			g_raintime = g_screentime
			g_rainframe :- 1
			If g_rainframe < 0 Then g_rainframe = 7
		EndIf
		Select g_rainmode
			Case 1
				g_rainvol = g_rainvol + 0.001
				g_rainpan = g_rainpan + 0.001
			Case 0
				g_rainvol = g_rainvol - 0.001
				g_rainpan = g_rainpan - 0.003
		End Select
		ClampFloat(Varptr g_rainvol, 0, 0.35)
		ClampFloat(Varptr g_rainpan, 0, g_options_sfxvol / 100.0)
		g_rainchannel.SetVolume(g_rainpan)
		If g_rainmode And g_rainchannel.Playing() = 0
			PlaySound(g_rainsound, g_rainchannel)
		EndIf
	End Function
