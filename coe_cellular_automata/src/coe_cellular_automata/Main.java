package coe_cellular_automata;
public class Main {

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		 if (args.length != 4) {
	            System.err.println("Usage: java coe_cellular_automata <Attributes> <Adjacency> <Iterations> <Lambda>");
	            System.out.println("Creating a test run...");
	            CellularAutomata ca = new CellularAutomata();
	            ca.createData();
	            ca.simulate2();
		 }else {
			 CellularAutomata ca = new CellularAutomata();
			 ca.setRParms();
		 }
	}

}