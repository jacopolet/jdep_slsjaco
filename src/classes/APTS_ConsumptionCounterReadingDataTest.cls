/*******************************************************************************************
Name            : APTS_ConsumptionCounterReadingDataTest
Created By      : Beulah Ann Thomas
Created Date    : 05/26/2018
Description     : Test class written for 'createVolumeObligationLineItems' method in
                  APTS_BIRUtils.
Version history : v1.0 - Created - 
Classes Covered : APTS_BIRUtils(91% code coverage)
*********************************************************************************************/

@isTest
public with sharing class APTS_ConsumptionCounterReadingDataTest
{
    @TestSetup
    private static void createTestData()
    {
        User testUser = APTS_TestUtils.createUser();
        testUser.LocaleSidKey = 'nl_NL';
        
        System.runAs(testUser) {
        
            TriggerSettings__c settings = new TriggerSettings__c();
            settings.AssetLineItemTrigger__c = true;
            settings.APTS_OrderLineItemTrigger__c = false;
            Database.insert(settings);
            
            ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
            pb.WorkOrderPBFlows__c = true;
            pb.WorkOrderLineItemPBFlows__c = true;
            insert pb;
            
            Account account = APTS_TestUtils.createaccount();
            Database.insert(account);
            
            Account account1 = APTS_TestUtils.createaccount();
            account1.Name = 'TestAccount1';
            account1.Main_Street_Only__c='test address 2';
            account1.Main_House_Number__c='test number 2';
            account1.Main_Postal_Code__c='635110';
            account1.Main_City__c='NewYork';
            Database.insert(account1);
            
            Product2 product = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
            Database.insert(product);

            Product2 product1 = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee1');
            Database.insert(product1);

            Product2 product2 = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee1');
            Database.insert(product2);
            
            Apttus_Config2__PriceList__c  plist = APTS_TestUtils.createPriceList();
            Database.insert(plist,false);
            
            Apttus_Config2__PriceListItem__c pli = APTS_TestUtils.createPriceListItem(plist.Id, product.Id);
            Database.insert(pli,false);
            
            Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
            Database.insert(billpre,false);
            
            Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('test',account.Id,plist.Id,billpre.Id);
            order.APTS_Order_Type__c = 'Machine Order';
            order.APTS_Order_Sub_Type__c = 'Installation';
            order.APTS_SAP_OrderType__c = 'XA13';
            Database.insert(order,false);
            
            Apttus_Config2__Order__c order1 = APTS_TestUtils.createOrder('test2',account.Id,plist.Id,billpre.Id);
            order1.APTS_Order_Type__c = 'Machine Order';
            order1.APTS_Order_Sub_Type__c = 'External Movement With Contract Change';
            order1.APTS_SAP_OrderType__c = 'XA13';
            order1.Apttus_Config2__BillToAccountId__c = account.Id;
            order1.Apttus_Config2__PriceListId__c = plist.Id;
            order1.Apttus_Config2__BillingPreferenceId__c = billpre.Id;
            order1.Apttus_Config2__SoldToAccountId__c = account.Id;
            order1.Apttus_Config2__ShipToAccountId__c = account.Id;
            insert order1;
    
            Contact con = APTS_TestUtils.createContact();
            Database.insert(con,false);
            
            Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, account.Id);
            aggr.Apttus__Status__c = 'In Effect';
            aggr.Apttus__Status_Category__c = 'Being Amended';
            Database.insert(aggr,true);
            
            Apttus__APTS_Agreement__c aggr1 = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, account.Id);
            aggr1.Name = 'AssetUpdateAgree';
            aggr1.Apttus__Status__c = 'In Effect';
            aggr1.Apttus__Status_Category__c = 'Being Amended';
            Database.insert(aggr1,true);
            
            /* Apttus_Config2__ProductOptionComponent__c optiongrpcomp = new Apttus_Config2__ProductOptionComponent__c();
            optiongrpcomp.Apttus_Config2__ProductOptionGroupId__c = Prodoptiongroup.id;
            optiongrpcomp.Apttus_Config2__Sequence__c=5;
            insert optiongrpcomp;
            
            Apttus_Config2__LineItem__c li1 = new Apttus_Config2__LineItem__c();
            li1.Apttus_Config2__OptionId__c = product.Id;
            li1.Apttus_Config2__ProductOptionId__c = optiongrpcomp.id;
            li1.Apttus_Config2__PriceListItemId__c = plist.id;
            li1.Apttus_Config2__AttributeValueId__c=pav1.id;
            li1.Apttus_Config2__LineNumber__c = 5;
            li1.Apttus_Config2__ItemSequence__c = 5;
            li1.Apttus_Config2__ConfigurationId__c = proconfig.id;
            li1.CurrencyIsoCode = 'EUR'; 
            insert li1; */
            
            List<Apttus__AgreementLineItem__c> lstAgreementLineItem = new List<Apttus__AgreementLineItem__c>();
            //APTS_TestUtils.createAgreementLineItem(
            //product.Id, aggr.Id, account.Id, null, plist.Id, null);
            Apttus__AgreementLineItem__c agreementLineItem1 = new Apttus__AgreementLineItem__c();
            agreementLineItem1.Apttus__ProductId__c = product.Id;
            agreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
            //agreementLineItem1.Apttus_CMConfig__DerivedFromId__c = plist .Id;
            //agreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
            agreementLineItem1.Apttus__AgreementId__c = aggr.Id;
           
            agreementLineItem1.CurrencyIsoCode = 'EUR';
            lstAgreementLineItem.add(agreementLineItem1);

            //Agreement Li2
            Apttus__AgreementLineItem__c agreementLineItem2 = new Apttus__AgreementLineItem__c();
            agreementLineItem2.Apttus__ProductId__c = product1.Id;
            agreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
            agreementLineItem2.Apttus__AgreementId__c = aggr.Id;
            agreementLineItem2.CurrencyIsoCode = 'EUR';
            lstAgreementLineItem.add(agreementLineItem2);
            
            INSERT lstAgreementLineItem;
            
            List<PhysicalAsset__c> lstPhysicalAsset = new List<PhysicalAsset__c>();
            
            PhysicalAsset__c physicalAsset1 = APTS_TestUtils.createPhysicalAsset();
            lstPhysicalAsset.add(physicalAsset1);
            
            PhysicalAsset__c physicalAsset2 = APTS_TestUtils.createPhysicalAsset();
            lstPhysicalAsset.add(physicalAsset2);
            
            Database.INSERT(lstPhysicalAsset);
            
            List<Apttus_Config2__AssetLineItem__c> lstAssetLine = new List<Apttus_Config2__AssetLineItem__c>();

            Apttus_Config2__AssetLineItem__c bundleALI =APTS_TestUtils.createAssetLineItem(
                                                   account.Id,product.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
            bundleALI.Apttus_CMConfig__AgreementId__c = aggr.Id;
            bundleALI.Apttus_Config2__AssetStatus__c = 'New';
            bundleALI.APTS_Physical_Asset__c = lstPhysicalAsset[0].Id;
            bundleALI.Apttus_CMConfig__AgreementLineItemId__c = lstAgreementLineItem[0].Id;
            bundleALI.Apttus_Config2__OptionId__c = product.Id;
            bundleALI.APTS_Option_Group_Text__c = '';
            insert bundleALI;

            Apttus_Config2__AssetLineItem__c ali =APTS_TestUtils.createAssetLineItem(
                                                   account.Id,product.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
            ali.Apttus_CMConfig__AgreementId__c = aggr.Id;
            ali.Apttus_Config2__AssetStatus__c = 'New';
            ali.APTS_Physical_Asset__c = lstPhysicalAsset[0].Id;
            ali.Apttus_CMConfig__AgreementLineItemId__c = lstAgreementLineItem[0].Id;
            ali.Apttus_Config2__OptionId__c = product.Id;
            ali.APTS_Option_Group_Text__c = 'Consumption Categories';
            ali.Apttus_Config2__BundleAssetId__c = bundleALI.Id;
            lstAssetLine.add(ali);
            
            Apttus_Config2__AssetLineItem__c ali1 =APTS_TestUtils.createAssetLineItem(
                                                    account.Id,product.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
            ali1.Apttus_CMConfig__AgreementId__c = aggr.Id;
            ali1.APTS_Physical_Asset__c = lstPhysicalAsset[0].Id;
            ali1.APTS_Option_Group_Text__c = 'Consumption Categories';
            ali1.Apttus_Config2__AssetStatus__c = 'New';
            ali1.Apttus_CMConfig__AgreementLineItemId__c = lstAgreementLineItem[0].Id;
            ali1.Apttus_Config2__OptionId__c = product.Id;
            ali1.APTS_Physical_Asset__c = lstPhysicalAsset[0].Id;
            ali1.Apttus_Config2__BundleAssetId__c = bundleALI.Id;
            lstAssetLine.add(ali1);
            
            Database.INSERT(lstAssetLine);  
    
            Apttus_Config2__AssetAttributeValue__c atributeValue = new Apttus_Config2__AssetAttributeValue__c(Apttus_Config2__AssetLineItemId__c=ali.Id);
            atributeValue.APTS_Type_of_Consumption__c = 'Paid';
            insert atributeValue;  
            
            List<APTS_CounterReadingData__c> lstCounterReading = new List<APTS_CounterReadingData__c>();
            APTS_CounterReadingData__c counterReading1 = new APTS_CounterReadingData__c();
            counterReading1.APTS_AgreementLineItem__c = lstAgreementLineItem[0].Id;
            counterReading1.APTS_Asset_Line_Item__c = lstAssetLine[0].Id;
            lstCounterReading.add(counterReading1);
            
            APTS_CounterReadingData__c counterReading2 = new APTS_CounterReadingData__c();
            counterReading2.APTS_AgreementLineItem__c = lstAgreementLineItem[1].Id;
            counterReading2.APTS_Asset_Line_Item__c = lstAssetLine[1].Id;
            counterReading2.TS_Physical_Asset__c = lstPhysicalAsset[0].Id;
            lstCounterReading.add(counterReading2);
            
            APTS_CounterReadingData__c counterReading3 = new APTS_CounterReadingData__c();
            counterReading3.APTS_AgreementLineItem__c = lstAgreementLineItem[0].Id;
            counterReading3.TS_Physical_Asset__c = lstPhysicalAsset[0].Id;
            lstCounterReading.add(counterReading3);
            
            INSERT lstCounterReading;  

            Apttus_Config2__Order__c oMachineOrder = APTS_TestDataFactory.createOrder(account.Id, plist.Id, con.Id);
            oMachineOrder.Apttus_Config2__Status__c = 'Activated';
            oMachineOrder.Apttus_Config2__Description__c = 'MachineOrder';
            oMachineOrder.Apttus_Config2__PONumber__c = '1234';
            oMachineOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(System.Label.APTS_Machine_Order).getRecordTypeId();
            oMachineOrder.APTS_Order_Type__c = 'Machine Order';
            oMachineOrder.APTS_Order_Sub_Type__c = 'Installation';
            oMachineOrder.APTS_SAP_OrderType__c = 'XA13';
            insert oMachineOrder;


            //Create Parent OLi
            Apttus_Config2__OrderLineItem__c parentOLI = APTS_TestUtils.createOrderLineItem(Product.Id, oMachineOrder.Id, null, billpre.Id, plist.Id, pli.Id);
            //parentOLI.APTS_Physical_Asset__c = physicalAsset2.Id;
            parentOLI.Apttus_Config2__LineType__c = 'Product/Service';
            parentOLI.APTS_Type_of_Contract__c = 'Consumption';
            parentOLI.Apttus_Config2__ChargeType__c = 'Rental Fee';
            parentOLI.Apttus_CMConfig__AgreementLineItemId__c = agreementLineItem1.Id;
            insert parentOLI;
            
            
            Apttus_Config2__OrderLineItem__c POLI = APTS_TestUtils.createOrderLineItem(Product.Id, oMachineOrder.Id, null, billpre.Id, plist.Id, pli.Id);
            POLI.APTS_Physical_Asset__c = physicalAsset2.Id;
            POLI.Apttus_Config2__LineType__c = 'Product/Service';
            POLI.APTS_Type_of_Contract__c = 'Consumption';
            POLI.Apttus_Config2__ChargeType__c = 'Rental Fee';
            POLI.Apttus_CMConfig__AgreementLineItemId__c = agreementLineItem1.Id;
            insert POLI;

            //Create Child OLi
            Apttus_Config2__OrderLineItem__c childOLI = APTS_TestUtils.createOrderLineItem(Product.Id, oMachineOrder.Id, null, billpre.Id, plist.Id, pli.Id);
            childOLI.Apttus_Config2__OptionId__c = product1.Id;
            childOLI.APTS_Is_Primary_L1_Parent__c = parentOLI.Id;
            childOLI.APTS_Option_Group_Text__c = 'Consumption Categories';
            childOLI.Apttus_CMConfig__AgreementLineItemId__c = agreementLineItem2.Id;
            insert childOLI;

            //Insert Work Order
            Id counterReadingId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Counter Reading').getRecordTypeId();
            WorkOrder wo = new WorkOrder();
            wo.RecordTypeId = counterReadingId;
            insert wo;

            //Insert Work Order Line Item
            WorkOrderLineItem woli = new WorkOrderLineItem();
            woli.WorkOrderId = wo.Id;
            woli.OrderLineItem__c = childOLI.Id;
            woli.WorkOrderType__c = 'S40';
            woli.ReadytosendEmail__c = true;
            //woli.PhysicalAsset__c ='';
            woli.Status = 'Dispatched';
            insert woli;
            
             List<Apttus_Billing__BillingSchedule__c> billingSchedulesList = new List<Apttus_Billing__BillingSchedule__c>();
                Apttus_Billing__BillingSchedule__c billingSchedules2 = new Apttus_Billing__BillingSchedule__c(Apttus_Billing__ReadyForInvoiceDate__c = Date.today(),
                                                                                                                Apttus_Billing__AssetLineItemId__c = ali1.Id,
                                                                                                                Apttus_Billing__BillToAccountId__c = account.Id,
                                                                                                                Apttus_Billing__Status__c ='Pending Billing',
                                                                                                                Apttus_Billing__IsSuperseded__c = false,
                                                                                                                Apttus_Billing__PeriodEndDate__c = Date.today()+60,
                                                                                                                Apttus_Billing__PeriodStartDate__c = Date.today()+30,
                                                                                                                Apttus_Billing__FeeAmount__c = 90.00,
                                                                                                                Apttus_Billing__Type__c = 'Contracted');
                
                
                billingSchedulesList.add(billingSchedules2);
              insert billingSchedulesList;

        }                                                        
    }

     static testMethod void testAssetTrigger()
     {

         List<Apttus_Config2__AssetLineItem__c> updtAssetLine = new List<Apttus_Config2__AssetLineItem__c>();
         List<Apttus_Config2__AssetLineItem__c> lstAssetLine = [SELECT Id, Apttus_Config2__AssetStatus__c, 
                                                  APTS_Physical_Asset__c,Apttus_Config2__BusinessObjectId__c 
                                                  FROM Apttus_Config2__AssetLineItem__c where APTS_Option_Group_Text__c =: 'Consumption Categories'];
        Apttus__APTS_Agreement__c updateAgree = [Select Id From Apttus__APTS_Agreement__c Where Name='AssetUpdateAgree' Limit 1];                                 
        List<PhysicalAsset__c> lstPhysicalAsset = [SELECT Id FROM PhysicalAsset__c];                                                  
        Account acc1 = [Select Id From Account Where Name = 'TestAccount1'];
        Apttus_Config2__Order__c ord = [Select ID,APTS_Order_Type__c,APTS_Order_Sub_Type__c From Apttus_Config2__Order__c Where Apttus_Config2__Type__c = 'test2' Limit 1];
        for(Apttus_Config2__AssetLineItem__c asli: lstAssetLine){
            asli.Apttus_CMConfig__AgreementId__c = updateAgree.Id; 
            asli.Apttus_Config2__AccountId__c = acc1.Id;
            asli.Apttus_Config2__AssetStatus__c = 'Activated';
            asli.Apttus_Config2__AssetStatus__c = 'Amended';
            asli.APTS_Physical_Asset__c  = lstPhysicalAsset[1].Id;
            asli.Apttus_Config2__BusinessObjectId__c = ord.Id;
            updtAssetLine.add(asli);
        }
        
        system.assertEquals(2, lstAssetLine.size());
        test.startTest();
        //Database.Update(lstAssetLine);                                         
        Database.Update(updtAssetLine);                                         
        test.stopTest();                                   
                                                  
     }


     static testMethod void testOLICounterReading() 
     {

     
         List<Apttus_Config2__OrderLineItem__c> lstOrderLine = [SELECT Id, APTS_Option_Group_Text__c, Apttus_CMConfig__AgreementLineItemId__c FROM Apttus_Config2__OrderLineItem__c];
         List<Apttus__AgreementLineItem__c> lstALI= [select id from Apttus__AgreementLineItem__c];

        List<PhysicalAsset__c> lstPhysicalAsset = [SELECT Id FROM PhysicalAsset__c]; 
        for(Apttus_Config2__OrderLineItem__c oli : lstOrderLine){     
            if(oli.APTS_Option_Group_Text__c != 'Consumption Categories'){                                            
                //oli.APTS_Physical_Asset__c  = lstPhysicalAsset[0].Id;
                oli.Apttus_CMConfig__AgreementLineItemId__c  = lstALI[0].Id;
            }
            else{
                oli.Apttus_CMConfig__AgreementLineItemId__c  = lstALI[1].Id;
            }
        }
        
        //system.assertEquals(2, lstAssetLine.size());
        test.startTest();
        Database.Update(lstOrderLine);                                       
        test.stopTest();    

        WorkOrderLineItem woli = [Select id, SendCounterReadings__c  from WorkOrderLineItem limit 1][0];  
        system.assertEquals(3, lstOrderLine.size());                               
                                                  
     }

     static testMethod void testOLICounterReadingNew() 
     {

     
         Map<Id,Apttus_Config2__OrderLineItem__c> lstOrderLine = new Map<Id,Apttus_Config2__OrderLineItem__c>([SELECT Id, APTS_Option_Group_Text__c, Apttus_CMConfig__AgreementLineItemId__c, APTS_Is_Primary_L1_Line__c ,APTS_Physical_Asset__c, Apttus_Config2__OrderId__c  FROM Apttus_Config2__OrderLineItem__c]);
         List<Apttus__AgreementLineItem__c> lstALI= [select id from Apttus__AgreementLineItem__c];
         Map<Id,Apttus_Config2__OrderLineItem__c> newMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();

        List<PhysicalAsset__c> lstPhysicalAsset = [SELECT Id FROM PhysicalAsset__c]; 
        for(Apttus_Config2__OrderLineItem__c oli : lstOrderLine.values()){     
            if(oli.APTS_Option_Group_Text__c != 'Consumption Categories'){
                //oli.APTS_Physical_Asset__c  = lstPhysicalAsset[0].Id;
                oli.Apttus_CMConfig__AgreementLineItemId__c  = lstALI[0].Id;
            }
            else{
                Apttus_Config2__OrderLineItem__c xyz= oli.clone(true, true, false, false);       
                oli.Apttus_CMConfig__AgreementLineItemId__c  = lstALI[1].Id;
            }
        }
        Database.Update(lstOrderLine.values()); 

        for(Apttus_Config2__OrderLineItem__c oli : lstOrderLine.values()){     
            if(oli.APTS_Option_Group_Text__c != 'Consumption Categories'){
                Apttus_Config2__OrderLineItem__c xyz = oli.clone(true, true, false, false);   
                xyz.APTS_Physical_Asset__c  = lstPhysicalAsset[0].Id;                                         
                newMap.put(oli.Id, xyz);
            }
            else{
                Apttus_Config2__OrderLineItem__c xyz= oli.clone(true, true, false, false);       
                newMap.put(oli.Id, xyz);
            }
        }
        
        //system.assertEquals(2, lstAssetLine.size());
        test.startTest();
        //Database.Update(lstOrderLine);  
        APTS_BIRUtils.updateCounterReadingWithPhysicalAsset(newMap.values(), newMap, lstOrderLine.values(), lstOrderLine);                                  
        test.stopTest();    

        WorkOrderLineItem woli = [Select id, SendCounterReadings__c  from WorkOrderLineItem limit 1][0];  
        system.assertEquals(3, lstOrderLine.size());                               
                                                  
     }
       
}