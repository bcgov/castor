package q3;
import lpsolve.LpSolveException;

public class Main {
	public static String fileName = "D:/";
	public static void main(String[] args) {
		try {
			new Lp_AllocationModel().execute();
		}
		catch (LpSolveException e) {
			e.printStackTrace();
		}
	}

}

