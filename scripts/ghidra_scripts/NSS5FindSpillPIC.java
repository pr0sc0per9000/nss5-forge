//Locate get_pc_thunk-style PIC base setup, resolve callers' PIC base, and search each
//containing function for scalar displacements matching our two target string addresses.
//@category NSS5
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceIterator;
import ghidra.program.model.symbol.RefType;
import ghidra.program.model.scalar.Scalar;
import ghidra.program.model.lang.Register;
import java.util.ArrayList;
import java.util.List;

public class NSS5FindSpillPIC extends GhidraScript {

    long[] targets = new long[] { 0x4cdbcL, 0x4cd9aL };
    int debugCount = 0;

    public void run() throws Exception {
        // Step 1: find thunk-like functions: <=6 bytes, body is MOV reg,[ESP] ; RET
        List<Function> thunks = new ArrayList<>();
        FunctionIterator fi = currentProgram.getFunctionManager().getFunctions(true);
        while (fi.hasNext()) {
            Function f = fi.next();
            if (monitor.isCancelled()) break;
            long len = f.getBody().getNumAddresses();
            if (len < 2 || len > 8) continue;
            InstructionIterator ii = currentProgram.getListing().getInstructions(f.getBody(), true);
            List<Instruction> insns = new ArrayList<>();
            while (ii.hasNext()) insns.add(ii.next());
            if (insns.size() != 2) continue;
            Instruction i0 = insns.get(0);
            Instruction i1 = insns.get(1);
            if (!i0.getMnemonicString().equalsIgnoreCase("MOV")) continue;
            if (!i1.getMnemonicString().equalsIgnoreCase("RET")) continue;
            // check i0 reads [esp]
            String rep = i0.toString();
            if (!rep.contains("ESP")) continue;
            thunks.add(f);
            println("### THUNK CANDIDATE: " + f.getName() + " @ " + f.getEntryPoint() + "  insn0=" + i0);
        }

        if (thunks.isEmpty()) {
            println("### NO THUNK FUNCTIONS FOUND via pattern match. Trying name-based search.");
            fi = currentProgram.getFunctionManager().getFunctions(true);
            while (fi.hasNext()) {
                Function f = fi.next();
                String nm = f.getName();
                if (nm.toLowerCase().contains("get_pc_thunk") || nm.toLowerCase().contains("__x86") ) {
                    thunks.add(f);
                    println("### NAME-MATCH THUNK: " + nm + " @ " + f.getEntryPoint());
                }
            }
        }

        println("### Total thunk candidates: " + thunks.size());

        for (Function thunk : thunks) {
            if (monitor.isCancelled()) break;
            ReferenceIterator refs = currentProgram.getReferenceManager().getReferencesTo(thunk.getEntryPoint());
            int refCount = 0;
            while (refs.hasNext()) {
                Reference r = refs.next();
                refCount++;
                println("### REF to thunk " + thunk.getName() + " from " + r.getFromAddress() + " type=" + r.getReferenceType());
                if (r.getReferenceType() != RefType.UNCONDITIONAL_CALL && !r.getReferenceType().isCall()) continue;
                Address callAddr = r.getFromAddress();
                Instruction callInsn = currentProgram.getListing().getInstructionAt(callAddr);
                if (callInsn == null) { continue; }
                Address retAddr = callInsn.getAddress().add(callInsn.getLength());
                // Darwin-style PIC: no separate ADD. EBX/ECX == retAddr itself; later
                // LEA reg,[EBX + disp] where disp = target - retAddr directly.
                long candidateBase = retAddr.getOffset();

                Function containing = getFunctionContaining(callAddr);
                String fname = containing != null ? containing.getName() + "@" + containing.getEntryPoint() : "???";

                for (long t : targets) {
                    long neededDisp = t - candidateBase;
                    // search within containing function for a matching scalar
                    if (containing == null) continue;
                    InstructionIterator ii2 = currentProgram.getListing().getInstructions(containing.getBody(), true);
                    while (ii2.hasNext()) {
                        Instruction ins = ii2.next();
                        int numOps = ins.getNumOperands();
                        for (int op = 0; op < numOps; op++) {
                            Object[] objs = ins.getOpObjects(op);
                            for (Object o : objs) {
                                if (o instanceof Scalar) {
                                    long v = ((Scalar) o).getSignedValue();
                                    if (v == neededDisp) {
                                        println("### MATCH target=0x" + Long.toHexString(t)
                                            + " thunkCallAt=" + callAddr
                                            + " candidateBase=0x" + Long.toHexString(candidateBase)
                                            + " neededDisp=0x" + Long.toHexString(neededDisp & 0xffffffffL)
                                            + " foundAt=" + ins.getAddress()
                                            + " insn=[" + ins + "]"
                                            + " inFunction=" + fname);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            println("### thunk " + thunk.getName() + " total refCount=" + refCount);
        }
        println("### DONE");
    }
}
