trigger BookingBugDataTrigger on BookingBug_Data__c (before insert, before update, before delete,
                                                    after insert, after update, after delete, after undelete) {
    new BookingBugDataTriggerHandler().run();
}