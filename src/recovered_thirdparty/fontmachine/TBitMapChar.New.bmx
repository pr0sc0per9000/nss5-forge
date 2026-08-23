' TBitMapChar.New
' VA 0x00592404   80 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (80/80, mode=reloc)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' Every store in the body is a FIELD DEFAULT, not a body statement, and the body is empty.
' Same reasoning as TPrivateBitmapFont.New.bmx: declaring all six as '!Field defaults lets
' bmk emit them together in field order, which is the order the original uses. The
' `Image:TImage = Null` pragma is required even though Null is the implicit default --
' an object field with NO declared default is the zero-code case, and this one is not
' zero code: the original really does `mov eax,&bbNullObject / inc [eax+4] / mov [ebx+0x1c],eax`.

	Method New()
		'!Field DrawOffsetX:Int = 0
		'!Field DrawOffsetY:Int = 0
		'!Field DrawWidth:Int = 0
		'!Field DrawHeight:Int = 0
		'!Field Charwidth:Int = 0
		'!Field Image:TImage = Null
	End Method
