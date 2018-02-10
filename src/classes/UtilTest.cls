@isTest
public class UtilTest {

	@isTest
    public static void dynamicUpsertTest() {
        String objType = 'Contact';

        // adding an initial contact to check the update function
        Contact ct0 = new Contact(LastName = 'TestName0', BookingBugId__c = 100);
        insert ct0;

        List<SObject> genericSObjects = new List<SObject>();
        Contact ct1 = new Contact(LastName = 'TestName100', BookingBugId__c = 100);
        Contact ct2 = new Contact(LastName = 'TestName200', BookingBugId__c = 200);
        genericSObjects.Add(ct1);
        genericSObjects.Add(ct2);

        Set<Integer> ids = new Set<Integer>();
        ids.Add(Integer.valueOf(ct1.BookingBugId__c));
        ids.Add(Integer.valueOf(ct2.BookingBugId__c));

        Util.dynamicUpsert(genericSObjects, objType);

        List<Contact> ctList = [SELECT Id, BookingBugId__c, LastName FROM Contact WHERE BookingBugId__c IN :ids];
        System.assertEquals(2, ctList.size());  // should be only 2 since one Contact has been updated
        if (ctList[0].BookingBugId__c == 100) {
            System.assertEquals('TestName100', ctList[0].LastName);
            System.assertEquals('TestName200', ctList[1].LastName);
        }
        else {
            System.assertEquals('TestName200', ctList[0].LastName);
            System.assertEquals('TestName100', ctList[1].LastName);
        }
    }

    @isTest
    public static void makeDMLOperationTest() {
        //
    }

    // mark method in Util as @TestVisible
    @isTest
    public static void getFieldDetailsTest() {
        // 1 - field not encrypted
        Schema.DescribeFieldResult fieldResult = Util.getFieldDetails('Contact', 'LastName');
        System.assert(fieldResult.filterable);
        
        // 2 - encrypted field
        fieldResult = Util.getFieldDetails('Contact', 'enc__c');
        System.assert(!fieldResult.filterable);
    }
    
    @isTest
    public static void filterUpdateOnlyTest() {
        Contact ct1 = new Contact(LastName = 'FirstContact');
        insert ct1;

        Contact ct2 = new Contact(LastName = 'SecondContact');
        List<Contact> ctList = new List<Contact>();
        ctList.Add(ct1);
        ctList.Add(ct2);
        upsert ctList;

        Account ac1 = new Account(Name = 'FirstAccount');
        insert ac1;

        Account ac2 = new Account(Name = 'SecondAccount');
        List<Account> acList = new List<Account>();
        acList.Add(ac1);
        acList.Add(ac2);
        upsert acList;

        //List<Booking_Bug_Mapping__mdt> ctMapping = [SELECT Id, Update_Only__c FROM Booking_Bug_Mapping__mdt LIMIT 100];
        //system.debug('*** mappings: ' + ctMapping);

        Map<String, List<SObject>> newObjects = new Map<String, List<SObject>>();
        newObjects.put('Contact', ctList);
        newObjects.put('Account', acList);
        List<SObject> objectsToUpdate = Util.filterUpdateOnly(newObjects);
        system.assertEquals(0, objectsToUpdate.size());
    }

	@isTest
    public static void stringToDateTest() {
        // 1 - date is null
        string dateStr;
        system.assertEquals(null, Util.stringToDate(dateStr));
        
        // 2 - EU-standard 24h format, including seconds
        dateStr = '2011/10/10 21:46:05';
        DateTime dte = DateTime.newInstance(2011, 10, 10, 21, 46, 0);
        dte = dte.addSeconds(5);
        DateTime dta = Util.stringToDate(dateStr);
        system.assertEquals(dte, dta);
        //system.debug('dte = ' + dte + ', dta = '+ dta);
    }

    // fix the method in the Util class!
    // won't work?!? when using encrypted fields
    // must test on Org with Shield Platform Encryption
    @isTest
    public static void findRecordsByUniqueFieldTest() {
        Contact[] cts = new Contact[2];
        cts[0] = new Contact(LastName = 'TestContactName1');
        cts[1] = new Contact(LastName = 'TestContactName2');
        insert cts;
        
        Map<String, Schema.SObjectType>     globalDescribe          = Schema.getGlobalDescribe(); 
		Schema.SObjectType                  objectType              = globalDescribe.get('contact');
		Schema.DescribeSObjectResult        objectDescribeResult    = objectType.getDescribe();

		Map<String, Schema.SObjectField>    objectFieldMap          = objectDescribeResult.fields.getMap();
		Schema.SObjectField                 objectField             = objectFieldMap.get('enc__c');

		//system.debug('*** ' + objectFieldMap.get('enc__c').getDescribe());

		String searchQuery = 'TestContactName';
		Set<String> dataset = new Set<String>();
		dataset.Add(searchQuery);

        List<SObject> foundObject = Util.findRecordsByUniqueField('contact', dataset, objectField.getDescribe());
        //System.debug('*** recs: ' + recs);
        
        ////String qryHolder = 'FIND \'' + searchQuery + '\' IN ALL FIELDS Returning Contact(id, LastName, enc__c)';
		//String qryHolder = 'FIND {TestParola2} IN ALL FIELDS Returning Contact(id, LastName, enc__c)';
        //    List<List<SObject>> foundObjects = Search.query(qryHolder);
		//System.debug('*** recs: ' + foundObjects);
    }

    @isTest
    public static void extractUniqueFieldValueTest() {
        // 1 - adding a few objects with the same value on a specified field
        String sameValue = 'TestName';
        Lead l = new Lead(LastName = sameValue, Company = 'ACompany', Status = 'Open - Not Contacted');
        Contact c1 = new Contact(FirstName = 'Contact1', LastName = sameValue);
        Contact c2 = new Contact(FirstName = 'Contact2', LastName = sameValue);
        List<SObject> objectList = new List<SObject>();
        objectList.Add(l);
        objectList.Add(c1);
        objectList.Add(c2);

        Set<String> uniq = Util.extractUniqueFieldValue(objectList, 'LastName');
        system.assertEquals(1, uniq.size());

        // 2 - objects with different values
        Lead l2 = new Lead(LastName = sameValue, Company = 'ACompany', Status = 'Open - Not Contacted');
        Contact ct = new Contact(FirstName = 'Contact', LastName = sameValue + '2');
        List<SObject> objectListDifferent = new List<SObject>();
        objectListDifferent.Add(l2);
        objectListDifferent.Add(ct);
        
        uniq = Util.extractUniqueFieldValue(objectListDifferent, 'LastName');
        system.assertEquals(2, uniq.size());
	}

	public static void bbFieldValueMapTest() {

    }

    public static void aMethod(SObject othis) {
        String CurrentClassName = String.valueOf(othis).substring(0,String.valueOf(othis).indexOf(':'));
        system.debug('*** class: ' + CurrentClassName);
        system.debug('*** method: ' + String.valueOf(othis));
    }
}