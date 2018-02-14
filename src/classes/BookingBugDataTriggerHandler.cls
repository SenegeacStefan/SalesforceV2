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
		for(BookingBug_Data__c bdata : newBBDataList) {
			Mapper m = new Mapper();
			if(String.isNotBlank(bdata.Clients__c)) {
				//try{
					List<Client> clients = new List<Client>();
					clients = Mapper.deserializeClients(bdata.Clients__c);
					Map<String, List<Sobject>> clientlist = m.createClientMapping(clients);
					Util.makeDMLOperation(clientlist);
				// } catch(Exception ex) {
				// 	system.debug('==>Handler Client Exception:' + ex.getMessage());
				// }
			}
			if(String.isNotBlank(bdata.Booking__c)) {
				//try{
					List<Booking> bookings = new List<Booking>();
					bookings = Mapper.deserializeBookings(bdata.Booking__c);
					Map<string, List<Sobject>> booklist = m.createBookingMapping(bookings);
					Util.makeDMLOperation(booklist); 
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