package coe_cellular_automata;

import java.util.Arrays;

public class Grid {
	int ageThreshold=50, ph=100, pl=10;
	double  minHarvVol = 100.0;
	int colSizeLattice = 10; //Size of the grid used for dummy examples
	int numCells = colSizeLattice*colSizeLattice;;
	int numTimePeriods = ph/pl;
	int[][] grid;
	int[] cellList = new int[numCells];
	public double[] lambda = new double[numTimePeriods];
	public double[] alpha = new double[numTimePeriods];
	public double[] beta = new double[numTimePeriods];
	public double[] gamma = new double[numTimePeriods];
	
	Grid(){
		//Assign the cellList needed for adjacency 
		for(int i =0; i < numCells; i++) {
			cellList[i] = i+1;
		}
	};
	
	public void setPenalties() {
		Arrays.fill(lambda, 0.5);
		Arrays.fill(alpha, 0.0);
		Arrays.fill(beta, 0.0);
		Arrays.fill(gamma, 0.0);
	}

}
