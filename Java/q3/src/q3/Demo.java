package q3;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

import lpsolve.*;


public class Demo {
	public Demo() {
	}

	  public static void main(String[] args) {
		    try {
		      // Create a problem with 4 variables and 0 constraints
		      LpSolve solver = LpSolve.makeLp(0, 12);

		      // add constraints

		      //AREA
		      solver.strAddConstraint("1 1 1 1 1 1 0 0 0 0 0 0", LpSolve.EQ, 10);
		      solver.strAddConstraint("0 0 0 0 0 0 1 1 1 1 1 1", LpSolve.EQ, 25);

		      //EVEN-FLOW

		      //Lower Bound
		      //80%(P1) - P2 harvest < = 0
		      solver.strAddConstraint("0 232 232 -350 0 0 0 508 508 -760 0 0", LpSolve.LE, 0);
		      //80%P2-P3 < = 0
		      solver.strAddConstraint("0 0 0 280 -425 0 0 0 0 608 -900 0", LpSolve.LE, 0);
		      //80%P3-P4 < = 0
		      solver.strAddConstraint("0 0 -240 0 340 -520 0 0 -240 0 720 -1050", LpSolve.LE, 0);

		      //Upper Bound
		      //120%(P1) - P2 harvest < = 0
		      solver.strAddConstraint("0 348 348 -350 0 0 0 762 762 -760 0 0", LpSolve.GE, 0);
		      //120%P2-P3 < = 0
		      solver.strAddConstraint("0 0 0 420 -425 0 0 0 0 912 -900 0", LpSolve.GE, 0);
		      //120%P3-P4 < = 0
		      solver.strAddConstraint("0 0 -240 0 510 -520 0 0 -240 0 1080 -1050", LpSolve.GE, 0);

		      //ENDING INVENTORY

		      // set objective function
		      solver.strSetObjFn("5006 3706 3616 3808 3756 4315 15752 17199 17109 18103 16976 17607");
		      solver.setMaxim();
		      // solve the problem
		      solver.solve();

		      // print solution
		      System.out.println("Value of objective function: " + solver.getObjective());
		      double[] var = solver.getPtrVariables();
		      for (int i = 0; i < var.length; i++) {
		        System.out.println("Value of var[" + i + "] = " + var[i]);
		      }

		      // delete the problem and free memory
		      solver.deleteLp();
		    }
		    catch (LpSolveException e) {
		       e.printStackTrace();
		    }
		  }

}

