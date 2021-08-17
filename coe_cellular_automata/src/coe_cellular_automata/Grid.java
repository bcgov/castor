package coe_cellular_automata;

import java.util.Arrays;

public class Grid {
	int ageThreshold=140, ph=200, pl=10;
	double  minHarvVol = 120.0;
	int colSizeLattice = 50; //Size of the grid used for dummy examples
	double lambdaProp = 0.01;
	
	int numCells = colSizeLattice*colSizeLattice;
	int numTimePeriods = ph/pl;
	int[][] grid;
	int[] cellList = new int[numCells];
	public double[] lambda = new double[numTimePeriods];
	public double[] oneMinusLambda = new double[numTimePeriods];
	public double[] alpha = new double[numTimePeriods];
	public double[] beta = new double[numTimePeriods];
	public double[] gamma = new double[numTimePeriods];
	
	/** 
	* Class constructor.
	*/
	Grid(){
		//Assign the cellList needed for adjacency 
		for(int i =0; i < numCells; i++) {
			cellList[i] = i+1;
		}
	};
	
	/** 
	* Sets the global penalties needed to incentivize cell level decisions
	*/
	public void setPenaltiesBlank() {
		Arrays.fill(lambda, lambdaProp);
		Arrays.fill(alpha, 0.0);
		Arrays.fill(beta, 0.0);
		Arrays.fill(gamma, 0.0);
		
		oneMinusLambda = subtractScalar(1, lambda);
	}
	
	 /**
     * Setter for the global or landscape level penalties
     * @param alpha		a double array of the alpha penalties that correspond to min harvest
     * @param beta		a double array of the beta penalties that correspond to max harvest
     * @param gamma		a double array of the beta penalties that correspond to late-seral forest
     */
	public void setPenalties(double[] alpha, double[] beta, double [] gamma){
		this.alpha = alpha;
		this.beta = beta;
		this.gamma = gamma;
	}
	
	
	 /**
     * Takes the element wise difference between a scalar and a vector where the scalar is first
     * @param vector1	an Array of doubles with length equal to the number of time periods
     * @param scalar	a scalar
     * @return 		a vector of length equal to the number of time periods
     * @see subtractVector
     */
	private double[] subtractScalar (double scalar, double[] vector1) {
		double[] outVector = new double[vector1.length];
		for(int i =0; i < outVector.length; i++) {
			outVector[i] = scalar - vector1[i];
		}
		return outVector;
	}
}
