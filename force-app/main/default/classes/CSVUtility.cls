public with sharing class CSVUtility {
    public static void CreateCSV(string objName, set<string> flds) {
		CreateCSV(objName, flds, null);
	}

	public static void CreateCSV(string objName, set<string> flds, string whereFilter) {
		// Build query string
		String queryString = 'SELECT ';
		for(String fld : flds){
			queryString += fld;
			queryString += ', ';
		}
		queryString = queryString.removeEnd(', ');
		queryString += ' FROM ';
		queryString += objName;
		if(!String.isBlank(whereFilter)){
			queryString += ' WHERE ';
			queryString += whereFilter;
		}

		// Loop through query results and build csv
		Csv queryToCsv = new Csv();
		Blob csv = queryToCsv.Generate(Database.query(queryString), objName, flds);
		List<Folder> folders = [SELECT Id FROM Folder WHERE Name = 'CSI:  Record Backups'];
		Document doc = new Document(
			Body = csv,
			ContentType = 'text/csv',
			FolderId = folders[0].Id,
			IsPublic = FALSE,
			Name = System.now().format() + objName,
			Type = 'csv'
		);

		insert doc;
	}

	// Create csv file
	public class Csv {
	    public Blob Generate(List<SObject> sobjects, String objName, Set<String> fields) {
	    	// Get fields to for columns
	    	Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
	    	Schema.SObjectType sobjType = gd.get(objName);
			Schema.DescribeSObjectResult theObject = sobjType.getDescribe();
			Map<String, Schema.SObjectField> fieldMap = theObject.fields.getMap();

			// Create column headers
	    	List<String> headerFields = new List<String>();
	    	for(String fld : fields)
	    		headerFields.add(format(fld));
	    		
	        String body = line(headerFields);
	        
	        // create row from record and field names
	        for(SObject sobj : sobjects) {
	        	System.debug(LoggingLevel.ERROR, sobj);
	        	List<String> row = new List<String>();
		        for (String fld : fields) {
		        	// format data by type
	                Schema.SObjectField field = fieldMap.get(fld);
					Schema.DisplayType FldType = field.getDescribe().getType();
	                
		        	if(FldType.name() == 'BOOLEAN')
	            	    row.add(Format( (Boolean) sobj.get(fld) ));
	            	else if(FldType.name() == 'DATE')
	            	    row.add(Format( (Date) sobj.get(fld) ));
	            	else if(FldType.name() == 'DATETIME')
	            	    row.add(Format( (Datetime) sobj.get(fld) ));
	            	else if(FldType.name() == 'PERCENT' || FldType.name() == 'CURRENCY' || FldType.name() == 'DOUBLE')
	            	    row.add(Format( (Decimal) sobj.get(fld) ));
	                else if(FldType.name() == 'ADDRESS') {
	                    List<String> addrFields = new List<String>();

	                    Address addr = (Address) sobj.get(fld);
	                    addrFields.add(addr.Street);
	                    addrFields.add(addr.City);
	                    addrFields.add(addr.State);
	                    addrFields.add(addr.PostalCode);
	                    addrFields.add(addr.CountryCode);

	                    String addString = line(addrFields);
	                    row.add(Format( addString ));
	                }
	            	else
	            	    row.add(Format( (String) sobj.get(fld) ));
		        }
		        body += line(row);
		    }        
		    System.debug(LoggingLevel.ERROR, body);
	        return Blob.valueOf(body);
	    }

	    private String Line(List<String> cells) {
	        return String.join(cells, ',') + '\n';
	    }
	    private String Format(Date d)    {
	        return d != null ? '"' + d.format().escapeCsv() + '"' : '""';
	    }
	    private String Format(Datetime d)    {
	        return d != null ? '"' + d.format().escapeCsv() + '"' : '""';
	    }
	    private String Format(String s) {
	        return s != null ? '"' + s.escapeCsv() + '"' : '""';
	    }
	    private String Format(Decimal d, Integer scale) {
	        return d != null ? String.valueOf(d.setScale(scale)) : '';
	    }
	    private String Format(Decimal d) {
	        return Format(d, 2);
	    }
	    private String Format(Boolean input) {
	    	return (input == null) ? '' : '\'' + String.valueOf(input) + '\'';
		}

	}
}