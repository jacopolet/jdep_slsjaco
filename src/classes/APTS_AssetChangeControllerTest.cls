/*******************************************************************************************
Name            : APTS_AssetChangeControllerTest
Created By      : Sneha Eltepu
Created Date    : 2692018
Description     : Test class written for 'APTS_AssetChangeControllerTest'.
Version history : 
*********************************************************************************************/
@isTest(SeeAllData=false)
private class APTS_AssetChangeControllerTest {
    @isTest
    private static void AssetChangeControllerUtil(){
        PageReference  pref = Page.APTS_AssetChanges;
        pref.getParameters().put('flow','RegisterMachineFlow');
        Test.setCurrentPage(pref);
        APTS_AssetChangeController AssetChange = new APTS_AssetChangeController();
        
        Test.startTest();
        AssetChange.lineitemlist =  new list<Apttus_Config2__LineItem__c>();
        AssetChange.updateLineItem();
        AssetChange.goBack();
        Test.stopTest();
    }
    
     @isTest
    private static void AssetChangeControllerUtil2(){
        
        Id recordtype = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(System.Label.APTS_Standard_Deal).getRecordTypeId();
        
        Account testAccount = APTS_TestUtils.createGrandParentAccount();
        testAccount.Name = 'Test Account';
        Database.Insert(testAccount);
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.insert(priceList, false);
        
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = testAccount.Id, 
                        Name = 'New Agreement',RecordTypeId = recordtype,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Signatures', Apttus__Status__c = 'Fully Signed');
        Database.Insert(testAgreement);
        
        Apttus_Config2__ProductConfiguration__c pC = new Apttus_Config2__ProductConfiguration__c();
        pC.Name = 'Product Config - Standard Deal';
        pC.Apttus_Config2__Status__c = 'Finalized';
        insert pC;
        
        Apttus_Config2__ProductConfiguration__c ProductConfiguration = APTS_TestDataFactory.createProductConfig(testAgreement);
        Database.insert(ProductConfiguration);
        
        /*Apttus_Config2__ProductAttributeValue__c  pA = new Apttus_Config2__ProductAttributeValue__c ();
        pA.APTS_Type_of_contract__c = 'Rent';
        pA.*/
        
        PhysicalAsset__c testphAsset = APTS_TestUtils.createPhysicalAsset();
        testphAsset.Name = 'Test Option Physical Asset';
        //testphAsset.RecordTypeId = optionRecId;
        testphAsset.SerialNumber__c = 'RJ213456234';
        testphAsset.PONumberServices__c = '123567';
        testphAsset.PONumberRequiredServices__c = 'Yes';
        testphAsset.PONumberTypeServices__c = 'Variable';
        insert testphAsset;
        
        Apttus_Config2__AssetLineItem__c tstAsset1 = new Apttus_Config2__AssetLineItem__c();
        tstAsset1.Apttus_Config2__LineNumber__c = 1;
        tstAsset1.Apttus_Config2__PrimaryLineNumber__c = 1;
        tstAsset1.Apttus_Config2__NetPrice__c = 100;
        tstAsset1.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset1.APTS_Old_Net_Price__c = 100;
        tstAsset1.Apttus_Config2__HasOptions__c = true;
        tstAsset1.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset1.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset1.APTS_Type_Of_Contract__c = 'Sales';
        tstAsset1.Apttus_Config2__IsPrimaryLine__c = true;
        tstAsset1.APTS_Is_Primary_L1_Line__c = false;
        tstAsset1.Apttus_Config2__HasOptions__c = true;
        tstAsset1.Apttus_Config2__EndDate__c = Date.today().addDays(100);
        insert tstAsset1;
        
        Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
        tstAsset.Apttus_Config2__LineNumber__c = 1;
        tstAsset.Apttus_Config2__PrimaryLineNumber__c = 1;
        tstAsset.Apttus_Config2__NetPrice__c = 100;
        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.APTS_Old_Net_Price__c = 100;
        tstAsset.Apttus_Config2__HasOptions__c = true;
        tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset.APTS_Type_Of_Contract__c = 'Sales';
        tstAsset.Apttus_Config2__IsPrimaryLine__c = true;
        tstAsset.APTS_Is_Primary_L1_Line__c = false;
        tstAsset.Apttus_Config2__HasOptions__c = true;
        tstAsset.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
        tstAsset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
        insert tstAsset;
        
        Apttus_Config2__LineItem__c lI = new Apttus_Config2__LineItem__c();
        lI.Apttus_Config2__LineType__c = 'Product/Service';
        lI.Apttus_Config2__ChargeType__c = 'Sales Price';
        lI.Apttus_Config2__ItemSequence__c = 1;
        lI.Apttus_Config2__LineNumber__c = 1;
        lI.Apttus_Config2__ConfigurationId__c = ProductConfiguration.Id;
        lI.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        Insert lI;
        
        PageReference  pref = Page.APTS_AssetChanges;
        pref.getParameters().put('flow','NG Default');
        pref.getParameters().put('id',ProductConfiguration.Id);
        Test.setCurrentPage(pref);
        
        
        APTS_AssetChangeController AssetChange = new APTS_AssetChangeController();
        
        Test.startTest();
        //AssetChange.sFlow = 'RegisterMachineFlow1';
        AssetChange.updateLineItem();
        AssetChange.goBack();
        Test.stopTest();
    }
    
    @isTest
    private static void AssetChangeControllerUtil1(){
        
        Id recordtype = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(System.Label.APTS_Standard_Deal).getRecordTypeId();
        
        Account testAccount = APTS_TestUtils.createGrandParentAccount();
        testAccount.Name = 'Test Account';
        Database.Insert(testAccount);
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.insert(priceList, false);
        
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = testAccount.Id, 
                        Name = 'New Agreement',RecordTypeId = recordtype,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Signatures', Apttus__Status__c = 'Fully Signed');
        Database.Insert(testAgreement);
        
        Apttus_Config2__ProductConfiguration__c pC = new Apttus_Config2__ProductConfiguration__c();
        pC.Name = 'Product Config - Standard Deal';
        pC.Apttus_Config2__Status__c = 'Finalized';
        insert pC;
        
        Apttus_Config2__ProductConfiguration__c ProductConfiguration = APTS_TestDataFactory.createProductConfig(testAgreement);
        Database.insert(ProductConfiguration);
        
        /*Apttus_Config2__ProductAttributeValue__c  pA = new Apttus_Config2__ProductAttributeValue__c ();
        pA.APTS_Type_of_contract__c = 'Rent';
        pA.*/
        
        PhysicalAsset__c testphAsset = APTS_TestUtils.createPhysicalAsset();
        testphAsset.Name = 'Test Option Physical Asset';
        //testphAsset.RecordTypeId = optionRecId;
        testphAsset.SerialNumber__c = 'RJ213456234';
        testphAsset.PONumberServices__c = '123567';
        testphAsset.PONumberRequiredServices__c = 'Yes';
        testphAsset.PONumberTypeServices__c = 'Variable';
        insert testphAsset;
        
        Apttus_Config2__AssetLineItem__c tstAsset1 = new Apttus_Config2__AssetLineItem__c();
        tstAsset1.Apttus_Config2__LineNumber__c = 1;
        tstAsset1.Apttus_Config2__PrimaryLineNumber__c = 1;
        tstAsset1.Apttus_Config2__NetPrice__c = 100;
        tstAsset1.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset1.APTS_Old_Net_Price__c = 100;
        tstAsset1.Apttus_Config2__HasOptions__c = true;
        tstAsset1.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset1.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset1.APTS_Type_Of_Contract__c = 'Sales';
        tstAsset1.Apttus_Config2__IsPrimaryLine__c = true;
        tstAsset1.APTS_Is_Primary_L1_Line__c = false;
        tstAsset1.Apttus_Config2__HasOptions__c = true;
        tstAsset1.Apttus_Config2__EndDate__c = Date.today().addDays(100);
        insert tstAsset1;
        
        Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
        tstAsset.Apttus_Config2__LineNumber__c = 1;
        tstAsset.Apttus_Config2__PrimaryLineNumber__c = 1;
        tstAsset.Apttus_Config2__NetPrice__c = 100;
        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.APTS_Old_Net_Price__c = 100;
        tstAsset.Apttus_Config2__HasOptions__c = true;
        tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset.APTS_Type_Of_Contract__c = 'Sales';
        tstAsset.Apttus_Config2__IsPrimaryLine__c = true;
        tstAsset.APTS_Is_Primary_L1_Line__c = false;
        tstAsset.Apttus_Config2__HasOptions__c = true;
        tstAsset.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
        tstAsset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
        insert tstAsset;
        
        Apttus_Config2__LineItem__c lI = new Apttus_Config2__LineItem__c();
        lI.Apttus_Config2__LineType__c = 'Product/Service';
        lI.Apttus_Config2__ChargeType__c = 'Sales Price';
        lI.Apttus_Config2__ItemSequence__c = 1;
        lI.Apttus_Config2__LineNumber__c = 1;
        lI.Apttus_Config2__ConfigurationId__c = ProductConfiguration.Id;
        lI.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        Insert lI;
        
        PageReference  pref = Page.APTS_AssetChanges;
        pref.getParameters().put('flow','RegisterMachineFlow');
        pref.getParameters().put('id',ProductConfiguration.Id);
        Test.setCurrentPage(pref);
        
        
        APTS_AssetChangeController AssetChange = new APTS_AssetChangeController();
        
        Test.startTest();
        //AssetChange.sFlow = 'RegisterMachineFlow1';
        AssetChange.updateLineItem();
        AssetChange.goBack();
        Test.stopTest();
    }
}