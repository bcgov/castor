package castor;

import java.util.ArrayList;
import java.util.HashMap;

public class ForestType {
	
	int id;
	int age;
	int id_yc;
	int id_yc_trans;
	int manage_type;
	float maxMAI =0f;
	double area; // This be a double-- used to be set up as pixels based or count based
	
	ArrayList<HashMap<String, float[]>> stateTypes = new ArrayList<HashMap<String, float[]>>();
	
	/**
	 * Constructor
	 */
	public ForestType() {

	}
	
	public void setForestTypeAttributes(int id, int age, int id_yc, int id_yc_trans, int manage_type, float[] yc, double area) {
		this.id = id;
		this.age = age;
		this.id_yc = id_yc;
		this.id_yc_trans = id_yc_trans;
		this.manage_type = manage_type;	
		this.area = area;
		// Calculate the max mai for the forest type;
		for(int y = 4; y < yc.length; y++) {
			if(maxMAI < yc[y]/(y*10)) {
				maxMAI= yc[y]/(y*10);
			}
		}
		

	}
	
	public void setForestTypeStates(int manageType, ArrayList<float[]> ageTemplate, ArrayList<float[]> harvestTemplate, HashMap<String, float[]> yc,
			HashMap<String, float[]> yc_trans, float minHarvVol) {
		//Age State: already set up need for reporting
		//Harvest Age State: already set up for repoting and links to constraints for BEO, WHA, UWR
		//Growing Stock State : need for reporting
		//Harvest Volume State: need for reporting
		//Ht state: need and links to constraints for VQOs
		//ECA state: links to constraints for watersheds CW, FSW
		//CrownClosure: ? need for fisher constraints
		//Dist:? 
		
		//Add state zero to all - a no harvest state!
		this.stateTypes.add(0, new HashMap<String, float[]>());
		this.stateTypes.get(0).put("age", ageTemplate.get(0)); // int type
		this.stateTypes.get(0).put("harvAge", harvestTemplate.get(0)); // float type
				
		float[] harvVol = new float[harvestTemplate.get(0).length];
		float[] gsVol = new float[ageTemplate.get(0).length];
		float[] ht = new float[ageTemplate.get(0).length];
		//float[] eca = new float[ageTemplate.get(0).length];
		
		int ageLower, ageUpper;
		boolean transitionCurve;
		
		for(int h =0 ; h < ageTemplate.get(0).length; h ++) {
			harvVol[h] =  0f;	//no harvesting in state zero!
			
			ageLower = (int) Math.min(350, Math.floor(ageTemplate.get(0)[h]/10)*10);
			ageUpper = Math.min(350, (int) (Math.round((ageTemplate.get(0)[h]/10) + 0.5)*10));
			
			if(ageUpper == ageLower) {
				gsVol[h] = yc.get("vol")[ageLower/10];
				ht[h] = yc.get("height")[ageLower/10];
				//eca[h] = ht[h];
			}else {
				gsVol[h] = interpFloat(ageTemplate.get(0)[h], ageLower , ageUpper, yc.get("vol")[ageLower/10], yc.get("vol")[ageUpper/10] );
				ht[h] = interpFloat(ageTemplate.get(0)[h], ageLower , ageUpper, yc.get("height")[ageLower/10], yc.get("height")[ageUpper/10] );	
				//eca[h] = ht[h];
			}
		}
				
		this.stateTypes.get(0).put("harvVol", harvVol); 
		this.stateTypes.get(0).put("gsVol", gsVol); 
		this.stateTypes.get(0).put("height", ht); 
		
		
		if(manageType > 0) { // if the management type allows harvesting meaning its > 0;
			int stateCounter =0;
			//Add all states that meet the minimum harvest criteria
			searchStates: for(int s = 1; s < harvestTemplate.size(); s++) {
				float[] harvVol1 = new float[harvestTemplate.get(0).length];
				float[] gsVol1 = new float[harvestTemplate.get(0).length];
				float[] ht1 = new float[harvestTemplate.get(0).length];
				transitionCurve = false;
				
				for(int t =0 ; t < harvestTemplate.get(0).length; t ++) {
					
					ageLower =  (int) Math.min(350,Math.floor(harvestTemplate.get(s)[t]/10)*10);
					ageUpper =  Math.min(350, (int) (Math.round((harvestTemplate.get(s)[t]/10) + 0.5)*10));
					
					if(transitionCurve) {
						harvVol1[t] = interpFloat(harvestTemplate.get(s)[t], ageLower , ageUpper, yc_trans.get("vol")[ageLower/10], yc_trans.get("vol")[ageUpper/10]);
					}else {
						harvVol1[t] = interpFloat(harvestTemplate.get(s)[t], ageLower , ageUpper, yc.get("vol")[ageLower/10], yc.get("vol")[ageUpper/10]);
					}
					
					//Stop scoping this state -- it doesn't meet the minimum harvest volume -- go to the next state
					if(harvVol1[t] > 0 && harvVol1[t] < minHarvVol) {
						continue searchStates;
					} 	
					
					//Get the rest of the yields
					ageLower =  (int) Math.min(350,Math.floor(ageTemplate.get(s)[t]/10)*10);
					ageUpper = Math.min(350, (int) (Math.round((ageTemplate.get(s)[t]/10) + 0.5)*10));
					
					if(transitionCurve) {

						gsVol1[t] = interpFloat(ageTemplate.get(s)[t], ageLower , ageUpper, yc_trans.get("vol")[ageLower/10], yc_trans.get("vol")[ageUpper/10]);						
						ht1[t] = interpFloat(ageTemplate.get(s)[t], ageLower , ageUpper, yc_trans.get("height")[ageLower/10], yc_trans.get("height")[ageUpper/10]);
					}else {
						gsVol1[t] = interpFloat(ageTemplate.get(s)[t], ageLower , ageUpper, yc.get("vol")[ageLower/10], yc.get("vol")[ageUpper/10]);						
						ht1[t] = interpFloat(ageTemplate.get(s)[t], ageLower , ageUpper, yc.get("height")[ageLower/10], yc.get("height")[ageUpper/10]);
					}
					
					if(harvVol1[t] >= minHarvVol) {
						transitionCurve = true;
					}
				}
				
				stateCounter ++;
				
				this.stateTypes.add(stateCounter, new HashMap<String, float[]>());
				this.stateTypes.get(stateCounter).put("age", ageTemplate.get(s)); // int type
				this.stateTypes.get(stateCounter).put("harvAge", harvestTemplate.get(s)); // int type
				this.stateTypes.get(stateCounter).put("harvVol", harvVol1); 
				this.stateTypes.get(stateCounter).put("gsVol", gsVol1); 
				this.stateTypes.get(stateCounter).put("height", ht1); 
				
			}						
		}
	}
	
	//More methods
	public float interpFloat(float f, int ageLower, int ageUpper, float yieldLower, float yieldUpper) {		
		float inpterpValue;
		if(ageUpper == ageLower) {
			inpterpValue = yieldLower;
		} else {
			inpterpValue = ((yieldUpper - yieldLower)/(ageUpper - ageLower))*(f-ageLower) + yieldLower;
		}
		return inpterpValue;
	}
	
}
