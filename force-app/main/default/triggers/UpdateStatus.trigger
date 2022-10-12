trigger UpdateStatus on  Unit_Progress__c (after update) {
    if(Trigger.isAfter){
        UpdateStatusHelper.afterUpdateHelper(Trigger.new);
    }
}

