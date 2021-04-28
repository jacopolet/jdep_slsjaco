/*******************************************************************************************
Name            : APTS_FixedTermAgreement
Created By      : Beulah Ann Thomas
Created Date    : 01/15/2018
Description     : If a fixed term agreement is activated, then order,
                  order line item and asset line item has to be created with dummy
                  products, and activated.
                  v1.1 - Modified to add list price info in OLI.
Test Class      : APTS_FixedTermAgreementTest (87% code coverage)
********************************************************************************************/
public with sharing class APTS_FixedTermAgreement {

    Static final string FIXEDCOST = 'Fixed Cost';
    Static final string ALLINGREDIENTS = 'All Ingredients';
    Static final string COSTANDINGREDIENTS = 'Fixed Costs and Ingredients';
    Static final string INGREDIENTS = 'Ingredients';
    Static final string MACHINE = 'Machine';
    Static final String ADMINORDER = 'Admin Order'; 
    Static final String ACTIVATED = 'Activated';
    Static final string INEFFECT = 'In Effect';
    Static final String SAPORDERTYPE = 'XD01';
    Static final String ORDEROBJECT = 'Apttus_Config2__Order__c';
    Static final String ORDERLINEITEMOBJECT='Apttus_Config2__OrderLineItem__c';
    Static final String MISC='Misc';
    /* Create order if the fixed term agreement record is active. */
    //public static void fixedTermAgreementActivation(Map<Id,SObject> mapNewAgreements, Map<Id,SObject> mapOldAgreements)
    //@future
    //public static void fixedTermAgreementActivation(String jsonNewMap, String jsonOldMap)
    public static void fixedTermAgreementActivation(Map<Id,SObject> mapNewAgreements, Map<Id,SObject> mapOldAgreements){
        DescribeSObjectResult objResultOrder = APTS_OTCUtil.getsObjectAccess(ORDEROBJECT);
        DescribeSObjectResult objResultOrderLineItem = APTS_OTCUtil.getsObjectAccess(ORDERLINEITEMOBJECT);
        DateTime currentDateTime = datetime.now();
        TimeZone userTimezone = UserInfo.getTimeZone();
        DateTime localTime = currentDateTime.AddSeconds(userTimezone.getOffset(currentDateTime)/1000);
        Apttus_Config2__Order__c createOrder;
        List<Apttus__APTS_Agreement__c> lstActiveFixedTerm = new List<Apttus__APTS_Agreement__c>();
    
        try{           
            Map<Id ,Apttus__APTS_Agreement__c> mapOldAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
            mapOldAgreement.putAll((Map<Id,Apttus__APTS_Agreement__c>)mapOldAgreements);
            Map<Id, Apttus__APTS_Agreement__c> mapNewAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
            mapNewAgreement.putAll((Map<Id,Apttus__APTS_Agreement__c>)mapNewAgreements);
           
            for(Apttus__APTS_Agreement__c agreement : mapNewAgreement.values()){
                system.debug('agreement ===> '+agreement);
                system.debug('mapOldAgreement ===> '+mapOldAgreement);
                /* Check whether the agreement record is a fixed term or not by checking the subtype value. Also,
                check whether agreement record was not activated before and got activated now.*/
             
                if((mapOldAgreement.get(agreement.Id).Apttus__Status__c != agreement.Apttus__Status__c
                        && activated.equals(agreement.Apttus__Status__c)) && 
                        inEffect.equals(agreement.Apttus__Status_Category__c) &&
                    (FIXEDCOST.equals(agreement.APTS_Fixed_Term_Type__c ) ||  
                    ALLINGREDIENTS.equals(agreement.APTS_Fixed_Term_Type__c ) || 
                    COSTANDINGREDIENTS.equals(agreement.APTS_Fixed_Term_Type__c ))){
                    system.debug('in IF--');
                    lstActiveFixedTerm.add(agreement);
                    system.debug('constructor//='+ lstActiveFixedTerm);
                }
            } 
            //If the agreement is a fixed term agreement then create admin order and order line items.
            if(!lstActiveFixedTerm.isEmpty()){
                Map<Id, List<Apttus_Config2__Order__c>> mapOrder = new Map<Id, List<Apttus_Config2__Order__c>>();
                Set<Id> setAgreementIds = new Set<Id>();
                Map<String, Apttus_Config2__Order__c> mapOrderType = new Map<String, Apttus_Config2__Order__c>();
                Map<String, Apttus_Config2__Order__c> mapUpdateOrder = new Map<String, Apttus_Config2__Order__c>();
                Map<String, String> mapProductNameNType = new Map<String, String>();
                Map<String, APTS_Billing_Settings__c> mapBillingSetting = new Map<String, APTS_Billing_Settings__c>();
               
                List<Apttus_Config2__Order__c> lstOrder = new List<Apttus_Config2__Order__c>();
                List<Apttus_Config2__OrderLineItem__c> lstOrderLineItem = new List<Apttus_Config2__OrderLineItem__c>();
                List<Apttus_Config2__Order__c> lstUpdateOrder = new List<Apttus_Config2__Order__c>();
                Apttus_Config2__OrderLineItem__c orderLineItem;
                Set<String> setDummyProducts = new Set<String>();
                String lineItemProduct;

                Id adminOrderRT= Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(ADMINORDER).getRecordTypeId();
     
                /*
                Query billing setting for the fixed term agreement which is activated. This billing setting information has to be cascaded 
                to the admin order(s). If its a 'Fixed Costs and Ingredients' type Agreement having different Bill To Ingredient and 
                Bill to machines then, two admin orders will be created per Agreemnt. For the remaining 'Fixed Term Type' only one admin order will 
                be created per Agreement.
                */             
                List<APTS_Billing_Settings__c> lstBillingSetting = [SELECT Id, APTS_Agreement_ID__c, APTS_Billing_Preference_Setting__c, 
                                                            APTS_Billing_Rule_Contract__c, APTS_Bill_To_ID__c, 
                                                            APTS_Bill_To_ID__r.Distribution_Channel__c,
                                                            APTS_Bill_To_ID__r.Division__c,
                                                            APTS_ConversionId__c, APTS_Invoice_Delivery_Preference__c, 
                                                            APTS_Invoice_Type__c, APTS_MigrationDate__c, APTS_Payment_Method__c, 
                                                            APTS_Payment_Term_Setting__c, APTS_SourceSystem__c, 
                                                            APTS_Agreement_Billing_Type__c,APTS_Sales_Organization__c 
                                                            FROM APTS_Billing_Settings__c
                                                            WHERE APTS_Agreement_ID__c IN : lstActiveFixedTerm];
                List<string> lstProductName = new List<String>();               
                //From custom setting get the names of fixed term dummy products, their type and inactive status.
                //The dummy products should be considered only if the 'Inactive' checkbox is false.
                for(APTS_Fixed_Term_Dummy_Product__c product : APTS_Fixed_Term_Dummy_Product__c.getall().values()){
                    if(!product.Inactive__c){
                        setDummyProducts.add(product.Product_Name__c);    
                        lstProductName.add(product.Product_Name__c);            
                        mapProductNameNType.put(product.Product_Name__c , product.Product_Type__c);
                    }
                }
                
               //Query all agreement line items for dummy products.
               List<Apttus__AgreementLineItem__c> lstAgreementLineItem = [SELECT Id, Apttus__AgreementId__c, Apttus__ProductId__c, Apttus__ProductId__r.Name,
                                                                        Apttus_CMConfig__BillingFrequency__c, Apttus_CMConfig__BillingRule__c, 
                                                                        Apttus_CMConfig__BillingPlanId__c, Apttus_CMConfig__PriceType__c,
                                                                        Apttus_CMConfig__PriceListItemId__c, Apttus__NetPrice__c, Apttus_CMConfig__PriceListId__c,
                                                                        Apttus_CMConfig__StartDate__c, Apttus_CMConfig__EndDate__c, Apttus_Config2_SellingUom__c, 
                                                                        Apttus_CMConfig__SellingFrequency__c, Apttus_CMConfig__SellingTerm__c, APTS_Payment_Method__c, 
                                                                        Apttus_CMConfig__BillingPreferenceId__c, Apttus_CMConfig__PaymentTermId__c, 
                                                                        Apttus_CMConfig__LineNumber__c, Apttus_CMConfig__ItemSequence__c, 
                                                                        Apttus_CMConfig__BillToAccountId__c, Apttus_CMConfig__Frequency__c,
                                                                        //v1.1Including fields to popluate pricing related info in OLI
                                                                        Apttus__ListPrice__c, Apttus_CMConfig__BaseExtendedPrice__c, 
                                                                        Apttus_CMConfig__BasePrice__c, Apttus_CMConfig__BasePriceOverride__c, 
                                                                        Apttus__ExtendedPrice__c 
                                                                        FROM Apttus__AgreementLineItem__c 
                                                                        WHERE Apttus__AgreementId__c IN: lstActiveFixedTerm
                                                                        AND Apttus__ProductId__r.Name IN: setDummyProducts
                                                                        LIMIT 10];
               
               
                // Create a new order for each billing setting
                for(APTS_Billing_Settings__c billingSetting : lstBillingSetting){
                    createOrder = new Apttus_Config2__Order__c();
                    createOrder.RecordTypeID = adminOrderRT;
                    createOrder.APTS_SAP_OrderType__c = SAPORDERTYPE;
                    createOrder.Apttus_Config2__Source__c = 'Agreement';
                    createOrder.APTS_Requested_Delivery_Date__c = System.Today();
                    createOrder.Apttus_Config2__PriceListId__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).Apttus_CMConfig__PriceListId__c;
                    createOrder.Apttus_CMConfig__AgreementId__c = billingSetting.APTS_Agreement_ID__c;
                    createOrder.Apttus_Config2__AutoActivateOrder__c = True;
                    createOrder.APTS_Name__c = System.Label.APTS_BIR_FixedTerm_Dummy;                    
                    createOrder.Apttus_Config2__SoldToAccountId__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Sold_To__c; //from agreement                    
                    createOrder.APTS_Order_Type__c = 'Admin Order';                    
                    createOrder.Apttus_Config2__Status__c = 'Draft';
                    createOrder.APTS_PayerIngredients__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Payer_Ingredients__c;
                    createOrder.Apttus_Config2__PrimaryContactId__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).Apttus__Primary_Contact__c;
                    createOrder.APTS_Status__c = 'Draft';                    
                    createOrder.Apttus_Config2__OrderStartDate__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).Apttus__Contract_Start_Date__c;
                    createOrder.Apttus_Config2__OrderEndDate__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).Apttus__Contract_End_Date__c;                    
                    createOrder.Apttus_Config2__BillingPreferenceId__c = billingSetting.APTS_Billing_Preference_Setting__c;
                    createOrder.Apttus_Config2__PaymentTermId__c = billingSetting.APTS_Payment_Term_Setting__c;
                    createOrder.APTS_Payment_Method__c = billingSetting.APTS_Payment_Method__c;
                    createOrder.APTS_InvoiceType__c = billingSetting.APTS_Invoice_Type__c;
                    createOrder.APTS_InvoiceDeliveryPreference__c = billingSetting.APTS_Invoice_Delivery_Preference__c;
                    createOrder.APTS_Sales_Organization__c = billingSetting.APTS_Sales_Organization__c;
                    // Fix for defect Id 20666 starts here. Populate distribution channel and division.
                    createOrder.APTS_Distribution_Channel__c = billingSetting.APTS_Bill_To_ID__r.Distribution_Channel__c;
                    createOrder.APTS_Division__c = billingSetting.APTS_Bill_To_ID__r.Division__c;
                    //Fix for defect Id 20666 ends here
                    createOrder.APTS_Requested_Delivery_Date__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).Apttus__Request_Date__c !=Null ? 
                        mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).Apttus__Request_Date__c : System.Today();
                    system.debug('--createOrder-- outside '+ createOrder);
                    if(!Test.isRunningTest()){
                        system.debug('localTime --'+ localTime );
                        system.debug('agreement.Apttus__Contract_Start_Date__c --'+ mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).Apttus__Contract_Start_Date__c);
                        createOrder.Apttus_Config2__ReadyForBillingDate__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).Apttus__Contract_Start_Date__c!= null && 
                                                                                mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).Apttus__Contract_Start_Date__c < System.Today()?
                                                                                localTime : 
                                                                                datetime.newInstance(mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).Apttus__Contract_Start_Date__c.year(), 
                                                                                mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).Apttus__Contract_Start_Date__c.month(),
                                                                                mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).Apttus__Contract_Start_Date__c.day());
                        createOrder.Apttus_Config2__ActivatedDate__c = System.Today();
                        system.debug('--createOrder-- in Test running'+ createOrder);
                    }
                
                    /*If the billing setting record's billing type is machine, 
                    then for all account fields use 'Bill To Machines' value from agreement.
                    If the billing setting record's billing type is ingredients, 
                    then for all account fields use 'Bill To Ingredients' value from agreement. */
                    if(billingSetting.APTS_Agreement_Billing_Type__c == MACHINE){
                        createOrder.Apttus_Config2__BillToAccountId__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_MachServ__c;
                        createOrder.APTS_Bill_to_Party_Machines_Services__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_MachServ__c;
                        createOrder.APTS_Payer__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_MachServ__c;
                        system.debug('MACHINE --');
                        system.debug('--createOrder '+ createOrder);
                    }                      
                    else if(billingSetting.APTS_Agreement_Billing_Type__c == INGREDIENTS){
                        createOrder.Apttus_Config2__BillToAccountId__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_Ingredients__c;
                        createOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_Ingredients__c;
                        createOrder.APTS_Payer__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_Ingredients__c;
                        system.debug('--INGREDIENTS');
                    }
                    createOrder.APTS_SAP_OrderType__c = SAPORDERTYPE;
                    createOrder.APTS_Requested_Delivery_Date__c = mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).Apttus__Contract_Start_Date__c;                    
                    mapOrder.put(billingSetting.APTS_Agreement_ID__c , lstOrder);
                   
                    //Get combination of agreement id and billing type from billing setting to get relationship of orders corresponding
                    // to each billing setting.
                    if(mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Fixed_Term_Type__c == COSTANDINGREDIENTS 
                        && mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_Ingredients__c != 
                        mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_MachServ__c){
                        mapOrderType.put(billingSetting.APTS_Agreement_ID__c+ ' '+ billingSetting.APTS_Agreement_Billing_Type__c, createOrder);
                        system.debug('cost&ing--');
                    }else if(mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Fixed_Term_Type__c == COSTANDINGREDIENTS &&
                        (mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_Ingredients__c == 
                         mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_MachServ__c) && 
                        (setAgreementIds.isEmpty() || 
                        (!setAgreementIds.isEmpty() && !setAgreementIds.Contains(billingSetting.APTS_Agreement_ID__c)))){
                        mapOrderType.put(billingSetting.APTS_Agreement_ID__c+ ' '+ billingSetting.APTS_Agreement_Billing_Type__c, createOrder);  
                        setAgreementIds.add(billingSetting.APTS_Agreement_ID__c); 
                        system.debug('cost ing--');
                    }
                    else if(mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Fixed_Term_Type__c == ALLINGREDIENTS &&
                        (mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_Ingredients__c!= NULL) &&
                        (setAgreementIds.isEmpty() || 
                        (!setAgreementIds.isEmpty() && !setAgreementIds.Contains(billingSetting.APTS_Agreement_ID__c)))){
                        mapOrderType.put(billingSetting.APTS_Agreement_ID__c+ ' '+ INGREDIENTS, createOrder); 
                        setAgreementIds.add(billingSetting.APTS_Agreement_ID__c);
                        system.debug('-all ing--');    
                    }
                    else if(mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Fixed_Term_Type__c == FIXEDCOST &&
                        mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_MachServ__c != NULL && 
                        (setAgreementIds.isEmpty() || 
                        (!setAgreementIds.isEmpty() && !setAgreementIds.Contains(billingSetting.APTS_Agreement_ID__c)))){
                        mapOrderType.put(billingSetting.APTS_Agreement_ID__c+ ' '+ MACHINE, createOrder); 
                        setAgreementIds.add(billingSetting.APTS_Agreement_ID__c); 
                        system.debug('fixed cost--');
                    }
                }
                           
                if(!mapOrderType.isEmpty() && !lstAgreementLineItem.isEmpty()){
                    system.debug('--mapOrderType.values() Before INSERT 2--' + mapOrderType.values());                
                    if(objResultOrder.isCreateable()){
                        APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = true;
                        Database.INSERT(mapOrderType.values());
                        APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = false;
                    }
                    //Get map of insert orders to use later for order update. 
                    mapUpdateOrder.putAll(mapOrderType);
                }
            
                for(APTS_Billing_Settings__c billingSetting : lstBillingSetting){             
                    //If bill to ingredients and bill to machine are same, only one order will be created. But dummy agreement line items
                    //corresponding to both ingredients and machines should be cascased as OLIs to the newly created order.   
                    if(mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Fixed_Term_Type__c == COSTANDINGREDIENTS &&
                        (mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_Ingredients__c == 
                         mapNewAgreement.get(billingSetting.APTS_Agreement_ID__c).APTS_Bill_to_Party_MachServ__c) && 
                         mapOrderType.ContainsKey(billingSetting.APTS_Agreement_ID__c+' '+billingSetting.APTS_Agreement_Billing_Type__c))
                     {
                         if(billingSetting.APTS_Agreement_Billing_Type__c == MACHINE)
                         {
                             mapOrderType.put(billingSetting.APTS_Agreement_ID__c+' '+INGREDIENTS,
                             mapOrderType.get(billingSetting.APTS_Agreement_ID__c+' '+billingSetting.APTS_Agreement_Billing_Type__c));
                         }
                         else if(billingSetting.APTS_Agreement_Billing_Type__c == INGREDIENTS)
                         {
                             mapOrderType.put(billingSetting.APTS_Agreement_ID__c+' '+MACHINE,
                             mapOrderType.get(billingSetting.APTS_Agreement_ID__c+' '+billingSetting.APTS_Agreement_Billing_Type__c));
                         }
                     }
                }
            
                Set<Id> setOrderIds = new Set<Id>();
                system.debug('--mapOrderType.values() AFTER INSERT--' + mapOrderType.values());
                system.debug('/mapOrderType//'+ mapOrderType);
            
                //Insert order line items corresponding to agreement line items with dummy products.
                system.debug('lstAgreementLineItem==='+lstAgreementLineItem);
                for(Apttus__AgreementLineItem__c agreementLineItem: lstAgreementLineItem){
                    lineItemProduct = string.valueOf(agreementLineItem.Apttus__ProductId__r.Name);                
                    system.debug('lineItemProduct == > '+lineItemProduct);
                    system.debug('mapProductNameNType --> '+mapProductNameNType);
                    system.debug('contains == > '+ mapProductNameNType.ContainsKey(lineItemProduct));
                    system.debug('AgrId ==> '+agreementLineItem.Apttus__AgreementId__c);
                    system.debug('agreementLineItem.Apttus__ProductId__r.Name' + agreementLineItem.Apttus__ProductId__r.Name);
                    system.debug(mapOrderType.ContainsKey(agreementLineItem.Apttus__AgreementId__c + ' '+
                                        mapProductNameNType.get(agreementLineItem.Apttus__ProductId__r.Name)));
                    if(!mapProductNameNType.isEmpty() && 
                       mapProductNameNType.ContainsKey(lineItemProduct) && 
                       !mapOrderType.isEmpty() &&
                       mapOrderType.ContainsKey(agreementLineItem.Apttus__AgreementId__c + ' '+ mapProductNameNType.get(agreementLineItem.Apttus__ProductId__r.Name))){
                        system.debug('ali same as custom setting');
                        orderLineItem = new Apttus_Config2__OrderLineItem__c();
                        system.debug('mapOrderType=='+ mapOrderType);
                        orderLineItem.Apttus_CMConfig__AgreementId__c = agreementLineItem.Apttus__AgreementId__c;
                        orderLineItem.Apttus_Config2__ProductId__c = agreementLineItem.Apttus__ProductId__c;
                        orderLineItem.Apttus_Config2__SellingUom__c = agreementLineItem.Apttus_Config2_SellingUom__c;
                        orderLineItem.APTS_Payment_Method__c = agreementLineItem.APTS_Payment_Method__c;
                        orderLineItem.Apttus_Config2__PaymentTermId__c = agreementLineItem.Apttus_CMConfig__PaymentTermId__c;                
                        orderLineItem.Apttus_Config2__BillToAccountId__c = agreementLineItem.Apttus_CMConfig__BillToAccountId__c;                   
                        orderLineItem.Apttus_Config2__PriceListItemId__c = agreementLineItem.Apttus_CMConfig__PriceListItemId__c;
                        orderLineItem.Apttus_Config2__PriceListId__c = agreementLineItem.Apttus_CMConfig__PriceListId__c;
                        //v1.1 Added list price as pricing info not reaching SAP
                        orderLineItem.Apttus_Config2__ListPrice__c = agreementLineItem.Apttus__ListPrice__c;
                        orderLineItem.Apttus_Config2__NetPrice__c = agreementLineItem.Apttus__NetPrice__c;
                        system.debug('mapProductNameNType.get(agreementLineItem.Apttus__ProductId__r.Name)--'+ 
                        mapProductNameNType.get(agreementLineItem.Apttus__ProductId__r.Name));
                        system.debug('agreementLineItem.Apttus__AgreementId__c--'+ agreementLineItem.Apttus__AgreementId__c);
                        system.debug('mapOrderType.keyset--'+ mapOrderType.keySet());
                        orderLineItem.Apttus_Config2__OrderId__c = mapOrderType.get(agreementLineItem.Apttus__AgreementId__c + ' '+mapProductNameNType.get(agreementLineItem.Apttus__ProductId__r.Name)).Id;
                        system.debug('mapOrderType.get(agreementLineItem.Apttus__AgreementId__c + mapProductNameNType.get(agreementLineItem.Apttus__ProductId__r.Name)).Id;=='+
                        mapOrderType.get(agreementLineItem.Apttus__AgreementId__c + ' '+ mapProductNameNType.get(agreementLineItem.Apttus__ProductId__r.Name)).Id);                                                                        
                        setOrderIds.add(orderLineItem.Apttus_Config2__OrderId__c);
                        orderLineItem.APTS_SAP_OrderType__c = mapOrderType.get(agreementLineItem.Apttus__AgreementId__c + ' '+ mapProductNameNType.get(agreementLineItem.Apttus__ProductId__r.Name)).APTS_SAP_OrderType__c;
                        orderLineItem.Apttus_Config2__Status__c = mapOrderType.get(agreementLineItem.Apttus__AgreementId__c + ' '+ mapProductNameNType.get(agreementLineItem.Apttus__ProductId__r.Name)).Apttus_Config2__Status__c;                                     
                        /* orderLineItem.Apttus_Config2__BillingPreferenceId__c = agreementLineItem.Apttus_CMConfig__BillingPreferenceId__c;
                        orderLineItem.Apttus_Config2__BillingFrequency__c = agreementLineItem.Apttus_CMConfig__BillingFrequency__c;
                        orderLineItem.Apttus_Config2__BillingPlanId__c = agreementLineItem.Apttus_CMConfig__BillingPlanId__c;
                        orderLineItem.Apttus_Config2__BillingRule__c = agreementLineItem.Apttus_CMConfig__BillingRule__c; */
                        orderLineItem.Apttus_Config2__BillingPreferenceId__c = mapOrderType.get(agreementLineItem.Apttus__AgreementId__c + ' '+ mapProductNameNType.get(agreementLineItem.Apttus__ProductId__r.Name)).Apttus_Config2__BillingPreferenceId__c;                
                        orderLineItem.Apttus_Config2__BillingFrequency__c = agreementLineItem.Apttus_CMConfig__BillingFrequency__c;                
                        //orderLineItem.Apttus_Config2__BillingPlanId__c =
                        //agreementLineItem.Apttus_CMConfig__BillingPlanId__c;                
                        orderLineItem.Apttus_Config2__BillingRule__c = agreementLineItem.Apttus_CMConfig__BillingRule__c;                
                        orderLineItem.Apttus_Config2__StartDate__c = agreementLineItem.Apttus_CMConfig__StartDate__c;
                        orderLineItem.Apttus_Config2__EndDate__c = agreementLineItem.Apttus_CMConfig__EndDate__c;        
                        orderLineItem.Apttus_Config2__PriceType__c = agreementLineItem.Apttus_CMConfig__PriceType__c;
                        orderLineItem.Apttus_Config2__Frequency__c = agreementLineItem.Apttus_CMConfig__Frequency__c;
                        orderLineItem.Apttus_Config2__Quantity__c = 1;
                        orderLineItem.Apttus_Config2__SellingFrequency__c = agreementLineItem.Apttus_CMConfig__SellingFrequency__c;
                        orderLineItem.Apttus_Config2__SellingTerm__c = agreementLineItem.Apttus_CMConfig__SellingTerm__c;                           
                        orderLineItem.Apttus_Config2__LineNumber__c = 1;
                        orderLineItem.Apttus_Config2__ItemSequence__c  = 1;
                        orderLineItem.Apttus_Config2__ChargeType__c = 'Sales Price';
                        orderLineItem.Apttus_Config2__LineType__c = MISC;
                        orderLineItem.APTS_Type_of_Contract__c ='Sales';
                        orderLineItem.Apttus_Config2__HasOptions__c = false;
                        orderLineItem.APTS_Item_Relevant_for_SAP__c =  true;
                        orderLineItem.Apttus_Config2__IsPrimaryLine__c = false;
                        orderLineItem.Apttus_Config2__BasePriceOverride__c = agreementLineItem.Apttus_CMConfig__BasePriceOverride__c;
                        orderLineItem.Apttus_Config2__BaseExtendedPrice__c = agreementLineItem.Apttus_CMConfig__BaseExtendedPrice__c;
                        orderLineItem.Apttus_Config2__ExtendedPrice__c= agreementLineItem.Apttus__ExtendedPrice__c;
                        lstOrderLineItem.add(orderLineItem);
                        system.debug('orderLineItem//'+ orderLineItem);
                        system.debug('in order line item//'+ lstOrderLineItem);                
                    }
                }
            
                if(!lstOrderLineItem.isEmpty()){
                    system.debug('lstOrderLineItem==='+ lstOrderLineItem);
                    if(objResultOrderLineItem.isCreateable()){
                        APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = true;
                        INSERT lstOrderLineItem;
                        APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = false;
                    }                
                    system.debug('AFTER INSERT lstOrderLineItem==='+ lstOrderLineItem);
                }
            }
        }catch(Exception ex){
            system.debug('ex--'+ ex);
            //System.assert(false,ex.getMessage()+'--'+ex.getLineNumber());
            system.debug('ex line number=='+ ex.getLineNumber());
            Database.INSERT(APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', string.valueOf(ex), //ex.getStackTraceString() ,
                'Order', createOrder.Id ,'BIR',False, False,'', False));
        }
    }
    
    
    /*Activate the order. Upon order activation, order line item gets 
    activated and OOB asset line items get created along with billing schedule. */
    public static void activateOrder(Apttus_Config2__Order__c order){        
        try{            
            Apttus_Config2.CPQStruct.AcceptOrderRequestDO acceptOrderRequest = new Apttus_Config2.CPQStruct.AcceptOrderRequestDO();
            acceptOrderRequest.OrderId = order.Id;
            Apttus_Config2.CPQStruct.AcceptOrderResponseDO acceptOrderResponse = Apttus_Config2.OrderWebService.acceptOrder(acceptOrderRequest);
            system.debug('acceptOrderResponse --'+ acceptOrderResponse );
        }
        catch(exception ex){
            //exception error
            system.debug('ex--'+ ex);
            Database.INSERT(APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', string.valueOf(ex) , 'Order', order.Id ,'BIR',False, False,'', False));
        }
    }

}