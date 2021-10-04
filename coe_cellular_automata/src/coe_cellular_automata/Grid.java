package coe_cellular_automata;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;

public class Grid {
	int ageThreshold=140, ph=100, pl=10;
	float  minHarvVol = 150L;
	int colSizeLattice = 150; //Size of the grid used for dummy examples
	double lambdaProp = 0.05;
	int ncell;
	int nrow;
	
	int numCells = colSizeLattice*colSizeLattice;
	int numTimePeriods = ph/pl;
	//int[][] grid;
	int[] cellList = new int[numCells];
	public double[] lambda = new double[numTimePeriods];
	public double[] oneMinusLambda = new double[numTimePeriods];
	public double[] alpha = new double[numTimePeriods];
	public double[] beta = new double[numTimePeriods];
	public double[] gamma = new double[numTimePeriods];
	public ArrayList<ArrayList<int[]>> ageStatesTemplate = new ArrayList<ArrayList<int[]>>();
	public ArrayList<ArrayList<int[]>> harvestStatesTemplate = new ArrayList<ArrayList<int[]>>();
	
	double weight = (double) 1/numCells;
	/** 
	* Class constructor.
	*/
	Grid(){
		//Assign the cellList needed for adjacency 
		for(int i =0; i < numCells; i++) {
			cellList[i] = i+1;
		}
		setStatesTemplates(numTimePeriods, pl);
	};
	
	private void setStatesTemplates(int numTimePeriods2, int pl2) {
		ArrayList<ArrayList<int[]>> ageStatesTemplate = new ArrayList<ArrayList<int[]>>() ;
		ArrayList<ArrayList<int[]>> harvestStatesTemplate = new ArrayList<ArrayList<int[]>>();
		
		for(int age = 0; age < 351; age++) { // A total of 250 possible ages
				ArrayList<int[]> states = new ArrayList<int[]>();
				ArrayList<int[]> statesHarvest = new ArrayList<int[]>();
				
				int[] stateZero = new int[numTimePeriods2];
				int[] stateHarvestZero = new int[numTimePeriods2];
				
				for(int ft = 0; ft < numTimePeriods2; ft ++) { // this is always state zero or no harvesting
					int ageFT = 0;
					if(ft == 0) {
						ageFT = age + (int)(pl2/2);
					} else {
						ageFT = age + (int) (pl2*ft + pl2/2);
					}
					
					if(ageFT > 350) {
						stateZero[ft] = 350;
					}else {
						stateZero[ft] = ageFT;
					}					
					stateHarvestZero[ft] = 0;
				}

				states.add(stateZero); //This add state zero which is the no harvest state
				statesHarvest.add(stateHarvestZero);
				
			    //One harvest with nested second harvest
				int[] stateAge = new int[numTimePeriods2];
				stateAge = stateZero.clone();
				
				int[] stateHarvest = new int[numTimePeriods2];
				stateHarvest = stateHarvestZero.clone();
				
				//Counters
				int ft = 0;
				int sh = 0;
				int srp = 0;
				
				for(int harvPeriod = 0; harvPeriod < numTimePeriods2; harvPeriod ++) { // cant harvest in period 0 -- thats now! Which is used for reporting thus 1 is the future assuming a midpoint	
					if(stateAge[harvPeriod] > 50) { // set minimum harvest age --conservatively set to 50 
						for(int rp = 0; rp < numTimePeriods2 ; rp ++) {
							if(harvPeriod == rp) {
								stateHarvest[rp]=stateAge[rp];//assign the age of harvest
								stateAge[rp] = 0;//age the harvest to zero
							} else if (harvPeriod < rp) {
								ft ++;
								stateAge[rp] = (int) (pl2*ft - pl2/2);
								if(stateAge[rp] > 50 & sh == 0) {
									srp = rp;
									sh ++;
								}
							} else {
								continue;
							}				
						}
						states.add(stateAge);
						statesHarvest.add(stateHarvest);
						sh =0;
						
						if(srp > 0) {
							ft = 0;
							for(int m = srp; m <numTimePeriods2; m++ ) {
								int[] stateAgeSecond = new int[numTimePeriods2];
								stateAgeSecond = stateAge.clone();
								
								int[] stateHarvestSecond = new int[numTimePeriods2];
								stateHarvestSecond = stateHarvest.clone();								
								
								for(int k = m; k <numTimePeriods2; k++ ) {
									if(k == m) {
										stateHarvestSecond[k] = stateAgeSecond[k];
										stateAgeSecond[k] = 0;
										
									} else {
										ft ++;
										stateAgeSecond[k]  = (int) (pl2*ft - pl2/2);									
									} 
								}
								states.add(stateAgeSecond);
								statesHarvest.add(stateHarvestSecond);
								ft = 0;
							}
						}
						
						stateAge = stateZero.clone();
						stateHarvest = stateHarvestZero.clone();
						ft = 0;
						srp = 0;
					}
				
				}
				ageStatesTemplate.add(states); // add all the states for a given age
				harvestStatesTemplate.add(statesHarvest); // add all the states for a given age
		}	
    setAgeStatesTemplate (ageStatesTemplate);
    setHarvestStatesTemplate(harvestStatesTemplate);
	}

	private void setHarvestStatesTemplate(ArrayList<ArrayList<int[]>> harvestStatesTemplate) {
		this.harvestStatesTemplate = harvestStatesTemplate;	
	}

	private void setAgeStatesTemplate(ArrayList<ArrayList<int[]>> ageStatesTemplate) {
		this.ageStatesTemplate = ageStatesTemplate;	
	}

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
	
	public void setGrid (int ncell, int nrow) {
		this.ncell = ncell;
		this.nrow = nrow;
		this.colSizeLattice = ncell/nrow;
	}
}
