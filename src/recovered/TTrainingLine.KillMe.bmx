' TTrainingLine.KillMe
' VA 0x0058437E   247 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (247/247, original length from Ghidra's inventory)

'!Global g_trainingline_sound:TSound
'!Global g_trainingline_chan:TChannel
'!Global g_training_lines:TList
Select colour
	Case "FF0000"
	Case "00FF00"
		PlaySound(g_trainingline_sound, g_trainingline_chan)
		alive = 0
		g_training_lines.Remove(Self)
		ActivateNextLine()
	Case "0000FF"
		PlaySound(g_trainingline_sound, g_trainingline_chan)
		alive = 0
		g_training_lines.Remove(Self)
	Case "00FFFF"
		PlaySound(g_trainingline_sound, g_trainingline_chan)
		alive = 0
		g_training_lines.Remove(Self)
End Select
