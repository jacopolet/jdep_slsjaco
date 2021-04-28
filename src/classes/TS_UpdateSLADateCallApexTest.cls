/**
* @author        Rey Austral
* @date          8.21.2017           
* @description   Test Class for TS_UpdateSLADateCallApex and TS_UpdateSLADateQueueable
* @revision(s)   4.26.2018 Paul Aguiling - Updated TestCallQueueable and TestException assertion methods
*/
@isTest
private class TS_UpdateSLADateCallApexTest {

	@isTest static void TestCallQueueable() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.CaseTrigger__c = true;
        Insert trg;
        
        Contact cons = TS_TestDataFactory.createContact();  
        Insert cons;   
        
        List<Account> accountList = TS_TestDataFactory.createAccounts(1);
        accountList.get(0).Name = 'DynamicSLAMilestoneCalculatorName';
        insert accountList;

        SlaProcess slaProc = [SELECT Id FROM SlaProcess 
                                where IsActive = true and IsVersionDefault = true and Name like '%complaint%' Limit 1];
        
        Entitlement ent = new Entitlement();
        ent.Name = 'Belgium - ' + Label.TS_Case_Type_Complaint + ' Contract';                        
        ent.AccountId = accountList.get(0).Id;
        ent.SlaProcessId = slaProc.Id;
        insert ent;     

		Case cse = TS_TestDataFactory.createFieldServiceCase();
        cse.ContactId = cons.Id;       
        cse.Type = Label.TS_Case_Type_Complaint;
        cse.SubType__c = 'Contract';
        cse.EntitlementId = ent.Id;
        
        insert cse;  
        test.startTest();
        TS_UpdateSLADateCallApex.UpdateSLARequest req = new TS_UpdateSLADateCallApex.UpdateSLARequest();
        req.caseIds = cse.Id;
        TS_UpdateSLADateCallApex.InvokeQueueableClass(New TS_UpdateSLADateCallApex.UpdateSLARequest[]{req});
        test.stopTest();
        Case updatedCse = [Select SLADate__c from Case where Id=:cse.Id];
        System.assert(updatedCse.SLADate__c == null);
	}
	
	@isTest static void TestNoCaseMilestone() {

		TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.CaseTrigger__c = true;
        Insert trg;      
        
        Contact cons = TS_TestDataFactory.createContact();  
        Insert cons;   
        
        List<Account> accountList = TS_TestDataFactory.createAccounts(1);
        accountList.get(0).Name = 'DynamicSLAMilestoneCalculatorName';
        insert accountList;   

		Case cse = TS_TestDataFactory.createFieldServiceCase();
        cse.ContactId = cons.Id;       
        cse.Type = Label.TS_Case_Type_Complaint;
        cse.SubType__c = 'Contract';
        test.startTest();
     
    	insert cse;  

    	TS_UpdateSLADateCallApex.UpdateSLARequest req = new TS_UpdateSLADateCallApex.UpdateSLARequest();
        req.caseIds = cse.Id;
        TS_UpdateSLADateCallApex.InvokeQueueableClass(New TS_UpdateSLADateCallApex.UpdateSLARequest[]{req});
       
        
        test.stopTest();
        Case updatedCse = [Select SLADate__c from Case where Id=:cse.Id];
        System.assertEquals(Null, updatedCse.SLADate__c);
	}

	@isTest static void TestException() {
		TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.CaseTrigger__c = true;
        Insert trg;  
        
        Contact cons = TS_TestDataFactory.createContact();  
        Insert cons;   
        
        List<Account> accountList = TS_TestDataFactory.createAccounts(1);
        accountList.get(0).Name = 'DynamicSLAMilestoneCalculatorName';
        insert accountList;

        SlaProcess slaProc = [SELECT Id FROM SlaProcess 
                                where IsActive = true and IsVersionDefault = true and Name like '%complaint%' Limit 1];
        
        Entitlement ent = new Entitlement();
        ent.Name = 'Belgium - ' + Label.TS_Case_Type_Complaint + ' Contract';                        
        ent.AccountId = accountList.get(0).Id;
        ent.SlaProcessId = slaProc.Id;
        insert ent;     

		Case cse = TS_TestDataFactory.createFieldServiceCase();
        cse.ContactId = cons.Id;       
        cse.Type = Label.TS_Case_Type_Complaint;
        cse.SubType__c = 'Contract';
        cse.EntitlementId = ent.Id;
        
        insert cse;  
        test.startTest();
        TS_UpdateSLADateCallApex.hasException = true;
        TS_UpdateSLADateCallApex.InvokeQueueableClass(null);
		TS_UpdateSLADateQueueable queue = new TS_UpdateSLADateQueueable();
        queue.numberOfExecution = 1;
		queue.hasException = true;
		queue.caseIds = cse.Id;
		System.enqueueJob(queue);
        
        
		test.stopTest();
		Case updatedCse = [Select SLADate__c from Case where Id=:cse.Id];
        System.assertEquals(Null, updatedCse.SLADate__c);
	}
	
}