/*************************************************************
@Name: APTS_PartialCancellationCtrlTest
@Author: Lavanya
@CreateDate: Aug 5 , 2020
@Description: Test class for APTS_PartialCancellationCtrl- DQ-333
@UsedBy: 
******************************************************************/
@isTest
private with sharing class APTS_PartialCancellationCtrlTest{
private static final String NGMACHINE_ORDER = System.Label.APTS_NGMachineOrder;

@isTest static void test_MachineOrder() {

            

       
        
        Account oAccount = APTS_TestDataFactory.createAccount('JDETestAccount');
            oAccount.Sales_Organization__c = 'SAP_0111';
            oAccount.Distribution_Channel__c = 'SAP_10';
            oAccount.Division__c = 'SAP_20';
            oAccount.SAP_Customer_ID__c = '123';
           // oAccount.Apttus_Config2__BillingPreferenceId__c = oBillingPreference.Id;
            //oAccount.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
           // oAccount.APTS_Payment_Method__c = paymentMethod.Id;
            Database.insert(oAccount);
            
             List<Contact> contactList = new List<Contact>();
            Contact oContact = APTS_TestDataFactory.createContact(oAccount, '1010101011');
            oContact.Function__c = 'Buyer Ingredients';
            oContact.Main_Service_Person__c = true;
            contactList.add(oContact);
            Database.insert(contactList);
            
        Opportunity oOpportunity = APTS_TestDataFactory.createOpportunity('JDETestOpportunity', oAccount.Id);
            Database.insert(oOpportunity);

       // Product2 oStandaloneProduct = getStandaloneProduct();
        Product2 oBundleProduct = APTS_TestDataFactory.createProduct('Bundle', '101', 'MA', 'Bundle', FALSE, TRUE);
            oBundleProduct.APTS_Material_Type__c = 'ZCMA';
            Product2 oOptionProduct = APTS_TestDataFactory.createProduct('Option', '102', 'MA', 'Option', FALSE, FALSE);
            oOptionProduct.APTS_Plug_and_Play_Indicator__c = true;
       
        //Apttus_Config2__BillingPreference__c oBillingPreference = getBillingPreference();
 Apttus_Config2__PriceList__c priceList = APTS_TestDataFactory.createPriceList('JDETest Price List');
            Database.insert(priceList);
            
            Apttus_Config2__BillingPreference__c oBillingPreference = APTS_TestDataFactory.createBillingPrefrence('JDETestPrefrence');
            Database.insert(oBillingPreference);

        Apttus_Config2__PriceListItem__c oPriceListItemBundle = APTS_TestDataFactory.createPriceListItem(priceList.Id, oBundleProduct.Id);
            oPriceListItemBundle.APTS_Call_Out_Coverage__c = 10;
            oPriceListItemBundle.APTS_Labour_Coverage__c = 10;
            oPriceListItemBundle.APTS_Spare_Parts_Coverage__c = 10;
            insert oPriceListItemBundle;
            Apttus_Config2__PriceListItem__c oPriceListItemOption = APTS_TestDataFactory.createPriceListItem(priceList.Id, oOptionProduct.Id);
           insert oPriceListItemOption;
      //  Apttus_Config2__ProductOptionComponent__c oProductOptionComponentMachine = getProductOptionComponent('Machine');
        //insert oProductOptionComponentMachine;
        
            
           Apttus__APTS_Agreement__c oAgreement = APTS_TestDataFactory.createAgreement(oContact.Id, PriceList.Id, oAccount.Id, 'Standard Deal', 'Agreement');
            oAgreement.Apttus__Status_Category__c = 'In Effect';
            oAgreement.Apttus__Status__c = 'Activated';
            oAgreement.Apttus__Contract_End_Date__c = Date.Today().addDays(365);
            oAgreement.APTS_Bill_to_Party_Ingredients__c = oAgreement.Apttus__Account__c;
            oAgreement.APTS_Bill_to_Party_MachServ__c = oAgreement.Apttus__Account__c;
            oAgreement.APTS_Payer_Ingredients__c = oAgreement.Apttus__Account__c;
            oAgreement.APTS_Payer_Machines_Services__c = oAgreement.Apttus__Account__c;
            oAgreement.Apttus__Auto_Renewal__c = true;
            Database.insert(oAgreement);

            Apttus_Config2__OrderSystemProperties__c oOrderSystemProperties = APTS_TestDataFactory.getOrderSystemProperties();
            Database.insert(oOrderSystemProperties);

            Apttus_Config2__Order__c oMachineOrder = APTS_TestDataFactory.createOrder(oAccount.Id, PriceList.Id, oContact.Id);
            oMachineOrder.Apttus_Config2__Status__c = 'Pending';
            oMachineOrder.Apttus_Config2__Description__c = 'MachineOrder';
            oMachineOrder.APTS_Order_Sub_Type__c = 'Installation';
            oMachineOrder.APTS_SAP_OrderType__c = 'XA13';
            oMachineOrder.Apttus_Config2__PONumber__c = '123456789';
            oMachineOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get('Machine Order').getRecordTypeId();
           // orderList.add(oMachineOrder);
            Database.insert(oMachineOrder);

            

            

          
            

            Apttus_Config2__ProductAttributeValue__c prdAttValue = new Apttus_Config2__ProductAttributeValue__c();
            prdAttValue.APTS_Type_of_Consumption__c = 'Both';
            prdAttValue.APTS_Number_of_months__c = '9';
            prdAttValue.APTS_WTS_Changed_By__c = 'Customer';
            prdAttValue.APTS_Refurbished__c = 'Yes';
            Database.insert(prdAttValue, false);

            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = new List<Apttus_Config2__OrderLineItem__c>();
            

            Apttus_Config2__OrderLineItem__c oOrderLineItemBundle = APTS_TestDataFactory.createOrderLineItem(oMachineOrder, oPriceListItemBundle.Id, null, oBundleProduct.Id, null,null,null, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 200.0, 20.0);
            oOrderLineItemBundle.Apttus_Config2__FulfilledQuantity__c = 20;
            oOrderLineItemBundle.Apttus_Config2__LineNumber__c=1;
            oOrderLineItemBundle.Apttus_Config2__IsPrimaryLine__c = true;
            oOrderLineItemBundle.APTS_Item_Relevant_for_SAP__c = true;
            oOrderLineItemBundle.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
            oOrderLineItemBundle.APTS_Material_Availability_Date__c = Date.today();
            oOrderLineItemBundle.Apttus_Config2__LineType__c = 'Product/Service';
            oOrderLineItemBundle.APTS_Type_of_Contract__c = 'Sales';
            oOrderLineItemBundle.Apttus_Config2__Status__c='Pending';
            oOrderLineItemBundle.APTS_Item_Relevant_for_SAP__c=true;
            oOrderLineItemBundle.APTS_Reason_For_Rejection__c='27';
            oOrderLineItemBundle.Apttus_Config2__ChargeType__c = 'Sales Price';
            orderLineItemList.add(oOrderLineItemBundle);

            Apttus_Config2__OrderLineItem__c oOrderLineItemOption = APTS_TestDataFactory.createOrderLineItem(oMachineOrder, oPriceListItemOption.Id, null, oOptionProduct.Id, null, null, null, 1, 1, 1, 'Option', oBillingPreference.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 200.0, 20.0);
            oOrderLineItemOption.Apttus_Config2__FulfilledQuantity__c = 20;
            oOrderLineItemOption.Apttus_Config2__LineNumber__c=1;
            oOrderLineItemOption.Apttus_Config2__IsPrimaryLine__c = true;
            oOrderLineItemOption.Apttus_Config2__Status__c='Pending';
            oOrderLineItemOption.APTS_Item_Relevant_for_SAP__c=true;
            oOrderLineItemOption.APTS_Reason_For_Rejection__c='27';
            oOrderLineItemOption.APTS_Item_Relevant_for_SAP__c = true;
            //oOrderLineItemOption.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            
            orderLineItemList.add(oOrderLineItemOption);
            System.assert(orderLineItemList.size()>0);            
            Database.insert(orderLineItemList);
    
        Test.startTest();
        ApexPages.currentPage().getParameters().put('Id',oMachineOrder.Id);       
        APTS_PartialCancellationCtrl instPartial = new APTS_PartialCancellationCtrl();
       
        instPartial.CancelPendingLines();
        instPartial.CancelMultipleBundles();
        Test.stopTest();
        }
        
        @TestVisible private static Apttus_Config2__ProductOptionComponent__c getProductOptionComponent(String sName) {

        Apttus_Config2__ProductOptionComponent__c oProductOptionComponent = [SELECT Id FROM Apttus_Config2__ProductOptionComponent__c WHERE Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c = :sName LIMIT 1];

        return oProductOptionComponent;
    }
}