' IsPointNearLine  -- module-level Function (no Type)
' VA 0x005061dd   218 bytes   sig (f,f,f,f,f,f,f)i   mode=reloc, reloc_masked=5
' byte-identical vs NSS5.exe (218/218), verified with NSS5_NO_LEARN=1.
'
' NAME IS OURS. Segment/point occlusion test used by TBall.CanSeePlayer (and presumably
' others): is point (a4,a5) within distance a6 of the SEGMENT from (a0,a1) to (a2,a3)?
' Computes the standard clamped closest-point-on-segment parameter t, the closest point
' itself, and compares its Dist2D to the point against the radius. Calls the already
' -verified `Dist2D` (src/recovered_module/Dist2D.bmx).
'
' CODEGEN NOTES
'   * `dx`/`dy` are Float Locals that DO get reused live on the x87 stack (no reload) for
'     the denominator `dx*dx + dy*dy` -- but the SAME subtractions also appear a second
'     time, spelled out again as literal `a2-a0` / `a3-a1` in the numerator, and THAT
'     occurrence reloads a2/a3 from the parameter slot and recomputes rather than reusing
'     dx/dy. bcc does no CSE (confirmed again here), so which spelling you use determines
'     reload vs reuse -- this is what the byte-exact match hinges on. Without the two
'     Locals declared first, bcc's load order for the whole expression comes out 7 bytes
'     long and in a different order (verified empirically: writing the same formula as one
'     single expression with no Locals gives length 225, not 218).
'   * The two clamp Ifs (`t < 0.0`, `t > 1.0`) are separate solo Ifs, same pattern as
'     `GetInterceptPoint`'s four clamp tests.
'   * `qx`/`qy` are written as `(1.0-t)*a0 + t*a2` (lerp form), not `a0 + t*(a2-a0)` --
'     the multiply-by-(1-t)-then-add-t*target order is what the trace shows.
	Function IsPointNearLine:Int(a0:Float, a1:Float, a2:Float, a3:Float, a4:Float, a5:Float, a6:Float)
		Local dx:Float = a2-a0
		Local dy:Float = a3-a1
		Local t:Float = ((a4-a0)*(a2-a0) + (a5-a1)*(a3-a1)) / (dx*dx + dy*dy)
		If t < 0.0 Then t = 0.0
		If t > 1.0 Then t = 1.0
		Local qx:Float = (1.0-t)*a0 + t*a2
		Local qy:Float = (1.0-t)*a1 + t*a3
		If Dist2D(a4,a5,qx,qy) < a6
			Return 1
		Else
			Return 0
		EndIf
	End Function
