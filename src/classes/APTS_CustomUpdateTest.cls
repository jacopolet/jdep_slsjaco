/**************************************************************
* @Author: jason.e.mactal
* @Company: Accenture
* @Description: Test class for APTS_CustomUpdate
* @Created Date: May 23, 2018
* @Revisions:
*      <Name>              <Date>          <Description>
*      jason.e.mactal      Sep 06, 2018    Initial Version
* 
*************************************************************/
@isTest

private class APTS_CustomUpdateTest {
    
    private static final String NGDEFAULT = 'NGDefault';
    public static List<Apttus_Config2__LineItem__c> lstLineItem = new List<Apttus_Config2__LineItem__c>();
    public static List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustmentLI = new List<Apttus_Config2__AdjustmentLineItem__c>();
    
    @testSetup
    static void testSetup() {
        
        User testUser = APTS_TestDataFactory.createUser();
        testUser.Email = 'testuser123@jdecoffee.com';
        system.runAs(testUser){
            
            Apttus_Config2__ConfigFlow__c oFlow = new Apttus_Config2__ConfigFlow__c();
            oFlow.Name = NGDEFAULT;
            oFLow.Apttus_Config2__AssetsPage__c = 'Apttus_Config2__Cart';
            oFLow.Apttus_Config2__CartPage__c = 'Apttus_Config2__Cart';
            oFLow.Apttus_Config2__CatalogPage__c = 'Apttus_Config2__Cart';
            oFLow.Apttus_Config2__OptionsPage__c = 'Apttus_Config2__Cart';
            oFLow.Apttus_Config2__ProductAttributeDetailPage__c = 'Apttus_Config2__Cart';
            insert oFlow;
            
            Account oAcc = APTS_TestDataFactory.createAccount('Test Account');
            insert oAcc;
            
            Apttus__APTS_Agreement__c oAgg = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
            insert oAgg;
            
        }
    }
    
    private static testMethod void customUpdateTestnCER() {
     //User oTestUser = APTS_TestFacade.createTestUser();
        
    
    String STANDARD_DEAL = 'Standard Deal';
        String BILLING_PREFRENCE = 'JDETestPrefrence';
        String ACCOUNT_NAME = 'JDETestAccount';
        String CONTACT_NUMBER = '1010101011';
        String OPPORTUNITY_NAME = 'JDETestOpportunity';
        String PRICELIST_NAME = 'JDETest Price List';
        String PROD_FAMILY_MACHINE = 'MA';
        String PROD_CONFIG_BUNDLE = 'Bundle';
        String PROD_CONFIG_OPTION = 'Option';
        String PRODUCT_SERVICE = 'PRODUCT/SERVICE';
        String BILLING_FREQ_MONTHLY = 'Monthly';
        String BILLING_TYPE_ADVANCED = 'Bill In Advance';
        String PRICE_TYPE_ONETIME = 'One Time';
        String PRICE_UNIT_PER = 'Per Unit';
        String PRICE_UNIT_EACH = 'Each';
        String ORDER_TYPE_MACHINE_ORDER = 'Machine Order';
        String ORDER_SUBTYPE_TECHNICAL_SWAP = 'Technical Swap';
        String COMMERCIAL_SWAP = 'Commercial Swap';
        String PAGE_PARAM_ID = 'id';
        String PAGE_PARAM_FIRST_PARAM = 'firstParam';
        String AGREEMENT_ACTIVATED = 'Activated';
        String AGREEMENT_IN_EFFECT = 'In Effect';

        User oTestUser = APTS_TestFacade.getTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence(BILLING_PREFRENCE);
        Database.insert(billPref, FALSE);

        Account acc = APTS_TestDataFactory.createAccount('testAccount');
        Database.insert(acc);

        Contact con = APTS_TestDataFactory.createContact(acc, 'testContact');
        con.Email = 'test@test.com';
        Database.insert(con);

        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList('testPriceList');
        Database.insert(pricelist);

        Product2 prod1 = APTS_TestDataFactory.createProduct(ACCOUNT_NAME, ACCOUNT_NAME, PROD_FAMILY_MACHINE, PROD_CONFIG_BUNDLE, FALSE, TRUE);
        Database.insert(prod1);

        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(pricelist.Id, prod1.Id);
        pli1.Apttus_Config2__ChargeType__c = 'Additional Service Fee';
        Database.insert(pli1);

        Apttus__APTS_Agreement__c oAgreement = APTS_TestDataFactory.createAgreement(con.id, pricelist.id, acc.id, 'Standard Deal');
        Database.insert(oAgreement);

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(oAgreement);
        Database.insert(oProductConfiguration);

        Apttus_Config2__LineItem__c lineItem = APTS_TestDataFactory.createLineItem(oProductConfiguration, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, PRODUCT_SERVICE, billPref.Id, BILLING_FREQ_MONTHLY, BILLING_TYPE_ADVANCED, PRICE_TYPE_ONETIME, PRICE_UNIT_PER, PRICE_UNIT_EACH, 200, 10);
        lineItem.Apttus_Config2__LineType__c = 'Option';
        Database.insert(lineItem);
        
       

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
          oOrder.APTS_Order_Type__c  = System.Label.APTS_Order_Type_Operating;
          oOrder.APTS_Order_Sub_Type__c= System.Label.APTS_Order_Type_Digital;
          oOrder.APTS_Source_Order_Number__c = '8909';
          Database.update(oOrder);

        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        oProductConfiguration.Apttus_Config2__Status__c = 'Finalized';
        oProductConfiguration.Apttus_Config2__OrderId__c = oOrder.id;
        Database.update(oProductConfiguration);


 Apttus_Config2__LineItem__c lineItem11 = APTS_TestDataFactory.createLineItem(oProductConfiguration, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, PRODUCT_SERVICE, billPref.Id, BILLING_FREQ_MONTHLY, BILLING_TYPE_ADVANCED, PRICE_TYPE_ONETIME, PRICE_UNIT_PER, PRICE_UNIT_EACH, 200, 10);
        lineItem11.Apttus_Config2__LineType__c = 'Option';
        Database.insert(lineItem11);

        oAgreement.APTS_Is_Amended_for_Indexation__c = true;
        Database.update(oAgreement);

        Apttus_Config2__ProductAttributeValue__c pav = new Apttus_Config2__ProductAttributeValue__c();
        pav.Apttus_Config2__LineItemId__c = lineItem.id;
        pav.APTS_Type_of_contract__c = 'Consumption';
        Database.insert(pav);

        List<APTS_Contract_Entitlement_Repository__c> repoList = new List<APTS_Contract_Entitlement_Repository__c>();

        APTS_Contract_Entitlement_Repository__c repo1 = new APTS_Contract_Entitlement_Repository__c();
        repo1.APTS_Adjustment_Type__c = 'PPR';
        repo1.APTS_Adjustment_Value__c = 20.0;
        repo1.APTS_Agreement_Type__c = 'Standard Deal';
        repo1.APTS_Exclusion_Exception_Available__c = false;
        repo1.APTS_Is_Pending__c = false;
        repo1.APTS_Max_Volume__c = false;
        repo1.APTS_Product__c = prod1.Id;
        repoList.add(repo1);

        APTS_Contract_Entitlement_Repository__c repo2 = new APTS_Contract_Entitlement_Repository__c();
        repo2.APTS_Adjustment_Type__c = 'TPR';
        repo2.APTS_Adjustment_Value__c = 20.0;
        repo2.APTS_Agreement_Type__c = 'Standard Deal';
        repo2.APTS_Exclusion_Exception_Available__c = false;
        repo2.APTS_Is_Pending__c = false;
        repo2.APTS_Max_Volume__c = false;
        repo2.APTS_Product__c = prod1.Id;
        repoList.add(repo2);

        APTS_Contract_Entitlement_Repository__c repo3 = new APTS_Contract_Entitlement_Repository__c();
        repo3.APTS_Adjustment_Type__c = 'EFF';
        repo3.APTS_Adjustment_Value__c = 20.0;
        repo3.APTS_Agreement_Type__c = 'Standard Deal';
        repo3.APTS_Exclusion_Exception_Available__c = false;
        repo3.APTS_Is_Pending__c = false;
        repo3.APTS_Max_Volume__c = false;
        repo3.APTS_Product__c = prod1.Id;
        repoList.add(repo3);

        Database.insert(repoList, false);
         lineItem.Apttus_Config2__BasePriceOverride__c = 100;
        lineItem.Apttus_Config2__ChargeType__c = APTS_CPQConstants.SALES_PRICE;
        lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
        Database.update(lineItem);
        
          lineItem11.Apttus_Config2__BasePriceOverride__c = 100;
        lineItem11.Apttus_Config2__ChargeType__c = APTS_CPQConstants.SALES_PRICE;
        lineItem11.Apttus_Config2__AttributeValueId__c = pav.id;        
        Database.update(lineItem11);
       
        

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Contract__c = oRelatedAgreement.Apttus__APTS_Contract_From__c;
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_AdjustmentLineItemCallback oCallback = new APTS_AdjustmentLineItemCallback();

        Map<String, Apttus_Config2__AdjustmentLineItem__c> ceradjustmentMap = oCallback.processcerdata(lineItem, repoList, false);
        Map<String, Apttus_Config2__AdjustmentLineItem__c> ceradjustmentMap1 = oCallback.processcerdata(lineItem, repoList);
        System.debug('Before Calling');
        lstLineItem.add(lineItem);
        lstLineItem.add(lineItem11);
        
        
        Test.startTest();
        user testUser = [SELECT Id FROM USER WHERE Email = 'testuser123@jdecoffee.com'];
        Apttus__APTS_Agreement__c oAgg = [SELECT Id, Apttus__Account__c, Apttus_CMConfig__PriceListId__c, Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c FROM Apttus__APTS_Agreement__c LIMIT 1];
        
        Apttus_Config2__ProductConfiguration__c oConfig = APTS_TestDataFactory.createProductConfig(oAgg);
        oConfig.APTS_Flow__c = NGDEFAULT;
        
        Apttus_Config2__TempObject__c oTempObject = new Apttus_Config2__TempObject__c();
        oTempObject.Apttus_Config2__Data__c = '<?xml version="1.0" encoding="UTF-8"?> <ConfigRequest> <Params> <Param> <Name>flow</Name> <Value>' + NGDEFAULT + '</Value> </Param> </Params> </ConfigRequest>';
        oTempObject.Apttus_Config2__ConfigurationId__c = oConfig.Id;
        
        system.runAs(testUser){
            //Test.startTest();
            
            insert oConfig;
            insert oTempObject;
            
            PageReference pref;
            pref = Page.Apttus_Config2__Cart;
            //pref.getParameters().put('id', oConfig.Id);//oProductConfiguration 
            pref.getParameters().put('id', oProductConfiguration.Id);
            pref.getParameters().put('flow',NGDEFAULT);       
            pref.getParameters().put('configRequestId', oTempObject.Id);  
            Test.setCurrentPage(pref);
            createAdjustmentLineItem(lstLineItem);           
          
        }
        Apttus_Config2__ProductConfiguration__c checkIsPricePending = [SELECT Id, Apttus_Config2__IsPricePending__c FROM Apttus_Config2__ProductConfiguration__c WHERE Id =:oConfig.id];
        //system.assert(checkIsPricePending.Apttus_Config2__IsPricePending__c);
    }
    
    
      private static testMethod void customUpdateTest() {
     //User oTestUser = APTS_TestFacade.createTestUser();
        
    
    String STANDARD_DEAL = 'Standard Deal';
        String BILLING_PREFRENCE = 'JDETestPrefrence';
        String ACCOUNT_NAME = 'JDETestAccount';
        String CONTACT_NUMBER = '1010101011';
        String OPPORTUNITY_NAME = 'JDETestOpportunity';
        String PRICELIST_NAME = 'JDETest Price List';
        String PROD_FAMILY_MACHINE = 'MA';
        String PROD_CONFIG_BUNDLE = 'Bundle';
        String PROD_CONFIG_OPTION = 'Option';
        String PRODUCT_SERVICE = 'PRODUCT/SERVICE';
        String BILLING_FREQ_MONTHLY = 'Monthly';
        String BILLING_TYPE_ADVANCED = 'Bill In Advance';
        String PRICE_TYPE_ONETIME = 'One Time';
        String PRICE_UNIT_PER = 'Per Unit';
        String PRICE_UNIT_EACH = 'Each';
        String ORDER_TYPE_MACHINE_ORDER = 'Machine Order';
        String ORDER_SUBTYPE_TECHNICAL_SWAP = 'Technical Swap';
        String COMMERCIAL_SWAP = 'Commercial Swap';
        String PAGE_PARAM_ID = 'id';
        String PAGE_PARAM_FIRST_PARAM = 'firstParam';
        String AGREEMENT_ACTIVATED = 'Activated';
        String AGREEMENT_IN_EFFECT = 'In Effect';

        User oTestUser = APTS_TestFacade.getTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence(BILLING_PREFRENCE);
        Database.insert(billPref, FALSE);

        Account acc = APTS_TestDataFactory.createAccount('testAccount');
        Database.insert(acc);

        Contact con = APTS_TestDataFactory.createContact(acc, 'testContact');
        con.Email = 'test@test.com';
        Database.insert(con);

        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList('testPriceList');
        Database.insert(pricelist);

        Product2 prod1 = APTS_TestDataFactory.createProduct(ACCOUNT_NAME, ACCOUNT_NAME, PROD_FAMILY_MACHINE, PROD_CONFIG_BUNDLE, FALSE, TRUE);
        Database.insert(prod1);

        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(pricelist.Id, prod1.Id);
        pli1.Apttus_Config2__ChargeType__c = 'Additional Service Fee';
        Database.insert(pli1);

        Apttus__APTS_Agreement__c oAgreement = APTS_TestDataFactory.createAgreement(con.id, pricelist.id, acc.id, 'Standard Deal');
        Database.insert(oAgreement);

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(oAgreement);
        Database.insert(oProductConfiguration);

        Apttus_Config2__LineItem__c lineItem = APTS_TestDataFactory.createLineItem(oProductConfiguration, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, PRODUCT_SERVICE, billPref.Id, BILLING_FREQ_MONTHLY, BILLING_TYPE_ADVANCED, PRICE_TYPE_ONETIME, PRICE_UNIT_PER, PRICE_UNIT_EACH, 200, 10);
        lineItem.Apttus_Config2__LineType__c = 'Option';
        Database.insert(lineItem);
        
       

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
          oOrder.APTS_Order_Type__c  = System.Label.APTS_Order_Type_Operating;
          oOrder.APTS_Order_Sub_Type__c= System.Label.APTS_Order_Type_Digital;
          oOrder.APTS_Source_Order_Number__c = '8909';
          Database.update(oOrder);

        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        oProductConfiguration.Apttus_Config2__Status__c = 'Finalized';
        oProductConfiguration.Apttus_Config2__OrderId__c = oOrder.id;
        Database.update(oProductConfiguration);


 Apttus_Config2__LineItem__c lineItem11 = APTS_TestDataFactory.createLineItem(oProductConfiguration, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, PRODUCT_SERVICE, billPref.Id, BILLING_FREQ_MONTHLY, BILLING_TYPE_ADVANCED, PRICE_TYPE_ONETIME, PRICE_UNIT_PER, PRICE_UNIT_EACH, 200, 10);
        lineItem11.Apttus_Config2__LineType__c = 'Option';
        Database.insert(lineItem11);

        oAgreement.APTS_Is_Amended_for_Indexation__c = true;
        Database.update(oAgreement);

        Apttus_Config2__ProductAttributeValue__c pav = new Apttus_Config2__ProductAttributeValue__c();
        pav.Apttus_Config2__LineItemId__c = lineItem.id;
        pav.APTS_Type_of_contract__c = 'Consumption';
        Database.insert(pav);

        List<APTS_Contract_Entitlement_Repository__c> repoList = new List<APTS_Contract_Entitlement_Repository__c>();

        APTS_Contract_Entitlement_Repository__c repo1 = new APTS_Contract_Entitlement_Repository__c();
        repo1.APTS_Adjustment_Type__c = 'PPR';
        repo1.APTS_Adjustment_Value__c = 20.0;
        repo1.APTS_Agreement_Type__c = 'Standard Deal';
        repo1.APTS_Exclusion_Exception_Available__c = false;
        repo1.APTS_Is_Pending__c = false;
        repo1.APTS_Max_Volume__c = false;
        repo1.APTS_Product__c = prod1.Id;
        repoList.add(repo1);

        APTS_Contract_Entitlement_Repository__c repo2 = new APTS_Contract_Entitlement_Repository__c();
        repo2.APTS_Adjustment_Type__c = 'TPR';
        repo2.APTS_Adjustment_Value__c = 20.0;
        repo2.APTS_Agreement_Type__c = 'Standard Deal';
        repo2.APTS_Exclusion_Exception_Available__c = false;
        repo2.APTS_Is_Pending__c = false;
        repo2.APTS_Max_Volume__c = false;
        repo2.APTS_Product__c = prod1.Id;
        repoList.add(repo2);

        APTS_Contract_Entitlement_Repository__c repo3 = new APTS_Contract_Entitlement_Repository__c();
        repo3.APTS_Adjustment_Type__c = 'EFF';
        repo3.APTS_Adjustment_Value__c = 20.0;
        repo3.APTS_Agreement_Type__c = 'Standard Deal';
        repo3.APTS_Exclusion_Exception_Available__c = false;
        repo3.APTS_Is_Pending__c = false;
        repo3.APTS_Max_Volume__c = false;
        repo3.APTS_Product__c = prod1.Id;
        repoList.add(repo3);

        Database.insert(repoList, false);
         lineItem.Apttus_Config2__BasePriceOverride__c = 100;
        lineItem.Apttus_Config2__ChargeType__c = APTS_CPQConstants.SALES_PRICE;
        lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
        Database.update(lineItem);
        
          lineItem11.Apttus_Config2__BasePriceOverride__c = 100;
        lineItem11.Apttus_Config2__ChargeType__c = APTS_CPQConstants.SALES_PRICE;
        lineItem11.Apttus_Config2__AttributeValueId__c = pav.id;        
        Database.update(lineItem11);
       
        

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Contract__c = oRelatedAgreement.Apttus__APTS_Contract_From__c;
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_AdjustmentLineItemCallback oCallback = new APTS_AdjustmentLineItemCallback();

        Map<String, Apttus_Config2__AdjustmentLineItem__c> ceradjustmentMap = oCallback.processcerdata(lineItem, repoList, false);
        Map<String, Apttus_Config2__AdjustmentLineItem__c> ceradjustmentMap1 = oCallback.processcerdata(lineItem, repoList);
        System.debug('Before Calling');
        lstLineItem.add(lineItem);
        lstLineItem.add(lineItem11);
        
        
        Test.startTest();
        user testUser = [SELECT Id FROM USER WHERE Email = 'testuser123@jdecoffee.com'];
        Apttus__APTS_Agreement__c oAgg = [SELECT Id, Apttus__Account__c, Apttus_CMConfig__PriceListId__c, Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c FROM Apttus__APTS_Agreement__c LIMIT 1];
        
        Apttus_Config2__ProductConfiguration__c oConfig = APTS_TestDataFactory.createProductConfig(oAgg);
        oConfig.APTS_Flow__c = NGDEFAULT;
        
        Apttus_Config2__TempObject__c oTempObject = new Apttus_Config2__TempObject__c();
        oTempObject.Apttus_Config2__Data__c = '<?xml version="1.0" encoding="UTF-8"?> <ConfigRequest> <Params> <Param> <Name>flow</Name> <Value>' + NGDEFAULT + '</Value> </Param> </Params> </ConfigRequest>';
        oTempObject.Apttus_Config2__ConfigurationId__c = oConfig.Id;
        
        system.runAs(testUser){
            //Test.startTest();
            
            insert oConfig;
            insert oTempObject;
            
            PageReference pref;
            pref = Page.Apttus_Config2__Cart;
            //pref.getParameters().put('id', oConfig.Id);//oProductConfiguration 
            pref.getParameters().put('id', oProductConfiguration.Id);
            pref.getParameters().put('flow',NGDEFAULT);       
            pref.getParameters().put('configRequestId', oTempObject.Id);  
            Test.setCurrentPage(pref);
                   
           deleteAdjustmentLineItem(lstLineItem);
        }
        Apttus_Config2__ProductConfiguration__c checkIsPricePending = [SELECT Id, Apttus_Config2__IsPricePending__c FROM Apttus_Config2__ProductConfiguration__c WHERE Id =:oConfig.id];
        //system.assert(checkIsPricePending.Apttus_Config2__IsPricePending__c);
    }
    //Delete Adjustment LineItem  
      
public static void deleteAdjustmentLineItem(List<Apttus_Config2__LineItem__c> lstLineItem){
List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustmentLI = new List<Apttus_Config2__AdjustmentLineItem__c>();
      
       for(Apttus_Config2__LineItem__c instLineItem: lstLineItem)
        { System.debug('Lavanya DELTE'+instLineItem.Apttus_Config2__AdjustmentLineItems__r);
            for(Apttus_Config2__AdjustmentLineItem__c instAdj : instLineItem.Apttus_Config2__AdjustmentLineItems__r)
            {
               lstAdjustmentLI.add(instAdj) ;
               System.debug('Lineitem Delete->'+instLineItem.id+'Apttus_Config2__AdjustmentLineItem__c->'+instAdj.ID);
            }
        }
     
        delete lstAdjustmentLI;
            APTS_CustomUpdate customUpdate = new APTS_CustomUpdate();            
            PageReference resultAPTS_CustomValidate = customUpdate.APTS_CustomValidate1();
            PageReference resultCustomUpdate = customUpdate.APTS_CustomUpdate();

             System.debug('Lavanya RESULT for Delete'+resultCustomUpdate);
    }   


// Create Adjustment LineItem   
    public static void createAdjustmentLineItem(List<Apttus_Config2__LineItem__c> lstLineItem)
    {   
    List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustmentLI = new List<Apttus_Config2__AdjustmentLineItem__c>();
            
             for(Apttus_Config2__LineItem__c instLineItem: lstLineItem)
            {
              Apttus_Config2__AdjustmentLineItem__c  adjLineItem= new Apttus_Config2__AdjustmentLineItem__c();    
              adjLineItem.isCustom__c = true;
              adjLineItem.Apttus_Config2__AdjustmentType__c = APTS_CPQConstants.DISCOUNT;
              adjLineItem.Apttus_Config2__AdjustmentAmount__c = 100;
              adjLineItem.Apttus_Config2__LineItemId__c = instLineItem.id;      
              adjLineItem.Apttus_Config2__LineNumber__c =1;      
              //adjLineItem.Apttus_Config2__LineType__c ='Manual';
              //adjLineItem.APTS_Discount_Type__c='Manual';
              adjLineItem.Apttus_Config2__Type__c = APTS_CPQConstants.LABEL_TPR;
              adjLineItem.Apttus_Config2__SubType__c = APTS_CPQConstants.LABEL_ZX10;
              adjLineItem.Apttus_Config2__Bucket__c = APTS_CPQConstants.LABEL_BUCKET3;     
              adjLineItem.Apttus_Config2__AdjustmentAppliesTo__c=APTS_CPQConstants.LABEL_BUCKET2;
              lstAdjustmentLI.add(adjLineItem) ; 
            
            }
            Database.insert(lstAdjustmentLI,false) ;
            for(Apttus_Config2__AdjustmentLineItem__c instADJLI : lstAdjustmentLI)
            {
                System.debug('Lineitem create->'+instADJLI.Apttus_Config2__LineItemId__c+'ADJLI->'+instADJLI.id);
            }

            APTS_CustomUpdate customUpdate = new APTS_CustomUpdate();            
            PageReference resultAPTS_CustomValidate = customUpdate.APTS_CustomValidate1();
            PageReference resultCustomUpdate = customUpdate.APTS_CustomUpdate();

            System.debug('Lavanya RESULT for create'+resultCustomUpdate);
            
          
    }
    private static testMethod void noCartTest() {
        user testUser = [SELECT Id FROM USER WHERE Email = 'testuser123@jdecoffee.com'];
        
        try{
        system.runAs(testUser){
            Test.startTest();

            APTS_CustomUpdate customUpdate = new APTS_CustomUpdate();
            
            PageReference resultAPTS_CustomValidate2 = customUpdate.APTS_CustomValidate1();
            PageReference resultCustomUpdate2 = customUpdate.APTS_CustomUpdate();
      
            Test.stopTest();
        }
        }catch(exception e){
                system.assert(e.getMessage().contains('Please create cart'));
        }
    }
}