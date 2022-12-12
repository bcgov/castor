package q3;

import lpsolve.LpSolve;
import lpsolve.LpSolveException;

public class Lp_AllocationModel {

	public Lp_AllocationModel(){

	}

	public int execute() throws LpSolveException {
        LpSolve lp;
        int Ncol, j, ret = 0;

        /* We will build the model row by row
           So we start with creating a model with 0 rows and 2 columns */
        Ncol = 6; /* there are 6 variables in the model */

        /* create space large enough for one row */
        int[] colno = new int[Ncol];
        double[] row = new double[Ncol];

        lp = LpSolve.makeLp(0, Ncol);
        if(lp.getLp() == 0)
          ret = 1; /* couldn't construct a new model... */

        if(ret == 0) {
          /* let us name our variables. Not required, but can be useful for debugging */
          lp.setColName(1, "x11");
          lp.setColName(2, "x12");
          lp.setColName(3, "x13");
          lp.setColName(4, "x21");
          lp.setColName(5, "x22");
          lp.setColName(6, "x23");

          lp.setAddRowmode(true);  /* makes building the model faster if it is done rows by row */

          /* construct first row (1 x11 + 1 x12 + 1 x13 = 120) */
          j = 0;

          colno[j] = 1; /* first column */
          row[j++] = 1;

          colno[j] = 2; /* second column */
          row[j++] = 1;

          colno[j] = 3; /* third column */
          row[j++] = 1;

         // colno[j] = 4; /* fourth column */
         // row[j++] = 0;

         // colno[j] = 5; /* fifth column */
         // row[j++] = 0;

         // colno[j] = 6; /* sixth column */
         // row[j++] = 0;

          /* add the row to lpsolve */
          lp.addConstraintex(j, row, colno, LpSolve.EQ, 120);
        }

        if(ret == 0) {
          /* construct second row (1 x11 + 1 x12 + 1 x13 = 180) */
          j = 0;

          colno[j] = 1; /* first column */
          row[j++] = 0;

          colno[j] = 2; /* second column */
          row[j++] = 0;

          colno[j] = 3; /* third column */
          row[j++] = 0;

          colno[j] = 4; /* fourth column */
          row[j++] = 1;

          colno[j] = 5; /* fifth column */
          row[j++] = 1;

          colno[j] = 6; /* sixth column */
          row[j++] = 1;

          /* add the row to lpsolve */
          lp.addConstraintex(j, row, colno, LpSolve.EQ, 180);
        }

        if(ret == 0) {
          /* construct third row (x11 + x21 = 100) */
          j = 0;

          colno[j] = 1; /* first column */
          row[j++] = 1;

          colno[j] = 2; /* second column */
          row[j++] = 0;

          colno[j] = 3; /* third column */
          row[j++] = 0;

          colno[j] = 4; /* fourth column */
          row[j++] = 1;

          colno[j] = 5; /* fifth column */
          row[j++] = 0;

          colno[j] = 6; /* sixth column */
          row[j++] = 0;

          /* add the row to lpsolve */
          lp.addConstraintex(j, row, colno, LpSolve.EQ, 100);
        }

        if(ret == 0) {
            /* construct fourth row (x12 + x22 = 100) */
            j = 0;

            colno[j] = 1; /* first column */
            row[j++] = 0;

            colno[j] = 2; /* second column */
            row[j++] = 1;

            colno[j] = 3; /* third column */
            row[j++] = 0;

            colno[j] = 4; /* fourth column */
            row[j++] = 0;

            colno[j] = 5; /* fifth column */
            row[j++] = 1;

            colno[j] = 6; /* sixth column */
            row[j++] = 0;

            /* add the row to lpsolve */
            lp.addConstraintex(j, row, colno, LpSolve.EQ, 100);
          }

        if(ret == 0) {
            /* construct fifth row (x13 + x23 = 100) */
            j = 0;

            colno[j] = 1; /* first column */
            row[j++] = 0;

            colno[j] = 2; /* second column */
            row[j++] = 0;

            colno[j] = 3; /* third column */
            row[j++] = 1;

            colno[j] = 4; /* fourth column */
            row[j++] = 0;

            colno[j] = 5; /* fifth column */
            row[j++] = 0;

            colno[j] = 6; /* sixth column */
            row[j++] = 1;

            /* add the row to lpsolve */
            lp.addConstraintex(j, row, colno, LpSolve.EQ, 100);
          }

        if(ret == 0) {
          lp.setAddRowmode(false); /* rowmode should be turned off again when done building the model */

          /* set the objective function (143 x + 60 y) */
          j = 0;

          colno[j] = 1; /* first column */
          row[j++] = 16;

          colno[j] = 2; /* second column */
          row[j++] = 23;

          colno[j] = 3; /* third column */
          row[j++] = 33;

          colno[j] = 4; /* fourth column */
          row[j++] = 24;

          colno[j] = 5; /* fifth column */
          row[j++] = 32;

          colno[j] = 6; /* sixth column */
          row[j++] = 45;

          System.out.println(j);
          /* set the objective in lpsolve */
          lp.setObjFnex(j, row, colno);
        }

        if(ret == 0) {
          /* set the object direction to maximize */
          lp.setMaxim();

          /* just out of curiousity, now generate the model in lp format in file model.lp */
          lp.writeLp("first_model_EvenAged.lp");

          /* I only want to see important messages on screen while solving */
          lp.setVerbose(LpSolve.IMPORTANT);

          /* Now let lpsolve calculate a solution */
          ret = lp.solve();
          if(ret == LpSolve.OPTIMAL)
            ret = 0;
          else
            ret = 5;
        }

        if(ret == 0) {
          /* a solution is calculated, now lets get some results */

          /* objective value */
          System.out.println("Objective value: " + lp.getObjective());
          System.out.println("Dual value: " + lp.getVarDualresult(0));
          System.out.println("print duals: " );lp.printDuals();

          /* variable values */
          lp.getVariables(row);
          for(j = 0; j < Ncol; j++)
            System.out.println(lp.getColName(j + 1) + ": " + row[j]);

           lp.printTableau();
           lp.printDuals();
           lp.printLp();
          
          /* we are done now */
        }
        
        lp.printSolution(0);
        	
        /* clean up such that all used memory by lpsolve is freed */
        if(lp.getLp() != 0)
          lp.deleteLp();

        return(ret);
      }

}
