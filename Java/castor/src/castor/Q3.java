package castor;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.stream.Stream;

import lpsolve.LpSolve;
import lpsolve.LpSolveException;

//import org.gnu.glpk.GLPK;
//import org.gnu.glpk.glp_prob;
//import org.gnu.glpk.GlpkException;
//import org.gnu.glpk.GLPKConstants;

public class Q3 {
	//glp_prob lp;
	
	double evenFlowDeviation = 0.05;
	double percentInitalGS = 0.8;
	double maxHarvestAreaBudget = 0.02;
	boolean evenFlow = true;
	boolean endingInventory= true;
	boolean harvestAreaBudget= true;
	
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
		
		ArrayList<Integer> forestType = new ArrayList<Integer>();
		
		HashMap<Integer, ArrayList<Integer>> periodHarvestCols = new HashMap<Integer,ArrayList<Integer>>();
		HashMap<Integer, ArrayList<Double>> periodHarvestRows = new HashMap<Integer,ArrayList<Double>>();
		
		//Fill in the period harvesting arrays
		for(int tp = 0; tp < ca.landscape.numTimePeriods; tp ++) {
			periodHarvestCols.put(tp, new ArrayList<Integer>());
			periodHarvestRows.put(tp, new ArrayList<Double>());
		}
		
		
		int col = 1, ret =0, forestTypes = 0;
		double gs0=0, tarea =0;
		float[] hvol = new float[ca.landscape.numTimePeriods];
		
		System.out.println("Building Model I lp");
		// Get the parameters from Cellular Automata Class
		for( int f = 1; f < ca.forestTypeList.size(); f ++) { //the 0 forestType is null
			
			
			if(ca.forestTypeList.get(f).manage_type <= 0) { //remove non timber harvesting areas
				forestType.add(null);
				continue;
			}
			
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
			
			forestTypes += 1;
			forestType.add(forestTypes);
			gs0 += (double) ca.forestTypeList.get(f).stateTypes.get(0).get("gsVol")[0]*ca.forestTypeList.get(f).area; //initial growing stock
			
			//Add Area constraints
			areaConstraintsRows.add(areaConstraintRowsVals);
			areaConstraintsCols.add(areaConstraintColsVals);
			areaConstraintsValue.add((double) ca.forestTypeList.get(f).area);
			
			tarea += ca.forestTypeList.get(f).area;
		}
		
		// Build the Model I Linear Program//
		try {
			
			/*Convert to Array for lpSolve */
			double[] endingGSRows = endingGSConstraintRows.stream().mapToDouble(i -> i).toArray();
			
			double[] objFncRows = objRows.stream().mapToDouble(i -> i).toArray();
			int[] objFncCols = objCols.stream().mapToInt(i -> i).toArray();
			
			/*Build the lp*/
			//lp = GLPK.glp_create_prob();
			//GLPK.glp_set_prob_name(lp, "Model I: timber supply");
			//GLPK.glp_add_cols(lp, objCols.size());
			
			LpSolve m1 = LpSolve.makeLp(0, objCols.size());
			m1.setObjFnex(objCols.size(), objFncRows, objFncCols); // set the objective function
			
			m1.setAddRowmode(true);  /* makes building the model faster if it is done rows by row */
			
			//Area Constraints
			for(int ac =0; ac < areaConstraintsValue.size(); ac ++) { //set the area constraints
				m1.addConstraintex(areaConstraintsCols.get(ac).length, areaConstraintsRows.get(ac), areaConstraintsCols.get(ac), LpSolve.EQ, areaConstraintsValue.get(ac));
			}
			
			
			//Even Flow Constraints
			if(evenFlow) {
				for(int ef =0; ef < periodHarvestCols.size()-1; ef ++) { //set the evenflow constraints
					
					//Add the cols from P1 and P2 for the columns
					//Multiply the row vectors by negative 1 or the percent deviation
		
					int fal = periodHarvestCols.get(ef).size();        //determines length of firstArray  
					int sal = periodHarvestCols.get(ef+1).size();   //determines length of secondArray  
					int[] efCols = new int[fal + sal];
					
					System.arraycopy(periodHarvestCols.get(ef).stream().mapToInt(i->i).toArray(), 0, efCols, 0, fal);  
					System.arraycopy(periodHarvestCols.get(ef+1).stream().mapToInt(i->i).toArray(), 0, efCols, fal, sal);  
					//System.out.println(Arrays.toString(result)); 
					
		
					double[] efLowerRows = new double[fal + sal];
					double[] efUpperRows = new double[fal + sal];
					int counter =0;
					for(int r =0 ; r < efLowerRows.length; r ++) {
						if(counter < fal) {
							efLowerRows[r] = (double) periodHarvestRows.get(ef).get(r)*(1-evenFlowDeviation);
						    efUpperRows[r] = (double) periodHarvestRows.get(ef).get(r)*(1+evenFlowDeviation);
						    counter ++;
						}else {
							efLowerRows[r] = (double) periodHarvestRows.get(ef+1).get(r-counter)*-1;
						    efUpperRows[r] = (double) periodHarvestRows.get(ef+1).get(r-counter)*-1;
						}
					}
	
					//System.out.println("Adding P"+ ef+ " and P"+ (ef+1) + " constraint");
					m1.addConstraintex(efCols.length , efLowerRows, efCols, LpSolve.LE, 0);
					m1.addConstraintex(efCols.length , efUpperRows, efCols, LpSolve.GE, 0);
				}
			}
			
			//Ending Inventory Constraint
			if(endingInventory) {
				m1.addConstraintex(objCols.size(), endingGSRows, objFncCols, LpSolve.GE, gs0*percentInitalGS); // set the ending growing stock constraint
			}
			
			if(harvestAreaBudget) {
				
				for(int r =0 ; r < periodHarvestCols.size(); r ++) {
					int[] hab = new int[periodHarvestCols.get(r).size()];		
					double[] harvestAreaRows = new double[hab.length];
					Arrays.fill(harvestAreaRows, 1);
					System.arraycopy(periodHarvestCols.get(r).stream().mapToInt(i->i).toArray(), 0, hab, 0, hab.length); 
					m1.addConstraintex(hab.length, harvestAreaRows, hab, LpSolve.LE, maxHarvestAreaBudget*tarea); // set the ending growing stock constraint
			
				}
			}
			
			m1.setAddRowmode(false);
			 
		    m1.setMaxim(); // set obj to maximize
		    System.out.println("...done");
		    System.out.print("");
		    m1.writeMps("C:/Users/klochhea/castor/R/test.mps");
		    
		    System.out.println("Solving...");
		    
		    ret = m1.solve(); // solve the problem
		    
	        if(ret == LpSolve.OPTIMAL)
	            ret = 0;
	          else
	            ret = 5;
	        if(ret == 0) {// print solution
	        	System.out.println("Solved. Value of objective function: " + m1.getObjective());
	        	//double[] var = m1.getPtrVariables();
	        	//for (int i = 0; i < var.length; i++) {
	        	//	System.out.println("Value of var[" + i + "] = " + var[i]);
	        	//}
	        }else {
	        	System.out.println("Infeasible. Value of objective function:" + m1.getObjective());
	        }
	        
	        
	        double[] dual =new double[forestTypes];
	    	for(int d =0; d < forestTypes; d ++) { //set the area constraints
	    		dual[d] = m1.getVarDualresult(d+1);
	    	}
	    		        
		    // delete the problem and free memory
		    m1.deleteLp();
		    saveResults(dual, forestType);
		    
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
	
	private void saveResults(double dual[], ArrayList<Integer> forestTypeLUT) {
		try { //Get the data from the db
			Connection conn = DriverManager.getConnection("jdbc:sqlite:" + ca.castordb);		
			if (conn != null) {
					
				String insertResults = "Update pixels set dual = ? where pixelid = ?;";
				conn.setAutoCommit(false);
				PreparedStatement pstmt = conn.prepareStatement(insertResults);
				try {
					for(int c = 0; c < ca.cellsList.size(); c++) {
						if(forestTypeLUT.get(ca.cellsList.get(c).foresttype) != null) {
							pstmt.setDouble(1, dual[forestTypeLUT.get(ca.cellsList.get(c).foresttype)]);
							pstmt.setInt(2, ca.cellsList.get(c).pixelid);
							pstmt.executeUpdate();
						}
								        	
					}
				}finally {
					System.out.println("...done");
					//pstmt.executeBatch();
					pstmt.close();
					conn.commit();
					//conn.close();
				}  
				
				
			}
			
		} catch (SQLException e) {
		        System.out.println(e.getMessage());
		       }
	}
	
 

}


