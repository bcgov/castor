package castor;

public class Main {

	public static void main(String[] args) throws Exception {
		// TODO Auto-generated method stub
		 if ((args.length == 4)) {
	         System.err.println("Usage: java coe_cellular_automata <clusdb> <Parameters>");
	         CellularAutomata ca = new CellularAutomata();
	         ca.getCastorData();
	         ca.coEvolutionaryCellularAutomata();
		 }else {
			 Q3 q3 = new Q3();
			 q3.lpModel1();
			 //ca.setRParms();
		 }
	}

}