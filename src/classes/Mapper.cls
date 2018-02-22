//class that handles the mapping
public with sharing class Mapper {
    public Mapper() {
        
    }

    public static Map<Booking_Bug_Mapping__mdt, SObject> createClientMapping(Client member) {
        Map<Booking_Bug_Mapping__mdt, SObject> clientObjects = new Map<Booking_Bug_Mapping__mdt, SObject>(); //one object per mapping
        SObject clientObject;
        List<Booking_Bug_Mapping__mdt> mappings = getActiveClientRecordsOrderedByObjectType();
        Map<String, Object> clientMap;
        Map<String, Object> questionMap;

        for(Booking_Bug_Mapping__mdt m : mappings) {
            clientMap = deserializeMapping(m);
            questionMap = deserializeQuestionsMap(m);
            clientObject = Schema.getGlobalDescribe().get(m.API_Name__c).newSObject();
            Schema.SobjectType clientObjType = Schema.getGlobalDescribe().get(m.API_Name__c);
            Map<String, Schema.SObjectField> clientObjectFieldMap = clientObjType.getDescribe().fields.getMap();
            assignQuestions(clientObjectFieldMap, clientObject, questionMap, member.answers);
            for(String s : clientMap.keyset()) {
                Object val = (Object)member.get((String)clientMap.get(s));
                assignFieldVal(clientObjectFieldMap, clientObject, s, val);
            }
            clientObjects.put(m, clientObject);
        }
        return clientObjects;
    }

    public static List<SObject> createBookingMapping(Booking book) {
        List<SObject> bookingObjects = new List<SObject>();
        SObject bookingObject;
        List<Booking_Bug_Mapping__mdt> mappings = getActiveBookingRecordsOrderedByObjectType();
        Map<String, Object> bookingMap;
        Map<String, Object> questionMap;

        for(Booking_Bug_Mapping__mdt m : mappings) {
            bookingMap = deserializeMapping(m);
            questionMap = deserializeQuestionsMap(m);
            bookingObject = Schema.getGlobalDescribe().get(m.API_Name__c).newSObject();
            Schema.SobjectType bookingObjType = bookingObject.getSObjectType();
            Map<String, Schema.SObjectField> bookingObjectFieldMap = bookingObjType.getDescribe().fields.getMap();
            assignQuestions(bookingObjectFieldMap, bookingObject, questionMap, book.questions);
            for(String s : bookingMap.keyset()) {
                Object val = (Object)book.get((String)bookingMap.get(s));
                assignFieldVal(bookingObjectFieldMap, bookingObject, s, val);
            }
            bookingObjects.add(bookingObject);
        }
        return bookingObjects;
    }

    public static void assignQuestions(Map<String, Schema.SObjectField> objFieldMap, SObject obj, Map<String, Object> questionMap, List<Answer> questions) {
        if(questionMap != null && questions != null && questionMap.size() > 0 && questions.size() > 0) {
            for(Answer ans : questions) {
                if(questionMap.get(ans.question) != null) {
                    String fld = (String)questionMap.get(ans.question); //field for answer
                    assignFieldVal(objFieldMap, obj, fld, ans.answer);
                }
            }
        }
    }

    public static void assignFieldVal(Map<String, Schema.SObjectField> objFieldMap, SObject obj, String fld, Object val) {
        if(String.IsNotBlank(fld) && val != null) {
            Schema.DisplayType fldType = objFieldMap.get(fld).getDescribe().getType();
            if(fldType == Schema.DisplayType.Boolean) {
                String boolVal = (String.valueOf(val)).toLowerCase();
                obj.put(fld, (boolVal == 'true' || boolVal == 'yes' || boolVal == '1'));
            } else if(fldType == Schema.DisplayType.DateTime) {
                DateTime dt;
                try {
                    dt = Util.stringToDate((String)val);
                    obj.put(fld, dt);
                }
                catch(Exception ex)
                {
                    system.debug('==>Mapper.createBookingMapping exception: ' + ex.getMessage());
                }
            } else {
                obj.put(fld, val);
            }
        }
    }

    // public Map<String, List<SObject>> createClientsMapping(List<Client> clients) {
    //     Map<String, List<SObject>> objMapType = new Map<String, List<SObject>>();
    //     List<Booking_Bug_Mapping__mdt> mappings = getActiveClientRecordsOrderedByObjectType();
    //     //check by api name and put at right key(key is api name - upsert by key)
    //     //you need to create an sobject with the api_name type and assign fields based on mapping
    //     //damn dynamic object creation
    //     //https://developer.salesforce.com/forums/?id=906F000000090F3IAI
    //     //sObject sObj = Schema.getGlobalDescribe().get(ObjectName).newSObject() ;
    //     for(Booking_Bug_Mapping__mdt m : mappings) {    
    //         Map<String, Object> clientMap = deserializeMapping(m);
    //         Map<String, Object> questionMap = deserializeQuestionsMap(m);
    //         List<SObject> clientObjects = new List<SObject>();
    //         for(Client client : clients) {
    //             Sobject rawClient = Schema.getGlobalDescribe().get(m.API_Name__c).newSObject();
    //             Schema.SobjectType rawObjType = Schema.getGlobalDescribe().get(m.API_Name__c);
    //             Map<String, Schema.SObjectField> rawObjectFieldMap = rawObjType.getDescribe().fields.getMap();

    //             for(String s : clientMap.keyset()) { //debug
    //                 Object val = (Object)client.get((String)clientMap.get(s));
    //                 system.debug('==>cfield:' + s);
    //                 system.debug('==>cvalue:' + val); //https://salesforce.stackexchange.com/questions/135891/can-we-access-class-properties-dynamically-with-object-class
    //                 rawClient.put(s, val);
    //             }
    //             //questions region
    //             if(client.answers != null && client.answers.size() > 0 && questionMap != null && questionMap.size() > 0) {                         
    //                 for(Answer a : client.answers) {
    //                     String fld = (String)questionMap.get(a.question); //field name
    //                     if (rawObjectFieldMap.get(fld).getDescribe().getType() == Schema.DisplayType.Boolean) {
    //                         String boolVal = (String.valueOf(a.answer)).toLowerCase();
    //                         rawClient.put(fld, (boolVal == 'true' || boolVal == 'yes' || boolVal == '1')); //field - answer 
    //                     } else {
    //                         rawClient.put(fld, a.answer);
    //                     }
    //                 }
    //             }
    //             //questions region end
    //             clientObjects.add(rawClient);
    //         }
    //         objMapType.put(m.API_Name__c, clientObjects);
    //     }
    //     return objMapType;
    // }

    // public Map<String, List<SObject>> createBookingMapping(List<Booking> bookings) {
    //     system.debug('==>Mapper.createBookingMapping bookings: ' + bookings);
    //     Map<String, List<SObject>> objMapType = new Map<String, List<SObject>>();
    //     List<Booking_Bug_Mapping__mdt> mappings = getActiveBookingRecordsOrderedByObjectType();
    //     for(Booking_Bug_Mapping__mdt m : mappings) {
    //         system.debug('==>Mapper mapping: ' + m);
    //         Map<String, Object> bookingMap = deserializeMapping(m);
    //         Map<String, Object> questionMap = deserializeQuestionsMap(m);
    //         system.debug('==>Mapper.createBookingMapping bookingMap: ' + bookingMap); //put here field and values from questionMapping

    //         List<SObject> bookObjects = new List<SObject>();
    //         for(Booking booking : bookings) {
    //             SObject rawBooking = Schema.getGlobalDescribe().get(m.API_Name__c).newSObject();
                
    //             Schema.SobjectType rawObjType = Schema.getGlobalDescribe().get(m.API_Name__c);
    //             Map<String, Schema.SObjectField> rawObjectFieldMap = rawObjType.getDescribe().fields.getMap();
                
    //             for(String s : bookingMap.keyset()) {
    //                 system.debug('==>bookingVal: ' + booking.get((String)bookingMap.get(s)));
    //                 Object val = (Object)booking.get((String)bookingMap.get(s));
    //                 system.debug('==>bfield:' + s);
    //                 system.debug('==>bvalue:' + val);
    //                 //check if field is questions and treat accordingly
    //                 system.debug('*** ' + rawObjectFieldMap.get(s).getDescribe().getType());
    //                 if (rawObjectFieldMap.get(s).getDescribe().getType() == Schema.DisplayType.DateTime) {
    //                     //system.debug('==> datetime!');
    //                     DateTime dt;
    //                     try {
    //                         dt = Util.stringToDate((String)val);
    //                         rawBooking.put(s, dt);
    //                     }
    //                     catch(Exception ex)
    //                     {
    //                         system.debug('==>Mapper.createBookingMapping exception: ' + ex.getMessage());
    //                     }
    //                 }
    //                 else if (rawObjectFieldMap.get(s).getDescribe().getType() == Schema.DisplayType.Boolean) {
    //                     String boolVal = (String.valueOf(val)).toLowerCase();
    //                     rawBooking.put(s, (boolVal == 'true' || boolVal == 'yes' || boolVal == '1'));
    //                 }
    //                 else {
    //                     rawBooking.put(s, val);
    //                 }
                    
    //             }
    //             //questions region
    //             if(booking.questions != null && booking.questions.size() > 0 && questionMap != null && questionMap.size() > 0) {                         
    //                 for(Answer a : booking.questions) {
    //                     String fld = (String)questionMap.get(a.question); //field name
    //                     if(String.IsNotBlank(fld)){
    //                         if (rawObjectFieldMap.get(fld).getDescribe().getType() == Schema.DisplayType.Boolean) {
    //                             String boolVal = (String.valueOf(a.answer)).toLowerCase();
    //                             rawBooking.put(fld, (boolVal == 'true' || boolVal == 'yes' || boolVal == '1')); //field - answer 
    //                         } else {
    //                             rawBooking.put(fld, a.answer);
    //                         }
    //                     }
    //                 }
    //             }
    //             //questions region end
    //             bookObjects.add(rawBooking);
    //         }
    //         objMapType.put(m.API_Name__c, bookObjects);
    //     }
    //     return objMapType;
    // }

    public static Map<String, Object> deserializeMapping(Booking_Bug_Mapping__mdt mapping) {
        if(String.IsNotBlank(mapping.Field_Map_Definition__c))
            return (Map<String, Object>)Json.deserializeUntyped(mapping.Field_Map_Definition__c);
        return null;
    }

    public static Map<String, Object> deserializeQuestionsMap(Booking_Bug_Mapping__mdt mapping) {
        if(String.IsNotBlank(mapping.Question_Mapping__c))
            return (Map<String, Object>)Json.deserializeUntyped(mapping.Question_Mapping__c);
        return null;
    }

    public static Client deserializeClient(String JSONString) {
        Client member = new Client();
        JSONString = JSONString.replace('\\"', '"'); //for testing when inputting manual JSON
        Object objectMap = (Object)JSON.deserializeUntyped(JSONString);
        system.debug('==>Mapper jsonstring client:' + JSONString);
        member = (Client)JSON.deserialize(JSON.serialize(objectMap)
                                                         .replace('datetime":"', '"date_time":"'), 
                                                         Client.class);
        return member;
    }

    public static Booking deserializeBooking(String JSONString) {
        Booking book = new Booking();
        //JSONString = JSONString.replace('\\"', '"');
        Object objectMap = (Object)JSON.deserializeUntyped(JSONString);
        system.debug('==>Mapper jsonstring:' + objectMap);
        book = (Booking)JSON.deserialize(JSON.serialize(objectMap)
                                                        .replace('"datetime":"', '"date_time":"'), 
                                                        Booking.class);
        system.debug('==>Mapper booking class:' + book);
        system.debug('==>Mapper rawBooking answer:' + book.questions );
        return book;
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
        return [SELECT API_Name__c, Field_Map_Definition__c, Is_Active__c, Type__c, Update_Only__c, Question_Mapping__c, Unique_Field__c
                FROM Booking_Bug_Mapping__mdt
                WHERE Type__c = 'Client' AND Is_Active__c = TRUE
                ORDER BY API_Name__c];
    }

    public static List<Booking_Bug_Mapping__mdt> getActiveBookingRecordsOrderedByObjectType() {
        return [SELECT API_Name__c, Field_Map_Definition__c, Is_Active__c, Type__c, Update_Only__c, Question_Mapping__c, Unique_Field__c
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