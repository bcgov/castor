package castor;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;

public class Grid {
	int ageThreshold=140, ph=150, pl=5;
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
	public ArrayList<ArrayList<float[]>> ageStatesTemplate = new ArrayList<ArrayList<float[]>>();
	public ArrayList<ArrayList<float[]>> harvestStatesTemplate = new ArrayList<ArrayList<float[]>>();
	
	double weight;
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
		ArrayList<ArrayList<float[]>> ageStatesTemplate = new ArrayList<ArrayList<float[]>>() ;
		ArrayList<ArrayList<float[]>> harvestStatesTemplate = new ArrayList<ArrayList<float[]>>();
		
		for(int age = 0; age < 351; age++) { // A total of 350 possible ages
				ArrayList<float[]> states = new ArrayList<float[]>();
				ArrayList<float[]> statesHarvest = new ArrayList<float[]>();
				
				float[] stateZero = new float[numTimePeriods2];
				float[] stateHarvestZero = new float[numTimePeriods2];
				
				for(int ft = 0; ft < numTimePeriods2; ft ++) { // this is always state zero or no harvesting
					float ageFT = 0f;
					if(ft == 0) {
						ageFT = (float) (age + (int)(pl2/2));
					} else {
						ageFT = (float) ( age + (int) (pl2*ft + pl2/2));
					}
					
					if(ageFT > 350) {
						stateZero[ft] = 350f;
					}else {
						stateZero[ft] = ageFT;
					}					
					stateHarvestZero[ft] = 0f;
				}

				states.add(stateZero); //This add state zero which is the no harvest state
				statesHarvest.add(stateHarvestZero);
				
			    //One harvest with nested second harvest
				float[] stateAge = new float[numTimePeriods2];
				stateAge = stateZero.clone();
				
				float[] stateHarvest = new float[numTimePeriods2];
				stateHarvest = stateHarvestZero.clone();
				
				//Counters
				int ft = 0;
				int sh = 0;
				int srp = 0; //second
				int th =0;
				int trp = 0; //third
				
				for(int harvPeriod = 0; harvPeriod < numTimePeriods2; harvPeriod ++) { // cant harvest in period 0 -- thats now! Which is used for reporting thus 1 is the future assuming a midpoint	
					if(stateAge[harvPeriod] >= 50) { // set minimum harvest age --conservatively set to 50 
						for(int rp = 0; rp < numTimePeriods2 ; rp ++) {
							if(harvPeriod == rp) {
								stateHarvest[rp]=stateAge[rp];//assign the age of harvest
								stateAge[rp] = 0f;//age the harvest to zero
							} else if (harvPeriod < rp) {
								ft ++;
								stateAge[rp] = (float) ((int) (pl2*ft - pl2/2));
								if(stateAge[rp] >= 50 & sh == 0) {
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
							for(int m = srp; m < numTimePeriods2; m++ ) {
								float[] stateAgeSecond = new float[numTimePeriods2];
								stateAgeSecond = stateAge.clone();
								
								float[] stateHarvestSecond = new float[numTimePeriods2];
								stateHarvestSecond = stateHarvest.clone();								
								
								for(int k = m; k < numTimePeriods2; k++ ) {
									if(k == m) {
										stateHarvestSecond[k] = stateAgeSecond[k];
										stateAgeSecond[k] = 0f;
										
									} else {
										ft ++;
										stateAgeSecond[k]  = (float)((int) (pl2*ft - pl2/2));	
										if(stateAgeSecond[k] >= 50 & th == 0) {
											trp = k;
											th ++; // a counter to find the earliest period for a third harvest
										}
									} 
								}
								
								states.add(stateAgeSecond);
								statesHarvest.add(stateHarvestSecond);
								ft = 0;
								th = 0 ;
								
								if(trp > 0) {
									for(int h = trp; h < numTimePeriods2; h++ ) {
										float[] stateAgeThird = new float[numTimePeriods2];
										stateAgeThird = stateAgeSecond.clone();
										
										float[] stateHarvestThird = new float[numTimePeriods2];
										stateHarvestThird = stateHarvestSecond.clone();
										
										for(int f = h; f <numTimePeriods2; f++ ) {
											if(f == h) {
												stateHarvestThird[f] = stateAgeThird[f];
												stateAgeThird[f] = 0f;
												
											} else {
												ft ++;
												stateAgeThird[f]  = (float)((int) (pl2*ft - pl2/2));									
											} 
										}
										
										states.add(stateAgeThird);
										statesHarvest.add(stateHarvestThird);
										ft = 0;
									}
									
								}
								trp = 0;
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

	private void setHarvestStatesTemplate(ArrayList<ArrayList<float[]>> harvestStatesTemplate) {
		this.harvestStatesTemplate = harvestStatesTemplate;	
	}

	private void setAgeStatesTemplate(ArrayList<ArrayList<float[]>> ageStatesTemplate) {
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

	public void setLandscapeWeight(double weight) {
		this.weight = weight;	
	}
	
	public void setLandscapeParameters(int ageThres, int planHorizon, int planLength, float minHarvestVolume) {
		ageThreshold = ageThres; 
		ph = planHorizon; 
		pl = planLength;
		minHarvVol = minHarvestVolume;
	}
}
