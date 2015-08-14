import java.io.FileNotFoundException;
import java.io.FileReader;
import java.util.Scanner;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Multiply {
	private float[] matrixA;
	private float[] matrixB;
	private float[] result;
	private int colA, rowA, colB, rowB, nCore, lin, col;
	
	private MultiAccel multi;

	Multiply(String arq1, String arq2){
		long timeStartR = System.currentTimeMillis(); 
		matrixA = readFile(arq1);
		rowA = lin; colA =col;
		
		matrixB = readFile(arq2);
		rowB = lin; colB = col;
		
		nCore = 4;// Runtime.getRuntime().availableProcessors();
		multi = new MultiAccel(nCore);
		multi.setData(matrixA, matrixB,rowA, colB);
	
		
		long timeEndR = System.currentTimeMillis();
		long timeStartM = System.currentTimeMillis();  
		calculating();
			
		long timeEndM = System.currentTimeMillis();
		/*Calculating times*/
		long dif = (timeEndM - timeStartM);  
		long difR = (timeEndR-timeStartR);
		long difT = (timeEndM - timeStartR);
		System.out.println(
		  String.format("%02d:%02d--%02d\t%02d:%02d--%02d\t%02d:%02d--%02d", 
		  dif/1000, dif%1000,dif,difR/1000,difR%1000,difR,difT/1000,difT%1000,difT));		
	}
	
	float[] readFile(String arq){
		Scanner in;
		try {
			in = new Scanner(new FileReader(arq+".txt"));
			lin = in.nextInt();
			col = in.nextInt();
			
			float matrix[] = new float[lin*col];
			for( int i = 0 ; i < lin*col; i++ ){
			   matrix[i] = Float.parseFloat(in.next());
			}
			return matrix;
		} catch (FileNotFoundException e) {
			e.printStackTrace();
			return null;
		}		
	}

	public void calculating(){
		MyThread poolThread[] = new MyThread[nCore];
		ExecutorService executor = Executors.newFixedThreadPool(nCore);
    
		for(int i=0;i<nCore;i++){
			poolThread[i] = new MyThread(i);
			executor.execute(poolThread[i]);
		}		
		executor.shutdown();
		while (!executor.isTerminated()){
		}	
		result = multi.getResult();
	}

	public void printResult(int row){
		for(int i=0;i<row*colB;i++){
		  System.out.print(" "+result[i]);
		}
	}

	public static void main(String args[]){		
		Multiply mult = new Multiply(args[0],args[1]);
		mult.printResult(32);
	}
	
	class MyThread implements Runnable{
		int index;
		MultiAccel.Calc unit;
		
		MyThread(int index){
			this.unit = multi.new Calc(index);
			this.index = index;
		}
		public void run(){
			this.unit.multiply();
		}
	}
}
