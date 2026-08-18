' TCompetition.SetPriority
' VA 0x0050D498  179 bytes  vtable slot 0xb8
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.

	Method SetPriority:Int()
		Select level
			Case 0
				Select locale
					Case 0
						Select comptype
							Case 0
								priority=4
							Case 1
								priority=3
							Case 2
								priority=5
							Case 3
								priority=5
							Case 4
								priority=4
							Case 5
								priority=5
						End Select
					Case 1
						priority=2
					Case 2
						priority=2
				End Select
			Case 1
				priority=1
		End Select
	End Method
