package coe_cellular_automata;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Random;
import java.util.stream.DoubleStream;
import java.sql.*;
import org.sqlite.*;

public class CellularAutomata {
	//ArrayList<Cell> cellList = new ArrayList<Cell>();
	ArrayList<Cells> cellsList = new ArrayList<Cells>();
	ArrayList<Integer> cellsListChangeState = new ArrayList<Integer>();
	
	//ArrayList<Cell> cellListMaximum = new ArrayList<Cell>();
	int numIter=15000;
	float harvestMax,harvestMin, gsMin, objValue, maxObjValue;
	double globalWeight =0.01; // needs be of high precision
	boolean finalPlan = false;
	boolean globalConstraintsAchieved = false;
	int lateSeralTarget;
	
	Grid landscape = new Grid();//Instantiate the GRID
	//LandCoverConstraint beo = new LandCoverConstraint();
	float[] planHarvestVolume = new float[landscape.numTimePeriods];
	float[] planGSVolume = new float[landscape.numTimePeriods];
	int[] planLateSeral = new int[landscape.numTimePeriods];
	float[] maxPlanHarvestVolume = new float[landscape.numTimePeriods];
	int[] maxPlanLateSeral = new int[landscape.numTimePeriods];
	ArrayList<ArrayList<LinkedHashMap<String, Double>>> yields = new ArrayList<ArrayList<LinkedHashMap<String, Double>>>();
	ArrayList<HashMap<String, float[]>> yieldTable = new ArrayList<HashMap<String, float[]>>();
	public ArrayList<ForestType> forestTypeList = new ArrayList<ForestType>() ;
	public ArrayList<LandCoverConstraint> landCoverConstraintList = new ArrayList<LandCoverConstraint>() ;
	//Variables for simulate2
	float maxCutLocal = 0L;
	float[] maxCutGlobal = new float[landscape.numTimePeriods];
	double plc;
	
	enum type{
		SUBTRACT,
		SUM
	}
	
	/** 
	* Class constructor.
	*/
	public CellularAutomata() {
	}
	
	/** 
	* Simulates the co-evolutionary cellular automata. This is the main algorithm for searching the decision space following Heinonen and Pukkala 
	* <p>
	* 1. Local level decisions (stand-level) are optimized by:
	* 	<li> a. create a vector of randomly sampled without replacement cell indexes 
	* 	<li> b. pull a random variable and determine if the cell is to be mutated. If mutated pick random state
	* 	<li> c. pull a random variable and determine if the cell is to be innovated. If innovated pick best state
	* 	<li> d. go to next cell
	* 	<li> e. stop when number of iterations reached.
	* <p>
	* 2. Global level decisions (forest-level) are optimized by:
	* 	<li> a. use the local level optimization as the starting point. Global weight (b) =0.01;
	* 	<li> b. estimate local + global objective function
	* 	<li> c. for each cell evaluate the best state
	* 	<li> d. increment the global weight b += 0.1 and go to the next iteration
	* 	<li> e. stop when global penalties are met
	* 
	* <h4>References</h4>
	* <p> Heinonen, T., and T. Pukkala. 2007. The use of cellular automaton approach in forest planning. Canadian Journal of Forest Research. 37(11): 2188-2200. https://doi.org/10.1139/X07-073
	*/
	public void simulate2() {
		boolean mutate = false;
		boolean innovate = true;
		int counterLocalMaxState = 0;
		int currentMaxState;
		Random r = new Random(15); // needed for mutation or innovation probabilities? 
		harvestMin = 2100000*landscape.pl;
		//harvestMin = 20000000;
		gsMin = 69000000;
		setLCCHarvestDelay(); //In cases no-harvesting decision does not meet the constraint -- remove harvesting during these periods and as a penalty -- thus ahciving the paritial amount
		
		System.out.println("");
		landscape.setLandscapeWeight((double) 1/cellsListChangeState.size());
		
		setMaxCutValue();//scope all of the cells to determine the maxHarvVol	
		randomizeStates(r);
		
		//---------------------------------------------
		System.out.println("Starting local optimization..");
		//---------------------------------------------
		for(int i = 0; i < 100; i ++) {
			//Local level optimization
			System.out.println("Local iter:" + i);
			Collections.shuffle(cellsListChangeState); // randomize which cell gets selected.
			
			for(int j = 0; j < cellsListChangeState.size(); j++) {
				if(mutate) {
					cellsList.get(cellsListChangeState.get(j)).state = r.nextInt(forestTypeList.get(cellsList.get(cellsListChangeState.get(j)).foresttype).stateTypes.size()); //get a random state
				}
				if(innovate) {
					currentMaxState = getMaxStateLocal(cellsListChangeState.get(j));
					if(cellsList.get(cellsListChangeState.get(j)).state == currentMaxState) {
						counterLocalMaxState ++;
						continue;
					}else {
						cellsList.get(cellsListChangeState.get(j)).state = currentMaxState; //set the maximum state with no global constraints
					}
				}
			}	
			
			if(counterLocalMaxState == cellsListChangeState.size()) {
				System.out.println("Local optimization solved");
				System.out.print("");
				break;
			}else {
				counterLocalMaxState = 0;
			}	
		}
		
		//---------------------------------------------
		System.out.print("Setting global targets...");
		//---------------------------------------------
		for(int c =0; c < cellsListChangeState.size(); c++) {// Iterate through each of the cell and their corresponding state
			planHarvestVolume = sumVector(planHarvestVolume,  forestTypeList.get(cellsList.get(cellsListChangeState.get(c)).foresttype).stateTypes.get(cellsList.get(cellsListChangeState.get(c)).state).get("harvVol"), cellsList.get(cellsListChangeState.get(c)).thlb) ;//harvest volume
			planGSVolume = sumVector(planGSVolume,  forestTypeList.get(cellsList.get(cellsListChangeState.get(c)).foresttype).stateTypes.get(cellsList.get(cellsListChangeState.get(c)).state).get("gsVol"), cellsList.get(cellsListChangeState.get(c)).thlb) ;
		}
		setLandCoverConstraints(); //go through each land cover constraint and assign achievedConstraint following the local level optimization
		System.out.println("done");
		
		
		//---------------------------------------------	
		System.out.println("Starting global optimization..");
		//---------------------------------------------
		int cell;
		for(int g =0; g < 10000; g++) {	// allow for 10000 iterations
			if(globalConstraintsAchieved) {
				break;
			}
			
			Collections.shuffle(cellsListChangeState); // randomize which cell gets selected.
			
			for(int j = 0; j < cellsListChangeState.size(); j++) { //transition the states based on global objectives
				if(globalConstraintsAchieved) {
					break;
				}
				cell = cellsListChangeState.get(j);				
				cellsList.get(cell).state = getMaxStateGlobal(cell); //set the maximum state with global constraints			
			}
			
			System.out.print("iter:" + g + " global weight:" + globalWeight + " Plc:" + plc );
			globalWeight += 1; //increment the global weight
			
			for(int k =0; k < planHarvestVolume.length; k++){
				System.out.print(" Vol:" + planHarvestVolume[k] + "  ");
			}
			System.out.println("");
		}
		 
		System.out.println("Solved");
		for(int f =0; f < planHarvestVolume.length; f++){
			System.out.print(" GS:" + planGSVolume[f] + "  ");
		}
		
		try {
			System.out.print("Saving states");
			saveResults();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	/**
	 * Estimates the number of periods needed for the land cover constraint to be met. 
	 * This is the number of years needed for recruitment
	 */
	private void setLCCHarvestDelay() {
		float[] value = null;
		boolean addToChangeStateList;
		int counter = 0;
		//loop through each cell assuming no harvest to find out the period in the planning horizon the land cover constraint becomes non-binding
		for(Cells c : cellsList) {		
			addToChangeStateList = true;
			
			for(Integer constraint : c.landCoverList) {
				value =  forestTypeList.get(c.foresttype).stateTypes.get(0).get(landCoverConstraintList.get(constraint).variable);
				setAddLCConstraint(constraint, value);
				if(addToChangeStateList) {
					addToChangeStateList = getNoHarvestCells(constraint);
				}
				
			}
			
			if(c.manage_type > 0 && addToChangeStateList) { //add only those cells who are allowed to change their state (or allow harvesting)
				cellsListChangeState.add(counter);
			}
			
			counter ++;
		}
		
		for(LandCoverConstraint lc : landCoverConstraintList) {
			if(lc.achievedConstraint == null) {
				continue;
			}
			switch(lc.type) {
				case "ge":
					for(int p = 0; p < lc.achievedConstraint.length; p++) {
						if(lc.achievedConstraint[p] > lc.target_cover ) {
							lc.delayHarvest = p;
							break;
						}
						if(p == lc.achievedConstraint.length-1) { //the constraint will never be met within the planning horizon
							lc.delayHarvest = p;
							break;
						}
					}
					break;
				case "le":
					for(int p = 0; p < lc.achievedConstraint.length; p++) {
						if(lc.achievedConstraint[p] < lc.target_cover ) {
							lc.delayHarvest = p;
							break;
						}
						if(p == lc.achievedConstraint.length-1) { //the constraint will never be met within the planning horizon
							lc.delayHarvest = p;
							break;
						}
					}
					break;
				case "nh": // No harvest -- don't allow any harvesting so delay will be the entire planning horizon
					lc.delayHarvest = lc.achievedConstraint.length;				
					break;
			}
				
		}
	}
	
	/**
	 * Determines if a cell is within a no harvesting zone
	 * @param constraint the index of the land cover constraint
	 * @return if the cell is a "no Harvest" cell denoted a "nh" in the type - then return a false else returna  true
	 */
	private boolean getNoHarvestCells(Integer constraint) {
		if(landCoverConstraintList.get(constraint).type == "nh") {
			return false;
		}else {
			return true;
		}	
	}

	/**
	* Finds the quantity across all cells and schedules of the maximum amount of volume harvested 
	* across all planning horizons (maxCutLocal).
	*/
	private void setMaxCutValue() {
		float tempCut = 0 ;	
		for(int c =0; c < cellsListChangeState.size(); c++) {
			for(int s= 0; s < forestTypeList.get(cellsList.get(cellsListChangeState.get(c)).foresttype).stateTypes.size(); s++ ) {				
				
				tempCut = tempCut + sumFloatVector(forestTypeList.get(cellsList.get(cellsListChangeState.get(c)).foresttype).stateTypes.get(s).get("harvVol")) ;	
				if(maxCutLocal < tempCut) {
					maxCutLocal =   tempCut;
				}		
				tempCut = 0L;
			}		
		}
		//Note that the max og local is 1 for all periods. 
	}
	
	/**
	 * Randomizes the cells state assignment
	 * @param r the random variable
	 */
	private void randomizeStates(Random r) {
		int cell;
		for(int c = 0 ; c < cellsListChangeState.size(); c++) {
			cell = cellsListChangeState.get(c);
			cellsList.get(cell).state = r.nextInt(forestTypeList.get(cellsList.get(cell).foresttype).stateTypes.size());			
		}
	}

	/**
	* Retrieves the state with greatest rank considering only the local scale. 
	* The rank of alternative schedules is based on Heinonen and Pukkala (2007):
	* <p>
	* <li> Ujk = SUM(wi*ui(qi)) 
	* <p> 
	* where wi is the weight for objective i, 
	* ui is the priority function for objective i and qi is the quantity of the objective i 
	* 
	* <h4>References</h4>
	* <p> Heinonen, T., and T. Pukkala. 2007. The use of cellular automaton approach in forest planning. Canadian Journal of Forest Research. 37(11): 2188-2200. https://doi.org/10.1139/X07-073
	* 
	* @param i the cell index
	* @return the index of the cell state which maximizes the objectives
	*/
	private int getMaxStateLocal(int i) {
		double maxValue = 0.0, stateValue = 0.0;
		double isf =0.0;
		int stateMax = 0;
		float[] harvVol, age;
		float[][] propN = getNeighborProportion(cellsList.get(i).adjCellsList);
		float maxPropNH = sumPropN(propN[0]);
		float maxPropNAge = sumPropN(propN[1]);
		float thlb = cellsList.get(i).thlb;
		
		for(int s = 0; s < forestTypeList.get(cellsList.get(i).foresttype).stateTypes.size(); s++) {
				
			harvVol = forestTypeList.get(cellsList.get(i).foresttype).stateTypes.get(s).get("harvVol");
			isf = sumArray(harvVol, thlb)/maxCutLocal;
	
			age = forestTypeList.get(cellsList.get(i).foresttype).stateTypes.get(s).get("age");
		    stateValue = 0.05*isf + 0.90*getPropNHRank(harvVol, propN[0], maxPropNH)+ 0.05*getPropNAgeRank(age, propN[1], maxPropNAge);
				
			if(maxValue < stateValue) {
				maxValue = stateValue;
				stateMax = s;
			}	
		}
		return stateMax;
	}

	/**
	 * Sets the {@code achievedConstraint} and {@code perPHAchieved} for each land cover constraint
	 */
	private void setLandCoverConstraints() {
		float[] value = null;	
		for(LandCoverConstraint lc : landCoverConstraintList ) { // reset each constraint
			if(lc.achievedConstraint == null) {
				continue;
			}
			Arrays.fill(lc.achievedConstraint, 0f);
		}
		
		for(Cells c : cellsList) { // assign the current constraint
			for(Integer constraint : c.landCoverList) {
				value =  forestTypeList.get(c.foresttype).stateTypes.get(c.state).get(landCoverConstraintList.get(constraint).variable);
				setAddLCConstraint(constraint, value);		
			}
		}
		
		for(int landC = 1; landC < landCoverConstraintList.size(); landC++ ) { //start at one because the first landCoverConstraint with index 0 is null
			setLandCoverPHAchieved(landC);
		}
	}
	
	/**
	* Retrieves the state of a cell with the maximum rank when linking local and global objectives. 
	* The rank of alternative schedules is based on Heinonen and Pukkala (2007):
	* <p>
	* Local level rank of alternative states
	* <li> Ujk = SUM(wi*ui(qi)) 
	* <p>
	* where wi is the weight for objective i, 
	* ui is the priority function for objective i and qi is the quantity of the objective i 
	* </br><p>
	* Global level rank of alternative states
	* <li>P =SUM(vl*pl(gl)) 
	* <p>
	* where vl is the weight for global objective l, 
	* pl is the priority function for objective l and gl is the quantity of the objective l 
	* <p>
	* Combination rank or linkage between the two scales
	* <li> Rjk = a/A*Ujk + b*P 
	* <p>
	* where Rjk is the rank of alternative states, a is the
	* area of the cell, A is the total area of all cells, b is the globalWeight to be incremented.
	* 
	* <h4>References</h4>
	* <p> Heinonen, T., and T. Pukkala. 2007. The use of cellular automaton approach in forest planning. Canadian Journal of Forest Research. 37(11): 2188-2200. https://doi.org/10.1139/X07-073
	*
	* @param id the cell index
	* @return the index of the cell state which has the highest rank
	*/
	private int getMaxStateGlobal(int i) {
		double maxValue = 0.0, P = 0.0, U =0.0 , hfc = 0.0, gsc= 0.0;
		double isf =0.0, lc =1.0;
		double stateValue;
		
		int stateMax = 0;
		float[] harvVol, age;
		float[][] propN = getNeighborProportion(cellsList.get(i).adjCellsList);
		float maxPropNH = sumPropN(propN[0]);
		float maxPropNAge = sumPropN(propN[1]);
		float thlb = cellsList.get(i).thlb;
		boolean recruitment = false;
		
		//Get some of the cells info - fetched more than three times
		int harvestDelay = getMaxHarvestDelay(cellsList.get(i).landCoverList);
		ForestType ft = forestTypeList.get(cellsList.get(i).foresttype);
		ArrayList<Integer> lcList = cellsList.get(i).landCoverList;
		plc = getLCRemaining(lcList);
		
		//Adjust the global objectives
		setObjectives(type.SUBTRACT, ft.stateTypes.get(cellsList.get(i).state), lcList);
		
		//Iterate through all of the states
		for(int s = 0; s < ft.stateTypes.size(); s++) {
			harvVol = ft.stateTypes.get(s).get("harvVol");
			for(int r = 0; r < harvVol.length;r ++) {
				if(harvVol[r] > 0 && r < harvestDelay) {
					recruitment = true;
					break;
				}
				if(r >= harvestDelay) {
					break;
				}
			}
			
			if(recruitment) {
				recruitment = false;
				continue; // go to the next state - can't harvest this one -- its locked down!
			}
			
			isf = sumArray(harvVol, thlb)/maxCutLocal;
			age = ft.stateTypes.get(s).get("age");
		    U = 0.05*isf + 0.90*getPropNHRank(harvVol, propN[0],maxPropNH)+ 0.05*getPropNAgeRank(age, propN[1],maxPropNAge);
				
			hfc = getHarvestFlowConstraint(harvVol, thlb);
			gsc = getGrowingStockConstraint(ft.stateTypes.get(s).get("gsVol"), thlb);
			lc  = getLandCoverConstraint(ft.stateTypes.get(s), lcList);
					
			P = 0.2*hfc + 0.0*gsc + 0.8*lc; 
			stateValue = landscape.weight*U + globalWeight*P;
				
			if(maxValue < stateValue) { 
				maxValue = stateValue; //save the top ranking state
				stateMax = s;
				if( plc >= 0.999 && P >= 0.999) { //this is the threshold for stopping the simulation
					globalConstraintsAchieved = true;
					break;
				}
			}
		}
		//Adjust the global objectives now that a new state (or same) as been found
		setObjectives(type.SUM, ft.stateTypes.get(stateMax), lcList);
		return stateMax;
	}
	
	private float getPropNHRank(float[] attribute, float[] propN, float maxPropN) {
		if(maxPropN == 0f) {
			return 0f;
		}else {
			float rank =0;
			for(int r =0; r < attribute.length; r++) {
				if(attribute[r] > 0) {
					rank = rank + propN[r]; // this equates to one times the propNH
				}
			}
			return (float) rank/maxPropN;
		}
	}
	
	private float getPropNAgeRank(float[] attribute, float[] propN, float maxPropN) {
		if(maxPropN == 0f) {
			return 0f;
		}else {
			float rank =0;
			for(int r =0; r < attribute.length; r++) {
				if(attribute[r] > 100) {
					rank = rank + propN[r]; // this equates to one times the propNH
				}
			}
			return (float) rank/maxPropN;
		}
	}

	private float sumPropN(float[] propN) {
		float out =0;
		for(int n = 0; n < propN.length; n++) {
			out = out + propN[n];
		}
		return out;
	}
	
	private int getMaxHarvestDelay(ArrayList<Integer> landCoverList) {
		int delay = 0;
		for(int d = 0; d<landCoverList.size(); d++) {
			delay = Math.max(delay, landCoverConstraintList.get(landCoverList.get(d)).delayHarvest);
		}
		return delay;
	}

	/**
	 * Gets the remaining percentage of land cover constraints that are achieved through out the planning horizon
	 * @param lcList  the land cover constraints that are not be included in the remaining percentage
	 * @return  a double value of the percentage of land cover constraints achieved
	 */
	private double getLCRemaining(ArrayList<Integer> lcList) {
		int lcRemaining = 0;
		int count = 0;
		for(int f = 1; f < landCoverConstraintList.size(); f ++) { //note that the index 0 is reserved as a null landcover constraint
			if(landCoverConstraintList.get(f).delayHarvest >= landscape.numTimePeriods -1) {
				continue;
			}		
			if(landCoverConstraintList.get(f).perPHAchieved >= 0.99999) { //had to set close to one- due to rounding issues
				lcRemaining ++;
			}
			count ++;
		}
		//Remove any of the land cover constraints in question
		for(int f2 = 0; f2 < lcList.size(); f2 ++) {
			count --;
			if(landCoverConstraintList.get(f2).perPHAchieved >= 0.99999) { //had to set close to one- due to rounding issues
				lcRemaining --;
			}
		}
		
		return (double) lcRemaining/count;
	}

	/**
	 * Sets the global objectives by either adding or subtracting the cells state from the constraints value.
	 * @param operator  either a SUBTRACT or a SUM
	 * @param hashMap  the attributes over the planning horizon that adjust the constraint value
	 * @param landCoverList  the list of LandCoverConstraint objects that belong to this cell
	 */
	private void setObjectives(type operator, HashMap<String, float[]> hashMap, ArrayList<Integer> landCoverList) {
		switch (operator) {
			case SUBTRACT:
				for(int i =0; i < hashMap.get("harvVol").length; i++) {
					planHarvestVolume[i] = planHarvestVolume[i] - hashMap.get("harvVol")[i];
					planGSVolume[i] = planGSVolume[i] - hashMap.get("gsVol")[i];
					
				}
				for(int lc = 0; lc < landCoverList.size(); lc++) {		
					setSubLCConstraint(landCoverList.get(lc),hashMap.get(landCoverConstraintList.get(landCoverList.get(lc)).variable) );
				}
				break;
			case SUM:
				for(int i =0; i < hashMap.get("harvVol").length; i++) {
					planHarvestVolume[i] = planHarvestVolume[i] + hashMap.get("harvVol")[i];
					planGSVolume[i] = planGSVolume[i] + hashMap.get("gsVol")[i];
				}
				for(int lc = 0; lc < landCoverList.size(); lc++) {		
					setAddLCConstraint(landCoverList.get(lc),hashMap.get(landCoverConstraintList.get(landCoverList.get(lc)).variable) );
					setLandCoverPHAchieved(landCoverList.get(lc));
				}
				break;
			}
	}


	private double getLandCoverConstraint(HashMap<String, float[]> hashMap, ArrayList<Integer> landCoverList) {
		double valueOut =0.0;
		float[] vector, currentConstraint;
		int constraint, target;
		
		for(int lcc = 0; lcc < landCoverList.size(); lcc++) {
			constraint = landCoverList.get(lcc);
			vector = hashMap.get(landCoverConstraintList.get(constraint).variable);
			currentConstraint = landCoverConstraintList.get(constraint).achievedConstraint;
			target = landCoverConstraintList.get(constraint).target_cover;
			double weight;
			
			switch(landCoverConstraintList.get(constraint).type) {
				case "nh":
					break;
				case "ge": //greater or equal to
					weight = (double) 1/(vector.length-landCoverConstraintList.get(constraint).delayHarvest)*((double) 1/landCoverList.size());
					
					for(int v =landCoverConstraintList.get(constraint).delayHarvest; v < vector.length; v ++) {
						if(  vector[v] >=  landCoverConstraintList.get(constraint).threshold) {
							valueOut += Math.min(1.0, (currentConstraint[v]+1)/target)*weight;
						}else {
							valueOut += Math.min(1.0, currentConstraint[v]/target)*weight;							
						}
					}
					break;
				case "le": //lesser or equal to
					weight = (double) 1/(vector.length-landCoverConstraintList.get(constraint).delayHarvest)*((double) 1/landCoverList.size());
					
					for(int v =landCoverConstraintList.get(constraint).delayHarvest; v < vector.length; v ++) {
						if(  vector[v] <=  landCoverConstraintList.get(constraint).threshold) {
							valueOut += Math.min(1.0, target/(currentConstraint[v]+1))*weight;
						}else {
							valueOut += Math.min(1.0, target/currentConstraint[v])*weight;							
						}
					}
					break;
			}
		}
		return valueOut;
	}


	private void setLandCoverPHAchieved (int constraint) {
		float weight = (float) 1/(landCoverConstraintList.get(constraint).achievedConstraint.length-landCoverConstraintList.get(constraint).delayHarvest);
		landCoverConstraintList.get(constraint).perPHAchieved = 0f;//reset it
		
		switch(landCoverConstraintList.get(constraint).type) {
			case "nh":
				break;
			case "ge":
				///since some land cover constraints need years for recruitment we don't include those years when assessing if the constraint is achieved
				for(int l = landCoverConstraintList.get(constraint).delayHarvest; l < landCoverConstraintList.get(constraint).achievedConstraint.length; l++) {
					if(landCoverConstraintList.get(constraint).achievedConstraint[l] >= landCoverConstraintList.get(constraint).target_cover) {
						landCoverConstraintList.get(constraint).perPHAchieved += weight;
					};
				}
				break;
			case "le":
				for(int l = landCoverConstraintList.get(constraint).delayHarvest; l < landCoverConstraintList.get(constraint).achievedConstraint.length; l++) {
					if(landCoverConstraintList.get(constraint).achievedConstraint[l] <= landCoverConstraintList.get(constraint).target_cover) {
						landCoverConstraintList.get(constraint).perPHAchieved += weight;
					};
				}
				break;
		}
	}
	
	private double getHarvestFlowConstraint(float[] harvVol, float thlb) {
		double hvConstraint = 0.0;
		double volActual;
		double weight = (double) 1/harvVol.length; 
		for(int h = 0; h < harvVol.length; h++) {
			volActual = harvVol[h]*thlb + planHarvestVolume[h];
			if( volActual >= harvestMin) {
				hvConstraint += weight;
			}else {
				hvConstraint += weight*(volActual/harvestMin);
			}
		}
		return hvConstraint;
	}

	private double getGrowingStockConstraint(float[] gsVol, float thlb) {
		double hvConstraint = 0.0;
		double volActual;
		double weight = (double) 1/gsVol.length; 
		for(int h = 0; h < gsVol.length; h++) {
			volActual = gsVol[h]*thlb + planGSVolume[h];
			if( volActual >= gsMin) {
				hvConstraint += weight;
			}else {
				hvConstraint += weight*(volActual/gsMin);
			}
		}
		return hvConstraint;
	}
	
	/**
	 * Adds a cells state value to the global land cover constraint
	 * @param constraint  the land cover constraint index 
	 * @param value  the attribute of a cells state that is added to the {@code achievedConstraint}
	 */
	private void setAddLCConstraint (int constraint, float[] value) {
		
		switch(landCoverConstraintList.get(constraint).type) {
			case "nh":
				break;
			case "ge": //greater or equal to
				for(int v =0; v < value.length; v ++) {
					if(  value[v] >=  landCoverConstraintList.get(constraint).threshold) {
						landCoverConstraintList.get(constraint).achievedConstraint[v] += 1f;
					}
				}
				break;
			case "le": //lesser or equal to
				for(int v =0; v < value.length; v ++) {
					if(value[v] <=  landCoverConstraintList.get(constraint).threshold) {
						landCoverConstraintList.get(constraint).achievedConstraint[v] += 1f;
					}		
				}
				break;
		}	
	}
	
	/**
	 * Subtracts a cells state value from the global land cover constraint
	 * @param constraint  the land cover constraint index 
	 * @param value  the attribute of a cells state that is subtracted from the {@code achievedConstraint}
	 */
	private void setSubLCConstraint (int constraint, float[] value) {
		switch(landCoverConstraintList.get(constraint).type) {
		case "nh":
			break;
		case "ge": //greater or equal to
			for(int v =0; v < value.length; v ++) {
				if(  value[v] >=  landCoverConstraintList.get(constraint).threshold) {
					landCoverConstraintList.get(constraint).achievedConstraint[v] -= 1f;
				}
			}
			break;
		case "le": //lesser or equal to
			for(int v =0; v < value.length; v ++) {
				if(value[v] <=  landCoverConstraintList.get(constraint).threshold) {
					landCoverConstraintList.get(constraint).achievedConstraint[v] -= 1f;
				}
			
			}
			break;
		}

	}
	
	/** 
	 * Finds the proportion of a cells neighbors that are cut in the same time period
	 * @param adjCellsList
	 * @return a double representing the proportion of adjacent cells that are also cut in the same time period;
	 */
	private float[][] getNeighborProportion(ArrayList<Integer> adjCellsList) {
		float[][] hvn = new float[2][landscape.numTimePeriods];
		float[] tempHVN;
		float[] tempAgeN;
		int state = 0;
		
		for(int n =0; n < adjCellsList.size(); n++) {
			state = cellsList.get(adjCellsList.get(n)).state; // the cellList is no longer in order can't use get. Need a comparator.
			if(state == 0) {
				continue; // go to the next adjacent cell --this one has no harvesting
			}else {
				tempHVN = forestTypeList.get(cellsList.get(adjCellsList.get(n)).foresttype).stateTypes.get(state).get("harvVol");
				tempAgeN = forestTypeList.get(cellsList.get(adjCellsList.get(n)).foresttype).stateTypes.get(state).get("age");
				for(int t = 0 ; t < landscape.numTimePeriods; t ++) {
					if(tempHVN[t] > 0) {
						hvn[0][t]= hvn[0][t] + (float) 1/adjCellsList.size();
					}
					
					if(tempAgeN[t] > 100) {
						hvn[1][t]= hvn[1][t] + (float) 1/adjCellsList.size();
					}
				}
			}
		}		
		return hvn;
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
				int state = cellsList.get(adjCellsList.get(n)-1).state; // the cellList is no longer in order can't use get. Need a comparator.
				//lsnTimePeriod += cellsList.get(adjCellsList.get(n)-1).statesOG.get(state)[t];
				counter ++;
			}
			lsn[t] = lsnTimePeriod/counter;
			counter = 0;
			lsnTimePeriod = 0.0;
		}
		
		return lsn;
	}

	/**
	 * Sum's the values within a float array
	 * @param object the float array
	 * @return  the sum of the float array
	 */
	private float sumFloatVector(float[] object) {
		float out = 0;
		for(int f = 0; f < object.length; f ++) {
			out = out + object[f];
		}
		return out;
	}
	
	 /**
     * Adds two vectors so that the element wise sum is returned.
     * @param planHarvestVolume2	an Array of doubles with length equal to the number of time periods
     * @param scalar	a scalar
     * @return 		a vector of length equal to the number of time periods
     * @see subtractVector
     */
	private double sumArray(float[] vector, float thlb) {
		float outValue = 0L;
		for(int i =0; i < vector.length; i++) {
			outValue = outValue + vector[i]*thlb;
		}
		return outValue;
	}
	
	 /**
     * Adds two vectors so that the element wise sum is returned.
     * @param planHarvestVolume2	an Array of doubles with length equal to the number of time periods
     * @param scalar	a scalar
     * @return 		a vector of length equal to the number of time periods
     * @see subtractVector
     */
	private float[] sumVector(float[] planHarvestVolume, float[] vector2, float thlb) {
		float[] outVector = new float[planHarvestVolume.length];
		for(int i =0; i < outVector.length; i++) {
			outVector[i] = planHarvestVolume[i]+ vector2[i]*thlb;
		}
		return outVector;
	}
	
	 //TODO: need better outputs rather than just age
	  /**
	  * Saves the results of the co-evolutionary cellular automata. Writes to a table called ca_result in the sqlite database
	  * @throws SQLException
	  */
	 public void saveResults ()  throws SQLException {
		String create = "", wild = "", colname = "";

		for(int s = 1; s < landscape.numTimePeriods + 1; s++) {
			if(s == landscape.numTimePeriods ) {
				create += "t" + s  + " numeric";
				wild += "?";
				colname += " t" +s;
			}else {
				create += "t" + s + " numeric, ";
				wild += " ?, ";
				colname += " t" +s+",";
			}	
		}
		
		try { //Get the data from the db
			Connection conn = DriverManager.getConnection("jdbc:sqlite:C:/Users/klochhea/clus/R/SpaDES-modules/forestryCLUS/Quesnel_TSA_clusdb.sqlite");		
			if (conn != null) {
				Statement statement = conn.createStatement();
					
				String dropResultsTable = "DROP TABLE IF EXISTS ca_result_age;";
				statement.execute(dropResultsTable);
					
				String makeResultsTable = "CREATE TABLE IF NOT EXISTS ca_result_age (pixelid integer, " + create + ");";
				statement.execute(makeResultsTable);

				statement.close();
					
				String insertResults =
						      "INSERT INTO ca_result_age (pixelid, "+ colname+ ") VALUES (?, " + wild + ");";
					
				float [] age;
					
				conn.setAutoCommit(false);
				PreparedStatement pstmt = conn.prepareStatement(insertResults);
				try {
					for(int c = 0; c < cellsList.size(); c++) {
						pstmt.setInt(1, cellsList.get(c).pixelid);
						age =  forestTypeList.get(cellsList.get(c).foresttype).stateTypes.get(cellsList.get(c).state).get("age");
				        for(int t = 0; t < age.length; t++) {
				        	pstmt.setInt(t+2, (int) age[t]);
				         }
				        pstmt.executeUpdate();		        	
					}
				}finally {
					System.out.println("...done");
					//pstmt.executeBatch();
					pstmt.close();
					conn.commit();
					//conn.close();
				}  
				
				//TODO: save constraint reporting
				//Landcover Constraints Table
				Statement statementLC = conn.createStatement();
				
				String dropResultsTableLC = "DROP TABLE IF EXISTS ca_result_lc;";
				statementLC.execute(dropResultsTableLC);
					
				String makeResultsTableLC = "CREATE TABLE IF NOT EXISTS ca_result_lc (zoneid integer, variable text, type text, threshold numeric, percentage numeric, target_cover numeric, harvest_delay integer, " + create + " );";
				statementLC.execute(makeResultsTableLC);

				statementLC.close();
					
				String insertResultsLC =
						      "INSERT INTO ca_result_lc (zoneid, variable, type, threshold, percentage, target_cover, harvest_delay, " + colname + " ) VALUES (?,?,?,?,?,?,?," + wild + ");";
					
				float [] ac;
					
				conn.setAutoCommit(false);
				PreparedStatement pstmtLC = conn.prepareStatement(insertResultsLC);
				
				try {
					for(int c = 1; c < landCoverConstraintList.size(); c++) {
						pstmtLC.setInt(1, c);
						pstmtLC.setString(2, landCoverConstraintList.get(c).variable);
						pstmtLC.setString(3, landCoverConstraintList.get(c).type);
						pstmtLC.setFloat(4, landCoverConstraintList.get(c).threshold);
						pstmtLC.setFloat(5, landCoverConstraintList.get(c).percentage);
						pstmtLC.setFloat(6, landCoverConstraintList.get(c).target_cover);
						pstmtLC.setFloat(7, landCoverConstraintList.get(c).delayHarvest);
						ac =  landCoverConstraintList.get(c).achievedConstraint;
				        for(int t = 0; t < ac.length; t++) {
				        	pstmtLC.setInt(t+8, (int) ac[t]);
				         }
				        pstmtLC.executeUpdate();		        	
					}
				}finally {
					System.out.println("...done");
					//pstmt.executeBatch();
					pstmtLC.close();
					conn.commit();
					conn.close();
				} 
			}
			
		} catch (SQLException e) {
		        System.out.println(e.getMessage());
		       }
	}
	
	 	/**
	 	 * Gets the landscape data from a clusdb sqlite databases and assigns various tables to 
	 	 * plain old java objects (POJO).
	 	 * 
	 	 *<p> A number of tables in clusdb are used and manipulated. The process begins by
	 	 * fetching the yields table which includes a primary key for each yield curve 
	 	 * (a forest type can contain two different yield curves) and is converted to a hashMap 
	 	 * {@code yieldTable}. Following the instantiation of {@code yieldTable} an
	 	 * aggregate field within the clusdb called forest_type is generated which is a unique identifier 
	 	 * for management type (see below) and describes the transition assumptions following harvesting. 
	 	 * All of the forest types are then stored in {@code forestTypeList} which 
	 	 * stores {@code ForestType} objects. Next, spatial information is retrieved from clusdb in order
	 	 * to instantiate the {@code landscape} object. Then, each cell is instantiated and stored as
	 	 * {@code cellsList}. Lastly, landcover constraint objects are instantiated
	 	 * and stored in {@code landCoverConstraintList} and each cell
	 	 * is assigned landcover constraint identifiers which are stored in the {@code Cell} object.
	 	 * 
	 	 * <h4> Management Types </h4>
	 	 * <p>There are several management types with possibility of adding more. These are hard coded to include:
	 	 * 
	 	 * <li>-1: Non-contributing
	 	 * <li>  0: Contributing to landcover constraints
	 	 * <li>  1: Contributing to landcover constraints and have a natural origin
	 	 * <li>  2: Contributing to landcover constraints and have a managed origin
	 	 * 
	 	 * @throws Exception  sqlite
	 	 */
		public void getCLUSData() throws Exception {
			try { // Load the driver
			    Class.forName("org.sqlite.JDBC");
			} catch (ClassNotFoundException eString) {
			    System.err.println("Could not init JDBC driver - driver not found");
			}		
			try { //Get the data from the db
				Connection conn = DriverManager.getConnection("jdbc:sqlite:C:/Users/klochhea/clus/R/SpaDES-modules/forestryCLUS/Quesnel_TSA_clusdb.sqlite");		
				if (conn != null) {
					System.out.println("Connected to clusdb");
					Statement statement = conn.createStatement();
					System.out.print("Getting yield information");
					
					//Create a yield lookup
					String yc_lookup = "CREATE TABLE IF NOT EXISTS yield_lookup as SELECT ROW_NUMBER() OVER( ORDER BY yieldid asc) as id_yc, yieldid, count(*) as num FROM yields GROUP BY yieldid;";
					statement.execute(yc_lookup);
					
					//Getting the yields--so far just age and height;
					String get_yc = "SELECT o.id_yc," +
							"  MAX(CASE WHEN p.age = 0 THEN p.tvol END) AS vol_0," + 
							"  MAX(CASE WHEN p.age = 10 THEN p.tvol END) AS vol_10," + 
							"  MAX(CASE WHEN p.age = 20 THEN p.tvol END) AS vol_20," + 
							"  MAX(CASE WHEN p.age = 30 THEN p.tvol END) AS vol_30," + 
							"  MAX(CASE WHEN p.age = 40 THEN p.tvol END) AS vol_40," + 
							"  MAX(CASE WHEN p.age = 50 THEN p.tvol END) AS vol_50," + 
							"  MAX(CASE WHEN p.age = 60 THEN p.tvol END) AS vol_60," + 
							"  MAX(CASE WHEN p.age = 70 THEN p.tvol END) AS vol_70," + 
							"  MAX(CASE WHEN p.age = 80 THEN p.tvol END) AS vol_80," + 
							"  MAX(CASE WHEN p.age = 90 THEN p.tvol END) AS vol_90," + 
							"  MAX(CASE WHEN p.age = 100 THEN p.tvol END) AS vol_100," + 
							"  MAX(CASE WHEN p.age = 110 THEN p.tvol END) AS vol_110," + 
							"  MAX(CASE WHEN p.age = 120 THEN p.tvol END) AS vol_120," + 
							"  MAX(CASE WHEN p.age = 130 THEN p.tvol END) AS vol_130," + 
							"  MAX(CASE WHEN p.age = 140 THEN p.tvol END) AS vol_140," + 
							"  MAX(CASE WHEN p.age = 150 THEN p.tvol END) AS vol_150," + 
							"  MAX(CASE WHEN p.age = 160 THEN p.tvol END) AS vol_160," + 
							"  MAX(CASE WHEN p.age = 170 THEN p.tvol END) AS vol_170," + 
							"  MAX(CASE WHEN p.age = 180 THEN p.tvol END) AS vol_180," + 
							"  MAX(CASE WHEN p.age = 190 THEN p.tvol END) AS vol_190," + 
							"  MAX(CASE WHEN p.age = 200 THEN p.tvol END) AS vol_200," + 
							"  MAX(CASE WHEN p.age = 210 THEN p.tvol END) AS vol_210," + 
							"  MAX(CASE WHEN p.age = 220 THEN p.tvol END) AS vol_220," + 
							"  MAX(CASE WHEN p.age = 230 THEN p.tvol END) AS vol_230," + 
							"  MAX(CASE WHEN p.age = 240 THEN p.tvol END) AS vol_240," + 
							"  MAX(CASE WHEN p.age = 250 THEN p.tvol END) AS vol_250," + 
							"  IFNULL(MAX(CASE WHEN p.age = 260 THEN p.tvol END), MAX(CASE WHEN p.age = 250 THEN p.tvol END)) AS vol_260," + 
							"  IFNULL(MAX(CASE WHEN p.age = 270 THEN p.tvol END), MAX(CASE WHEN p.age = 250 THEN p.tvol END)) AS vol_270," + 
							"  IFNULL(MAX(CASE WHEN p.age = 280 THEN p.tvol END), MAX(CASE WHEN p.age = 250 THEN p.tvol END)) AS vol_280," + 
							"  IFNULL(MAX(CASE WHEN p.age = 290 THEN p.tvol END), MAX(CASE WHEN p.age = 250 THEN p.tvol END)) AS vol_290," + 
							"  IFNULL(MAX(CASE WHEN p.age = 300 THEN p.tvol END), MAX(CASE WHEN p.age = 250 THEN p.tvol END)) AS vol_300," + 
							"  IFNULL(MAX(CASE WHEN p.age = 310 THEN p.tvol END), MAX(CASE WHEN p.age = 250 THEN p.tvol END)) AS vol_310," + 
							"  IFNULL(MAX(CASE WHEN p.age = 320 THEN p.tvol END), MAX(CASE WHEN p.age = 250 THEN p.tvol END)) AS vol_320," + 
							"  IFNULL(MAX(CASE WHEN p.age = 330 THEN p.tvol END), MAX(CASE WHEN p.age = 250 THEN p.tvol END)) AS vol_330," + 
							"  IFNULL(MAX(CASE WHEN p.age = 340 THEN p.tvol END), MAX(CASE WHEN p.age = 250 THEN p.tvol END)) AS vol_340," + 
							"  IFNULL(MAX(CASE WHEN p.age = 350 THEN p.tvol END), MAX(CASE WHEN p.age = 250 THEN p.tvol END)) AS vol_350," + 
							"  MAX(CASE WHEN p.age = 0 THEN p.height END) AS ht_0," + 
							"  MAX(CASE WHEN p.age = 10 THEN p.height END) AS ht_10," + 
							"  MAX(CASE WHEN p.age = 20 THEN p.height END) AS ht_20," + 
							"  MAX(CASE WHEN p.age = 30 THEN p.height END) AS ht_30," + 
							"  MAX(CASE WHEN p.age = 40 THEN p.height END) AS ht_40," + 
							"  MAX(CASE WHEN p.age = 50 THEN p.height END) AS ht_50," + 
							"  MAX(CASE WHEN p.age = 60 THEN p.height END) AS ht_60," + 
							"  MAX(CASE WHEN p.age = 70 THEN p.height END) AS ht_70," + 
							"  MAX(CASE WHEN p.age = 80 THEN p.height END) AS ht_80," + 
							"  MAX(CASE WHEN p.age = 90 THEN p.height END) AS ht_90," + 
							"  MAX(CASE WHEN p.age = 100 THEN p.height END) AS ht_100," + 
							"  MAX(CASE WHEN p.age = 110 THEN p.height END) AS ht_110," + 
							"  MAX(CASE WHEN p.age = 120 THEN p.height END) AS ht_120," + 
							"  MAX(CASE WHEN p.age = 130 THEN p.height END) AS ht_130," + 
							"  MAX(CASE WHEN p.age = 140 THEN p.height END) AS ht_140," + 
							"  MAX(CASE WHEN p.age = 150 THEN p.height END) AS ht_150," + 
							"  MAX(CASE WHEN p.age = 160 THEN p.height END) AS ht_160," + 
							"  MAX(CASE WHEN p.age = 170 THEN p.height END) AS ht_170," + 
							"  MAX(CASE WHEN p.age = 180 THEN p.height END) AS ht_180," + 
							"  MAX(CASE WHEN p.age = 190 THEN p.height END) AS ht_190," + 
							"  MAX(CASE WHEN p.age = 200 THEN p.height END) AS ht_200," + 
							"  MAX(CASE WHEN p.age = 210 THEN p.height END) AS ht_210," + 
							"  MAX(CASE WHEN p.age = 220 THEN p.height END) AS ht_220," + 
							"  MAX(CASE WHEN p.age = 230 THEN p.height END) AS ht_230," + 
							"  MAX(CASE WHEN p.age = 240 THEN p.height END) AS ht_240," + 
							"  MAX(CASE WHEN p.age = 250 THEN p.height END) AS ht_250," + 
							"  IFNULL(MAX(CASE WHEN p.age = 260 THEN p.height END), MAX(CASE WHEN p.age = 250 THEN p.height END)) AS ht_260," + 
							"  IFNULL(MAX(CASE WHEN p.age = 270 THEN p.height END), MAX(CASE WHEN p.age = 250 THEN p.height END)) AS ht_270," + 
							"  IFNULL(MAX(CASE WHEN p.age = 280 THEN p.height END), MAX(CASE WHEN p.age = 250 THEN p.height END)) AS ht_280," + 
							"  IFNULL(MAX(CASE WHEN p.age = 290 THEN p.height END), MAX(CASE WHEN p.age = 250 THEN p.height END)) AS ht_290," + 
							"  IFNULL(MAX(CASE WHEN p.age = 300 THEN p.height END), MAX(CASE WHEN p.age = 250 THEN p.height END)) AS ht_300," + 
							"  IFNULL(MAX(CASE WHEN p.age = 310 THEN p.height END), MAX(CASE WHEN p.age = 250 THEN p.height END)) AS ht_310," + 
							"  IFNULL(MAX(CASE WHEN p.age = 320 THEN p.height END), MAX(CASE WHEN p.age = 250 THEN p.height END)) AS ht_320," + 
							"  IFNULL(MAX(CASE WHEN p.age = 330 THEN p.height END), MAX(CASE WHEN p.age = 250 THEN p.height END)) AS ht_330," + 
							"  IFNULL(MAX(CASE WHEN p.age = 340 THEN p.height END), MAX(CASE WHEN p.age = 250 THEN p.height END)) AS ht_340," + 
							"  IFNULL(MAX(CASE WHEN p.age = 350 THEN p.height END), MAX(CASE WHEN p.age = 250 THEN p.height END)) AS ht_350" + 
							" FROM yield_lookup o " + 
							" JOIN yields p " + 
							"  ON o.yieldid = p.yieldid " + 
							" GROUP BY o.id_yc ORDER BY o.id_yc;";
					ResultSet rs0 = statement.executeQuery(get_yc);
					yieldTable.add(0, new HashMap<String, float[]>());
					int id_yc = 1;
					
					while(rs0.next()) {
						yieldTable.add(id_yc, new HashMap<String, float[]>());
						float[] vol = new float[36];
						float[] ht = new float[36];
						for(int y =0; y < 36; y++) {
							vol[y] = rs0.getFloat(y+2);//the first one is the id the second starts the 36 yields
							ht[y] = rs0.getFloat(y+38); //the yields for height are the next 36 yields
						}
						yieldTable.get(id_yc).put("vol", vol);
						yieldTable.get(id_yc).put("height", ht);
						id_yc ++;
					}
					System.out.println("...done");
					
					System.out.print("Getting state information");
					//Create manage_type field to check what type of management the cell has.
					// manage_type : -1 means non forested; 0: means forested but not harvestable; 1: forest and harvestable
					String manage_type = "SELECT COUNT(*) FROM pragma_table_info('pixels') WHERE name='manage_type';";
					ResultSet rs1 = statement.executeQuery(manage_type);
					if(rs1.getInt(1) == 0) { //only populate if the pixels table has no records in it
						//create a column in the pixels table called manage_type
						String add_column1 = "ALTER TABLE pixels ADD COLUMN manage_type integer default -1;"; // non-contributing
						statement.execute(add_column1);
					}
					
					String populate_type0 = "UPDATE pixels SET manage_type = 0 where age is not null and yieldid is not null;"; //contributing
					statement.execute(populate_type0 );
					String populate_type1 = "UPDATE pixels SET manage_type = 1 where thlb > 0 and age is not null and yieldid is not null and yieldid_trans is not null;"; // natural origin
					statement.execute(populate_type1 );		
					String populate_type2 = "UPDATE pixels SET manage_type = 2 where thlb > 0 and age is not null and yieldid is not null and yieldid_trans is not null and yieldid > 0;"; // managed origin
					statement.execute(populate_type2);	
					
					//Drop old table
					String drop_foresttype = "DROP TABLE foresttype;";
					
					statement.execute(drop_foresttype);
					//Create the 'foresttype' table and populate it with unique forest types
					String create_foresttype = "CREATE TABLE IF NOT EXISTS foresttype AS " +
							" SELECT ROW_NUMBER() OVER(ORDER BY age asc, yield_lookup.id_yc, t.id_yc_trans, pixels.manage_type) AS foresttype_id, age, id_yc, id_yc_trans, pixels.manage_type, pixels.yieldid, pixels.yieldid_trans " + 
							" FROM pixels " + 
							" LEFT JOIN yield_lookup ON pixels.yieldid = yield_lookup.yieldid" + 
							" LEFT JOIN (SELECT id_yc AS id_yc_trans, yieldid FROM yield_lookup) t ON pixels.yieldid_trans = t.yieldid " + 
							" WHERE manage_type > -1 AND id_yc IS NOT null GROUP BY age, id_yc, id_yc_trans, manage_type;";	
					statement.execute(create_foresttype);
					
					//Set the states for each foresttype
					String getForestType = "SELECT foresttype_id, age, id_yc, id_yc_trans, manage_type FROM foresttype ORDER BY foresttype_id;";
					ResultSet rs2 = statement.executeQuery(getForestType);
					forestTypeList.add(0, new ForestType()); //at id zero there is no foresttype -- add a null
					int forestTypeID = 1;
					while(rs2.next()) {
						if(forestTypeID == rs2.getInt(1)) {
							ForestType forestType = new ForestType(); //create a new ForestType object
							forestType.setForestTypeAttributes(rs2.getInt(1), Math.min(350, rs2.getInt(2)), rs2.getInt(3), rs2.getInt(4), rs2.getInt(5)); //the max age a cell can have is 350
							forestType.setForestTypeStates(rs2.getInt(5), landscape.ageStatesTemplate.get(Math.min(350, rs2.getInt(2))), landscape.harvestStatesTemplate.get(Math.min(350, rs2.getInt(2))), yieldTable.get(rs2.getInt(3)),  yieldTable.get(rs2.getInt(4)), landscape.minHarvVol);
							forestTypeList.add(forestTypeID, forestType);
						}else {
							throw new Exception("forestTypeID does not coincide with the forestTypeList! Thus, the list of forestTypes will be wrong");
						}
						forestTypeID ++;
					}
					System.out.println("...done");
					
					System.out.print("Getting spatial information");
					//Get raster information used to set the GRID object. This is important for determining adjacency
					String getRasterInfo = "SELECT ncell, nrow FROM raster_info";
					ResultSet rs3 = statement.executeQuery(getRasterInfo);
					while(rs3.next()) {
						landscape.setGrid(rs3.getInt("ncell"), rs3.getInt("nrow"));
					}
					System.out.println("...done");
					
					System.out.print("Getting cell information");			
					int[] pixelidIndex = new int[landscape.ncell + 1];
					for(int i =0; i < landscape.ncell+1; i++) {
						pixelidIndex[i] = i; //this will be used for adjacency after the Cells objects are instantiated
					}
					int[] cellIndex = new int[landscape.ncell + 1]; // since pixelid starts one rather than zero, add a one
				    Arrays.fill(cellIndex, -1); // used to look up the index from the pixelid   
					
				    //Instantiate the Cells objects for each cell that is forested og manage_type >= 0
					String getAllCells = "SELECT pixelid, pixels.age, foresttype.foresttype_id,  pixels.manage_type, thlb "
							+ "FROM pixels "
							+ "LEFT JOIN foresttype ON pixels.age = foresttype.age AND "
							+ "pixels.yieldid = foresttype.yieldid AND pixels.yieldid_trans = foresttype.yieldid_trans "
							+ "AND pixels.manage_type = foresttype.manage_type "
							+ "WHERE pixels.yieldid IS NOT null AND "
							+ "pixels.age IS NOT null AND "
							+ "foresttype.foresttype_id IS NOT null "
							+ "ORDER BY pixelid;";
					ResultSet rs4 = statement.executeQuery(getAllCells);
					int counter = 0; // this is the index for cellsList -- the list of Cells objects
					while(rs4.next()) { // not all cells get a state of zero initially -- useful for inferring the landCoverConstraints ---years of recruitment
						cellsList.add(new Cells(rs4.getInt(1), rs4.getInt(2), rs4.getInt(3), rs4.getInt(4), rs4.getFloat(5)));
						cellIndex[rs4.getInt(1)] = counter;
						counter ++;
					}				
					System.out.println("...done");
					
					System.out.print("Getting constraint information");
					landCoverConstraintList.add(0, new LandCoverConstraint()); // zero is a null landCoverConstraint
					counter =0;
					String getConstraintObjects = "SELECT id, variable, threshold, type, percentage, t_area FROM zoneConstraints ORDER BY id;";
					ResultSet rs5 = statement.executeQuery(getConstraintObjects);
					while(rs5.next()) {
						counter ++;
						if(counter == rs5.getInt(1)) {
							landCoverConstraintList.add(counter, new LandCoverConstraint());
							landCoverConstraintList.get(counter).setLandCoverConstraintParameters(rs5.getString(2), rs5.getFloat(3),rs5.getString(4), rs5.getFloat(5), rs5.getFloat(6), landscape.numTimePeriods);
						}else {
							throw new Exception("zoneConstraint id does not coincide with the landCoverConstraintList! Thus, the list of constraints will be wrong");
						}		
					}
					System.out.println("...done");
					
					System.out.print("Setting constraints to cells");
					String setConstraints = "SELECT zone_column FROM zone WHERE reference_zone IN ('rast.zone_cond_beo','rast.zone_cond_vqo','rast.zone_cond_wha', 'rast.zone_cond_uwr','rast.zone_cond_nharv');";
					ResultSet rs6 = statement.executeQuery(setConstraints);
					ArrayList<String> zones = new ArrayList<String>();
					while(rs6.next()) {
						zones.add(rs6.getString(1));
					}
					
					int cell;
					for(int z = 0; z < zones.size(); z++) {
						String getZonesConstraints = "SELECT pixelid, z.id "
								+ "FROM pixels "
								+ "LEFT JOIN (SELECT * FROM zoneConstraints WHERE zone_column = '" +zones.get(z)+ "' and variable IN ('age', 'height', '')) AS z "
								+ "ON pixels." + zones.get(z) +" = z.zoneid "
								+ "WHERE pixels."+zones.get(z)+" is not null AND z.id is not null;";
						ResultSet rs7 = statement.executeQuery(getZonesConstraints);
						
						while(rs7.next()) { 
							cell = cellIndex[rs7.getInt(1)];
							if(cell >= 0) { //removes non-treed area (e.g., INDEX = -1) which has no state changes
								cellsList.get(cell).setLandCoverConstraint(rs7.getInt(2));
							}
						}
					}
					System.out.println("...done");

					//Close all connections to the clusdb	
					statement.close();
					conn.close();
					System.out.println("Disconnected from clusdb");
					
					System.out.print("Setting neighbourhood information");	
					int cols = (int) landscape.ncell/landscape.nrow;
					for(int c = 0; c < cellsList.size(); c++) {
						ArrayList<Integer> adjList = new ArrayList<Integer>();
						adjList = getNeighbourhood(cellsList.get(c).pixelid, cols , pixelidIndex, cellIndex);
						cellsList.get(c).setNeighbourhood(adjList);
					}				
					System.out.println("...done");
				} 	              
	        }catch (SQLException e) {
	            System.out.println(e.getMessage());
	        }
		}
		
		/**
		 * Gets the adjacency list of neighboring cells
		 * @param id  the index of the cell whose neighbors are to be found
		 * @param cols  the number of columns in the {@code Grid}
		 * @param pixelidIndex  the cells index that relates to the {@code Grid}
		 * @param cellIndex the cells index that relates to the {@code cellsList}
		 * @return  an ArrayList of Integers that corresponds to the neighbors of the cell 
		 */
		private ArrayList<Integer> getNeighbourhood(int id, int cols, int[] pixelidIndex, int[] cellIndex) {
		    ArrayList<Integer> cs = new ArrayList<Integer>(8);
		    //check if cell is on an edge
		    boolean l = id %  cols > 0;        //has left
		    boolean u = id >= cols;            //has upper
		    boolean r = id %  cols < cols - 1; //has right
		    boolean d = id <   pixelidIndex.length - cols;   //has lower
		    //collect all existing adjacent cells
		    if (l && cellIndex[pixelidIndex[id - 1]] > 0) {
		    	cs.add(cellIndex[pixelidIndex[id - 1]] );
		    }
		    if (l && u && cellIndex[pixelidIndex[id - 1 - cols]] > 0) {
		    	cs.add(cellIndex[pixelidIndex[id - 1 - cols]]);
		    }
		    if (u && cellIndex[pixelidIndex[id     - cols]] > 0) {
		    	cs.add(cellIndex[pixelidIndex[id     - cols]]);
		    }
		    if (u && r && cellIndex[pixelidIndex[id + 1 - cols]] > 0) {
		    	cs.add(cellIndex[pixelidIndex[id + 1 - cols]]);
		    }
		    if (r && cellIndex[pixelidIndex[id + 1       ]] > 0)     {
		    	cs.add(cellIndex[pixelidIndex[id + 1       ]]);
		    }
		    if (r && d && cellIndex[pixelidIndex[id + 1 + cols]] > 0) {
		    	cs.add(cellIndex[pixelidIndex[id + 1 + cols]]);
		    }
		    if (d && cellIndex[pixelidIndex[id     + cols]] > 0)      {
		    	cs.add(cellIndex[pixelidIndex[id     + cols]]);
		    }
		    if (d && l && cellIndex[pixelidIndex[id - 1 + cols]] > 0) {
		    	cs.add(cellIndex[pixelidIndex[id - 1 + cols]]);
		    }
		    
		    return cs;
		}
		
        //TODO: connect the java objects to R
		 /**
	     * Instantiates java objects developed in R
	     */
		public void setRParms(int[] to, int[] from, double[] weight, int[] dg, ArrayList<LinkedHashMap<String, Object>> histTable, double allowdiff ) {
			//Instantiate the Edge objects from the R data.table
			//System.out.println("Linking to java...");
			for(int i =0;  i < to.length; i++){
				 //this.edgeList.add( new Edges((int)to[i], (int)from[i], (double)weight[i]));
			}
			//System.out.println(to.length + " edges ");

			//this.degree = Arrays.stream(dg).boxed().toArray( Integer[]::new );
			//this.idegree = Arrays.stream(dg).boxed().toArray( Integer[]::new );
			//System.out.println(degree.length + " degree ");
			
			//this.hist = new histogram(histTable);
			//System.out.println(this.hist.bins.size() + " target bins have been added");
			
			//dg = null;
			//histTable.clear();
			//to = null;
			//from =null;
			//weight = null;
			
			//this.allowableDiff = allowdiff;
		}

	/** 
	* <h4> DEPRECATED </h4>
	* <p>
	* This algorithm was found to produce feasible results but no guarantee of a 'good' result
	* <p>
	* Simulates the cellular automata follow Mathey et al. This is the main algorithm for searching the decision space. 
	* <li> 1. global level penalties are determined which incentivize cell level decisions
	* <li> 2. create a vector of randomly sampled without replacement cell indexes 
	* <li> 3. the first random cell is tested if its at maximum state which includes context independent values such as
	* the maximum amount of volume the cell can produce of the planning horizon and context dependent values such as
	* its contribution, as well as, the surrounding cells contribution to late-seral forest targets. 
	* <li> 4. If already at max state then proceed to the next cell. Else update to its max state.
	* <li> 5. If there are no more stands to change or the number of iterations has been reached - end.
	*/
	public void simulate() {
		int block = 0;
		int numIterSinceFreq = 0;
		int[] blockParams = {0, 2000, 4000,7000,10000, 1000000}; // add a large number so there's no out of bounds issues
		int[] freqParams = {0, 300,200,100,1,1};
		boolean timeToSetPenalties = false;
		int [] maxStates = new int[cellsList.size()];
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
			
			Arrays.fill(planHarvestVolume, 0L); //set the harvestVolume indicator
			Arrays.fill(planLateSeral, 0); //set the late-seral forest indicator
			objValue = 0; //reset the object value;
			
			int[] rand = new Random().ints(0, cellsList.size()).distinct().limit(cellsList.size()).toArray();; // Randomize the stand or cell list
			
			for(int j = 0; j < rand.length; j++) { //Stand or cell list loop
				int maxState = getMaxState(rand[j]);
				if(cellsList.get(rand[j]).state == maxState) { //When the cell is at its max state - go to the next cell
					//System.out.println("Cell:" + cellList.get(rand[j]).id + " already at max");
					if(j == cellsList.size()-1) {
						finalPlan = true;
					}
					continue; // Go to the next cell -- this one is already at its max
				}else{ // Change the state of the cell to its max state and then exit the stand or cell list loop
					//System.out.println("Cell:" + cellsList.get(rand[j]).pixelid + " change from " + cellList.get(rand[j]).state + " to " + maxState );
					cellsList.get(rand[j]).state = maxState; //transition function - set the new state to the max state
					break;
				}
				
			}
			
			//Output the global indicators (aggregate all cell level values)
			for(int c =0; c < cellsList.size(); c++) {// Iterate through each of the cell and their corresponding state
				int state = cellsList.get(c).state;
				double isf, dsf;
					
				//isf = DoubleStream.of(multiplyVector(cellList.get(c).statesPrHV.get(state), sumVector(landscape.lambda, subtractVector(landscape.alpha,landscape.beta)))).sum(); //I s(f) is the context independent component of the obj function			
				//dsf = DoubleStream.of(multiplyVector(divideScalar(sumVector(cellList.get(c).statesOG.get(state), getNeighborLateSeral(cellList.get(c).adjCellsList)), landscape.numTimePeriods*2), sumVector(landscape.lambda,landscape.gamma))).sum();
				//isf = DoubleStream.of(multiplyVector(landscape.lambda,multiplyVector(cellsList.get(c).statesPrHV.get(state), subtractVector(landscape.alpha,landscape.beta)))).sum(); //I s(f) is the context independent component of the obj function			
				//dsf = DoubleStream.of(multiplyVector(landscape.oneMinusLambda, multiplyVector(divideScalar(sumIntDoubleVector(cellList.get(c).statesOG.get(state), getNeighborLateSeral(cellList.get(c).adjCellsList)), landscape.numTimePeriods*2), landscape.gamma))).sum();
					
				//objValue += isf + dsf; //objective value
				
				//planHarvestVolume = sumVector(planHarvestVolume, cellsList.get(c).statesHarvest.get(state)) ;//harvest volume
				//planLateSeral = sumIntVector(planLateSeral, cellsList.get(c).statesOG.get(state));
			}
			System.out.println("iter:"+ i + " obj:" + objValue);
			if(maxObjValue < objValue && i > 14000) {
				maxObjValue = objValue;
				maxPlanHarvestVolume = planHarvestVolume.clone();
				maxPlanLateSeral = planLateSeral.clone();
				
				for(int h =0; h < cellsList.size(); h++) {
					maxStates[h] = cellsList.get(h).state;
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
	* <h4> DEPRECATED </h4>
	* Retrieves the penalty for late-seral forest
	* @param planLateSeral2	the plan harvest volume
	* @param lateSeralTarget2	the minimum amount of late-seral needed
	* @return 		an array of gamma penalties
	*/
	 private double[] getGammaPenalty(int[] planLateSeral2, float lateSeralTarget2) {
			double[] gamma = new double[landscape.numTimePeriods];
			for(int a = 0; a < planLateSeral2.length; a++ ) {
				if(planLateSeral2[a] <= lateSeralTarget2) {
					if(planLateSeral2[a] == 0.0) {//check divisible by zero
						gamma[a] = lateSeralTarget2/0.00001; //use a small number in lieu of zero
					}else {
						gamma[a] = (double) lateSeralTarget2/planLateSeral2[a];
					}
				}else {
					gamma[a] = 0.0;
				}
				
			}
			return gamma;
	}
	 
	/**
	* <h4> DEPRECATED </h4>
	* Retrieves the penalty for over harvesting
	* @param planHarvestVolume2	the plan harvest volume
	* @param harvestMax2	the maximum harvest volume
	* @return 		an array of beta penalties
	*/
	private double[] getBetaPenalty(float[] planHarvestVolume2, float harvestMax2) {
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
	 * <h4> DEPRECATED </h4>
     * Retrieves the penalty for under harvesting
     * @param planHarvestVolume2	the plan harvest volume
     * @param harvestMin2	the minimum harvest volume
     * @return 		an array of alpha penalties
     */
	private double[] getAlphaPenalty(float[] planHarvestVolume2, float harvestMin2) {
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
	 * <h4> DEPRECATED </h4>
     * Retrieves the schedule or state with the maximum value for this cell object
     * @param id	the index of the cell or stand
     * @return 		an integer representing the maximum state of a cell
     */
	public int getMaxState(int id) {
		double maxValue = 0.0;
		double stateValue, isf,dsf;
		int stateMax =0;
		double[] lsn = new double[landscape.numTimePeriods];
		lsn = getNeighborLateSeral(cellsList.get(id).adjCellsList);
	
		/*for(int i = 0; i < cellsList.get(id).statesPrHV.size(); i++) { // Iterate through each of the plausible treatment schedules also known as states
		
			//isf = DoubleStream.of(multiplyVector(cellList.get(id).statesPrHV.get(i), sumVector(landscape.lambda, subtractVector(landscape.alpha,landscape.beta)))).sum(); //I s(f) is the context independent component of the obj function			
			//dsf = DoubleStream.of(multiplyVector(divideScalar(sumVector(cellList.get(id).statesOG.get(i), lsn), landscape.numTimePeriods*2), sumVector(landscape.oneMinusLambda,landscape.gamma))).sum();
			isf = DoubleStream.of(multiplyVector(landscape.lambda,multiplyVector(cellsList.get(id).statesPrHV.get(i), subtractVector(landscape.alpha,landscape.beta)))).sum(); //I s(f) is the context independent component of the obj function			
			dsf = DoubleStream.of(multiplyVector(landscape.oneMinusLambda, multiplyVector(divideScalar(sumIntDoubleVector(cellList.get(id).statesOG.get(i), lsn), landscape.numTimePeriods*2.0), landscape.gamma))).sum();
			
			stateValue = isf + dsf;
			if(maxValue < stateValue) {
				maxValue = stateValue;
				stateMax = i;
			}
		};
		*/
		return stateMax;
	}

}

	


