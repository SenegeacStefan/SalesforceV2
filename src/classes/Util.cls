public with sharing class Util {

	 private static Database.DMLOptions dmlOptions = new Database.DMLOptions();
	//method to check for duplicates
	
	//Updates or inserts a list of objects based on the uniqueness of the BB ID
	public static void dynamicUpsert(List<Sobject> genericSObjects, String objectType) { 
		system.debug('==>DynamicUpsert type:' + objectType);
		Set<Integer> newExtIDSet = new Set<Integer>();
		String bbID = 'BookingBugId__c';
		//SObjectField uniqueField = Schema.get

		//Loop through and build a set of External IDs that should be used for a query
		for(Sobject sobj : genericSObjects){
			Integer bbIdVal = Integer.ValueOf(sobj.get(bbID)); //convert to integer as bb id is decimal #yay
			//SObjectField 
			if(bbIdVal != null) {
				newExtIDSet.add(bbIdVal);
			}
		}

		List<Sobject> sObjExistingList = new List<Sobject>();
		//Now use those external IDs for matching
		string sQuery = '';
		sQuery = 'Select ID, ' + bbID +
			' From ' + objectType + 
			' Where ' + bbID + ' IN :newExtIDSet';
		system.debug('==>newExtIdSet:' + newExtIDSet);
		system.debug('==>sobjExistingQuery:' + sQuery);
		sObjExistingList = database.query(sQuery);
		system.debug('==>SObjExistingList:' + sObjExistingList);
		//Now loop through the matches and build a map of that external ID to the actual Salesforce ID
		Map<string, string> extIDToIDMap = new Map<string, string>();
		for(sObject sObjItem : sObjExistingList) {
			extIDToIDMap.put(string.valueOf(sObjItem.get(bbID)), sObjItem.ID);
		}

		//Now loop through the items to be updated/inserted and assign the Salesforce IDs to that items that matches by the External ID
		List<sObject> sObjInsertList = new List<sObject>();
		List<sObject> sObjUpdateList = new List<sObject>();
		for(Sobject sObjItem : genericSObjects) {
			if(extIDToIDMap.containsKey(string.ValueOf(sObjItem.get(bbID)))) {
				sObjItem.ID = extIDToIDMap.get(string.ValueOf(sObjItem.get(bbID))); //do something like sobjitm.get(bbid) si apoi, mai jos, upsert
				sObjUpdateList.add(sObjItem);
			} else {
				sObjInsertList.add(sObjItem);
			}
		}
		if(sObjUpdateList.size() > 0) {
			system.debug('==>Update List:' + sObjUpdateList);
			update sObjUpdateList; //modify to database.update
		}
		if(sObjInsertList.size() > 0) {
			system.debug('==>Insert List:' + sObjInsertList);
			insert sObjInsertList;	//modify to database.insert
		}
	} //could be cool to also check email(for dupes) here and have a setting IN CLIENT RECORDS (OMG) - if yes/no 


	//new dynamic upsert
	//type is API_Name__c
	//check for Update Only option and decide
	//if upsert then check unique field and try assuming it is external id or idlookup and if it fails just insert
	//done?
	//return results somewhere and do something for logging
	public static void makeDMLOperation(Map<String, List<Sobject>> objects) {
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
		dmlOptions.optAllOrNone = false;
		Map<String, String> objectFieldMappings = Mapper.getActiveUniqueFields();
		system.debug('==>objectfieldMappings map:' + objectFieldMappings);
		List<SObject> updateOnlyObjects = filterUpdateOnly(objects);
		
		try {
			database.update(updateOnlyObjects, dmlOptions);
		} catch(DMLException ex) {
			system.debug('==>filterUpdateOnly:' + ex.getMessage());
		}

		system.debug('==>updateOnlyObjects in makeDML:' + updateOnlyObjects);
		system.debug('==>objects map after filtering update:' + objects);
		for(String objectName : objects.keySet()) {
			// List<SObject> castObjects = (List<SObject>)Type.forName(objectName).newInstance();
			// castObjects.addAll(objects.get(objectName));
			try {					
				//get METMappings(with field)
					//--see above
				//cast to SObjectField
				//upsert with that field
				List<SObject> casted = (List<SObject>)Type.forName('List<' + objectName + '>').newInstance();//don't know how reliable is this
				casted.addAll(objects.get(objectName));
				//database.SaveResult[] dmlResults = database.upsert(casted, dmlOptions);
				system.debug('==>objectFieldMappings field:' + objectFieldMappings.get(objectName));
				String extIdName = objectFieldMappings.get(objectName);

				Schema.DescribeFieldResult extIdField;

				if(String.isNotBlank(extIdName)) {
					extIdField = Util.getFieldDetails(objectName, extIdName);
					getFieldDetails(objectName, objectFieldMappings.get(objectName));
					system.debug('==>extIdField:' + extIdField);
					if(extIdField.isExternalId() || extIdField.isIdLookup()) {
						system.debug('==>it is external id');
						upsert casted;
					}
				}
				//system.debug('==>DML results:' + dmlResults); //save this and log somewhere else
			} catch(DMLException dmlex) {
				system.debug('==>makeDMLOPEX:' + dmlex.getMessage());
			} catch(Exception ex) {
				system.debug('==>makeDMLEX:' + ex.getMessage());
			}
		}
	}


	private static Schema.DescribeFieldResult getFieldDetails(String objectName, String fieldName) {
		Map<String, Schema.SObjectType>     globalDescribe          = Schema.getGlobalDescribe(); 
		Schema.SObjectType                  objectType              = globalDescribe.get(objectName);
		Schema.DescribeSObjectResult        objectDescribeResult    = objectType.getDescribe();

		Map<String, Schema.SObjectField>    objectFieldMap          = objectDescribeResult.fields.getMap();
		Schema.SObjectField                 objectField             = objectFieldMap.get(fieldName);
		return objectField.getDescribe();
	}

	public static List<SObject> filterUpdateOnly(Map<String, List<SObject>> objects) {
		List<SObject> updateObjs = new List<SObject>();
		List<Booking_Bug_Mapping__mdt> updateMappings = Mapper.getActiveUpdateOnlyMappings();

		system.debug('==>updateMappings:' + updateMappings);
		if(updateMappings.size() > 0) {
			for(String apiName : objects.keySet()) {
				for(Booking_Bug_Mapping__mdt metaType : updateMappings)
					if(apiName.equalsIgnoreCase(metaType.API_Name__c)) {
						updateObjs.addAll(objects.get(apiName));
						objects.remove(apiName);
					}
			}
		}

		//filter out objects that have a value on ID(otherwise they can't be updated)
		for(SObject obj : updateObjs) {
			if(obj.get('Id') == null)
				obj.addError('Does not have value on the ID field!');
		}

		system.debug('==>updateObjects:' + updateObjs);
		return updateObjs;
	}

	public static DateTime stringToDate(String strDate) {
		try {
			Integer year = Integer.valueOf(strDate.substring(0, 4));
            Integer month = Integer.valueOf(strDate.substring(5, 7));
            Integer day = Integer.valueOf(strDate.substring(8, 10));
            Integer hour = Integer.valueOf(strDate.substring(11, 13));
            Integer minute = Integer.valueOf(strDate.substring(14, 16));
            Integer second = Integer.valueOf(strDate.substring(17, 19));
                
            return Datetime.newInstance(year, month, day, hour, minute, second);
        }
        catch(Exception ex) {
			return null;
		}
	}


	//4 case update/insert check
	//1 - customer wants only existing records updating. Append BB ID to them. Find them by unique_field
	// private static List<SObject> updateObjects(String objectName, List<Sobject> objsToBeUpdated, Schema.DescribeFieldResult uniqueField) {
	// 	if(String.isBlank(uniqueFieldName)) {
	// 		system.debug('==>Specified unique field is null');
	// 		return null;
	// 	}
		

	//}
	//2 - find existing recs by unique_filed, append BB ID and create new ones if that's the case
	//3 - customer gives upsert field (doesn't work) - we need to find existing and append and also create new ones if that's the case(manual upsert)
	//4 - update BY SF ID


	//search for records that have values in the Unique Field the same as on BookingBug
	public static List<SObject> findRecordsByUniqueField(String objectName, Set<String> existingValues, DescribeFieldResult field) {
		//future - should check if field is encrypted or not and use sosl instead of soql
		List<SObject> foundObjects = new List<SObject>();
		List<string> qryParams = new String[]{field.getName(), objectName};
		if (field.isEncrypted()) {
			//use SOSL but apparently no 'FIND set where vals in set'
			String searchQuery = String.join(new List<String>(existingValues), ' OR ');	// 4000 char limit in SOSL search query! *should* not be a problem
            String qryHolder = 'FIND ' + searchQuery + ' IN ALL FIELDS Returning {1}(Id, {0})]';
			String query = String.format(qryHolder, qryParams);
            foundObjects = Search.query(query)[0];
			//so - SOSL to find objects with field value equal to 'existingvalues' set - return list of sobject I guess
		} else {
			String qryHolder = 'SELECT Id, {0} FROM {1} WHERE {0} IN:existingValues';
			String query = String.format(qryHolder, qryParams);
			foundObjects = database.query(query);
		}
		system.debug('==>Found objects by uniqueID:' + foundObjects);
		return foundObjects;
	}
}