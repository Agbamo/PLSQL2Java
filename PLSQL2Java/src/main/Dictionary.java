package main;

public class Dictionary {

	public static String ProcedureReference(String name) {
		switch (name) {
		case "dbms_output.put_line":
			return "System.out.println";
		default:
			break;
		}
		return name;
	}

	public static String dataType(String name) {
		switch (name) {
		case "NUMBER":
			return "int";
		default:
			break;
		}
		return name;
	}
	
	public static String Arguments(String arguments) {
		return toDoubleQuotes(arguments);
	}
	
	private static String toDoubleQuotes(String st){
		return st.replace('\'', '\"');
	}
}
