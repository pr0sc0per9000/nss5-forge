' TBlackJack.Draw
' VA 0x0057734E   549 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static method on the Type, no implicit Self), SIG=()i, class-table slot 0x54
' ORACLE 549/549 reloc_masked=23, first attempt.
'
' ASSUMPTIONS / RESOLUTIONS
'   Globals (names are OURS; the TYPES are load-bearing):
'     0x00C6EFDC -> g_screenw:Int          0x00C6EFE0 -> g_screenh:Int
'     0x00C6C16C -> g_hand1:TList          0x00C6C170 -> g_hand2:TList
'       (same two Globals TBlackJack.Reset declares as g_hand1/g_hand2; slot 0x8C
'        ObjectEnumerator, elements downcast against ClassTable_TCard at 0x00C6C450)
'     0x00C6C17C -> g_bj3:Int              (TBlackJack.Reset's third Int)
'     0x00C6C34C -> g_cardback:TImage      (DrawImage's first argument)
'   Calls: 0x005AD711 = _brl_max2d_DrawImage, 0x005AE3C5 = _brl_max2d_ImageWidth,
'     0x005B9690 = _bbFloatToInt (emitted for Int(x)), 0x004A8F60 = _bbObjectDowncast.
'   TCard field +0x08 = img:TImage (object_model.json).
'   .rdata floats read out of NSS5.exe: 0x00C90ED8 = 0.3, 0x00C90EDC = 0.3.
'
' CODEGEN NOTES
'   `(D + (D >> 0x1f & 1)) >> 1` is signed `Int / 2`, not a hand-written shift.
'   The per-card advance is a real Float Local: the original does
'     mov [ebp-4],Float(x) / fild width / fmul 0.3 / fld [ebp-4] / faddp / fstp [ebp-4]
'   which is `Local fx:Float = x` then `fx :+ ...`, then `x = Int(fx)`. Inlining it as
'   x = Int(x + ImageWidth(...)*0.3) has no place to spill the running sum.
'   `x` and `y` are REASSIGNED for the second hand (same esi / same [ebp-0x18] slot), not
'   redeclared.
'   The face-up test is a short-circuit `Or`: mov eax,[g_bj3] / cmp 0 / jne past the
'   second test / cmp edi,1 / sete / movzx, then one `cmp eax,0` for both.
	Function Draw:Int()
		'!Global g_screenw:Int
		'!Global g_screenh:Int
		'!Global g_hand1:TList
		'!Global g_hand2:TList
		'!Global g_bj3:Int
		'!Global g_cardback:TImage
		Local x:Int = g_screenw / 2 - 100
		Local y:Int = g_screenh / 2 + 100
		For Local c:TCard = EachIn g_hand1
			DrawImage(c.img, x, y, 0)
			Local fx:Float = x
			fx :+ ImageWidth(c.img) * 0.3
			x = Int(fx)
		Next
		Local n:Int = 1
		x = g_screenw / 2 - 100
		y = g_screenh / 2 - 100
		For Local c2:TCard = EachIn g_hand2
			If g_bj3 Or n = 1
				DrawImage(c2.img, x, y, 0)
			Else
				DrawImage(g_cardback, x, y, 0)
			EndIf
			Local fx2:Float = x
			fx2 :+ ImageWidth(c2.img) * 0.3
			x = Int(fx2)
			n :+ 1
		Next
	End Function
