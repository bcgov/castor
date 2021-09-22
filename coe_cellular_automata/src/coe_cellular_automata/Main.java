package coe_cellular_automata;

import java.sql.SQLException;

public class Main {

	public static void main(String[] args) throws Exception {
		// TODO Auto-generated method stub
		 if (args.length != 4) {
	            System.err.println("Usage: java coe_cellular_automata <clusdb> <Parameters>");
	            CellularAutomata ca = new CellularAutomata();
	            ca.createData2();
	            ca.simulate2();
		 }else {
			 CellularAutomata ca = new CellularAutomata();
			 //ca.setRParms();
		 }
	}

}