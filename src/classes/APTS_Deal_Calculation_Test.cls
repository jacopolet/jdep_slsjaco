@istest
public class APTS_Deal_Calculation_Test {
    
    private static final String ACCOUNT_NAME = 'JDETestAccount';
    private static final String CONTACT_NUMBER = '1010101011';
    private static final String STANDARD_DEAL = 'Standard Deal';
    private static final String PRICELIST_NAME = 'JDETest Price List';
    private static final String PROD_FAMILY_MACHINE = 'MA';
    private static final String PROD_CONFIG_BUNDLE = 'Bundle';
    private static final String APPNAME = 'Deal Calculation';
    
    static testmethod void logic(){
        // create account
        Account oAccount = APTS_TestDataFactory.createAccount(ACCOUNT_NAME);
        Database.insert(oAccount, FALSE);

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, CONTACT_NUMBER);
        Database.insert(oContact, FALSE);

        //create price list
        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList(PRICELIST_NAME);
        Database.insert(oPricelist, FALSE);
        
        //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct(ACCOUNT_NAME,ACCOUNT_NAME, PROD_FAMILY_MACHINE, PROD_CONFIG_BUNDLE, FALSE, TRUE);
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        //Agreement
        Apttus__APTS_Agreement__c oAgr = APTS_TestDataFactory.createAgreement(oContact.Id, oPricelist.Id, oAccount.Id, STANDARD_DEAL);
        oAgr.Apttus__Term_Months__c = 12;
        Database.insert(oAgr, FALSE);
        
        Apttus_Config2__ProductConfiguration__c config = APTS_TestDataFactory.createProductConfig(oAgr);
        Database.insert(config, FALSE);

        Apttus_Config2__ClassificationName__c oCategory = new Apttus_Config2__ClassificationName__c();
        oCategory.Name = 'Test Cat';
        oCategory.Apttus_Config2__HierarchyLabel__c = 'Test Cat';
        Database.insert(oCategory, FALSE);

        Apttus_Config2__ClassificationHierarchy__c oCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        oCategoryHierarchy.APTS_CategoryHierarchyOfferingExtId__c = '0701';
        oCategoryHierarchy.Apttus_Config2__HierarchyId__c = oCategory.Id;
        oCategoryHierarchy.Name = 'Test';
        oCategoryHierarchy.Apttus_Config2__Label__c = 'Test';
        Database.insert(oCategoryHierarchy, FALSE); 
        
        Apttus_Config2__LineItem__c oMachineLineItemBundle = APTS_TestDataFactory.createLineItem(config, NULL, NULL, prod1.Id, NULL, NULL, 1, 1, 2, 'Product/Service', NULL, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
        oMachineLineItemBundle.Apttus_Config2__IsPrimaryLine__c = true;
        oMachineLineItemBundle.Apttus_Config2__ClassificationHierarchy__c = 'Machines';
        oMachineLineItemBundle.Apttus_Config2__ClassificationId__c = oCategory.Id;
        Database.insert(oMachineLineItemBundle, FALSE);

        Apttus_XApps__Application__c app = new Apttus_XApps__Application__c(name=APPNAME, Apttus_XApps__UniqueId__c='111');
        insert app;
        
        ApexPages.currentPage().getParameters().put('id', config.id);
        ApexPages.currentPage().getParameters().put('businessObjectId', oAgr.id);
        
        test.startTest();
            
        APTS_Deal_Calculation dcal = new APTS_Deal_Calculation();
        string str = dcal.primaryLineItemJson;
        dcal.updateCartStatus();
        Pagereference p = dcal.returnToAgreement();
    
        system.assertEquals('/'+oAgr.Id, p.getUrl());
            
        test.stopTest();
        
    }

}