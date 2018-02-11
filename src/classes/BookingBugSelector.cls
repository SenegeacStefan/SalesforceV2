public with sharing class BookingBugSelector {

	public static Map<Integer, Sobject> getBBIDMap(Set<Integer> bbids, List<string> qryParams, String queryHolder) {
		Map<Integer, Sobject> sobjMap = new Map<Integer, Sobject>();
		String query = String.format(queryHolder, qryParams);
		system.debug('Selector query: ' + query);
		List<SObject> bbSObjs = database.query(query);
		for(SObject obj : bbSObjs) {
			sobjMap.put(Integer.valueOf(obj.get(Util.bbIDName)), obj);
		}
		return sobjMap;
	}

	//========================================================================= Standard object queries =========================================================================
	//0 = BookingBugId, 1 = Object name, 2 and forward are params

	//account = no link
	public static Map<Integer, SObject> getBBAccounts(Set<Integer> bbids) {
		String queryHolder = 'SELECT Id, {0} from {1} where {0} IN:bbids';
		List<string> qryParams = new List<string>{Util.bbIDName, 'Account' };
		Map<Integer, SObject> accMap = getBBIDMap(bbids, qryParams, queryHolder); 
		System.debug('Selector accMap:' + accMap);
		return accMap;
	}

	//contact =  accountId
	public static Map<Integer, SObject> getBBContacts(Set<Integer> bbids) {
		String queryHolder = 'SELECT Id, {0},{2} from {1} where {0} IN:bbids';
		List<string> qryParams = new List<string>{Util.bbIDName, 'Contact', 'AccountId'};
		Map<Integer, SObject> contactMap = getBBIDMap(bbids, qryParams, queryHolder); 
		System.debug('Selector contactMap:' + contactMap);
		return contactMap;
	}
	
	//lead = no link
	public static Map<Integer, SObject> getBBLeads(Set<Integer> bbids) {
		String queryHolder = 'SELECT Id, {0} from {1} where {0} IN:bbids';
		List<string> qryParams = new List<string>{Util.bbIDName, 'Lead'}; 
		Map<Integer, SObject> leadMap = getBBIDMap(bbids, qryParams, queryHolder); 
		System.debug('Selector leadMap:' + leadMap);
		return leadMap;
	}

	//Opportunity = accountId
	public static Map<Integer, SObject> getBBOpportunities(Set<Integer> bbids) {
		String queryHolder = 'SELECT Id, {0},{2} from {1} where {0} IN:bbids';
		List<string> qryParams = new List<string>{Util.bbIDName, 'Opportunity', 'AccountId'}; 
		Map<Integer, SObject> opportunityMap = getBBIDMap(bbids, qryParams, queryHolder); 
		System.debug('Selector opportunityMap:' + opportunityMap);
		return opportunityMap;
	}

	//Case = accountId, contactID
	public static Map<Integer, SObject> getBBCases(Set<Integer> bbids) {
		String queryHolder = 'SELECT Id, {0},{2},{3} from {1} where {0} IN:bbids';
		List<string> qryParams = new List<string>{Util.bbIDName, 'Case', 'AccountId','ContactId'}; 
		Map<Integer, SObject> caseMap = getBBIDMap(bbids, qryParams, queryHolder); 
		System.debug('Selector caseMap:' + caseMap);
		return caseMap;
	}

	//Event = whatId, whoId
	public static Map<Integer, SObject> getBBEvents(Set<Integer> bbids) {
		String queryHolder = 'SELECT Id, {0},{2},{3} from {1} where {0} IN:bbids';
		List<string> qryParams = new List<string>{Util.bbIDName, 'Event', 'WhatId','WhoId'}; 
		Map<Integer, SObject> eventMap = getBBIDMap(bbids, qryParams, queryHolder); 
		System.debug('Selector eventMap:' + eventMap);
		return eventMap;
	}

	//Task = whatId, whoId
	public static Map<Integer, SObject> getBBTasks(Set<Integer> bbids) {
		String queryHolder = 'SELECT Id, {0},{2},{3} from {1} where {0} IN:bbids';
		List<string> qryParams = new List<string>{Util.bbIDName, 'Task', 'WhatId','WhoId'}; 
		Map<Integer, SObject> taskMap = getBBIDMap(bbids, qryParams, queryHolder); 
		System.debug('Selector taskMap:' + taskMap);
		return taskMap;
	}
	//=============================================================================================================================================================================

	public static List<Person> getAllStaff() {
		List<BookingBug_Data__c> staffJSONList = new List<BookingBug_Data__c>();
		Map<Integer, Person> mapOfStaff = new Map<Integer, Person>(); //guarantee no duplicates
		staffJSONList = [SELECT Staff__c FROM BookingBug_Data__c 
										 WHERE staffnotempty__c = true];
		system.debug('==>BookingBug Selector staffJSONList' + staffJSONList);
		if(staffJSONList.size() > 0) {
			for(BookingBug_Data__c s : staffJSONList) {
				Person p = Mapper.deserializeStaff(s.Staff__c);
				mapOfStaff.put(p.id, p);
			}
		}
		return mapOfStaff.values();
	}
}