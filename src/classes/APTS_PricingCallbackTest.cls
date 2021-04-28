/*************************************************************
@Name: APTS_PricingCallbackTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: Pricing Callback Test
@UsedBy: APTS_PricingCallback
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_PricingCallbackTest {

    @testSetup static void setupTestData() {
        
        Test.startTest();
        User otestuser = APTS_TestDataFactory.createUser();
        Database.insert(otestuser);
        test.stopTest();
        APTS_TestFacade.createMandatoryRecords(oTestUser);

        TriggerSettings__c oTriggerSettings = [SELECT APTS_Order_Trigger__c, APTS_OrderLineItemTrigger__c, APTS_Configuration_Trigger__c FROM TriggerSettings__c];
        oTriggerSettings.APTS_Order_Trigger__c = false;
        oTriggerSettings.APTS_OrderLineItemTrigger__c = false;
        oTriggerSettings.APTS_Configuration_Trigger__c = false;
        oTriggerSettings.AdjustmentLineItemTrigger__c = false;
        oTriggerSettings.AccountTrigger__c=false;
        Database.update(oTriggerSettings);

        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);

        Apttus_Config2__ConfigCustomClasses__c configCustomClassesProperty = new Apttus_Config2__ConfigCustomClasses__c();
        configCustomClassesProperty.Name = 'Config Custom Classes';
        configCustomClassesProperty.Apttus_Config2__PricingCallbackClass__c = 'APTS_PricingCallback';
        insert configCustomClassesProperty;

        Apttus_Config2__ConfigLineItemCustomFields__c  oConfigLineItemCustomFields = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomFields.Name = 'System Properties';
        oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames__c = 'APTS_ATP_Check_Status__c,Apttus_Config2__HasIncentives__c,Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,Apttus_Config2__PriceListItemId__r.APTS_Default_Selling_Uom__c,Apttus_Config2__SellingUom__c,APTS_Requested_Delivery_Date__c';
        oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c, Apttus_Config2__OptionId__r.Name';
        oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__PriceListItemId__r.APTS_Call_Out_Coverage__c, Apttus_Config2__PriceListItemId__r.APTS_Labour_Coverage__c, Apttus_Config2__PriceListItemId__r.APTS_Spare_Parts_Coverage__c';
        oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames4__c = 'Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_chk__c, Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_chk__c, Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_chk__c';
        oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames5__c = 'Apttus_Config2__NetPrice__c,Apttus_Config2__ConfigurationId__r.APTS_Max_Requested_Delivery_Date__c,APTS_Agreement__r.APTS_Agreement_Request__c, Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c';
        insert oConfigLineItemCustomFields;

        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomFields1 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomFields1.Name = 'System Properties 1';
        oConfigLineItemCustomFields1.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Requested_Installation_Date__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__LocationId__c,Apttus_Config2__LocationId__c';
        oConfigLineItemCustomFields1.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c';
        oConfigLineItemCustomFields1.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__c';
        oConfigLineItemCustomFields1.Apttus_Config2__CustomFieldNames4__c = 'Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Is_Amended_for_Indexation__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.APTS_Country__c';
        oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames5__c = 'Apttus_Config2__NetPrice__c,Apttus_Config2__ConfigurationId__r.APTS_Flow__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus_CMConfig__LocationId__c';
        insert oConfigLineItemCustomFields1;

        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomFields2 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomFields2.Name = 'System Properties 2';
        oConfigLineItemCustomFields2.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.Name,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c,APTS_Agreement__c';
        oConfigLineItemCustomFields2.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.RecordType.Name,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_Ingredients__c';
        oConfigLineItemCustomFields2.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c';
        oConfigLineItemCustomFields2.Apttus_Config2__CustomFieldNames4__c = 'Apttus_Config2__NetPrice__c, Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Duration_Months__c,Apttus_Config2__AssetLineItemId__r.APTS_Stop_RtR_Transactions_from__c';
        insert oConfigLineItemCustomFields2;
        
        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomFields3 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomFields3.Name = 'System Properties 3';
        oConfigLineItemCustomFields3.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__OrderStartDate__c';
        oConfigLineItemCustomFields3.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Location__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c, Apttus_Config2__PriceType__c';
        oConfigLineItemCustomFields3.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__ConfigurationId__r.Apttus_Config2__BillToAccountId__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Country__c';
        oConfigLineItemCustomFields3.Apttus_Config2__CustomFieldNames4__c = 'Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__PrimaryContactId__c, Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_Start_Date__c';
        insert oConfigLineItemCustomFields3;

         Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomFields4 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomFields4.Name = 'System Properties 4';
        oConfigLineItemCustomFields4.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__ProductId__r.name,APTS_is_selling_UOM_defaulted__c,Apttus_Config2__PriceListItemId__r.APTS_Default_selling_UOM__c,APTS_Agreement_Line_Item__r.Apttus_CMConfig__AutoRenew__c';
        oConfigLineItemCustomFields4.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__ConfigurationId__r.APTS_Threshold__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_End_Date__c';
        oConfigLineItemCustomFields4.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.APTS_Customer_Specific_Freight_charge__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c';
        oConfigLineItemCustomFields4.Apttus_Config2__CustomFieldNames4__c = 'Apttus_Config2__PriceListItemId__r.Apttus_Config2__PriceUom__c,Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c, APTS_Agreement_Line_Item__r.Apttus__AgreementId__c, APTS_Agreement_Line_Item__r.Apttus__AgreementId__r.Apttus__Subtype__c';
        insert oConfigLineItemCustomFields4;

        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomFields5 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomFields5.Name = 'System Properties 5';
        oConfigLineItemCustomFields5.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__ConfigurationId__r.Apttus_Config2__BillToAccountId__c,Apttus_Config2__DerivedFromId__c,APTS_List_price__c,Apttus_Config2__BillingFrequency__c,APTS_Agreement_Line_Item__r.Apttus_CMConfig__BillingFrequency__c';
        oConfigLineItemCustomFields5.Apttus_Config2__CustomFieldNames2__c = 'APTS_is_Tax_and_VAT_calculated__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Type__c,Apttus_Config2__PriceListItemId__r.APTS_Master_list_price__c';
        oConfigLineItemCustomFields5.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c';
        oConfigLineItemCustomFields5.Apttus_Config2__CustomFieldNames4__c = 'Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Version_Number__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Boomerang_Invoicing__c';
        insert oConfigLineItemCustomFields5;

        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomFields6 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomFields6.Name = 'System Properties 6';
        oConfigLineItemCustomFields6.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c';
        oConfigLineItemCustomFields6.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Account__c,APTS_Default_Selling_UOM__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__ShipToAccountId__c';
        oConfigLineItemCustomFields6.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c, APTS_Type_of_contract__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c';
        oConfigLineItemCustomFields6.Apttus_Config2__CustomFieldNames4__c = 'APTS_Is_DateDefaulted_AmendSD__c,APTS_Is_DateDefaulted_AmendED__c,APTS_Is_DateDefaulted_OriginalLI__c,APTS_Is_DateDefaulted_NewLI__c,APTS_Agreement_Line_Item__r.Apttus_CMConfig__EndDate__c';
        insert oConfigLineItemCustomFields6;

        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomField7 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomField7.Name = 'System Properties 7';
        oConfigLineItemCustomField7.Apttus_Config2__CustomFieldNames__c = 'APTS_is_selling_UOM_defaulted__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__BillingFrequency__c,APTS_Default_Billing_Frequency__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__BillToAccountId__c';
        oConfigLineItemCustomField7.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,Apttus_Config2__AssetLineItemId__r.Apttus_Config2__PriceType__c,Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AutoRenew__c';
        oConfigLineItemCustomField7.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Auto_Renewal__c,Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AssetStatus__c,Apttus_Config2__Comments__c';
        oConfigLineItemCustomField7.Apttus_Config2__CustomFieldNames4__c = 'Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Auto_renewal_staging_source_id__c,Apttus_Config2__IncentiveCode__c';
        insert oConfigLineItemCustomField7;
        
        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomField8 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomField8.Name = 'System Properties 8';
        oConfigLineItemCustomField8.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__AssetLineItemId__r.APTS_Payment_Method__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__BillToAccountId__c';
        oConfigLineItemCustomField8.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__c,Apttus_Config2__AssetLineItemId__r.Apttus_Config2__PaymentTermId__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c';
        oConfigLineItemCustomField8.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c,Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c,Apttus_Config2__AssetLineItemId__r.Apttus_Config2__ListPrice__c';
        oConfigLineItemCustomField8.Apttus_Config2__CustomFieldNames4__c = 'APTS_PrimaryL1__c,APTS_Terminated_Asset_Line__c,APTS_Serial_Number2__c,APTS_Serial_Number__c,Apttus_Config2__AssetLineItemId__c,Apttus_Config2__ProductOptionId__c,Apttus_Config2__AssetLineItemId__r.Apttus_Config2__OriginalStartDate__c';
        insert oConfigLineItemCustomField8;

        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomField9 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomField9.Name = 'System Properties 9';
        oConfigLineItemCustomField9.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__AssetLineItemId__r.Apttus_Config2__LocationId__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Sub_Type__c';
        oConfigLineItemCustomField9.Apttus_Config2__CustomFieldNames2__c = 'APTS_Billing_frequency_New_UX__c,APTS_Start_Date_New_UX__c,APTS_End_Date_New_UX__c,APTS_Auto_renew_New_UX__c';
        oConfigLineItemCustomField9.Apttus_Config2__CustomFieldNames3__c = 'APTS_Credit_Proposal_XC09_Block__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Credit_Proposal_XC09_Block__c';
        oConfigLineItemCustomField9.Apttus_Config2__CustomFieldNames4__c = 'APTS_List_Price_New_UX__c, Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Source_of_Order_Creation__c';
        insert oConfigLineItemCustomField9;
        
        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomField10 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomField10.Name = 'Freight Charges';
        oConfigLineItemCustomField10.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__PriceListId__c, Apttus_Config2__PriceListId__r.APTS_Region__c';
        oConfigLineItemCustomField10.Apttus_Config2__CustomFieldNames2__c = '';      
        insert oConfigLineItemCustomField10;

        Profile p = [SELECT Id,name FROM Profile WHERE Name = 'System Administrator' Limit 1];
        otestuser.profileid=p.id;
        otestuser.LastName='PricingCallBackUser';
        update otestuser;
    }
    
    @isTest static void test_PricingCallback() {

       User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        //System.debug('users===============>'+users);
        //Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        Apttus_Config2__ProductConfiguration__c oProductConfiguration =  [SELECT Id, APTS_Flow__c,Apttus_Config2__OrderId__r.APTS_Contract_Change__c, Apttus_Config2__OrderId__c,
                    Apttus_Config2__CartDataCache__c, Apttus_Config2__CartDataCache2__c, Apttus_Config2__PriceListId__c,
                    Apttus_Config2__EffectiveDate__c, Apttus_Config2__BusinessObjectType__c, Apttus_Config2__SummaryGroupType__c,ownerId
                    FROM Apttus_Config2__ProductConfiguration__c
                    WHERE APTS_Flow__c = : System.Label.APTS_NGStandardOrder limit 1];
        System.debug('oProductConfiguration===============>'+oProductConfiguration);
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        System.debug('lineItemList===============>'+lineItemList);
        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.BASEPRICE);

        Test.startTest();

        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
    }
    
    
    @isTest static void test_PricingCallbackWithMachine() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
       
        //Added below
        Account oAccount = APTS_TestFacade.getAccount();
        Product2 oOptionProduct = APTS_TestFacade.getOptionProduct();
        Contact oContact = APTS_TestFacade.getContact();
        Apttus_Config2__PriceList__c oPriceList = APTS_TestFacade.getPriceList();
        Apttus_Config2__PriceListItem__c oPriceListItemOption = APTS_TestFacade.getPriceListItem(oOptionProduct.Id);
        
        Apttus__APTS_Agreement__c oAgreement = APTS_TestDataFactory.createAgreement(oContact.Id, oPriceList.Id, oAccount.Id, System.Label.APTS_Standard_Deal, 'Agreement');
        oAgreement.Apttus__Status_Category__c = System.Label.APTS_In_Effect;
        oAgreement.Apttus__Status__c = System.Label.APTS_Activated;
        oAgreement.Apttus__Contract_End_Date__c = Date.Today().addDays(365);  
        oAgreement.Apttus__Version_Number__c = 24;          
        Database.insert(oAgreement);
        
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.id;
        update oProductConfiguration;
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        
        
        Apttus__AgreementLineItem__c oAgreementLineItemOption = APTS_TestDataFactory.createAgreementLineItem(oOptionProduct.Id, oAgreement.Id, oAccount.Id, oPriceListItemOption.Id);
        oAgreementLineItemOption.Apttus_CMConfig__OptionId__c = oOptionProduct.Id;
        oAgreementLineItemOption.Apttus_CMConfig__IsPrimaryLine__c = true;
        oAgreementLineItemOption.Apttus_CMConfig__LineType__c = 'Option';
         //oAgreement.Apttus__Version_Number__c = 24;   
        Database.insert(oAgreementLineItemOption, false);
        
        if(!lineItemList.isEmpty())
        {
            lineItemList[0].APTS_Agreement_Line_Item__c = oAgreementLineItemOption.id;
        }
        Database.update(lineItemList[0], false);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.BASEPRICE);

        Test.startTest();

        System.runAs(oTestUser) {

            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
        
        /*List<APTS_Error_Object__c> errorObj = [SELECT Id, APTS_Description_Of_Error__c, APTS_Error_Name__c FROM APTS_Error_Object__c];
        for(APTS_Error_Object__c err: errorObj){            
           //system.assertEquals('TEST',err.APTS_Description_Of_Error__c);
        }*/
    }
    
    
    @isTest static void test_PricingCallbackWithStandard() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        update oProductConfiguration;
        
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();

        System.runAs(oTestUser) {

           Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
        List<APTS_Error_Object__c> errorObj = [SELECT Id, APTS_Description_Of_Error__c, APTS_Error_Name__c FROM APTS_Error_Object__c];
        for(APTS_Error_Object__c err: errorObj){
        //13Aug 2018 - Aarthi - commented below
        //system.assertEquals('TEST',err.APTS_Description_Of_Error__c);
        }
    }
    
    
    @isTest static void test_PricingCallbackWithIndexation() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');
        //oProductConfiguration.Apttus_Config2__BusinessObjectType__c = APTS_CPQConstants.LABEL_AGREEEMENT;
        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oProductConfiguration);

        oAgreement.APTS_Is_Amended_for_Indexation__c = true;
        Database.update(oAgreement);

        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c = 'Coffee';
        //lineItemList.get(0).APTS_is_Tax_and_VAT_calculated__c=true;
        Database.update(lineItemList);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        List<APTS_Index_Contract__c> oIndexcontractlist = new List<APTS_Index_Contract__c>();
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Non-Standard Indexation','Technical Services'));
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Standard Indexation(incl Fixed Prices)','Technical Services'));
        Database.insert(oIndexcontractlist);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Contract__c = oRelatedAgreement.Apttus__APTS_Contract_From__c;
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();

        System.runAs(oTestUser) {

            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
    }

    @isTest static void test_PricingCallbackWithIndexation2() {

         User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oProductConfiguration);

        oAgreement.APTS_Is_Amended_for_Indexation__c = true;
        Database.update(oAgreement);

        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c = 'Coffee||';
        Database.update(lineItemList);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        List<APTS_Index_Contract__c> oIndexcontractlist = new List<APTS_Index_Contract__c>();
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Non-Standard Indexation','Products (Ingredients and &More)'));
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Standard Indexation(incl Fixed Prices)','Technical Services'));
        Database.insert(oIndexcontractlist);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Category__c = 'Products(Ingredients and &More)';
        oIndexationExecuting.APTS_Indexation_Contract__c = oRelatedAgreement.Apttus__APTS_Contract_From__c;
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();

        System.runAs(oTestUser) {

            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
    }

    @isTest static void test_PricingCallbackWithIndexation3() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oProductConfiguration);

        oAgreement.APTS_Is_Amended_for_Indexation__c = true;
        Database.update(oAgreement);

        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c = 'Services||';
        Database.update(lineItemList);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        List<APTS_Index_Contract__c> oIndexcontractlist = new List<APTS_Index_Contract__c>();
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Non-Standard Indexation','Technical Services'));
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Standard Indexation(incl Fixed Prices)','Technical Services'));
        Database.insert(oIndexcontractlist);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Category__c = 'Technical Services';
        oIndexationExecuting.APTS_Indexation_Contract__c = oRelatedAgreement.Apttus__APTS_Contract_From__c;
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();

        System.runAs(oTestUser) {

           Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
    }

    @isTest static void test_PricingCallbackWithIndexation4() {

         User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oProductConfiguration);

        oAgreement.APTS_Is_Amended_for_Indexation__c = true;
        Database.update(oAgreement);

        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c = 'Services||';
        //lineItemList.get(0).APTS_Option_Group_Text__c = 'Machine Care';
        Database.update(lineItemList);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        List<APTS_Index_Contract__c> oIndexcontractlist = new List<APTS_Index_Contract__c>();
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Non-Standard Indexation','Machine Care Service'));
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Standard Indexation(incl Fixed Prices)','Machine Care Service'));
        Database.insert(oIndexcontractlist);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Category__c = 'Machine Care Service';
        oIndexationExecuting.APTS_Indexation_Contract__c = oRelatedAgreement.Apttus__APTS_Contract_From__c;
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();

        System.runAs(oTestUser) {

            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
    }

    @isTest static void test_PricingCallbackWithIndexation5() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Account oAccount = APTS_TestFacade.getAccount();
        oAccount.billingcountry = 'Netherlands';
        Database.update(oAccount);

        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oProductConfiguration);

        oAgreement.APTS_Is_Amended_for_Indexation__c = true;
        Database.update(oAgreement);

        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c = 'Services||';
        //lineItemList.get(0).APTS_Option_Group_Text__c = 'Machine Care';
        Database.update(lineItemList);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        List<APTS_Index_Contract__c> oIndexcontractlist = new List<APTS_Index_Contract__c>();
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Standard Indexation(incl Fixed Prices)','Machine Care Service'));
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Standard Indexation(incl Fixed Prices)','Technical Services'));
        Database.insert(oIndexcontractlist);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Category__c = 'Technical Services';
        oIndexationExecuting.APTS_Indexation_Country__c = 'Netherlands';
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();

        System.runAs(oTestUser) {

            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
    }    

    @isTest static void test_PricingCallbackWithOrderIndexation() {

         User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        Database.update(oProductConfiguration);

        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        insert priceList;

        Product2 product1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines'); 
         product1.APTS_Material_Type__c = 'ZFIN';
        insert product1;

        Apttus_Config2__PriceListItem__c pricelistitem = APTS_TestUtils.createPriceListItem(priceList.id,product1.id);
        pricelistitem.Apttus_Config2__ChargeType__c = 'Sales Price';
        pricelistitem.APTS_Call_Out_Coverage__c = 10;
        pricelistitem.APTS_Labour_Coverage__c = 10;
        pricelistitem.APTS_Spare_Parts_Coverage__c = 10;
        insert pricelistitem;

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder('StandardOrder');
        oOrder.APTS_Order_Sub_Type__c = 'Indexation';
        oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oOrder);
        
       
        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
         Apttus_Config2__ClassificationHierarchy__c oClassificationHierarchy = APTS_TestFacade.getClassificationHierarchy('Machine');
            Apttus_Config2__ProductOptionComponent__c oProductOptionComponentMachine = APTS_TestFacade.getProductOptionComponent('Machine');
        lineItemList.get(0).Apttus_Config2__ClassificationId__c = oClassificationHierarchy.Id;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c= 'Services';
        lineItemList.get(0).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        lineItemList.get(0).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
        Database.update(lineItemList);

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
        
        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);
        
        Test.startTest();

        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
        }

    @isTest static void test_PricingCallbackWithOrderIndexation2() {

         User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        Database.update(oProductConfiguration);

        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        insert priceList;

        Product2 product1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines'); 
         product1.APTS_Material_Type__c = 'ZFIN';
        insert product1;

        Apttus_Config2__PriceListItem__c pricelistitem = APTS_TestUtils.createPriceListItem(priceList.id,product1.id);
        pricelistitem.Apttus_Config2__ChargeType__c = 'Sales Price';
        pricelistitem.APTS_Call_Out_Coverage__c = 10;
        pricelistitem.APTS_Labour_Coverage__c = 10;
        pricelistitem.APTS_Spare_Parts_Coverage__c = 10;
        insert pricelistitem;

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder('StandardOrder');
        oOrder.APTS_Order_Sub_Type__c = 'Indexation';
        oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oOrder);
 
        
        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
         Apttus_Config2__ClassificationHierarchy__c oClassificationHierarchy = APTS_TestFacade.getClassificationHierarchy('Machine');
            Apttus_Config2__ProductOptionComponent__c oProductOptionComponentMachine = APTS_TestFacade.getProductOptionComponent('Machine');
        lineItemList.get(0).Apttus_Config2__ClassificationId__c = oClassificationHierarchy.Id;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c= 'Services||';
        lineItemList.get(0).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        lineItemList.get(0).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
        Database.update(lineItemList);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        List<APTS_Index_Contract__c> oIndexcontractlist = new List<APTS_Index_Contract__c>();
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Non-Standard Indexation','Machine Care Service'));
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Standard Indexation(incl Fixed Prices)','Technical Services'));
        Database.insert(oIndexcontractlist);        

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Category__c = 'Machine Care Service';
        oIndexationExecuting.APTS_Indexation_Contract__c = oRelatedAgreement.Apttus__APTS_Contract_From__c;
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();

        System.runAs(oTestUser) {

            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
    }

    @isTest static void test_PricingCallbackWithOrderIndexation3() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        Database.update(oProductConfiguration);

        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        insert priceList;

        Product2 product1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines'); 
         product1.APTS_Material_Type__c = 'ZFIN';
        insert product1;

        Apttus_Config2__PriceListItem__c pricelistitem = APTS_TestUtils.createPriceListItem(priceList.id,product1.id);
        pricelistitem.Apttus_Config2__ChargeType__c = 'Sales Price';
        pricelistitem.APTS_Call_Out_Coverage__c = 10;
        pricelistitem.APTS_Labour_Coverage__c = 10;
        pricelistitem.APTS_Spare_Parts_Coverage__c = 10;
        insert pricelistitem;

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder('StandardOrder');
        oOrder.APTS_Order_Sub_Type__c = 'Indexation';
        oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oOrder);
 
        
        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
         Apttus_Config2__ClassificationHierarchy__c oClassificationHierarchy = APTS_TestFacade.getClassificationHierarchy('Machine');
            Apttus_Config2__ProductOptionComponent__c oProductOptionComponentMachine = APTS_TestFacade.getProductOptionComponent('Machine');
        lineItemList.get(0).Apttus_Config2__ClassificationId__c = oClassificationHierarchy.Id;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c= 'Services';
        lineItemList.get(0).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        lineItemList.get(0).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
        Database.update(lineItemList);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Category__c = 'Technical Services';
        oIndexationExecuting.APTS_Indexation_Contract__c = oRelatedAgreement.Apttus__APTS_Contract_From__c;
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();

        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
    }

    @isTest static void test_PricingCallbackWithOrderIndexation4() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        Database.update(oProductConfiguration);

        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        insert priceList;

        Product2 product1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines'); 
         product1.APTS_Material_Type__c = 'ZFIN';
        insert product1;

        Apttus_Config2__PriceListItem__c pricelistitem = APTS_TestUtils.createPriceListItem(priceList.id,product1.id);
        pricelistitem.Apttus_Config2__ChargeType__c = 'Sales Price';
        pricelistitem.APTS_Call_Out_Coverage__c = 10;
        pricelistitem.APTS_Labour_Coverage__c = 10;
        pricelistitem.APTS_Spare_Parts_Coverage__c = 10;
        insert pricelistitem;

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder('StandardOrder');
        oOrder.APTS_Order_Sub_Type__c = 'Indexation';
        oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oOrder);
 
        
        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
         Apttus_Config2__ClassificationHierarchy__c oClassificationHierarchy = APTS_TestFacade.getClassificationHierarchy('Machine');
            Apttus_Config2__ProductOptionComponent__c oProductOptionComponentMachine = APTS_TestFacade.getProductOptionComponent('Machine');
        lineItemList.get(0).Apttus_Config2__ClassificationId__c = oClassificationHierarchy.Id;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c= 'Services';
        lineItemList.get(0).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        lineItemList.get(0).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
        Database.update(lineItemList);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Category__c = 'Products(Ingredients and &More)';
        oIndexationExecuting.APTS_Indexation_Contract__c = oRelatedAgreement.Apttus__APTS_Contract_From__c;
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();

        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
    }


    @isTest static void test_PricingCallbackPriceModeBase() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        Database.update(oProductConfiguration);

        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        insert priceList;

        Product2 product1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines'); 
         product1.APTS_Material_Type__c = 'ZFIN';
        insert product1;

        Apttus_Config2__PriceListItem__c pricelistitem = APTS_TestUtils.createPriceListItem(priceList.id,product1.id);
        pricelistitem.Apttus_Config2__ChargeType__c = 'Sales Price';
        pricelistitem.APTS_Call_Out_Coverage__c = 10;
        pricelistitem.APTS_Labour_Coverage__c = 10;
        pricelistitem.APTS_Spare_Parts_Coverage__c = 10;
        insert pricelistitem;

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder('StandardOrder');
        oOrder.APTS_Order_Sub_Type__c = 'Indexation';
        oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        oOrder.APTS_Contract_Change__c='No';
        Database.update(oOrder);
 
        
        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
         Apttus_Config2__ClassificationHierarchy__c oClassificationHierarchy = APTS_TestFacade.getClassificationHierarchy('Machine');
            Apttus_Config2__ProductOptionComponent__c oProductOptionComponentMachine = APTS_TestFacade.getProductOptionComponent('Machine');
        lineItemList.get(0).Apttus_Config2__ClassificationId__c = oClassificationHierarchy.Id;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c= 'Services';
        lineItemList.get(0).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        lineItemList.get(0).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
        lineItemList.get(0).Apttus_Config2__PricingStatus__c='Pending';
        Database.update(lineItemList);

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

        Test.startTest();

        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
    }

    @isTest static void test_PricingCallbackWithOrderAggCountryIndexation() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        Database.update(oProductConfiguration);

        Account oAccount = APTS_TestFacade.getAccount();
        oAccount.BillingCountry = 'Netherlands';
        Database.update(oAccount);

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder('StandardOrder');
        oOrder.APTS_Order_Sub_Type__c = 'Indexation';
        oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        oOrder.APTS_Contract_Change__c='No';
        Database.update(oOrder);

        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c = 'Services';
        Database.update(lineItemList);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Indexation_Country__c = 'Netherlands';
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();

        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
    }

    @isTest static void test_PricingCallbackCalloutCoverage() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        oProductConfiguration.APTS_Flow__c = 'NGDefault';
        oAgreement.Apttus__Version_Number__c = 24; 
        
       Database.update(oAgreement ); 
       Database.update(oProductConfiguration);

        Apttus_Config2__ProductOptionComponent__c oProductOptionComponentMachine = APTS_TestFacade.getProductOptionComponent('Machine');

        Apttus_Config2__ProductAttributeValue__c pav = new Apttus_Config2__ProductAttributeValue__c();
        pav.Apttus_Config2__LineItemId__c = lineItemList.get(0).id;
        pav.APTS_Type_of_contract__c = 'Trial';
        insert pav;
        
        Apttus_Config2__ProductAttributeValue__c pav1 = new Apttus_Config2__ProductAttributeValue__c();
        pav1.Apttus_Config2__LineItemId__c = lineItemList.get(1).id;
        pav1.APTS_Type_of_contract__c = 'Sales';
        pav1.APTS_Include_Free_Service__c= 'NO';
        insert pav1;
 
        Apttus_Config2__ProductAttributeValue__c pav2 = new Apttus_Config2__ProductAttributeValue__c();
        pav2.Apttus_Config2__LineItemId__c = lineItemList.get(4).id;
        pav2.APTS_Type_of_contract__c = 'Free On Loan';
        pav2.APTS_Include_Free_Service__c= 'YES';
        insert pav2; 
         
          Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        insert priceList;
        
         Product2 product1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines'); 
         product1.APTS_Material_Type__c = 'ZFIN';
        insert product1;
        
        Product2 option1= APTS_TestUtils.createProduct('All-in Coverage-Draft', '26940992', 'Machines'); 
         option1.APTS_Material_Type__c = 'ZFIN';
        insert option1;
        
        Apttus_Config2__PriceListItem__c pricelistitem = APTS_TestUtils.createPriceListItem(priceList.id,product1.id);
        pricelistitem.Apttus_Config2__ChargeType__c = 'Sales Price';
        insert pricelistitem;
        
        
         //lineitem1.Apttus_Config2__AttributeValueId__c = pav.id;       
         //update lineitem1;

        Apttus_Config2__ClassificationHierarchy__c oClassificationHierarchy = APTS_TestFacade.getClassificationHierarchy('Machine');
        lineItemList.get(0).Apttus_Config2__ClassificationId__c = oClassificationHierarchy.Id;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c = 'Coffee';
        lineItemList.get(0).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        lineItemList.get(0).Apttus_Config2__AttributeValueId__c = pav.id; 
        lineItemList.get(0).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
        
        lineItemList.get(0).CurrencyIsoCode = 'USD';
        
         lineItemList.get(1).Apttus_Config2__ClassificationId__c = oClassificationHierarchy.Id;
        lineItemList.get(1).Apttus_Config2__ClassificationHierarchy__c = 'Coffee';
        lineItemList.get(1).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        lineItemList.get(1).Apttus_Config2__AttributeValueId__c = pav1.id; 
        lineItemList.get(1).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
        lineItemList.get(1).CurrencyIsoCode = 'USD';
        
        for(Integer i = 2;i<5;i++){
        lineItemList.get(i).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        lineItemList.get(i).Apttus_Config2__AttributeValueId__c = pav2.id; 
        lineItemList.get(i).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
        lineItemList.get(i).CurrencyIsoCode = 'USD';
        lineItemList.get(i).Apttus_Config2__ProductId__c = product1.id;
        }
        
         //lineItemList.get(4).Apttus_Config2__AttributeValueId__c = pav2.id; 
         lineItemList.get(4).Apttus_Config2__OptionId__c = option1.id;
        //lineItemList.get(3).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        //lineItemList.get(4).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        
        Database.update(lineItemList);
        
         //System.assertEquals(lineItemList.get(0).Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c,'machine');
        //System.assertEquals(lineItemList.size(),2);
        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
       // System.assertEquals(lineItemList.get(1).Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c,'');
        //APTS_PricingCallBackUtils.updateLineItemCategory(lineItemList);

        System.runAs(oTestUser) {

           Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }
//APTS_PricingCallBackUtils.updateLineItemCategory(lineItemList);
        Test.stopTest();
    }
    
    @isTest static void test_PricingCallbackCalloutCoverage1() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');
        oAgreement.Apttus__Version_Number__c = 24;          
        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        oProductConfiguration.APTS_Flow__c = 'NGDefault';
        Database.update(oAgreement ); 
        Database.update(oProductConfiguration);

        Apttus_Config2__ProductOptionComponent__c oProductOptionComponentMachine = APTS_TestFacade.getProductOptionComponent('Machine');

        Apttus_Config2__ProductAttributeValue__c pav = new Apttus_Config2__ProductAttributeValue__c();
        pav.Apttus_Config2__LineItemId__c = lineItemList.get(0).id;
        pav.APTS_Type_of_contract__c = 'Sales';
        insert pav;
        
        Apttus_Config2__ProductAttributeValue__c pav1 = new Apttus_Config2__ProductAttributeValue__c();
        pav1.Apttus_Config2__LineItemId__c = lineItemList.get(1).id;
        pav1.APTS_Type_of_contract__c = 'Sales';
        pav1.APTS_Include_Free_Service__c= 'NO';
        insert pav1;
 
        Apttus_Config2__ProductAttributeValue__c pav2 = new Apttus_Config2__ProductAttributeValue__c();
        pav2.Apttus_Config2__LineItemId__c = lineItemList.get(4).id;
        pav2.APTS_Type_of_contract__c = 'Sales';
        pav2.APTS_Include_Free_Service__c= 'YES';
        insert pav2; 
         
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        insert priceList;
        
        Product2 product1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines'); 
        product1.APTS_Material_Type__c = 'ZFIN';
        insert product1;
        
        Product2 option1= APTS_TestUtils.createProduct('All-in Coverage-Draft', '26940992', 'Machines'); 
        option1.name = 'All-in Coverage-Draft';
         option1.APTS_Material_Type__c = 'ZFIN';
        insert option1;
        
        Apttus_Config2__PriceListItem__c pricelistitem = APTS_TestUtils.createPriceListItem(priceList.id,product1.id);
        pricelistitem.Apttus_Config2__ChargeType__c = 'Sales Price';
        insert pricelistitem;
        
        
         //lineitem1.Apttus_Config2__AttributeValueId__c = pav.id;       
         //update lineitem1;

        Apttus_Config2__ClassificationHierarchy__c oClassificationHierarchy = APTS_TestFacade.getClassificationHierarchy('Machine');
        lineItemList.get(0).Apttus_Config2__ClassificationId__c = oClassificationHierarchy.Id;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c = 'Coffee';
        lineItemList.get(0).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        lineItemList.get(0).Apttus_Config2__AttributeValueId__c = pav.id; 
        lineItemList.get(0).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
        lineItemList.get(0).CurrencyIsoCode = 'USD';
        lineItemList.get(0).Apttus_Config2__ProductId__c = product1.id;
        //lineItemList.get(0).Apttus_Config2__OptionId__c = option1.id;
        
        lineItemList.get(1).Apttus_Config2__ClassificationId__c = oClassificationHierarchy.Id;
        lineItemList.get(1).Apttus_Config2__ClassificationHierarchy__c = 'Coffee';
        lineItemList.get(1).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        lineItemList.get(1).Apttus_Config2__AttributeValueId__c = pav1.id; 
        lineItemList.get(1).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
        lineItemList.get(1).CurrencyIsoCode = 'USD';
        lineItemList.get(0).Apttus_Config2__ProductId__c = product1.id;
        //lineItemList.get(1).Apttus_Config2__OptionId__c = option1.id;
        
        for(Integer i = 2;i<5;i++){
            lineItemList.get(i).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
            lineItemList.get(i).Apttus_Config2__AttributeValueId__c = pav2.id; 
            lineItemList.get(i).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
            lineItemList.get(i).CurrencyIsoCode = 'USD';
            lineItemList.get(i).Apttus_Config2__ProductId__c = product1.id;
            //lineItemList.get(i).Apttus_Config2__OptionId__c = option1.id;
        }
        
         //lineItemList.get(4).Apttus_Config2__AttributeValueId__c = pav2.id; 
         
        //lineItemList.get(3).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        //lineItemList.get(4).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        
        Database.update(lineItemList);
        
        //System.assertEquals(lineItemList.get(0).Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c,'machine');
        //System.assertEquals(lineItemList.size(),2);
        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
       // System.assertEquals(lineItemList.get(1).Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c,'');
        //APTS_PricingCallBackUtils.updateLineItemCategory(lineItemList);

        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }
//APTS_PricingCallBackUtils.updateLineItemCategory(lineItemList);
    Test.stopTest();
    }
    
    @isTest static void test_PricingCallbackCalloutCoverage2() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');
        oAgreement.Apttus__Version_Number__c = 24;  
        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        oProductConfiguration.APTS_Flow__c = 'NGDefault';
        Database.update(oAgreement ); 
        Database.update(oProductConfiguration);

        Apttus_Config2__ProductOptionComponent__c oProductOptionComponentMachine = APTS_TestFacade.getProductOptionComponent('Machine');

        Apttus_Config2__ProductAttributeValue__c pav = new Apttus_Config2__ProductAttributeValue__c();
        pav.Apttus_Config2__LineItemId__c = lineItemList.get(0).id;
        pav.APTS_Type_of_contract__c = 'Sales';
        insert pav;
        
        
         
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        insert priceList;
        
        Product2 product1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines'); 
        product1.APTS_Material_Type__c = 'ZFIN';
        insert product1;
        
        Product2 option1= APTS_TestUtils.createProduct('All-in Coverage-Draft', '26940992', 'Machines'); 
         option1.APTS_Material_Type__c = 'ZFIN';
        insert option1;
        
        Apttus_Config2__PriceListItem__c pricelistitem = APTS_TestUtils.createPriceListItem(priceList.id,product1.id);
        pricelistitem.Apttus_Config2__ChargeType__c = 'Sales Price';
        insert pricelistitem;
        
        
         //lineitem1.Apttus_Config2__AttributeValueId__c = pav.id;       
         //update lineitem1;

        Apttus_Config2__ClassificationHierarchy__c oClassificationHierarchy = APTS_TestFacade.getClassificationHierarchy('Machine');
        /*lineItemList.get(0).Apttus_Config2__ClassificationId__c = oClassificationHierarchy.Id;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c = 'Coffee';
        lineItemList.get(0).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        lineItemList.get(0).Apttus_Config2__AttributeValueId__c = pav.id; 
        lineItemList.get(0).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
        lineItemList.get(0).CurrencyIsoCode = 'USD';
        lineItemList.get(0).Apttus_Config2__OptionId__c = option1.id;
        
         lineItemList.get(1).Apttus_Config2__ClassificationId__c = oClassificationHierarchy.Id;
        lineItemList.get(1).Apttus_Config2__ClassificationHierarchy__c = 'Coffee';
        lineItemList.get(1).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        lineItemList.get(1).Apttus_Config2__AttributeValueId__c = pav1.id; 
        lineItemList.get(1).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
        lineItemList.get(1).CurrencyIsoCode = 'USD';
        lineItemList.get(1).Apttus_Config2__OptionId__c = option1.id;*/
        
        Account oAccount = APTS_TestFacade.getAccount();
        oAccount.BillingCountry = 'Netherlands';
        Database.update(oAccount);
        Apttus_Config2__AccountLocation__c al = APTS_TestUtils.createAccountLocation(oAccount.id);
        insert al;
        lineItemList.get(1).Apttus_Config2__OptionId__c = option1.id;
        for(Integer i = 0;i<5;i++){
            lineItemList.get(0).Apttus_Config2__ClassificationId__c = oClassificationHierarchy.Id;
            lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c = 'Coffee';
            lineItemList.get(0).Apttus_Config2__LocationId__c =al.id;
            lineItemList.get(i).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
            lineItemList.get(i).Apttus_Config2__AttributeValueId__c = pav.id; 
            lineItemList.get(i).Apttus_Config2__PriceListItemId__c = pricelistitem.id;
            lineItemList.get(i).CurrencyIsoCode = 'USD';
            lineItemList.get(i).Apttus_Config2__ProductId__c = product1.id;
            lineItemList.get(i).Apttus_Config2__OptionId__c = option1.id;
        }
        
        //lineItemList.get(4).Apttus_Config2__AttributeValueId__c = pav2.id; 
         
        //lineItemList.get(3).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        //lineItemList.get(4).Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
        
        Database.update(lineItemList);
        
        for(Apttus_Config2__LineItem__c linItem : lineItemList)
        {
            System.assertNOTEquals(linItem.Apttus_Config2__OptionId__c ,'');
        }
        
         //System.assertEquals(lineItemList.get(0).Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c,'machine');
        //System.assertEquals(lineItemList.size(),2);
        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
       // System.assertEquals(lineItemList.get(1).Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c,'');
        //APTS_PricingCallBackUtils.updateLineItemCategory(lineItemList);
        Apttus_Config2.LineItem lineItemMO; 
        //new APTS_PricingCallBack().onPriceItemSet(pricelistitem ,lineItemMO);
        APTS_PricingCallBackUtils.getBiggestRequestedDeliveryDate(oProductConfiguration.id,Date.today());
        APTS_PricingCallBackUtils.setRequestedDeliveryDate(lineItemList.get(0),System.Label.APTS_NGStandardOrder,Date.today());
        APTS_PricingCallBackUtils.setRequestedInstallationDate(lineItemList.get(0),System.Label.APTS_NGStandardOrder,Date.today());
        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }
        //APTS_PricingCallBackUtils.updateLineItemCategory(lineItemList);
        Test.stopTest();
    }
    @isTest static void test_PricingCallbackFreightcharges() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = [
                    SELECT Id, APTS_Flow__c, Apttus_Config2__OrderId__c,Apttus_Config2__BillToAccountId__c,Apttus_Config2__ShipToAccountId__c,Apttus_Config2__ExpectedStartDate__c,Apttus_Config2__ExpectedEndDate__c,
                    Apttus_Config2__CartDataCache__c, Apttus_Config2__CartDataCache2__c, Apttus_Config2__PriceListId__c,
                    Apttus_Config2__EffectiveDate__c, Apttus_Config2__BusinessObjectType__c, Apttus_Config2__SummaryGroupType__c
                    FROM Apttus_Config2__ProductConfiguration__c
                    WHERE APTS_Flow__c = :System.Label.APTS_NGStandardOrder limit 1];
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus_Config2__PriceList__c oPriceList = [SELECT Id, APTS_Region__c FROM Apttus_Config2__PriceList__c LIMIT 1];
        oPriceList.APTS_Region__c = 'SAP_6712';
        Database.Update(oPriceList, false);

        Apttus_Config2__PriceListItem__c priceListItem = [select APTS_Call_Out_Coverage__c,APTS_Labour_Coverage__c,APTS_Spare_Parts_Coverage__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__r.name='Option' limit 1];
        priceListItem.APTS_Call_Out_Coverage__c = 10.0;
        priceListItem.APTS_Labour_Coverage__c = 10.0;
        priceListItem.APTS_Spare_Parts_Coverage__c = 10.0;
        Database.update(priceListItem);
                
        Product2 freightCharges = APTS_TestUtils.createProduct(System.Label.APTS_FREIGHT_CHARGES_PRODUCT_NAME, '26940992', 'Machines'); 
        Database.insert(freightCharges);

        Apttus_Config2__PriceListItem__c oPriceListFC = APTS_TestDataFactory.createPriceListItem(oPriceList.Id, freightCharges.Id);
        Database.insert(oPriceListFC);
        
        List<APTS_Freight_Charge_Details__c> lstFreightChargeDetails = new List<APTS_Freight_Charge_Details__c>();
        APTS_Freight_Charge_Details__c oFreightChargeDetails = new APTS_Freight_Charge_Details__c();
        oFreightChargeDetails.APTS_Range_From__c = 0;
        oFreightChargeDetails.APTS_Range_To__c = 400;
        oFreightChargeDetails.APTS_Region__c = 'SAP_6712';
        oFreightChargeDetails.APTS_ListPriceOverride__c = 5.95;
        oFreightChargeDetails.APTS_IsActive__c = true;
        Database.insert(oFreightChargeDetails, false);
        lstFreightChargeDetails.add(oFreightChargeDetails);

        Apttus_Config2__LineItem__c lineItem = [select id,Apttus_Config2__ProductOptionId__c,Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__c,Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__c,Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c,Apttus_Config2__LineNumber__c from Apttus_Config2__LineItem__c where Apttus_Config2__PriceListItemId__c =: priceListItem.id limit 1];
        system.debug('----->>' + lineItem);
        System.debug('test1=========>'+lineItem.Apttus_Config2__ProductOptionId__c);
        System.debug('test2=========>'+lineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__c);
        System.debug('test3=========>'+lineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__c);
        System.debug('test4=========>'+lineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c);
        

        Apttus_Config2__LineItem__c freightChargesLI = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListFC.Id, NULL, freightCharges.Id, NULL, NULL, 1, 1, 1, 'Product/Service', NULL , 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
        Database.insert(freightChargesLI);

        //Call PCB
        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);
        Test.startTest();

        System.runAs(oTestUser) {
            oPricingCallback.getFreightChargeLPO(lstFreightChargeDetails, 200);
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
        List<APTS_Error_Object__c> errorObj = [SELECT Id, APTS_Description_Of_Error__c, APTS_Error_Name__c FROM APTS_Error_Object__c];
        for(APTS_Error_Object__c err: errorObj){
        //13Aug 2018 - Aarthi - commented below
        //system.assertEquals('TEST',err.APTS_Description_Of_Error__c);
        }
    }
    @isTest static void test_TAXandVAT() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = [
                    SELECT Id, APTS_Flow__c, Apttus_Config2__OrderId__c,Apttus_Config2__BillToAccountId__c,Apttus_Config2__ShipToAccountId__c,Apttus_Config2__ExpectedStartDate__c,Apttus_Config2__ExpectedEndDate__c,
                    Apttus_Config2__CartDataCache__c, Apttus_Config2__CartDataCache2__c, Apttus_Config2__PriceListId__c,
                    Apttus_Config2__EffectiveDate__c, Apttus_Config2__BusinessObjectType__c, Apttus_Config2__SummaryGroupType__c
                    FROM Apttus_Config2__ProductConfiguration__c
                    WHERE Apttus_Config2__BusinessObjectType__c = 'Agreement' limit 1];
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        lineItemList[0].APTS_is_Tax_and_VAT_calculated__c=true;
        update lineItemList[0];
        //Call PCB
        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();

        System.runAs(oTestUser) {

           Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }

        Test.stopTest();
        List<APTS_Error_Object__c> errorObj = [SELECT Id, APTS_Description_Of_Error__c, APTS_Error_Name__c FROM APTS_Error_Object__c];
        for(APTS_Error_Object__c err: errorObj){
        //13Aug 2018 - Aarthi - commented below
        //system.assertEquals('TEST',err.APTS_Description_Of_Error__c);
        }
    }
        @isTest static void test_TAXandVAT1() {
        
        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');
        Apttus_Config2__PriceList__c oPriceList = APTS_TestFacade.getPriceList();
          Contact oContact = APTS_TestFacade.getContact();
        Account oAccount = APTS_TestFacade.getAccount();
        oAccount.billingcountry = 'Netherlands';
        Database.update(oAccount);
        
        Apttus_Config2__Order__c oOrder = APTS_TestDataFactory.createOrder(oAccount.Id, oPriceList.Id, oContact.Id);
           // oOrder.Apttus_Config2__Status__c = ACTIVATED;
            oOrder.Apttus_Config2__Description__c = 'AdminOrder';
            oOrder.Apttus_Config2__PONumber__c = '1234';
            //oOrder.APTS_Order_Sub_Type__c = STANDARD_ORDER;
            //oOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(Admin_Order).getRecordTypeId();
            oOrder.APTS_Order_Type__c = 'Admin Order';
            oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            oOrder.APTS_Requested_Installation_Date__c=null;
            oOrder.APTS_Contract_Change__c='No';
            Database.insert(oOrder);
        //Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder('AdminOrder');

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        oProductConfiguration.Apttus_Config2__OrderId__c = oOrder.Id;
        oProductConfiguration.APTS_Flow__c = System.Label.APTS_NGAdminOrder;
        Database.update(oProductConfiguration);

        //oOrder.APTS_Is_Amended_for_Indexation__c = true;
       
        //oOrder.Apttus__Version_Number__c = 24;
        //oOrder.Apttus__Contract_Start_Date__c = Date.today(); 
        //oOrder.Apttus__Contract_End_Date__c = Date.today()+365;
       
        
        List<Apttus_Config2__ProductAttributeValue__c> attrVal = [Select id, APTS_Type_of_contract__c, APTS_Type_of_Consumption__c, APTS_Number_of_months__c, APTS_WTS_Changed_By__c, APTS_Refurbished__c FROM Apttus_Config2__ProductAttributeValue__c ];
        attrVal.get(0).APTS_Type_of_contract__c = 'Sales';
        attrVal.get(0).APTS_Number_of_months__c = '12';
        update attrVal;
        
        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c = 'Services||';
        lineItemList.get(0).Apttus_Config2__LineStatus__c = 'New';
        lineItemList.get(0).Apttus_Config2__AssetLineItemId__c = null;
        lineItemList.get(0).Apttus_Config2__AttributeValueId__c = attrVal.get(0).id;
        lineItemList.get(0).Apttus_Config2__LineNumber__c = 1;
        lineItemList.get(0).Apttus_Config2__DerivedFromId__c = null;
        Database.update(lineItemList);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        List<APTS_Index_Contract__c> oIndexcontractlist = new List<APTS_Index_Contract__c>();
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Non-Standard Indexation','Technical Services'));
        Database.insert(oIndexcontractlist);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Category__c = 'Technical Services';
        oIndexationExecuting.APTS_Indexation_Country__c = 'Netherlands';
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
           // Apttus_Config2.LineItem lineItemMO;
           // Apttus_Config2__PriceListItem__c PLI = new Apttus_Config2__PriceListItem__c();
          // oPricingCallback.onPriceItemSet(PLI,lineItemMO);
        }
        Test.stopTest();
        
    }
    @isTest static void test_basepriceMode() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = [
                    SELECT Id, APTS_Flow__c, Apttus_Config2__OrderId__c,Apttus_Config2__BillToAccountId__c,Apttus_Config2__ShipToAccountId__c,Apttus_Config2__ExpectedStartDate__c,Apttus_Config2__ExpectedEndDate__c,
                    Apttus_Config2__CartDataCache__c, Apttus_Config2__CartDataCache2__c, Apttus_Config2__PriceListId__c, 
                    Apttus_Config2__EffectiveDate__c, Apttus_Config2__BusinessObjectType__c, Apttus_Config2__SummaryGroupType__c
                    FROM Apttus_Config2__ProductConfiguration__c
                    WHERE Apttus_Config2__BusinessObjectType__c = 'Agreement' limit 1];
                    
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        for(Apttus_Config2__LineItem__c lineItenm : lineItemList){
            lineItenm.Apttus_Config2__PricingStatus__c='Pending';
            lineItenm.Apttus_Config2__IsPrimaryLine__c=true;
        }
        lineItemList[0].Apttus_Config2__LineStatus__c='Cancelled';
        update lineItemList;
        
        //Call PCB
        Test.startTest();
        System.runAs(oTestUser) {
            APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
            Apttus_Config2.PricingWebService.computeBasePriceForItemColl(oProductConfiguration.Id,1);
            Apttus_Config2.PricingWebService.computeBasePriceForItemColl(oProductConfiguration.Id,2);
            //Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
            /*Apttus_CPQApi.CPQ.UpdatePriceRequestDO priceReqDO = new Apttus_CPQApi.CPQ.UpdatePriceRequestDO();
            priceReqDO.cartID = oProductConfiguration.id;
            Apttus_CPQApi.CPQ.UpdatePriceResponseDO response = Apttus_CPQApi.CPQWebService.updatePriceForCart(priceReqDO);*/
        }
        Test.stopTest();
    }
    
    @isTest static void test_PricingCallbackWithIndexationCodeCoverage() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Account oAccount = APTS_TestFacade.getAccount();
        oAccount.billingcountry = 'Netherlands';
        Database.update(oAccount);

        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oProductConfiguration);

        oAgreement.APTS_Is_Amended_for_Indexation__c = true;
        oAgreement.APTS_Agreement_Request__c = 'New';
        oAgreement.Apttus__Version_Number__c = 0;
        oAgreement.Apttus__Contract_Start_Date__c = Date.today(); 
        oAgreement.Apttus__Contract_End_Date__c = Date.today()+365;
        Database.update(oAgreement);
        
        List<Apttus_Config2__ProductAttributeValue__c> attrVal = [Select id, APTS_Type_of_contract__c, APTS_Type_of_Consumption__c, APTS_Number_of_months__c, APTS_WTS_Changed_By__c, APTS_Refurbished__c FROM Apttus_Config2__ProductAttributeValue__c ];
        attrVal.get(0).APTS_Type_of_contract__c = 'Sales';
        attrVal.get(0).APTS_Number_of_months__c = '12';
        update attrVal;
        
        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c = 'Services||';
        lineItemList.get(0).Apttus_Config2__LineStatus__c = 'New';
        lineItemList.get(0).Apttus_Config2__AssetLineItemId__c = null;
        lineItemList.get(0).Apttus_Config2__PriceType__c = 'Recurring';
        lineItemList.get(0).Apttus_Config2__AttributeValueId__c = attrVal.get(0).id;
        lineItemList.get(0).Apttus_Config2__LineNumber__c = 1;
        Database.update(lineItemList);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        List<APTS_Index_Contract__c> oIndexcontractlist = new List<APTS_Index_Contract__c>();
       // oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Standard Indexation(incl Fixed Prices)','Machine Care Service'));
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Standard Indexation(incl Fixed Prices)','Technical Services'));
        Database.insert(oIndexcontractlist);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Category__c = 'Technical Services';
        oIndexationExecuting.APTS_Indexation_Country__c = 'Netherlands';
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
        
        System.runAs(oTestUser) {

            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }
        Test.stopTest();
    }   
    
    @isTest static void test_PricingCallbackWithIndexationCodeCoverage1() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Account oAccount = APTS_TestFacade.getAccount();
        oAccount.billingcountry = 'Netherlands';
        Database.update(oAccount);

        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oProductConfiguration);

        oAgreement.APTS_Is_Amended_for_Indexation__c = true;
        oAgreement.APTS_Agreement_Request__c = 'Amendment';
        oAgreement.Apttus__Version_Number__c = 24;
        oAgreement.Apttus__Contract_Start_Date__c = Date.today(); 
        oAgreement.Apttus__Contract_End_Date__c = Date.today()+365;
        Database.update(oAgreement);
        
        List<Apttus_Config2__ProductAttributeValue__c> attrVal = [Select id, APTS_Type_of_contract__c, APTS_Type_of_Consumption__c, APTS_Number_of_months__c, APTS_WTS_Changed_By__c, APTS_Refurbished__c FROM Apttus_Config2__ProductAttributeValue__c ];
        attrVal.get(0).APTS_Type_of_contract__c = 'Sales';
        attrVal.get(0).APTS_Number_of_months__c = '12';
        update attrVal;
        
        lineItemList.get(0).Apttus_Config2__BasePriceOverride__c = 100;
        lineItemList.get(0).Apttus_Config2__ClassificationHierarchy__c = 'Services||';
        lineItemList.get(0).Apttus_Config2__LineStatus__c = 'New';
        lineItemList.get(0).Apttus_Config2__AssetLineItemId__c = null;
        lineItemList.get(0).Apttus_Config2__PriceType__c = 'Recurring';
        lineItemList.get(0).Apttus_Config2__AttributeValueId__c = attrVal.get(0).id;
        lineItemList.get(0).Apttus_Config2__LineNumber__c = 1;
        lineItemList.get(0).Apttus_Config2__DerivedFromId__c = null;
        Database.update(lineItemList);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        List<APTS_Index_Contract__c> oIndexcontractlist = new List<APTS_Index_Contract__c>();
        oIndexcontractlist.add(APTS_TestUtils.createindexcontract(oAgreement,'Non-Standard Indexation','Technical Services'));
        Database.insert(oIndexcontractlist);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Category__c = 'Technical Services';
        oIndexationExecuting.APTS_Indexation_Country__c = 'Netherlands';
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
           // Apttus_Config2.LineItem lineItemMO;
           // Apttus_Config2__PriceListItem__c PLI = new Apttus_Config2__PriceListItem__c();
          // oPricingCallback.onPriceItemSet(PLI,lineItemMO);
        }
        Test.stopTest();
    }   

    @isTest static void test_PricingCallbackCustomQuantityUOMs() {

        List<Apttus_Config2__PriceListItem__c> pliList = new  List<Apttus_Config2__PriceListItem__c>();
        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);

        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oProductConfiguration);
        
        List<Apttus_Config2__ProductAttributeValue__c> attrVal = [Select id, APTS_Type_of_contract__c, APTS_Type_of_Consumption__c, APTS_Number_of_months__c, APTS_WTS_Changed_By__c, APTS_Refurbished__c FROM Apttus_Config2__ProductAttributeValue__c ];
        attrVal.get(0).APTS_Type_of_contract__c = 'Sales';
        attrVal.get(0).APTS_Number_of_months__c = '12';
        update attrVal;

        for(Apttus_Config2__PriceListItem__c pricelistItem : [select id from Apttus_Config2__PriceListItem__c]){
            pricelistItem.APTS_Default_selling_UOM__c='SAP_BX';
            pricelistItem.Apttus_Config2__PriceUom__c='SAP_PCE';
            pliList.add(pricelistItem);
        }
        Database.update(pliList);

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
            List<Apttus_Config2__LineItem__c> lineItemList1 = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
            for(Apttus_Config2__LineItem__c lineItem : lineItemList1){
             //   System.debug('lineItem APTS_is_selling_UOM_defaulted__c======>'+lineItem.APTS_is_selling_UOM_defaulted__c);
              //  System.debug('lineItem Apttus_Config2__LineNumber__c======>'+lineItem.Apttus_Config2__LineNumber__c);
            }
            Apttus_Config2.PricingWebService.computeBasePriceForItemColl(oProductConfiguration.Id,1);
            //Apttus_Config2.LineItem lineitem1ItemMO;
           // Apttus_Config2__PriceListItem__c PLI = new Apttus_Config2__PriceListItem__c();
          // oPricingCallback.onPriceItemSet(PLI,lineItemMO);
        }
        Test.stopTest();
    }   
    @isTest static void test_AutoRenewalsAssets_1() {

        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        
        Product2 product1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines'); 
        product1.APTS_Material_Type__c = 'ZFIN';
        product1.APTS_Sales_Catalog__c = '0401';
        insert product1;
        
        Product2 option1= APTS_TestUtils.createProduct('All-in Coverage-Draft', '26940992', 'Machines'); 
        option1.APTS_Material_Type__c = 'ZFIN';
        option1.APTS_Sales_Catalog__c = '0401';
        insert option1;
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');
        oAgreement.Apttus__Auto_Renewal__c= true;
        update oAgreement;

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oProductConfiguration);
        
        for(Integer i = 0;i<5;i++){
            lineItemList.get(i).Apttus_Config2__ProductId__c = product1.id;
            lineItemList.get(i).Apttus_Config2__OptionId__c = option1.id;
        }
        
        update lineItemList;

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
            List<Apttus_Config2__LineItem__c> lineItemList1 = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
            for(Apttus_Config2__LineItem__c lineItem : lineItemList1){
             //   System.debug('lineItem APTS_is_selling_UOM_defaulted__c======>'+lineItem.APTS_is_selling_UOM_defaulted__c);
              //  System.debug('lineItem Apttus_Config2__LineNumber__c======>'+lineItem.Apttus_Config2__LineNumber__c);
            }
            Apttus_Config2.PricingWebService.computeBasePriceForItemColl(oProductConfiguration.Id,1);
            //Apttus_Config2.LineItem lineitem1ItemMO;
           // Apttus_Config2__PriceListItem__c PLI = new Apttus_Config2__PriceListItem__c();
          // oPricingCallback.onPriceItemSet(PLI,lineItemMO);
        }
        Test.stopTest();
    }   
    @isTest static void test_AutoRenewalsAssets_2() {
        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        
        Apttus_Config2__Order__c StandardOrder = APTS_TestFacade.getOrder('StandardOrder');
        StandardOrder.APTS_Auto_renewal_staging_source_id__c='123';
        update StandardOrder;

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        oProductConfiguration.Apttus_Config2__OrderId__c  = StandardOrder.Id;
        Database.update(oProductConfiguration);
        
        List<Apttus_Config2__AssetLineItem__c> assetlineItemList = APTS_TestFacade.getAssetLineItem();
        assetlineItemList[0].Apttus_Config2__EndDate__c = System.Today().addDays(-1);
        assetlineItemList[0].Apttus_Config2__PriceType__c = 'Recurring';
        assetlineItemList[0].Apttus_Config2__AssetStatus__c  = 'Activated';
        assetlineItemList[0].Apttus_Config2__AutoRenew__c=true;
        assetlineItemList[0].APTS_BasePriceOverride__c=10;
        update assetlineItemList[0];

        
        for(Integer i = 0;i<5;i++){
            lineItemList[0].Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
            lineItemList.get(0).Apttus_Config2__PriceType__c = 'Recurring';
        }
        update lineItemList;

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
            List<Apttus_Config2__LineItem__c> lineItemList1 = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
            for(Apttus_Config2__LineItem__c lineItem : lineItemList1){
             //   System.debug('lineItem APTS_is_selling_UOM_defaulted__c======>'+lineItem.APTS_is_selling_UOM_defaulted__c);
              //  System.debug('lineItem Apttus_Config2__LineNumber__c======>'+lineItem.Apttus_Config2__LineNumber__c);
            }
            Apttus_Config2.PricingWebService.computeBasePriceForItemColl(oProductConfiguration.Id,1);
            //Apttus_Config2.LineItem lineitem1ItemMO;
           // Apttus_Config2__PriceListItem__c PLI = new Apttus_Config2__PriceListItem__c();
          // oPricingCallback.onPriceItemSet(PLI,lineItemMO);
        }
        Test.stopTest();
    }   
    @isTest static void test_AutoRenewalsAssets_5() {
        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        
        Apttus_Config2__Order__c StandardOrder = APTS_TestFacade.getOrder('StandardOrder');
        StandardOrder.APTS_Auto_renewal_staging_source_id__c='123';
        StandardOrder.APTS_Order_Type__c = 'Admin Order';
        update StandardOrder;

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        oProductConfiguration.Apttus_Config2__OrderId__c  = StandardOrder.Id;
        oProductConfiguration.APTS_Flow__c=System.Label.APTS_NGAdminOrder;
        Database.update(oProductConfiguration);
        
        List<Apttus_Config2__AssetLineItem__c> assetlineItemList = APTS_TestFacade.getAssetLineItem();
        assetlineItemList[0].Apttus_Config2__EndDate__c = System.Today().addDays(-1);
        assetlineItemList[0].Apttus_Config2__PriceType__c = 'Recurring';
        assetlineItemList[0].Apttus_Config2__AssetStatus__c  = 'Activated';
        assetlineItemList[0].Apttus_Config2__AutoRenew__c=true;
        assetlineItemList[0].APTS_BasePriceOverride__c=10;
        update assetlineItemList[0];

        
        for(Integer i = 0;i<5;i++){
            lineItemList[0].Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
            lineItemList.get(0).Apttus_Config2__PriceType__c = 'Recurring';
        }
        update lineItemList;

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
            List<Apttus_Config2__LineItem__c> lineItemList1 = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
            for(Apttus_Config2__LineItem__c lineItem : lineItemList1){
             //   System.debug('lineItem APTS_is_selling_UOM_defaulted__c======>'+lineItem.APTS_is_selling_UOM_defaulted__c);
              //  System.debug('lineItem Apttus_Config2__LineNumber__c======>'+lineItem.Apttus_Config2__LineNumber__c);
            }
            Apttus_Config2.PricingWebService.computeBasePriceForItemColl(oProductConfiguration.Id,1);
            //Apttus_Config2.LineItem lineitem1ItemMO;
           // Apttus_Config2__PriceListItem__c PLI = new Apttus_Config2__PriceListItem__c();
          // oPricingCallback.onPriceItemSet(PLI,lineItemMO);
        }
        Test.stopTest();
    }   
    
     
 
 @isTest static void test_ContractChange() {
 Map<Id, Apttus_Config2__LineItem__c> MapCancelledLines=new Map<Id, Apttus_Config2__LineItem__c>();
 Map<Id, Apttus_Config2__LineItem__c> MapNewLines= new Map<Id, Apttus_Config2__LineItem__c>();
 Apttus_Config2__LineItem__c instLine0 = new  Apttus_Config2__LineItem__c();
    Apttus_Config2__LineItem__c instLine1 = new  Apttus_Config2__LineItem__c();
    Apttus_Config2__LineItem__c instLine2 = new  Apttus_Config2__LineItem__c();
    Apttus_Config2__LineItem__c instLine3 = new  Apttus_Config2__LineItem__c();

Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');
        Apttus_Config2__PriceList__c oPriceList = APTS_TestFacade.getPriceList();
          Contact oContact = APTS_TestFacade.getContact();
        Account oAccount = APTS_TestFacade.getAccount(); 

 Apttus_Config2__Order__c oOrder = APTS_TestDataFactory.createOrder(oAccount.Id, oPriceList.Id, oContact.Id);
            oOrder.Apttus_Config2__Description__c = 'AdminOrder';
            oOrder.Apttus_Config2__PONumber__c = '1234';
            oOrder.APTS_Order_Sub_Type__c = 'Conversion Order';
            oOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get('Admin Order').getRecordTypeId();
            oOrder.APTS_Order_Type__c = 'Admin Order';
            oOrder.APTS_Requested_Installation_Date__c=null;
            oOrder.APTS_Contract_Change__c='Yes';
            Database.insert(oOrder);

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        oProductConfiguration.Apttus_Config2__OrderId__c = oOrder.Id;
        oProductConfiguration.APTS_Flow__c = System.Label.APTS_NGAdminOrder;
        Database.update(oProductConfiguration);
        
        List<Apttus_Config2__ProductAttributeValue__c> attrVal = [Select id, APTS_Type_of_contract__c, APTS_Type_of_Consumption__c, APTS_Number_of_months__c, APTS_WTS_Changed_By__c, APTS_Refurbished__c FROM Apttus_Config2__ProductAttributeValue__c limit 1];
        attrVal.get(0).APTS_Type_of_contract__c = 'Rent';
        attrVal.get(0).APTS_Number_of_months__c = '12';
        update attrVal;
        
        Product2 product1 = APTS_TestUtils.createProduct('Instant 220', '26940992', 'Machines'); 
        product1.APTS_Sales_Catalog__c = '0401';
        insert product1;
        
        Product2 option = APTS_TestUtils.createProduct('Instant 220', '26940992', 'Machines'); 
        option.APTS_Sales_Catalog__c = '0401';
        insert option;
        
        List<Apttus_Config2__AssetLineItem__c> assetlineItemList = APTS_TestFacade.getAssetLineItem();
        assetlineItemList[0].Apttus_Config2__EndDate__c = System.Today().addDays(-1);
        assetlineItemList[0].Apttus_Config2__PriceType__c = 'Recurring';
        assetlineItemList[0].Apttus_Config2__AssetStatus__c  = 'Activated';
        assetlineItemList[0].Apttus_Config2__AutoRenew__c=true;
        update assetlineItemList[0];


        instLine0.Apttus_Config2__BasePriceOverride__c = 100;
        instLine0.Apttus_Config2__ClassificationHierarchy__c = 'Services';
        instLine0.Apttus_Config2__AttributeValueId__c = attrVal.get(0).id;
        instLine0.Apttus_Config2__LineNumber__c = 1;
        instLine0.Apttus_Config2__LineType__c='Product/Service';
        instLine0.Apttus_Config2__ProductId__c = product1.id;
        instLine0.APTS_Serial_Number2__c='12345';
        instLine0.Apttus_Config2__HasOptions__c=true;
        instLine0.Apttus_Config2__LineStatus__c = 'Cancelled';
        instLine0.Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
        instLine0.CurrencyIsoCode = 'EUR';
        //Database.insert(instLine0);      
        mapCancelledLines.put(instLine0.id,instLine0);
        
        instLine1.Apttus_Config2__BasePriceOverride__c = 100;
        instLine1.Apttus_Config2__ClassificationHierarchy__c = 'Services';
        instLine1.Apttus_Config2__LineStatus__c = 'New';
        instLine1.Apttus_Config2__AssetLineItemId__c = null;
        instLine1.Apttus_Config2__ProductId__c = product1.id;
        instLine1.Apttus_Config2__LineType__c='Product/Service';
        instLine1.Apttus_Config2__AttributeValueId__c = attrVal.get(0).id;
        instLine1.Apttus_Config2__LineNumber__c = 2;
        instLine1.CurrencyIsoCode = 'EUR';
        //Database.insert(instLine1);
        mapNewLines.put(instLine1.id,instLine1);
        
        instLine2.Apttus_Config2__BasePriceOverride__c = 100;
        instLine2.Apttus_Config2__ClassificationHierarchy__c = 'Services';
        instLine2.Apttus_Config2__AttributeValueId__c = attrVal.get(0).id;
        instLine2.Apttus_Config2__LineNumber__c = 3;
        instLine2.Apttus_Config2__LineType__c='Option';
        instLine2.Apttus_Config2__OptionId__c = option.id;
        instLine2.APTS_Serial_Number2__c='12345';
        instLine2.Apttus_Config2__LineStatus__c = 'Cancelled';
        instLine2.CurrencyIsoCode = 'EUR';
        instLine2.Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
        //Database.insert(instLine2);      
        mapCancelledLines.put(instLine2.id,instLine2);
        
        instLine3.Apttus_Config2__BasePriceOverride__c = 100;
        instLine3.Apttus_Config2__ClassificationHierarchy__c = 'Services';
        instLine3.Apttus_Config2__LineStatus__c = 'New';
        instLine3.Apttus_Config2__AssetLineItemId__c = null;
        instLine3.Apttus_Config2__OptionId__c = option.id;
        instLine3.CurrencyIsoCode = 'EUR';
        instLine3.Apttus_Config2__LineType__c='Option';
        instLine3.Apttus_Config2__AttributeValueId__c = attrVal.get(0).id;
        instLine3.Apttus_Config2__LineNumber__c = 4;
        //Database.insert(instLine3);
        mapNewLines.put(instLine3.id,instLine3);
        
        
         APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);
        
        Test.startTest();     
oPricingCallback.PrimaryLineSwapforContractChange(mapNewLines,mapCancelledLines);
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);

        Test.stopTest();
 }
     @isTest static void test_AutoRenewalsAssets_6() {
        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        
        Apttus_Config2__Order__c StandardOrder = APTS_TestFacade.getOrder('StandardOrder');
        StandardOrder.APTS_Auto_renewal_staging_source_id__c='123';
        StandardOrder.APTS_Order_Type__c = 'Admin Order';
        StandardOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA14;
        update StandardOrder;

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        oProductConfiguration.Apttus_Config2__OrderId__c  = StandardOrder.Id;
        oProductConfiguration.APTS_Flow__c=System.Label.APTS_NGAdminOrder;
        Database.update(oProductConfiguration);
        
        List<Apttus_Config2__AssetLineItem__c> assetlineItemList = APTS_TestFacade.getAssetLineItem();
        assetlineItemList[0].Apttus_Config2__EndDate__c = System.Today().addDays(-1);
        assetlineItemList[0].Apttus_Config2__PriceType__c = 'Recurring';
        assetlineItemList[0].Apttus_Config2__AssetStatus__c  = 'Activated';
        assetlineItemList[0].Apttus_Config2__AutoRenew__c=true;
        assetlineItemList[0].APTS_BasePriceOverride__c=10;
        update assetlineItemList[0];

        
        for(Integer i = 0;i<5;i++){
            lineItemList[0].Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
            lineItemList.get(0).Apttus_Config2__PriceType__c = 'Recurring';
            lineItemList[0].Apttus_Config2__HasOptions__c = true;
            lineItemList[0].Apttus_Config2__ChargeType__c = 'Service fee';
            lineItemList[0].Apttus_Config2__LineNumber__c=1;
            lineItemList[0].APTS_is_Indexation_skip__c=false;
            
            lineItemList[1].Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
            lineItemList.get(0).Apttus_Config2__PriceType__c = 'Recurring';
            lineItemList[1].Apttus_Config2__HasOptions__c = false;
            lineItemList[1].Apttus_Config2__ChargeType__c = 'Service fee';
            lineItemList[1].Apttus_Config2__LineNumber__c=1;
            lineItemList[0].APTS_is_Indexation_skip__c=false;
        }
        update lineItemList;

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
            List<Apttus_Config2__LineItem__c> lineItemList1 = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
            for(Apttus_Config2__LineItem__c lineItem : lineItemList1){
             //   System.debug('lineItem APTS_is_selling_UOM_defaulted__c======>'+lineItem.APTS_is_selling_UOM_defaulted__c);
              //  System.debug('lineItem Apttus_Config2__LineNumber__c======>'+lineItem.Apttus_Config2__LineNumber__c);
            }
           Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }
        Test.stopTest();
    }   

    @isTest static void test_AutoRenewalsAssets_7() {
        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        
        Apttus_Config2__Order__c StandardOrder = APTS_TestFacade.getOrder('StandardOrder');
        StandardOrder.APTS_Auto_renewal_staging_source_id__c='123';
        StandardOrder.APTS_Order_Type__c = 'Admin Order';
        StandardOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA14;
        update StandardOrder;

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        oProductConfiguration.Apttus_Config2__OrderId__c  = StandardOrder.Id;
        oProductConfiguration.APTS_Flow__c=System.Label.APTS_NGAdminOrder;
        Database.update(oProductConfiguration);
        
        List<Apttus_Config2__AssetLineItem__c> assetlineItemList = APTS_TestFacade.getAssetLineItem();
        assetlineItemList[0].Apttus_Config2__EndDate__c = System.Today().addDays(-1);
        assetlineItemList[0].Apttus_Config2__PriceType__c = 'Recurring';
        assetlineItemList[0].Apttus_Config2__AssetStatus__c  = 'Activated';
        assetlineItemList[0].Apttus_Config2__AutoRenew__c=true;
        assetlineItemList[0].APTS_BasePriceOverride__c=10;
        update assetlineItemList[0];

        
        for(Integer i = 0;i<5;i++){
            lineItemList[0].Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
            lineItemList[0].Apttus_Config2__PriceType__c = 'Recurring';
            lineItemList[0].Apttus_Config2__HasOptions__c = true;
            lineItemList[0].Apttus_Config2__ChargeType__c = 'Service fee';
            lineItemList[0].Apttus_Config2__LineNumber__c=1;
            lineItemList[0].APTS_is_Indexation_skip__c=false;
            
            lineItemList[1].Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
            lineItemList[1].Apttus_Config2__PriceType__c = 'Recurring';
            lineItemList[1].Apttus_Config2__HasOptions__c = false;
            lineItemList[1].Apttus_Config2__LineType__c = 'Option';
            lineItemList[1].Apttus_Config2__ChargeType__c = 'Service fee';
            lineItemList[1].Apttus_Config2__LineNumber__c=1;
            lineItemList[1].APTS_is_Indexation_skip__c=false;
        }
        update lineItemList;

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
            List<Apttus_Config2__LineItem__c> lineItemList1 = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
            for(Apttus_Config2__LineItem__c lineItem : lineItemList1){
             //   System.debug('lineItem APTS_is_selling_UOM_defaulted__c======>'+lineItem.APTS_is_selling_UOM_defaulted__c);
              //  System.debug('lineItem Apttus_Config2__LineNumber__c======>'+lineItem.Apttus_Config2__LineNumber__c);
            }
           Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }
        Test.stopTest();
    }   

    @isTest static void addRemoveOptions() {
        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus_Config2__Order__c StandardOrder = APTS_TestFacade.getOrder('StandardOrder');
        StandardOrder.APTS_Order_Type__c = 'Admin Order';
        StandardOrder.APTS_Order_Sub_Sub_Type__c = 'Add/Remove Options';
        StandardOrder.RecordTypeId=Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByDeveloperName().get('Admin_Order').getRecordTypeId();
        StandardOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA14;
        update StandardOrder;

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        oProductConfiguration.Apttus_Config2__OrderId__c  = StandardOrder.Id;
        oProductConfiguration.APTS_Flow__c=System.Label.APTS_NGAdminOrder;
        Database.update(oProductConfiguration);
        
        List<Apttus_Config2__AssetLineItem__c> assetlineItemList = APTS_TestFacade.getAssetLineItem();
        assetlineItemList[0].Apttus_Config2__EndDate__c = System.Today().addDays(-1);
        assetlineItemList[0].Apttus_Config2__PriceType__c = 'Recurring';
        assetlineItemList[0].Apttus_Config2__AssetStatus__c  = 'Activated';
        assetlineItemList[0].Apttus_Config2__AutoRenew__c=true;
        assetlineItemList[0].APTS_BasePriceOverride__c=10;
        update assetlineItemList[0];

        
        for(Integer i = 0;i<5;i++){
            lineItemList[0].Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
            lineItemList[0].Apttus_Config2__PriceType__c = 'Recurring';
            lineItemList[0].Apttus_Config2__HasOptions__c = true;
            lineItemList[0].Apttus_Config2__ChargeType__c = 'Service fee';
            lineItemList[0].Apttus_Config2__LineNumber__c=1;
            lineItemList[0].Apttus_Config2__LineStatus__c='New';
            //lineItemList[0].APTS_is_Indexation_skip__c=false;
            
            lineItemList[1].Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
            lineItemList[1].Apttus_Config2__PriceType__c = 'Recurring';
            lineItemList[1].Apttus_Config2__HasOptions__c = false;
            lineItemList[1].Apttus_Config2__LineType__c = 'Option';
            lineItemList[1].Apttus_Config2__ChargeType__c = 'Service fee';
            lineItemList[1].Apttus_Config2__LineNumber__c=1;
            lineItemList[1].Apttus_Config2__LineStatus__c='Cancelled';
            //lineItemList[1].APTS_is_Indexation_skip__c=false;
            //lineItemList[1].APTS_is_Indexation_skip__c=false;
        }
        update lineItemList;

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
            List<Apttus_Config2__LineItem__c> lineItemList1 = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
            for(Apttus_Config2__LineItem__c lineItem : lineItemList1){
             //   System.debug('lineItem APTS_is_selling_UOM_defaulted__c======>'+lineItem.APTS_is_selling_UOM_defaulted__c);
              //  System.debug('lineItem Apttus_Config2__LineNumber__c======>'+lineItem.Apttus_Config2__LineNumber__c);
            }
           Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }
        Test.stopTest();
    }   

    
    @isTest static void addRemoveOptions1() {
        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus_Config2__Order__c StandardOrder = APTS_TestFacade.getOrder('StandardOrder');
        StandardOrder.APTS_Order_Type__c = 'Admin Order';
        StandardOrder.APTS_Order_Sub_Sub_Type__c = 'Add/Remove Options';
        StandardOrder.RecordTypeId=Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByDeveloperName().get('Admin_Order').getRecordTypeId();
        StandardOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA14;
        update StandardOrder;

        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        oProductConfiguration.Apttus_Config2__OrderId__c  = StandardOrder.Id;
        oProductConfiguration.APTS_Flow__c=System.Label.APTS_NGAdminOrder;
        Database.update(oProductConfiguration);
        
        List<Apttus_Config2__AssetLineItem__c> assetlineItemList = APTS_TestFacade.getAssetLineItem();
        assetlineItemList[0].Apttus_Config2__EndDate__c = System.Today().addDays(-1);
        assetlineItemList[0].Apttus_Config2__PriceType__c = 'Recurring';
        assetlineItemList[0].Apttus_Config2__AssetStatus__c  = 'Activated';
        assetlineItemList[0].Apttus_Config2__AutoRenew__c=true;
        assetlineItemList[0].APTS_BasePriceOverride__c=10;
        update assetlineItemList[0];

        
        for(Integer i = 0;i<5;i++){
            lineItemList[0].Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
            lineItemList[0].Apttus_Config2__PriceType__c = 'Recurring';
            lineItemList[0].Apttus_Config2__HasOptions__c = true;
            lineItemList[0].Apttus_Config2__ChargeType__c = 'Service fee';
            lineItemList[0].Apttus_Config2__LineNumber__c=1;
            lineItemList[0].Apttus_Config2__LineStatus__c='New';
            //lineItemList[0].APTS_is_Indexation_skip__c=false;
            
            lineItemList[1].Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
            lineItemList[1].Apttus_Config2__PriceType__c = 'Recurring';
            lineItemList[1].Apttus_Config2__HasOptions__c = false;
            lineItemList[1].Apttus_Config2__LineType__c = 'Option';
            lineItemList[1].Apttus_Config2__ChargeType__c = 'Service fee';
            lineItemList[1].Apttus_Config2__LineNumber__c=1;
            lineItemList[1].Apttus_Config2__LineStatus__c='New';
            //lineItemList[1].APTS_is_Indexation_skip__c=false;
            //lineItemList[1].APTS_is_Indexation_skip__c=false;
        }
        update lineItemList;

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
            List<Apttus_Config2__LineItem__c> lineItemList1 = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
            for(Apttus_Config2__LineItem__c lineItem : lineItemList1){
             //   System.debug('lineItem APTS_is_selling_UOM_defaulted__c======>'+lineItem.APTS_is_selling_UOM_defaulted__c);
              //  System.debug('lineItem Apttus_Config2__LineNumber__c======>'+lineItem.Apttus_Config2__LineNumber__c);
            }
           Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }
        Test.stopTest();
    }   
    @isTest static void addRemoveOptions2() {
        User oTestUser = [SELECT Id FROM USER WHERE LastName = 'PricingCallBackUser' LIMIT 1];

        Account oAccount = APTS_TestFacade.getAccount();

        Apttus_Config2__AccountLocation__c testAcclocation = APTS_TestUtils.createAccountLocation(oAccount.Id);
        insert testAcclocation;

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus_Config2__Order__c StandardOrder = APTS_TestFacade.getOrder('StandardOrder');
        StandardOrder.APTS_Order_Type__c = 'Admin Order';
        StandardOrder.APTS_Order_Sub_Sub_Type__c = 'Add/Remove Options';
        StandardOrder.RecordTypeId=Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByDeveloperName().get('Admin_Order').getRecordTypeId();
        StandardOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA14;
        update StandardOrder;



        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        oProductConfiguration.Apttus_Config2__OrderId__c  = StandardOrder.Id;
        oProductConfiguration.APTS_Flow__c=System.Label.APTS_NGAdminOrder;
        Database.update(oProductConfiguration);
        
        List<Apttus_Config2__AssetLineItem__c> assetlineItemList = APTS_TestFacade.getAssetLineItem();
        assetlineItemList[0].Apttus_Config2__EndDate__c = System.Today().addDays(-1);
        assetlineItemList[0].Apttus_Config2__PriceType__c = 'Recurring';
        assetlineItemList[0].Apttus_Config2__AssetStatus__c  = 'Activated';
        assetlineItemList[0].Apttus_Config2__AutoRenew__c=true;
        assetlineItemList[0].APTS_BasePriceOverride__c=10;
        assetlineItemList[0].Apttus_Config2__LocationId__c=testAcclocation.id;
        update assetlineItemList[0];

        
        for(Integer i = 0;i<5;i++){
            lineItemList[0].Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
            lineItemList[0].Apttus_Config2__PriceType__c = 'Recurring';
            lineItemList[0].Apttus_Config2__HasOptions__c = true;
            lineItemList[0].Apttus_Config2__IsPrimaryLine__c=true;
            lineItemList[0].Apttus_Config2__ChargeType__c = 'Service fee';
            lineItemList[0].Apttus_Config2__LineNumber__c=1;
            lineItemList[0].Apttus_Config2__LineStatus__c='New';
            //lineItemList[0].APTS_is_Indexation_skip__c=false;
            
            lineItemList[1].Apttus_Config2__AssetLineItemId__c=assetlineItemList[0].id;
            lineItemList[1].Apttus_Config2__PriceType__c = 'Recurring';
            lineItemList[1].Apttus_Config2__HasOptions__c = false;
            lineItemList[1].Apttus_Config2__LineType__c = 'Option';
            lineItemList[1].Apttus_Config2__ChargeType__c = 'Service fee';
            lineItemList[1].Apttus_Config2__LineNumber__c=1;
            lineItemList[1].Apttus_Config2__LineStatus__c='New';
            //lineItemList[1].APTS_is_Indexation_skip__c=false;
            //lineItemList[1].APTS_is_Indexation_skip__c=false;
        }
        update lineItemList;

        APTS_PricingCallback oPricingCallback = new APTS_PricingCallback();
        oPricingCallback.setMode(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT);

        Test.startTest();
        System.runAs(oTestUser) {
            Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
            List<Apttus_Config2__LineItem__c> lineItemList1 = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
            for(Apttus_Config2__LineItem__c lineItem : lineItemList1){
             //   System.debug('lineItem APTS_is_selling_UOM_defaulted__c======>'+lineItem.APTS_is_selling_UOM_defaulted__c);
              //  System.debug('lineItem Apttus_Config2__LineNumber__c======>'+lineItem.Apttus_Config2__LineNumber__c);
            }
           Apttus_Config2.PricingWebService.updatePriceForCart(oProductConfiguration.Id);
        }
        Test.stopTest();
    }   
}