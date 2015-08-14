import java.io.FileNotFoundException;
import java.io.FileReader;
import java.util.Scanner;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Multiply {
	private float matrixA[][];
	private float matrixB[][];
	private float result[][];
	private int colA, rowA, colB, rowB, nCore, block;

	Multiply(String arq1, String arq2){
		long timeStartR = System.currentTimeMillis(); 
		matrixA = readFile(arq1);
		rowA = matrixA.length; colA = matrixA[0].length;
		
		matrixB = readFile(arq2);
		rowB = matrixB.length; colB = matrixB[0].length;
		
		nCore = Runtime.getRuntime().availableProcessors();
		this.block = rowA/nCore;
		
		result = new float[rowA][colB];
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
	
	float[][] readFile(String arq){
		Scanner in;
		try {
			in = new Scanner(new FileReader(arq+".txt"));
			int lin = in.nextInt();
			int col = in.nextInt();
			float matrix[][] = new float[lin][col];
			for( int i = 0 ; i < lin ; i++ ){
				for(int j=0; j<col;j++){
					matrix[i][j] = Float.parseFloat(in.next());
				}
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
	}

	public void getResult(){
		for(int i=0;i<rowA;i++){
			for(int j=0;j<colB;j++){
				System.out.print(" "+result[i][j]);
			}
			System.out.println();
		}
	}

	public static void main(String args[]){		
		Multiply mult = new Multiply(args[0],args[1]);
		//mult.getResult();
	}
	
	class MyThread implements Runnable{
		int index;
		MyThread(int index){
			this.index = index;
		}
		public void run(){
			for (int h=index*block; h<(index*block)+block; h++){
				for(int i=0; i<colB; i++){
					for(int j=0; j<colA; j++)
						result[h][i] += matrixA[h][j] * matrixB[j][i];
				}
			}
		}
	}
}
