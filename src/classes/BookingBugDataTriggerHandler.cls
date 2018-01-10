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
		// for(BookingBug_Data__c bdata : newBBDataList) {
		// 	//system.debug('==>bdata.Clients__c: ' + bdata.Clients__c);
		// 	//clients = Mapper.deserializeClients(bdata.Clients__c);
		// 	system.debug('==>bdata.Booking__c: ' + bdata.Booking__c);
		// 	bookings = Mapper.deserializeBookings(bdata.Booking__c);
		// }
		//system.debug('==>clients:' + clients);
		//system.debug('==>client fname:' + clients[0].get('first_name'));
		//system.debug('==>clients count:' + clients.size());
		system.debug('==>bookings:' + bookings);
		system.debug('==>bookings count:' + bookings.size());

		Mapper m = new Mapper();
		//Map<String, List<Sobject>> clientlist = m.createClientMapping(clients);
		//Map<string, List<Sobject>> booklist = m.createBookingMapping(bookings);
		//system.debug('==>bookObjList' + booklist);
		//system.debug('==>clientList:' + clientlist);
		// for(String s : clientlist.KeySet()) {
		// 	Util.dynamicUpsert(clientlist.get(s), s);
		// }

		// for(String s: booklist.KeySet()) {
		// 	Util.dynamicUpsert(booklist.get(s), s);
		// }
		//Util.makeDMLOperation(booklist);
		//Util.makeDMLOperation(clientlist);
	}

	//TODO
	//test with multiple Client types 
	//make code error/hazard resilient
	//structure methods in a pretty way
	//start-finish booking
	//find way to link everything through bb_id or other stuff
	//start considering SF-REF (ID) and how to treat it
	//best of luck to me :) 
}