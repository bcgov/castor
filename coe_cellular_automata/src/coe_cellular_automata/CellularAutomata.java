package coe_cellular_automata;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Random;
import java.util.stream.DoubleStream;

public class CellularAutomata {
	ArrayList<Cell> cellList = new ArrayList<Cell>();
	ArrayList<Cell> cellListMaximum = new ArrayList<Cell>();
	int numIter=15000;
	double lateSeralTarget,harvestMax,harvestMin, objValue, maxObjValue;
	boolean finalPlan = false;
	
	Grid landscape = new Grid();//Instantiate the GRID
	double[] planHarvestVolume = new double[landscape.numTimePeriods];
	double[] planLateSeral = new double[landscape.numTimePeriods];
	double[] maxPlanHarvestVolume = new double[landscape.numTimePeriods];
	double[] maxPlanLateSeral = new double[landscape.numTimePeriods];
	ArrayList<ArrayList<LinkedHashMap<String, Double>>> yields = new ArrayList<ArrayList<LinkedHashMap<String, Double>>>();
	
	/** 
	* Class constructor.
	*/
	public CellularAutomata() {
	}
	
	/** 
	* Simulates the cellular automata. This is the main algorithm for searching the decision space. 
	* 1. global level penalties are determined which incentivize cell level decisions
	* 2. create a vector of randomly sampled without replacement cell indexes 
	* 3. the first random cell is tested if its at maximum state which includes context independent values such as
	* the maximum amount of volume the cell can produce of the planning horizon and context dependent values such as
	* its contribution, as well as, the surrounding cells contribution to late-seral forest targets. 
	* 4. If already at max state then proceed to the next cell. Else update to its max state.
	* 5. If there are no more stands to change or the number of iterations has been reached - end.
	* 
	*/
	public void simulate() {
		int block = 0;
		int numIterSinceFreq = 0;
		int[] blockParams = {0, 2000, 4000,7000,10000, 1000000}; // add a large number so there's no out of bounds issues
		int[] freqParams = {0, 300,200,100,1,1};
		boolean timeToSetPenalties = false;
		int [] maxStates = new int[cellList.size()];
		landscape.setPenaltiesBlank();//set penalty parameters - alpha, beta and gamma as zero filled arrays
		
		for(int i=0; i < numIter; i++) { // Iteration loop
					
			if(i >= blockParams[block+1]) { // Go to the next block
				block ++;
			}
			
			if(block > 0 && numIterSinceFreq >= freqParams[block]) { // Calculate at the freq level
				timeToSetPenalties = true;
				numIterSinceFreq = 0;
			}
				
			numIterSinceFreq ++;
			
			Arrays.fill(planHarvestVolume, 0.0); //set the harvestVolume indicator
			Arrays.fill(planLateSeral, 0.0); //set the late-seral forest indicator
			objValue = 0.0; //reset the object value;
			
			int[] rand = new Random().ints(0, cellList.size()).distinct().limit(cellList.size()).toArray();; // Randomize the stand or cell list
			
			for(int j = 0; j < rand.length; j++) { //Stand or cell list loop
				int maxState = getMaxState(rand[j]);
				if(cellList.get(rand[j]).state == maxState) { //When the cell is at its max state - go to the next cell
					//System.out.println("Cell:" + cellList.get(rand[j]).id + " already at max");
					if(j == cellList.size()-1) {
						finalPlan = true;
					}
					continue; // Go to the next cell -- this one is already at its max
				}else{ // Change the state of the cell to its max state and then exit the stand or cell list loop
					System.out.println("Cell:" + cellList.get(rand[j]).id + " change from " + cellList.get(rand[j]).state + " to " + maxState );
					cellList.get(rand[j]).state = maxState; //transition function - set the new state to the max state
					break;
				}
				
			}
			
			//Output the global indicators (aggregate all cell level values)
			for(int c =0; c < cellList.size(); c++) {// Iterate through each of the cell and their corresponding state
				int state = cellList.get(c).state;
				double isf, dsf;
					
				//isf = DoubleStream.of(multiplyVector(cellList.get(c).statesPrHV.get(state), sumVector(landscape.lambda, subtractVector(landscape.alpha,landscape.beta)))).sum(); //I s(f) is the context independent component of the obj function			
				//dsf = DoubleStream.of(multiplyVector(divideScalar(sumVector(cellList.get(c).statesOG.get(state), getNeighborLateSeral(cellList.get(c).adjCellsList)), landscape.numTimePeriods*2), sumVector(landscape.lambda,landscape.gamma))).sum();
				isf = DoubleStream.of(multiplyVector(landscape.lambda,multiplyVector(cellList.get(c).statesPrHV.get(state), subtractVector(landscape.alpha,landscape.beta)))).sum(); //I s(f) is the context independent component of the obj function			
				dsf = DoubleStream.of(multiplyVector(landscape.oneMinusLambda, multiplyVector(divideScalar(sumVector(cellList.get(c).statesOG.get(state), getNeighborLateSeral(cellList.get(c).adjCellsList)), landscape.numTimePeriods*2), landscape.gamma))).sum();
					
				objValue += isf + dsf; //objective value
				
				planHarvestVolume = sumVector(planHarvestVolume, cellList.get(c).statesHarvest.get(state)) ;//harvest volume
				planLateSeral = sumVector(planLateSeral, cellList.get(c).statesOG.get(state));
			}
			System.out.println("iter:"+ i + " obj:" + objValue);
			if(maxObjValue < objValue && i > 14000) {
				maxObjValue = objValue;
				maxPlanHarvestVolume = planHarvestVolume.clone();
				maxPlanLateSeral = planLateSeral.clone();
				
				for(int h =0; h < cellList.size(); h++) {
					maxStates[h] = cellList.get(h).state;
				}
			}
			//Set the global-level penalties
			if(timeToSetPenalties) {
				double[] alpha = getAlphaPenalty(planHarvestVolume, harvestMin);
				double[] beta = getBetaPenalty(planHarvestVolume, harvestMax);
				double[] gamma = getGammaPenalty(planLateSeral, lateSeralTarget);
				landscape.setPenalties(alpha, beta, gamma);
				timeToSetPenalties = false;
			}
			
			if(finalPlan || i == numIter-1) {
				System.out.println("All cells at max state in iteration:" + i);
				System.out.println("maxObjValue:" + maxObjValue);
				for(int t= 0; t < planHarvestVolume.length; t++) {
					System.out.print("HV @ " + t + ": " + planHarvestVolume[t]+", ");
					System.out.println();
					System.out.print("HV @ " + t + ": " + maxPlanHarvestVolume[t]+", ");
					System.out.println();
					System.out.print("LS @ " + t + ": " + planLateSeral[t]+", ");
					System.out.println();
					System.out.print("LS @ " + t + ": " + maxPlanLateSeral[t]+", ");
					System.out.println();
				}
				System.out.println();
				//print the grid at each time
				/*for(int g= 0; g < landscape.numTimePeriods; g++) {
				   System.out.println("Time Period:" + (g + 1));
				   int rowCounter = 0;
			        for (int l= 0; l < cellList.size(); l++){
			            if (cellList.get(l).statesOG.get(cellList.get(l).state)[g] == 0.0) {
			            	System.out.print(".");
			            }else {
			            	System.out.print("*");
			            }
			            rowCounter ++;
			            if(rowCounter == landscape.colSizeLattice) {
			            	 System.out.println();
			            	 rowCounter = 0;
			            }
			         }
			        
			        System.out.println();
			        System.out.println();
			        System.out.println(maxObjValue);
				}*/
				break;
			}
		}
		
		//Report final plan indicators
	}
	
	/**
	* Retrieves the penalty for late-seral forest
	* @param planLateSeral2	the plan harvest volume
	* @param lateSeralTarget2	the minimum amount of late-seral needed
	* @return 		an array of gamma penalties
	*/
	 private double[] getGammaPenalty(double[] planLateSeral2, double lateSeralTarget2) {
			double[] gamma = new double[landscape.numTimePeriods];
			for(int a = 0; a < planLateSeral2.length; a++ ) {
				if(planLateSeral2[a] <= lateSeralTarget2) {
					if(planLateSeral2[a] == 0.0) {//check divisible by zero
						gamma[a] = lateSeralTarget2/0.00001; //use a small number in lieu of zero
					}else {
						gamma[a] = lateSeralTarget2/planLateSeral2[a];
					}
				}else {
					gamma[a] = 0.0;
				}
				
			}
			return gamma;
	}
	 
	/**
	* Retrieves the penalty for over harvesting
	* @param planHarvestVolume2	the plan harvest volume
	* @param harvestMax2	the maximum harvest volume
	* @return 		an array of beta penalties
	*/
	private double[] getBetaPenalty(double[] planHarvestVolume2, double harvestMax2) {
			double[] beta = new double[landscape.numTimePeriods];
			for(int a = 0; a < planHarvestVolume2.length; a++ ) {
				if(planHarvestVolume2[a] >= harvestMax2) {
					beta[a] = planHarvestVolume2[a]/harvestMax2;
				}else {
					beta[a] = 0.0;
				}				
			}
			return beta;
	}
	
	/**
     * Retrieves the penalty for under harvesting
     * @param planHarvestVolume2	the plan harvest volume
     * @param harvestMin2	the minimum harvest volume
     * @return 		an array of alpha penalties
     */
	private double[] getAlphaPenalty(double[] planHarvestVolume2, double harvestMin2) {
		double[] alpha = new double[landscape.numTimePeriods];
		for(int a = 0; a < planHarvestVolume2.length; a++ ) {
			if(planHarvestVolume2[a] <= harvestMin2) {
				if(planHarvestVolume2[a] == 0.0) {//check divisible by zero
					alpha[a] = harvestMin2/0.001; //use a small number in lieu of zero
				}else {
					alpha[a] = harvestMin2/planHarvestVolume2[a];
				}
			}else {
				alpha[a] = 0.0;
			}			
		}
		return alpha;
	}

	/**
     * Retrieves the schedule or state with the maximum value for this cell object
     * @param id	the index of the cell or stand
     * @return 		an integer representing the maximum state of a cell
     */
	public int getMaxState(int id) {
		double maxValue = 0.0;
		double stateValue, isf,dsf;
		int stateMax =0;
		double[] lsn = new double[landscape.numTimePeriods];
		lsn = getNeighborLateSeral(cellList.get(id).adjCellsList);
		
		for(int i = 0; i < cellList.get(id).statesPrHV.size(); i++) { // Iterate through each of the plausible treatment schedules also known as states
		
			//isf = DoubleStream.of(multiplyVector(cellList.get(id).statesPrHV.get(i), sumVector(landscape.lambda, subtractVector(landscape.alpha,landscape.beta)))).sum(); //I s(f) is the context independent component of the obj function			
			//dsf = DoubleStream.of(multiplyVector(divideScalar(sumVector(cellList.get(id).statesOG.get(i), lsn), landscape.numTimePeriods*2), sumVector(landscape.oneMinusLambda,landscape.gamma))).sum();
			isf = DoubleStream.of(multiplyVector(landscape.lambda,multiplyVector(cellList.get(id).statesPrHV.get(i), subtractVector(landscape.alpha,landscape.beta)))).sum(); //I s(f) is the context independent component of the obj function			
			dsf = DoubleStream.of(multiplyVector(landscape.oneMinusLambda, multiplyVector(divideScalar(sumVector(cellList.get(id).statesOG.get(i), lsn), landscape.numTimePeriods*2), landscape.gamma))).sum();
			
			stateValue = isf + dsf;
			if(maxValue < stateValue) {
				maxValue = stateValue;
				stateMax = i;
			}
		};
		
		return stateMax;
	}
		
	 /**
     * Retrieves a factor between 0 and 1 that is equal to the proportion of stand f's neighbors 
     * that are also late-seral in planning period t
     * @param adjCellsList	an ArrayList of integers representing the cells index + 1
     * @return 		a vector of length equal to the number of time periods
     */
	public double[] getNeighborLateSeral(ArrayList<Integer> adjCellsList) {
		double[] lsn = new double[landscape.numTimePeriods];
		double lsnTimePeriod = 0.0;
		int counter = 0;
		
		for(int t =0; t < landscape.numTimePeriods; t++) {
			for(int n =0; n < adjCellsList.size(); n++) {
				int state = cellList.get(adjCellsList.get(n)-1).state; // the cellList is no longer in order can't use get. Need a comparator.
				lsnTimePeriod += cellList.get(adjCellsList.get(n)-1).statesOG.get(state)[t];
				counter ++;
			}
			lsn[t] = lsnTimePeriod/counter;
			counter = 0;
			lsnTimePeriod = 0.0;
		}
		
		return lsn;
	}

	 /**
     * Multiplies two vectors together to return the element wise product.
     * @param vector1	an Array of doubles with length equal to the number of time periods
     * @param vector2	an Array of doubles with length equal to the number of time periods
     * @return 		a vector of length equal to the number of time periods
     * @see divideVector
     */
	private double[] multiplyVector (double[] vector1, double[] vector2) {
		double[] outVector = new double[vector1.length];
		for(int i =0; i < outVector.length; i++) {
			outVector[i] = vector1[i]*vector2[i];
		}
		return outVector;
	}
	
	 /**
     * Divides a vectors by a scalar element wise.
     * @param vector1	an Array of doubles with length equal to the number of time periods
     * @param scalar	a scalar
     * @return 		a vector of length equal to the number of time periods
     * @see multiplyVector
     */
	private double[] divideScalar (double[] vector1, double scalar) {
		double[] outVector = new double[vector1.length];
		for(int i =0; i < outVector.length; i++) {
			outVector[i] = vector1[i]/scalar;
		}
		return outVector;
	}
	
	
	
	 /**
     * Subtracts two vectors so that the element wise difference is returned. The first vector is subtracted by the second
     * @param vector1	an Array of doubles with length equal to the number of time periods
     * @param vector2	an Array of doubles with length equal to the number of time periods
     * @return 		a vector of length equal to the number of time periods
     * @see sumVector
     */
	private double[] subtractVector (double[] vector1, double[] vector2) {
		double[] outVector = new double[vector1.length];
		for(int i =0; i < outVector.length; i++) {
			outVector[i] = vector1[i]-vector2[i];
		}
		return outVector;
	}
	
	 /**
     * Adds two vectors so that the element wise sum is returned.
     * @param vector1	an Array of doubles with length equal to the number of time periods
     * @param scalar	a scalar
     * @return 		a vector of length equal to the number of time periods
     * @see subtractVector
     */
	private double[] sumVector(double[] vector1, double[] vector2) {
		double[] outVector = new double[vector1.length];
		for(int i =0; i < outVector.length; i++) {
			outVector[i] = vector1[i]+vector2[i];
		}
		return outVector;
	}
	
	 /**
     * Instantiates java objects developed in R
     */
	public void setRParms() {
		// TODO Auto-generated method stub
	}
	
	 /**
     * Creates a forest data set used for testing the cellular automata
     */
	public void createData() {
		//harvest flow
		lateSeralTarget = Math.round(0.2*landscape.numCells); // 15% of the landscape should be old growth
		harvestMax = 66000.0;
		harvestMin = 65000.0;
		
		Random r =	new Random(15); //Random seed for making new grids
		//dummy yields taken from yieldid -203322
		Double vols[] = {0.0,0.0,0.0,0.0,10.22,45.4,95.32,148.35,198.33,243.29,283.14,318.13,349.0,377.2,402.6,422.64,435.88,443.75,447.82,449.16,448.54,444.25,439.52,434.92,430.47,426.17,422.0,417.96,414.02,410.19,406.46,402.82,400.28,398.41,396.56,394.73};
		Double hts[] = {0.0, 0.6,2.6,6.41,10.62,14.6,18.15,21.22,23.85,26.1,28.01,29.66,31.07,32.29,33.36,34.29,35.1,35.83,36.47,37.04,37.55,38.01,38.43,38.81,39.15,39.46,39.75,40.01,40.25,40.48,40.68,40.87,41.05,41.22,41.37,41.51};
		Double ogs[] = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0};
		//YieldID = 0
		yields.add(0, new ArrayList <LinkedHashMap<String, Double >>());
		
		Double vols2[] = {0.0,0.0,10.22,45.4,95.32,148.35,198.33,243.29,283.14,318.13,349.0,377.2,402.6,422.64,435.88,443.75,447.82,449.16,448.54,444.25,439.52,434.92,430.47,426.17,422.0,417.96,414.02,410.19,406.46,402.82,400.28,398.41,396.56,394.73,394.73,394.73};
		Double hts2[] = {0.0, 0.6,2.6,6.41,10.62,14.6,18.15,21.22,23.85,26.1,28.01,29.66,31.07,32.29,33.36,34.29,35.1,35.83,36.47,37.04,37.55,38.01,38.43,38.81,39.15,39.46,39.75,40.01,40.25,40.48,40.68,40.87,41.05,41.22,41.37,41.51};
		Double ogs2[] = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0};
		//YieldID = 1
		yields.add(1, new ArrayList <LinkedHashMap<String, Double >>());
		
		//Add in yields using a loop
		for(int y=0; y<36; y++) { // for each decade in the yield curve to a max of 350 years including year 0
			yields.get(0).add(y, new LinkedHashMap<String, Double >() );
			yields.get(0).get(y).put("vol", vols[y]);
			yields.get(0).get(y).put("ht", hts[y]);
			yields.get(0).get(y).put("og", ogs[y]);
			yields.get(1).add(y, new LinkedHashMap<String, Double >() );
			yields.get(1).get(y).put("vol", vols2[y]);
			yields.get(1).get(y).put("ht", hts2[y]);
			yields.get(1).get(y).put("og", ogs2[y]);
		}

		for(int k= 0; k < landscape.numCells; k++) {
			//Attribution of the stand or cell
			int age = Math.round(r.nextInt(250)/10)*10;
			this.cellList.add(new Cell(landscape, k + 1, age, yields.get(0), yields.get(1)));
		}
		
		
		System.out.println("create data done");
	}

}
