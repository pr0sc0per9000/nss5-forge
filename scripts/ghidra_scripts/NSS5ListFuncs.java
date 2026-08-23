//List functions whose name matches a substring given via scriptArgs, plus their addr/size.
//@category NSS5
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;

public class NSS5ListFuncs extends GhidraScript {
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String needle = args.length > 0 ? args[0].toLowerCase() : "";
        FunctionIterator fi = currentProgram.getFunctionManager().getFunctions(true);
        while (fi.hasNext()) {
            Function f = fi.next();
            if (needle.isEmpty() || f.getName().toLowerCase().contains(needle)) {
                println("FUNC " + f.getEntryPoint() + " size=" + f.getBody().getNumAddresses() + " name=" + f.getName());
            }
        }
    }
}
