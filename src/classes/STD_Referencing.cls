public with sharing class STD_Referencing {
	
	//this will be triggered right after a DML OP from BB. A schedulable variant could also exist
	//assertStandardObject is there to avoid unnecessary queries if object is not covered
	public static List<Sobject> std_referencing(Map<String, List<SObject>> objects) {
		Set<Integer> bbIds;
		List<Sobject> referencedObjects = new List<SObject>();

		for(String objectName : objects.keyset()) {
			if(assertStandardObject(objectName)) {
				bbids = Util.extractBBId(objects.get(objectName));
				Map<Integer, SObject> eventMap = BookingBugSelector.getBBEvents(bbids);
				Map<Integer, SObject> taskMap = BookingBugSelector.getBBTasks(bbids);
				Map<Integer, SObject> accountMap = BookingBugSelector.getBBAccounts(bbids);
				Map<Integer, SObject> contactMap = BookingBugSelector.getBBContacts(bbids);
				Map<Integer, SObject> caseMap = BookingBugSelector.getBBCases(bbids);
				Map<Integer, SObject> opportunityMap = BookingBugSelector.getBBOpportunities(bbids);
				Map<Integer, SObject> leadMap = BookingBugSelector.getBBLeads(bbids);

				if(objectName.equalsIgnoreCase('event')) {
					for(Integer bbId : eventMap.keyset()) {
						Id accId = assignNotNullValue(accountMap, bbId);
						Id caseId = assignNotNullValue(caseMap, bbId);
						Id oppId = assignNotNullValue(opportunityMap, bbId);
						Id whatId = accId == null? (oppId == null? caseId : oppId) : accId;
						eventMap.get(bbId).put('WhatId', whatId);
						Id ctId = assignNotNullValue(contactMap, bbId);
						Id leadId = assignNotNullValue(leadMap, bbId);
						Id whoId = ctId == null? leadId : ctId;
						eventMap.get(bbId).put('WhoId', whoId);
					}
					referencedObjects.addAll(eventMap.values());
				}

				if(objectName.equalsIgnoreCase('task')) {
					for(Integer bbId : taskMap.keyset()) {
						Id accId = assignNotNullValue(accountMap, bbId);
						Id caseId = assignNotNullValue(caseMap, bbId);
						Id oppId = assignNotNullValue(opportunityMap, bbId);
						Id whatId = accId == null? (oppId == null? caseId : oppId) : accId;
						taskMap.get(bbId).put('WhatId', whatId);
						Id ctId = assignNotNullValue(contactMap, bbId);
						Id leadId = assignNotNullValue(leadMap, bbId);
						Id whoId = ctId == null? leadId : ctId;
						taskMap.get(bbId).put('WhoId', whoId);
					}
					referencedObjects.addAll(taskMap.values());
				}

				if(objectName.equalsIgnoreCase('contact')) {
					for(Integer bbId : contactMap.keyset()) {
						Id accId = assignNotNullValue(accountMap, bbId);
						contactMap.get(bbId).put('AccountId', accId);
					}
					referencedObjects.addAll(contactMap.values());
				}

				if(objectName.equalsIgnoreCase('case')) {
					for(Integer bbId : caseMap.keyset()) {
						Id ctId = assignNotNullValue(contactMap, bbId);
						Id accId = assignNotNullValue(accountMap, bbId);
						caseMap.get(bbId).put('AccountId', accid);
						caseMap.get(bbId).put('ContactId', ctId);
					}
					referencedObjects.addAll(caseMap.values());
				}

				if(objectName.equalsIgnoreCase('opportunity')) {
					for(Integer bbId : opportunityMap.keyset()) {
						Id accId = assignNotNullValue(accountMap, bbId);
						opportunityMap.get(bbId).put('AccountId', accId);
					}
					referencedObjects.addAll(opportunityMap.values());
				}
				
			}
		}
		return referencedObjects;
	}

	//check if object is covered by std referencing by name checking
	private static boolean assertStandardObject(String objectName) {
		if(objectName.equalsIgnoreCase('account') || objectName.equalsIgnoreCase('contact') ||
		   objectName.equalsIgnoreCase('lead') || objectName.equalsIgnoreCase('opportunity') ||
		   objectName.equalsIgnoreCase('case') || objectName.equalsIgnoreCase('event') ||
		   objectName.equalsIgnoreCase('task'))
		   return true;
		return false;
	}

	private static Id assignNotNullValue(Map<Integer, SObject> mapWithVal, Integer bbId) {
		if(mapWithVal != null && mapWithVal.size() > 0) {
			if(mapWithVal.get(bbId) != null)
				return (Id)mapWithVal.get(bbId).get('Id');
		}
		return null;
	}
}