package coe_cellular_automata;

import java.util.ArrayList;


public class Cells {
	int pixelid, state, age, foresttype, manage_type; 
	ArrayList<Integer> adjCellsList ;
	ArrayList<Integer> landCoverList = new ArrayList<Integer>();
	
	public Cells (int pixelid, int age, int foresttype, int manage_type){
		this.pixelid = pixelid;
		this.age = age;
		this.foresttype = foresttype;
		this.state = 0;
		this.manage_type = manage_type;
	}
	
	public void setState (int state) {
		this.state = state;
	}

	public void setNeighbourhood(ArrayList<Integer> adjList) {
	    this.adjCellsList = adjList;
	}

	public void setLandCoverConstraint(int int1) {
		this.landCoverList.add(int1);
		
	}
}
