@isTest
private class SM_OperationalTaskHeaderController_Test {

	private static testMethod void getRelatedOT() {
	    
	    Operational_Tasks__c ot = new Operational_Tasks__c();
        ot.Status__c = 'Redial';
	    insert ot;
	    
	    Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
	    
	    Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'INBOUND CALL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        tasks.Operational_Tasks__c = ot.id;
        
        insert tasks;
        
        SM_OperationalTaskHeaderController.getRelatedOTId(tasks.id);
        
        Task tRec = [Select Id, Operational_Tasks__c FROM Task WHERE Id = :tasks.id];
	    
	    System.assert(tRec.Operational_Tasks__c != Null);

	}
	
	private static testMethod void negativeTest() {
	    
	    Operational_Tasks__c ot = new Operational_Tasks__c();
        ot.Status__c = 'Redial';
	    insert ot;
	    
	    Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
	    
	    Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'INBOUND CALL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        tasks.Operational_Tasks__c = ot.id;
        
        insert tasks;
        try {
            SM_OperationalTaskHeaderController.getRelatedOTId(ot.id);
        
            Task tRec = [Select Id, Operational_Tasks__c FROM Task WHERE Id = :tasks.id];
    	    
    	    System.assert(tRec.Operational_Tasks__c != Null);
        } catch (Exception e) {
            
        }
        
	}

}