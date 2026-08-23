' UpdateAudio  -- module-level Function (no Type)
' VA 0x004bc88c   780 bytes   sig ()i
' byte-identical vs NSS5.exe (780/780, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=74, verified with NSS5_NO_LEARN=1 so nothing was masked by a name the run
' taught itself -- see codegen-patterns 13.1)
'
' NAME AND GLOBAL NAMES ARE OURS -- module-level Functions and Globals carry no debug
' record. This is the blocker under 0x004BCB98 (the music player, gates 15); it is not hard,
' it is the LoadSoundChecked family again -- six calls to the already-recovered 0x004BC564,
' one per music track.
'
' Per-channel volume push, then TEngine.UpdateSounds (class-table TEngine+0xC0), then the
' music track table is lazily loaded when the music volume is up and released when it is
' zero. The six literals decode out of the exe with harness.read_string (13.2); the three
' divisors 110.0/100.0/100.0 are float literals pooled immediately ahead of those strings
' in source order, not Globals (0x00C6FA5C/60/64).
'
' ASSUMPTIONS carried by the declared Global types, all of which are load-bearing:
'   0x00C6F08C g_musicchannel  :TChannel   -- slot 0x38 = TChannel.SetVolume(f)i
'   0x00C6F088 g_sfxchannel    :TChannel   -- same slot; merged onto g_Object857, the name
'              the module body allocates, in extracted/global_alias_overrides.tsv. Split,
'              the SFX volume never reached the channel every UI sound plays on.
'   0x00C6F090 g_speechchannel :TChannel   -- same slot
'   0x00C5D224 g_musicvol      :Float      -- globals_final: Float, high, TOptions
'   0x00C5D220 g_sfxvol        :Float      -- globals_final: Float, high, TOptions
'   0x00C6F130 g_tracks        :TSound[]   -- globals_final: Object[], init=bbEmptyArray;
'              element type is TSound because every store is a LoadSoundChecked result
'!Global g_musicchannel:TChannel
'!Global g_sfxchannel:TChannel
'!Global g_speechchannel:TChannel
'!Global g_musicvol:Float
'!Global g_sfxvol:Float
'!Global g_tracks:TSound[]
	Function UpdateAudio:Int()
		If g_musicchannel <> Null
			g_musicchannel.SetVolume(g_musicvol / 110.0)
		End If
		If g_sfxchannel <> Null
			g_sfxchannel.SetVolume(g_sfxvol / 100.0)
		End If
		If g_speechchannel <> Null
			g_speechchannel.SetVolume(g_sfxvol / 100.0)
		End If
		TEngine.UpdateSounds()
		If g_musicvol > 0 And Not g_tracks[1]
			g_tracks[1] = LoadSoundChecked("incbin::Inc/Music/Main.ogg", 1)
			g_tracks[2] = LoadSoundChecked("incbin::Inc/Music/Training_Loop1.ogg", 1)
			g_tracks[3] = LoadSoundChecked("incbin::Inc/Music/Training_Loop2.ogg", 1)
			g_tracks[4] = LoadSoundChecked("incbin::Inc/Music/Shopping_Loop1.ogg", 1)
			g_tracks[5] = LoadSoundChecked("incbin::Inc/Music/Casino_Loop1.ogg", 1)
			g_tracks[0] = LoadSoundChecked("incbin::Inc/Music/Intro.ogg", 0)
		ElseIf Not g_musicvol
			g_tracks[0] = Null
			g_tracks[1] = Null
			g_tracks[2] = Null
			g_tracks[3] = Null
			g_tracks[4] = Null
			g_tracks[5] = Null
		End If
	End Function
