package castor;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;

import lpsolve.LpSolve;
import lpsolve.LpSolveException;

public class Q3 {
	
	double evenFlowDeviation = 0.2;
	double percentInitalGS = 0.75;	
	
    CellularAutomata ca = new CellularAutomata();
    
	/** 
	* Class constructor.
	 * @throws Exception 
	*/
	public Q3(){
		try {
			ca.getCastorData();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	public void lpModel1() {
		
		ArrayList<Double> objRows = new ArrayList<Double>();
		ArrayList<Integer> objCols = new ArrayList<Integer>();
		
		ArrayList<Double> endingGSConstraintRows = new ArrayList<Double>();
		
		ArrayList<Double> areaConstraintsValue = new ArrayList<Double>();
		ArrayList<double[]> areaConstraintsRows = new ArrayList<double[]>();
		ArrayList<int[]> areaConstraintsCols = new ArrayList<int[]>();
		
		ArrayList<double[]> evenFlowLowerConstraintsRows = new ArrayList<double[]>();
		ArrayList<int[]> evenFlowLowerConstraintsCols = new ArrayList<int[]>();
		
		
		HashMap<Integer, ArrayList<Integer>> periodHarvestCols = new HashMap<Integer,ArrayList<Integer>>();
		HashMap<Integer, ArrayList<Double>> periodHarvestRows = new HashMap<Integer,ArrayList<Double>>();
		
		//Fill in the period harvesting arrays
		for(int tp = 0; tp < ca.landscape.numTimePeriods; tp ++) {
			periodHarvestCols.put(tp, new ArrayList<Integer>());
			periodHarvestRows.put(tp, new ArrayList<Double>());
		}
		
		
		int col = 1, ret =0;
		double gs0=0;
		float[] hvol = new float[ca.landscape.numTimePeriods];
		
		// Get the parameters from Cellular Automata Class
		for( int f = 1; f < ca.forestTypeList.size(); f ++) {
			
			double[] areaConstraintRowsVals = new double[ca.forestTypeList.get(f).stateTypes.size()];
			Arrays.fill(areaConstraintRowsVals, 1);
			int[] areaConstraintColsVals = new int[ca.forestTypeList.get(f).stateTypes.size()];
			
			
			for(int s = 0; s < ca.forestTypeList.get(f).stateTypes.size(); s ++) {
				
				areaConstraintColsVals[s] = col;
				objCols.add(col);
				objRows.add(sumVector(ca.forestTypeList.get(f).stateTypes.get(s).get("harvVol")));
				endingGSConstraintRows.add((double) ca.forestTypeList.get(f).stateTypes.get(s).get("gsVol")[ca.landscape.numTimePeriods-1]);
				
				//The number of periods per state
				if(s > 0) { // the state has to have harvesting
					hvol = ca.forestTypeList.get(f).stateTypes.get(s).get("harvVol");
					for(int p = 0; p < hvol.length; p ++) {
						if(hvol[p]> 0) {
							periodHarvestCols.get(p).add(col);
							periodHarvestRows.get(p).add((double) hvol[p]);
						}	
					}
				}	
				col ++;
			}
			
			gs0 += (double) ca.forestTypeList.get(f).stateTypes.get(0).get("gsVol")[0]*ca.forestTypeList.get(f).area; //initial growing stock
			
			//Add Area constraints
			areaConstraintsRows.add(areaConstraintRowsVals);
			areaConstraintsCols.add(areaConstraintColsVals);
			areaConstraintsValue.add((double) ca.forestTypeList.get(f).area);
		}
		
		// Build the Model I Linear Program//
		try {
			
			/*Convert to Array for lpSolve */
			double[] endingGSRows = endingGSConstraintRows.stream().mapToDouble(i -> i).toArray();
			
			double[] objFncRows = objRows.stream().mapToDouble(i -> i).toArray();
			int[] objFncCols = objCols.stream().mapToInt(i -> i).toArray();
			
			/*Build the lp*/
			LpSolve m1 = LpSolve.makeLp(0, objCols.size());
			m1.setObjFnex(objCols.size(), objFncRows, objFncCols); // set the objective function
			
			m1.setAddRowmode(true);  /* makes building the model faster if it is done rows by row */
			
			for(int ac =0; ac < areaConstraintsValue.size(); ac ++) { //set the area constraints
				m1.addConstraintex(areaConstraintsCols.get(ac).length, areaConstraintsRows.get(ac), areaConstraintsCols.get(ac), LpSolve.EQ, areaConstraintsValue.get(ac));
			}
			
			for(int ef =0; ef < ca.landscape.numTimePeriods -1; ef ++) { //set the evenflow constraints
				m1.addConstraintex(evenFlowLowerConstraintsCols.get(ef).length, evenFlowLowerConstraintsRows.get(ef), evenFlowLowerConstraintsCols.get(ef), LpSolve.LE, 0);
			}
			
			m1.addConstraintex(objCols.size(), endingGSRows, objFncCols, LpSolve.GE, gs0*percentInitalGS); // set the ending growing stock constraint
			
			m1.setAddRowmode(false);
			 
		    m1.setMaxim(); // set obj to maximize
		    
		    ret = m1.solve(); // solve the problem
	        if(ret == LpSolve.OPTIMAL)
	            ret = 0;
	          else
	            ret = 5;
	        if(ret == 0) {// print solution
	        	System.out.println("Solved. Value of objective function: " + m1.getObjective());
	        	double[] var = m1.getPtrVariables();
	        	for (int i = 0; i < var.length; i++) {
	        		System.out.println("Value of var[" + i + "] = " + var[i]);
	        	}
	        }else {
	        	System.out.println("Infeasible. Value of objective function:" + m1.getObjective());
	        }
		 
		    // delete the problem and free memory
		    m1.deleteLp();
		     
		} catch (LpSolveException e) {
		       e.printStackTrace();
		 }
		
		
	}

	private double sumVector(float[] vector) {
		float outVector = 0;
		for(int i =0; i < vector.length; i++) {
			outVector += vector[i];
		}
		return (double) outVector;
	}

}


