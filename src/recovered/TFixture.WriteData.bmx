' TFixture.WriteData
' VA 0x004C2E72   581 bytes   mode=reloc   MATCH 581/581
' byte-identical vs NSS5.exe
' KIND=Method on TFixture, SIG=(:TStream)i, SLOT=0x38
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'   No Globals. Fields are object_model.json's TFixture layout, +0x08..+0x40, all Int.
'   0x004A7AC0 = _bbStringFromInt, 0x004A7C20 = _bbStringConcat (runtime_helpers.tsv);
'   0x005B8307 = _brl_stream_WriteLine (brl_functions.tsv).
'   The separator literal at 0x00C6FCC0 is a TAB, read with harness.read_string.
'
'   SOURCE FORM -- this is the load-bearing part. A single `a + "~t" + b + "~t" + ...`
'   expression compiles to 549 bytes, not 581, and evaluates RIGHT-to-LEFT (it starts with
'   compid and stacks 15 pending pushes); explicit parentheses in either direction change
'   nothing, so bcc re-associates the chain. The original instead saves the running string
'   in EBX and re-loads it as the LEFT operand of the next concat (`call Concat / add esp,8
'   / mov ebx,eax`, repeated), which is a register-allocated String Local accumulated one
'   statement at a time. `s :+ <field> + "~t"` groups the whole RHS first, which is exactly
'   the observed `Concat(IntToStr(f),"~t")` followed by `Concat(s, that)`.
Local s:String = Self.sdate + "~t"
s :+ Self.matchtype + "~t"
s :+ Self.round + "~t"
s :+ Self.groupno + "~t"
s :+ Self.leg + "~t"
s :+ Self.hometeam + "~t"
s :+ Self.awayteam + "~t"
s :+ Self.result + "~t"
s :+ Self.resulttype + "~t"
s :+ Self.score1 + "~t"
s :+ Self.score2 + "~t"
s :+ Self.penscore1 + "~t"
s :+ Self.penscore2 + "~t"
s :+ Self.level + "~t"
s :+ Self.compid + "~t"
WriteLine(a0, s)
