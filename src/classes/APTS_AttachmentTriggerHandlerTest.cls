/*************************************************************
@Name: APTS_AttachmentTriggerHandlerTest
@Author: Wendy Kelley
@CreateDate: 23-05-2018
@Description: Test class for APTS_AttachmentTriggerHandler class
@UsedBy: APTS_AttachmentTriggerHandler
**************************************************************/
@isTest
private class APTS_AttachmentTriggerHandlerTest {
    
    @isTest
    private static void testAttachmentTrigger() {
    
        TriggerSettings__c settings = new TriggerSettings__c(APTS_AssetTxnHistoryTrigger__c=true);
        Database.insert(settings, false);
        
        Contact contact = APTS_TestUtils.createContact();
        Database.insert(contact,false);
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.insert(priceList,false);
        
        Account account = APTS_TestUtils.createaccount();
        Database.insert(account,false);
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.createAgreement(contact.Id, null, priceList.Id, account.Id);
        agreement.Apttus__Status__c = 'Fully Signed';
        agreement.Apttus__Status_Category__c = 'In Signatures';
        agreement.Apttus__Auto_Renewal__c = false;
        agreement.Apttus__Contract_End_Date__c = System.Today() - 1;
        Database.insert(agreement,false);
        
        Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
        Attachment attachment = new Attachment(Name='Test Signed.pdf', Body=bodyBlob, ParentId=agreement.Id);
        Database.insert(attachment);
        
        Map<Id, Attachment> agreementAttachmentMap = new Map<Id, Attachment>();
        agreementAttachmentMap.put(agreement.Id, attachment);
        
        /* ---------- Start of PI fix # 718082----------------------- */
        Apttus__APTS_Agreement__c agmt = [SELECT Id, APTS_Document_Version__c FROM Apttus__APTS_Agreement__c WHERE Id IN :agreementAttachmentMap.keySet()];
        system.assert(agmt.id!=NULL);
        
        Attachment atAgmt = agreementAttachmentMap.get(agmt.Id);
        system.assertequals('Test Signed.pdf',atAgmt.Name);
        /* ---------- End of PI fix # 718082----------------------- */
        
        APTS_AttachmentTriggerHandler handler = new APTS_AttachmentTriggerHandler();
        handler.renameAgreementAttachments(agreementAttachmentMap);
        handler.beforeInsert(null);
        handler.beforeUpdate(null, null, null, null);
        handler.afterUpdate(null, null, null, null);
        handler.beforeDelete(null, null);
        handler.afterDelete(null, null);
        handler.afterUndelete(null, null);
    }

}