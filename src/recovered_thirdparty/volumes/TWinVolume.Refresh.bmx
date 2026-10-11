' TWinVolume.Refresh
' VA 0x0059886C   114 bytes   vtable slot 0x30   sig ()i
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (114/114, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
'
' Edit: bare `Return` -> `Return 0`. 1.06 declares `Method Refresh()`, which under
' SuperStrict is VOIDFUN (parser.cpp:500), where a bare Return is legal; the probe
' declares `Refresh:Int()` and bcc then rejects it ("Function must return a value",
' stm.cpp:553). Both evaluate to Int 0: `mov eax,0 / jmp` at 0x00598886.
' `If Not vs` is the setne/movzx shape at 0x00598876; vs.refresh() is TVolSpace slot
' 0x34; tb/fb copied as dword pairs.
	Method Refresh:Int()
		If Not vs Then
			Return 0
		End If

		Local ret:Int = vs.refresh()

		If ret Then
			volumeSize = vs.tb
			volumeFree = vs.fb

			available = True
		Else
			available = False
		End If

	End Method
