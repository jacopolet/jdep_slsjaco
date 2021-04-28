/**
    * @author        Archi Delphinanto
    * @date          March .2018           
    * @description   Test class for TS_TaskClosureEmailLink_Controller
    * @revision(s)   
    */
@isTest
public class TS_TaskClosureEmailLink_Controller_Test {


 @isTest static void test_getcontentdistributionList () {
      User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
      System.runAs(u) {

                Contact con = TS_TestDataFactory.createContact();  
                con.Preferred_Language__c = 'SAP_EN';
                Insert con;

                Case cse = TS_TestDataFactory.createFieldServiceCase();
                cse.ContactId = con.Id;
                insert cse;

                 WorkOrder parentWO = TS_TestDataFactory.createWorkOrder();
                 parentWO.ContactId = con.Id;
                 parentWO.CaseId = cse.Id;
                 parentWO.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
                 insert parentWO;
                
                 Resource__c testResource = TS_TestDataFactory.createResourceSingle('Test Resource Number');
                 insert testResource;
                
                 WorkOrderLineItem woliParent = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
                 woliParent.ExecutingEngineer__c = testResource.Id;
                 woliParent.Status = Label.TS_WOLI_Status_Completed;
                 woliParent.InternalOrderSAP__c = '123';  
                 woliParent.WorkOrderLineItemType__c = Label.TS_Type_Task;   
                 woliParent.Case__c = cse.Id;
                 woliParent.WorkOrderId = parentWO.Id;
                
                 insert woliParent;
                
                // create content version

                Blob b= Blob.valueOf('UNIT.Test');

                ContentVersion signatureFile = new ContentVersion();
                signatureFile.VersionData = b;
                signatureFile.Title = 'TS_TaskClosureEmailLink_Controller';
                signatureFile.PathOnClient = 'TS_TaskClosureEmailLink_Controller.pdf' ;
                signatureFile.ContentLocation='S';
                signatureFile.Description  = woliParent.Id;
                signatureFile.ObjectReferenceID__c =woliParent.Id ;//
                 System.debug(' signatureFile : '+signatureFile);

                 //insert signatureFile;
                 Database.SaveResult lsr2 =Database.insert(signatureFile, false);
                 system.debug('Save result: ' +lsr2);

                ContentVersion newcontentversion = [SELECT ContentDocumentId,Description,PathOnClient, ObjectReferenceID__c FROM ContentVersion WHERE id =:signatureFile.id limit 1] ;
                System.debug(' content document id : '+newcontentversion.ContentDocumentId);

                ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = newcontentversion.ContentDocumentId, LinkedEntityId = newcontentversion.ObjectReferenceID__c, ShareType = 'V') ;

                insert cdl;

                // create content distribution
                  ContentDistribution cd = new ContentDistribution();
                  cd.PreferencesAllowPDFDownload = true;
                  cd.Name = newcontentversion.PathOnClient;
                  cd.ContentVersionId = newcontentversion.Id;
                  cd.PreferencesAllowOriginalDownload = false;
                  cd.PreferencesAllowViewInBrowser = true;
                insert cd;

                //////////////////////////

                 TS_TaskClosureEmailLink_Controller controller = new TS_TaskClosureEmailLink_Controller();
                 Test.startTest();
                 controller.WoliID = woliParent.Id;
                 List<ContentDistribution> cdrlist = controller.getcontentdistributionList();
                 System.debug('cdr list: ' + cdrlist);
                 
                 System.assert(cdrlist != null);

                 Test.stopTest();
             }
    }
    
    @isTest static void testException() {
      TS_TaskClosureEmailLink_Controller.hasException = true;
      User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
      System.runAs(u) {

                Contact con = TS_TestDataFactory.createContact();  
                con.Preferred_Language__c = 'SAP_EN';
                Insert con;

                Case cse = TS_TestDataFactory.createFieldServiceCase();
                cse.ContactId = con.Id;
                insert cse;

                 WorkOrder parentWO = TS_TestDataFactory.createWorkOrder();
                 parentWO.ContactId = con.Id;
                 parentWO.CaseId = cse.Id;
                 parentWO.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
                 insert parentWO;
                
                 Resource__c testResource = TS_TestDataFactory.createResourceSingle('Test Resource Number');
                 insert testResource;
                
                 WorkOrderLineItem woliParent = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
                 woliParent.ExecutingEngineer__c = testResource.Id;
                 woliParent.Status = Label.TS_WOLI_Status_Completed;
                 woliParent.InternalOrderSAP__c = '123';  
                 woliParent.WorkOrderLineItemType__c = Label.TS_Type_Task;   
                 woliParent.Case__c = cse.Id;
                 woliParent.WorkOrderId = parentWO.Id;
                
                 insert woliParent;
                
                // create content version

                Blob b= Blob.valueOf('UNIT.Test');

                ContentVersion signatureFile = new ContentVersion();
                signatureFile.VersionData = b;
                signatureFile.Title = 'TS_TaskClosureEmailLink_Controller';
                signatureFile.PathOnClient = 'TS_TaskClosureEmailLink_Controller.pdf' ;
                signatureFile.ContentLocation='S';
                signatureFile.Description  = woliParent.Id;
                signatureFile.ObjectReferenceID__c =woliParent.Id ;//
                 System.debug(' signatureFile : '+signatureFile);

                 //insert signatureFile;
                 Database.SaveResult lsr2 =Database.insert(signatureFile, false);
                 system.debug('Save result: ' +lsr2);

                ContentVersion newcontentversion = [SELECT ContentDocumentId,Description,PathOnClient, ObjectReferenceID__c FROM ContentVersion WHERE id =:signatureFile.id limit 1] ;
                System.debug(' content document id : '+newcontentversion.ContentDocumentId);

                ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = newcontentversion.ContentDocumentId, LinkedEntityId = newcontentversion.ObjectReferenceID__c, ShareType = 'V') ;

                insert cdl;

                // create content distribution
                  ContentDistribution cd = new ContentDistribution();
                  cd.PreferencesAllowPDFDownload = true;
                  cd.Name = newcontentversion.PathOnClient;
                  cd.ContentVersionId = newcontentversion.Id;
                  cd.PreferencesAllowOriginalDownload = false;
                  cd.PreferencesAllowViewInBrowser = true;
                insert cd;

                //////////////////////////

                 TS_TaskClosureEmailLink_Controller controller = new TS_TaskClosureEmailLink_Controller();
                 Test.startTest();
                 controller.WoliID = woliParent.Id;
                 List<ContentDistribution> cdrlist = controller.getcontentdistributionList();
                 Test.stopTest();
                 
                 System.assert(TS_TaskClosureEmailLink_Controller.hasException);
             }
    }
}