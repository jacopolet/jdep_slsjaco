//-------------------------------------------------------------------------------------------//
// Author       :   Anna Gonzales - Accenture
// Created Date :   May 17, 2017
// Usage        :   Test Class for TS_SignatureGeneratorController 
//-------------------------------------------------------------------------------------------//
@isTest
public class TS_SignatureGeneratorControllerTest {
    @testSetup
    static void dataSetup() {
        //Custom settings is being shared by all test class, if another test class has already inserted the record 
        //this test class will throw "UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record"
        try {
            TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
            trg.WorkOrderLineItemTrigger__c = true;
            insert trg;
           
        } catch(Exception ex) {
            system.debug(ex);
        }

        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.CasePBFlows__c = true;
        insert pb;
    }

    static testMethod void testConstructor() {
        Contact con = TS_TestDataFactory.createContact(); 
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;

        Case cse = TS_TestDataFactory.createFieldServiceCase();
        cse.ContactId = con.Id;
        insert cse;

         WorkOrder parentWO = TS_TestDataFactory.createWorkOrder();
         parentWO.CaseId = cse.Id;
         parentWO.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
		 parentWO.ContactId = con.Id;
         insert parentWO;

         WorkOrderLineItem woli = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
         woli.Case__c = cse.Id;
         test.startTest();
         woli.Signature__c = TS_TestDataFactory.createBase64();        
         woli.QuotingSignature__c = TS_TestDataFactory.createBase64();
         insert woli;
        
        Blob b = Blob.valueOf(woli.Signature__c);
        
        Attachment att = new Attachment();
        att.Name = '%' + INT_Constants.CLICK_SIGNATUREFILE + '%';
        att.ParentId = woli.Id;
        att.Body = b;
        insert att;    
        
        Attachment att1 = new Attachment();
        att1.Name = '%' + INT_Constants.CLICK_QUOTESIGNATUREFILE + '%';
        att1.ParentId = woli.Id;
        att1.Body = b;
        insert att1;   
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(woli); 
        
        TS_SignatureGeneratorController tsg = new TS_SignatureGeneratorController(stdController);
        test.stopTest();
        System.assert(tsg.photos != null);   
                
    }
}