' TWinVolume.ListVolumes
' VA 0x005983DE   681 bytes   vtable slot 0x34   sig ():brl.linkedlist.TList
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (681/681, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
'
' 1.06 source, line for line. Edit: `Self.PATH_MAX` -> `PATH_MAX` (the harness emits no
' Type Const; module Const from Fn_00598051.bmx, same $104). Source comments dropped.
' Frame: nameBuffer [ebp-4], pathsBuffer [ebp-8], bufferSize [ebp-0xC], paths array
' [ebp-0x10]/end [ebp-0x14], bitmap [ebp-0x18], handle [ebp-0x1C]; volumes in ebx.
' mpBuffer is allocated and dropped (second bbArrayNew1D, result unused), as in 1.06.
' "~0" is 0x00C9AFFC, ":\" is 0x00C9B00C. TMap Insert 0x38 / Contains 0x3C /
' Values 0x4C; TList 0x00CB0824 AddLast 0x44; EachIn over TMapEnumerator/
' TNodeEnumerator slots 0x30/0x34 with bbObjectDowncast to TVolume.
' `If Not volumes` gives the setne/movzx shape at 0x00598594; `If volumes Then` the
' direct cmp/je at 0x00598606, both as the source has them. GetVolumeInfo(path) is
' the Self method (slot 0x40), not the module Function.
' Needs the module Consts / Extern / Globals declared as pragmas in Fn_00598051.bmx.
	Method ListVolumes:TList()
		Local volumes:TMap

		Local nameBuffer:Short[] = New Short[PATH_MAX]
		Local mpBuffer:Short[] = New Short[PATH_MAX]

		Local handle:Int = FindFirstVolume(nameBuffer, PATH_MAX)
		If handle Then

			volumes = New TMap

			While True

				Local pathsBuffer:Short[] = New Short[PATH_MAX]
				Local bufferSize:Int

				Local paths:String[]

				If GetVolumePathNamesForVolumeName(nameBuffer, pathsBuffer, PATH_MAX, Varptr bufferSize) Then

					paths = String.FromShorts(pathsBuffer, bufferSize).Trim().split("~0")

				Else If bufferSize > PATH_MAX Then

					If GetVolumePathNamesForVolumeName(nameBuffer, pathsBuffer, bufferSize, Varptr bufferSize) Then
						paths = String.FromShorts(pathsBuffer, bufferSize).Trim().split("~0")
					EndIf

				EndIf

				For Local path:String = EachIn paths
					volumes.Insert(path, GetVolumeInfo(path))
				Next

				If Not FindNextVolume(handle, nameBuffer, PATH_MAX) Then
					Exit
				End If
			Wend

			FindVolumeClose(handle)

		End If

		Local bitmap:Int = GetLogicalDrives()

		For Local i:Int = 1 To 26
			If bitmap & 1 Then

				If Not volumes Then
					volumes = New TMap
				End If

				Local path:String = Chr(64 + i) + ":\"

				If Not volumes.Contains(path) Then
					volumes.Insert(path, GetVolumeInfo(path))
				End If

			End If

			bitmap:Shr 1
		Next

		If volumes Then
			Local list:TList = New TList
			For Local volume:TVolume = EachIn volumes.Values()
				list.AddLast(volume)
			Next

			Return list
		Else
			Return Null
		End If

	End Method
