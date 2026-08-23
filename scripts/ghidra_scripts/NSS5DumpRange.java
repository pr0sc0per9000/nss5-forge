//Dump disassembly for an address range given as -scriptArgs start,end (hex, no 0x needed or with 0x)
//@category NSS5
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;

public class NSS5DumpRange extends GhidraScript {
    public void run() throws Exception {
        String[] args = getScriptArgs();
        Address start = currentProgram.getAddressFactory().getAddress(args[0]);
        Address end = currentProgram.getAddressFactory().getAddress(args[1]);
        InstructionIterator ii = currentProgram.getListing().getInstructions(start, true);
        while (ii.hasNext()) {
            Instruction ins = ii.next();
            if (ins.getAddress().compareTo(end) > 0) break;
            println(ins.getAddress() + "  " + ins);
        }
    }
}
