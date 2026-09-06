' TZipEngineStreamFactory.CreateStream
' VA 0x0058F628   231 bytes   vtable slot 0x30   sig (:Object,$,$,i,i):brl.stream.TStream
' byte-identical vs NSS5.exe (231/231, mode=reloc, NSS5_NO_LEARN=1)
' THIRD-PARTY MODULE (zipengine) -- this body must NOT be moved into src/recovered/.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
'
' This is the hook into BlitzMax's stream system -- the entry point the game reaches when
' it opens a zipped asset. The factory only answers to the protocol "zipe", and the url
' syntax is
'     zipe::<zipfile>::<entry inside the zip>[::<password>]
' so the path half is split on "::" and must yield 2 or 3 fields. a3/a4 are readable and
' writeable; a write request only logs a warning and is otherwise ignored, because these
' streams are read-only. Every rejection returns Null, which is what makes BlitzMax move on
' to the next registered factory.
'
' parts.Dimensions()[0], NOT parts.length. That is measured, not taste: .length compiles to
' a direct mov eax,[arr+0x14] field read (this same probe came out 199 bytes that way),
' whereas the original calls 0x004A6400 three times and reads +0x18 of the RESULT, which is
' element 0 of the Int[] that .Dimensions() returns. 0x004A6400 is bbArrayDimensions by
' direct identification -- it returns the shared empty array when dims is 0, else allocates
' an Int[dims] and fills it with scales[i]/scales[i+1], which is blitz_array.c's
' bbArrayDimensions exactly. Recorded through the harness's learn path, then this body was
' re-verified from scratch under NSS5_NO_LEARN=1.
'
' The three locals zipfile/filename/pw are load-bearing, not cosmetic: written inline as
' arguments the frame needs one fewer spill slot and the prologue becomes sub esp,4 against
' the original's sub esp,8.

	Method CreateStream:TStream(a0:Object, a1:String, a2:String, a3:Int, a4:Int)
		Local st:TStream = Null
		If a1 = "zipe"
			If a4 Or Not a3 Then DebugLog "WARNING: ZipEngine streams are read-only"
			Local parts:String[] = a2.Split("::")
			If parts.Dimensions()[0] < 2 Or parts.Dimensions()[0] > 3
				DebugLog "Invalid syntax for URL (ex. zipe::zipfilename::file_in_zip::password)"
			Else
				Local zipfile:String = parts[0]
				Local filename:String = parts[1]
				Local pw:String
				If parts.Dimensions()[0] = 3 Then pw = parts[2]
				st = TZipEStream.Create(zipfile, filename, 0, pw)
			EndIf
		EndIf
		Return st
	End Method
