' TScreen_Stable.ButtonQuit
' VA 0x00588403   161 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (161/161, original length from Ghidra's inventory), harness mode=reloc
' Assumptions (module Globals -- names ours, declared types load-bearing):
'   * 0x00C6DEE4 / 0x00C6DEE8 / 0x00C6DEC0 / 0x00C6DED8 : TPanel  (globals_final, construction)
'   * 0x00C6DEB8 / 0x00C6DEBC : TButton                          (globals_final, construction)
'   * 0x00C6DF64 / 0x00C6DF70 : Int
'   * 0x00C6DF1C : TChannel. globals_final says `Object` (usage, low); it is the sole
'     argument of 0x0059B2A7, whose alias set contains _brl_audio_StopChannel.
'   * slots 0x54 = TGadget.Hide, 0x58 = TGadget.Show -- both inherited by TPanel and TButton.
'   * 0x00C66D04 resolves to class table TScreen_Relationships + 0x34 = SetUpScreen(i)i.
'   * field `hidden` at +0x3C (TGadget).
' SHAPE (measured): the first arm ends with an explicit `Return 0` (mov eax,0 / jmp epilogue),
'   not an Else. Written as If/Else it is 156 bytes; the early return supplies the 5 bytes.
'   The guard is bare int truthiness (`cmp [f],0 / je`); `<> 0` would emit setne/movzx first.
' HARNESS NOTE: needs harness.MODULE_TYPES patched with TChannel -> BRL.Audio, otherwise the
'   probe fails to build with "Unable to convert from 'TChannel' to 'TChannel'".
	'!Global g_stbl_pnl1:TPanel
	'!Global g_stbl_pnl2:TPanel
	'!Global g_stbl_pnl3:TPanel
	'!Global g_stbl_pnl4:TPanel
	'!Global g_stbl_btn1:TButton
	'!Global g_stbl_btn2:TButton
	'!Global g_stable_int02:Int
	'!Global g_stable_int05:Int
	'!Global g_stable_chan:TChannel
	Function ButtonQuit:Int()
		If g_stbl_pnl1.hidden
			g_stbl_pnl1.Show()
			g_stbl_pnl2.Show()
			g_stbl_pnl3.Hide()
			g_stbl_pnl4.Hide()
			g_stbl_btn1.Show()
			g_stbl_btn2.Show()
			Return 0
		EndIf
		g_stable_int02 = 0
		g_stable_int05 = 0
		StopChannel(g_stable_chan)
		TScreen_Relationships.SetUpScreen(0)
	End Function
