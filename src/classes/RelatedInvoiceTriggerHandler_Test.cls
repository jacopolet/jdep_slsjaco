/* Karen Hung 
 * November 24, 2020
 * Test class for RelatedInvoiceTriggerHandler DOO-4734
*/
@isTest
private class RelatedInvoiceTriggerHandler_Test {
    static Account acct;
    static Case caseRec;
    static Apttus_Billing__Invoice__c invoiceRec;
    static Related_Invoice__c relInvoice;

    @testSetup
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.RelatedInvoiceTrigger__c = true;
        upsert trg;
    }
    
    static void setupTestData(){
        acct = APTS_TestUtils.createaccount();
        insert acct;
        
        caseRec = APTS_TestUtils.createCase(acct.Id);
		insert caseRec;
        
        invoiceRec = APTS_TestUtils.createInvoice(acct.Id);
        insert invoiceRec;
        
        relInvoice = new Related_Invoice__c ();
        relInvoice.Case__c = caseRec.Id;
        relInvoice.Invoice__c = invoiceRec.Id;
        relInvoice.Dunning_Block__c = true;
        insert relInvoice;		        
    }
    
    private static testMethod void preventDeletiontest(){
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {        	
            
            test.startTest();
            setupTestData();
            
            relInvoice.Dunning_Block__c = false;
            update relInvoice;
            
            delete relInvoice;
            
            undelete relInvoice;
            
            test.stopTest();
            //verify value of related invoice
            system.assertEquals(relInvoice.Dunning_Block__c, false);
        }
    }
}