public with sharing class Util {

	public static String bbIDName = 'BookingBugId__c';
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
	//CASE #1 - update by SF ID, discard rest
	//CASE #2 - update by existing field, discard rest
	//CASE #3 - update by existing field, upsert rest by bb id 
	//this method will not make DB Callouts! move DML ops in different method
	public static void makeDMLOperation(Map<String, List<Sobject>> objects) { //objectname - listof objects
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
		Map<String, String> objectFieldMappings = Mapper.getActiveUniqueFields(); //unique field + objectname
		Map<String, Booking_Bug_Mapping__mdt> mappingsInfo = Mapper.getActiveMetadataRecordsMap();

		//update only records (check update_only, check for SF ID) 
		List<SObject> recsToUpdateByID = filterUpdateOnly(objects); //(CASE #1) 
		List<SObject> recsToUpdateByUniqueField = new List<SObject>(); //(CASE #2)
		for(String objName : objects.keySet()) {
			String uniqueFieldName = objectFieldMappings.get(objName);
			Schema.DescribeFieldResult uniqueField;
			//update only(check unique field, assign BB ID, discard non found)
			system.debug('==>here(makeDMLOP before IF)');
			if(String.isNotBlank(uniqueFieldName)) {
				uniqueField = Util.getFieldDetails(objName, uniqueFieldName);
				Set<String> uniqueValues = extractUniqueFieldValue(objects.get(objName), uniqueFieldName);
				List<SObject> foundObjects = findRecordsByUniqueField(objName, uniqueValues, uniqueField);
				Map<String, Integer> bbValMap = bbFieldValueMap(objects.get(objName), uniqueFieldName);
				for(SObject objToUpdate : foundObjects) {
					Integer newBBId = bbValMap.get((String)objToUpdate.get(uniqueFieldName));
					objToUpdate.put(bbIDName, newBBId);
				}
				update foundObjects;
			} else {
				system.debug('==>here(makeDMLOP in else)');
				String listType = 'List<' + objName + '>';
        		List<SObject> castRecords = (List<SObject>)Type.forName(listType).newInstance();
        		castRecords.addAll(objects.get(objName));
				Schema.DescribeFieldResult bbExternalId = getFieldDetails(objName, bbIDName);
				database.upsert(castRecords, bbExternalId.getSObjectField());
				system.debug('==>castRecords:' + castRecords);
			}

			//upsert-manual(check unique field, assign BB ID, insert others)
			//insert only(upsert by BB ID)
			//UPSERT BY BB ID ALL
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
		for(SObject obj : updateObjs) { //filter out objects that have a value on ID(otherwise they can't be updated)
			if(obj.get('Id') == null)
				obj.addError('Does not have value on the ID field!');
		}
		system.debug('==>updateObjects:' + updateObjs);
		return updateObjs; //this returns {account, contact, lead, etc and will work with one database.update call for all}
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
		if (!field.isFilterable()) {
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

	private Static Set<String> extractUniqueFieldValue(List<SObject> objects, String field) {
		Set<String> values = new Set<String>();
		for(SObject obj : objects) {
			values.add((String)obj.get(field));
		}
		return values;
	}

	private Static Map<String, Integer> bbFieldValueMap(List<SObject> objectsFromBB, String uniqueField) {
		Map<String, Integer> fieldValueMap = new Map<String, Integer>();
		for(SObject obj : objectsFromBB) {
			fieldValueMap.put((String)obj.get(uniqueField), Integer.valueof(obj.get(bbIDName)));
		}
		return fieldValueMap;
	}

}