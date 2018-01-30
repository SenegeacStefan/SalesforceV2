public class BookingBugDataTriggerHandler extends TriggerHandler {

	private Map<Id, BookingBug_Data__c> newBBDataMap;
	private List<BookingBug_Data__c> newBBDataList;
	
	
	public BookingBugDataTriggerHandler() {
		//prevent recurison
		this.setMaxLoopCount(2);
	}

	public override void afterInsert()
	{
		//this section will be moved in a separate(domain? class)
		system.debug('==>once or twice or more?');
		newBBDataList = Trigger.new;
		//system.debug('==>newBBDataList: ' + newBBDataList);
		List<Client> clients = new List<Client>();
		List<Booking> bookings = new List<Booking>();
		for(BookingBug_Data__c bdata : newBBDataList) {
			Mapper m = new Mapper();
			if(String.isNotBlank(bdata.Clients__c)) {
				clients = Mapper.deserializeClients(bdata.Clients__c);
				Map<String, List<Sobject>> clientlist = m.createClientMapping(clients);
				Util.makeDMLOperation(clientlist);
			}
			if(String.isNotBlank(bdata.Booking__c)) {
				bookings = Mapper.deserializeBookings(bdata.Booking__c);
				Map<string, List<Sobject>> booklist = m.createBookingMapping(bookings);
				Util.makeDMLOperation(booklist); 
			}
		}
	}
}