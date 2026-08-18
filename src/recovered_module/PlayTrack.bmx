' PlayTrack  -- module-level Function (no Type)
' VA 0x004bcb98   323 bytes   sig (i)i
' byte-identical vs NSS5.exe (323/323, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=25, verified with NSS5_NO_LEARN=1 -- codegen-patterns 13.1)
'
' NAME AND GLOBAL NAMES ARE OURS. The music player: 15 callers. This body cannot be verified
' until 0x004BC88C is recovered: the leading call goes there, and standing in a placeholder
' file for that VA would make harness.module_functions() treat it as verified, naming the
' ORIGINAL side from the placeholder's own header and masking the call by name
' (codegen-patterns 13.3). 0x004BC88C is genuinely recovered as UpdateAudio, so the call
' names itself on both sides and this body verifies with nothing stubbed.
'
' a0 is the 1-based track number; 0 means "stop". g_tracks is indexed a0-1, and the index
' expression is written twice because bcc does no CSE.
'
' ASSUMPTIONS carried by the declared Global types:
'   0x00C6F08C g_musicchannel :TChannel  -- slot 0x30 = Stop, slot 0x38 = SetVolume
'   0x00C5D224 g_musicvol     :Float
'   0x00C6F130 g_tracks       :TSound[]
'   0x00C6FC38 g_currenttrack :Int       -- globals_final: Int, medium
' 0x00C6FC3C is not a Global: it is the float literal 110.0 in this function's literal pool.
'!Global g_musicchannel:TChannel
'!Global g_musicvol:Float
'!Global g_tracks:TSound[]
'!Global g_currenttrack:Int
	Function PlayTrack:Int(a0:Int)
		UpdateAudio()
		If a0 = 0 Or g_musicvol = 0
			If g_musicchannel <> Null
				g_musicchannel.Stop()
			End If
		ElseIf a0 <> g_currenttrack Or (g_musicvol > 0 And Not g_musicchannel)
			If g_musicchannel <> Null
				g_musicchannel.Stop()
			End If
			g_musicchannel = AllocChannel()
			g_musicchannel.SetVolume(g_musicvol / 110.0)
			If g_tracks[a0 - 1] <> Null
				PlaySound(g_tracks[a0 - 1], g_musicchannel)
			End If
		End If
		g_currenttrack = a0
	End Function
