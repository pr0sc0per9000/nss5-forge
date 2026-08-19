' TMyVector.RotateAroundV
' VA 0x004E2594   271 bytes   mode=reloc
' byte-identical vs NSS5.exe
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
Local c:Double = Cos(a1)
Local s:Double = Sin(a1)
Local t:Double = 1.0 - c
Local x:Double = Self.X
Local y:Double = Self.Y
Local z:Double = Self.Z
Self.X = x*(c + a0.X*a0.X*t) + y*(a0.X*a0.Y*t - a0.Z*s) + z*(a0.X*a0.Z*t + a0.Y*s)
Self.Y = x*(a0.Y*a0.X*t + a0.Z*s) + y*(c + a0.Y*a0.Y*t) + z*(a0.Y*a0.Z*t - a0.X*s)
Self.Z = x*(a0.Z*a0.X*t - a0.Y*s) + y*(a0.Z*a0.Y*t + a0.X*s) + z*(c + a0.Z*a0.Z*t)
Return Self
