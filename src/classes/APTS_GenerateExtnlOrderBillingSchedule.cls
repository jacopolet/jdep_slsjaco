/*
@Author : Amit
@Description : Batch Class created to generate External order and external order line Item.
Version history : v1.0 created
                  v1.1 Added WHERE condition type = contracted, status = pending invoice 
                  and order line item's price type != one time. Logic to find category,
                  sub-category, sub-sub category of external order line item.
                  v1.2 Updated logic to populate quantity from usage input

*/
global class APTS_GenerateExtnlOrderBillingSchedule implements Database.Batchable<sObject> ,Database.Stateful{

    private static final String EXTERNALORDERSUMMARY = 'Apttus_Config2__ExternalOrderSummary__c';
    
    private static final String EXTERNALORDERSUMMARYITEM = 'Apttus_Config2__ExternalOrderSummaryItem__c';
    
    private static final String BILLINGSCHEDULE = 'Apttus_Billing__BillingSchedule__c';
    
    private static final String RATED = 'Rated'; //v1.2
    
    private static final String USAGEINPUT = 'Apttus_Billing__UsageInput__c'; //v1.2

    Apttus_Config2__ExternalOrderSummaryItem__c extLn = null;
    
    Apttus_Config2__ExternalOrderSummary__c extnOrdRef = null;
    Apttus_Billing__UsageSchedule__c usgSch = null;
   
    list<Apttus_Billing__BillingSchedule__c> lstBillSchToupdate = new list<Apttus_Billing__BillingSchedule__c>();
    
    
    map<Id,Apttus_Config2__ExternalOrderSummary__c> mapExtOrd = new map<Id,Apttus_Config2__ExternalOrderSummary__c>();
    map<Id,list<Apttus_Billing__BillingSchedule__c>> bsToExtLn = new map<Id,list<Apttus_Billing__BillingSchedule__c>>();
    map<Id, Apttus_Config2__ProductClassification__c> mapAllProductCategory = 
        new map<Id, Apttus_Config2__ProductClassification__c>(); //v1.1 
    //v1.2 starts here
    
    map<Id, Apttus_Billing__UsageInput__c> mapAssetLineToUsageInput = new map<Id, Apttus_Billing__UsageInput__c>();
    
    
    //v1.2 ends here
    private string CONSUMPTION = 'Consumption Model';
    private string INREVIEW = 'In Review';
    private static string DRAFT = 'Draft';
    private string SALESDATA = 'Sales Data';
    private static final string CONTRACTED = 'Contracted';
    private static final string PENDINGINVOICE = 'Pending Invoiced';
    private static final string ONETIME = 'One Time';
    private static final string CONSIGNMENTINGREDIENTS = 'Consignment Ingredients';
    private static final string EXTERNALORDERSUMMARYOBJ = 'Apttus_Config2__ExternalOrderSummaryItem__c';
    //private static final string CONSUMPTIONCLASSIFICATION = 'Consumption';
    private static final string CONSUMPTIONCLASSIFICATION = 'Consumption Categories';
    private static final string JDEINVOICE = 'JDE Invoice';
    private static final string SELLOUTDATA = 'Sellout Data';
    //private static final string BILLINGSCHEDULE = 'Apttus_Billing__BillingSchedule__c';
    list<Apttus_Config2__ExternalOrderSummaryItem__c> lstExtOrdli = new list<Apttus_Config2__ExternalOrderSummaryItem__c>();
    global Database.QueryLocator start(Database.BatchableContext BC) {
        string query;
        query = 'Select Id, Apttus_Billing__BillToAccountId__c, Apttus_Billing__ReadyForInvoiceDate__c, Apttus_Billing__AssetLineItemId__c,APTS_AddToExternalOrderlineItem__c,\n'+
                'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c,\n'+
                'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ListPrice__c, \n'+
                'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__StartDate__c, \n'+
                'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__EndDate__c, \n'+
                'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetUnitPrice__c,\n'+
                'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c,\n'+
                'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingFrequency__c,\n'+
                'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingUom__c,\n'+
                'Apttus_Billing__FeeAmount__c,Apttus_Billing__PeriodEndDate__c,Apttus_Billing__PeriodStartDate__c,\n'+
                'Apttus_Billing__ShipToAccountId__c,\n'+
                'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__OptionId__c,\n'+ //part of v1.1
                //v1.2 Add field Apttus_Billing__AssetLineItemId__c to the inner query.
                '(Select id, Name, Apttus_Billing__Uom__c, Apttus_Billing__ActualOverageQuantity__c,Apttus_Billing__ActualQuantity__c,Apttus_Billing__AssetLineItemId__c from Apttus_Billing__UsageSchedules__r)\n'+
                ' From Apttus_Billing__BillingSchedule__c\n'+
                ' where APTS_AddToExternalOrderlineItem__c = false and Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.RecordType.Name =:CONSUMPTION'+
                //v1.1 starts here
                ' AND Apttus_Billing__Type__c =: CONTRACTED AND Apttus_Billing__Status__c =: PENDINGINVOICE ' + 
                'AND Apttus_Billing__OrderLineItemId__r.Apttus_Config2__PriceType__c !=: ONETIME';
                //v1.1 ends here
        system.debug('query ==> BS'+query);     
        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Apttus_Billing__BillingSchedule__c> scope) {
        try{
        set<Id> soldtoId = new set<Id>();
        //v1.1 starts here
        set<Id> setProducts = new set<Id>();
        set<Date> assetLineKeyDates = new set<Date>();
        map<Id, Apttus_Config2__ProductClassification__c> mapProductCategory = 
        new map<Id, Apttus_Config2__ProductClassification__c>();
        //v1.1 ends here
        /* ---------- Start of PI fix # 111937 ----------------------- */
        Apttus_Config2__ExternalOrderSummary__c extnOrd = null;
        set<Id> soldToAcc = new set<Id>();
        set<Id> extIdnew = new set<Id>();
         map<Id,Apttus_Billing__BillingSchedule__c> mapBillSc = new map<Id,Apttus_Billing__BillingSchedule__c>();
         map<Id, Id> mapUsageScheduleToAssetLine = new map<Id, Id>(); 
         List<Apttus_Billing__UsageInput__c> lstUsageInput = new List<Apttus_Billing__UsageInput__c>();
         map<Id, Apttus_Billing__BillingSchedule__c> mapAssetToBilling = new map<Id,Apttus_Billing__BillingSchedule__c>(); 
        /* ---------- End of PI fix # 111937 ----------------------- */
        list<Apttus_Config2__ExternalOrderSummary__c> newlstExtOrd = new list<Apttus_Config2__ExternalOrderSummary__c>();
        for( Apttus_Billing__BillingSchedule__c bs : scope){
            soldtoId.add(bs.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c);
            mapBillSc.put(bs.Id,bs);
            setProducts.add(bs.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__OptionId__c);
            if(bs.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__StartDate__c != null){
                assetLineKeyDates.add(bs.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__StartDate__c);
            }
            if(bs.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__EndDate__c != null){
                assetLineKeyDates.add(bs.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__EndDate__c);
            }
            //v1.2 starts here
            if(!bs.Apttus_Billing__UsageSchedules__r.isEmpty())
            {

                usgSch = (Apttus_Billing__UsageSchedule__c)bs.Apttus_Billing__UsageSchedules__r;
                if(usgSch!=null) {mapUsageScheduleToAssetLine.put(usgSch.Id, usgSch.Apttus_Billing__AssetLineItemId__c);}
            }
            mapAssetToBilling.put(bs.Apttus_Billing__AssetLineItemId__c, bs);
            system.debug('--mapAssetToBilling--'+ mapAssetToBilling);
            //v1.2 ends here
        }
        map<Id,Apttus_Config2__ExternalOrderSummary__c> mapsoldToExt = new map<Id,Apttus_Config2__ExternalOrderSummary__c>();
        list<Apttus_Config2__ExternalOrderSummary__c> lstExtOrd = new list<Apttus_Config2__ExternalOrderSummary__c>();
        
        lstExtOrd = [select Id,
                            Apttus_Config2__AccountId__c,
                            Apttus_Config2__PeriodEndDate__c,
                            Apttus_Config2__PeriodStartDate2__c,
                            Apttus_Config2__Status__c,
                            Apttus_Config2__Type__c 
                        from Apttus_Config2__ExternalOrderSummary__c 
                        where Apttus_Config2__AccountId__c IN :soldtoId
                        AND APTS_Calculate_Rebate_On__c !=: JDEINVOICE
                        AND APTS_Calculate_Rebate_On__c !=: SELLOUTDATA
                        LIMIT 50000];

        for(Apttus_Config2__ExternalOrderSummary__c ext : lstExtOrd){
            if(ext.Apttus_Config2__PeriodStartDate2__c != null
                && !assetLineKeyDates.isEmpty()
                && assetLineKeyDates.contains(ext.Apttus_Config2__PeriodStartDate2__c)
                && assetLineKeyDates.contains(ext.Apttus_Config2__PeriodEndDate__c)
                && !soldtoId.isEmpty()
                && soldtoId.contains(ext.Apttus_Config2__AccountId__c)){
                mapsoldToExt.put(ext.Apttus_Config2__AccountId__c,ext); 
            }
        }
        integer count =0;
        
        //v1.2 starts here
        for(Apttus_Billing__UsageInput__c usageInput : [SELECT Id, Apttus_Billing__AssetLineItemId__c, Apttus_Billing__Status__c, 
                                                        Apttus_Billing__Quantity__c, APTS_ProcessedByBatch__c, Apttus_Billing__UsageDate__c
                                                        FROM Apttus_Billing__UsageInput__c 
                                                        WHERE 
                                                        Apttus_Billing__AssetLineItemId__c IN : 
                                                        mapUsageScheduleToAssetLine.values() 
                                                        AND 
                                                        Apttus_Billing__Status__c =: RATED 
                                                        AND 
                                                        APTS_ProcessedByBatch__c= false
                                                        LIMIT 50000])
        {
            system.debug('-usageinput--'+ usageinput);
            system.debug('--start date--'+ usageInput.Apttus_Billing__UsageDate__c);
            system.debug(mapAssetToBilling.get(usageInput.Apttus_Billing__AssetLineItemId__c).Apttus_Billing__PeriodStartDate__c);
            system.debug('--end date--'+ usageInput.Apttus_Billing__UsageDate__c);
            system.debug(mapAssetToBilling.get(usageInput.Apttus_Billing__AssetLineItemId__c).Apttus_Billing__PeriodEndDate__c);
            if(!mapAssetToBilling.isEmpty() && usageInput.Apttus_Billing__UsageDate__c!= null && 
              usageInput.Apttus_Billing__UsageDate__c >= mapAssetToBilling.get(usageInput.Apttus_Billing__AssetLineItemId__c).Apttus_Billing__PeriodStartDate__c && 
              usageInput.Apttus_Billing__UsageDate__c <= mapAssetToBilling.get(usageInput.Apttus_Billing__AssetLineItemId__c).Apttus_Billing__PeriodEndDate__c){
                mapAssetLineToUsageInput.put(usageInput.Apttus_Billing__AssetLineItemId__c, usageInput);
            }
            system.debug('--mapAssetLineToUsageInput--'+ mapAssetLineToUsageInput);
        }
        //v1.2 ends here
        
        //v1.1 starts here        
        for(Apttus_Config2__ProductClassification__c productClassification : [SELECT Id,
                    Apttus_Config2__ProductId__c, 
                    Apttus_Config2__ProductId__r.ProductCode,
                    Apttus_Config2__ClassificationId__c,
                    Apttus_Config2__ClassificationId__r.Apttus_Config2__Label__c,
                    Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__r.Apttus_Config2__Label__c ,
                    Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__Label__c,
                    Apttus_Config2__ClassificationId__r.APTS_CategoryHierarchyOfferingExtId__c
                FROM Apttus_Config2__ProductClassification__c 
                WHERE Apttus_Config2__ProductId__r.IsActive = true 
                AND  Apttus_Config2__ProductId__c IN : setProducts
                AND APTS_Category_Name__c !=: CONSIGNMENTINGREDIENTS
                AND Apttus_Config2__ClassificationId__r.APTS_CategoryHierarchyOfferingExtId__c != NULL 
                LIMIT 50000]){
                mapProductCategory.put(productClassification.Apttus_Config2__ProductId__c, productClassification);
        }
        //v1.1 ends here
        
        for(Apttus_Billing__BillingSchedule__c bills : scope){
            extLn = new Apttus_Config2__ExternalOrderSummaryItem__c();
            
            if(mapsoldToExt.containsKey(
                bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c))
            {
                                
                if(!bills.Apttus_Billing__UsageSchedules__r.isEmpty())
                {

                    usgSch = (Apttus_Billing__UsageSchedule__c)bills.Apttus_Billing__UsageSchedules__r;
                }
                else
                {
                    usgSch = null;

                }
                extLn.Apttus_Config2__BillToAccountId__c = bills.Apttus_Billing__BillToAccountId__c;
                extLn.Apttus_Config2__LineNumber__c = count++;
                extLn.Apttus_Config2__ListPrice__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ListPrice__c;
                extLn.Apttus_Config2__NetPrice__c = bills.Apttus_Billing__FeeAmount__c;
                extLn.Apttus_Config2__NetUnitPrice__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetUnitPrice__c;
                extLn.Apttus_Config2__PeriodEndDate__c = bills.Apttus_Billing__ReadyForInvoiceDate__c;
                //extLn.Apttus_Config2__PeriodStartDate__c = bills.Apttus_Billing__PeriodStartDate__c;
                if(bills.Apttus_Billing__AssetLineItemId__c != null
                    && bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__OptionId__c != null){
                    extLn.Apttus_Config2__ProductId__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__OptionId__c;
                }else{
                    extLn.Apttus_Config2__ProductId__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c;
                }
                extLn.Apttus_Config2__SellingFrequency__c =  bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingFrequency__c;
                extLn.Apttus_Config2__ShipToAccountId__c = bills.Apttus_Billing__ShipToAccountId__c;
                extLn.Apttus_Config2__SoldToAccountId__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c;
                extLn.Apttus_Config2__OrderSummaryId__c = mapsoldToExt.get(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Id;
                extLn.Apttus_Config2__Status__c = DRAFT;
                extln.APTS_Category__c = CONSUMPTIONCLASSIFICATION;
                extln.APTS_Subcategory__c = CONSUMPTIONCLASSIFICATION;
                if(bills.Apttus_Billing__AssetLineItemId__c != null
                    && bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingUom__c != null){
                   extln.Apttus_Config2__SellingUom__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingUom__c; 
                }
                
                //v1.2 starts here
                //extln.Apttus_Config2__Quantity__c =  usgSch!=null ? usgSch.Apttus_Billing__ActualQuantity__c : null;// Commented during to change in logic to populate quantity from Usage input as part of CR2106
                extln.Apttus_Config2__Quantity__c = usgSch!=null && !mapAssetLineToUsageInput.isEmpty() && 
                                                      mapAssetLineToUsageInput.containsKey(usgSch.Apttus_Billing__AssetLineItemId__c) ? mapAssetLineToUsageInput.get(usgSch.Apttus_Billing__AssetLineItemId__c).Apttus_Billing__Quantity__c : null;
                if(usgSch!=null && !mapAssetLineToUsageInput.isEmpty() && 
                                                      mapAssetLineToUsageInput.containsKey(usgSch.Apttus_Billing__AssetLineItemId__c))
                {
                    lstUsageInput.add(mapAssetLineToUsageInput.get(usgSch.Apttus_Billing__AssetLineItemId__c));
                }
                //v1.2 ends here
                extln.Apttus_Config2__ProductUom__c = usgSch!= null ? usgSch.Apttus_Billing__Uom__c : null; 
                //v1.1 starts here
                
                if(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c != null && mapProductCategory.containsKey(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c)
                && mapProductCategory.get(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c) != null){
                    if(mapProductCategory.get(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__c != null){
                        extln.Apttus_Config2__ProductCategory__c = mapProductCategory.get(
                            bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__r.Apttus_Config2__Label__c;
                     //v1.2 starts here. Commented logic for populating category, sub category and sub-sub category.       
                    //    extln.APTS_SubSubcategory__c = mapProductCategory.get(
                      //      bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__r.Apttus_Config2__Label__c;
                    }
                    /* if(mapProductCategory.get(
                    bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c != null){
                        extln.APTS_Category__c =  mapProductCategory.get(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__r.Apttus_Config2__Label__c;
                    }
                    if(mapProductCategory.get(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c != null){
                        extln.APTS_Subcategory__c = mapProductCategory.get(
                        bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__Label__c;
                    } */ //v1.2 ends here
                }
                //v1.1 ends here
                lstExtOrdli.add(extLn);
                bills.APTS_AddToExternalOrderlineItem__c = true;
                lstBillSchToupdate.add(bills);
            }else{
                mapAllProductCategory.putAll(mapProductCategory);
                if(bsToExtLn.containsKey(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c)){
                    list<Apttus_Billing__BillingSchedule__c> lsBs = new list<Apttus_Billing__BillingSchedule__c>();
                    lsBs = bsToExtLn.get(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c);
                    lsBs.add(bills);
                    bsToExtLn.put(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c,lsBs);
                    
                }else{
                    list<Apttus_Billing__BillingSchedule__c> lsBs = new list<Apttus_Billing__BillingSchedule__c>();
                    lsBs.add(bills);
                    bsToExtLn.put(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c,lsBs);
                }

                if(!soldToAcc.contains(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c)){ 
                    extnOrd = new Apttus_Config2__ExternalOrderSummary__c();
                    extnOrd.Apttus_Config2__AccountId__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c;
                    extnOrd.Apttus_Config2__PeriodEndDate__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__EndDate__c;
                    extnOrd.Apttus_Config2__PeriodStartDate2__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__StartDate__c;
                    extnOrd.Apttus_Config2__Status__c = DRAFT;
                    extnOrd.Apttus_Config2__Type__c = SALESDATA;
                    //extnOrd.APTS_ExternalId__c = bills.Id;
                    newlstExtOrd.add(extnOrd);
                    soldToAcc.add(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c);
                }
            }
        }
         system.debug('--Main List newlstExtOrd --'+ newlstExtOrd);
         DescribeSObjectResult objResultEO = APTS_OTCUtil.getsObjectAccess(EXTERNALORDERSUMMARY);
        
        if(objResultEO!= null && objResultEO.isCreateable())
        {
            Database.SaveResult[] srList = Database.insert(newlstExtOrd, false);
            system.debug('--srList--'+ srList);
            APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,EXTERNALORDERSUMMARYOBJ,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
            
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    extIdnew.add(sr.getId());
                }       
            }
        
        }
        
        
        for(Apttus_Config2__ExternalOrderSummary__c exor : [select Id,Apttus_Config2__AccountId__c from Apttus_Config2__ExternalOrderSummary__c where Id in: extIdnew]){
            mapExtOrd.put(exor.Apttus_Config2__AccountId__c,exor);
        }
        }catch(Exception e){
            system.debug('e '+e.getMessage() + e.getLineNumber());
            APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,'execute() Method',APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
        }


    }
    
    global void finish(Database.BatchableContext BC) {
        try{
        integer line=0;
        /* ---------- PI fix # 111937 ----------------------- */
        List<Apttus_Billing__UsageInput__c> lstUpdateUsageInput = new List<Apttus_Billing__UsageInput__c>();
        list<Apttus_Config2__ExternalOrderSummaryItem__c> lstextln = new list<Apttus_Config2__ExternalOrderSummaryItem__c>();
        list<Apttus_Billing__BillingSchedule__c> billToupdate = new list<Apttus_Billing__BillingSchedule__c>();
        for(Id accsldto : bsToExtLn.keySet()){
            list<Apttus_Billing__BillingSchedule__c> lstbills = bsToExtLn.get(accsldto);
            for(Apttus_Billing__BillingSchedule__c bills : lstbills){

                usgSch = !bills.Apttus_Billing__UsageSchedules__r.isEmpty() ? 
                (Apttus_Billing__UsageSchedule__c)bills.Apttus_Billing__UsageSchedules__r : null; 
                extLn = new Apttus_Config2__ExternalOrderSummaryItem__c();
                extLn.Apttus_Config2__BillToAccountId__c = bills.Apttus_Billing__BillToAccountId__c;
                extLn.Apttus_Config2__LineNumber__c = line++;
                extLn.Apttus_Config2__ListPrice__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ListPrice__c;
                extLn.Apttus_Config2__NetPrice__c = bills.Apttus_Billing__FeeAmount__c;
                extLn.Apttus_Config2__NetUnitPrice__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetUnitPrice__c;
                extLn.Apttus_Config2__PeriodEndDate__c = bills.Apttus_Billing__ReadyForInvoiceDate__c;
                //extLn.Apttus_Config2__PeriodStartDate__c = bills.Apttus_Billing__PeriodStartDate__c;
                extLn.Apttus_Config2__ProductId__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c;
                extLn.Apttus_Config2__SellingFrequency__c =  bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingFrequency__c;
                extLn.Apttus_Config2__ShipToAccountId__c = bills.Apttus_Billing__ShipToAccountId__c;
                extLn.Apttus_Config2__SoldToAccountId__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c;
                extLn.Apttus_Config2__OrderSummaryId__c = mapExtOrd.get(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Id;
                
                //v1.2 starts here
                //extln.Apttus_Config2__Quantity__c =  usgSch!= null ? usgSch.Apttus_Billing__ActualQuantity__c : null; // Commented during to change in logic to populate quantity from Usage input as part of CR2106
                extln.Apttus_Config2__Quantity__c = usgSch!=null && !mapAssetLineToUsageInput.isEmpty() && 
                                                    mapAssetLineToUsageInput.containsKey(usgSch.Apttus_Billing__AssetLineItemId__c) ? mapAssetLineToUsageInput.get(usgSch.Apttus_Billing__AssetLineItemId__c).Apttus_Billing__Quantity__c : null;
                //v1.2 ends here
                
                extln.Apttus_Config2__ProductUom__c = usgSch!= null ? usgSch.Apttus_Billing__Uom__c : null;
                extln.APTS_Category__c = CONSUMPTIONCLASSIFICATION;
                extln.APTS_Subcategory__c = CONSUMPTIONCLASSIFICATION;
                extLn.Apttus_Config2__Status__c = DRAFT;
                if(bills.Apttus_Billing__AssetLineItemId__c != null
                    && bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingUom__c != null){
                   extln.Apttus_Config2__SellingUom__c = bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingUom__c; 
                }
                //v1.1 starts here
                if(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c != null
                && mapAllProductCategory.containsKey(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c)
                && mapAllProductCategory.get(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c) != null){
                    if(mapAllProductCategory.get(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__c != null){
                        extln.Apttus_Config2__ProductCategory__c = mapAllProductCategory.get(
                            bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__r.Apttus_Config2__Label__c;
                            //v1.2 starts here. Commented logic for populating category, sub category and sub-sub category.
                        //extln.APTS_SubSubcategory__c = mapAllProductCategory.get(
                          //  bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__r.Apttus_Config2__Label__c;
                    }
                    /* if(mapAllProductCategory.get(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c != null){
                        extln.APTS_Category__c =  mapAllProductCategory.get(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__r.Apttus_Config2__Label__c;
                    }
                    if(mapAllProductCategory.get(bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c != null){
                        extln.APTS_Subcategory__c = mapAllProductCategory.get(
                        bills.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__Label__c;
                    } */ 
                    //v1.2 ends here
                }
                //v1.1 ends here
                lstextln.add(extLn);
                bills.APTS_AddToExternalOrderlineItem__c = true;
                billToupdate.add(bills);
            }
        }
        //v1.2 starts here. Once the usage input quantity is proccessed by this batch, it shouldn't be picked in next batch run.
        for(Apttus_Billing__UsageInput__c usageInput : mapAssetLineToUsageInput.values())
        {
            usageInput.APTS_ProcessedByBatch__c = True;
            lstUpdateUsageInput.add(usageInput);
        }
        system.debug('--lstUpdateUsageInput--'+ lstUpdateUsageInput);
        //v1.2 ends here
        lstextln.addAll(lstExtOrdli);
        billToupdate.addAll(lstBillSchToupdate);
        //system.debug('--Main List lstextln --'+ lstextln);
        DescribeSObjectResult objResultEOS = APTS_OTCUtil.getsObjectAccess(EXTERNALORDERSUMMARYITEM);
        DescribeSObjectResult objResultBS = APTS_OTCUtil.getsObjectAccess(BILLINGSCHEDULE);
        DescribeSObjectResult objResultUI = APTS_OTCUtil.getsObjectAccess(USAGEINPUT);
        
        if(objResultEOS != null && (objResultEOS.isCreateable() || objResultEOS.isUpdateable()) )
        {
            //system.debug('--lstextln --'+ lstextln);
            Database.SaveResult[] srList = Database.insert(lstextln,false);
            system.debug('--srList --'+ srList);
            APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,EXTERNALORDERSUMMARYOBJ,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
        }
        
        if(objResultBS  != null &&  objResultBS.isUpdateable() )
        {
            Database.SaveResult[] srListBs = Database.update(billToupdate,false);
            APTS_BIRUtils.logError(null,srListBs,null,null,APTS_BIRUtils.BATCH,BILLINGSCHEDULE,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
        }
        
        //v1.2 starts here
        if(objResultUI != null &&  objResultUI.isUpdateable() )
        {
            Database.SaveResult[] srListUI = Database.update(lstUpdateUsageInput,false);
            system.debug('--srListUI --'+ srListUI);
            APTS_BIRUtils.logError(null,srListUI,null,null,APTS_BIRUtils.BATCH,USAGEINPUT,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
        }
        //v1.2 ends here
        
        }catch(Exception e){
            system.debug('e ==> '+e.getMessage());
            APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,'finish() Method',APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
        }
    }
}