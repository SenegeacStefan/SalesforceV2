public with sharing class StaffMappingController {
	public PersonExtended[] peopleExtended {get; set;}
    public PUM__c[] lookUpUsers{get; set;}
    public Map<PersonExtended, PUM__c> personUserMap {get; set;}
    
    
	public StaffMappingController() {

	}

	public List<PersonExtended> getStaffUsers() {
		peopleExtended = new PersonExtended[0];
        
		List<Person> personList = BookingBugSelector.getAllStaff();
		system.debug('==>StaffMapping ctrl staff list:' + personList);
		//List<PersonExtended> staff = new List<PersonExtended>();
    	lookUpUsers = new List<PUM__c>();
		personUserMap = new Map<PersonExtended, PUM__c>();
        
        PUM__c[] existingMappingList = [SELECT Id, Name, User__c FROM PUM__c];
        Map<String, PUM__c> existingMappingsMap = new Map<String, PUM__c>();
        for (PUM__c eml : existingMappingList) {
            existingMappingsMap.put(eml.Name, eml);
        }
        
		for(Person p : personList) {
            PUM__c pum = new PUM__c();
            PersonExtended pex;
            
            if (existingMappingsMap.get(p.name) != null) {
                pum.User__c = existingMappingsMap.get(p.name).User__c;
                pex = new PersonExtended(existingMappingsMap.get(p.name).id, p, existingMappingsMap.get(p.name).User__c);
            } else {
                pex = new PersonExtended(null, p, null);
            }
            
            peopleExtended.add(pex);
            lookUpUsers.add(pum);
            personUserMap.put(pex, pum);
		}
        
        return peopleExtended;
	}
    
    public void saveMapping() {
        List<User> userList = [SELECT Id, StaffId__c FROM User];
        for (User u : userList) {
            u.StaffID__c = null;
        }
                
        PUM__c[] personUserMapToUpsert = new PUM__c[0];
        
        for (integer i = 0; i<peopleExtended.size(); i++) {
            PersonExtended p = peopleExtended.get(i);
            PUM__c pum = lookUpUsers.get(i);
            personUserMapToUpsert.add(new PUM__c(
                                                                 Name = p.person.name,
                                                                 User__c = pum.User__c));   
            for (User u : userList) {
                if (u.Id == pum.User__c) {
                    u.StaffID__c = p.person.id;
                }
            }
        }
        
        update userList;
        upsert personUserMapToUpsert Name;
    }

	public class PersonExtended {
        public Id personUserMappingId {get; set;}  
        public Person person {get; set;}  
        public Id mappedUserId {get; set;}   
        
        public PersonExtended(Id personUserMappingId, Person person, Id mappedUserId) {
            this.personUserMappingId = personUserMappingId;
            this.person = person;
            this.mappedUserId = mappedUserId;
        }
    }

	//list users - create rows for how many staff there are then same number of user lookups in the right
	// STAFF - USER LOOKUP pairs
	// STAFF DISPLAY NAME ONLY AS LABEL(READ-ONLY) BUT VAL IS ID
	// UPDATE CORRECT USER WITH CORRECT STAFF ID
	// ERROR PRONE FOR EVERYTHING!
}