//Find FPU instructions (FILD/FMUL/FDIV/FDIVP/FMULP etc) within a function given by scriptArgs[0]=addr
//@category NSS5
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;

public class NSS5FindFPU extends GhidraScript {
    public void run() throws Exception {
        String[] args = getScriptArgs();
        Address a = currentProgram.getAddressFactory().getAddress(args[0]);
        Function f = getFunctionContaining(a);
        if (f == null) { println("NOFUNC"); return; }
        println("### function " + f.getName() + " @ " + f.getEntryPoint() + " size=" + f.getBody().getNumAddresses());
        InstructionIterator ii = currentProgram.getListing().getInstructions(f.getBody(), true);
        while (ii.hasNext()) {
            Instruction ins = ii.next();
            String m = ins.getMnemonicString().toUpperCase();
            if (m.startsWith("F") || m.contains("SS") || m.contains("CVT") || m.contains("MUL") || m.contains("DIV")) {
                println(ins.getAddress() + "  " + ins);
            }
        }
    }
}
