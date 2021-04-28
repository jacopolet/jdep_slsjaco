/*************************************************************
	@Name: APTS_IndexationBatch_Phase3_Test
	@Author: Aswin Selvaraj
	@CreateDate: 26-03-2019
	@Description: Apex Class to test APTS_IndexationBatch_Phase3 Class 
	******************************************************************/
	@isTest
	private class APTS_IndexationBatch_Phase3_Test{
		
		@isTest
		static void indexTransactionmethod(){
				System.debug('**************METHOD 1*************');
				Account acc = APTS_TestUtils.createaccount();
				Database.insert(acc,false);

				APTS_AssetRenewalRollbackBatch.bypassCurrentUserfromTriggersandFlows();
				
				Contact cont = APTS_TestUtils.createContact();
				Database.insert(cont,false);
				
				Apttus_Config2__PriceList__c plist = APTS_TestUtils.createPriceList();
				Database.insert(plist,false);
				
				List<Apttus__APTS_Agreement__c> agrlst = new List<Apttus__APTS_Agreement__c>(); 
				
				Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(cont.Id,null,plist.Id,acc.Id);
				aggr.Apttus__Contract_End_Date__c = System.today()-1;
				aggr.Apttus__Account__c = acc.Id;
				aggr.Apttus__Status_Category__c = 'In Effect';
				aggr.Apttus__Status__c = 'Activated';
				aggr.Apttus__Contract_Start_Date__c = System.today()-50;
				aggr.Apttus__Auto_Renewal__c = true;
				aggr.APTS_Language__c = 'SAP_3A'; 
				aggr.APTS_Distribution_Channel__c =null;
				aggr.Apttus_CMConfig__BillingPreferenceId__c = null;
				aggr.Apttus_CMConfig__PONumber__c = null;
				aggr.Apttus_CMConfig__PaymentTermId__c = null;
				aggr.APTS_Bill_to_Party_Ingredients__c = null;
				aggr.APTS_Payer_Ingredients__c = null;
				aggr.APTS_Bill_to_Party_MachServ__c = null;
				aggr.APTS_Payer_Machines_Services__c = null;
				agrlst.add(aggr);
				Database.insert(agrlst,false); 
				
				Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
				tstAsset.Apttus_Config2__LineNumber__c = 1;
				tstAsset.Apttus_Config2__PrimaryLineNumber__c = 1;
				tstAsset.Apttus_Config2__NetPrice__c = 100;
				tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
				tstAsset.APTS_Old_Net_Price__c = 100;
				//tstAsset.APTS_Is_Primary_L1_Asset__r.name = asset.Name;
				tstAsset.Apttus_Config2__HasOptions__c = true;
				tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
				tstAsset.Apttus_Config2__ChargeType__c = 'Sales Price';
				tstAsset.APTS_Type_Of_Contract__c = 'Sales';
				tstAsset.APTS_Is_Primary_L1_Line__c = true;
				tstAsset.Apttus_Config2__IsPrimaryLine__c = true;
				tstAsset.Apttus_CMConfig__AgreementId__c = aggr.Id;
				tstAsset.APTS_relatedlist_agreement__c = aggr.Id;
				tstAsset.Apttus_Config2__AccountId__c = acc.Id;
				tstAsset.APTS_Option_Group_Text__c = 'Technical Service';
				tstAsset.APTS_Is_Indexation_Executed__c = false;
				tstAsset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
				tstAsset.Apttus_Config2__Quantity__c=1;
				tstAsset.CurrencyIsoCode='EUR';
				insert tstAsset;
				
				List<Apttus_Config2__AssetLineItem__c> assetlst = new List<Apttus_Config2__AssetLineItem__c>();
				Apttus_Config2__AssetLineItem__c asset = new Apttus_Config2__AssetLineItem__c();
				//asset.Name = 'Test Asset';
				asset.Apttus_Config2__AssetStatus__c = 'Activated';
				asset.APTS_Old_Net_Price__c = 100;
				asset.Apttus_Config2__LineType__c = 'option';
				asset.Apttus_Config2__ChargeType__c = 'Sales Price';
				asset.APTS_Type_Of_Contract__c = 'Sales';
				asset.Apttus_CMConfig__AgreementId__c = aggr.Id;
				asset.APTS_relatedlist_agreement__c = aggr.Id;
				asset.Apttus_Config2__AccountId__c = acc.Id;
				asset.APTS_Option_Group_Text__c = 'Technical Service';
				asset.APTS_Is_Indexation_Executed__c = false;
				asset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
				asset.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
				asset.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
				asset.Apttus_Config2__Quantity__c=1;
				assetlst.add(asset);
				//insert asset;   
				
				Apttus_Config2__AssetLineItem__c asset1 = new Apttus_Config2__AssetLineItem__c();
				//asset.Name = 'Test Asset';
				asset1.Apttus_Config2__AssetStatus__c = 'Activated';
				asset1.APTS_Old_Net_Price__c = 100;
				asset1.Apttus_Config2__LineType__c = 'option';
				asset1.Apttus_Config2__ChargeType__c = 'Sales Price';
				asset1.APTS_Type_Of_Contract__c = 'Sales';
				asset1.Apttus_CMConfig__AgreementId__c = aggr.Id;
				asset1.APTS_relatedlist_agreement__c = aggr.Id;
				asset1.Apttus_Config2__AccountId__c = acc.Id;
				asset1.APTS_Option_Group_Text__c = 'Machine Care';
				asset1.APTS_Is_Indexation_Executed__c = false;
				asset1.Apttus_Config2__EndDate__c = Date.today().addDays(100);
				asset1.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
				asset1.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
				asset1.Apttus_Config2__Quantity__c=1;
				assetlst.add(asset1);
				
				Apttus_Config2__AssetLineItem__c asset2 = new Apttus_Config2__AssetLineItem__c();
				//asset.Name = 'Test Asset';
				asset2.Apttus_Config2__AssetStatus__c = 'Activated';
				asset2.APTS_Old_Net_Price__c = 100;
				asset2.Apttus_Config2__LineType__c = 'option';
				asset2.Apttus_Config2__ChargeType__c = 'Sales Price';
				asset2.APTS_Type_Of_Contract__c = 'Sales';
				asset2.Apttus_CMConfig__AgreementId__c = aggr.Id;
				asset2.APTS_relatedlist_agreement__c = aggr.Id;
				asset2.Apttus_Config2__AccountId__c = acc.Id;
				asset2.APTS_Option_Group_Text__c = 'Value Added Machine Care';
				asset2.APTS_Is_Indexation_Executed__c = false;
				asset2.Apttus_Config2__EndDate__c = Date.today().addDays(100);
				asset2.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
				asset2.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
				asset2.Apttus_Config2__Quantity__c=1;
				assetlst.add(asset2);
				Database.insert(assetlst,false);  
				
				Apttus_Config2__BillingPreference__c billpref = APTS_TestUtils.createBillingPrefrence('January');
				insert billpref;
				
				Apttus_Config2__Order__c standardOrder = APTS_TestUtils.createOrder('Admin Order',plist.id,acc.Id,billpref.id);
				standardOrder.Apttus_CMConfig__AgreementId__c = aggr.id;
				standardOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(System.Label.APTS_Standard_Order).getRecordTypeId();    
				standardOrder.Apttus_Config2__SoldToAccountId__c = acc.id;
				standardOrder.APTS_Requested_Installation_Date__c=null;
				insert standardOrder;
				
				Apttus_Config2__ProductConfiguration__c standardProdConfig = new Apttus_Config2__ProductConfiguration__c(
					Apttus_Config2__AccountId__c=acc.id, 
					Name = 'Sample', 
					Apttus_Config2__OrderId__c = standardOrder.id, 
					Apttus_Config2__PriceListId__c = plist.id);
				insert standardProdConfig;
				
				Product2 prod2 = APTS_TestDataFactory.createProduct('JDETestAccount', 'JDETestAccount', 'JDETestAccount', 'Standalone', FALSE, FALSE);
				prod2.APTS_Category_Adjustments_Product__c = false;
				insert prod2;
				
				Product2 freightCharges = APTS_TestUtils.createProduct(System.Label.APTS_FREIGHT_CHARGES_PRODUCT_NAME, '26940992', 'Machines'); 
				Database.insert(freightCharges);
				
				Apttus_Config2__PriceListItem__c oPriceListFC = APTS_TestDataFactory.createPriceListItem(plist.Id, freightCharges.Id);
				Database.insert(oPriceListFC);
				
				Apttus_Config2__LineItem__c lineItem2 = APTS_TestDataFactory.createLineItem(standardProdConfig, oPriceListFC.Id, NULL, prod2.Id, NULL, tstAsset.Id, 2, 2, 2, 'PRODUCT/SERVICE', billpref.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 300, 1);
				lineItem2.Apttus_Config2__PricingStatus__c = 'Completed';
				lineItem2.APTS_Requested_Delivery_Date__c = System.today();
				lineItem2.Apttus_Config2__LineType__c='Option';
				lineItem2.Apttus_Config2__HasOptions__c = false;
				insert lineItem2;
				
				Apttus_Billing__BillingSchedule__c billingSchedules = new Apttus_Billing__BillingSchedule__c(Apttus_Billing__ReadyForInvoiceDate__c = Date.today().addDays(10),
																											Apttus_Billing__AssetLineItemId__c = tstAsset.Id,
																											Apttus_Billing__BillToAccountId__c = acc.Id,
																											Apttus_Billing__Status__c ='Pending Billing',
																											Apttus_Billing__IsSuperseded__c = false,
																											Apttus_Billing__PeriodEndDate__c = Date.today().addDays(40),
																											Apttus_Billing__PeriodStartDate__c = Date.today().addDays(10),
																											Apttus_Billing__FeeAmount__c = 90.00,
																											Apttus_Billing__Type__c = 'Contracted');
				insert billingSchedules;
							
				APTS_Index_Transaction__c index = new APTS_Index_Transaction__c();
				index.APTS_Is_Processed__c = 'Unprocessed';
				index.APTS_Asset_ID__c = tstAsset.id;
				index.APTS_Asset_Line_Item__c = tstAsset.id;
				index.Thread__c = '11';
				index.APTS_Technical_services_Index__c=2;
				index.APTS_Machine_care_Index__c=2;
				insert index;
				list<APTS_Index_Transaction__c> indexLs = new list<APTS_Index_Transaction__c>{index};
					
				test.startTest();
				system.debug('APTS_Index_Transaction__c ++++' + index.APTS_Asset_Line_Item__c );
				system.debug('Method 1 index record ++++' + index);
				APTS_IndexationBatch_Phase3 b = new APTS_IndexationBatch_Phase3('11');
				
				Database.executeBatch(b,11);   
				//b.execute(Null,indexLs);
				//APTS_IndexationBatch_Phase3.activateOrder(standardProdConfig.Id , new list<Id>{tstAsset.id}, standardOrder.Id);
				test.stopTest();
		}
		
		
		 @isTest
		static void indexTransactionmethod2(){
				System.debug('**************METHOD 2*************');
				
				Account acc = APTS_TestUtils.createaccount();
				Database.insert(acc,false);
				
				Contact cont = APTS_TestUtils.createContact();
				Database.insert(cont,false);
				
				Apttus_Config2__PriceList__c plist = APTS_TestUtils.createPriceList();
				Database.insert(plist,false);
				
				List<Apttus__APTS_Agreement__c> agrlst = new List<Apttus__APTS_Agreement__c>(); 
				APTS_AssetRenewalRollbackBatch.bypassCurrentUserfromTriggersandFlows();
				
				Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(cont.Id,null,plist.Id,acc.Id);
				aggr.Apttus__Contract_End_Date__c = System.today()-1;
				aggr.Apttus__Account__c = acc.Id;
				aggr.Apttus__Status_Category__c = 'In Effect';
				aggr.Apttus__Status__c = 'Activated';
				aggr.Apttus__Contract_Start_Date__c = System.today()-50;
				aggr.Apttus__Auto_Renewal__c = true;
				aggr.APTS_Language__c = 'SAP_3A'; 
				aggr.APTS_Distribution_Channel__c =null;
				aggr.Apttus_CMConfig__BillingPreferenceId__c = null;
				aggr.Apttus_CMConfig__PONumber__c = null;
				aggr.Apttus_CMConfig__PaymentTermId__c = null;
				aggr.APTS_Bill_to_Party_Ingredients__c = null;
				aggr.APTS_Payer_Ingredients__c = null;
				aggr.APTS_Bill_to_Party_MachServ__c = null;
				aggr.APTS_Payer_Machines_Services__c = null;
				agrlst.add(aggr);
				Database.insert(agrlst,false); 
				
				Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
				tstAsset.Apttus_Config2__LineNumber__c = 1;
				tstAsset.Apttus_Config2__PrimaryLineNumber__c = 1;
				tstAsset.Apttus_Config2__NetPrice__c = 100;
				tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
				tstAsset.APTS_Old_Net_Price__c = 100;
				//tstAsset.APTS_Is_Primary_L1_Asset__r.name = asset.Name;
				tstAsset.Apttus_Config2__HasOptions__c = true;
				tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
				tstAsset.Apttus_Config2__ChargeType__c = 'Sales Price';
				tstAsset.APTS_Type_Of_Contract__c = 'Sales';
				tstAsset.APTS_Is_Primary_L1_Line__c = true;
				tstAsset.Apttus_Config2__IsPrimaryLine__c = true;
				tstAsset.Apttus_CMConfig__AgreementId__c = aggr.Id;
				tstAsset.APTS_relatedlist_agreement__c = aggr.Id;
				tstAsset.Apttus_Config2__AccountId__c = acc.Id;
				tstAsset.APTS_Option_Group_Text__c = 'Technical Service';
				tstAsset.APTS_Is_Indexation_Executed__c = false;
				tstAsset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
				tstAsset.Apttus_Config2__Quantity__c=1;
				insert tstAsset;
				
				List<Apttus_Config2__AssetLineItem__c> assetlst = new List<Apttus_Config2__AssetLineItem__c>();
				Apttus_Config2__AssetLineItem__c asset = new Apttus_Config2__AssetLineItem__c();
				//asset.Name = 'Test Asset';
				asset.Apttus_Config2__AssetStatus__c = 'Activated';
				asset.APTS_Old_Net_Price__c = 100;
				asset.Apttus_Config2__LineType__c = 'option';
				asset.Apttus_Config2__ChargeType__c = 'Sales Price';
				asset.APTS_Type_Of_Contract__c = 'Sales';
				asset.Apttus_CMConfig__AgreementId__c = aggr.Id;
				asset.APTS_relatedlist_agreement__c = aggr.Id;
				asset.Apttus_Config2__AccountId__c = acc.Id;
				asset.APTS_Option_Group_Text__c = 'Technical Service';
				asset.APTS_Is_Indexation_Executed__c = false;
				asset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
				asset.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
				asset.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
				asset.Apttus_Config2__Quantity__c=1;
				assetlst.add(asset);
				//insert asset;   
				
				Apttus_Config2__AssetLineItem__c asset1 = new Apttus_Config2__AssetLineItem__c();
				//asset.Name = 'Test Asset';
				asset1.Apttus_Config2__AssetStatus__c = 'Activated';
				asset1.APTS_Old_Net_Price__c = 100;
				asset1.Apttus_Config2__LineType__c = 'option';
				asset1.Apttus_Config2__ChargeType__c = 'Sales Price';
				asset1.APTS_Type_Of_Contract__c = 'Sales';
				asset1.Apttus_CMConfig__AgreementId__c = aggr.Id;
				asset1.APTS_relatedlist_agreement__c = aggr.Id;
				asset1.Apttus_Config2__AccountId__c = acc.Id;
				asset1.APTS_Option_Group_Text__c = 'Machine Care';
				asset1.APTS_Is_Indexation_Executed__c = false;
				asset1.Apttus_Config2__EndDate__c = Date.today().addDays(100);
				asset1.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
				asset1.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
				asset1.Apttus_Config2__Quantity__c=1;
				asset1.Apttus_Config2__BasePrice__c=10;
                asset1.APTS_BasePriceOverride__c=10;
				assetlst.add(asset1);
				
				Apttus_Config2__AssetLineItem__c asset2 = new Apttus_Config2__AssetLineItem__c();
				//asset.Name = 'Test Asset';
				asset2.Apttus_Config2__AssetStatus__c = 'Activated';
				asset2.APTS_Old_Net_Price__c = 100;
				asset2.Apttus_Config2__LineType__c = 'option';
				asset2.Apttus_Config2__ChargeType__c = 'Sales Price';
				asset2.APTS_Type_Of_Contract__c = 'Sales';
				asset2.Apttus_CMConfig__AgreementId__c = aggr.Id;
				asset2.APTS_relatedlist_agreement__c = aggr.Id;
				asset2.Apttus_Config2__AccountId__c = acc.Id;
				asset2.APTS_Option_Group_Text__c = 'Value Added Machine Care';
				asset2.APTS_Is_Indexation_Executed__c = false;
				asset2.Apttus_Config2__EndDate__c = Date.today().addDays(100);
				asset2.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
				asset2.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
                asset2.Apttus_Config2__Quantity__c=1;
                asset2.Apttus_Config2__BasePrice__c=10;
                asset2.APTS_BasePriceOverride__c=null;
                //asset2.basepriceo=10;
				assetlst.add(asset2);
                
				insert assetlst;
							
				APTS_Index_Transaction__c index = new APTS_Index_Transaction__c();
				index.APTS_Is_Processed__c = 'Unprocessed';
				index.APTS_Technical_services_Index__c=2;
				index.APTS_Machine_care_Index__c=2;
				index.APTS_Asset_ID__c = tstAsset.id;
				index.APTS_Asset_Line_Item__c = tstAsset.id;
				index.Thread__c='1';
				insert index;
				
				Apttus_Config2__BillingPreference__c billpref = APTS_TestUtils.createBillingPrefrence('January');
				insert billpref;
				
				Apttus_Config2__Order__c standardOrder = APTS_TestUtils.createOrder('Admin Order',plist.id,acc.Id,billpref.id);
				standardOrder.Apttus_CMConfig__AgreementId__c = aggr.id;
				standardOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(System.Label.APTS_Standard_Order).getRecordTypeId();    
				standardOrder.Apttus_Config2__SoldToAccountId__c = acc.id;
				standardOrder.APTS_Requested_Installation_Date__c=null;
				standardOrder.APTS_Indexation_source_id__c=index.id;
				insert standardOrder;
				
				Apttus_Config2__ProductConfiguration__c standardProdConfig = new Apttus_Config2__ProductConfiguration__c(
					Apttus_Config2__AccountId__c=acc.id, 
					Name = 'Sample', 
					Apttus_Config2__OrderId__c = standardOrder.id, 
					Apttus_Config2__PriceListId__c = plist.id);
				insert standardProdConfig;
				
				Product2 prod2 = APTS_TestDataFactory.createProduct('JDETestAccount', 'JDETestAccount', 'JDETestAccount', 'Standalone', FALSE, FALSE);
				prod2.APTS_Category_Adjustments_Product__c = false;
				insert prod2;

				Product2 prod3 = APTS_TestDataFactory.createProduct('JDETestAccount1', 'JDETestAccount1', 'JDETestAccount1', 'Standalone', FALSE, FALSE);
				prod3.APTS_Category_Adjustments_Product__c = false;
				insert prod3;

				Product2 prod4 = APTS_TestDataFactory.createProduct('JDETestAccount2', 'JDETestAccount2', 'JDETestAccount2', 'Standalone', FALSE, FALSE);
				prod4.APTS_Category_Adjustments_Product__c = false;
				insert prod4;
				
				Product2 freightCharges = APTS_TestUtils.createProduct(System.Label.APTS_FREIGHT_CHARGES_PRODUCT_NAME, '26940992', 'Machines'); 
				Database.insert(freightCharges);
				
				Apttus_Config2__PriceListItem__c oPriceListFC = APTS_TestDataFactory.createPriceListItem(plist.Id, freightCharges.Id);
				Database.insert(oPriceListFC);
				
				Apttus_Config2__LineItem__c lineItem2 = APTS_TestDataFactory.createLineItem(standardProdConfig, oPriceListFC.Id, NULL, prod2.Id, NULL,asset2.id, 2, 2, 2, 'PRODUCT/SERVICE', billpref.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 300, 1);
				lineitem2.Apttus_Config2__ChargeType__c = 'Service Fee';
				lineItem2.Apttus_Config2__PricingStatus__c = 'Completed';
				lineItem2.APTS_Requested_Delivery_Date__c = System.today();
				lineitem2.Apttus_Config2__PriceType__c = 'Recurring';
				lineItem2.Apttus_Config2__LineType__c='Option';
                lineItem2.Apttus_Config2__HasOptions__c = false;
				lineitem2.Apttus_Config2__OptionId__c=prod3.id;
				lineitem2.Apttus_Config2__AssetLineItemId__c=asset2.id;
				insert lineItem2;

				Apttus_Config2__LineItem__c lineItem3 = APTS_TestDataFactory.createLineItem(standardProdConfig, oPriceListFC.Id, NULL, prod2.Id, NULL,asset1.id, 2, 2, 2, 'PRODUCT/SERVICE', billpref.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 300, 1);
				lineitem2.Apttus_Config2__ChargeType__c = 'Rental Fee';
				lineItem3.Apttus_Config2__PricingStatus__c = 'Completed';
				lineItem3.APTS_Requested_Delivery_Date__c = System.today();
				lineItem3.Apttus_Config2__LineType__c='Option';
				lineitem3.Apttus_Config2__PriceType__c = 'Recurring';
                lineItem3.Apttus_Config2__HasOptions__c = false;
				lineitem3.Apttus_Config2__OptionId__c=prod4.id;
				lineitem3.Apttus_Config2__AssetLineItemId__c=asset1.id;
				lineitem3.Apttus_Config2__BasePriceOverride__c=10;
				insert lineItem3;

				Apttus_Config2__LineItem__c queriedLine = [SELECT Id,
															APTS_Type_of_Contract__c,
															Apttus_Config2__ChargeType__c,
															Apttus_Config2__AssetLineItemId__c,APTS_Option_Group_Text__c,
															Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c,
															Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
															Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,
															Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c,
															Apttus_Config2__OptionId__r.name,
															Apttus_Config2__StartDate__c,
															APTS_is_Indexation_skip__c,
															Apttus_Config2__Description__c,
															Apttus_Config2__LineType__c,
															Apttus_Config2__BasePriceOverride__c,
															Apttus_Config2__BasePrice__c
															FROM Apttus_Config2__LineItem__c where id=: lineItem2.id];
				
				Apttus_Config2__LineItem__c queriedLine1 = [SELECT Id,
															APTS_Type_of_Contract__c,
															Apttus_Config2__ChargeType__c,
															Apttus_Config2__AssetLineItemId__c,APTS_Option_Group_Text__c,
															Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c,
															Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
															Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,
															Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c,
															Apttus_Config2__OptionId__r.name,
															Apttus_Config2__StartDate__c,
															APTS_is_Indexation_skip__c,
															Apttus_Config2__Description__c,
															Apttus_Config2__LineType__c,
															Apttus_Config2__BasePriceOverride__c,
															Apttus_Config2__BasePrice__c
															FROM Apttus_Config2__LineItem__c where id=: lineItem3.id];

				Apttus_Billing__BillingSchedule__c billingSchedules = new Apttus_Billing__BillingSchedule__c(Apttus_Billing__ReadyForInvoiceDate__c = Date.today().addDays(10),
																											Apttus_Billing__AssetLineItemId__c = tstAsset.Id,
																											Apttus_Billing__BillToAccountId__c = acc.Id,
																											Apttus_Billing__Status__c ='Pending Billing',
																											Apttus_Billing__IsSuperseded__c = false,
																											Apttus_Billing__PeriodEndDate__c = Date.today().addDays(40),
																											Apttus_Billing__PeriodStartDate__c = Date.today().addDays(10),
																											Apttus_Billing__FeeAmount__c = 90.00,
																											Apttus_Billing__Type__c = 'Contracted');
				insert billingSchedules;
				list<APTS_Index_Transaction__c> indexLs = new list<APTS_Index_Transaction__c>{index};
				system.debug('Method 2 index record ++++' + index);    
				Map<String,Date> minAssetPendingBillingDateMap = new Map<String,Date>();
				List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c>();
				Map<String,Decimal> indexBundlePercentageMap = new Map<String,Decimal>();
				Map<Id,String> bundleIdAdditionalInfoMap = new  Map<Id,String>();
				minAssetPendingBillingDateMap.put(asset2.id,System.today().addDays(10));
				indexBundlePercentageMap.put(tstAsset.Id+'Technical Services',2.2);
				indexBundlePercentageMap.put(tstAsset.Id+'Machine Care Service',2.2);
				minAssetPendingBillingDateMap.put(asset1.id,System.today().addDays(10));
				//indexBundlePercentageMap.put(asset1.id+'Technical Services',2.2);
				//indexBundlePercentageMap.put(asset1.id+'Machine Care Service',2.2);
				test.startTest();
				APTS_IndexationBatch_Phase3.manageIndexedOptionLineItems(queriedLine,indexBundlePercentageMap,minAssetPendingBillingDateMap,lineItemList);
				APTS_IndexationBatch_Phase3.manageIndexedOptionLineItems(queriedLine1,indexBundlePercentageMap,minAssetPendingBillingDateMap,lineItemList);
				minAssetPendingBillingDateMap.clear();
				asset2.Apttus_Config2__BasePrice__c=0;
				asset2.APTS_BasePriceOverride__c=null;
				update asset2;
				asset1.APTS_BasePriceOverride__c=0;
				update asset1;
				Apttus_Config2__LineItem__c queriedLine3 = [SELECT Id,
				APTS_Type_of_Contract__c,
				Apttus_Config2__ChargeType__c,
				Apttus_Config2__AssetLineItemId__c,APTS_Option_Group_Text__c,
				Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c,
				Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
				Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,
				Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c,
				Apttus_Config2__OptionId__r.name,
				Apttus_Config2__StartDate__c,
				APTS_is_Indexation_skip__c,
				Apttus_Config2__Description__c,
				Apttus_Config2__LineType__c,
				Apttus_Config2__BasePriceOverride__c,
				Apttus_Config2__BasePrice__c
				FROM Apttus_Config2__LineItem__c where id=: lineItem2.id];

				Apttus_Config2__LineItem__c queriedLine4 = [SELECT Id,
				APTS_Type_of_Contract__c,
				Apttus_Config2__ChargeType__c,
				Apttus_Config2__AssetLineItemId__c,APTS_Option_Group_Text__c,
				Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c,
				Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
				Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,
				Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c,
				Apttus_Config2__OptionId__r.name,
				Apttus_Config2__StartDate__c,
				APTS_is_Indexation_skip__c,
				Apttus_Config2__Description__c,
				Apttus_Config2__LineType__c,
				Apttus_Config2__BasePriceOverride__c,
				Apttus_Config2__BasePrice__c
				FROM Apttus_Config2__LineItem__c where id=: lineItem3.id];
				APTS_IndexationBatch_Phase3.addAdditionalInfoOnProcessedItems(queriedLine3,minAssetPendingBillingDateMap,bundleIdAdditionalInfoMap);
				APTS_IndexationBatch_Phase3.addAdditionalInfoOnProcessedItems(queriedLine4,minAssetPendingBillingDateMap,bundleIdAdditionalInfoMap);
				Database.executeBatch(new APTS_IndexationRollbackBatch(),200);
				test.stopTest();

		}
		
		@isTest
		static void catchBlockTest(){
				System.debug('**************METHOD 2*************');
				
				Account acc = APTS_TestUtils.createaccount();
				Database.insert(acc,false);
				
				Contact cont = APTS_TestUtils.createContact();
				Database.insert(cont,false);
				
				Apttus_Config2__PriceList__c plist = APTS_TestUtils.createPriceList();
				Database.insert(plist,false);
				
				List<Apttus__APTS_Agreement__c> agrlst = new List<Apttus__APTS_Agreement__c>(); 
				APTS_AssetRenewalRollbackBatch.bypassCurrentUserfromTriggersandFlows();
				
				Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(cont.Id,null,null,acc.Id);
				aggr.Apttus__Contract_End_Date__c = System.today()-1;
				aggr.Apttus__Account__c = acc.Id;
				aggr.Apttus__Status_Category__c = 'In Effect';
				aggr.Apttus__Status__c = 'Activated';
				aggr.Apttus__Contract_Start_Date__c = System.today()-50;
				aggr.Apttus__Auto_Renewal__c = true;
				aggr.APTS_Language__c = 'SAP_3A'; 
				aggr.APTS_Distribution_Channel__c =null;
				aggr.Apttus_CMConfig__BillingPreferenceId__c = null;
				aggr.Apttus_CMConfig__PONumber__c = null;
				aggr.Apttus_CMConfig__PaymentTermId__c = null;
				aggr.APTS_Bill_to_Party_Ingredients__c = null;
				aggr.APTS_Payer_Ingredients__c = null;
				aggr.APTS_Bill_to_Party_MachServ__c = null;
				aggr.APTS_Payer_Machines_Services__c = null;
				agrlst.add(aggr);
				Database.insert(agrlst,false); 
				
				Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
				tstAsset.Apttus_Config2__LineNumber__c = 1;
				tstAsset.Apttus_Config2__PrimaryLineNumber__c = 1;
				tstAsset.Apttus_Config2__NetPrice__c = 100;
				tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
				tstAsset.APTS_Old_Net_Price__c = 100;
				//tstAsset.APTS_Is_Primary_L1_Asset__r.name = asset.Name;
				tstAsset.Apttus_Config2__HasOptions__c = true;
				tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
				tstAsset.Apttus_Config2__ChargeType__c = 'Sales Price';
				tstAsset.APTS_Type_Of_Contract__c = 'Sales';
				tstAsset.APTS_Is_Primary_L1_Line__c = true;
				tstAsset.Apttus_Config2__IsPrimaryLine__c = true;
				tstAsset.Apttus_CMConfig__AgreementId__c = aggr.Id;
				tstAsset.APTS_relatedlist_agreement__c = aggr.Id;
				tstAsset.Apttus_Config2__AccountId__c = acc.Id;
				tstAsset.APTS_Option_Group_Text__c = 'Technical Service';
				tstAsset.APTS_Is_Indexation_Executed__c = false;
				tstAsset.Apttus_Config2__OriginalStartDate__c= Date.today().addYears(10);
				tstAsset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
				tstAsset.Apttus_Config2__Quantity__c=1;
				tstAsset.Apttus_Config2__PriceListId__c=null;
				insert tstAsset;
				
				List<Apttus_Config2__AssetLineItem__c> assetlst = new List<Apttus_Config2__AssetLineItem__c>();
				Apttus_Config2__AssetLineItem__c asset = new Apttus_Config2__AssetLineItem__c();
				//asset.Name = 'Test Asset';
				asset.Apttus_Config2__AssetStatus__c = 'Activated';
				asset.APTS_Old_Net_Price__c = 100;
				asset.Apttus_Config2__LineType__c = 'option';
				asset.Apttus_Config2__ChargeType__c = 'Sales Price';
				asset.APTS_Type_Of_Contract__c = 'Sales';
				asset.Apttus_CMConfig__AgreementId__c = aggr.Id;
				asset.APTS_relatedlist_agreement__c = aggr.Id;
				asset.Apttus_Config2__AccountId__c = acc.Id;
				asset.APTS_Option_Group_Text__c = 'Technical Service';
				asset.APTS_Is_Indexation_Executed__c = false;
				asset.Apttus_Config2__OriginalStartDate__c= Date.today().addYears(10);
				asset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
				asset.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
				asset.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
				asset.Apttus_Config2__Quantity__c=1;
				asset.Apttus_Config2__PriceListId__c=null;
				assetlst.add(asset);
				//insert asset;   
				
				Apttus_Config2__AssetLineItem__c asset1 = new Apttus_Config2__AssetLineItem__c();
				//asset.Name = 'Test Asset';
				asset1.Apttus_Config2__AssetStatus__c = 'Activated';
				asset1.APTS_Old_Net_Price__c = 100;
				asset1.Apttus_Config2__LineType__c = 'option';
				asset1.Apttus_Config2__ChargeType__c = 'Sales Price';
				asset1.APTS_Type_Of_Contract__c = 'Sales';
				asset1.Apttus_CMConfig__AgreementId__c = aggr.Id;
				asset1.APTS_relatedlist_agreement__c = aggr.Id;
				asset1.Apttus_Config2__AccountId__c = acc.Id;
				asset1.APTS_Option_Group_Text__c = 'Machine Care';
				asset1.APTS_Is_Indexation_Executed__c = false;
				asset1.Apttus_Config2__OriginalStartDate__c= Date.today().addYears(10);
				asset1.Apttus_Config2__EndDate__c = Date.today().addDays(100);
				asset1.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
				asset1.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
				asset1.Apttus_Config2__Quantity__c=1;
				asset1.Apttus_Config2__BasePrice__c=10;
                asset1.APTS_BasePriceOverride__c=10;
				asset1.Apttus_Config2__PriceListId__c=null;
				assetlst.add(asset1);
				
				Apttus_Config2__AssetLineItem__c asset2 = new Apttus_Config2__AssetLineItem__c();
				//asset.Name = 'Test Asset';
				asset2.Apttus_Config2__AssetStatus__c = 'Activated';
				asset2.APTS_Old_Net_Price__c = 100;
				asset2.Apttus_Config2__LineType__c = 'option';
				asset2.Apttus_Config2__ChargeType__c = 'Sales Price';
				asset2.APTS_Type_Of_Contract__c = 'Sales';
				asset2.Apttus_CMConfig__AgreementId__c = aggr.Id;
				asset2.APTS_relatedlist_agreement__c = aggr.Id;
				asset2.Apttus_Config2__AccountId__c = acc.Id;
				asset2.APTS_Option_Group_Text__c = 'Value Added Machine Care';
				asset2.APTS_Is_Indexation_Executed__c = false;
				asset2.Apttus_Config2__OriginalStartDate__c= Date.today().addYears(10);
				asset2.Apttus_Config2__EndDate__c = Date.today().addDays(100);
				asset2.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
				asset2.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
                asset2.Apttus_Config2__Quantity__c=1;
                asset2.Apttus_Config2__BasePrice__c=10;
                asset2.APTS_BasePriceOverride__c=null;
				asset2.Apttus_Config2__PriceListId__c=null;
                //asset2.basepriceo=10;
				assetlst.add(asset2);
                
				insert assetlst;
							
				APTS_Index_Transaction__c index = new APTS_Index_Transaction__c();
				index.APTS_Is_Processed__c = 'Unprocessed';
				index.APTS_Technical_services_Index__c=2;
				index.APTS_Machine_care_Index__c=2;
				index.APTS_Asset_ID__c = tstAsset.id;
				index.APTS_Asset_Line_Item__c = tstAsset.id;
				index.Thread__c='1';
				insert index;
				
				Apttus_Config2__BillingPreference__c billpref = APTS_TestUtils.createBillingPrefrence('January');
				insert billpref;
				
				Apttus_Config2__Order__c standardOrder = APTS_TestUtils.createOrder('Admin Order',plist.id,acc.Id,billpref.id);
				standardOrder.Apttus_CMConfig__AgreementId__c = aggr.id;
				standardOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(System.Label.APTS_Standard_Order).getRecordTypeId();    
				standardOrder.Apttus_Config2__SoldToAccountId__c = acc.id;
				standardOrder.APTS_Requested_Installation_Date__c=null;
				standardOrder.APTS_Indexation_source_id__c=index.id;
				standardOrder.Apttus_Config2__PriceListId__c=null;
				insert standardOrder;
				
				Apttus_Config2__ProductConfiguration__c standardProdConfig = new Apttus_Config2__ProductConfiguration__c(
					Apttus_Config2__AccountId__c=acc.id, 
					Name = 'Sample', 
					Apttus_Config2__OrderId__c = standardOrder.id, 
					Apttus_Config2__PriceListId__c = null);
				insert standardProdConfig;
				
				Product2 prod2 = APTS_TestDataFactory.createProduct('JDETestAccount', 'JDETestAccount', 'JDETestAccount', 'Standalone', FALSE, FALSE);
				prod2.APTS_Category_Adjustments_Product__c = false;
				insert prod2;

				Product2 prod3 = APTS_TestDataFactory.createProduct('JDETestAccount1', 'JDETestAccount1', 'JDETestAccount1', 'Standalone', FALSE, FALSE);
				prod3.APTS_Category_Adjustments_Product__c = false;
				insert prod3;

				Product2 prod4 = APTS_TestDataFactory.createProduct('JDETestAccount2', 'JDETestAccount2', 'JDETestAccount2', 'Standalone', FALSE, FALSE);
				prod4.APTS_Category_Adjustments_Product__c = false;
				insert prod4;
				
				Product2 freightCharges = APTS_TestUtils.createProduct(System.Label.APTS_FREIGHT_CHARGES_PRODUCT_NAME, '26940992', 'Machines'); 
				Database.insert(freightCharges);
				
				Apttus_Config2__PriceListItem__c oPriceListFC = APTS_TestDataFactory.createPriceListItem(plist.Id, freightCharges.Id);
				Database.insert(oPriceListFC);
				
				Apttus_Config2__LineItem__c lineItem2 = APTS_TestDataFactory.createLineItem(standardProdConfig, oPriceListFC.Id, NULL, prod2.Id, NULL,asset2.id, 2, 2, 2, 'PRODUCT/SERVICE', billpref.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 300, 1);
				lineitem2.Apttus_Config2__ChargeType__c = 'Service Fee';
				lineItem2.Apttus_Config2__PricingStatus__c = 'Completed';
				lineItem2.APTS_Requested_Delivery_Date__c = System.today();
				lineitem2.Apttus_Config2__PriceType__c = 'Recurring';
				lineItem2.Apttus_Config2__LineType__c='Option';
                lineItem2.Apttus_Config2__HasOptions__c = false;
				lineitem2.Apttus_Config2__OptionId__c=prod3.id;
				lineitem2.Apttus_Config2__AssetLineItemId__c=asset2.id;
				lineitem2.Apttus_Config2__PriceListId__c=null;
				insert lineItem2;

				Apttus_Config2__LineItem__c lineItem3 = APTS_TestDataFactory.createLineItem(standardProdConfig, oPriceListFC.Id, NULL, prod2.Id, NULL,asset1.id, 2, 2, 2, 'PRODUCT/SERVICE', billpref.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 300, 1);
				lineitem2.Apttus_Config2__ChargeType__c = 'Rental Fee';
				lineItem3.Apttus_Config2__PricingStatus__c = 'Completed';
				lineItem3.APTS_Requested_Delivery_Date__c = System.today();
				lineItem3.Apttus_Config2__LineType__c='Option';
				lineitem3.Apttus_Config2__PriceType__c = 'Recurring';
                lineItem3.Apttus_Config2__HasOptions__c = false;
				lineitem3.Apttus_Config2__OptionId__c=prod4.id;
				lineitem3.Apttus_Config2__AssetLineItemId__c=asset1.id;
				lineitem3.Apttus_Config2__BasePriceOverride__c=10;
				insert lineItem3;

				Apttus_Config2__LineItem__c queriedLine = [SELECT Id,
															APTS_Type_of_Contract__c,
															Apttus_Config2__ChargeType__c,
															Apttus_Config2__AssetLineItemId__c,APTS_Option_Group_Text__c,
															Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c,
															Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
															Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,
															Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c,
															Apttus_Config2__OptionId__r.name,
															Apttus_Config2__StartDate__c,
															APTS_is_Indexation_skip__c,
															Apttus_Config2__Description__c,
															Apttus_Config2__LineType__c,
															Apttus_Config2__BasePriceOverride__c,
															Apttus_Config2__BasePrice__c
															FROM Apttus_Config2__LineItem__c where id=: lineItem2.id];
				
				Apttus_Config2__LineItem__c queriedLine1 = [SELECT Id,
															APTS_Type_of_Contract__c,
															Apttus_Config2__ChargeType__c,
															Apttus_Config2__AssetLineItemId__c,APTS_Option_Group_Text__c,
															Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c,
															Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
															Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,
															Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c,
															Apttus_Config2__OptionId__r.name,
															Apttus_Config2__StartDate__c,
															APTS_is_Indexation_skip__c,
															Apttus_Config2__Description__c,
															Apttus_Config2__LineType__c,
															Apttus_Config2__BasePriceOverride__c,
															Apttus_Config2__BasePrice__c
															FROM Apttus_Config2__LineItem__c where id=: lineItem3.id];

				Apttus_Billing__BillingSchedule__c billingSchedules = new Apttus_Billing__BillingSchedule__c(Apttus_Billing__ReadyForInvoiceDate__c = Date.today().addDays(10),
																											Apttus_Billing__AssetLineItemId__c = tstAsset.Id,
																											Apttus_Billing__BillToAccountId__c = acc.Id,
																											Apttus_Billing__Status__c ='Pending Billing',
																											Apttus_Billing__IsSuperseded__c = false,
																											Apttus_Billing__PeriodEndDate__c = Date.today().addDays(40),
																											Apttus_Billing__PeriodStartDate__c = Date.today().addDays(10),
																											Apttus_Billing__FeeAmount__c = 90.00,
																											Apttus_Billing__Type__c = 'Contracted');
				insert billingSchedules;
				list<APTS_Index_Transaction__c> indexLs = new list<APTS_Index_Transaction__c>{index};
				system.debug('Method 2 index record ++++' + index);    
				Map<String,Date> minAssetPendingBillingDateMap = new Map<String,Date>();
				List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c>();
				Map<String,Decimal> indexBundlePercentageMap = new Map<String,Decimal>();
				Map<Id,String> bundleIdAdditionalInfoMap = new  Map<Id,String>();
				minAssetPendingBillingDateMap.put(asset2.id,System.today().addDays(10));
				indexBundlePercentageMap.put(tstAsset.Id+'Technical Services',2.2);
				indexBundlePercentageMap.put(tstAsset.Id+'Machine Care Service',2.2);
				minAssetPendingBillingDateMap.put(asset1.id,System.today().addDays(10));
				//indexBundlePercentageMap.put(asset1.id+'Technical Services',2.2);
				//indexBundlePercentageMap.put(asset1.id+'Machine Care Service',2.2);
				test.startTest();
				APTS_IndexationBatch_Phase3.manageIndexedOptionLineItems(queriedLine,indexBundlePercentageMap,minAssetPendingBillingDateMap,lineItemList);
				APTS_IndexationBatch_Phase3.manageIndexedOptionLineItems(queriedLine1,indexBundlePercentageMap,minAssetPendingBillingDateMap,lineItemList);
				minAssetPendingBillingDateMap.clear();
				asset2.Apttus_Config2__BasePrice__c=0;
				asset2.APTS_BasePriceOverride__c=null;
				update asset2;
				asset1.APTS_BasePriceOverride__c=0;
				update asset1;
				Apttus_Config2__LineItem__c queriedLine3 = [SELECT Id,
				APTS_Type_of_Contract__c,
				Apttus_Config2__ChargeType__c,
				Apttus_Config2__AssetLineItemId__c,APTS_Option_Group_Text__c,
				Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c,
				Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
				Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,
				Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c,
				Apttus_Config2__OptionId__r.name,
				Apttus_Config2__StartDate__c,
				APTS_is_Indexation_skip__c,
				Apttus_Config2__Description__c,
				Apttus_Config2__LineType__c,
				Apttus_Config2__BasePriceOverride__c,
				Apttus_Config2__BasePrice__c
				FROM Apttus_Config2__LineItem__c where id=: lineItem2.id];

				Apttus_Config2__LineItem__c queriedLine4 = [SELECT Id,
				APTS_Type_of_Contract__c,
				Apttus_Config2__ChargeType__c,
				Apttus_Config2__AssetLineItemId__c,APTS_Option_Group_Text__c,
				Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c,
				Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
				Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,
				Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c,
				Apttus_Config2__OptionId__r.name,
				Apttus_Config2__StartDate__c,
				APTS_is_Indexation_skip__c,
				Apttus_Config2__Description__c,
				Apttus_Config2__LineType__c,
				Apttus_Config2__BasePriceOverride__c,
				Apttus_Config2__BasePrice__c
				FROM Apttus_Config2__LineItem__c where id=: lineItem3.id];
				APTS_IndexationBatch_Phase3 b = new APTS_IndexationBatch_Phase3('11');
				Database.executeBatch(b,11);  
				test.stopTest();

		}
	}