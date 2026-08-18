' TScreen_Negotiate.ButtonHigher
' VA 0x0057A752   150 bytes   vtable slot 0x3C   sig ()i
' byte-identical vs NSS5.exe (150/150, original length from Ghidra's inventory, mode=reloc)
' module Globals assumed (names ours, types load-bearing):
'   0x00C6CC40 : Int    0x00C6CC44 : Int    0x00C6CC48 : Int    0x00C6EFD4 : Int
'     (globals_final types 0x00C6EFD4 as TScreen with a TButton/TScreen conflict, but here
'      it is copied dword-for-dword into an Int slot, so Int is what codegen needs)
'   0x00C6CBFC, 0x00C6CC00, 0x00C6CC0C : TButton (construction-typed, confidence medium)
'   TGadget.alive is +0x38; slot 0x70 is TGadget.SetAlph(f), inherited by TButton.
'   0x3F000000 is the Float constant 0.5.
' The `cmp [g],4 / jle body / mov eax,0 / jmp end` head is an EARLY RETURN guard.
' Wrapping the body in `If g < 5 ... End If` instead comes out 143 bytes, not 150.

	Function ButtonHigher:Int()
		'!Global g_neg_count:Int
		'!Global g_neg_value:Int
		'!Global g_neg_flag:Int
		'!Global g_neg_base:Int
		'!Global g_neg_btn1:TButton
		'!Global g_neg_btn2:TButton
		'!Global g_neg_btn3:TButton
		If g_neg_count > 4 Then Return 0
		g_neg_count = g_neg_count + 1
		g_neg_flag = 1
		g_neg_value = g_neg_base
		g_neg_btn1.alive = 0
		g_neg_btn1.SetAlph(0.5)
		g_neg_btn2.alive = 0
		g_neg_btn2.SetAlph(0.5)
		g_neg_btn3.alive = 0
		g_neg_btn3.SetAlph(0.5)
	End Function
