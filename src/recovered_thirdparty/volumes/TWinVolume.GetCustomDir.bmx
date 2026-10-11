' TWinVolume.GetCustomDir
' VA 0x0059893A   76 bytes   vtable slot 0x54   sig (i)$
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (76/76, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names: a0.. as the harness emits them (1.06 source name in the note)
'
' a0 is `dirType`. Select compiles to cmp 2/3/4 chain; pushes 0x27/0xD/0xE
' (CSIDL_MYPICTURES/MYMUSIC/MYVIDEO) into slot 0x5C. `Return Null` for a String is
' bbEmptyString 0x005C7D40.
' Needs the module Consts / Extern / Globals declared as pragmas in Fn_00598051.bmx.
	Method GetCustomDir:String(a0:Int)
		Select a0
			Case DT_USERPICTURES
				Return _getFolderPath(CSIDL_MYPICTURES)
			Case DT_USERMUSIC
				Return _getFolderPath(CSIDL_MYMUSIC)
			Case DT_USERMOVIES
				Return _getFolderPath(CSIDL_MYVIDEO)
		End Select

		Return Null
	End Method
