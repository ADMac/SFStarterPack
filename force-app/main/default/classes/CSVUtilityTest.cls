public with sharing class CSVUtilityTest {
    public CSVUtilityTest() {

    }
}
@isTest
private class CSVUtilityTest {
	@TestSetup
	static void dataSetup(){
		List<Account> acctList = new List<Account>();

		acctList.add(
			new Account(
				Name = 'Test',
				Type = 'Prospect',
				Phone = '(718) 856-2432',
				Website = 'http://example.com',
				Industry = 'Energy'
			)
		);

		acctList.add(
			new Account(
				Name = 'Burlington',
				Type = 'Prospect',
				Phone = '(718) 693-0676',
				Website = 'http://example.com',
				Industry = 'Banking'
			)
		);

		insert acctList;
	}

	static testmethod void createCSVFromQuery() {
		Map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Account.fields.getMap();
		String whereFilter = 'Name != \'Burlington\'';

		Test.startTest();
		CSVUtility.createCSV('Account', fieldMap.keySet(), whereFilter);
		Test.stopTest();

		Folder backups = [SELECT Id FROM Folder WHERE Name = 'CSI:  Record Backups' LIMIT 1];
		Document csv = [SELECT Name FROM Document WHERE FolderId = :backups.Id];

		System.assert(csv != null);
		System.assert(csv.Name.contains('Account'));
	}

	static testmethod void createCSVFromQueryNoFilter() {
		Map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Account.fields.getMap();

		Test.startTest();
		CSVUtility.createCSV('Account', fieldMap.keySet());
		Test.stopTest();

		Folder backups = [SELECT Id FROM Folder WHERE Name = 'CSI:  Record Backups' LIMIT 1];
		List<Document> csvList = [SELECT Name FROM Document WHERE FolderId = :backups.Id];

		System.assert(!csvList.isEmpty());
		System.assert(csvList[0].Name.contains('Account'));
	}

	static testmethod void generatorTest() {
        Contact[] contacts = new Contact[]{
            new Contact(
                FirstName = 'Jane',
                LastName = 'Doe'
            ),
            new Contact(
                FirstName = 'John',
                LastName = 'Smith',
                Birthdate = Date.newInstance(1985, 2, 3),
                Email = 'abc@def.com',
                Phone = '222 444 55555'
            )
        };
        insert contacts;

        Set<String> fields = new Set<String>{'firstname', 'lastname', 'birthdate', 'email', 'phone'};
        String expected = ''
                + '"firstname","lastname","birthdate","email","phone"\n'
                + '"Jane","Doe","","",""\n'
                + '"John","Smith","2/3/1985","abc@def.com","222 444 55555"\n';
        System.assertEquals(Blob.valueOf(expected), new CSVUtility.Csv().generate(contacts, 'Contact', fields));
    }
}
