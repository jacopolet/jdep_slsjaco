/*
* @author        Francis Allen Alindogan
* @date          November 16, 2020
* @description   Test class for TS_DeleteOperationalContact_Batch
* @revision(s)
*/

@isTest
public class TS_DeleteOperationalContactBatch_Test {
    
    static Account acct;
    static Contact con;
    static Contact con2;
    static Case c;
    static Case c2;	
    static product2 prod;

    
    @testSetup
    public static void dataSetup() {
		String operationalConId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(TS_Constants.TS_CONTACT_RECORDTYPE_OPERATIONALCONTACT).getRecordTypeId();            		
        Integer threshold  = 0 - Integer.valueOf(Label.TS_DeleteOperationalContactThreshold);
		
        con = TS_TestDataFactory.createContact();
        con.RecordTypeId = operationalConId;
        con.Last_Relevant_Activity_Date__c = Date.Today().AddMonths(threshold-2);
        insert con;    
                
		con2 = TS_TestDataFactory.createContact();
        con2.RecordTypeId = operationalConId;
        con2.Last_Relevant_Activity_Date__c = Date.Today().AddMonths(threshold);
        insert con2;    
        
        acct = new Account(Name='Account', Phone='+31302979111');   
        insert acct;
                
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.AccountId = acct.Id;
        c.SalesOrganization__c= 'SAP_0111'; 
        c.Status = TS_Constants.STATUS_CLOSED;        
        insert c;
                
    }
       
    private static testMethod void testDeleteOperationalContact() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {         
            Test.startTest();  
            	dataSetup();
                TS_DeleteOperationalContact_Batch regularBatch = new TS_DeleteOperationalContact_Batch(0);                                                             
                TS_DeleteOperationalContact_Batch.hasException = true;
                Database.executeBatch(regularBatch);            		
            Test.stopTest();     
        }        
    }              
}