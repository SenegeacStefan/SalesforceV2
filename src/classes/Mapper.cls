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
            Map<String, Object> questionMap = deserializeQuestionsMap(m);
            List<SObject> clientObjects = new List<SObject>();
            for(Client client : clients) {
                Sobject rawClient = Schema.getGlobalDescribe().get(m.API_Name__c).newSObject();
                Schema.SobjectType rawObjType = Schema.getGlobalDescribe().get(m.API_Name__c);
                Map<String, Schema.SObjectField> rawObjectFieldMap = rawObjType.getDescribe().fields.getMap();

                for(String s : clientMap.keyset()) { //debug
                    Object val = (Object)client.get((String)clientMap.get(s));
                    system.debug('==>cfield:' + s);
                    system.debug('==>cvalue:' + val); //https://salesforce.stackexchange.com/questions/135891/can-we-access-class-properties-dynamically-with-object-class
                    rawClient.put(s, val);
                }
                //questions region
                if(client.answers != null && client.answers.size() > 0 && questionMap != null && questionMap.size() > 0) {                         
                    for(Answer a : client.answers) {
                        String fld = (String)questionMap.get(a.question); //field name
                        if (rawObjectFieldMap.get(fld).getDescribe().getType() == Schema.DisplayType.Boolean) {
                            String boolVal = (String.valueOf(a.answer)).toLowerCase();
                            rawClient.put(fld, (boolVal == 'true' || boolVal == 'yes' || boolVal == '1')); //field - answer 
                        } else {
                            rawClient.put(fld, a.answer);
                        }
                    }
                }
                //questions region end
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
            Map<String, Object> questionMap = deserializeQuestionsMap(m);
            system.debug('==>Mapper.createBookingMapping bookingMap: ' + bookingMap); //put here field and values from questionMapping

            List<SObject> bookObjects = new List<SObject>();
            for(Booking booking : bookings) {
                SObject rawBooking = Schema.getGlobalDescribe().get(m.API_Name__c).newSObject();
                
                Schema.SobjectType rawObjType = Schema.getGlobalDescribe().get(m.API_Name__c);
                Map<String, Schema.SObjectField> rawObjectFieldMap = rawObjType.getDescribe().fields.getMap();
                
                for(String s : bookingMap.keyset()) {
                    system.debug('==>bookingVal: ' + booking.get((String)bookingMap.get(s)));
                    Object val = (Object)booking.get((String)bookingMap.get(s));
                    system.debug('==>bfield:' + s);
                    system.debug('==>bvalue:' + val);
                    //check if field is questions and treat accordingly
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
                //questions region
                if(booking.questions != null && booking.questions.size() > 0 && questionMap != null && questionMap.size() > 0) {                         
                    for(Answer a : booking.questions) {
                        String fld = (String)questionMap.get(a.question); //field name
                        if(String.IsNotBlank(fld)){
                            if (rawObjectFieldMap.get(fld).getDescribe().getType() == Schema.DisplayType.Boolean) {
                                String boolVal = (String.valueOf(a.answer)).toLowerCase();
                                rawBooking.put(fld, (boolVal == 'true' || boolVal == 'yes' || boolVal == '1')); //field - answer 
                            } else {
                                rawBooking.put(fld, a.answer);
                            }
                        }
                    }
                }
                //questions region end
                bookObjects.add(rawBooking);
            }
            objMapType.put(m.API_Name__c, bookObjects);
        }
        return objMapType;
    }

    public Map<String, Object> deserializeMapping(Booking_Bug_Mapping__mdt mapping) {
        if(String.IsNotBlank(mapping.Field_Map_Definition__c))
            return (Map<String, Object>)Json.deserializeUntyped(mapping.Field_Map_Definition__c);
        return null;
    }

    public Map<String, Object> deserializeQuestionsMap(Booking_Bug_Mapping__mdt mapping) {
        if(String.IsNotBlank(mapping.Question_Mapping__c))
            return (Map<String, Object>)Json.deserializeUntyped(mapping.Question_Mapping__c);
        return null;
    }

    public static List<Client> deserializeClients(String JSONString) {
        List<Client> clients = new List<Client>();
        Client member = new Client();
        //JSONString = JSONString.replace('\\"', '"');
        Object objectMap = (Object)JSON.deserializeUntyped(JSONString);
        system.debug('==>Mapper jsonstring client:' + JSONString);
        //Type clientType = Type.getType(Client.class);
        member = (Client)JSON.deserialize(JSON.serialize(objectMap)
                                                         .replace('datetime":"', '"date_time":"'), 
                                                         Client.class);
                                                        
        system.debug('==>Mapper client class:' + member);
        system.debug('==>Mapper client questions:' + member.answers);
        clients.add(member);
        // Map<String, Object> objectMap = (Map<String, Object>)JSON.deserializeUntyped(JSONString);
        // system.debug('==>objectMap:' + objectMap);
        // Map<String, Object> justClientsMap = (Map<String, Object>) objectMap.get('_embedded');
        // system.debug('==>justClientsMap:' + justClientsMap);
        // List<Object> clientListRaw = (List<Object>)justClientsMap.get('clients');
        // List<Client> clients = (List<Client>)JSON.deserialize(JSON.serialize(clientListRaw)
        //                                                   .replace('"datetime":"', '"date_time":"')
        //                                                   .replace('"_links":{', '"links":{'),
        //                                               List<Client>.class);
        return clients;
    }

    //even though it returns a list in 99.99% it's only 1 booking, the code was built w/o this info
    public static List<Booking> deserializeBookings(String JSONString) {
        List<Booking> books = new List<Booking>();
        Booking book = new Booking();
        //JSONString = JSONString.replace('\\"', '"');
        Object objectMap = (Object)JSON.deserializeUntyped(JSONString);
        system.debug('==>Mapper jsonstring:' + objectMap);
        book = (Booking)JSON.deserialize(JSON.serialize(objectMap)
                                                        .replace('"datetime":"', '"date_time":"'), 
                                                        Booking.class);
        system.debug('==>Mapper booking class:' + book);
        system.debug('==>Mapper rawBooking answer:' + book.questions );
        books.add(book);
        return books;
    }

    public static Person deserializeStaff(String JSONString) {
        Person staff = new Person();
        staff = (Person)JSON.deserialize(JSONString, Person.class);
        system.debug('==>Mapper staff class:' + staff);
        return staff;
    }

    public static Map<String, Booking_Bug_Mapping__mdt> getMetadataRecordsMap() {
        Map<String, Booking_Bug_Mapping__mdt> mappingsMap = new Map<String, Booking_Bug_Mapping__mdt>();
        List<Booking_Bug_Mapping__mdt> metadataRecords =  [SELECT API_Name__c, Field_Map_Definition__c, Is_Active__c, Type__c, Update_Only__c
                                                           FROM Booking_Bug_Mapping__mdt];
        for(Booking_Bug_Mapping__mdt mapping : metadataRecords) {
            mappingsMap.put(mapping.API_Name__c, mapping);
        }
        return mappingsMap;
    }

    public static Map<String, Booking_Bug_Mapping__mdt> getActiveMetadataRecordsMap() {
        Map<String, Booking_Bug_Mapping__mdt> mappingsMap = new Map<String, Booking_Bug_Mapping__mdt>();
        List<Booking_Bug_Mapping__mdt> metadataRecords =  [SELECT API_Name__c, Field_Map_Definition__c, Is_Active__c, Type__c, Update_Only__c, Question_Mapping__c
                                                           FROM Booking_Bug_Mapping__mdt 
                                                           WHERE Is_Active__c = TRUE];
        for(Booking_Bug_Mapping__mdt mapping : metadataRecords) {
            mappingsMap.put(mapping.API_Name__c, mapping);
        }
        return mappingsMap;
    }

    public static List<Booking_Bug_Mapping__mdt> getActiveClientRecordsOrderedByObjectType() {
        return [SELECT API_Name__c, Field_Map_Definition__c, Is_Active__c, Type__c, Update_Only__c, Question_Mapping__c
                FROM Booking_Bug_Mapping__mdt
                WHERE Type__c = 'Client' AND Is_Active__c = TRUE
                ORDER BY API_Name__c];
    }

    public static List<Booking_Bug_Mapping__mdt> getActiveBookingRecordsOrderedByObjectType() {
        return [SELECT API_Name__c, Field_Map_Definition__c, Is_Active__c, Type__c, Update_Only__c, Question_Mapping__c
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
} //update