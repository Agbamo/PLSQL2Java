package aspects;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.After;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.annotation.Pointcut;

import main.Dictionary;
import parser.PlSql_Parser;

@Aspect
public aspect JavaTranslationAspect {

	List<String> code = new ArrayList<String>();
	List<Integer> forIndexes = new ArrayList<Integer>();
	boolean isInsideAssignment = false;

	// Antes de la ejecuci�n de CompilationUnit, escribimos todo
	// el c�digo anterior al bloque de la clase autogenerada.
	@Before("(execution(* parser.PlSql_Parser.CompilationUnit()))")
	public void beforeCompilationUnit(JoinPoint jp) {
		String newCode = "public class " + PlSql_Parser.getClassName() + " {" + getIntro(1) 
		+ "public static void main(String args[]){"+ getIntro(1);
		code.add(newCode);
		consolePrint("@Before", "CompilationUnit", print2String(code), newCode);
	}

	// Despu�s de la ejecuci�n de ProcedureReference, tomamos las referencias,
	// las traducimos usando el diccionario y las insertamos en el c�digo.
	@AfterReturning(pointcut="(execution(* PlSql_Parser.ProcedureReference(..)))",returning="name")
	public void afterProcedureReference(String name) {
		if(!name.equals("null") && name != null ) {
			String newCode = Dictionary.ProcedureReference(name);
			code.add(newCode);
			consolePrint("@AfterReturning", "ProcedureReference", print2String(code), newCode);
		}
	}

	// Despu�s de la ejecuci�n de ProcedureReference, abrimos el par�ntesis 
	// que contiene los par�metros.
	@After("(execution(* PlSql_Parser.ProcedureReference(..)))")
	public void afterProcedureReference(JoinPoint jp) {
		String newCode = "(";
		code.add(newCode);
		consolePrint("@After", "ProcedureReference", print2String(code), newCode);
	}

	// Despu�s de la ejecuci�n de Arguments, se traducen los par�metros
	// usando el diccionario y se insertan.
	@AfterReturning(pointcut="(execution(* PlSql_Parser.Arguments(..)))",returning="arguments")
	public void afterArguments(String arguments) {
		String newCode = Dictionary.Arguments(arguments);
		code.add(newCode);
		consolePrint("@AfterReturning", "Arguments", print2String(code), newCode);
	}

	// Despu�s de la ejecuci�n de ProcedureCall, se cierra el par�ntesis 
	// que contiene los argumentos.
	@After("(execution(* PlSql_Parser.ProcedureCall(..)))")
	public void afterProcedureCall(JoinPoint jp) {
		String newCode = ");" + getIntro(1);
		code.add(newCode);
		consolePrint("@After", "ProcedureCall", print2String(code), newCode);
	}

	// Despu�s de la ejecuci�n de CompilationUnit, cerramos la 
	// llave del bloque de la clase autogenerada.
	@After("(execution(* PlSql_Parser.CompilationUnit(..)))")
	public void afterCompilationUnit(JoinPoint jp) {
		String newCode = getIntro(1) + "}" + getIntro(1) + " }";
		code.add(newCode);
		consolePrint("@After", "CompilationUnit", print2String(code), newCode);
		PlSql_Parser.setCode(print2String(code));
	}

	// Antes de la ejecuci�n de NumericForLoop, escribimos el principio del 
	// c�digo del bucle for y almacenamos en la pila forIndexes el �ndice
	// en el que lo hemos insertado en la lista code.
	@Before("(execution(* parser.PlSql_Parser.NumericForLoop()))")
	public void beforeNumericForLoop(JoinPoint jp) {
		String newCode = "IntStream.range(";
		code.add(newCode);
		consolePrint("@Before", "NumericForLoop", print2String(code), newCode);
		forIndexes.add(code.size()-1);
	}

	// Despu�s de la ejecuci�n de NumericForLoop, retiramos del c�digo todo
	// lo que est� por debajo del �ndice del fragmento insertado en el @Before.
	// Despu�s, completamos el c�digo del for y reinsertamos todo lo eliminado 
	// en el paso anterior. Por �ltimo, insertamos la llave de cierre del bucle.
	@AfterReturning(pointcut="(execution(* PlSql_Parser.NumericForLoop(..)))", returning="arguments")
	public void afterNumericForLoop(String[] arguments) {
		int codeIndex = forIndexes.get(forIndexes.size()-1);
		List<String> auxCode = new ArrayList<String>();
		List<String> innerCode = new ArrayList<String>(code.subList(codeIndex+1, code.size()));
		auxCode = code.subList(0, codeIndex+1);
		String newCode = arguments[1] + ", " + arguments[2] + ").forEach(" 
				+ getIntro(1) + arguments[0] + " -> {" + getIntro(1);
		code = auxCode;
		code.add(newCode);
		System.out.println(code.toString());
		addAll(code, innerCode);
		newCode = getIntro(1) + "}";
		code.add(newCode);
		consolePrint("@AfterReturning", "NumericForLoop", print2String(code), newCode);
		forIndexes.remove(forIndexes.size()-1);
	}

	// Despu�s de VariableDeclaration, recogemos los valores necesarios e insertamos la l�nea correspondiente. 
	@AfterReturning(pointcut="(execution(* PlSql_Parser.VariableDeclaration(..)))", returning="arguments")
	public void afterVariableDeclaration(String[] arguments) {
		String dataType = Dictionary.dataType(arguments[1]);
		String newCode = dataType + " " + arguments[0] + " = " + arguments[2] + ";" + getIntro(1);
		code.add(newCode);
		consolePrint("@AfterReturning", "VariableDeclaration", print2String(code), newCode);
	}

	// Antes de AssingmentStatement, se habilitan los advisors de 
	// PlSqlSimpleExpression y PlSqlMultiplicativeExpression.
	@Before("(execution(* parser.PlSql_Parser.AssignmentStatement()))")
	public void beforeAssignmentStatement(JoinPoint jp) {
		isInsideAssignment = true;
	}
	
	// Despu�s de Assingmentstatement, se captura el nombre de la variable que recibe 
	// el resultado y se coloca, seguida de "=", delante de los dos �ltimos token.
	// Por �ltimo, se deshabilitan los advisors de PlSqlSimpleExpression y PlSqlMultiplicativeExpression.
	@AfterReturning(pointcut="(execution(* parser.PlSql_Parser.AssignmentStatement()))", returning="variable")
	public void afterAssignmentStatement(String variable) {
		String temp = code.get(code.size()-1);
		code = new ArrayList<String>(code.subList(0, code.size()-1));
		String newCode = variable + " " + "=" + temp + ";" + getIntro(1);
		code.add(newCode);
		consolePrint("@AfterReturning", "AssignmentStatement", print2String(code), newCode);
		isInsideAssignment = false;
	}

	// Despu�s de PlSqlSimpleExpression se captura el operador de la expresi�n y se coloca entre los operandos.
	@AfterReturning(pointcut="(execution(* PlSql_Parser.PlSqlSimpleExpression(..)))", returning="operation")
	public void afterPlSqlSimpleExpression(String operation) {
		if(isInsideAssignment) {
			List<String> temp = new ArrayList<String>(code.subList(code.size()-2, code.size()));
			code = new ArrayList<String>(code.subList(0, code.size()-2));
			String newCode = temp.get(0) + " " + operation + " " + temp.get(1);
			code.add(newCode);
			consolePrint("@AfterReturning", "PlSqlSimpleExpression", print2String(code), newCode);
		}
	}

	//Despu�s de PlSqlMultiplicativeExpression se captura el operando de la expresi�n.
	@AfterReturning(pointcut="(execution(* PlSql_Parser.PlSqlMultiplicativeExpression(..)))", returning="operator")
	public void afterPlSQLMultiplicativeExpression(String operator) {
		if(isInsideAssignment) {
			String newCode = " " + operator + " ";
			code.add(newCode);
			consolePrint("@AfterReturning", "PlSqlMultiplicativeExpression", print2String(code), newCode);
		}
	}

	///////////////////////// Auxiliary methods /////////////////////////////

	private void consolePrint(String moment, String construct, String oldCode, String newCode) {
		System.out.println(moment + " " + construct + ", inserting: " + getIntro(1) + newCode + getIntro(1));
		System.out.println(oldCode + getIntro(1));
	}

	private String getIntro(int n) {
		String tabs = "";
		for(int i = 0; i<n; i++) {
			tabs += "\r\n";
		}
		return tabs;
	}

	private void addAll(List<String> to, List<String> from) {
		Iterator<String> iterator = from.iterator();
		while(iterator.hasNext()) {
			String item = iterator.next();
			to.add(item);
		}
	}

	private String print2String(List<String> code) {
		String output = "";
		Iterator<String> iterator = code.iterator();
		while(iterator.hasNext()) {
			String item = iterator.next();
			output += item;
		}
		return output;
	}
}