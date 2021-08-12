package coe_cellular_automata;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Random;
import java.util.stream.DoubleStream;

public class CellularAutomata {
	ArrayList<Cell> cellList = new ArrayList<Cell>();
	int numIter=10000;
	double lambda = 0.5;
	double objValue;
	boolean finalPlan = false;
	//Create the parameters for the GRID
	Grid landscape = new Grid();
	ArrayList<ArrayList<LinkedHashMap<String, Double>>> yields = new ArrayList<ArrayList<LinkedHashMap<String, Double>>>();
	
	
	public CellularAutomata() {

	}
	
	public void simulate() {
		
		landscape.setPenalties();//set penalty parameters - alpha, beta and gamma
		for(int i=0; i < numIter; i++) { // Iteration loop		
			int[] rand = new Random().ints(0, cellList.size()).distinct().limit(cellList.size()).toArray();; // Randomize the stand or cell list
			objValue =0.0; //reset the object value;
			
			for(int j = 0; j < rand.length; j++) { //Stand or cell list loop
				int maxState = getMaxState(rand[j]);
				if(cellList.get(rand[j]).state == maxState) { //When the cell is at its max state - go to the next cell
					//System.out.println("Cell:" + cellList.get(rand[j]).id + " already at max");
					if(j == cellList.size() -1) {
						finalPlan = true;
					}
					continue;
				}else{ // Change the state of the cell to its max state and then exit the stand or cell list loop
					cellList.get(rand[j]).state = maxState;
					//System.out.println("Cell:" + cellList.get(rand[j]).id + " change to " + cellList.get(rand[j]).state);
				    break;
				}
				
			}
			//Report objective function
			for(int c =0; c < cellList.size(); c++) {// Iterate through each of the cell and their corresponding state
					int state = cellList.get(c).state;
					double isf, dsf;
					
					isf = DoubleStream.of(multiplyVector(cellList.get(c).statesPrHV.get(state), sumVector(landscape.lambda, subtractVector(landscape.alpha,landscape.beta)))).sum(); //I s(f) is the context independent component of the obj function			
					dsf = DoubleStream.of(multiplyVector(divideVector(sumVector(cellList.get(c).statesOG.get(state), getNeighborLateSeral(cellList.get(c).adjCellsList)), landscape.numTimePeriods*2), sumVector(landscape.lambda,landscape.gamma))).sum();
					
					objValue += isf + dsf;
			}
			
			System.out.println("iter:"+ i + " obj:" + objValue);
			
			if(finalPlan) {
				System.out.println("All cells at max state" + " iteration:" + i);
				break;
			}
		}
	}
	

	public int getMaxState(int id) {
		double maxValue = 0.0;
		double stateValue, isf,dsf;
		int stateMax =0;
		
		for(int i = 0; i < cellList.get(id).statesPrHV.size(); i++) { // Iterate through each of the plausible treatment schedules also known as states
			isf = DoubleStream.of(multiplyVector(cellList.get(id).statesPrHV.get(i), sumVector(landscape.lambda, subtractVector(landscape.alpha,landscape.beta)))).sum(); //I s(f) is the context independent component of the obj function			
			dsf = DoubleStream.of(multiplyVector(divideVector(sumVector(cellList.get(id).statesOG.get(i), getNeighborLateSeral(cellList.get(id).adjCellsList)), landscape.numTimePeriods*2), sumVector(landscape.lambda,landscape.gamma))).sum();
			
			stateValue = isf + dsf;
			if(maxValue < stateValue) {
				maxValue = stateValue;
				stateMax = i;
			}
		};
		
		return stateMax;
	}
		

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

	private double[] multiplyVector (double[] vector1, double[] vector2) {
		double[] outVector = new double[vector1.length];
		for(int i =0; i < outVector.length; i++) {
			outVector[i] = vector1[i]*vector2[i];
		}
		return outVector;
	}
	
	private double[] divideVector (double[] vector1, double scalar) {
		double[] outVector = new double[vector1.length];
		for(int i =0; i < outVector.length; i++) {
			outVector[i] = vector1[i]/scalar;
		}
		return outVector;
	}
	
	private double[] subtractVector (double[] vector1, double[] vector2) {
		double[] outVector = new double[vector1.length];
		for(int i =0; i < outVector.length; i++) {
			outVector[i] = vector1[i]-vector2[i];
		}
		return outVector;
	}
	
	private double[] sumVector(double[] vector1, double[] vector2) {
		double[] outVector = new double[vector1.length];
		for(int i =0; i < outVector.length; i++) {
			outVector[i] = vector1[i]+vector2[i];
		}
		return outVector;
	}
	
	public void setRParms() {
		// TODO Auto-generated method stub
	}
	
	
	public void createData() {
		
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
