//For each address given via -scriptArgs, report the containing function and decompile it.
//@category NSS5
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;

public class NSS5Where extends GhidraScript {
    public void run() throws Exception {
        String[] args = getScriptArgs();
        DecompInterface d = new DecompInterface();
        d.openProgram(currentProgram);
        for (String a : args) {
            for (String one : a.split(",")) {
                one = one.trim();
                if (one.isEmpty()) continue;
                Address ad = currentProgram.getAddressFactory().getAddress(one);
                Function f = getFunctionContaining(ad);
                if (f == null) { println("### NOFUNC " + one); continue; }
                println("### BEGIN " + one + " containing=" + f.getEntryPoint() + " " + f.getName());
                DecompileResults r = d.decompileFunction(f, 90, monitor);
                if (r.decompileCompleted()) println(r.getDecompiledFunction().getC());
                else println("### FAILED " + r.getErrorMessage());
                println("### END " + one);
            }
        }
        d.dispose();
    }
}
