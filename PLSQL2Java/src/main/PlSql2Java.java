package main;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;

import parser.PlSql_Parser;

public class PlSql2Java {
	public static void main(String args[]) throws Throwable {
		// Si el número de argumentos es incorrecto, se informa al usuario.
		if(args.length != 1) {
			System.out.println("PlSql2Java\r\n");
			System.out.println("Usage is:\r\n");
			System.out.println("         java PlSql2Java filePath");
			return;
		}else {
			try {
				System.out.println("PlSql2Java");
				System.out.println("Reading file... " + args[0] + "\r\n");
				// Leemos de los parámetros el archivo de entrada.
				File inputFile = new File(args[0]);
				// Extraemos el nombre de la clase a generar.
				String className = inputFile.getName().substring(0, 1).toUpperCase() 
								 + inputFile.getName().substring(1).replaceFirst(".pls", "");
				// Creamos los argumentos para el parser.
				String[] parserArgs = new String[2];
				parserArgs[0] = className;
				parserArgs[1] = inputFile.getAbsolutePath();
				// Realizamos el análisis léxico y gramatical del archivo de entrada.
				PlSql_Parser.main(parserArgs);
				// Extraemos el código generado.
				String code = PlSql_Parser.getCode();
				// Creamos el archivo de salida.
				// 			"\"" + inputFile.getAbsolutePath().substring(0, )(".pls", ".java") + "\""
				Path inputFilePath = inputFile.toPath();
			    File outputFile = new File(inputFile.getParent() + System.getProperty("file.separator") +
			    							className + ".java");
				System.out.println(outputFile.getAbsolutePath());
				outputFile.createNewFile();
				// Escribimos el código generado en el archivo de salida.
				FileWriter myWriter = new FileWriter(outputFile);
			    myWriter.write(code);
			    myWriter.close();
				// Informamos al usuario del éxico en la ejecución.
				System.out.println("Successfully generated translated program in:");
				System.out.println(outputFile.getAbsolutePath());
			}catch(Exception e) {
				System.out.println("Error while translating...");
				e.printStackTrace();
			}
		}
	}
}
