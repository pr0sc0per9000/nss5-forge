' TOptions.GetButtonIcon
' VA 0x004E2B71   201 bytes   vtable slot 0x38   sig (i,i):TImage
' byte-identical vs NSS5.exe (201/201, original length from Ghidra's inventory)
' The leading If with an empty body is real: the original emits cmp [g],2 / jne +0 and nothing else.
' Outer Select on the global, inner Select on a0; Default bodies are emitted inline directly after the dispatch, with no trailing jump.
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_options_int01:Int
'   Global g_Object55:TImage
'   Global g_Object56:TImage
'   Global g_options_arr12:TImage[]
'   Global g_options_arr13:TImage[]

	Function GetButtonIcon:TImage(a0:Int, a1:Int)
		'!Global g_options_int01:Int
		'!Global g_Object56:TImage
		'!Global g_Object55:TImage
		'!Global g_options_arr13:TImage[]
		'!Global g_options_arr12:TImage[]
		If g_options_int01 = 2
		EndIf
		Select g_options_int01
		Case 0
			Return Null
		Default
			Select a0
			Case -1
				If a1 Then Return g_Object56 Else Return g_Object55
			Case -2
				If a1 Then Return g_Object56 Else Return g_Object55
			Case -3
				If a1 Then Return g_Object56 Else Return g_Object55
			Case -4
				If a1 Then Return g_Object56 Else Return g_Object55
			Default
				If a0 < 0 Or a0 > 15 Then Return Null
				If a1 Then Return g_options_arr13[a0] Else Return g_options_arr12[a0]
			End Select
		End Select
	End Function
