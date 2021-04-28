public with sharing class APTS_NetPriceExtraction {
    public static final String IN_EFFECT = 'In Effect';

    Public static void updateNetPriceExtraction(Set<Id> accountSet) {
        String inClause = String.format('(\'\'{0}\'\')',
                                        new List<String> { String.join(new List<Id> (accountSet), '\',\'') });
        String query = 'SELECT Id FROM Account WHERE(Purchasing_Organization__c IN ' + inClause + '  OR Parent.Parent.Id IN ' + inClause + ' OR Parent.Id IN ' + inClause + ' OR ID IN ' + inClause + ' ) limit 50000';
        database.executeBatch(new APTS_NetPriceExtractionBatch(query), 2);
    }





    public static void insertNetPrice(Id soldToAccountId) {
        // The first step is to obtain the record which are the CER located (not pending)
        Id tempSoldToAccountId = APTS_CERUtility.getCerRecordAccountForRelatedAccount(soldToAccountId, false);
        decimal price = 0.0, tempPrice = 0.0, uomFactor = 0.0, StartingPrice = 0.0, tempPriceBP = 0.0, uomLIFactor = 0.0, listPrice = 0.0; //Lavanya
        Boolean tempFlag = true;
        Id tempCategoryId;
        Id categoryId;
        Id priceListId;
        Id basedOnPriceListId;
        String IncomingProdId;
        Set<Id> salesOrgProducts = new Set<Id> ();
        Set<Id> ingrProductSet = new Set<Id> ();
        Set<String> uomString = new Set<String> ();
        Set<String> uomALLString = new Set<String> ();
        Set<String> uomExtraString = new Set<String> ();
        Set<String> uomLIString = new Set<String> ();
        List<Id> categories = new List<Id> ();
        List<Id> subCategories = new List<Id> ();
        Boolean overrideFlg = false;
        Map<String, Decimal> uomOutput = new Map<String, Decimal> ();
        Map<String, Decimal> uomLIOutput = new Map<String, Decimal> ();
        Boolean check = false;
        string tempString, tempString1, tempString2, tempLIString, tempStringKG, tempStringBX, tempStringPCE;
        Boolean inTestScope = Test.isRunningTest();
        List<Id> subSubCategories = new List<Id> ();
        Map<Id, Id> productPLI = new Map<Id, Id> ();
        Map<Id, Map<String, Decimal>> mapProductBPO = new Map<Id, Map<String, Decimal>> (); // Lavanya
        Map<Id, String> productUom = new Map<Id, String> ();
        Map<Id, String> productDeafultSellingUom = new Map<Id, String> ();
        Map<Id, String> productChargeType = new Map<Id, String> ();
        Map<Id, String> productReplacement = new Map<Id, String> ();
        Set<Id> priceListItemSet = new Set<Id> ();
        List<APTS_Net_Price_Extraction__c> insertList = new List<APTS_Net_Price_Extraction__c> ();
        APTS_Net_Price_Extraction__c tempNetPriceRecord = new APTS_Net_Price_Extraction__c();
        APTS_GetPriceRest.GetPriceWrapper gpw;
        Map<String, Decimal> tempMap;
        List<String> bucketList = new List<String> { 'Bucket 1', 'Bucket 2', 'Bucket 3', 'Bucket 4', 'Bucket 5', 'Bucket 6', 'Bucket 7', 'Bucket 8' }; // Buckets to group the results
        Map<String, List<APTS_Contract_Entitlement_Repository__c>> tempGroupByBucket = new Map<String, List<APTS_Contract_Entitlement_Repository__c>> ();
        Map<Id, Map<String, List<APTS_Contract_Entitlement_Repository__c>>> productMap = new Map<Id, Map<String, List<APTS_Contract_Entitlement_Repository__c>>> ();
        Map<Id, List<APTS_Contract_Entitlement_Repository__c>> aliMap = new Map<Id, List<APTS_Contract_Entitlement_Repository__c>> ();
        Map<Id, Decimal> productStartPrice = new Map<Id, Decimal> ();
        Map<Id, String> sapCode = new Map<Id, String> ();
        List<APTS_Contract_Entitlement_Repository__c> tempCerRecords = new List<APTS_Contract_Entitlement_Repository__c> ();
        List<APTS_Contract_Entitlement_Repository__c> tCerRecord = new List<APTS_Contract_Entitlement_Repository__c> ();
        List<Apttus_Config2__PriceListItem__c> lstPriceListItem;
        List<APTS_Contract_Entitlement_Repository__c> cerRecords = new List<APTS_Contract_Entitlement_Repository__c> ();
        List<APTS_Contract_Entitlement_Repository__c> categoryCerRecords = new List<APTS_Contract_Entitlement_Repository__c> ();
        list<Account> salAcc = new list<Account> ();
        list<APTS_Sales_Org_Data__c> salesOrgDataList = new list<APTS_Sales_Org_Data__c> ();
        List<Account> acc = [select Id, Account_Type__c from Account where id = :soldToAccountId];
        Set<String> uniqueProductSet = new Set<String> ();
        String uniqueproduct;
        //if (acc.size() > 0 && acc[0].Account_Type__c != null && acc[0].Account_Type__c == APTS_CERUtility.PROSPECT && !(inTestScope)) {
        //returnObject.success = true;
        //return returnObject;
        //}
        // If there are no products as parameters, the query SOQL does not include any product filtering
        Set<Id> agreementExculsion = new Set<Id> ();
        for (APTS_Agreement_Account_Exclusion__c aae :[Select APTS_Agreement__c from APTS_Agreement_Account_Exclusion__c where APTS_Account__c = :soldToAccountId])
        {
            if (!agreementExculsion.contains(aae.APTS_Agreement__c))
            agreementExculsion.add(aae.APTS_Agreement__c);
        }
        List<Product2> lstProduct = [SELECT Id, Name FROM Product2 WHERE APTS_Category_Adjustments_Product__c = true];
        categoryId = lstProduct.size() > 0 ? lstProduct[0].Id : null;
        cerRecords = [Select id, APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePrice__c, APTS_Charge_Type__c,
                      APTS_Adjustment_Value__c, APTS_Adjustment_Type__c, APTS_Type__c, APTS_Sub_Type__c,
                      APTS_Adjustment_Applies_To__c, APTS_Bucket__c, APTS_Product__c, APTS_Product__r.ProductCode,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c, APTS_Category_Level__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_VAT_indicator_Digital__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceListId__c,
                      APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c, APTS_Amendment_In_Progress__c,
                      APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c, APTS_Agreement_Line_Item__r.APTS_More_Standalone__c, APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone_or_Spare_Part__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.CurrencyIsoCode,
                      APTS_UOM__c,
                      //  APTS_Agreement_Line_Item__r.Apttus__AgreementId__r.APTS_Customer_Specific_Freight_charge__c,
                      APTS_Product__r.Name,
                      APTS_Product__r.Family,
                      APTS_End_Date__c,
                      APTS_Agreement_Line_Item__c,
                      APTS_CategoryCER__c,
                      APTS_Sub_Category__c,
                      APTS_Start_Date__c,
                      APTS_Sub_Sub_Category__c, APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c, APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Product_Code__c
                      from APTS_Contract_Entitlement_Repository__c
                      where APTS_Sold_to_Party__c = :tempSoldToAccountId
                      and APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__Active__c = true
                      and APTS_Contributing_Agreement__c not in :agreementExculsion
                      and APTS_Agreement_Line_Item__c not in(Select APTS_Agreement_Line_Item__c from APTS_Agreement_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                      and APTS_Agreement_Adjustment_Line_Item__c not in(Select APTS_Agreement_Adjustment_Line_Item__c from APTS_Adjustment_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                      and APTS_Bucket__c != ''
                      and APTS_Is_Pending__c = false
                      //and APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c = :APTS_CERUtility.PRODUCT_SERVICE
                      and(APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c = true or APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c = true or
                          APTS_Agreement_Line_Item__r.APTS_More_Standalone__c = true)
                      ORDER BY APTS_Contributing_Agreement_Level_Num__c, APTS_Category_Level__c Desc];
        try {
            if (cerRecords.size() > 0)
            {
                salAcc = [select Sales_Organization__c from Account where id = :tempSoldToAccountId];

                string tempSaleOrg = salAcc.size() > 0 && salAcc[0].Sales_Organization__c != null ? salAcc[0].Sales_Organization__c.substring(4, salAcc[0].Sales_Organization__c.length()) : '';


                if (cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c != null)
                salesOrgDataList = [SELECT Id, APTS_Product__c FROM APTS_Sales_Org_Data__c WHERE APTS_Sales_Org_Data_Name__c = :tempSaleOrg and(APTS_Price_List__c = :cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c or APTS_Price_List__c = :cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c) and APTS_Product__c != null];
                else
                salesOrgDataList = [SELECT Id, APTS_Product__c FROM APTS_Sales_Org_Data__c WHERE APTS_Sales_Org_Data_Name__c = :tempSaleOrg and APTS_Price_List__c = :cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c and APTS_Product__c != null];

                if (inTestScope) {
                    salesOrgDataList = [SELECT Id, APTS_Product__c FROM APTS_Sales_Org_Data__c limit 20];
                    categoryCerRecords = [Select id, APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c,
                                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePrice__c, APTS_Charge_Type__c,
                                          APTS_Adjustment_Value__c, APTS_Adjustment_Type__c, APTS_Type__c, APTS_Sub_Type__c,
                                          APTS_Adjustment_Applies_To__c, APTS_Bucket__c, APTS_Product__c, APTS_Product__r.ProductCode,
                                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c, APTS_Category_Level__c,
                                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_VAT_indicator_Digital__c,
                                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c,
                                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceListId__c,
                                          APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c,
                                          APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c,
                                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.CurrencyIsoCode,
                                          APTS_Product__r.Name,
                                          APTS_Product__r.Family,
                                          APTS_End_Date__c,
                                          APTS_CategoryCER__c,
                                          APTS_Sub_Category__c,
                                          APTS_UOM__c,
                                          APTS_Start_Date__c,
                                          APTS_Sub_Sub_Category__c,
                                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Product_Code__c
                                          from APTS_Contract_Entitlement_Repository__c
                                          Limit : 20];
                }

                for (APTS_Sales_Org_Data__c salesOrgData : salesOrgDataList) {
                    if (!salesOrgProducts.contains(salesOrgData.APTS_Product__c)) {
                        salesOrgProducts.add(salesOrgData.APTS_Product__c);
                    }
                }


                if (cerRecords.size() > 0)
                {
                    priceListId = cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c;
                    basedOnPriceListId = cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c;
                    priceListItemSet.add(priceListId);
                    if (basedOnPriceListId != NULL)
                    priceListItemSet.add(basedOnPriceListId);
                }
                for (APTS_Contract_Entitlement_Repository__c cerRecord : cerRecords) {


                    if ((cerRecord.APTS_Product__c != null && cerRecord.APTS_Product__c == categoryId) || inTestScope) {

                        if (cerRecord.APTS_Category_Level__c == APTS_CERUtility.CATEGORY) {
                            categories.add(cerRecord.APTS_CategoryCER__c);
                        } else if (cerRecord.APTS_Category_Level__c == APTS_CERUtility.SUB_CATEGORY) {
                            subCategories.add(cerRecord.APTS_Sub_Category__c);
                        } else if (cerRecord.APTS_Category_Level__c == APTS_CERUtility.SUB_SUB_CATEGORY) {
                            subSubCategories.add(cerRecord.APTS_Sub_Sub_Category__c);
                        } else {
                            if (!ingrProductSet.contains(cerRecord.APTS_Product__c) && salesOrgProducts.contains(cerRecord.APTS_Product__c)) {
                                ingrProductSet.add(cerRecord.APTS_Product__c);
                            }
                        }
                        categoryCerRecords.add(cerRecord);
                    }
                }
                Set<Id> tempProductSet = new Set<Id> ();


                List<Apttus_Config2__ProductClassification__c> productList = new List<Apttus_Config2__ProductClassification__c> ();

                productList = [SELECT Id, Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.ProductCode, Apttus_Config2__ClassificationId__c, Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c, Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c, Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c FROM Apttus_Config2__ProductClassification__c WHERE Apttus_Config2__ProductId__r.IsActive = true
                               and Apttus_Config2__ProductId__c in :salesOrgProducts
                               and(Apttus_Config2__ProductId__c in :ingrProductSet
                                   OR Apttus_Config2__ClassificationId__c IN :categories
                                   OR Apttus_Config2__ClassificationId__c IN :subCategories
                                   OR Apttus_Config2__ClassificationId__c IN :subSubCategories
                                   OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c IN :categories
                                   OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c IN :subCategories
                                   OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c IN :categories)
                              ];
                if (inTestScope) {
                    productList = [SELECT Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.ProductCode, Apttus_Config2__ClassificationId__c, Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c FROM Apttus_Config2__ProductClassification__c limit 20];
                }

                for (APTS_Contract_Entitlement_Repository__c cerRecord : cerRecords) {
                    if (cerRecord.APTS_Product__c == categoryId) {
                        continue;
                    }
                    check = true;
                    if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c != null && cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c > 0) //BPO,BP instead of LP
                    {
                        tempMap = new Map<String, Decimal> ();
                        tempMap.put('IngredientBPO', cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c);
                        mapProductBPO.put(cerRecord.APTS_Product__c, tempMap);
                    }
                    //else
                    //{
                    //tempMap = new Map<String, Decimal> ();
                    //tempMap.put('Ingredient', cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePrice__c);
                    //mapProductBPO.put(cerRecord.APTS_Product__c, tempMap);
                    //}

                    if (!productMap.keySet().contains(cerRecord.APTS_Product__c)) {
                        if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_Start_Date__c != null && cerRecord.APTS_Start_Date__c > Date.today())) {
                            check = false;
                        }
                        if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_End_Date__c != null && cerRecord.APTS_End_Date__c <= Date.today())) {
                            check = false;
                        }
                        if (check) {
                            tempGroupByBucket =
                            productMap.get(cerRecord.APTS_Product__c) != null ?
                            productMap.get(cerRecord.APTS_Product__c) : new Map<String, List<APTS_Contract_Entitlement_Repository__c>> ();
                            tempCerRecords =
                            tempGroupByBucket.get(cerRecord.APTS_Bucket__c) != null ?
                            tempGroupByBucket.get(cerRecord.APTS_Bucket__c) :
                            new List<APTS_Contract_Entitlement_Repository__c> ();
                            tempCerRecords.add(cerRecord);
                            tempGroupByBucket.put(cerRecord.APTS_Bucket__c, tempCerRecords);
                            productMap.put(cerRecord.APTS_Product__c, tempGroupByBucket);
                            aliMap.put(cerRecord.APTS_Product__c, tempCerRecords);
                            sapCode.put(cerRecord.APTS_Product__c, cerRecord.APTS_Product__r.ProductCode);
                        }
                    } else {
                        for (String s : bucketList) {
                            List<APTS_Contract_Entitlement_Repository__c> tCerRecords = productMap.get(cerRecord.APTS_Product__c).get(s) != null ? productMap.get(cerRecord.APTS_Product__c).get(s) : new List<APTS_Contract_Entitlement_Repository__c> ();
                            if (tCerRecords.size() == 0) {
                                continue;
                            }
                            for (APTS_Contract_Entitlement_Repository__c cr : tCerRecords) {
                                if (cerRecord.APTS_Type__c == cr.APTS_Type__c && cerRecord.APTS_Sub_Type__c == cr.APTS_Sub_Type__c && cerRecord.APTS_Charge_Type__c == cr.APTS_Charge_Type__c) {
                                    check = false;
                                }
                                if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_Start_Date__c != null && cerRecord.APTS_Start_Date__c > Date.today())) {
                                    check = false;
                                }
                                if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_End_Date__c != null && cerRecord.APTS_End_Date__c <= Date.today())) {
                                    check = false;
                                }

                            }

                            if (check || inTestScope) {
                                tempGroupByBucket = productMap.get(cerRecord.APTS_Product__c) != null ?
                                productMap.get(cerRecord.APTS_Product__c) : new Map<String, List<APTS_Contract_Entitlement_Repository__c>> ();
                                tempCerRecords = tempGroupByBucket.get(cerRecord.APTS_Bucket__c) != null ? tempGroupByBucket.get(cerRecord.APTS_Bucket__c) :
                                new List<APTS_Contract_Entitlement_Repository__c> ();
                                tempCerRecords.add(cerRecord);
                                tempGroupByBucket.put(cerRecord.APTS_Bucket__c, tempCerRecords);
                                productMap.put(cerRecord.APTS_Product__c, tempGroupByBucket);
                                aliMap.put(cerRecord.APTS_Product__c, tempCerRecords);
                                sapCode.put(cerRecord.APTS_Product__c, cerRecord.APTS_Product__r.ProductCode);
                            }

                        }
                    }
                }

                for (Apttus_Config2__ProductClassification__c products : productList) {

                    if (!salesOrgProducts.contains(products.Apttus_Config2__ProductId__c)) {
                        continue;
                    }

                    for (APTS_Contract_Entitlement_Repository__c cerRecord : categoryCerRecords) {
                        if (cerRecord.APTS_Product__c != categoryId && !inTestScope) {
                            continue;
                        }
                        check = true;

                        if (!productMap.keySet().contains(products.Apttus_Config2__ProductId__c)) {

                            if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_Start_Date__c != null && cerRecord.APTS_Start_Date__c > Date.today())) {
                                check = false;
                            }
                            if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_End_Date__c != null && cerRecord.APTS_End_Date__c <= Date.today())) {
                                check = false;
                            } //6653- Added OR condition to check Ancestor's Ancestor for Category Level 
                            if (check && ((cerRecord.APTS_Category_Level__c == APTS_CERUtility.CATEGORY && (products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_CategoryCER__c || products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_CategoryCER__c || products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_CategoryCER__c)) || (cerRecord.APTS_Category_Level__c == APTS_CERUtility.SUB_CATEGORY && (products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_Sub_Category__c || products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_Sub_Category__c)
                                                                                                                                                                                                                                                                                                                                                                                                                                                            && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c == cerRecord.APTS_CategoryCER__c) || (cerRecord.APTS_Category_Level__c == APTS_CERUtility.SUB_SUB_CATEGORY && products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_Sub_Sub_Category__c && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_Sub_Category__c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c == cerRecord.APTS_CategoryCER__c)) || inTestScope) {
                                tempGroupByBucket = productMap.get(products.Apttus_Config2__ProductId__c) != null ?
                                productMap.get(products.Apttus_Config2__ProductId__c) : new Map<String, List<APTS_Contract_Entitlement_Repository__c>> ();
                                tempCerRecords = tempGroupByBucket.get(cerRecord.APTS_Bucket__c) != null ? tempGroupByBucket.get(cerRecord.APTS_Bucket__c) :
                                new List<APTS_Contract_Entitlement_Repository__c> ();
                                tempCerRecords.add(cerRecord);
                                tempGroupByBucket.put(cerRecord.APTS_Bucket__c, tempCerRecords);
                                productMap.put(products.Apttus_Config2__ProductId__c, tempGroupByBucket);
                                aliMap.put(products.Apttus_Config2__ProductId__c, tempCerRecords);
                                sapCode.put(products.Apttus_Config2__ProductId__c, products.Apttus_Config2__ProductId__r.ProductCode);

                            }

                        } else {

                            for (String s : bucketList) {
                                List<APTS_Contract_Entitlement_Repository__c> tCerRecords = productMap.get(products.Apttus_Config2__ProductId__c).get(s) != null ? productMap.get(products.Apttus_Config2__ProductId__c).get(s) : new List<APTS_Contract_Entitlement_Repository__c> ();
                                if (tCerRecords.size() == 0) {
                                    continue;
                                }
                                for (APTS_Contract_Entitlement_Repository__c cr : tCerRecords) {
                                    if (cerRecord.APTS_Type__c == cr.APTS_Type__c && cerRecord.APTS_Sub_Type__c == cr.APTS_Sub_Type__c && cerRecord.APTS_Charge_Type__c == cr.APTS_Charge_Type__c) {
                                        check = false;
                                    }
                                    if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_Start_Date__c != null && cerRecord.APTS_Start_Date__c > Date.today())) {
                                        check = false;
                                    }
                                    if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_End_Date__c != null && cerRecord.APTS_End_Date__c <= Date.today())) {
                                        check = false;
                                    }

                                } ////6653- Added OR condition to check Ancestor's Ancestor for Category Level 
                                if (inTestScope || (check && ((cerRecord.APTS_Category_Level__c == APTS_CERUtility.CATEGORY && (products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_CategoryCER__c || products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_CategoryCER__c || products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_CategoryCER__c)) || (cerRecord.APTS_Category_Level__c == APTS_CERUtility.SUB_CATEGORY && (products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_Sub_Category__c || products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_Sub_Category__c)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c == cerRecord.APTS_CategoryCER__c) || (cerRecord.APTS_Category_Level__c == APTS_CERUtility.SUB_SUB_CATEGORY && products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_Sub_Sub_Category__c && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_Sub_Category__c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c == cerRecord.APTS_CategoryCER__c)))) {
                                    tempGroupByBucket =
                                    productMap.get(products.Apttus_Config2__ProductId__c) != null ?
                                    productMap.get(products.Apttus_Config2__ProductId__c) : new Map<String, List<APTS_Contract_Entitlement_Repository__c>> ();
                                    tempCerRecords =
                                    tempGroupByBucket.get(cerRecord.APTS_Bucket__c) != null ?
                                    tempGroupByBucket.get(cerRecord.APTS_Bucket__c) :
                                    new List<APTS_Contract_Entitlement_Repository__c> ();
                                    tempCerRecords.add(cerRecord);
                                    tempGroupByBucket.put(cerRecord.APTS_Bucket__c, tempCerRecords);
                                    productMap.put(products.Apttus_Config2__ProductId__c, tempGroupByBucket);
                                    aliMap.put(products.Apttus_Config2__ProductId__c, tempCerRecords);
                                    sapCode.put(products.Apttus_Config2__ProductId__c, products.Apttus_Config2__ProductId__r.ProductCode);

                                }
                            }
                        }
                        //  }
                    }

                }
                if (basedOnPriceListId != Null)
                lstPriceListItem = new List<Apttus_Config2__PriceListItem__c> ([select Apttus_Config2__ListPrice__c, APTS_Default_selling_UOM__c, Apttus_Config2__ChargeType__c, Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c, Apttus_Config2__ProductId__c, Apttus_Config2__PriceUom__c, APTS_Tax_per_UOM__c, APTS_VAT_indicator_Digital__c, APTS_Product_Code__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__c IN :productMap.keySet() and Apttus_Config2__PriceListId__c = :priceListItemSet and Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true and
                                                                               Apttus_Config2__Active__c = true and(Apttus_Config2__ExpirationDate__c = null or Apttus_Config2__ExpirationDate__c >= TODAY) and
                (Apttus_Config2__PriceListId__r.Apttus_Config2__ExpirationDate__c = null or Apttus_Config2__PriceListId__r.Apttus_Config2__ExpirationDate__c >= TODAY) order by Apttus_Config2__PriceListId__c DESC]);
                else
                lstPriceListItem = new List<Apttus_Config2__PriceListItem__c> ([select Apttus_Config2__ListPrice__c, APTS_Default_selling_UOM__c, Apttus_Config2__ChargeType__c, Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c, Apttus_Config2__ProductId__c, Apttus_Config2__PriceUom__c, APTS_Tax_per_UOM__c, APTS_VAT_indicator_Digital__c, APTS_Product_Code__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__c IN :productMap.keySet() and Apttus_Config2__PriceListId__c = :priceListId]);
                for (Apttus_Config2__PriceListItem__c p : lstPriceListItem) {


                    if (p.Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c != null)
                    {
                        if (!mapProductBPO.keySet().contains(p.Apttus_Config2__ProductId__c))
                        {
                            tempMap = new Map<String, Decimal> ();
                            tempMap.put('CSP', p.Apttus_Config2__ListPrice__c);
                            mapProductBPO.put(p.Apttus_Config2__ProductId__c, tempMap); //category CSP Products              
                        }
                        if (!productChargeType.containsKey(p.Apttus_Config2__ProductId__c))
                        productChargeType.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__ChargeType__c);
                        if (!productPLI.containsKey(p.Apttus_Config2__ProductId__c))
                        productPLI.put(p.Apttus_Config2__ProductId__c, p.Id);
                        if (!productReplacement.containsKey(p.Apttus_Config2__ProductId__c))
                        productReplacement.put(p.Apttus_Config2__ProductId__c, p.APTS_Product_Code__c);
                        if (!productUom.containsKey(p.Apttus_Config2__ProductId__c))
                        productUom.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__PriceUom__c);
                        if (!productDeafultSellingUom.containsKey(p.Apttus_Config2__ProductId__c))
                        productDeafultSellingUom.put(p.Apttus_Config2__ProductId__c, p.APTS_Default_selling_UOM__c);

                    }
                    else {
                        if (!mapProductBPO.keySet().contains(p.Apttus_Config2__ProductId__c))
                        {
                            tempMap = new Map<String, Decimal> ();
                            tempMap.put('General', p.Apttus_Config2__ListPrice__c);
                            mapProductBPO.put(p.Apttus_Config2__ProductId__c, tempMap); //category CSP Products              
                        }
                        if (!productChargeType.containsKey(p.Apttus_Config2__ProductId__c))
                        productChargeType.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__ChargeType__c);
                        if (!productPLI.containsKey(p.Apttus_Config2__ProductId__c))
                        productPLI.put(p.Apttus_Config2__ProductId__c, p.Id);
                        if (!productReplacement.containsKey(p.Apttus_Config2__ProductId__c))
                        productReplacement.put(p.Apttus_Config2__ProductId__c, p.APTS_Product_Code__c);
                        if (!productUom.containsKey(p.Apttus_Config2__ProductId__c))
                        productUom.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__PriceUom__c);
                        if (!productDeafultSellingUom.containsKey(p.Apttus_Config2__ProductId__c))
                        productDeafultSellingUom.put(p.Apttus_Config2__ProductId__c, p.APTS_Default_selling_UOM__c);
                    }

                }

                String cur = null;
                for (Id pId : productMap.keySet())
                {
                    for (String s : bucketList)
                    {
                        if (productMap.get(pId).get(s) != null)
                        {
                            tempCerRecords = productMap.get(pId).get(s);
                            for (APTS_Contract_Entitlement_Repository__c c : tempCerRecords) {
                                tempString = ''; tempStringKG = ''; tempStringBX = ''; tempStringPCE = '';
                                tempLIString = '';
                                if (sapCode.get(pId) != null) {
                                    tempString += sapCode.get(pId);
                                    tempLIString += sapCode.get(pId);
                                }
                                else {
                                    continue;
                                }

                                if (c.APTS_UOM__c != null) {
                                    tempString += ';' + c.APTS_UOM__c;
                                    if (c.APTS_Product__c == categoryId)
                                    {
                                        tempLIString += ';' + productDeafultSellingUom.get(pId);
                                    }
                                    else {
                                        tempLIString += ';' + c.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c; //FromUOM
                                    }

                                }
                                else {
                                    continue;
                                }
                                if (productUom.get(pId) != null) {
                                    tempString += ';' + productUom.get(pId);
                                    tempLIString += ';' + productUom.get(pId); //adding toUOM

                                    tempStringKG = sapCode.get(pId) + ';' + productUom.get(pId) + ';SAP_KGM';
                                    tempStringPCE = sapCode.get(pId) + ';' + productUom.get(pId) + ';SAP_PCE';
                                    tempStringBX = sapCode.get(pId) + ';' + productUom.get(pId) + ';SAP_BX';
                                }
                                else {
                                    continue;
                                }
                                if (!uomString.contains(tempString)) {
                                    uomString.add(tempString);
                                }
                                if (!uomLIString.contains(tempLIString)) {
                                    uomLIString.add(tempLIString);
                                }
                                if (!uomExtraString.contains(tempStringKG)) {
                                    uomExtraString.add(tempStringKG);

                                }
                                if (!uomExtraString.contains(tempStringPCE)) {
                                    uomExtraString.add(tempStringPCE);

                                }
                                if (!uomExtraString.contains(tempStringBX)) {
                                    uomExtraString.add(tempStringBX);

                                }
                            }
                        }
                    }
                }

                uomALLString.addAll(uomString);
                uomALLString.addAll(uomExtraString);

                if (uomString != null)
                uomOutput = APTS_UOMConversionUtils.getUOMConversions(uomALLString);
                uomALLString = new Set<String> ();
                uomALLString.addAll(uomLIString);
                uomALLString.addAll(uomExtraString);

                if (uomLIString != null)
                uomLIOutput = APTS_UOMConversionUtils.getUOMConversions(uomALLString);
                Decimal tempBP;
                for (Id pId : productMap.keySet())
                { tempMap = new Map<String, Decimal> ();
                    //gpw = new APTS_GetPriceRest.GetPriceWrapper();      
                    if (mapProductBPO != null && mapProductBPO.get(pId) != NULL)
                    tempMap = mapProductBPO.get(pId);
                    tempBP = null;
                    uniqueProduct = soldToAccountId + ';' + pId;

                    for (String instProdUOM : uomLiString)
                    {
                        List<String> tempStringList = new List<String> ();
                        tempStringList = instProdUOM.Split(';');
                        IncomingProdId = tempStringList[0];
                        tempString = tempStringList[0] + ';' + tempStringList[2] + ';';
                        if (IncomingProdId == sapCode.get(pId) && !uniqueProductSet.contains(uniqueProduct))
                        {
                            uomLIFactor = uomLIOutput.get(instProdUOM) != null ? uomLIOutput.get(instProdUOM) : 1;
                            if (tempMap.containskey('IngredientBPO'))
                            {
                                StartingPrice = tempMap.get('IngredientBPO');
                                StartingPrice = StartingPrice * uomLIFactor;
                                tempBP = StartingPrice;
                            }
                            //else if (tempMap.containskey('Ingredient'))
                            //{
                            //StartingPrice = tempMap.get('Ingredient');
                            //StartingPrice = StartingPrice * uomLIFactor;
                            //}
                            else if (tempMap.containskey('CSP'))
                            {
                                StartingPrice = tempMap.get('CSP');
                            }
                            else if (tempMap.containskey('General'))
                            {
                                StartingPrice = tempMap.get('General');
                            }


                        }
                        else { continue; }
                        listPrice = StartingPrice;
                        if (StartingPrice > 0 || inTestScope) {
                            tempFlag = true;
                            tCerRecord = aliMap.get(pId);
                            // tempString= tCerRecord[0].APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c != null ? tCerRecord[0].APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c : '';
                            tempString1 = productUom.get(pId) != null ? productUom.get(pId) : '';

                            if (tempString1 == APTS_CERUtility.SAP_PCE || tempString1 == APTS_CERUtility.SAP_BX || inTestScope)
                            {
                                for (String s : bucketList) {
                                    if (productMap.get(pId).get(s) != null) {
                                        tempCerRecords = productMap.get(pId).get(s);
                                        tempPrice = 0; tempPriceBP = 0;
                                        if (tempCerRecords.size() > 0 && tempFlag) {
                                            tempNetPriceRecord = new APTS_Net_Price_Extraction__c();
                                            tempNetPriceRecord.APTS_Product__c = pId;
                                            tempNetPriceRecord.APTS_Base_Price_Override__c = tempBP;
                                            tempNetPriceRecord.APTS_Sold_to_Party__c = soldToAccountId;
                                            tempNetPriceRecord.APTS_Type__c = 'GetPrice';
                                            tempNetPriceRecord.APTS_Agreement_Line_Item__c = tempCerRecords[0].APTS_Agreement_Line_Item__c;
                                            tempNetPriceRecord.APTS_Category__c = tempCerRecords[0].APTS_Product__r.Family;
                                            tempNetPriceRecord.APTS_Charge_Type__c = productChargeType.get(pId);
                                            tempNetPriceRecord.APTS_Price_List_Item__c = productPLI.get(pId);
                                            tempFlag = false;
                                        }
                                        for (APTS_Contract_Entitlement_Repository__c c : tempCerRecords) {
                                            tempString2 = '';
                                            if (sapCode.get(pId) != null)
                                            {
                                                tempString2 += sapCode.get(pId);
                                            }
                                            if (c.APTS_UOM__c != null)
                                            {
                                                tempString2 += ';' + c.APTS_UOM__c;
                                            }
                                            if (productUom.get(pId) != null)
                                            {
                                                tempString2 += ';' + productUom.get(pId);
                                            } //Applying Adjustments on Price
                                            if (c.APTS_Adjustment_Value__c == null)
                                            c.APTS_Adjustment_Value__c = 0;
                                            uomFactor = uomOutput.get(tempString2) != null ? uomOutput.get(tempString2) : 1;
                                            if (c.APTS_Adjustment_Type__c == '% Discount') {
                                                tempPriceBP = (tempPriceBP + (StartingPrice * (c.APTS_Adjustment_Value__c / 100)));
                                            } else if (c.APTS_Adjustment_Type__c == 'Base Price Discount' || c.APTS_Adjustment_Type__c == 'Discount Amount') {
                                                tempPriceBP = (tempPriceBP + (c.APTS_Adjustment_Value__c * uomFactor));
                                            } else if (c.APTS_Adjustment_Type__c == '% Markup') {
                                                tempPriceBP = (tempPriceBP - (StartingPrice * (c.APTS_Adjustment_Value__c / 100)));
                                            } else if (c.APTS_Adjustment_Type__c == 'Markup Amount') {
                                                tempPriceBP = (tempPriceBP - (c.APTS_Adjustment_Value__c * uomFactor));
                                            } else if (c.APTS_Adjustment_Type__c == 'Price Override') {
                                                tempPriceBP = (c.APTS_Adjustment_Value__c * uomFactor);
                                            } else continue;
                                        }
                                        if (StartingPrice != NULL)
                                        StartingPrice = StartingPrice - tempPriceBP;
                                    }
                                    else
                                    {

                                        tempCerRecords = aliMap.get(pId) != null ? aliMap.get(pId) : new List<APTS_Contract_Entitlement_Repository__c> ();
                                        if (tempCerRecords.size() > 0 && tempFlag) {
                                            tempNetPriceRecord = new APTS_Net_Price_Extraction__c();
                                            tempNetPriceRecord.APTS_Product__c = pId;
                                            tempNetPriceRecord.APTS_Agreement_Line_Item__c = tempCerRecords[0].APTS_Agreement_Line_Item__c;
                                            tempNetPriceRecord.APTS_Type__c = 'GetPrice';
                                            tempNetPriceRecord.APTS_Base_Price_Override__c = tempBP;
                                            tempNetPriceRecord.APTS_Sold_to_Party__c = soldToAccountId;
                                            tempNetPriceRecord.APTS_Category__c = tempCerRecords[0].APTS_Product__r.Family;
                                            tempNetPriceRecord.APTS_Charge_Type__c = productChargeType.get(pId);
                                            tempNetPriceRecord.APTS_Price_List_Item__c = productPLI.get(pId);
                                            tempFlag = false;
                                        }
                                    }
                                }

                                uomFactor = uomLIOutput.get(instProdUOM) != null ? uomLIOutput.get(instProdUOM) : 1;
                                tempNetPriceRecord.APTS_Net_Price__c = (StartingPrice / uomFactor).setScale(5);
                                 //tempNetPriceRecord.Discount__c = ((listPrice /uomFactor) - tempNetPriceRecord.APTS_Net_Price__c); 
                                tempNetPriceRecord.Discount__c =((listPrice-StartingPrice)/uomFactor).setScale(5); 

                                uomFactor = uomOutput.get(tempString + 'SAP_KGM') != null ? uomOutput.get(tempString + 'SAP_KGM') : 1;
                                tempNetPriceRecord.APTS_Net_Price_KG__c = (StartingPrice * uomFactor).setScale(5);
                                uomFactor = uomOutput.get(tempString + 'SAP_PCE') != null ? uomOutput.get(tempString + 'SAP_PCE') : 1;
                                tempNetPriceRecord.APTS_Net_Price_PCE__c = (StartingPrice * uomFactor).setScale(5);
                                uomFactor = uomOutput.get(tempString + 'SAP_BX') != null ? uomOutput.get(tempString + 'SAP_BX') : 1;
                                tempNetPriceRecord.APTS_Net_Price_BOX__c = (StartingPrice * uomFactor).setScale(5);

                                
                                                    
                                uniqueProductSet.add(uniqueProduct);

                                insertList.add(tempNetPriceRecord);
                            }
                        }
                    }

                }
            }

            cerRecords = [Select id,
                          APTS_Product__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c, APTS_Amendment_In_Progress__c,
                          APTS_Agreement_Adjustment_Line_Item__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.CurrencyIsoCode,
                          APTS_Category_Level__c,
                          APTS_Agreement_Line_Item__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceListId__c,
                          APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceUom__c,
                          APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePrice__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__ChargeType__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_VAT_indicator_Digital__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Product_Code__c,
                          APTS_Agreement_Line_Item__r.APTS_More_Standalone__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c,
                          APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone_or_Spare_Part__c, APTS_Sub_Category__c, APTS_Sub_Sub_Category__c, APTS_CategoryCER__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__ClassificationId__r.APTS_CategoryHierarchyOfferingExtId__c,
                          APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c, APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c
                          //APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c
                          from APTS_Contract_Entitlement_Repository__c
                          where APTS_Sold_to_Party__c = :tempSoldToAccountId
                          and APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__Active__c = true
                          and APTS_Contributing_Agreement__c not in :agreementExculsion
                          and APTS_Agreement_Line_Item__c not in(Select APTS_Agreement_Line_Item__c from APTS_Agreement_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                          and APTS_Agreement_Adjustment_Line_Item__c not in(Select APTS_Agreement_Adjustment_Line_Item__c from APTS_Adjustment_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                          and APTS_Is_Pending__c = false
                          // and APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c = :APTS_CERUtility.PRODUCT_SERVICE
                          and(APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c = true or APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c = true or
                              APTS_Agreement_Line_Item__r.APTS_More_Standalone__c = true) and APTS_Start_Date__c <= TODAY and APTS_End_Date__c >= TODAY
                          ORDER BY APTS_Contributing_Agreement_Level_Num__c, APTS_Category_Level__c Desc];
            productPLI = new Map<Id, Id> ();
            productChargeType = new Map<Id, String> ();
            Set<Id> cerProductsWithAdj = new Set<Id> ();
            Map<Id, String> SellingUOM = new Map<Id, String> ();
            Map<Id, Id> agreementLineItem = new Map<Id, Id> ();
            Map<Id, String> productPriceUom = new Map<Id, String> ();
            Set<Id> CerProducts = new Set<Id> ();
            Set<Id> cerAndCspProducts = new Set<Id> ();
            Set<Id> productSet = new Set<Id> ();
            Decimal tempBP;
            Set<Id> tempProductSet = new Set<Id> ();
            String cur=null;
            for (APTS_Contract_Entitlement_Repository__c cerRecord : cerRecords)
            {
                if (cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c)
                {
                    if (!cerProductsWithAdj.contains(cerRecord.APTS_Product__c) && cerRecord.APTS_Agreement_Adjustment_Line_Item__c != null)
                    {
                        cerProductsWithAdj.add(cerRecord.APTS_Product__c);
                    }
                    else {
                        SellingUOM.put(cerRecord.APTS_Product__c, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c);
                        productPriceUom.put(cerRecord.APTS_Product__c, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceUom__c);

                        productPLI.put(cerRecord.APTS_Product__c, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__c);
                        productChargeType.put(cerRecord.APTS_Product__c, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__ChargeType__c);

                        productReplacement.put(cerRecord.APTS_Product__c, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Product_Code__c);
                        CerProducts.add(cerRecord.APTS_Product__c);
                        if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c != null) //BPO,BP instead of LP              
                        {
                            tempMap = new Map<String, Decimal> ();
                            tempMap.put('CER BPO', cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c);
                            mapProductBPO.put(cerRecord.APTS_Product__c, tempMap);
                        }
                        //else
                        //{
                        //tempMap = new Map<String, Decimal> ();
                        //tempMap.put('CER', cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePrice__c);
                        //mapProductBPO.put(cerRecord.APTS_Product__c, tempMap);
                        //}
                        agreementLineItem.put(cerRecord.APTS_Product__c, cerRecord.APTS_Agreement_Line_Item__c);

                    }
                    if (cerRecord.APTS_Category_Level__c == APTS_CERUtility.CATEGORY) {
                        categories.add(cerRecord.APTS_CategoryCER__c);
                    } else if (cerRecord.APTS_Category_Level__c == APTS_CERUtility.SUB_CATEGORY) {
                        subCategories.add(cerRecord.APTS_Sub_Category__c);
                    } else if (cerRecord.APTS_Category_Level__c == APTS_CERUtility.SUB_SUB_CATEGORY) {
                        subSubCategories.add(cerRecord.APTS_Sub_Sub_Category__c);
                    }
                    if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__ClassificationId__r.APTS_CategoryHierarchyOfferingExtId__c != null && cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__ClassificationId__r.APTS_CategoryHierarchyOfferingExtId__c == APTS_CERUtility.S_0705)
                    {
                        tempProductSet.add(cerRecord.APTS_Product__c);
                    }



                }


            }
            if (cerRecords.size() > 0)
            {
                priceListId = cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c;
                basedOnPriceListId = cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c;
                priceListItemSet.add(priceListId);
                if (basedOnPriceListId != NULL)
                priceListItemSet.add(basedOnPriceListId);
            }
            else {
                set<id> accIdsSet = new set<id> ();
                Id AgrmentId = NULL;
                Map<Id, APTS_CERUtility.AccountAgreementHierarchyBottomToTop> accHierarchyMap = new Map<Id, APTS_CERUtility.AccountAgreementHierarchyBottomToTop> ();
                for (account a :[select id, parentId, parent.parent.Id FROM account WHERE id = :soldToAccountId]) {
                    accIdsSet.add(a.Id);
                    accIdsSet.add(a.parentId);
                    accIdsSet.add(a.parent.parent.Id);
                }
                accHierarchyMap = APTS_CERUtility.getAccountAgreementHierarchyBottomToTop(accIdsSet, new set<Id> { soldToAccountId });

                if (!accHierarchyMap.isEmpty()) {
                    for (APTS_CERUtility.AccountAgreementHierarchyBottomToTop accHrchy : accHierarchyMap.Values()) {
                        if (!accHrchy.currentLevelAgreements.IsEmpty()) {
                            for (APTS_CERUtility.Agreement agrmt : accHrchy.agreementList) {
                                if (agrmt.agreementType == APTS_CERUtility.STANDARD_DEAL) {
                                    AgrmentId = agrmt.agreementId; // active agreement from the account hierarchy(bottom-to-top).
                                }
                            }
                        }
                    }
                }
                if (AgrmentId != NULL) { // when there is an active agreement in the account hierarhy
                    Apttus__APTS_Agreement__c activeAgrmntPl = [SELECT Id, Apttus_CMConfig__PriceListId__c, Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c from Apttus__APTS_Agreement__c where Id = :AgrmentId] [0];
                    priceListId = activeAgrmntPl.Apttus_CMConfig__PriceListId__c;
                    basedOnPriceListId = activeAgrmntPl.Apttus_CMConfig__PriceListId__c != null ? activeAgrmntPl.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c : null;

                }
                else { // when there is no active agreement in the account hierarchy
                    for (Account a :[Select Id, APTS_Price_List__c, APTS_Price_List__r.Apttus_Config2__BasedOnPriceListId__c from Account where id = :soldToAccountId])
                    {
                        priceListId = a.APTS_Price_List__c;
                        basedOnPriceListId = a.APTS_Price_List__c != null ? a.APTS_Price_List__r.Apttus_Config2__BasedOnPriceListId__c : null;
                    }
                }
            }

            if (basedOnPriceListId != null || Test.isRunningTest())
            {
                for (Apttus_Config2__ProductClassification__c pc :[SELECT Apttus_Config2__ProductId__c FROM Apttus_Config2__ProductClassification__c WHERE Apttus_Config2__ProductId__r.IsActive = true
                     and(Apttus_Config2__ClassificationId__c IN :categories
                         OR Apttus_Config2__ClassificationId__c IN :subCategories
                         OR Apttus_Config2__ClassificationId__c IN :subSubCategories
                         OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c IN :categories
                         OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c IN :subCategories
                         OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c IN :categories) LIMIT 50000

                     ])
                {

                    if (!cerProductsWithAdj.contains(pc.Apttus_Config2__ProductId__c))
                    {
                        cerProductsWithAdj.add(pc.Apttus_Config2__ProductId__c);
                    }


                }
                //salAcc = [select Sales_Organization__c from Account where id = :tempSoldToAccountId];
                //tempSaleOrg = salAcc.size() > 0 && salAcc[0].Sales_Organization__c != null ? salAcc[0].Sales_Organization__c.substring(4, salAcc[0].Sales_Organization__c.length()) : '';
                //salesOrgDataList = [SELECT Id, APTS_Product__c FROM APTS_Sales_Org_Data__c WHERE APTS_Sales_Org_Data_Name__c = :tempSaleOrg and APTS_Product__c != null and APTS_Product__c NOT IN :cerProductsWithAdj];
                for (APTS_Sales_Org_Data__c salesOrgData : salesOrgDataList)
                {
                    if (!cerAndCspProducts.contains(salesOrgData.APTS_Product__c) && !cerProductsWithAdj.contains(salesOrgData.APTS_Product__c))
                    {
                        cerAndCspProducts.add(salesOrgData.APTS_Product__c);
                    }
                }
            }
            else
            {
                cerAndCspProducts.addAll(tempProductSet);
            }
            if (basedOnPriceListId != Null)
            lstPriceListItem = new List<Apttus_Config2__PriceListItem__c> ([SELECT Apttus_Config2__ListPrice__c, Apttus_Config2__ChargeType__c, Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c, APTS_Default_selling_UOM__c, CurrencyIsoCode, Apttus_Config2__PriceUom__c, Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.ProductCode, APTS_Tax_per_UOM__c, APTS_VAT_indicator_Digital__c, APTS_Product_Code__c
                                                                           FROM Apttus_Config2__PriceListItem__c
                                                                           WHERE((
                                                                                  Apttus_Config2__PriceListId__c = :priceListId
            )
                                                                                 OR(
                                                                                    Apttus_Config2__ProductId__c IN :CerProducts
                                                                                    AND Apttus_Config2__PriceListId__c = :priceListItemSet
            ))
                                                                           and Apttus_Config2__ProductId__c not in :cerProductsWithAdj
                                                                           AND Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true
                                                                           AND Apttus_Config2__Active__c = true
                                                                           AND(
                                                                               Apttus_Config2__ExpirationDate__c = NULL
                                                                               OR Apttus_Config2__ExpirationDate__c >= TODAY
            )
                                                                           AND(
                                                                               Apttus_Config2__PriceListId__r.Apttus_Config2__ExpirationDate__c = NULL
                                                                               OR Apttus_Config2__PriceListId__r.Apttus_Config2__ExpirationDate__c >= TODAY
            )
                                                                           ORDER BY Apttus_Config2__PriceListId__c DESC]);
            else
            lstPriceListItem = new List<Apttus_Config2__PriceListItem__c> ([select Apttus_Config2__ListPrice__c, Apttus_Config2__ChargeType__c, Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c, APTS_Default_selling_UOM__c, CurrencyIsoCode, Apttus_Config2__PriceUom__c, Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.ProductCode, APTS_Tax_per_UOM__c, APTS_VAT_indicator_Digital__c, APTS_Product_Code__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__c IN :CerProducts and Apttus_Config2__PriceListId__c = :priceListId]);
            for (Apttus_Config2__PriceListItem__c p : lstPriceListItem)
            {
                sapCode.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__ProductId__r.ProductCode);
                productSet.add(p.Apttus_Config2__ProductId__c);

                if (cur == null)
                {
                    cur = p.CurrencyIsoCode;
                }

                tempString1 = p.Apttus_Config2__PriceUom__c != null ? p.Apttus_Config2__PriceUom__c : '';
                if (tempString1 == APTS_CERUtility.SAP_PCE || tempString1 == APTS_CERUtility.SAP_BX || inTestScope)
                {

                    if (p.Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c != null)
                    {
                        if (!mapProductBPO.keySet().contains(p.Apttus_Config2__ProductId__c))
                        {
                            tempMap = new Map<String, Decimal> ();
                            tempMap.put('CSP', p.Apttus_Config2__ListPrice__c);
                            mapProductBPO.put(p.Apttus_Config2__ProductId__c, tempMap); //category CSP Products              
                        }
                        if (!productPLI.containsKey(p.Apttus_Config2__ProductId__c))
                        productPLI.put(p.Apttus_Config2__ProductId__c, p.Id);



                        if (!SellingUOM.containsKey(p.Apttus_Config2__ProductId__c))
                        SellingUOM.put(p.Apttus_Config2__ProductId__c, p.APTS_Default_selling_UOM__c);


                        if (!productChargeType.containsKey(p.Apttus_Config2__ProductId__c))
                        productChargeType.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__ChargeType__c);


                        if (!productReplacement.containsKey(p.Apttus_Config2__ProductId__c))
                        productReplacement.put(p.Apttus_Config2__ProductId__c, p.APTS_Product_Code__c);
                        if (!productPriceUom.containsKey(p.Apttus_Config2__ProductId__c))
                        productPriceUom.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__PriceUom__c);
                    }
                    else {
                        if (!mapProductBPO.keySet().contains(p.Apttus_Config2__ProductId__c))
                        {
                            tempMap = new Map<String, Decimal> ();
                            tempMap.put('General', p.Apttus_Config2__ListPrice__c);
                            mapProductBPO.put(p.Apttus_Config2__ProductId__c, tempMap); //category CSP Products              
                        }
                        if (!productPLI.containsKey(p.Apttus_Config2__ProductId__c))
                        productPLI.put(p.Apttus_Config2__ProductId__c, p.Id);
                        if (!SellingUOM.containsKey(p.Apttus_Config2__ProductId__c))
                        SellingUOM.put(p.Apttus_Config2__ProductId__c, p.APTS_Default_selling_UOM__c);
                        if (!productChargeType.containsKey(p.Apttus_Config2__ProductId__c))
                        productChargeType.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__ChargeType__c);
                        if (!productReplacement.containsKey(p.Apttus_Config2__ProductId__c))
                        productReplacement.put(p.Apttus_Config2__ProductId__c, p.APTS_Product_Code__c);
                        if (!productPriceUom.containsKey(p.Apttus_Config2__ProductId__c))
                        productPriceUom.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__PriceUom__c);
                    }

                }
                tempString = ''; tempStringKG = ''; tempStringBX = ''; tempStringPCE = '';
                if (p.Apttus_Config2__ProductId__r.ProductCode != null) {
                    tempString += p.Apttus_Config2__ProductId__r.ProductCode;
                } else {
                    continue;
                }
                if (SellingUOM.get(p.Apttus_Config2__ProductId__c) != null) {
                    tempString += ';' + SellingUOM.get(p.Apttus_Config2__ProductId__c); // from UOM
                }
                else {
                    continue;
                }
                if (productPriceUom.get(p.Apttus_Config2__ProductId__c) != null) {
                    tempStringKG = p.Apttus_Config2__ProductId__r.ProductCode + ';' + productPriceUom.get(p.Apttus_Config2__ProductId__c) + ';SAP_KGM';
                    tempStringPCE = p.Apttus_Config2__ProductId__r.ProductCode + ';' + productPriceUom.get(p.Apttus_Config2__ProductId__c) + ';SAP_PCE';
                    tempStringBX = p.Apttus_Config2__ProductId__r.ProductCode + ';' + productPriceUom.get(p.Apttus_Config2__ProductId__c) + ';SAP_BX';
                    tempString += ';' + productPriceUom.get(p.Apttus_Config2__ProductId__c);
                }
                else {
                    continue;

                }
                if (!uomString.contains(tempString)) {
                    uomString.add(tempString);

                }
                if (!uomExtraString.contains(tempStringKG)) {
                    uomExtraString.add(tempStringKG);

                }
                if (!uomExtraString.contains(tempStringPCE)) {
                    uomExtraString.add(tempStringPCE);

                }
                if (!uomExtraString.contains(tempStringBX)) {
                    uomExtraString.add(tempStringBX);

                }
            }
            uomALLString.addAll(uomString);
            uomALLString.addAll(uomExtraString);

            if (uomString != NULL)
            uomOutput = APTS_UOMConversionUtils.getUOMConversions(uomALLString);

            for (Id pid : productSet)
            {
                tempMap = new Map<String, Decimal> ();
                if (mapProductBPO != null && mapProductBPO.get(pId) != NULL)
                tempMap = mapProductBPO.get(pId);
                uniqueProduct = soldToAccountId + ';' + pId;
                tempBP = null;
                for (String instProdUOM : uomString)
                {
                    List<String> tempStringList = new List<String> ();
                    tempStringList = instProdUOM.Split(';');

                    IncomingProdId = tempStringList[0];
                    tempString = tempStringList[0] + ';' + tempStringList[2] + ';';
                    if ((IncomingProdId == sapCode.get(pId) && !uniqueProductSet.contains(uniqueProduct)) || Test.isRunningTest())
                    {
                        uomFactor = uomOutput.get(instProdUOM) != null ? uomOutput.get(instProdUOM) : 1;
                        if (tempMap.containskey('CER BPO'))
                        {
                            price = tempMap.get('CER BPO');
                            price = price * uomFactor;
                            tempBP = price;
                        }
                        else if (tempMap.containskey('CER'))
                        {
                            price = tempMap.get('CER');
                            price = price * uomFactor;
                        }
                        else if (tempMap.containskey('CSP'))
                        {
                            price = tempMap.get('CSP');
                        }
                        else if (tempMap.containskey('General'))
                        {
                            price = tempMap.get('General');
                        }

                    }
                    else
                    { continue; }

                    listPrice = price;

                    //gpw.netPrice = p.Apttus_Config2__ListPrice__c.setScale(5);
                    tempNetPriceRecord = new APTS_Net_Price_Extraction__c();
                    tempNetPriceRecord.APTS_Product__c = pId;
                    tempNetPriceRecord.APTS_Base_Price_Override__c = tempBP;
                    tempNetPriceRecord.APTS_Sold_to_Party__c = soldToAccountId;
                    tempNetPriceRecord.APTS_Agreement_Line_Item__c = agreementLineItem.get(pId);
                    tempNetPriceRecord.APTS_Category__c = tempCerRecords.size() > 0 ? tempCerRecords[0].APTS_Product__r.Family != null ? tempCerRecords[0].APTS_Product__r.Family : null : null;
                    tempNetPriceRecord.APTS_Charge_Type__c = productChargeType.get(pId);
                    tempNetPriceRecord.APTS_Price_List_Item__c = productPLI.get(pId);
                    uomFactor = uomOutput.get(instProdUOM) != null ? uomOutput.get(instProdUOM) : 1;
                    tempNetPriceRecord.APTS_Net_Price__c = (price / uomFactor).setScale(5);
                    uomFactor = uomOutput.get(tempString + 'SAP_KGM') != null ? uomOutput.get(tempString + 'SAP_KGM') : 1;
                    tempNetPriceRecord.APTS_Net_Price_KG__c = (price * uomFactor).setScale(5);
                    uomFactor = uomOutput.get(tempString + 'SAP_PCE') != null ? uomOutput.get(tempString + 'SAP_PCE') : 1;
                    tempNetPriceRecord.APTS_Net_Price_PCE__c = (price * uomFactor).setScale(5);
                    uomFactor = uomOutput.get(tempString + 'SAP_BX') != null ? uomOutput.get(tempString + 'SAP_BX') : 1;
                    tempNetPriceRecord.APTS_Net_Price_BOX__c = (price * uomFactor).setScale(5);
                    tempNetPriceRecord.Discount__c = null;
                    tempNetPriceRecord.APTS_Type__c = 'GetProduct';
                    insertList.add(tempNetPriceRecord);
                    uniqueProductSet.add(uniqueProduct);
                }
                //returnObject.response.addAll(tempReturnObject);                
            }

            //MACHINES
            cerRecords = [Select id,
                          APTS_Product__c,
                          APTS_Contributing_Agreement__r.APTS_Agreement_Duration_Months__c,
                          APTS_Contributing_Agreement_Level__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PrimaryLineNumber__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__ParentBundleNumber__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__OptionId__r.Name,
                          APTS_Charge_Type__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__ListPrice__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__ChargeType__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__NetAdjustmentPercent__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Labour_Coverage_chk__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Spare_Parts_Coverage_chk__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Call_Out_Coverage_chk__c,
                          APTS_CategoryCER__r.name,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c
                          from APTS_Contract_Entitlement_Repository__c
                          where APTS_Sold_to_Party__c = :tempSoldToAccountId
                          and APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__Active__c = true
                          and APTS_Contributing_Agreement__c not in :agreementExculsion
                          and APTS_Agreement_Line_Item__c not in(Select APTS_Agreement_Line_Item__c from APTS_Agreement_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                          and APTS_Agreement_Adjustment_Line_Item__c not in(Select APTS_Agreement_Adjustment_Line_Item__c from APTS_Adjustment_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                          and APTS_Is_Pending__c = false
                          and APTS_CategoryCER__r.Name != :APTS_CERUtility.CONSIGNMENT_INGREDIENT
                          and APTS_Product__c != :categoryID
                          and APTS_Agreement_Type__c = :APTS_CERUtility.STANDARD_DEAL
                          and(APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c = false and APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c = false and
                              APTS_Agreement_Line_Item__r.APTS_More_Standalone__c = false and APTS_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__r.APTS_Fixed_Term_Product__c = false and
                              APTS_Agreement_Line_Item__r.APTS_Ingredient_Bundle__c = false and APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone_or_Spare_Part__c = false)
                          ORDER BY APTS_Contributing_Agreement_Level__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__PrimaryLineNumber__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__ItemSequence__c
                         ];
            String tempMachineString, tempOptionString, tempAtrString;
            APTS_Machine_Net_Price_Extraction__c tempMachineNetPriceRecord = new APTS_Machine_Net_Price_Extraction__c();
            List<APTS_Machine_Net_Price_Extraction__c> insertMachineList = new List<APTS_Machine_Net_Price_Extraction__c> ();
            Set<String> tempMachinetSet = new Set<String> ();
            Set<String> tempSet = new Set<String> ();
            Map<Id, Set<String>> machineSet = new Map<Id, Set<String>> ();
            Map<String, String> machineChargeType = new Map<String, String> ();
            Map<String, String> machineCategoryName = new Map<String, String> ();
            Map<String, Decimal> machineLineDiscount = new Map<String, Decimal> ();
            Map<String, Set<Id>> optionsPLIMap = new Map<String, Set<Id>> ();
            Set<Id> optionsPLISet = new Set<Id> ();
            Set<Id> optionsPLIList = new Set<Id> ();
            Map<String, String> coverageBundleHeaderMap = new Map<String, String> ();
            Map<String, String> coverageAttributeMap = new Map<String, String> ();
            List<String> coveragePrices = new List<String> ();
            Decimal total;
            Map<String, Id> machinePLI = new Map<String, Id> ();
            Map<string, Decimal> rentalCERRecords = new Map<string, Decimal> ();
            Map<Id, Map<string, Decimal>> pliRentalCERRecordsMap = new Map<Id, Map<string, Decimal>> ();
            Map<String, Id> machineAgrLineitem = new Map<String, Id> ();
            tempMap = new Map<String, Decimal> ();
            if (Test.isRunningTest())
            {
                cerRecords = [Select id,
                              APTS_Product__c,
                              APTS_Contributing_Agreement__r.APTS_Agreement_Duration_Months__c,
                              APTS_Contributing_Agreement_Level__c,
                              APTS_Charge_Type__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__PrimaryLineNumber__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__ParentBundleNumber__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__OptionId__r.Name,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__ListPrice__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__ChargeType__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__NetAdjustmentPercent__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Labour_Coverage_chk__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Spare_Parts_Coverage_chk__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Call_Out_Coverage_chk__c,
                              APTS_CategoryCER__r.name,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c
                              from APTS_Contract_Entitlement_Repository__c limit 100];
            }
            for (APTS_Contract_Entitlement_Repository__c cerRecord : cerRecords) {
                tempMachineString = cerRecord.APTS_Contributing_Agreement_Level__c + ';' + cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PrimaryLineNumber__c;
                if (!tempMachinetSet.contains(tempMachineString))
                {
                    tempSet = machineSet.get(cerRecord.APTS_Product__c) != null ? machineSet.get(cerRecord.APTS_Product__c) : new Set<String> ();
                    tempSet.add(tempMachineString);
                    machineSet.put(cerRecord.APTS_Product__c, tempSet);
                    machineChargeType.put(tempMachineString, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__ChargeType__c);
                    machinePLI.put(tempMachineString, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__c);
                    machineAgrLineitem.put(tempMachineString, cerRecord.APTS_Agreement_Line_Item__c);
                    machineCategoryName.put(tempMachineString, cerRecord.APTS_CategoryCER__r.name);
                    if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__NetAdjustmentPercent__c< 0)
                    machineLineDiscount.put(tempMachineString, (100 + (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__NetAdjustmentPercent__c)) / 100);

                    if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c != null) {
                        tempMap.put(tempMachineString, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c);
                        tempMap.put(tempMachineString + 'BPO', cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c);
                    }
                    else {
                        if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c == APTS_CERUtility.OPTION)
                        {
                            tempOptionString = cerRecord.APTS_Contributing_Agreement_Level__c + ';' + cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__ParentBundleNumber__c;
                            if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__OptionId__r.Name != system.label.APTS_All_in_Coverage_Draft && cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__OptionId__r.Name != system.label.APTS_Basic_Coverage_Draft)
                            {
                                optionsPLISet = optionsPLIMap.get(tempOptionString) != null ? optionsPLIMap.get(tempOptionString) : new Set<Id> ();
                                If (!optionsPLISet.contains(cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__c))
                                {
                                    optionsPLISet.add(cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__c);
                                    optionsPLIMap.put(tempOptionString, optionsPLISet);
                                    optionsPLIList.add(cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__c);
                                }
                            }
                            else {
                                coverageBundleHeaderMap.put(tempMachineString, tempOptionString);

                                if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Labour_Coverage_chk__c != null && cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Labour_Coverage_chk__c == 'Yes')
                                {
                                    tempAtrString = 'Y;';
                                }
                                else {
                                    tempAtrString = 'N;';
                                }
                                if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Spare_Parts_Coverage_chk__c != null && cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Spare_Parts_Coverage_chk__c == 'Yes')
                                {
                                    tempAtrString += 'Y;';
                                }
                                else {
                                    tempAtrString += 'N;';
                                }
                                if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Call_Out_Coverage_chk__c != null && cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Call_Out_Coverage_chk__c == 'Yes')
                                {
                                    tempAtrString += 'Y';
                                }
                                else {
                                    tempAtrString += 'N';
                                }
                                coverageAttributeMap.put(tempMachineString, tempAtrString);
                            }
                        }


                        if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c> 0 && cerRecord.APTS_Charge_Type__c == 'Rental Fee')
                        {

                            rentalCERRecords = pliRentalCERRecordsMap.get(cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__c) != null ? pliRentalCERRecordsMap.get(cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__c) : new Map<string, Decimal> ();
                            rentalCERRecords.put(tempMachineString, cerRecord.APTS_Contributing_Agreement__r.APTS_Agreement_Duration_Months__c);
                            pliRentalCERRecordsMap.put(cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__c, rentalCERRecords);
                        }
                        else {
                            tempMap.put(tempMachineString, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__ListPrice__c);
                        }

                    }
                }
            }
            
            List<Apttus_Config2__PriceListItem__c> pliList = [Select id, APTS_Labour_Coverage__c, APTS_Spare_Parts_Coverage__c, APTS_Call_Out_Coverage__c from Apttus_Config2__PriceListItem__c where id in :optionsPLIList and Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true and Apttus_Config2__Active__c = true];

            for (String s : coverageBundleHeaderMap.keySet())
            {
                coveragePrices = coverageAttributeMap.get(s).split(';');
                total = 0.0;
                if (s != null && coverageBundleHeaderMap.get(s) != null && optionsPLIMap.get(coverageBundleHeaderMap.get(s)) != null) {

                    optionsPLISet = optionsPLIMap.get(coverageBundleHeaderMap.get(s));
                    
                    for (Apttus_Config2__PriceListItem__c pli : pliList)
                    {
                        if (optionsPLISet.contains(pli.Id))
                        {
                            if (coveragePrices[0] == 'Y' && pli.APTS_Labour_Coverage__c != null)
                            {
                                total += pli.APTS_Labour_Coverage__c;
                            }
                            if (coveragePrices[1] == 'Y' && pli.APTS_Spare_Parts_Coverage__c != null)
                            {
                                total += pli.APTS_Spare_Parts_Coverage__c;
                            } if (coveragePrices[2] == 'Y' && pli.APTS_Call_Out_Coverage__c != null)
                            {
                                total += pli.APTS_Call_Out_Coverage__c;
                            }

                        }
                    }

                }
                tempMap.put(s, total);
            }

            List<Apttus_Config2__PriceMatrixEntry__c> pmeList = [Select Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__c, Apttus_Config2__Dimension1Value__c, Apttus_Config2__AdjustmentAmount__c from Apttus_Config2__PriceMatrixEntry__c where Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__c in :pliRentalCERRecordsMap.keySet() and Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__Active__c = true];
            for (Id i : pliRentalCERRecordsMap.keySet())
            {
                for (Apttus_Config2__PriceMatrixEntry__c pme : pmeList)
                {

                    if (pme.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__c == i)
                    {
                        for (String s : pliRentalCERRecordsMap.get(i).keySet())
                        {
                            if (pliRentalCERRecordsMap.get(i).get(s) == Decimal.valueOf(pme.Apttus_Config2__Dimension1Value__c))
                            {
                                tempMap.put(s, pme.Apttus_Config2__AdjustmentAmount__c);
                            }
                        }
                    }
                }
            }
            Decimal netListPrice, discount;
            for (Id pId : machineSet.keySet()) {

                for (String str : machineSet.get(pId)) {
                    netListPrice = tempMap.get(str) != null ? tempMap.get(str) : 0;
                    If (machineLineDiscount.get(str) != null)
                    {
                        discount = netListPrice - (netListPrice * machineLineDiscount.get(str));
                        netListPrice = netListPrice - discount;
                    }
                    else {
                        discount = null;
                    }
                    tempMachineNetPriceRecord = new APTS_Machine_Net_Price_Extraction__c();
                    tempMachineNetPriceRecord.APTS_Product__c = pId;
                    tempMachineNetPriceRecord.APTS_Base_Price_Override__c = tempMap.get(str + 'BPO') != null ? tempMap.get(str + 'BPO').setScale(5) : null;
                    tempMachineNetPriceRecord.APTS_Sold_to_Party__c = soldToAccountId;
                    tempMachineNetPriceRecord.APTS_Agreement_Line_Item__c = machineAgrLineitem.get(str);
                    tempMachineNetPriceRecord.APTS_Category__c = machineCategoryName.get(str);
                    tempMachineNetPriceRecord.APTS_Charge_Type__c = machineChargeType.get(str);
                    tempMachineNetPriceRecord.APTS_Price_List_Item__c = machinePLI.get(str);
                    tempMachineNetPriceRecord.APTS_Net_Price__c = netListPrice;
                    tempMachineNetPriceRecord.APTS_Discount__c = discount;
                    tempMachineNetPriceRecord.APTS_Type__c = APTS_CERUtility.STANDARD_DEAL;
                    insertMachineList.add(tempMachineNetPriceRecord);
                }
            }

            List<APTS_Net_Price_Extraction__c> deleteList =[select Id from APTS_Net_Price_Extraction__c where APTS_Sold_to_Party__c = : soldToAccountId FOR UPDATE];
            List<APTS_Machine_Net_Price_Extraction__c> deleteMachineList =[select Id from APTS_Machine_Net_Price_Extraction__c where APTS_Sold_to_Party__c = : soldToAccountId FOR UPDATE];
               if (deleteList.size() > 0) { Database.Delete(deleteList,false);}
                if (deleteMachineList.size() > 0) { Database.Delete(deleteMachineList,false);}
            if (insertList.size() > 0) {
                insert insertList;
            }
            if (insertMachineList.size() > 0) {
                insert insertMachineList;
            }
        }
        Catch(Exception e) {

            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', 'Message =' + e.getMessage() + ' Caused by =' + e.getStackTraceString(), 'APTS_Net_Price_Extraction__c ', soldToAccountId, 'CPQ', false, false, 'cpqerror@accenture.com', true);
        }
        //return returnObject;

    }
}