//VERY IMPORTANT CONSIDERATION - WE CURRENTLY USE MEMBER ID FOR BOOKINGBUGID ON BOOKING OBJECT 
//IN FUTURE WE NEED TO PASS A SET OF MEMBER IDS ALONG WITH THE BOOKING SOBJECT TO LINK CORRECTLY

public with sharing class STD_Referencing {
	
	//this will be triggered right after a DML OP from BB. A schedulable variant could also exist
	//assertStandardObject is there to avoid unnecessary queries if object is not covered
	public static List<Sobject> std_referencing(Map<String, List<SObject>> objects) {
		Set<Integer> bbIds;
		Set<Integer> memberIds;
		List<Sobject> referencedObjects = new List<SObject>();
		Map<Integer, SObject> eventMap;
		Map<Integer, SObject> taskMap;
		Map<Integer, SObject> accountMap;
		Map<Integer, SObject> contactMap;
		Map<Integer, SObject> caseMap;
		Map<Integer, SObject> opportunityMap;
		Map<Integer, SObject> leadMap;

		for(String objectName : objects.keyset()) {
			if(assertStandardObject(objectName)) {
				system.debug('==>STD REFERENCING OBJECT NAME:' + objectName);
				bbids = Util.extractBBId(objects.get(objectName), Util.bbIDName);

				if(objectName.equalsIgnoreCase('event')) {
					//region map create
					memberIds = Util.extractBBId(objects.get(objectName), Util.bbMemberId);
					eventMap = BookingBugSelector.getBBEvents(bbids);
					accountMap = BookingBugSelector.getBBAccounts(memberIds);
					taskMap = BookingBugSelector.getBBTasks(bbids);
					contactMap = BookingBugSelector.getBBContacts(memberIds);
					caseMap = BookingBugSelector.getBBCases(bbids);
					opportunityMap = BookingBugSelector.getBBOpportunities(bbids);
					leadMap = BookingBugSelector.getBBLeads(memberIds);
					//end region
					system.debug('==>STD Referencing bbIds Event:' + bbids);
					for(Integer bbId : eventMap.keyset()) {
						Integer memberId = Integer.ValueOf(eventMap.get(bbId).get(Util.bbMemberId)); //get member ID from Booking
						system.debug('==>STD EVENT memberId:' + memberId);
						Id accId = assignNotNullValue(accountMap, memberId);
						Id caseId = assignNotNullValue(caseMap, memberId);
						Id oppId = assignNotNullValue(opportunityMap, bbId);
						Id whatId = accId == null? (oppId == null? caseId : oppId) : accId;
						system.debug('==>STD EVENT accId: ' + accId);
						eventMap.get(bbId).put('WhatId', whatId);
						Id ctId = assignNotNullValue(contactMap, memberId);
						Id leadId = assignNotNullValue(leadMap, memberId);
						Id whoId = ctId == null? leadId : ctId;
						eventMap.get(bbId).put('WhoId', whoId);
						system.debug('==>STD EVENT ctID: ' + ctId);
					}
					referencedObjects.addAll(eventMap.values());
				}

				if(objectName.equalsIgnoreCase('task')) {
					//region map create
					memberIds = Util.extractBBId(objects.get(objectName), Util.bbMemberId);
					eventMap = BookingBugSelector.getBBEvents(bbids);
					accountMap = BookingBugSelector.getBBAccounts(memberIds);
					taskMap = BookingBugSelector.getBBTasks(bbids);
					contactMap = BookingBugSelector.getBBContacts(memberIds);
					caseMap = BookingBugSelector.getBBCases(bbids);
					opportunityMap = BookingBugSelector.getBBOpportunities(bbids);
					leadMap = BookingBugSelector.getBBLeads(memberIds);
					//end region
					
					for(Integer bbId : taskMap.keyset()) {
						Integer memberId = Integer.ValueOf(eventMap.get(bbId).get(Util.bbMemberId)); //get member ID from Booking
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
					accountMap = BookingBugSelector.getBBAccounts(bbids);
					contactMap = BookingBugSelector.getBBContacts(bbids);
					for(Integer bbId : contactMap.keyset()) {
						Id accId = assignNotNullValue(accountMap, bbId);
						contactMap.get(bbId).put('AccountId', accId);
					}
					referencedObjects.addAll(contactMap.values());
				}

				if(objectName.equalsIgnoreCase('case')) {
					memberIds = Util.extractBBId(objects.get(objectName), Util.bbMemberId);
					caseMap = BookingBugSelector.getBBCases(bbids);
					accountMap = BookingBugSelector.getBBAccounts(memberIds);
					contactMap = BookingBugSelector.getBBContacts(memberIds);
					
					for(Integer bbId : caseMap.keyset()) {
						Integer memberId = Integer.ValueOf(eventMap.get(bbId).get(Util.bbMemberId)); //get member ID from Booking
						Id ctId = assignNotNullValue(contactMap, bbId);
						Id accId = assignNotNullValue(accountMap, bbId);
						caseMap.get(bbId).put('AccountId', accid);
						caseMap.get(bbId).put('ContactId', ctId);
					}
					referencedObjects.addAll(caseMap.values());
				}

				if(objectName.equalsIgnoreCase('opportunity')) {
					memberIds = Util.extractBBId(objects.get(objectName), Util.bbMemberId);
					opportunityMap = BookingBugSelector.getBBOpportunities(bbids);
					accountMap = BookingBugSelector.getBBAccounts(memberIds);
					for(Integer bbId : opportunityMap.keyset()) {
						Integer memberId = Integer.ValueOf(eventMap.get(bbId).get(Util.bbMemberId)); //get member ID from Booking
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