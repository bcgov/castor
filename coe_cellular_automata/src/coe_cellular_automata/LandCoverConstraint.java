package coe_cellular_automata;

import java.util.ArrayList;
import java.util.LinkedHashMap;

public class LandCoverConstraint {
	String variable, type;
	float threshold, percentage, t_area, perPHAchieved;
	float[] achievedConstraint; // this id dynamic and is needed to keep track of the constraint
	int delayHarvest, target_cover;
	
	/**Constructor
	 * 
	 */
	LandCoverConstraint(){
	}

	/**Sets the parameters for the LandCoverConstraint object
	 * 
	 * @param variable	stores the variable to be tested
	 * @param threshold	stores the threshold from the variable is to be compared
	 * @param type	stores the mathematical relation of the threshold and variable
	 * @param percentage stores the percentage of the total area from which the mathematical relation holds
	 * @param t_area	the total area
	 * @param numTimePeriods the number of time periods for assessing the constraint
	 */
	public void setLandCoverConstraintParameters(String variable, float threshold, String type, float percentage, float t_area, int numTimePeriods) {
		this.variable = variable;
		this.threshold= threshold;
		this.type = type;
		this.percentage =percentage;
		this.t_area = t_area;
		this.achievedConstraint = new float[numTimePeriods];
		this.target_cover = (int) ((int) t_area*(percentage/100));
	}
	
	public void setAcheivedConstraint (float[] achievedConstraint) {
		this.achievedConstraint = achievedConstraint;
	}
	

}
