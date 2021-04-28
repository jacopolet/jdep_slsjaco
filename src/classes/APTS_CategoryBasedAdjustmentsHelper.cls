/*************************************************************
@Name: APTS_CategoryBasedAdjustmentsHelper
@Author: Raul Orozco
@CreateDate: 03-27-2018
@Description: Helper class for APTS_CategoryBasedAdjustments Vf Page. 
@UsedBy: APTS_CategoryBasedAdjustmentsCtrl
******************************************************************/
public with sharing class APTS_CategoryBasedAdjustmentsHelper {
    public static final String CATEGORY = 'Category';
    public static final String SUB_CATEGORY = 'Sub Category';
    public static final String SUB_SUB_CATEGORY = 'Sub Sub Category';
    
    public static List<APTS_Contract_Entitlement_Repository__c> getCategoryProducts(Id soldToAccountId, Id productId, String categoryLevel, Id category, Id subCategory, Id subSubCategory, Boolean allLevels) {
        Set<Id> agreementExculsion = new Set<Id> ();
        for (APTS_Agreement_Account_Exclusion__c aae :[Select APTS_Agreement__c from APTS_Agreement_Account_Exclusion__c where APTS_Account__c = :soldToAccountId])
        {
          if (!agreementExculsion.contains(aae.APTS_Agreement__c))
          agreementExculsion.add(aae.APTS_Agreement__c);
        }
        String query = 'SELECT Id, Name,'+ 
                        'APTS_Adjustment_Type__c,'+
                        'APTS_Adjustment_Value__c,'+
                        'APTS_Category_Level__c,'+ 
                        'APTS_Contributing_Agreement__c,'+
                        'APTS_Pricing_Sub_Type__c,'+ 
                        'APTS_Pricing_Type__c,'+ 
                        'APTS_Product__c,'+
                        'APTS_Sold_to_Party__c,'+ 
                        'APTS_Adjustment_Applies_To__c,'+
                        'APTS_Type__c,'+
                        'APTS_Sub_Type__c,'+
                        'APTS_Bucket__c,'+
                        'APTS_UOM__c,'+ 
                        'APTS_CategoryCER__c,'+
                        'APTS_CategoryCER__r.Name,'+ 
                        'APTS_Sub_Category__c,'+ 
                        'APTS_Sub_Sub_Category__c,'+ 
                        'APTS_Is_Pending__c, '+
                        'APTS_Contributing_Agreement_Level__c, '+
                        'APTS_Contributing_Agreement__r.Apttus__FF_Agreement_Number__c, '+
                        'APTS_Start_Date__c, '+
                        'APTS_End_Date__c, '+
                        'APTS_Category_Discount_Amendment__c, '+
                        'APTS_CER_from_Parent__c, '+
                        'APTS_CER_Changed_Amendment__c '+
                        'FROM APTS_Contract_Entitlement_Repository__c '+ 
                        'WHERE APTS_Sold_to_Party__c = :soldToAccountId '+
                        'AND APTS_Product__c = :productId '+
                        'AND  APTS_Agreement_Line_Item__c not in(Select APTS_Agreement_Line_Item__c from APTS_Agreement_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId) '+
                        'AND APTS_Agreement_Adjustment_Line_Item__c not in(Select APTS_Agreement_Adjustment_Line_Item__c from APTS_Adjustment_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId) '+
                        'AND  APTS_Contributing_Agreement__c not in :agreementExculsion ';

        if(!allLevels){
            query += 'AND APTS_Category_Level__c = :categoryLevel ';
        }

        if(category !=null){
            query += 'AND APTS_CategoryCER__c = :category ';
        }else if(subCategory != null){
            query += 'AND APTS_Sub_Category__c = :subCategory ';
        }else if(subSubCategory != null){
            query += 'AND APTS_Sub_Sub_Category__c = :subSubCategory ';
        }

        system.debug(Logginglevel.ERROR,'param1:::::::::' + soldToAccountId);
        system.debug(Logginglevel.ERROR,'param2:::::::::' + productId);
        system.debug(Logginglevel.ERROR,'param3:::::::::' + categoryLevel);
        system.debug(Logginglevel.ERROR,'param4:::::::::' + category);
        system.debug(Logginglevel.ERROR,'param5:::::::::' + subCategory);
        system.debug(Logginglevel.ERROR,'param6:::::::::' + subSubCategory);
        system.debug(Logginglevel.ERROR,'cer query:::::::::' + query);

        List<APTS_Contract_Entitlement_Repository__c> cerList = Database.query(query);
        
        return cerList;
    }

        @future
    public static void calculateECDA(Id soldToAccountId,Id cartId)
        {
            
            Decimal contractTerm,tempDiscount,totalValue,averagePrice,price, tempPrice;
            List<Apttus_Config2__LineItem__c> updateList =new List<Apttus_Config2__LineItem__c>();
            string cls;
            Set<Id> lineItemSet =new Set<Id>();
            Set<String> classificationString =new Set<String>();
            Id agreementId;
            List<String> bucketList = new List<String> { 'Bucket 0','Bucket 1', 'Bucket 2', 'Bucket 3', 'Bucket 4', 'Bucket 5' };
            Map<Id, List<APTS_Contract_Entitlement_Repository__c>> lineItemMap = APTS_CERUtility.getCategoryProductsWithDiscounts(soldToAccountId,cartId,true);
            Map<String,APTS_AgreementTotalVolumeObligation__c> voMap=new Map<String,APTS_AgreementTotalVolumeObligation__c>();
            List<Apttus_Config2__LineItem__c> lineItemList=
                [Select id,APTS_AgreementId__c,APTS_Category_Level__c,Apttus_Config2__ClassificationId__c,
                        APTS_Sub_Category__c,APTS_Sub_Sub_Category__c,APTS_Expected_Category_Discount_Amount__c,
                        Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Contract_Terms__c,
                        Apttus_Config2__NetAdjustmentPercent__c 
                        from Apttus_Config2__LineItem__c where id in:lineItemMap.keySet()];
            agreementId=lineItemList.size()>0?lineItemList[0].APTS_AgreementId__c:null;
            contractTerm=lineItemList.size()>0?lineItemList[0].Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Contract_Terms__c:0.0;
            for(APTS_AgreementTotalVolumeObligation__c avc:[select APTS_Value__c,APTS_Average_Price__c,APTS_VolumeAssumption__c from APTS_AgreementTotalVolumeObligation__c where APTS_Agreement__c=:agreementId])
                    {
                        voMap.put(avc.APTS_Value__c,avc);
                    }
            if(Test.isRunningTest())
            {
                for(APTS_AgreementTotalVolumeObligation__c avc:[select APTS_Value__c,APTS_Average_Price__c,APTS_VolumeAssumption__c from APTS_AgreementTotalVolumeObligation__c limit 5])
                    {
                        voMap.put(avc.APTS_Value__c,avc);
                    }
            }
            for(Apttus_Config2__LineItem__c li:lineItemList)
                {
                    tempDiscount=1;
                    totalValue=0;
                    cls=li.APTS_Category_Level__c==CATEGORY?li.Apttus_Config2__ClassificationId__c:li.APTS_Category_Level__c==SUB_CATEGORY?li.APTS_Sub_Category__c:li.APTS_Sub_Sub_Category__c;
                    if(voMap.get(cls)==null)
                        {
                            continue;
                        }
                        if(voMap.get(cls).APTS_Average_Price__c>0){averagePrice=voMap.get(cls).APTS_Average_Price__c;}
                        else{averagePrice=1;}
                    
                    if(averagePrice>0){price=averagePrice;}else{price=1;}
                    //price=averagePrice;
                    //System.debug('********averagePrice****'+averagePrice);
                    //System.debug('price****'+price);
                    for(string s:bucketList){
tempPrice = 0;
for(APTS_Contract_Entitlement_Repository__c c:lineItemMap.get(li.Id)){if(c.APTS_Bucket__c!=s){continue;}if (c.APTS_Adjustment_Type__c == '% Discount'){tempPrice = (tempPrice + (price * (c.APTS_Adjustment_Value__c / 100)));}
else if (c.APTS_Adjustment_Type__c == 'Base Price Discount'){tempPrice = (tempPrice + c.APTS_Adjustment_Value__c);}else if (c.APTS_Adjustment_Type__c == '% Markup'){tempPrice = (tempPrice - (price * (c.APTS_Adjustment_Value__c / 100)));}
else if (c.APTS_Adjustment_Type__c == 'Markup Amount'){tempPrice = (tempPrice - c.APTS_Adjustment_Value__c);}else if (c.APTS_Adjustment_Type__c == 'Price Override'){tempPrice = c.APTS_Adjustment_Value__c;}else continue;}price = price - tempPrice;}
                    tempDiscount=(price/averagePrice);
                    System.debug('tempDiscount****'+tempDiscount);
                    if(tempDiscount==0)
                        {
                            continue;
                        }
                    totalValue=((averagePrice*voMap.get(cls).APTS_VolumeAssumption__c)/12)*contractTerm*tempDiscount;
                    li.APTS_Expected_Category_Discount_Amount__c=totalValue;
                    // Additions by Ariel Quesada to support defect 20039
                    system.debug(''+averagePrice*voMap.get(cls).APTS_VolumeAssumption__c);
                    if(averagePrice*voMap.get(cls).APTS_VolumeAssumption__c>0)
                    {li.Apttus_Config2__NetAdjustmentPercent__c = totalValue/(averagePrice*voMap.get(cls).APTS_VolumeAssumption__c);}
                    else{li.Apttus_Config2__NetAdjustmentPercent__c = totalValue/1;}
                    //li.APTS_Discount_per_Uom__c = totalValue/voMap.get(cls).APTS_VolumeAssumption__c;
                    
                    updateList.add(li);
                }
            update updateList;
            
        }

    public static Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> getAdjustmentsStructure (Id cartId, Id categoryProductId){
        Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapLIAdjustments = new Map<Id, List<Apttus_Config2__AdjustmentLineItem__c>>();
        List<Apttus_Config2__AdjustmentLineItem__c> lstPreviousUserAdjustments;
        Map<Id,Apttus_Config2__LineItem__c> mapCategoryProductLines = new Map<Id, Apttus_Config2__LineItem__c>();
        Boolean addAdjustment;
        Boolean levelFound;
        Map<ID, List<APTS_Contract_Entitlement_Repository__c>> cerprdmap = new Map<ID, List<APTS_Contract_Entitlement_Repository__c>>();
        Id soldToacctID=null;
        List<APTS_Contract_Entitlement_Repository__c> tempCerList =new  List<APTS_Contract_Entitlement_Repository__c>();
         List<Apttus_Config2__AdjustmentLineItem__c> tempAdjList=new List<Apttus_Config2__AdjustmentLineItem__c>();
        //Get all cart line items with its adjustments
        List<Apttus_Config2__LineItem__c> lstLI = 
        [
            SELECT Id,
            Apttus_Config2__ClassificationId__c,
            Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__c,
            APTS_Category_Level__c,
            APTS_Sub_Category__c,
            APTS_Sub_Sub_Category__c,
            Apttus_Config2__ProductId__c,
            (
                SELECT Id,
                Apttus_Config2__AdjustmentType__c,
                Apttus_Config2__AdjustmentAmount__c,
                Apttus_Config2__Bucket__c,
                Apttus_Config2__Type__c,
                Apttus_Config2__SubType__c,
                Apttus_Config2__AdjustmentAppliesTo__c,
                Apttus_Config2__LineItemId__c,
                Apttus_Config2__LineType__c,
                Apttus_Config2__AdjustmentUom__c,
                APTS_Category__c,
                APTS_Sub_Category__c,
                APTS_Sub_Sub_Category__c,
                APTS_Adjustment_Source__c,
                APTS_Start_Date__c,
                APTS_End_Date__c
                FROM Apttus_Config2__AdjustmentLineItems__r
            ),
            Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__c,
            Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c,
            Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c,
            Apttus_Config2__ClassificationId__r.Name,
            Apttus_Config2__PricingStatus__c
            FROM Apttus_Config2__LineItem__c
            WHERE Apttus_Config2__ConfigurationId__c = :cartId
            AND Apttus_Config2__LineType__c = 'Product/Service'
            AND Apttus_Config2__HasOptions__c = false
            ORDER BY APTS_Category_Level__c DESC
        ];
list<Apttus_Config2__LineItem__c> updateList=new  list<Apttus_Config2__LineItem__c>();
list<Id> updatecacheList=new  list<Id>();
list<CERDiscountCache__c> CacheDeletion=new list<CERDiscountCache__c>();

        //Isolate category products
        for(Apttus_Config2__LineItem__c currentLI : lstLI){
            updatecacheList.add(currentLI.Id);
        if(soldToacctID==null)
                {
                    soldToacctID=currentLI.Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__c;
                }
            if(currentLI.Apttus_Config2__ProductId__c == categoryProductId){
                mapCategoryProductLines.put(currentLI.Id, currentLI);
            }
            currentLI.Apttus_Config2__PricingStatus__c='Pending';
            updateList.add(currentLI);
        }
        update updateList;
CacheDeletion=[select id,Name__c,Sub_Type__c,Source__c from CERDiscountCache__c where Name__c IN:updatecacheList];
cerprdmap=APTS_CERUtility.getContractedProductsWithDiscounts(soldToacctID,cartId,true);
        if(!lstLI.isEmpty()){
            //Loop throug line items list
            for(Apttus_Config2__LineItem__c currentLI : lstLI){
                //Exclude category products and products already added to map
                if(currentLI.Apttus_Config2__ProductId__c != categoryProductId && !mapLIAdjustments.containsKey(currentLI.Id)){
                    //Re-add the existing adjustments to line item, otherwise those will be deleted by Apttus API
                    if(!currentLI.Apttus_Config2__AdjustmentLineItems__r.isEmpty()){
                        lstPreviousUserAdjustments = new List<Apttus_Config2__AdjustmentLineItem__c>();

                        for(Apttus_Config2__AdjustmentLineItem__c currentAdj : currentLI.Apttus_Config2__AdjustmentLineItems__r){
                            //Only add the adjustments created by the user, not the ones coming from category adjustments
                            System.debug(LoggingLevel.ERROR,'currentAdj.APTS_Category__c***'+currentAdj.APTS_Category__c);
                            if(currentAdj.APTS_Category__c == null&&currentAdj.APTS_Adjustment_Source__c=='Child'){
                                lstPreviousUserAdjustments.add(currentAdj);
                            }
                        }
                        System.debug(LoggingLevel.ERROR,'lstPreviousUserAdjustments***'+lstPreviousUserAdjustments);
                        if(!lstPreviousUserAdjustments.isEmpty()){
                            if(mapLIAdjustments.containsKey(currentLI.Id)){
                                mapLIAdjustments.get(currentLI.Id).addAll(lstPreviousUserAdjustments);
                            }else{
                                mapLIAdjustments.put(currentLI.Id,lstPreviousUserAdjustments);
                            }
                        }else{
                            //If the line item doesn't have any previous adjustments must added to the map.
                            //This way if at the end of the process no new adjustments are added, and empty list will be
                            //passed to the Apttus API and all adjustments will be cleared for the line item
                            mapLIAdjustments.put(currentLI.Id,new List<Apttus_Config2__AdjustmentLineItem__c>());
                        }
                    }
                
                    //This variable is used to control when the right level for adjustments is found, don't look in the next levels
                    levelFound = false;
                    //Loop through category products and get the adjustments that apply to the line item,
                    //depending of the category, sub category or sub sub category or the category product                   
                    /*for(Apttus_Config2__LineItem__c currentLICategoryProduct : mapCategoryProductLines.values()){
                        system.debug(LoggingLevel.ERROR,'current sub sub category product:::::'  + currentLICategoryProduct);
                        if(currentLICategoryProduct.APTS_Category_Level__c == 'Sub Sub Category' && !levelFound){
                            //Check that the category, sub category and sub sub category of the category product and line item is the same and also 
                            //that the category product has adjustments
                            if(currentLICategoryProduct.Apttus_Config2__ClassificationId__c == currentLI.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c &&
                                currentLICategoryProduct.APTS_Sub_Category__c == currentLI.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c &&
                                currentLICategoryProduct.APTS_Sub_Sub_Category__c == currentLI.Apttus_Config2__ClassificationId__c &&
                                (currentLICategoryProduct.Apttus_Config2__AdjustmentLineItems__r.size() != null && 
                                    currentLICategoryProduct.Apttus_Config2__AdjustmentLineItems__r.size() > 0)){
                                //If current line item has no adjustments add all category product adjustments                                  
                                if(currentLI.Apttus_Config2__AdjustmentLineItems__r == null || currentLI.Apttus_Config2__AdjustmentLineItems__r.isEmpty()){
                                    mapLIAdjustments.put(currentLI.Id,currentLICategoryProduct.Apttus_Config2__AdjustmentLineItems__r);
                                }else{
                                    //Loop through line item adjustments and category product adjustments, if same type/sub type
                                    //product adjustment prevails over category product adjustment
                                    for(Apttus_Config2__AdjustmentLineItem__c currentCPAdj : currentLICategoryProduct.Apttus_Config2__AdjustmentLineItems__r){
                                        //Set the value of variable to control if the current adjustment is added or not to the line item
                                        addAdjustment = true;
                                        for(Apttus_Config2__AdjustmentLineItem__c currentLIAdj : mapLIAdjustments.get(currentLI.Id)){
                                            //If type/sub type are equal, ignore this adjustment
                                            if(currentCPAdj.Apttus_Config2__Type__c == currentLIAdj.Apttus_Config2__Type__c &&
                                                currentCPAdj.Apttus_Config2__SubType__c == currentLIAdj.Apttus_Config2__SubType__c){
                                                addAdjustment = false;
                                                break;
                                            }
                                        }

                                        //If same type/sub type adjustment not found, add adjustment to current line item
                                        if(addAdjustment){
                                            if(mapLIAdjustments.containsKey(currentLI.Id)){
                                                mapLIAdjustments.get(currentLI.Id).add(currentCPAdj);
                                            }else{
                                                mapLIAdjustments.put(currentLI.Id,new List<Apttus_Config2__AdjustmentLineItem__c>{currentCPAdj});
                                            }                                               
                                        }
                                    }
                                }
                                levelFound = true;
                            }
                        }else if(currentLICategoryProduct.APTS_Category_Level__c == 'Sub Category' && !levelFound){
                            system.debug(LoggingLevel.ERROR,'current sub category product:::::'  + currentLICategoryProduct);
                            //Check that the category and sub category of the category product and line item is the same and also that the category product
                            //has adjustments                           
                            
                            if(currentLICategoryProduct.Apttus_Config2__ClassificationId__c == currentLI.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c &&
                                currentLICategoryProduct.APTS_Sub_Category__c == currentLI.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c &&
                                (currentLICategoryProduct.Apttus_Config2__AdjustmentLineItems__r.size() != null && 
                                    currentLICategoryProduct.Apttus_Config2__AdjustmentLineItems__r.size() > 0)){
                                //If current line item has no adjustments add all category product adjustments                                  
                                if(currentLI.Apttus_Config2__AdjustmentLineItems__r == null || currentLI.Apttus_Config2__AdjustmentLineItems__r.isEmpty()){
                                    mapLIAdjustments.put(currentLI.Id,currentLICategoryProduct.Apttus_Config2__AdjustmentLineItems__r);
                                    //Loop through line item adjustments and category product adjustments, if same type/sub type
                                    //product adjustment prevails over category product adjustment
                                    for(Apttus_Config2__AdjustmentLineItem__c currentCPAdj : currentLICategoryProduct.Apttus_Config2__AdjustmentLineItems__r){
                                        //Set the value of variable to control if the current adjustment is added or not to the line item
                                        addAdjustment = true;
                                        for(Apttus_Config2__AdjustmentLineItem__c currentLIAdj : mapLIAdjustments.get(currentLI.Id)){
                                            //If type/sub type are equal, ignore this adjustment
                                            if(currentCPAdj.Apttus_Config2__Type__c == currentLIAdj.Apttus_Config2__Type__c &&
                                                currentCPAdj.Apttus_Config2__SubType__c == currentLIAdj.Apttus_Config2__SubType__c){

                                                addAdjustment = false;
                                                break;
                                            }
                                        }

                                        //If same type/sub type adjustment not found, add adjustment to current line item
                                        if(addAdjustment){
                                            if(mapLIAdjustments.containsKey(currentLI.Id)){
                                                mapLIAdjustments.get(currentLI.Id).add(currentCPAdj);
                                            }else{
                                                mapLIAdjustments.put(currentLI.Id,new List<Apttus_Config2__AdjustmentLineItem__c>{currentCPAdj});
                                            }                                               
                                        }
                                    }
                                }
                                levelFound = true;
                            }
                        }if(currentLICategoryProduct.APTS_Category_Level__c == 'Category' && !levelFound){
                            system.debug(LoggingLevel.ERROR,'current category product:::::'  + currentLICategoryProduct);
                            //Check that the category of the category product and line item is the same and also that the category product
                            //has adjustments
                            system.debug(LoggingLevel.ERROR,'currentLICategoryProduct.Apttus_Config2__ClassificationId__c:::::'  + currentLICategoryProduct.Apttus_Config2__ClassificationId__c);
                            system.debug(LoggingLevel.ERROR,'currentLI.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c:::::'  + currentLI.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c);
                            if((currentLICategoryProduct.Apttus_Config2__ClassificationId__c == currentLI.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c ||
                                (currentLICategoryProduct.Apttus_Config2__ClassificationId__r.Name == 'Spare Parts' && currentLI.Apttus_Config2__ClassificationId__r.Name == 'Spare Parts')) &&
                                (currentLICategoryProduct.Apttus_Config2__AdjustmentLineItems__r.size() != null && 
                                    currentLICategoryProduct.Apttus_Config2__AdjustmentLineItems__r.size() > 0)){
                                //If current line item has no adjustments add all category product adjustments                                  
                                if(currentLI.Apttus_Config2__AdjustmentLineItems__r == null || currentLI.Apttus_Config2__AdjustmentLineItems__r.isEmpty()){
                                    mapLIAdjustments.put(currentLI.Id,currentLICategoryProduct.Apttus_Config2__AdjustmentLineItems__r);
                                }else{
                                    //Loop through line item adjustments and category product adjustments, if same type/sub type
                                    //product adjustment prevails over category product adjustment
                                    for(Apttus_Config2__AdjustmentLineItem__c currentCPAdj : currentLICategoryProduct.Apttus_Config2__AdjustmentLineItems__r){
                                        //Set the value of variable to control if the current adjustment is added or not to the line item
                                        addAdjustment = true;
                                        for(Apttus_Config2__AdjustmentLineItem__c currentLIAdj : mapLIAdjustments.get(currentLI.Id)){
                                            //If type/sub type are equal, ignore this adjustment, the user created adjustment prevails
                                            if(currentCPAdj.Apttus_Config2__Type__c == currentLIAdj.Apttus_Config2__Type__c &&
                                                currentCPAdj.Apttus_Config2__SubType__c == currentLIAdj.Apttus_Config2__SubType__c){
                                                addAdjustment = false;
                                                break;
                                            }
                                        }

                                        //If same type/sub type adjustment not found, add adjustment to current line item
                                        if(addAdjustment){
                                            if(mapLIAdjustments.containsKey(currentLI.Id)){
                                                mapLIAdjustments.get(currentLI.Id).add(currentCPAdj);
                                            }else{
                                                mapLIAdjustments.put(currentLI.Id,new List<Apttus_Config2__AdjustmentLineItem__c>{currentCPAdj});
                                            }                                               
                                        }
                                    }
                                }
                                levelFound = true;
                            }
                        }
                    }*/
                }
                
                 tempAdjList= mapLIAdjustments.get(currentLI.Id)!=null? mapLIAdjustments.get(currentLI.Id):new List<Apttus_Config2__AdjustmentLineItem__c>();
                tempCerList =cerprdmap.get(currentLI.Apttus_Config2__ProductId__c)!=null?cerprdmap.get(currentLI.Apttus_Config2__ProductId__c):new List<APTS_Contract_Entitlement_Repository__c>();
                List<Apttus_Config2__AdjustmentLineItem__c> tempListADLIfin;
                if(tempAdjList.size()>0&&tempCerList.size()>0 )
                    {
                        Integer lineNumber=1;
                       system.debug('********123******'+tempCerList);
                       system.debug('********12345******'+tempAdjList);
                        for (APTS_Contract_Entitlement_Repository__c ceradjustment : tempCerList ) 
                        {
                             boolean isValid=true;
                system.debug('********ceradjustment.APTS_CER_Changed_Amendment__c******'+ceradjustment.APTS_CER_Changed_Amendment__c);
                            if(ceradjustment.APTS_Amendment_In_Progress__c==false){
                                //continue;
                            system.debug('++FinalLineitemlist'+currentLI.Id);
                            system.debug('++FinalLineitemlist1111'+mapLIAdjustments);
                            for (Apttus_Config2__AdjustmentLineItem__c a:mapLIAdjustments.get(currentLI.Id)){
                                system.debug('++FinalLineitemlist'+currentLI.Id);
                                if((a.Apttus_Config2__Type__c==ceradjustment.APTS_Type__c && a.Apttus_Config2__SubType__c ==ceradjustment.APTS_Sub_Type__c&&a.APTS_Adjustment_Source__c==ceradjustment.APTS_Contributing_Agreement_Level__c)){
                                    isValid=false;
                                    break;
                                    }
                                    /*else if(a.Apttus_Config2__Type__c==ceradjustment.APTS_Type__c && a.Apttus_Config2__SubType__c ==ceradjustment.APTS_Sub_Type__c&&a.APTS_Adjustment_Source__c!=ceradjustment.APTS_Contributing_Agreement_Level__c){
                                        //mapLIAdjustments.remove(a.Apttus_Config2__LineItemId__c);
                                    }*/
                                }
                                String listnewlist;Map<String,String> validcheck=new map<String,string>();

                                for(CERDiscountCache__c c:CacheDeletion){
                                    validcheck.put(c.Name__c+c.Sub_Type__c+c.Source__c,c.Name__c);
                                    system.debug('+++++6'+validcheck);
                                }
                            //listnewlist=validcheck.get(currentLI.Id+ceradjustment.APTS_Sub_Type__c)!=null?validcheck.get(currentLI.Id+ceradjustment.APTS_Sub_Type__c):new List<String>();
                            system.debug('+++++77777'+currentLI.Id+ceradjustment.APTS_Sub_Type__c+ceradjustment.APTS_Contributing_Agreement_Level__c);
                            listnewlist=validcheck.get(currentLI.Id+ceradjustment.APTS_Sub_Type__c+ceradjustment.APTS_Contributing_Agreement_Level__c);
                            system.debug('+++++7'+listnewlist);
                            system.debug('********listnewlist******'+listnewlist);
                            system.debug('********isValid******'+isValid);
                              //  ID prdID = PRODUCT_SERVICE.equalsIgnoreCase(lineItem.Apttus_Config2__LineType__c) ? lineItem.Apttus_Config2__ProductId__c : lineItem.Apttus_Config2__OptionId__c;
                                if(isValid&&listnewlist==null){
                                Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
                                adjustmentLineItem.Apttus_Config2__LineItemId__c = currentLI.Id;
                                adjustmentLineItem.Apttus_Config2__LineNumber__c = lineNumber++;
                                adjustmentLineItem.Apttus_Config2__AdjustmentType__c = ceradjustment.APTS_Adjustment_Type__c;
                                adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = ceradjustment.APTS_Adjustment_Value__c;
                                adjustmentLineItem.Apttus_Config2__IsModifiable__c = TRUE;
                                adjustmentLineItem.Apttus_Config2__Type__c = ceradjustment.APTS_Type__c;
                                adjustmentLineItem.APTS_Discount_Type__c= 'Auto';
                                adjustmentLineItem.Apttus_Config2__SubType__c = ceradjustment.APTS_Sub_Type__c;
                                adjustmentLineItem.Apttus_Config2_SellingUom__c = ceradjustment.APTS_UOM__c;
                                adjustmentLineItem.APTS_Adjustment_Source__c = ceradjustment.APTS_Contributing_Agreement_Level__c;
                                if(ceradjustment.APTS_Product__c!=currentLI.Apttus_Config2__ProductId__c){
                                adjustmentLineItem.APTS_Category__c = ceradjustment.APTS_CategoryCER__c;
                                adjustmentLineItem.APTS_Sub_Category__c = ceradjustment.APTS_Sub_Category__c;
                                adjustmentLineItem.APTS_Sub_Sub_Category__c = ceradjustment.APTS_Sub_Sub_Category__c;}
                                adjustmentLineItem.Apttus_Config2__AdjustmentUom__c = ceradjustment.APTS_UOM__c;
                                tempAdjList.add(adjustmentLineItem);
                                tempListADLIfin = APTS_DiscountBucketizing.processAdjustmentLineItemfields(tempAdjList);

                               }
                           }

                            }
                            tempListADLIfin = APTS_DiscountBucketizing.processAdjustmentLineItemfields(tempAdjList);
                          mapLIAdjustments.put(currentLI.Id,tempListADLIfin);  
                    }
            }
        }
        System.debug(LoggingLevel.ERROR,'Venki****'+mapLIAdjustments);
        //Return results
            /*List<Apttus_Config2__AdjustmentLineItem__c> tempListADLIfin; 
            Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapNewCategoryAdjustmentsfinal=new Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>();
            for(Id lineItemId : mapLIAdjustments.keySet()){
                tempListADLIfin = APTS_DiscountBucketizing.processAdjustmentLineItemfields(mapLIAdjustments.get(lineItemId));
                System.debug(LoggingLevel.ERROR,'shahultempListADLIfin****'+tempListADLIfin);
                mapNewCategoryAdjustmentsfinal.put(lineItemId,tempListADLIfin);
             }
             System.debug(LoggingLevel.ERROR,'shahul****'+mapNewCategoryAdjustmentsfinal);*/

        return mapLIAdjustments;
    }

    public static Boolean createNewAdjustments(Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapNewCategoryAdjustments, Id cartId){
        //Create structure required for API call
        Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO request = new  Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO();
        request.CartId = cartId;
        List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO> adjItemColls = new List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO>();
        Apttus_CPQApi.CPQ.AdjustmentItemCollDO adjItemColl;
        string limitstring = '';
        List<Apttus_Config2__AdjustmentLineItem__c> tempListADLI; 
        Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapNewCategoryAdjustmentsfinal1=new Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>();
        //Loop through adjustments structure to add line item id and adjustments list to request
        for(Id lineItemId : mapNewCategoryAdjustments.keySet()){
            system.debug(LoggingLevel.ERROR,'Initial list:::::::::' + mapNewCategoryAdjustments.get(lineItemId));
            //Change required by Shahul to solve issue with bucketizing logic
            tempListADLI = APTS_DiscountBucketizing.processAdjustmentLineItemfields(mapNewCategoryAdjustments.get(lineItemId));
            mapNewCategoryAdjustmentsfinal1.put(lineItemId,tempListADLI);
            system.debug(LoggingLevel.ERROR,'Bucketizing method response::::::::::' + tempListADLI);

            adjItemColl = new  Apttus_CPQApi.CPQ.AdjustmentItemCollDO();    
            adjItemColl.LineItemId = lineItemId;
            adjItemColl.AdjustmentItems = tempListADLI;
            //adjItemColl.AdjustmentItems = APTS_DiscountBucketizing.processAdjustmentLineItemfields(mapNewCategoryAdjustmentsfinal1.get(lineItemId));
            adjItemColls.add(adjItemColl);
        }
        
        //Add adjustments list to request
        request.AdjustmentItemColls = adjItemColls;
        System.debug('request.AdjustmentItemColls::::::::'+request.AdjustmentItemColls);

        //Validate salesforce limits before call
        limitstring += 'Query Limits: '+ Limits.getQueries() + '/' + Limits.getLimitQueries() +'\n';
        limitstring += 'DML Rows Limits: '+Limits.getDMLRows()+'/' + Limits.getLimitDMLRows()+'\n';
        limitstring += 'Heap Size Limits: '+Limits.getHeapSize()+'/' +Limits.getLimitHeapSize()+'\n';
        limitstring += 'Query Return Limits: '+Limits.getQueryRows()+'/' + Limits.getLimitQueryRows()+'\n';      
        limitstring += 'Aggregate Queries: '+Limits.getAggregateQueries()+'/' + Limits.getLimitAggregateQueries();
        limitstring += 'Callouts: '+Limits.getCallouts()+'/' +Limits.getLimitCallouts();    
        limitstring += 'CPU Time: '+Limits.getCpuTime()+'/' +Limits.getLimitCpuTime();
        limitstring += 'DML Statements: '+Limits.getDMLStatements()+'/' +Limits.getLimitDMLStatements();
        limitstring += 'Email Invocations: '+Limits.getEmailInvocations()+'/' +Limits.getLimitEmailInvocations();    
        limitstring += 'Future Calls: '+Limits.getFutureCalls()+'/' +Limits.getLimitFutureCalls();     
        limitstring += 'Query Locator Rows: '+Limits.getQueryLocatorRows() +'/'+Limits.getLimitQueryLocatorRows();

        System.debug(LoggingLevel.ERROR,'limits before call::::::::'+limitstring);

        //Execute API call
        Apttus_CPQApi.CPQ.UpdateManualAdjustmentsResponseDO result =  Apttus_CPQApi.CPQWebService.updateManualAdjustmentsForCart(request);

        //Validate salesforce limits after call
        limitstring = '';
        limitstring += 'Query Limits: '+ Limits.getQueries() + '/' + Limits.getLimitQueries() +'\n';
        limitstring += 'DML Rows Limits: '+Limits.getDMLRows()+'/' + Limits.getLimitDMLRows()+'\n';
        limitstring += 'Heap Size Limits: '+Limits.getHeapSize()+'/' +Limits.getLimitHeapSize()+'\n';
        limitstring += 'Query Return Limits: '+Limits.getQueryRows()+'/' + Limits.getLimitQueryRows()+'\n';      
        limitstring += 'Aggregate Queries: '+Limits.getAggregateQueries()+'/' + Limits.getLimitAggregateQueries();
        limitstring += 'Callouts: '+Limits.getCallouts()+'/' +Limits.getLimitCallouts();    
        limitstring += 'CPU Time: '+Limits.getCpuTime()+'/' +Limits.getLimitCpuTime();
        limitstring += 'DML Statements: '+Limits.getDMLStatements()+'/' +Limits.getLimitDMLStatements();
        limitstring += 'Email Invocations: '+Limits.getEmailInvocations()+'/' +Limits.getLimitEmailInvocations();    
        limitstring += 'Future Calls: '+Limits.getFutureCalls()+'/' +Limits.getLimitFutureCalls();     
        limitstring += 'Query Locator Rows: '+Limits.getQueryLocatorRows() +'/'+Limits.getLimitQueryLocatorRows();

        System.debug(LoggingLevel.ERROR,'limits after call::::::::'+limitstring);
        System.debug(LoggingLevel.ERROR,'result:::::::'+result);
        
        return true;
    }

    public static void validateCERAmendment(Id productConfigId, Id agreementId){
        //If product configurations found, check if the agreement has a finalized product configuration
        List<Apttus_Config2__ProductConfiguration__c> lstFinalizedConfig = 
        [
            SELECT Id,Apttus_CMConfig__AgreementId__c 
            FROM Apttus_Config2__ProductConfiguration__c 
            WHERE Apttus_CMConfig__AgreementId__c = :agreementId
            AND Apttus_Config2__Status__c = 'Finalized'
        ];
                System.debug('++WednesdayDebug++'+agreementId);
         List<Apttus__APTS_Agreement__c> listAgreements = [  SELECT Apttus_CMConfig__PriceListId__c, 
                                                                Apttus__Account__c,
                                                                Apttus__Contract_Start_Date__c,Apttus__Agreement_Number__c,
                                                                Apttus__Contract_End_Date__c
                                                                FROM Apttus__APTS_Agreement__c
                                                                WHERE Id = : agreementId LIMIT 1];
        String Type;
        String SubType;
        String AdjustmentType;
        String AgreementType;
        String AdjustmentValue;
        String ContributingAgreement ;
        String SoldtoParty;
        List<APTS_Contract_Entitlement_Repository__c>  UpdateCERList = new List<APTS_Contract_Entitlement_Repository__c>();
        List<APTS_Contract_Entitlement_Repository__c>  UpdateCERListAmendment = new List<APTS_Contract_Entitlement_Repository__c>();
        UpdateCERList=[select id,APTS_Amendment_In_Progress__c,APTS_Agreement_Adjustment_Line_Item__r.APTS_Category__c,APTS_Category__r.APTS_Category_Adjustments_Product__c,APTS_Product__c,APTS_Product__r.APTS_Category_Adjustments_Product__c,APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c,APTS_Agreement_Line_Item__r.Apttus_CMConfig__HasOptions__c from APTS_Contract_Entitlement_Repository__c where APTS_Contributing_Agreement__r.Apttus__Agreement_Number__c=:listAgreements[0].Apttus__Agreement_Number__c];
        for(APTS_Contract_Entitlement_Repository__c cer:UpdateCERList){
            if(cer.APTS_Product__r.APTS_Category_Adjustments_Product__c==true||(cer.APTS_Agreement_Adjustment_Line_Item__r.APTS_Category__c!=null&&cer.APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c=='Product/Service'&&cer.APTS_Agreement_Line_Item__r.Apttus_CMConfig__HasOptions__c==false)){
                cer.APTS_Amendment_In_Progress__c=true;
                UpdateCERListAmendment.add(cer);
            }
        }
        if(UpdateCERListAmendment.size() > 0){
                update UpdateCERListAmendment;
            }

        //If finalized configurations found continue
        if(lstFinalizedConfig != null && lstFinalizedConfig.size() > 0){
            //Get line items and adjustment line items for configuration
            List<APTS_Contract_Entitlement_Repository__c>  insertCERList = new List<APTS_Contract_Entitlement_Repository__c>();

            List<Apttus_Config2__LineItem__c> lstLI = 
            [
                SELECT Id,
                APTS_AgreementId__c,
                Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Recordtype.Name,
                Apttus_Config2__LineType__c,
                Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Account__c,
                APTS_Category_Level__c,
                Apttus_Config2__ClassificationId__c,
                APTS_Sub_Category__c,
                APTS_Sub_Sub_Category__c,
                Apttus_Config2__ProductId__c,
                Apttus_Config2__OptionId__c,
                (
                    SELECT Id,
                    Apttus_Config2__LineItemId__c,
                    Apttus_Config2__AdjustmentType__c,
                    Apttus_Config2__AdjustmentAmount__c,
                    Apttus_Config2__Type__c,
                    Apttus_Config2__SubType__c,
                    Apttus_Config2__AdjustmentAppliesTo__c,
                    Apttus_Config2__Bucket__c,
                    Apttus_Config2__AdjustmentUom__c,
                    APTS_Start_Date__c,
                    APTS_End_Date__c
                    FROM Apttus_Config2__AdjustmentLineItems__r
                )
                FROM Apttus_Config2__LineItem__c
                WHERE Apttus_Config2__ConfigurationId__c = :productConfigId
                AND Apttus_Config2__ProductId__r.APTS_Category_Adjustments_Product__c = true 
            ];

            //Loop through records and create CER records
            for(Apttus_Config2__LineItem__c currentLI : lstLI){

                List<Apttus_Config2__AdjustmentLineItem__c> lstADLI = currentLI.Apttus_Config2__AdjustmentLineItems__r;

                for(Apttus_Config2__AdjustmentLineItem__c currentADLI : currentLI.Apttus_Config2__AdjustmentLineItems__r){
                    
                    insertCERList.add(
                        new APTS_Contract_Entitlement_Repository__c(
                            APTS_Pending_Adjustment_Line_Item__c = currentADLI.Id,
                            APTS_Pending_Line_Item__c = currentADLI.Apttus_Config2__LineItemId__c,
                            APTS_Adjustment_Type__c = currentADLI.Apttus_Config2__AdjustmentType__c,
                            APTS_Adjustment_Value__c = currentADLI.Apttus_Config2__AdjustmentAmount__c,
                            APTS_Contributing_Agreement__c = currentLI.APTS_AgreementId__c,
                            APTS_Agreement_Type__c = currentLI.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Recordtype.Name,
                            APTS_Contributing_Agreement_Level__c = 'Child',
                            //APTS_Contributing_Agreement_Level__c = 'Parent',
                            APTS_Type__c = currentADLI.Apttus_Config2__Type__c,
                            APTS_Sub_Type__c = currentADLI.Apttus_Config2__SubType__c,
                            APTS_Adjustment_Applies_To__c  = currentADLI.Apttus_Config2__AdjustmentAppliesTo__c,
                            APTS_Bucket__c = currentADLI.Apttus_Config2__Bucket__c,
                            APTS_Product__c = 'Product/Service'.equalsIgnoreCase(currentLI.Apttus_Config2__LineType__c)?currentLI.Apttus_Config2__ProductId__c:currentLI.Apttus_Config2__OptionId__c,
                            APTS_UOM__c = currentADLI.Apttus_Config2__AdjustmentUom__c,
                            APTS_Sold_to_Party__c = currentLI.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Account__c,
                            APTS_Category_Level__c = currentLI.APTS_Category_Level__c,
                            APTS_CategoryCER__c = currentLI.Apttus_Config2__ClassificationId__c,
                            APTS_Sub_Category__c = currentLI.APTS_Sub_Category__c,
                            APTS_Sub_Sub_Category__c = currentLI.APTS_Sub_Sub_Category__c,
                            APTS_Is_Pending__c = true,
                            APTS_Charge_Type__c='Sales Price',
                            APTS_Start_Date__c = currentADLI.APTS_Start_Date__c,
                            APTS_End_Date__c = currentADLI.APTS_End_Date__c,
                            APTS_Category_Discount_Amendment__c = true
                        )
                    );
                }
            }

            if(insertCERList.size() > 0){
                insert insertCERList;
            }

            //Update flag in configuration
            Apttus_Config2__ProductConfiguration__c obj = new Apttus_Config2__ProductConfiguration__c();
            obj.Id = productConfigId;
            obj.APTS_Amendment_CER_Creation__c = true;
            update obj;
        }
    }

    public static List<Apttus_Config2__AdjustmentLineItem__c> getListCERAmendment(Id agreementId, Id categoryProduct,
    String category, String subCategory, String subSubCategory, String type, String subType){
        //If product configurations found, check if the agreement has a finalized product configuration
        List<Apttus_Config2__ProductConfiguration__c> lstFinalizedConfig = 
        [
            SELECT Id,Apttus_CMConfig__AgreementId__c 
            FROM Apttus_Config2__ProductConfiguration__c 
            WHERE Apttus_CMConfig__AgreementId__c = :agreementId
            AND Apttus_Config2__Status__c = 'Finalized'
        ];

        List<Apttus_Config2__AdjustmentLineItem__c> lstADLI;
        
        //If finalized configurations found continue
        if(lstFinalizedConfig != null && lstFinalizedConfig.size() > 0){
            //Get line items and adjustment line items for configuration
            lstADLI = 
            [
                SELECT Id,
                Apttus_Config2__LineItemId__c,
                Apttus_Config2__AdjustmentType__c,
                Apttus_Config2__AdjustmentAmount__c,
                Apttus_Config2__Type__c,
                Apttus_Config2__SubType__c,
                Apttus_Config2__AdjustmentAppliesTo__c,
                Apttus_Config2__Bucket__c,
                Apttus_Config2__AdjustmentUom__c,
                APTS_Start_Date__c,
                APTS_End_Date__c,
                APTS_Category__c,
                APTS_Sub_Category__c,
                APTS_Sub_Sub_Category__c
                FROM Apttus_Config2__AdjustmentLineItem__c
                WHERE Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c = :lstFinalizedConfig[0].Id
                AND Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__c = :categoryProduct
                AND APTS_Category__c = :category
                AND APTS_Sub_Category__c = :subCategory
                AND APTS_Sub_Sub_Category__c = :subSubCategory
                AND Apttus_Config2__Type__c = :type
                AND Apttus_Config2__SubType__c = :subType
            ];          
        }

        return lstADLI;
    }

    public static APTS_Contract_Entitlement_Repository__c createNewCERAmendment(Id cerId, Id agreementId, Double value, Id account){
        String strFields = '';

        Map <String, Schema.SObjectField> fieldMap = APTS_Contract_Entitlement_Repository__c.sObjectType.getDescribe().fields.getMap();

        for(Schema.SObjectField sfield : fieldMap.Values())
        {
            schema.describefieldresult dfield = sfield.getDescribe();
            if(dfield.isCustom() && dfield.isUpdateable()){
                strFields += dfield.getname() + ',';
            }
        }

        strFields = strFields.removeEnd(',');

        String strQuery = 'SELECT ' + strFields + ' FROM APTS_Contract_Entitlement_Repository__c WHERE Id = :cerId ';

        List<APTS_Contract_Entitlement_Repository__c> lstCERParent = Database.query(strQuery);

        System.debug(LoggingLevel.ERROR,'List CER Parent:::::::::' + lstCERParent);

        APTS_Contract_Entitlement_Repository__c newCERRecord;
        
        if(lstCERParent.size() > 0){
            newCERRecord = lstCERParent[0].clone(false, false, false, false);
            newCERRecord.APTS_Sold_to_Party__c = account;
            newCERRecord.APTS_Is_Pending__c = true;
            newCERRecord.APTS_Contributing_Agreement_Level__c = 'Child';
            newCERRecord.APTS_Contributing_Agreement__c = agreementId;
            newCERRecord.APTS_CER_from_Parent__c = true;
            newCERRecord.APTS_Charge_Type__c='Sales Price';
            newCERRecord.APTS_Adjustment_Value__c = value;              
            newCERRecord.APTS_Category_Discount_Amendment__c = true;                
            newCERRecord.APTS_Pending_Line_Item__c = null;              
            newCERRecord.APTS_Pending_Adjustment_Line_Item__c = null;               

            //Insert CER Parent Record
            insert newCERRecord;
        }

        return newCERRecord;
    }

    public static Id originalAgreementId(Id amendedAgreementId){
        Id originalAgreementId;

        //Get record from Related Agreement 
        List<Apttus__APTS_Related_Agreement__c> lstRelatedAgreement =
        [
            SELECT Id, Apttus__APTS_Contract_From__c 
            FROM Apttus__APTS_Related_Agreement__c 
            WHERE Apttus__APTS_Contract_To__c = :amendedAgreementId
            AND Apttus__Relationship_From_Type__c = 'Is Amended By'
            AND Apttus__Relationship_To_Type__c = 'Is Amendment For'
            LIMIT 1
        ];

        //Get original agreement Id
        if(lstRelatedAgreement.size() > 0){
            originalAgreementId = lstRelatedAgreement[0].Apttus__APTS_Contract_From__c;
        }

        return originalAgreementId;
    }

    public static List<APTS_Contract_Entitlement_Repository__c> getCERRecord(Id accountId, Id categoryProduct,
    String category, String subCategory, String subSubCategory, String type, String subType){
        //Get CER record
        List<APTS_Contract_Entitlement_Repository__c> lstCER = 
        [
            SELECT Id,
            APTS_CER_Changed_Amendment__c
            FROM APTS_Contract_Entitlement_Repository__c
            WHERE APTS_Sold_to_Party__c = :accountId
            AND APTS_Product__c = :categoryProduct
            AND APTS_CategoryCER__c = :category
            AND APTS_Sub_Category__c = :subCategory
            AND APTS_Sub_Sub_Category__c = :subSubCategory
            AND APTS_Type__c = :type
            AND APTS_Sub_Type__c = :subType
            AND APTS_CER_Changed_Amendment__c = true
        ];

        return lstCER;  
    }

    public static List<APTS_Contract_Entitlement_Repository__c> getCERRecord(Id accountId, Id categoryProduct,
    Set<String> setCategory, Set<String> setSubCategory, Set<String> setSubSubCategory, Set<String> setType, Set<String> setSubType){
        //Get CER record
        List<APTS_Contract_Entitlement_Repository__c> lstCER = [SELECT Id,APTS_CER_Changed_Amendment__c,APTS_Type__c,APTS_Sub_Type__c,APTS_CategoryCER__c,APTS_Sub_Category__c,APTS_Sub_Sub_Category__c FROM APTS_Contract_Entitlement_Repository__c WHERE APTS_Sold_to_Party__c = :accountId AND APTS_Product__c = :categoryProduct AND APTS_CategoryCER__c IN :setCategory AND APTS_Sub_Category__c IN :setSubCategory AND APTS_Sub_Sub_Category__c IN :setSubSubCategory AND APTS_Type__c IN :setType AND APTS_Sub_Type__c IN :setSubType AND APTS_CER_Changed_Amendment__c = true];
        return lstCER;  
    }
}