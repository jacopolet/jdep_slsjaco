@isTest
private class APTS_AdminOrderQueueTest {
    
    @testSetup
    static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
    }

    @isTest
    static void testUtil(){
        Contact contact = APTS_TestUtils.createContact();
        Database.insert(contact, false);

        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.insert(priceList, false);
        
        List<Account> childAccountList = new List<Account>();

        Account account = APTS_TestUtils.createaccount();
        insert account;

        Account childAccount = APTS_TestUtils.createChildAccount(account);
        insert childAccount;

		Apttus_Config2__AccountLocation__c location = APTS_TestUtils.createAccountLocation(account.Id);
		insert location;

        childAccountList.add(childAccount);

        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.createAgreement(contact.Id, null, priceList.Id, account.Id);
        agreement.Apttus__Status__c = Label.Apttus.Activated;
        agreement.Apttus__Status_Category__c = Label.APTS_In_Effect;
        agreement.Apttus__Auto_Renewal__c = false;
        agreement.Apttus__Contract_End_Date__c = System.Today() - 1;
        agreement.APTS_Order_Non_Contracted_Products__c = true;
        Database.insert(agreement, false);

        APTS_CLMUtil.setContractedProductsOnly(childAccountList, null);

        Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('January');
        Database.insert(billingPreference, false);
        
        Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('New', priceList.Id, account.Id, billingPreference.Id);
        Database.insert(order, false);
        
        Product2 product = APTS_TestUtils.createProduct('Test Product', '123', 'Machines');
        Database.insert(product, false);
        
        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.createPriceListItem(priceList.Id, product.Id);
        Database.insert(priceListItem, false);

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(agreement);
        Database.insert(oProductConfiguration);
        
        PhysicalAsset__c oPhysicalAsset = new PhysicalAsset__c();       
        oPhysicalAsset.AssetStatus__c = 'Pending Activation';
        oPhysicalAsset.SerialNumber__c = '2186451249';
        Database.insert(oPhysicalAsset, false);        
        
        test.startTest();
			List<Apttus_Config2__OrderLineItem__c> oLIList = new List<Apttus_Config2__OrderLineItem__c>();
			APTS_Order_LSP_Details__c oLSPdetail = new APTS_Order_LSP_Details__c();
			oLSPdetail.APTS_Area__c = 'Test Area';
			oLSPdetail.APTS_Building__c = 'Test Building';
			oLSPdetail.APTS_Floor__c = 'Test Floor';
			oLSPdetail.APTS_SmokingArea__c = true;
			oLSPdetail.APTS_StairClimber__c = true;    
			insert oLSPdetail;
			Apttus_Config2__OrderLineItem__c orderLineItem = new Apttus_Config2__OrderLineItem__c();
			orderLineItem.Apttus_Config2__Status__c = 'Activated';
			orderLineItem.Apttus_Config2__LineType__c = 'Product/Service';
			orderLineItem.APTS_Serial_Number__c = '2186451249';
			orderLineItem.APTS_Physical_Asset__c = oPhysicalAsset.ID;
			orderLineItem.Apttus_Config2__OrderId__c = order.id;
			orderLineItem.Apttus_Config2__LocationId__c = location.Id;
			orderLineItem.APTS_Order_LSP_Detail__c = oLSPdetail.Id;
			oLIList.add(orderLineItem);
        
			Apttus_Config2__OrderLineItem__c orderLineItem1 = new Apttus_Config2__OrderLineItem__c();
			orderLineItem1.Apttus_Config2__Status__c = 'Activated';
			orderLineItem1.Apttus_Config2__LineType__c = 'Option';
			orderLineItem1.APTS_Serial_Number__c = '2186451249';
			orderLineItem1.Apttus_Config2__OrderId__c = order.id;
			orderLineItem1.APTS_Order_LSP_Detail__c = oLSPdetail.Id;
			oLIList.add(orderLineItem1);
        
			Apttus_Config2__OrderLineItem__c orderLineItem2 = new Apttus_Config2__OrderLineItem__c();
			orderLineItem2.Apttus_Config2__Status__c = 'Cancelled';
			orderLineItem2.Apttus_Config2__LineType__c = 'Option';
			orderLineItem2.Apttus_Config2__NetPrice__c = -1;
			orderLineItem2.Apttus_Config2__OrderId__c = order.id;
			orderLineItem2.APTS_Order_LSP_Detail__c = oLSPdetail.Id;
			oLIList.add(orderLineItem2);
        
			Database.insert(oLIList, false);
        
			Apttus_Config2__AssetLineItem__c assetLineItem = APTS_TestUtils.createAssetLineItem(account.Id, product.Id, priceList.Id, priceListItem.Id, billingPreference.Id, order.Id);
			assetLineItem.Apttus_Config2__ChargeType__c = 'Sales Price';
			assetLineItem.Apttus_Config2__HasOptions__c = true;
			Database.insert(assetLineItem, false);
                
			APTS_AdminOrderQueue.reCalculateNetPrice(order.Id);
        test.stopTest();
        APTS_AdminOrderQueue.getAgreementPODetails(new Set<Id>{agreement.id});
		APTS_AdminOrderQueue.populatePAFieldsForMovement(new Map<Id,Apttus_Config2__OrderLineItem__c>{orderLineItem.Id => orderLineItem});
    }

    @isTest
    static void testReCalculateNetPrice(){
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = [Select ID from Apttus_Config2__ProductConfiguration__c where APTS_Flow__c =: System.Label.APTS_NGStandardOrder LIMIT 1];
        Apttus_Config2__Order__c order = [Select ID from Apttus_Config2__Order__c where Apttus_Config2__PONumber__c = '123456789' LIMIT 1];
        List<Apttus_Config2__OrderLineItem__c> orderLineList = [Select ID, Apttus_Config2__LineType__c from Apttus_Config2__OrderLineItem__c where Apttus_Config2__OrderId__c =: order.ID];
        for(Apttus_Config2__OrderLineItem__c orderLineSO : orderLineList){
            if(orderLineSO.Apttus_Config2__LineType__c == 'Option'){
                orderLineSO.Apttus_Config2__LineStatus__c = 'Cancelled';
                orderLineSO.Apttus_Config2__NetPrice__c = -1000;
                orderLineSO.Apttus_Config2__ChargeType__c = 'Sales Price';
            }
            else{
                orderLineSO.Apttus_Config2__ChargeType__c = 'Sales Price';
            }
        }
        update orderLineList;
        test.startTest();
			APTS_AdminOrderQueue.reCalculateNetPrice(order.Id);
			System.enqueueJob(new APTS_AdminOrderQueue(oProductConfiguration.id,order.Id,false));
        test.stopTest();
    }

    @isTest
    static void testrePriceOrder(){
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = [Select ID from Apttus_Config2__ProductConfiguration__c where APTS_Flow__c =: System.Label.APTS_NGStandardOrder LIMIT 1];
        Apttus_Config2__Order__c order = [Select ID from Apttus_Config2__Order__c where Apttus_Config2__PONumber__c = '123456789' LIMIT 1];
        test.startTest();
			//APTS_AdminOrderQueue.finalizeAdminOrders(oProductConfiguration.id,order.Id);
			System.enqueueJob(new APTS_FinalizeAdminOrdersQueue(oProductConfiguration.id,order.Id,'reprice'));
        test.stopTest();
		
    }

    @isTest
    static void testFinalizeOrder(){
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = [Select ID from Apttus_Config2__ProductConfiguration__c where APTS_Flow__c =: System.Label.APTS_NGStandardOrder LIMIT 1];
        Apttus_Config2__Order__c order = [Select ID from Apttus_Config2__Order__c where Apttus_Config2__PONumber__c = '123456789' LIMIT 1];
        test.startTest();
			//APTS_AdminOrderQueue.finalizeAdminOrders(oProductConfiguration.id,order.Id);
			System.enqueueJob(new APTS_FinalizeAdminOrdersQueue(oProductConfiguration.id,order.Id,'finalizeCart'));
        test.stopTest();		
    }

    @isTest
    static void testAcceptOrder(){
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = [Select ID from Apttus_Config2__ProductConfiguration__c where APTS_Flow__c =: System.Label.APTS_NGStandardOrder LIMIT 1];
        Apttus_Config2__Order__c order = [Select ID from Apttus_Config2__Order__c where Apttus_Config2__PONumber__c = '123456789' LIMIT 1];
        test.startTest();
			//APTS_AdminOrderQueue.finalizeAdminOrders(oProductConfiguration.id,order.Id);
			System.enqueueJob(new APTS_FinalizeAdminOrdersQueue(oProductConfiguration.id,order.Id,'acceptOrder'));
        test.stopTest();		
		APTS_AdminOrderQueue.updatePhyAssetOnMovement(order.Id);	
    }
}