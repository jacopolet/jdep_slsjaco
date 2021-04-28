@isTest
public class APTS_AgreementLoadTest {
    @testSetup
    private static void testDataSetup() {

        //insert custom settings
        TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.Agreement__c = false;
        objTriggerSettings.AssetLineItemTrigger__c = false;
        objTriggerSettings.APTS_Configuration_Trigger__c = false;
        insert objTriggerSettings;

        Account grandParentAccount = APTS_TestUtils.createGrandParentAccount();
        insert grandParentAccount;

        Account parentAccount = APTS_TestUtils.createParentAccount(grandParentAccount);
        insert parentAccount;

        Account childAccount = APTS_TestUtils.createChildAccount(parentAccount);
        insert childAccount;
        
        Opportunity opp = APTS_TestUtils.createOpportunity(childAccount.id);
        insert opp;
        
        Product2 product =APTS_TestUtils.createProduct('Piazza DOro Estremo Bonen 1000 Gram','26940998','Espresso');
        insert product;

        Apttus_Config2__ClassificationName__c category = APTS_TestUtils.createCategory();
        insert category;

        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = APTS_TestUtils.createCategoryHierarchy(category.Id);
        insert categoryHierarchy;

        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = APTS_TestUtils.createSubCategory(category.Id, categoryHierarchy.Id);
        insert subCategoryHierarchy;

        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = APTS_TestUtils.createSubSubCategory(category.Id,categoryHierarchy.Id ,subCategoryHierarchy.Id);
        insert subSubCategoryHierarchy;

        Apttus_Config2__ProductClassification__c productClassification = APTS_TestUtils.createProductClassification(subCategoryHierarchy.Id, product.id);
        insert productClassification;

        Apttus_Config2__ProductClassification__c productClassification1 = APTS_TestUtils.createProductClassification(subCategoryHierarchy.Id, product.id);
        insert productClassification1;
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        insert priceList;
        
        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.createPriceListItem(priceList.id,product.id);
        insert priceListItem;
        
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                Name = 'Agreement',
                Apttus__Agreement_Category__c = 'Standard',
                Apttus_CMConfig__PriceListId__c = priceList.Id,
                Apttus__Account__c = childAccount.Id);
        insert agreement;
        
        Apttus_Config2__ProductConfiguration__c agreementCart = new Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_CMConfig__AgreementId__c=agreement.id,Apttus_Config2__PriceListId__c=priceList.id);
        agreementCart.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        insert agreementCart;

        Apttus_Config2__LineItem__c lineItem1 = APTS_TestUtils.getConfigLineItem(agreementCart.id, null, 1, true, 2, '', product.id, false, null,product.id, null, '', 2.3, false, '', 1, priceList.id, priceListItem.Id, '', '', 'Sales Price', '',false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
        insert lineItem1;

        List<APTS_Adjustments__c> adjustmentLineItems = APTS_TestUtils.getAdjustmentLineItems(agreement.Id, categoryHierarchy.Id, subCategoryHierarchy.Id,subSubCategoryHierarchy.Id , childAccount.id, priceListItem.Id);
        for(APTS_Adjustments__c adj:adjustmentLineItems){
             adj.APTS_Type__c = 'TPR';
        } 
        insert adjustmentLineItems;

    }

    private static testMethod void test1() {
        //Set metadata
        APTS_BatchMetadataCoverageTest.setMetadata(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_API__c,'+
            'APTS_Triggers__c,'+
            'APTS_Times_Reprice__c '+
            'FROM APTS_Batch_Queries__mdt '+ 
            'WHERE DeveloperName = \'Query1\'',
            (List<APTS_Batch_Queries__mdt>) JSON.deserialize('[{"APTS_Query_String__c":"SELECT Id FROM Apttus_Config2__ProductConfiguration__c",'+
                '"APTS_Times_Reprice__c":"2","APTS_Triggers__c":"Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c",'+
                '"APTS_API__c":"true"}]', 
                List<APTS_Batch_Queries__mdt>.class
                )
            );

        test.startTest();
            APTS_AgreementLoadSch scheduler = new APTS_AgreementLoadSch();      
            String sch = '0  00 1 3 * ?';
            system.schedule('Test APTS_AgreementLoadSch', sch, scheduler);
        test.stopTest();
   
    }
}