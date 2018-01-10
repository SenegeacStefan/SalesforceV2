//class that handles the mapping
public with sharing class Mapper {
	public Mapper() {
		
	}

	//public List<SObject> createClientMapping(List<Client> clients) {
	public Map<String, List<SObject>> createClientMapping(List<Client> clients) {
		Map<String, List<SObject>> objMapType = new Map<String, List<SObject>>();
		List<Booking_Bug_Mapping__mdt> mappings = getActiveClientRecordsOrderedByObjectType();
		//check by api name and put at right key(key is api name - upsert by key)
		//you need to create an sobject with the api_name type and assign fields based on mapping
		//damn dynamic object creation
		//https://developer.salesforce.com/forums/?id=906F000000090F3IAI
		//sObject sObj = Schema.getGlobalDescribe().get(ObjectName).newSObject() ;
		for(Booking_Bug_Mapping__mdt m : mappings) {	
			Map<String, Object> clientMap = deserializeMapping(m);
			List<SObject> clientObjects = new List<SObject>();
			for(Client client : clients) {
				Sobject rawClient = Schema.getGlobalDescribe().get(m.API_Name__c).newSObject();
				for(String s : clientMap.keyset()) { //debug
					Object val = (Object)client.get((String)clientMap.get(s));
					system.debug('==>cfield:' + s);
					system.debug('==>cvalue:' + val); //https://salesforce.stackexchange.com/questions/135891/can-we-access-class-properties-dynamically-with-object-class
					rawClient.put(s, val);
				}
				//test
				clientObjects.add(rawClient);
			}
			objMapType.put(m.API_Name__c, clientObjects);
		}
		return objMapType;
	}

	public Map<String, List<SObject>> createBookingMapping(List<Booking> bookings) {
		system.debug('==>Mapper.createBookingMapping bookings: ' + bookings);
		Map<String, List<SObject>> objMapType = new Map<String, List<SObject>>();
		List<Booking_Bug_Mapping__mdt> mappings = getActiveBookingRecordsOrderedByObjectType();
		for(Booking_Bug_Mapping__mdt m : mappings) {
			system.debug('==>Mapper mapping: ' + m);
			Map<String, Object> bookingMap = deserializeMapping(m);
			system.debug('==>Mapper.createBookingMapping bookingMap: ' + bookingMap);
			List<SObject> bookObjects = new List<SObject>();
			for(Booking booking : bookings) {
				SObject rawBooking = Schema.getGlobalDescribe().get(m.API_Name__c).newSObject();
				
				Schema.SobjectType rawObjType = Schema.getGlobalDescribe().get(m.API_Name__c);
				system.debug('==>rawObjType: ' + rawObjType);
				Map<String, Schema.SObjectField> rawObjectFieldMap = rawObjType.getDescribe().fields.getMap();
				system.debug('==>rawObjectFieldMap: ' + rawObjectFieldMap);
				for(String s : bookingMap.keyset()) {
					system.debug('==>bookingVal: ' + booking.get((String)bookingMap.get(s)));
					Object val = (Object)booking.get((String)bookingMap.get(s));
					system.debug('==>bfield:' + s);
					system.debug('==>bvalue:' + val);
					system.debug('*** ' + rawObjectFieldMap.get(s).getDescribe().getType());
					if (rawObjectFieldMap.get(s).getDescribe().getType() == Schema.DisplayType.DateTime) {
						//system.debug('==> datetime!');
						DateTime dt;
						try {
							dt = Util.stringToDate((String)val);
							rawBooking.put(s, dt);
						}
						catch(Exception ex)
						{
							system.debug('==>Mapper.createBookingMapping exception: ' + ex.getMessage());
						}
					}
                    else if (rawObjectFieldMap.get(s).getDescribe().getType() == Schema.DisplayType.Boolean) {
						String boolVal = (String.valueOf(val)).toLowerCase();
						rawBooking.put(s, (boolVal == 'true' || boolVal == 'yes' || boolVal == '1'));
					}
					else {
						rawBooking.put(s, val);
					}
				}
				bookObjects.add(rawBooking);
			}
			objMapType.put(m.API_Name__c, bookObjects);
		}
		return objMapType;
	}

	public Map<String, Object> deserializeMapping(Booking_Bug_Mapping__mdt mapping) {
		return (Map<String, Object>)Json.deserializeUntyped(mapping.Field_Map_Definition__c);
	}

	public static List<Client> deserializeClients(String JSONString) {
		System.debug('==>JSON-string: ' + JSONString);
		Map<String, Object> objectMap = (Map<String, Object>)JSON.deserializeUntyped(JSONString);
		system.debug('==>objectMap:' + objectMap);
		Map<String, Object> justClientsMap = (Map<String, Object>) objectMap.get('_embedded');
		system.debug('==>justClientsMap:' + justClientsMap);
		List<Object> clientListRaw = (List<Object>)justClientsMap.get('clients');
		List<Client> clients = (List<Client>)JSON.deserialize(JSON.serialize(clientListRaw)
														  .replace('"datetime":"', '"date_time":"')
														  .replace('"_links":{', '"links":{'),
													  List<Client>.class);
		return clients;
	}

	public static List<Booking> deserializeBookings(String JSONString) {
		Map<String, Object> objectMap = (Map<String, Object>)JSON.deserializeUntyped(JSONString);
		Map<String, Object> justBookingsMap = (Map<String, Object>)objectMap.get('_embedded');
		List<Object> bookingListRaw = (List<Object>)justBookingsMap.get('bookings');
		List<Booking> bookings = (List<Booking>)JSON.deserialize(JSON.serialize(bookingListRaw)
														.replace('"datetime":"', '"date_time":"'), 
														List<Booking>.class);
		return bookings;
	}

	public static List<Booking_Bug_Mapping__mdt> getMetadataRecords() {
		return [SELECT API_Name__c, Field_Map_Definition__c, Is_Active__c, Type__c, Update_Only__c
				FROM Booking_Bug_Mapping__mdt];
	}

	public static List<Booking_Bug_Mapping__mdt> getActiveClientRecordsOrderedByObjectType() {
		return [SELECT API_Name__c, Field_Map_Definition__c, Is_Active__c, Type__c, Update_Only__c
				FROM Booking_Bug_Mapping__mdt
				WHERE Type__c = 'Client' AND Is_Active__c = TRUE
				ORDER BY API_Name__c];
	}

	public static List<Booking_Bug_Mapping__mdt> getActiveBookingRecordsOrderedByObjectType() {
		return [SELECT API_Name__c, Field_Map_Definition__c, Is_Active__c, Type__c, Update_Only__c
				FROM Booking_Bug_Mapping__mdt
				WHERE Type__c = 'Booking' AND Is_Active__c = TRUE
				ORDER BY API_Name__c];
	}

	public static List<Booking_Bug_Mapping__mdt> getActiveUpdateOnlyMappings() {
		return [SELECT API_Name__c, Update_Only__c
				FROM Booking_Bug_Mapping__mdt
				WHERE Update_Only__c = TRUE];
	}

	//object-uniqueFieldName for upsert calls
	//save-bug
	public static Map<String, String> getActiveUniqueFields() {
		Map<String, String> objectFieldMap = new Map<String, String>();
		List<Booking_Bug_Mapping__mdt> mappings = [SELECT Unique_Field__c, API_Name__c
												   FROM Booking_Bug_Mapping__mdt
												   WHERE Is_Active__c = TRUE];
		for(Booking_Bug_Mapping__mdt mapping : mappings) {
			objectFieldMap.put(mapping.API_Name__c, mapping.Unique_Field__c);
		}
		return objectFieldMap;
	}
}