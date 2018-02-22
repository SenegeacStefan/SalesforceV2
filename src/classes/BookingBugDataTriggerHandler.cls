public class BookingBugDataTriggerHandler extends TriggerHandler {

	private List<BookingBug_Data__c> newBBDataList;
	
	
	public BookingBugDataTriggerHandler() {
		//prevent recurison
		this.setMaxLoopCount(2);
	}

	public override void afterInsert()
	{
		newBBDataList = Trigger.new;
		for(BookingBug_Data__c bdata : newBBDataList) {
			Mapper m = new Mapper();
			if(String.isNotBlank(bdata.Clients__c)) {
					//List<Client> clients = new List<Client>();
					Client member = new Client(); 
					member = Mapper.deserializeClient(bdata.Clients__c);
					Map<Booking_Bug_Mapping__mdt, SObject> cList = Mapper.createClientMapping(member);
					system.debug('==>Handler Client List:' + cList);
					Util.makeDMLOperation(cList);
			}
			if(String.isNotBlank(bdata.Booking__c)) {
				//try{
					//List<Booking> bookings = new List<Booking>();
					Booking book = new Booking();
					book = Mapper.deserializeBooking(bdata.Booking__c);
					List<SObject> booklist = Mapper.createBookingMapping(book);
					system.debug('==>Handler Booking List:' + booklist);
					//Util.makeDMLOperation(booklist); 
				// } catch(Exception ex) {
				// 	system.debug('==>Handler Booking Exception:' + ex.getMessage());
				// }
			}
			if(String.isNotBlank(bdata.Staff__c)) {
				Person staff = new Person();
				staff = Mapper.deserializeStaff(bdata.Staff__c);
			}
		}
	}

	public override void beforeInsert() 
	{
		newBBDataList = Trigger.new;
		for(BookingBug_Data__c bdata : newBBDataList) {
			if(String.IsNotBlank(bdata.Staff__c)) {
				bdata.staffnotempty__c = true;
			} else {
				bdata.staffnotempty__c = false;
			}
		}
	}
}