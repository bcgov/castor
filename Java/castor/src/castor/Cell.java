package castor;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Random;
import java.util.stream.DoubleStream;

public class Cell {
	//Local variables for each cell
	int id, state, age; 
	ArrayList<Integer> adjCellsList ;
	ArrayList<double[]> statesHarvest = new ArrayList<double[]>();
	ArrayList<double[]> statesPrHV = new ArrayList<double[]>();
	ArrayList<int[]> statesOG = new ArrayList<int[]>();
	int yield;
	int yield_trans;
	ArrayList<Integer> landCoverList = new ArrayList<Integer>();
	
	Random r = new Random();
	
	/** 
	* Class constructor.
	* @param landscape	A grid object containing the necessary attribution about the landscape
	 * @param yields 
	* @param id			the cells index plus 1
	* @param age		The initial age of the cell or stand
	* @param yld		All forest yields for a cell. An ArrayList of LinkedHashMap where the key is a set of forest attributes including volume, height and old growth.
	* @param yld_trans 	All forest yields for a cell after harvesting. An ArrayList of LinkedHashMap where the key is a set of forest attributes including volume, height and old growth.
	* @param lc 
	*/
	public Cell (Grid landscape, ArrayList<ArrayList<LinkedHashMap<String, Double>>> yields, int id, int age, int yld, int yld_trans, ArrayList<Integer> lc){
		this.id = id;
		this.age = age;
		this.yield = yld;
		this.yield_trans = yld_trans;
		this.landCoverList = lc;
		setStates(landscape, age, yields.get(yld), yields.get(yld_trans));
		this.adjCellsList = getAdjCells(id-1, landscape.colSizeLattice, landscape.cellList);
		this.state = r.nextInt(statesHarvest.size()); //assign a random state to the initial grid
		//this.state =0;
	}
	
	
	//TODO the setStates method could be called once for each key of a hash map instead of for each cell/stand
		//Create a method to call this once for each age, yieldid, yieldid2 combinations and store as an HashMap of double[] arrays. 
		//Then each key will consist of the age, yieldid, yieldid2. This would only be beneficial when setting up a lattice of cells. 
		//Running the algorithm as a set of irregular shaped stands would result in a unique yieldid and yieldid2 given the aggregation to a stand/block level.
	/** 
	* Generates the plausible set of treatment schedules or states
	* @param landscape	A grid object containing the necessary attribution about the landscape
	 * @param yields 
	* @param age		The initial age of the cell or stand
	* @param yld		All forest yields for a cell. An ArrayList of LinkedHashMap where the key is a set of forest attributes including volume, height and old growth.
	* @param yld_trans 	All forest yields for a cell after harvesting. An ArrayList of LinkedHashMap where the key is a set of forest attributes including volume, height and old growth.
	*/
	public void setStates(Grid landscape, int age, ArrayList<LinkedHashMap<String, Double>> yld, ArrayList<LinkedHashMap<String, Double>> yld_trans ) { // get an arrayList of double arrays that are the length of the planning horizon (ph) 
			
			ArrayList<Integer> ageWindow = new ArrayList<Integer>();
			ArrayList<Double> volWindow = new ArrayList<Double>();
			ArrayList<Integer> ageWindow2 = new ArrayList<Integer>();
			ArrayList<Double> volWindow2 = new ArrayList<Double>();
			
			double[] decision = new double[landscape.numTimePeriods]; // ph = planning horizon, pl = period length as in 5 or 10 year lengths
			int[] ogStatus = new int[landscape.numTimePeriods]; // ph = planning horizon, pl = period length as in 5 or 10 year lengths
			boolean harvestWindow = false;		
			boolean moreStates = true;
			boolean lessThanMinHarvAge = true;
			
			int node1 =0;
			int stateIter = 0;
			int numPeriodsToFitSecondHarv;
			
			double maxHarvVol = 0.0;
			
			//Create an empty array of zeros across the ph
			for (int i =0 ; i < landscape.numTimePeriods; i++) { // An array of zeros for each period in the planning horizon (ph)
				decision[i] = 0.0;
				if(age + i*10 >= landscape.ageThreshold) { 	//Get the old growth status for a no harvest scenario. Need og here to determine the year the cell becomes old growth
					ogStatus[i] = 1;
				}else {
					ogStatus[i] = 0;
				}
				
			}
			
			//Scope the yield curve for use 1
			for (int i =0 ; i < 36; i++) { 
				if(yld.get(i).get("vol") >= landscape.minHarvVol) {
					harvestWindow = true;
					if(age >= i*10) { // When the age is greater than the min harvest age
						lessThanMinHarvAge = false;
						for( int k =0; k < (35-age/10); k++) {
							ageWindow.add(age + k*10); 
							volWindow.add(yld.get((age + k*10)/10).get("vol"));
						}
						break;
					}else {
						ageWindow.add(i*10); // assumption: the volume curves come in 10 year increments
						volWindow.add(yld.get(i).get("vol"));
					}
				}			
			}
			
			//Scope the yield curve for use 2
			for (int i =0 ; i < 36; i++) { 
				if(yld_trans.get(i).get("vol") >= landscape.minHarvVol) {
					ageWindow2.add(i*10); // assumption: the volume curves come in 10 year increments
					volWindow2.add(yld_trans.get(i).get("vol"));
				}
			}
			
		
	//------------------------------------
	//Generate the possible states
			while(moreStates) {
				if(stateIter == 0) { //the first state (Index = 0) is always leave for natural or no harvesting across the ph
					statesHarvest.add(stateIter, decision);
					statesOG.add(stateIter, ogStatus);
					stateIter = stateIter + 1;
				}else {
					if(harvestWindow){ // Check: is there a harvesting window?
						if(lessThanMinHarvAge) { // The age of the cell is less than the harvest window
							//Harvest once
							for(int i = 0; i < ageWindow.size(); i ++) { // each age in the harvest window
								if((ageWindow.get(i)-age)/landscape.pl <= (landscape.numTimePeriods)) { // Does the harvesting window occurs in the planning horizon (ph)
									double[] decision1 = new double[landscape.numTimePeriods];
									Arrays.fill(decision1, 0.0); // reset the temp to an array of zeros
									decision1[((ageWindow.get(i)-age)/landscape.pl)-1] = volWindow.get(i);
									//Set the states----
									statesHarvest.add(stateIter, decision1);
									statesOG.add(stateIter, getOGStatus(age, decision1, landscape.ageThreshold)); //Use a method to determine the vector. Use similar approach for other values
									//------------------
									if(maxHarvVol < DoubleStream.of(decision1).sum()) { //Calc the maxHarvVol
										maxHarvVol = DoubleStream.of(decision1).sum();
									}
									stateIter = stateIter + 1; // the number of single harvest events minus 1
									node1 = node1 + 1 ;
								}else {
									harvestWindow = false;
									break; // no room for a single harvest
								}
							}
							
							//Harvest Twice
							if(node1 > 0) {
								for(int i = 0; i < node1; i++) { //this loop is for node 1
									numPeriodsToFitSecondHarv = (landscape.numTimePeriods) - (ageWindow2.get(0) + (ageWindow.get(i)-age))/landscape.pl ;
									
									if(numPeriodsToFitSecondHarv > 0) {//Does a second harvest fit in the ph?	
										
										for(int i2 =0; i2 < numPeriodsToFitSecondHarv; i2++) { //this loop is for node 2
											double[] decision2 = statesHarvest.get(i+1).clone();//get the first state with harvesting
											decision2[(ageWindow2.get(i2) + (ageWindow.get(i)-age))/landscape.pl] = volWindow2.get(i2);
											statesHarvest.add(stateIter, decision2);
											statesOG.add(stateIter, getOGStatus(age, decision2, landscape.ageThreshold));
											if(maxHarvVol < DoubleStream.of(decision2).sum()) { //Calc the maxHarvVol
												maxHarvVol = DoubleStream.of(decision2).sum();
											}
											stateIter = stateIter + 1;
										}
										
									} else {
										moreStates = false;
										break;
									}
								}
							}
							moreStates = false;	
							
						}else {   //the age of the cell is greater than the harvest window
							//Harvest at any point during the planning horizon and within the ageWindow.
							for(int i = 0; i < landscape.numTimePeriods; i ++) { 
								double[] decision1 = new double[landscape.numTimePeriods];
								Arrays.fill(decision1, 0.0); // reset the temp to an array of zeros
								if(volWindow.size() <= i) { //age is at the max of the yield curve- just set to the oldest vol
									decision1[i] = volWindow.get(volWindow.size()-1);
									statesHarvest.add(stateIter, decision1);
								}else {
									decision1[i] = volWindow.get(i);
									statesHarvest.add(stateIter, decision1);
								}
								statesOG.add(stateIter, getOGStatus(age, decision1, landscape.ageThreshold));
								if(maxHarvVol < DoubleStream.of(decision1).sum()) { //Calc the maxHarvVol
									maxHarvVol = DoubleStream.of(decision1).sum();
								}
								stateIter = stateIter + 1; // the number of single harvest events minus 1
								node1 = node1 + 1 ;
							}
							
							//Harvest twice
							if(node1 > 0) {
								for(int i = 0; i < node1; i++) { //this loop is for node 1
									if(i >= ageWindow.size()) {
										break;
									}else {
										numPeriodsToFitSecondHarv = (landscape.numTimePeriods) - (ageWindow2.get(0) + (ageWindow.get(i)-age))/landscape.pl ;
									}
									if(numPeriodsToFitSecondHarv > 0) {//Does a second harvest fit in the ph?	
										
										for(int i2 =0; i2 < numPeriodsToFitSecondHarv; i2++) { //this loop is for node 2
											double[] decision2 = statesHarvest.get(i+1).clone();//get the first state with harvesting
											decision2[(ageWindow2.get(i2) + (ageWindow.get(i)-age))/landscape.pl] = volWindow2.get(i2);
											statesHarvest.add(stateIter, decision2);
											statesOG.add(stateIter, getOGStatus(age, decision2, landscape.ageThreshold));
											if(maxHarvVol < DoubleStream.of(decision2).sum()) { //Calc the maxHarvVol
												maxHarvVol = DoubleStream.of(decision2).sum();
											}
											stateIter = stateIter + 1;
										}
										
									} else {
										moreStates = false;
										break;
									}
								}
							}
						}
						harvestWindow = false;
					}else{ // No harvesting window -- end and the only state is 0 or no harvesting
						moreStates = false;
					}				
				}	
			}
			
			//System.out.println(age);
			//System.out.println(maxHarvVol);
			for(int i = 0; i < statesHarvest.size(); i ++){ //Assign the proportion of max total volume harvested
				double[] prHV  = statesHarvest.get(i).clone();
				for(int k =0; k < statesHarvest.get(0).length; k++) {
					prHV[k]= prHV[k]/maxHarvVol; 
				}
				statesPrHV.add(i, prHV);
			}
	}
	
	
	/** 
	* Retrieves spatially adjacent cells aka neighbors
	* @param id 	the index of the cell whose neighbors are to be found
	* @param cols	the number of columns in the lattice
	* @param cells	an array of cell index values
	* @return an ArrayList of Integers whose elements represent the cell index of adjacent cells
	*/
	public ArrayList<Integer> getAdjCells(int id, int cols, int[] cells ) {
		
	    ArrayList<Integer> cs = new ArrayList<Integer>(8);
	    //check if cell is on an edge
	    boolean l = id %  cols > 0;        //has left
	    boolean u = id >= cols;            //has upper
	    boolean r = id %  cols < cols - 1; //has right
	    boolean d = id <   cells.length - cols;   //has lower
	    //collect all existing adjacent cells
	    if (l)      cs.add(cells[id - 1]);
	    if (l && u) cs.add(cells[id - 1 - cols]);
	    if (u)      cs.add(cells[id     - cols]);
	    if (u && r) cs.add(cells[id + 1 - cols]);
	    if (r)      cs.add(cells[id + 1       ]);
	    if (r && d) cs.add(cells[id + 1 + cols]);
	    if (d)      cs.add(cells[id     + cols]);
	    if (d && l) cs.add(cells[id - 1 + cols]);
	    return cs;
	}
	
	/** 
	* Retrieves the late-seral or old growth status of a cell for each time period
	* @param age			the age of the cell in the initial time period
	* @param decision 		the vector of length equal to the number of time periods whose elements are the amount of volume harvested
	* @param ageThreshold	the threshold where a cell is considered late-seral or old growth
	* @return a vector of ones or zeros representing if the time period is late-seral. The length equal to the number of time periods
	*/
	private int[] getOGStatus(int age, double[] decision, int ageThreshold) {
		int harvYear = -1;
		int[] ogStatus = new int[decision.length];
		
		for(int d = 0; d< decision.length; d++) {
			if(decision[d] > 0.0) {
				ogStatus[d] = 10;
			}else {
				ogStatus[d] = 0;
			}
			
			
		}
		
		for(int o = 0; o < ogStatus.length; o++) {
			if(ogStatus[o] > 0) {
				harvYear = o;
			}
			if(harvYear == -1) {
				if(age >= ageThreshold){
					ogStatus[o] = 1;
				}else{
					if(age + o*10 >= ageThreshold) {
						ogStatus[o] = 1;
					}else {
						ogStatus[o] = 0;
					}
				}
			}else{
				if(o*10 - harvYear*10 >= ageThreshold){
					ogStatus[o] = 1;
				}else{ 
					ogStatus[o] = 0;
				}
			}				
		}
	return ogStatus;
	}
}
