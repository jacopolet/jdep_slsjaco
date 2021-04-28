/*************************************************************
@Name: APTS_PreviewOrderControllerTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: Preview Order Test
@UsedBy: APTS_PreviewOrderController
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_LSPDetailsControllerTest {

    private static final String ID = System.Label.APTS_Id;

    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        System.assert(oTestUser != Null);
    }

    @isTest static void test_LSPDetailsController() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);

        Apttus_Config2__LineItem__c oLineItem = lineItemList.get(1);
        oLineItem.Apttus_Config2__ChargeType__c = 'Sales Price';
        oLineItem.Apttus_Config2__LineType__c = 'Product/Service';
        oLineItem.Apttus_Config2__LineNumber__c = 1;
        
        System.assertEquals('Sales Price',oLineItem.Apttus_Config2__ChargeType__c);
        System.assertEquals('Product/Service',oLineItem.Apttus_Config2__LineType__c);

        lineItemList[0].Apttus_Config2__LineNumber__c = 1;
        Database.update(lineItemList);

        Apttus_Config2__ProductAttributeValue__c oProductAttributeValue = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c = oLineItem.Id);
        oProductAttributeValue.APTS_Type_of_Contract__c = 'Sales';
        Database.insert(oProductAttributeValue);

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(ID, lineItemList[0].Id);
            ApexPages.currentPage().getParameters().put('configId', oProductConfiguration.Id);
            ApexPages.currentPage().getParameters().put('lineNum', '1');

            APTS_LSPDetailsController oLSPDetailsController = new APTS_LSPDetailsController();
            oLSPDetailsController.addLSPDetails();
            oLSPDetailsController.back();
        }
               

        test.stopTest();
    }

    @isTest static void test_CommercialSwapchanges() {
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);

        orderLineItemList[0].APTS_Serial_Number__c = 'ne1234456';
        orderLineItemList[0].Apttus_Config2__OptionId__c = null;
        Database.update(orderLineItemList[0], false);

        Apttus_Config2__Order__c oOrderClone = oOrder.clone(false, false, false, false);
        oOrderClone.APTS_Order_Sub_Type__c = 'Commercial Swap';
        oOrderClone.APTS_SAP_OrderType__c = 'XA13';
        oOrderClone.Apttus_Config2__ParentOrderId__c = oOrder.Id;
        insert oOrderClone;

        
        Apttus_Config2__ProductConfiguration__c oCartClone = oProductConfiguration.clone(false, false, false, false);
        oCartClone.Apttus_Config2__OrderId__c = oOrderClone.Id;
        insert oCartClone;

        lineItemList[0].Apttus_Config2__ConfigurationId__c = oCartClone.Id;
        lineItemList[0].Apttus_Config2__ItemSequence__c  = 1;
        lineItemList[0].Apttus_Config2__LineNumber__c = 1;
        lineItemList[0].Apttus_Config2__ChargeType__c = 'Sales Price';
        lineItemList[0].Apttus_Config2__LineType__c = 'Product/Service';
        lineItemList[0].APTS_Credit_Proposal_XC09_Block__c = true ;
        lineItemList[0].Apttus_Config2__HasOptions__c = true ;
        lineItemList[0].Apttus_Config2__IsPrimaryLine__c= true ;
        update lineItemList[0];

        Apttus_Config2__ProductAttributeValue__c oProductAttributeValue = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c = lineItemList[0].Id);
        oProductAttributeValue.APTS_Type_of_Contract__c = 'Sales';
        insert oProductAttributeValue;

        test.startTest();

        System.runAs(oTestUser) {
            ApexPages.currentPage().getParameters().put(ID, lineItemList[0].Id);
            ApexPages.currentPage().getParameters().put('configId', oCartClone.Id);
            ApexPages.currentPage().getParameters().put('serialNum', 'ne1234456');
            ApexPages.currentPage().getParameters().put('lineNum', '1');
            ApexPages.currentPage().getParameters().put('creditBlock', 'true');

            APTS_LSPDetailsController oLSPDetailsController = new APTS_LSPDetailsController();
            oLSPDetailsController.oLSPDetail = new APTS_Order_LSP_Details__c();
            oLSPDetailsController.oLSPDetail.APTS_Building__c = 'b1';
            oLSPDetailsController.oLSPDetail.APTS_Floor__c = 'b1';
            oLSPDetailsController.oLSPDetail.APTS_Area__c = 'b1';

            oLSPDetailsController.listSerialNumberWrap[0].isSelected = true;
            oLSPDetailsController.setLSPDetails();
            oLSPDetailsController.addLSPDetails();
            
            List<Apttus_Config2__LineItem__c> listResult = [SELECT Id FROM Apttus_Config2__LineItem__c WHERE ID = :lineItemList[0].Id AND APTS_Serial_Number2__c <> NULL LIMIT 1];
            System.assertNotEquals(TRUE, listResult.isEmpty());
        }
        

        test.stopTest();
    }
    
    @isTest static void test_BilligDetails() {
         User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);

        orderLineItemList[0].APTS_Serial_Number__c = 'ne1234456';
        orderLineItemList[0].Apttus_Config2__OptionId__c = null;
        Database.update(orderLineItemList[0], false);

        Apttus_Config2__Order__c oOrderClone = oOrder.clone(false, false, false, false);
        oOrderClone.APTS_Order_Sub_Type__c = 'Commercial Swap';
        oOrderClone.APTS_SAP_OrderType__c = 'XA13';
        oOrderClone.Apttus_Config2__ParentOrderId__c = oOrder.Id;
        insert oOrderClone;

        
        Apttus_Config2__ProductConfiguration__c oCartClone = oProductConfiguration.clone(false, false, false, false);
        oCartClone.Apttus_Config2__OrderId__c = oOrderClone.Id;
        insert oCartClone;

        lineItemList[0].Apttus_Config2__ConfigurationId__c = oCartClone.Id;
        lineItemList[0].Apttus_Config2__ItemSequence__c  = 1;
        lineItemList[0].Apttus_Config2__LineNumber__c = 1;
        lineItemList[0].Apttus_Config2__ChargeType__c = 'Sales Price';
        lineItemList[0].Apttus_Config2__LineType__c = 'Product/Service';
        update lineItemList[0];

        Apttus_Config2__ProductAttributeValue__c oProductAttributeValue = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c = lineItemList[0].Id);
        oProductAttributeValue.APTS_Type_of_Contract__c = 'Sales';
        insert oProductAttributeValue;

        test.startTest();

        System.runAs(oTestUser) {
            ApexPages.currentPage().getParameters().put(ID, lineItemList[0].Id);
            ApexPages.currentPage().getParameters().put('configId', oCartClone.Id);
            ApexPages.currentPage().getParameters().put('serialNum', 'ne1234456');
            ApexPages.currentPage().getParameters().put('lineNum', '1');

            APTS_LSPDetailsController oLSPDetailsController = new APTS_LSPDetailsController();
            oLSPDetailsController.billingSalesOrg='SAP_0111';
            List<SelectOption> selectOp = oLSPDetailsController.getBillingPrefListbySo();
            List<SelectOption> selectOp1 = oLSPDetailsController.getPaymentMethodbySo();
            List<SelectOption> selectOp2 = oLSPDetailsController.getPaymentTermListbySo();
            PageReference pageRef = oLSPDetailsController.updateAndCascadeBillingDetails();
            
            APTS_LSPDetailsController oLSPDetailsController1 = new APTS_LSPDetailsController();
            oLSPDetailsController1.billingSalesOrg='SAP_0111';
            
            Apttus_Config2__BillingPreference__c pref = APTS_TestDataFactory.createBillingPrefrence('testPref1');
            pref.APTS_SalesOrg__c='SAP_0111';
            insert pref;
            
            Apttus_Config2__PaymentTerm__c payTerm = APTS_TestDataFactory.createPaymentTerm('testPref1','b',10,true,3);
            payTerm.APTS_Sales_Org__c='SAP_0111';
            insert payTerm;
            
            oLSPDetailsController1.selectedPaymentTerm=payTerm.id;
            oLSPDetailsController1.selectedBillingPref=pref.id;
            
            List<SelectOption> selectOp3 = oLSPDetailsController.getBillingPrefListbySo();
            List<SelectOption> selectOp4 = oLSPDetailsController.getPaymentMethodbySo();
            List<SelectOption> selectOp5 = oLSPDetailsController.getPaymentTermListbySo();
            PageReference pageRef1 = oLSPDetailsController1.updateAndCascadeBillingDetails();
        }
        

        test.stopTest();
    }
}