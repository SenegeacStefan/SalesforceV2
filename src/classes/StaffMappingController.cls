public with sharing class StaffMappingController {
	public StaffMappingController() {
		
	}

	public List<Person> getAllStaff() {
		return BookingBugSelector.getAllStaff();
	}

	//list users - create rows for how many staff there are then same number of user lookups in the right
	// STAFF - USER LOOKUP pairs
	// STAFF DISPLAY NAME ONLY AS LABEL(READ-ONLY) BUT VAL IS ID
	// UPDATE CORRECT USER WITH CORRECT STAFF ID
	// ERROR PRONE FOR EVERYTHING!
}