/**
* Class Name : APTS_ProductRedistributionBatchHandler
* Description :  Helper Class to create multiple Objects' records from Product2 Object
* Author : Nagavi/Shankar/Vigitha
* Date Created : 02/23/2018
**/
public with sharing class APTS_ProductRedistributionBatchHandler{// with sharing 
    
    private Static String EMPTY_STRING = ' ';

    /** Method Name : getObjectQuery
    * Description : Method to build and return a dynamic query for a specified sObject 
    **/
    public static String getObjectQuery(String objectName){
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        String thisQuery = Label.APTS_SelectLabel + EMPTY_STRING;
        for(Schema.SObjectField field : fieldMap.values()){
            thisQuery += field.getDescribe().getName() + Label.APTS_CommaSeparator;
        }
        thisQuery = thisQuery.subString(0, thisQuery.length()-1);
        thisQuery += EMPTY_STRING + Label.APTS_FromLabel + EMPTY_STRING + objectName + EMPTY_STRING;
        return thisQuery;
    }
    
   
    
    /** Method Name : updateFreqConversionRate
    * Description : Method to update Frequency/UOM Conversion Rate records from Product2 records
    **/
    public static Map<Id,List<APTS_Batch_Error__c>> updateFreqConversionRate(Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap,Map<Id, Product2> activeProductMap, Map<String, Product2> productCodeProductMap){
        List<Apttus_Config2__FrequencyConversionRate__c> freqConversionUpdateList = new List<Apttus_Config2__FrequencyConversionRate__c>();
        
        for(Apttus_Config2__FrequencyConversionRate__c freqConversion : [SELECT Id, Apttus_Config2__ProductId__c, APTS_ProductCode__c,APTS_Numerator__c ,APTS_Denominator__c,Apttus_Config2__ConversionFactor__c FROM Apttus_Config2__FrequencyConversionRate__c WHERE APTS_ProductCode__c IN: productCodeProductMap.keySet()]){
            if(productCodeProductMap.containsKey(freqConversion.APTS_ProductCode__c)){
                freqConversion.Apttus_Config2__ProductId__c = productCodeProductMap.get(freqConversion.APTS_ProductCode__c).Id;
                if(freqConversion.APTS_Numerator__c >0 && freqConversion.APTS_Denominator__c>0){
                    freqConversion.Apttus_Config2__ConversionFactor__c=(freqConversion.APTS_Numerator__c/freqConversion.APTS_Denominator__c);
                }
                freqConversionUpdateList.add(freqConversion);
            }
        }
        
        if(!freqConversionUpdateList.IsEmpty()){
            //populate batchErrorsMap
            Database.SaveResult[] srList = Database.update(freqConversionUpdateList,false);
            batchErrorsMap=getErrorDetailsForFreqUOM(srList,batchErrorsMap,system.label.APTS_Error_in_UOM_Update,freqConversionUpdateList);
        }
        return batchErrorsMap;
    }
    
    /** Method Name : getErrorDetailsForFreqUOM
    * Description : Method to process SaveResult and updates the batchErrorsMap
    **/
    public static Map<Id,List<APTS_Batch_Error__c>> getErrorDetailsForFreqUOM(List<Database.SaveResult> srList,Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap,String errorName,List<Apttus_Config2__FrequencyConversionRate__c> freqConversionUpdateList){
                
        for (Integer i = 0; i < freqConversionUpdateList.size(); i++) {
            Database.SaveResult s = srList[i];
            Apttus_Config2__FrequencyConversionRate__c origRecord = freqConversionUpdateList[i];
            if (!s.isSuccess()) {
                for(Database.Error err : s.getErrors()) {
                    batchErrorsMap=insertBatchErrors(batchErrorsMap,origRecord.Apttus_Config2__ProductId__c,errorName,err.getMessage());
                }
            } 
                    
        }
        
        return batchErrorsMap;
    }
    
    /** Method Name : UpdateProdTranslationWithProdId
    * Description : Method to update Product Translation records from Product2 records
    **/
    public static Map<Id,List<APTS_Batch_Error__c>> UpdateProdTranslationWithProdId(Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap,Map<Id, Product2> activeProductMap, Map<String, Product2> productCodeProductMap){
        List<Apttus_Config2__ProductTranslation__c> prodTranslationUpdateList = new List<Apttus_Config2__ProductTranslation__c>();
        
        for(Apttus_Config2__ProductTranslation__c prodTrans: [SELECT Id, Apttus_Config2__ProductId__c , Apttus_Config2__ProductCode__c FROM Apttus_Config2__ProductTranslation__c WHERE Apttus_Config2__ProductCode__c IN: productCodeProductMap.keySet()]){
            if(productCodeProductMap.containsKey(prodTrans.Apttus_Config2__ProductCode__c)){
                prodTrans.Apttus_Config2__ProductId__c = productCodeProductMap.get(prodTrans.Apttus_Config2__ProductCode__c).Id;
                prodTranslationUpdateList.add(prodTrans);
            }
        }
        
        if(!prodTranslationUpdateList .IsEmpty()){
            //populate batchErrorsMap
            Database.SaveResult[] srList = Database.update(prodTranslationUpdateList,false);
            batchErrorsMap=getErrorDetailsForProdTrans(srList,batchErrorsMap,system.label.APTS_Error_in_ProdTranslate,prodTranslationUpdateList);
        }
        return batchErrorsMap;
    }
    
    /** Method Name : getErrorDetailsForProdTrans
    * Description : Method to process SaveResult and updates the batchErrorsMap
    **/
    public static Map<Id,List<APTS_Batch_Error__c>> getErrorDetailsForProdTrans(List<Database.SaveResult> srList,Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap,String errorName,List<Apttus_Config2__ProductTranslation__c> prodTranslationUpdateList){
                
        for (Integer i = 0; i < prodTranslationUpdateList.size(); i++) {
            Database.SaveResult s = srList[i];
            Apttus_Config2__ProductTranslation__c origRecord = prodTranslationUpdateList[i];
            if (!s.isSuccess()) {
                for(Database.Error err : s.getErrors()) {
                    batchErrorsMap=insertBatchErrors(batchErrorsMap,origRecord.Apttus_Config2__ProductCode__c,errorName,err.getMessage());
                }
            } 
                    
        }
        
        return batchErrorsMap;
    }
    
    /** Method Name : processCategoryHierarchy
    * Description : Method to process Apttus_Config2__ClassificationHierarchy__c records from Product2 record
    **/
       
     public static Map<Id,List<APTS_Batch_Error__c>> processCategoryHierarchy(Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap,Set<String> offeringCodesSet,Set<String> optionCodesSet,Map<Id,Product2> productMap){    
        
        
        List<Apttus_Config2__ClassificationHierarchy__c> hierarchyList=new List<Apttus_Config2__ClassificationHierarchy__c>();
        Map<string,Map<Id,Apttus_Config2__ProductClassification__c>> catWithProdClassMap=new Map<string,Map<Id,Apttus_Config2__ProductClassification__c>>();
        Map<string,Map<Id,Apttus_Config2__ProductClassification__c>> catWithOptionGroupMap=new Map<string,Map<Id,Apttus_Config2__ProductClassification__c>>();
        Map<string,Apttus_Config2__ClassificationHierarchy__c> offeringIdsMap=new Map<string,Apttus_Config2__ClassificationHierarchy__c>();
        Map<string,Apttus_Config2__ClassificationHierarchy__c> optionIdsMap=new Map<string,Apttus_Config2__ClassificationHierarchy__c>();
        Map<Id,List<Apttus_Config2__ProductClassification__c>> prodIdProdClassMap =new Map<Id,List<Apttus_Config2__ProductClassification__c>>();
        List<Apttus_Config2__ProductClassification__c> existingProdClassList=new List<Apttus_Config2__ProductClassification__c>();
        List<Apttus_Config2__ProductClassification__c> prodClassToBeinserted=new List<Apttus_Config2__ProductClassification__c>();
        List<Apttus_Config2__ProductClassification__c> toBeDeletedList=new List<Apttus_Config2__ProductClassification__c>();
        Set<Apttus_Config2__ProductClassification__c> prodClassToBeDeleted=new Set<Apttus_Config2__ProductClassification__c>();
        set<Id> existingRequiredIds=new Set<Id>();
                
        if(!offeringCodesSet.IsEmpty() || !optionCodesSet.IsEmpty()){
            hierarchyList=[SELECT Id,APTS_CategoryHierarchyOfferingExtId__c,APTS_CategoryHierarchyOptionExtId__c ,Apttus_Config2__PrimordialId__c,Apttus_Config2__AncestorId__c,Apttus_Config2__IsLeaf__c,Apttus_Config2__MinOptions__c,Apttus_Config2__MaxOptions__c,
            (Select ID,Apttus_Config2__ProductId__c,Apttus_Config2__ClassificationId__c from Apttus_Config2__Products__r)
            from Apttus_Config2__ClassificationHierarchy__c where ((APTS_CategoryHierarchyOfferingExtId__c!=null AND APTS_CategoryHierarchyOfferingExtId__c IN : offeringCodesSet) OR (APTS_CategoryHierarchyOptionExtId__c!=null AND APTS_CategoryHierarchyOptionExtId__c IN : optionCodesSet)) Limit 50000];
        }
        
        //Get the existing Product Classification records for the product
        existingProdClassList=[Select ID,Apttus_Config2__ProductId__c,Apttus_Config2__ClassificationId__c from Apttus_Config2__ProductClassification__c
                               Where Apttus_Config2__ProductId__c IN: productMap.KeySet() Limit 50000];
        if(!existingProdClassList.IsEmpty()){
            
            for(Apttus_Config2__ProductClassification__c prodClassification : existingProdClassList){
                if(prodIdProdClassMap.containsKey(prodClassification.Apttus_Config2__ProductId__c)) {
                    prodIdProdClassMap.get(prodClassification.Apttus_Config2__ProductId__c).add(prodClassification);
                } else {
                    prodIdProdClassMap.put(prodClassification.Apttus_Config2__ProductId__c, new List<Apttus_Config2__ProductClassification__c> {prodClassification});
                }
                
            }
        }                       
        
        if(!hierarchyList.IsEmpty()){
            for(Apttus_Config2__ClassificationHierarchy__c hier:hierarchyList){
                if(hier.APTS_CategoryHierarchyOfferingExtId__c!=null){
                    offeringIdsMap.put(hier.APTS_CategoryHierarchyOfferingExtId__c,hier);
                    for(Apttus_Config2__ProductClassification__c prodClass: hier.Apttus_Config2__Products__r){
                        
                        if(catWithProdClassMap.containsKey(hier.APTS_CategoryHierarchyOfferingExtId__c)) {
                            catWithProdClassMap.get(hier.APTS_CategoryHierarchyOfferingExtId__c).put(prodClass.Apttus_Config2__ProductId__c,prodClass);
                        } else {
                            catWithProdClassMap.put(hier.APTS_CategoryHierarchyOfferingExtId__c, new Map<Id,Apttus_Config2__ProductClassification__c> { prodClass.Apttus_Config2__ProductId__c => prodClass});
                        }
                        
                    }
                }
                if(hier.APTS_CategoryHierarchyOptionExtId__c!=null){
                    optionIdsMap.put(hier.APTS_CategoryHierarchyOptionExtId__c,hier);
                                       
                    for(Apttus_Config2__ProductClassification__c optGroup : hier.Apttus_Config2__Products__r){
                                            
                        if(catWithOptionGroupMap.containsKey(hier.APTS_CategoryHierarchyOfferingExtId__c)) {
                            catWithOptionGroupMap.get(hier.APTS_CategoryHierarchyOfferingExtId__c).put(optGroup.Apttus_Config2__ProductId__c,optGroup);
                        } else {
                            catWithOptionGroupMap.put(hier.APTS_CategoryHierarchyOfferingExtId__c, new Map<Id,Apttus_Config2__ProductClassification__c> { optGroup.Apttus_Config2__ProductId__c => optGroup});
                        }
                        
                        //prodIdProdClassMap.put(optGroup.Apttus_Config2__ProductId__c,optGroup); 
                    }
                }
            }
        }
        
        
        for(Product2 prod : productMap.values()){
            Apttus_Config2__ProductClassification__c tempProdClass=new Apttus_Config2__ProductClassification__c();
            if(prod.APTS_Sales_Catalog__c!=null && prod.APTS_Sales_Catalog__c != system.label.APTS_00_Value){
                /*if(prodIdProdClassMap.containsKey(prod.Id) && offeringIdsMap.containsKey(prod.APTS_Sales_Catalog__c) && prodIdProdClassMap.get(prod.Id).Apttus_Config2__ClassificationId__c != offeringIdsMap.get(prod.APTS_Sales_Catalog__c).Id){
                    prodClassToBeDeleted.add(prodIdProdClassMap.get(prod.Id));    
                }*/ 
                                  
                if(offeringIdsMap.containsKey(prod.APTS_Sales_Catalog__c)){
                    if(!catWithProdClassMap.containsKey(prod.APTS_Sales_Catalog__c) || (catWithProdClassMap.containsKey(prod.APTS_Sales_Catalog__c) && !catWithProdClassMap.get(prod.APTS_Sales_Catalog__c).containsKey(prod.Id))){
                        tempProdClass=createProductClassification(prod.Id,offeringIdsMap.get(prod.APTS_Sales_Catalog__c).Id,prod.APTS_Sales_Catalog__c);
                        prodClassToBeinserted.add(tempProdClass);
                    }
                    else if(catWithProdClassMap.containsKey(prod.APTS_Sales_Catalog__c) && catWithProdClassMap.get(prod.APTS_Sales_Catalog__c).containsKey(prod.Id)){
                        existingRequiredIds.add(catWithProdClassMap.get(prod.APTS_Sales_Catalog__c).get(prod.Id).Id);
                    }
                }
                else {
                    batchErrorsMap=insertBatchErrors(batchErrorsMap,prod.Id,system.label.APTS_Unknown_Category,system.label.APTS_No_Match);
                }
                
            }
            if(prod.APTS_Option_Group_Indicator__c!=null && prod.APTS_Option_Group_Indicator__c != system.label.APTS_00_Value){
                               
                if(optionIdsMap.containsKey(prod.APTS_Option_Group_Indicator__c)){
                    if(!catWithOptionGroupMap.containsKey(prod.APTS_Option_Group_Indicator__c) || (catWithOptionGroupMap.containsKey(prod.APTS_Option_Group_Indicator__c) && !catWithOptionGroupMap.get(prod.APTS_Option_Group_Indicator__c).containsKey(prod.Id))){  
                        tempProdClass=createProductClassification(prod.Id,optionIdsMap.get(prod.APTS_Option_Group_Indicator__c).Id,prod.APTS_Option_Group_Indicator__c);                                    
                        prodClassToBeinserted.add(tempProdClass);
                    }
                    else if(catWithOptionGroupMap.containsKey(prod.APTS_Option_Group_Indicator__c) && catWithOptionGroupMap.get(prod.APTS_Option_Group_Indicator__c).containsKey(prod.Id)){
                        existingRequiredIds.add(catWithOptionGroupMap.get(prod.APTS_Option_Group_Indicator__c).get(prod.Id).Id);
                    }
                }
                else {
                    batchErrorsMap=insertBatchErrors(batchErrorsMap,prod.Id,system.label.APTS_Unknown_Category,system.label.APTS_No_Match);
                }
                
                
            }
            // Added by Abhishek K to Use Conversion Option Group for Creating Product Classification
            if(prod.APTS_Conversion_Option_Indicator__c!=null && prod.APTS_Conversion_Option_Indicator__c != system.label.APTS_00_Value){
                                
                if(optionIdsMap.containsKey(prod.APTS_Conversion_Option_Indicator__c)){
                    if(!catWithOptionGroupMap.containsKey(prod.APTS_Conversion_Option_Indicator__c) || (catWithOptionGroupMap.containsKey(prod.APTS_Conversion_Option_Indicator__c) && !catWithOptionGroupMap.get(prod.APTS_Conversion_Option_Indicator__c).containsKey(prod.Id))){  
                        tempProdClass=createProductClassification(prod.Id,optionIdsMap.get(prod.APTS_Conversion_Option_Indicator__c).Id,prod.APTS_Conversion_Option_Indicator__c);                                    
                        prodClassToBeinserted.add(tempProdClass);
                    }
                    else if(catWithOptionGroupMap.containsKey(prod.APTS_Conversion_Option_Indicator__c) && catWithOptionGroupMap.get(prod.APTS_Conversion_Option_Indicator__c).containsKey(prod.Id)){
                        existingRequiredIds.add(catWithOptionGroupMap.get(prod.APTS_Conversion_Option_Indicator__c).get(prod.Id).Id);
                    }
                }
                else {
                    batchErrorsMap=insertBatchErrors(batchErrorsMap,prod.Id,system.label.APTS_Unknown_Category,system.label.APTS_No_Match);
                }
                
                
            }
            
          
        }
        //Check if the product classification records needs to be deleted
        for(List<Apttus_Config2__ProductClassification__c> prdClassList : prodIdProdClassMap.values()){
            for(Apttus_Config2__ProductClassification__c prdClass: prdClassList){
                if(!existingRequiredIds.contains(prdClass.Id)){ // check if the product class needs to be present , if no, allow deletion
                    prodClassToBeDeleted.add(prdClass);
                }
            }
        }
        if(!prodClassToBeDeleted.IsEmpty()){
            toBeDeletedList.addAll(prodClassToBeDeleted);
            Database.Delete(toBeDeletedList,false);
            
        }
        if(!prodClassToBeinserted.IsEmpty()){
            Database.SaveResult[] srList = Database.insert(prodClassToBeinserted,false);
            batchErrorsMap=getErrorDetailsForProdClass(srList,batchErrorsMap,system.label.APTS_Error_in_PC_Insert,prodClassToBeinserted);
        }
        
                      
        return batchErrorsMap;
    }
    
      
    
    /** Method Name : createProductClassification
    * Description : Method to create Apttus_Config2__ProductClassification__c records for Product inserted
    **/
    public static Apttus_Config2__ProductClassification__c createProductClassification(Id ProductId,Id categoryId,string code){
        
        Apttus_Config2__ProductClassification__c prodClass=new Apttus_Config2__ProductClassification__c();
        prodClass.Apttus_Config2__ProductId__c=ProductId;
        prodClass.Apttus_Config2__ClassificationId__c=categoryId;
                
        return prodClass;
     }
     
     /** Method Name : getErrorDetailsForProdClass
    * Description : Method to process SaveResult and updates the batchErrorsMap
    **/
    public static Map<Id,List<APTS_Batch_Error__c>> getErrorDetailsForProdClass(List<Database.SaveResult> srList,Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap,String errorName,List<Apttus_Config2__ProductClassification__c> prodClassToBeinserted){
                
        for (Integer i = 0; i < prodClassToBeinserted.size(); i++) {
            Database.SaveResult s = srList[i];
            Apttus_Config2__ProductClassification__c origRecord = prodClassToBeinserted[i];
            if (!s.isSuccess()) {
                for(Database.Error err : s.getErrors()) {
                    batchErrorsMap=insertBatchErrors(batchErrorsMap,origRecord.Apttus_Config2__ProductId__c,errorName,err.getMessage());
                }
            } 
                    
        }
        
        return batchErrorsMap;
    }
    
    /** Method Name : processProductGroup
    * Description : Method to process product groups
    **/
        
      public static Map<Id,List<APTS_Batch_Error__c>> processProductGroup(Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap,Map<Id, Product2> activeProductMap){
        
        List<string> tempSalesCatalogList = new List<string>();
        List<string> tempOptionGroupList = new List<string>();
        //List<Apttus_Config2__ProductGroup__c> pgList;
        List<Apttus_Config2__ProductGroupMember__c> prodGroupMemberList = new List<Apttus_Config2__ProductGroupMember__c>();
        Set<String> allExternalIdSet = new Set<String>();
        Map<String, APTS_ProdDistributionGroupSettings__c> groupSettingMap = APTS_ProdDistributionGroupSettings__c.getAll();
        Map<String,String> groupsettingNewMap = new Map<String,String>();
        Map<Id,set<string>>prodExternalIdMap = new Map<Id,set<string>>();
        Map<String,Id>externalIdProdGroupMap = new Map<String,Id>();
        Map<Id,Set<Id>>prodGroupWithMemberMap = new Map<Id,Set<Id>>();
        //List<Apttus_Config2__ProductGroupMember__c> existingProdGroupMemList = new List<Apttus_Config2__ProductGroupMember__c>();
        Set<Apttus_Config2__ProductGroupMember__c> existingProdGroupMemToBeDeleted = new Set<Apttus_Config2__ProductGroupMember__c>();
        List<Apttus_Config2__ProductGroupMember__c> toBeDeletedList = new List<Apttus_Config2__ProductGroupMember__c>();
        Map<Id,Set<Apttus_Config2__ProductGroupMember__c>> ProdToProdGroupMemMap = new Map<Id,Set<Apttus_Config2__ProductGroupMember__c>>();
        Set<Id> blankConversionProdSet = new Set<Id>();
        
        for(String groupSetting : groupSettingMap.keyset())
        {
           if(groupSetting.startsWith(system.label.APTS_Product_Group)){
               groupsettingNewMap.put(groupSetting.substringAfter(Label.APTS_Colon),groupSettingMap.get(groupSetting).APTS_External_ID__c);
           }
        }
        if(activeProductMap !=null && !(activeProductMap.isEmpty())){
            for(Product2 prod :activeProductMap.values())
            {   
                Set<String> externalIdSet =new Set<String>();
                if(prod.APTS_Sales_Catalog__c!=Null && prod.APTS_Sales_Catalog__c != system.label.APTS_00_Value){
                    externalIdSet=codeSplitCheck(prod.APTS_Sales_Catalog__c,externalIdSet,groupsettingNewMap,system.label.APTS_Offering);    
                }
                
                if(prod.APTS_Option_Group_Indicator__c!=Null && prod.APTS_Option_Group_Indicator__c != system.label.APTS_00_Value){
                    //tempOptionGroupList =changeStringToListValue(prod.APTS_Option_Group_Indicator__c);
                    //for(string str:tempOptionGroupList){
                        externalIdSet=codeSplitCheck(prod.APTS_Option_Group_Indicator__c,externalIdSet,groupsettingNewMap,system.label.APTS_Option);
                    //} 
                     String spa= '\\s+'; 
                    if(prod.APTS_Option_Group_Indicator__c=='0203' && groupsettingNewMap.containsKey(label.APTS_Name+((prod.name).replaceAll(spa,'')).toUpperCase())){
                        //System.debug('Lavanya Prod COde--->'+groupsettingNewMap.get(label.APTS_Name+((prod.name).replaceAll(s,'')).toUpperCase()));
                        externalIdSet.add(groupsettingNewMap.get(label.APTS_Name+((prod.name).replaceAll(spa,'')).toUpperCase()));
                    }
                    
                    if(prod.APTS_Option_Group_Indicator__c.startsWith(system.label.APTS_0201_Value)){
                        if(prod.Name.containsIgnoreCase(system.label.APTS_All_Value) && prod.Name.containsIgnoreCase(system.label.APTS_Coverage_Value)){
                            if(groupsettingNewMap.containsKey(system.label.APTS_All)){
                                externalIdSet.add(groupsettingNewMap.get(label.APTS_All));
                            }
                        }
                        else if(prod.Name.containsIgnoreCase(system.label.APTS_Basic_Value) && prod.Name.containsIgnoreCase(system.label.APTS_Coverage_Value)){
                            if(groupsettingNewMap.containsKey(system.label.APTS_Basic)){
                                externalIdSet.add(groupsettingNewMap.get(label.APTS_Basic));
                            }
                        }
                    }
                    
                }
                
                //Added for CR 1987
                //Change Begin
                if(String.IsNotBlank(prod.APTS_Conversion_Option_Indicator__c) && 
                    (prod.APTS_Conversion_Option_Indicator__c.equals('0301') || prod.APTS_Conversion_Option_Indicator__c.equals('0302'))){
                    externalIdSet.add(groupsettingNewMap.get(system.label.APTS_Option + Label.APTS_Colon + '03'));
                }
                
                if(String.IsBlank(prod.APTS_Conversion_Option_Indicator__c) && String.IsBlank(prod.APTS_Option_Group_Indicator__c)){
                    blankConversionProdSet.add(prod.Id);
                }
                //Change End
                
                allExternalIdSet.addAll(externalIdSet);
                prodExternalIdMap.put(prod.Id,externalIdSet);
                
            }
        }
         
        /**if(!allExternalIdSet.IsEmpty() && activeProductMap !=null && (!(activeProductMap.isEmpty())) ){
            pgList= [Select id,APTS_ProductGroupExtId__c,(Select id,Apttus_Config2__ProductGroupId__c,Apttus_Config2__ProductId__c from Apttus_Config2__Products__r  where Apttus_Config2__ProductId__c IN:activeProductMap.keySet()) from Apttus_Config2__ProductGroup__c where APTS_ProductGroupExtId__c IN:allExternalIdSet]; 
             
        }
       
        if(pgList!=null && (!pgList.isEmpty()) && pgList.size()>0)**/
        if(!allExternalIdSet.IsEmpty() && activeProductMap !=null && (!(activeProductMap.isEmpty())))
        {
            for(Apttus_Config2__ProductGroup__c prodGroup : [Select id,APTS_ProductGroupExtId__c from Apttus_Config2__ProductGroup__c where APTS_ProductGroupExtId__c IN:allExternalIdSet]){
                //if(allExternalIdSet.contains(prodGroup.APTS_ProductGroupExtId__c)){
                    externalIdProdGroupMap.put(prodGroup.APTS_ProductGroupExtId__c,prodGroup.Id);
                    /**for(Apttus_Config2__ProductGroupMember__c pgm: prodGroup.Apttus_Config2__Products__r){
                        if(prodGroupWithMemberMap.containsKey(pgm.Apttus_Config2__ProductGroupId__c)){
                            Set<Id> prodId = prodGroupWithMemberMap.get(pgm.Apttus_Config2__ProductGroupId__c);
                            prodId.add(pgm.Apttus_Config2__ProductId__c);
                            prodGroupWithMemberMap.put(pgm.Apttus_Config2__ProductGroupId__c, prodId);
                        }
                        else{
                            prodGroupWithMemberMap.put(pgm.Apttus_Config2__ProductGroupId__c,new set<Id> {pgm.Apttus_Config2__ProductId__c});
                        }
                    }**/
                //}
            }
        }
        
        //Get the existing Product Group Member records for the product
        /**existingProdGroupMemList=[Select id,Apttus_Config2__ProductGroupId__c,Apttus_Config2__ProductId__c from Apttus_Config2__ProductGroupMember__c
                               Where Apttus_Config2__ProductId__c IN: activeProductMap.KeySet() Limit 50000];
        if(!existingProdGroupMemList.IsEmpty()){**/
            for(Apttus_Config2__ProductGroupMember__c prodGrpMem : [Select id,Apttus_Config2__ProductGroupId__c,Apttus_Config2__ProductId__c from Apttus_Config2__ProductGroupMember__c Where Apttus_Config2__ProductId__c IN: activeProductMap.KeySet() OR Apttus_Config2__ProductId__c IN: blankConversionProdSet]){
                if(ProdToProdGroupMemMap.containsKey(prodGrpMem.Apttus_Config2__ProductId__c)) {
                    ProdToProdGroupMemMap.get(prodGrpMem.Apttus_Config2__ProductId__c).add(prodGrpMem);
                } else {
                    ProdToProdGroupMemMap.put(prodGrpMem.Apttus_Config2__ProductId__c, new Set<Apttus_Config2__ProductGroupMember__c> {prodGrpMem});
                }
            }
        //}  
               
        if(activeProductMap !=null && !(activeProductMap.isEmpty())){ 
            for(Product2 activeProd :activeProductMap.values())
            {
                if(ProdToProdGroupMemMap.containsKey(activeProd.Id)){
                    existingProdGroupMemToBeDeleted.addAll(ProdToProdGroupMemMap.get(activeProd.Id));
                }
                Set<String> prodExtIdSet =prodExternalIdMap.get(activeProd.id);   
                for(String externalId:prodExtIdSet){
                    if(externalIdProdGroupMap.containsKey(externalId)){
                        prodGroupMemberList.addAll(createMemberRecord(externalIdProdGroupMap.get(externalId),activeProd.Id));   
                    }
                } 
            }
        } 
           
        if(!existingProdGroupMemToBeDeleted.IsEmpty()){
            toBeDeletedList.addAll(existingProdGroupMemToBeDeleted);
            Database.DeleteResult[] delList = Database.Delete(toBeDeletedList,false);
        }
        if(prodGroupMemberList.size()>0){
            Database.SaveResult[] srList = Database.insert(prodGroupMemberList,false);
            batchErrorsMap=getErrorDetailsForProdGroup(srList,batchErrorsMap,system.label.APTS_Error_in_PG_Insert,prodGroupMemberList);
        }
         
        return batchErrorsMap;
     }
    
     /** Method Name : getErrorDetailsForProdGroup
    * Description : Method to process SaveResult and updates the batchErrorsMap
    **/
    public static Map<Id,List<APTS_Batch_Error__c>> getErrorDetailsForProdGroup(List<Database.SaveResult> srList,Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap,String errorName,List<Apttus_Config2__ProductGroupMember__c> prodGroupMemberList){
                
        for (Integer i = 0; i < prodGroupMemberList.size(); i++) {
            Database.SaveResult s = srList[i];
            Apttus_Config2__ProductGroupMember__c origRecord = prodGroupMemberList[i];
            if (!s.isSuccess()) {
                for(Database.Error err : s.getErrors()) {
                    batchErrorsMap=insertBatchErrors(batchErrorsMap,origRecord.Apttus_Config2__ProductId__c,errorName,err.getMessage());
                }
            } 
                    
        }
        
        return batchErrorsMap;
    }
    
     public static List<String> changeStringToListValue(String value){
         List<string> tempList =new List<string>();
         tempList=value.split(system.label.APTS_CommaSeparator);
         return tempList;
     }
     
     public static set<string> codeSplitCheck(String CodeInProduct,Set<String> externalIdSet,Map<String,String>groupsettingNewMap,string typeOfCode){
         
                
         if(CodeInProduct.length()>=2){
             if(groupsettingNewMap.containsKey(typeOfCode+label.APTS_Colon+CodeInProduct.substring(0,2))){
                 if(groupsettingNewMap.get(typeOfCode+label.APTS_Colon+CodeInProduct.substring(0,2)).contains(system.label.APTS_CommaSeparator)){
                     List<string> tempList=changeStringToListValue(groupsettingNewMap.get(typeOfCode+label.APTS_Colon+CodeInProduct.substring(0,2)));
                     externalIdSet.addAll(tempList);
                  }
                  else{
                      externalIdSet.add(groupsettingNewMap.get(typeOfCode+label.APTS_Colon+CodeInProduct.substring(0,2)));
                  }
              }
          }
          if(CodeInProduct.length()>=4){
              if(groupsettingNewMap.containsKey(typeOfCode+label.APTS_Colon+CodeInProduct.substring(0,4))){
                  if(groupsettingNewMap.get(typeOfCode+label.APTS_Colon+CodeInProduct.substring(0,4)).contains(system.label.APTS_CommaSeparator)){
                     List<string> tempList=changeStringToListValue(groupsettingNewMap.get(typeOfCode+label.APTS_Colon+CodeInProduct.substring(0,4)));
                     externalIdSet.addAll(tempList);
                  }
                  else{
                  externalIdSet.add(groupsettingNewMap.get(typeOfCode+label.APTS_Colon+CodeInProduct.substring(0,4)));
                  }
              }
           }
           if(CodeInProduct.length()>=6){
               if(groupsettingNewMap.containsKey(typeOfCode+label.APTS_Colon+CodeInProduct.substring(0,6))){
                   if(groupsettingNewMap.get(typeOfCode+label.APTS_Colon+CodeInProduct.substring(0,6)).contains(system.label.APTS_CommaSeparator)){
                     List<string> tempList=changeStringToListValue(groupsettingNewMap.get(typeOfCode+label.APTS_Colon+CodeInProduct.substring(0,6)));
                     externalIdSet.addAll(tempList);
                  }
                  else{
                     externalIdSet.add(groupsettingNewMap.get(typeOfCode+label.APTS_Colon+CodeInProduct.substring(0,6)));
                   }
                }
           } return externalIdSet;   
     }
     
     public static List<Apttus_Config2__ProductGroupMember__c> createMemberRecord(Id GroupId,Id prodId){
         List<Apttus_Config2__ProductGroupMember__c>prodGroupMemberList=new List<Apttus_Config2__ProductGroupMember__c>();
         Apttus_Config2__ProductGroupMember__c  prodGroupMem = new Apttus_Config2__ProductGroupMember__c();
         prodGroupMem.Apttus_Config2__ProductGroupId__c=GroupId;
         prodGroupMem.Apttus_Config2__ProductId__c=prodId;
         prodGroupMem.Apttus_Config2__Sequence__c=decimal.valueOf(system.label.APTS_Sequence_Default_Value);
         prodGroupMemberList.add(prodGroupMem);
         return prodGroupMemberList;
     }
     
     
     
     
     /** Method Name : getErrorDetailsForProduct
    * Description : Method to process SaveResult and updates the batchErrorsMap
    **/
    public static Map<Id,List<APTS_Batch_Error__c>> getErrorDetailsForProduct(List<Database.SaveResult> srList,Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap,String errorName,List<Product2> productList){
                
        for (Integer i = 0; i < productList.size(); i++) {
            Database.SaveResult s = srList[i];
            Product2 origRecord = productList[i];
            if (!s.isSuccess()) {
                for(Database.Error err : s.getErrors()) {
                    batchErrorsMap=insertBatchErrors(batchErrorsMap,origRecord.Id,errorName,err.getMessage());
                }
            } 
                    
        }
        
        return batchErrorsMap;
    }
    
     
     
     public static Map<String,APTS_MARA_MVKE_Status_Mapping__c> getMARAMVKEStatusMapping(){
         Map<String, APTS_MARA_MVKE_Status_Mapping__c> custSettingMap = new Map<String, APTS_MARA_MVKE_Status_Mapping__c>();
         for(APTS_MARA_MVKE_Status_Mapping__c custSetting : APTS_MARA_MVKE_Status_Mapping__c.getAll().values()){
             //custSettingMap.put(custSetting.APTS_MARA_MVKE_Field_Combination__c, custSetting.APTS_MARA_MVKE_Addition_Removal__c);
             custSettingMap.put(custSetting.APTS_MARA_MVKE_Field_Combination__c, custSetting);
         }
         return custSettingMap;
     }
     
     public static Map<Id, Product2> processSalesOrgData(Map<Id, Product2> activeProductMap){
     
        Set<Id> prodIdSet = new Set<Id>();
        prodIdSet.addAll(activeProductMap.keySet());
        String query = getObjectQuery(system.label.APTS_SalesOrgDataObject);
        query += EMPTY_STRING +system.label.APTS_Product_query;
        Map<String, APTS_MARA_MVKE_Status_Mapping__c> salesStatusMap = getMARAMVKEStatusMapping();
        
        for(APTS_Sales_Org_Data__c sOrgData : Database.query(query)){
            if(sOrgData.APTS_Product__c != null){
                Product2 prod = activeProductMap.get(sOrgData.APTS_Product__c);
                Set<String> salesOrgValueSet = new Set<String>();
                if(String.IsNotBlank(prod.APTS_Associated_Sales_Org__c)){
                    salesOrgValueSet.addAll(prod.APTS_Associated_Sales_Org__c.split(label.APTS_Semi_Colon));
                }
                if(salesStatusMap.get(prod.APTS_Cross_plant_material_status__c+system.label.APTS_Pipe_Symbol+sOrgData.APTS_Distribution_chain_specific_materia__c).APTS_Visible_in_Catalogue__c){
                    salesOrgValueSet.add(system.label.APTS_SAP+sOrgData.APTS_Sales_Org_Data_Name__c);
                }else{
                    if(salesOrgValueSet.contains(system.label.APTS_SAP+sOrgData.APTS_Sales_Org_Data_Name__c)){
                        salesOrgValueSet.remove(system.label.APTS_SAP+sOrgData.APTS_Sales_Org_Data_Name__c);
                    }
                }
                String finalValue = EMPTY_STRING;
                System.debug('salesOrgValueSet======>'+salesOrgValueSet);
                for(String a : salesOrgValueSet){
                    finalValue = finalValue == EMPTY_STRING ? a : (finalValue+label.APTS_Semi_Colon+a);
                }
                prod.APTS_Associated_Sales_Org__c = finalValue;
                activeProductMap.put(prod.Id, prod);
            }
        }
        return activeProductMap;
    }
    
    public static Map<Id,List<APTS_Batch_Error__c>> insertBatchErrors(Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap,Id prodId,String errorName,string errorMsg){
            APTS_Batch_Error__c batchError = new APTS_Batch_Error__c();
            batchError.APTS_Error_Name__c = errorName;
            batchError.APTS_Error_Level__c = label.APTS_Error;
            batchError.APTS_Error_Description__c = errorMsg;
            batchError.APTS_Parent_ID__c = prodId;
            batchError.APTS_Parent_Object_Name__c = Label.Apttus_CPQAdmin.Product2;
            batchError.Error_Date_Time__c =System.Now();
            if(prodId!=null){
                if(batchErrorsMap.containsKey(prodId)){
                    batchErrorsMap.get(prodId).add(batchError);
                }
                else{
                    batchErrorsMap.put(prodId, new List<APTS_Batch_Error__c> { batchError });
                }
        }
        return batchErrorsMap;
    }
    
    /** Method Name : processProductAttributeGroups
    * Description : Method to process Product Attribute Groups
    **/
     public static Map<Id,List<APTS_Batch_Error__c>> processProductAttributeGroups(Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap, Map<Id, Product2> activeProductMap){
        
        List<string> tempSalesCatalogList =new List<string>();
        List<string> tempOptionGroupList =new List<string>();
        List<Apttus_Config2__ProductAttributeGroup__c> prgAttrGroupList;
        List<Apttus_Config2__ProductAttributeGroupMember__c> prodAttrGroupMemberList =new List<Apttus_Config2__ProductAttributeGroupMember__c>();
        
        Map<String, APTS_ProdDistributionGroupSettings__c> groupSettingMap = APTS_ProdDistributionGroupSettings__c.getAll();
        Map<String,String> groupsettingNewMap = new Map<String,String>();
        Map<Id,set<string>>prodExternalIdMap =new Map<Id,set<string>>();
        Map<String,Apttus_Config2__ProductAttributeGroup__c >externalIdProdAttrGroupMap =new Map<String,Apttus_Config2__ProductAttributeGroup__c >();
        Map<Id,Set<Id>>prodAttrGroupWithMemberMap=new Map<Id,Set<Id>>();
        Map<String,set<String>> prodAttributeMap= new Map<String,set<String>>();
        Map<String,Id> fieldExpMap= new Map<String,Id>();
        Set<String> allExternalIdSet =new Set<String>();
        
        List<Apttus_Config2__ProductAttributeGroupMember__c> existingProdAttrGroupMemList=new List<Apttus_Config2__ProductAttributeGroupMember__c>();
        Set<Apttus_Config2__ProductAttributeGroupMember__c> existingProdAttrGroupMemToBeDeleted=new Set<Apttus_Config2__ProductAttributeGroupMember__c>();
        List<Apttus_Config2__ProductAttributeGroupMember__c> toBeDeletedList=new List<Apttus_Config2__ProductAttributeGroupMember__c>();
        Map<Id,Set<Apttus_Config2__ProductAttributeGroupMember__c>> ProdToProdAttrGroupMemMap=new Map<Id,Set<Apttus_Config2__ProductAttributeGroupMember__c>>();
        
        for(String s : groupSettingMap.keyset())
        {
           if(s.startsWith(system.label.APTS_Attribute_Group)){
               groupsettingNewMap.put(s.substringAfter(label.APTS_Colon),groupSettingMap.get(s).APTS_External_ID__c);
           }
        }
        
        if(activeProductMap !=null && !(activeProductMap.isEmpty())){
            for(Product2 prod :activeProductMap.values())
            {
                Set<String> externalIdSet =new Set<String>();
                if(prod.APTS_Sales_Catalog__c!=Null && prod.APTS_Sales_Catalog__c != system.label.APTS_00_Value){
                        externalIdSet=codeSplitCheck(prod.APTS_Sales_Catalog__c,externalIdSet,groupsettingNewMap,system.label.APTS_Offering);
                        
                }
                if(prod.APTS_Option_Group_Indicator__c!=Null && prod.APTS_Option_Group_Indicator__c != system.label.APTS_00_Value){
                    //tempOptionGroupList =changeStringToListValue(prod.APTS_Option_Group_Indicator__c);
                    //for(string str:tempOptionGroupList){
                        externalIdSet=codeSplitCheck(prod.APTS_Option_Group_Indicator__c,externalIdSet,groupsettingNewMap,system.label.APTS_Option);
                        if(prod.APTS_Option_Group_Indicator__c.startsWith(system.label.APTS_0201_Value)){
                            if(prod.Name.containsIgnoreCase(system.label.APTS_All_Value) && prod.Name.containsIgnoreCase(system.label.APTS_Coverage_Value)){
                                if(groupsettingNewMap.containsKey(system.label.APTS_All)){
                                    externalIdSet.add(groupsettingNewMap.get(system.label.APTS_All));
                                }
                            }
                            else if(prod.Name.containsIgnoreCase(system.label.APTS_Basic_Value) && prod.Name.containsIgnoreCase(system.label.APTS_Coverage_Value)){
                                if(groupsettingNewMap.containsKey(system.label.APTS_Basic)){
                                    externalIdSet.add(groupsettingNewMap.get(system.label.APTS_Basic));
                                }
                            }
                           
                        }
                        
                    //} 
                }
                allExternalIdSet.addAll(externalIdSet);
                prodExternalIdMap.put(prod.Id,externalIdSet);
             }
         }   
         if(allExternalIdSet.size()>0 && activeProductMap !=null && (!(activeProductMap.isEmpty())) ){
             prgAttrGroupList= [Select id,APTS_AttributeGroupExtId__c,name,
             (Select id,Apttus_Config2__AttributeGroupId__c,Apttus_Config2__ProductId__c from Apttus_Config2__Products__r where Apttus_Config2__ProductId__c IN :activeProductMap.keySet()),
             (Select Apttus_Config2__AttributeGroupId__c,Apttus_Config2__Field__c from Apttus_Config2__Attributes__r)
             from Apttus_Config2__ProductAttributeGroup__c where APTS_AttributeGroupExtId__c in: allExternalIdSet]; 
         }
        
         if(prgAttrGroupList!=null && (!prgAttrGroupList.isEmpty()) && prgAttrGroupList.size()>0)
         {
            for(Apttus_Config2__ProductAttributeGroup__c prodAttrGroup :prgAttrGroupList){
                externalIdProdAttrGroupMap.put(prodAttrGroup.APTS_AttributeGroupExtId__c,prodAttrGroup);
                for(Apttus_Config2__ProductAttributeGroupMember__c pgm: prodAttrGroup.Apttus_Config2__Products__r){
                    if(prodAttrGroupWithMemberMap.containsKey(pgm.Apttus_Config2__AttributeGroupId__c)){
                        prodAttrGroupWithMemberMap.get(pgm.Apttus_Config2__AttributeGroupId__c).add(pgm.Apttus_Config2__ProductId__c);
                    }
                    else{
                        prodAttrGroupWithMemberMap.put(pgm.Apttus_Config2__AttributeGroupId__c,new set<Id> {pgm.Apttus_Config2__ProductId__c});
                    }
                }
                
                for(Apttus_Config2__ProductAttribute__c prodAttr: prodAttrGroup.Apttus_Config2__Attributes__r)
                {
                    if(prodAttributeMap.containsKey(prodAttr.Apttus_Config2__AttributeGroupId__c)){
                        prodAttributeMap.get(prodAttr.Apttus_Config2__AttributeGroupId__c).add(prodAttr.Apttus_Config2__Field__c);
                    }
                    else{
                        prodAttributeMap.put(prodAttr.Apttus_Config2__AttributeGroupId__c,new set<String> {prodAttr.Apttus_Config2__Field__c});
                    }
                }
            }
        }
        
        //Get the existing Product Attribute Group Members for the product
        existingProdAttrGroupMemList=[Select id,Apttus_Config2__AttributeGroupId__c,Apttus_Config2__ProductId__c from Apttus_Config2__ProductAttributeGroupMember__c Where Apttus_Config2__ProductId__c IN: activeProductMap.KeySet()];
        
        if(!existingProdAttrGroupMemList.IsEmpty()){
            for(Apttus_Config2__ProductAttributeGroupMember__c prodGrpMem : existingProdAttrGroupMemList){
                if(ProdToProdAttrGroupMemMap.containsKey(prodGrpMem.Apttus_Config2__ProductId__c)) {
                    ProdToProdAttrGroupMemMap.get(prodGrpMem.Apttus_Config2__ProductId__c).add(prodGrpMem);
                } else {
                    ProdToProdAttrGroupMemMap.put(prodGrpMem.Apttus_Config2__ProductId__c, new Set<Apttus_Config2__ProductAttributeGroupMember__c> {prodGrpMem});
                }
            }
        }       
        
        if(activeProductMap !=null && !(activeProductMap.isEmpty())){
            set<string> tempKey =new set<String>();
            for(string s:prodAttributeMap.Keyset()){
                tempKey.addAll(prodAttributeMap.get(s));
            }
            
            // Added by ABhishek K
            
            Map<Id,Set<Id>> ProdToProdAttrGroupMap=new Map<Id,Set<Id>>();

            for(Id prodid : ProdToProdAttrGroupMemMap.keyset())
            {
                for(Apttus_Config2__ProductAttributeGroupMember__c groupMem : ProdToProdAttrGroupMemMap.get(prodId))
                {
                    //System.debug('** Abhishek'+prodId+'--'+groupMem.Apttus_Config2__AttributeGroupId__c);
                    /*if(!ProdToProdAttrGroupMap.containsKey(prodId)) ProdToProdAttrGroupMap.put(prodId,new Set<Id>{groupMem.Apttus_Config2__AttributeGroupId__c});
                    else 
                    {
                    //System.debug('**Abhishek'+ProdToProdAttrGroupMap+groupMem.Apttus_Config2__AttributeGroupId__c+ProdToProdAttrGroupMap.get(groupMem.Apttus_Config2__AttributeGroupId__c));
                    if(groupMem.Apttus_Config2__AttributeGroupId__c!=null && ProdToProdAttrGroupMap.get(groupMem.Apttus_Config2__AttributeGroupId__c)!=null)     ProdToProdAttrGroupMap.get(groupMem.Apttus_Config2__AttributeGroupId__c).add(groupMem.Apttus_Config2__AttributeGroupId__c);
                    }*/
                    //Commented above code as it was buggy | Defect # 3835 | Karan Khatri
                    if(ProdToProdAttrGroupMap.get(prodId)==null){
                        ProdToProdAttrGroupMap.put(prodId,new Set<Id>{groupMem.Apttus_Config2__AttributeGroupId__c});
                    }else{
                        ProdToProdAttrGroupMap.get(prodId).add(groupMem.Apttus_Config2__AttributeGroupId__c);
                    }
                }
            }
            //System.debug('**abhishek'+ProdToProdAttrGroupMap.keyset()+ProdToProdAttrGroupMap.values());
            fieldExpMap=getFieldExpMap(tempKey);
            for(Product2 activeProd :activeProductMap.values())
            {
                if(ProdToProdAttrGroupMemMap.containsKey(activeProd.Id)){
                    //existingProdAttrGroupMemToBeDeleted.addAll(ProdToProdAttrGroupMemMap.get(activeProd.Id));
                }
                if(prodExternalIdMap.containsKey(activeProd.id)){
                    Set<String> prodExtIdSet=prodExternalIdMap.get(activeProd.id); 
                    //if(prodExtIdSet.size()==0){ system.assert(false);}
                    if(prodExtIdSet!=null){
                    
                        for(String externalId:prodExtIdSet){

                            if(externalIdProdAttrGroupMap.containsKey(externalId)){
                            
                           // System.debug('**abhi inside loop'+ProdToProdAttrGroupMemMap.containsKey(activeProd.id)+externalIdProdAttrGroupMap.get(externalId).id+ProdToProdAttrGroupMap.get(activeProd.id).contains(externalIdProdAttrGroupMap.get(externalId).id));
                            if(ProdToProdAttrGroupMemMap.keyset().size()>0 && ProdToProdAttrGroupMemMap.containsKey(activeProd.id) && ProdToProdAttrGroupMap.keyset().size()>0 && ProdToProdAttrGroupMap.get(activeProd.id)!=null && ProdToProdAttrGroupMap.get(activeProd.id).contains(externalIdProdAttrGroupMap.get(externalId).id)  ){}
                              else
                              {
                                prodAttrGroupMemberList.addAll(createAttributeMemberRecord(externalIdProdAttrGroupMap.get(externalId),activeProd,fieldExpMap,prodAttributeMap.get(externalIdProdAttrGroupMap.get(externalId).Id)));
                              }  
                            }
                        } 
                    }
                }
            }
        }    
        
        if(!existingProdAttrGroupMemToBeDeleted.IsEmpty()){
            toBeDeletedList.addAll(existingProdAttrGroupMemToBeDeleted);
            Database.DeleteResult[] delList = Database.Delete(toBeDeletedList,false);
        }
        if(prodAttrGroupMemberList.size()>0){
        
              Database.SaveResult[] srList = Database.insert(prodAttrGroupMemberList,false);
              
              batchErrorsMap=getErrorDetailsForProdAttrGroup(srList,batchErrorsMap,system.label.APTS_Error_in_Insert,prodAttrGroupMemberList);
        }
         
        return batchErrorsMap;
     }
     
     /** Method Name : getErrorDetailsForProdAttrGroup
    * Description : Method to process SaveResult and updates the batchErrorsMap
    **/
    public static Map<Id,List<APTS_Batch_Error__c>> getErrorDetailsForProdAttrGroup(List<Database.SaveResult> srList,Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap,String errorName,List<Apttus_Config2__ProductAttributeGroupMember__c> prodAttrGroupMemberList){
                
        for (Integer i = 0; i < prodAttrGroupMemberList.size(); i++) {
            Database.SaveResult s = srList[i];
            Apttus_Config2__ProductAttributeGroupMember__c origRecord = prodAttrGroupMemberList[i];
            if (!s.isSuccess()) {
                for(Database.Error err : s.getErrors()) {
                    batchErrorsMap=insertBatchErrors(batchErrorsMap,origRecord.Apttus_Config2__ProductId__c,errorName,err.getMessage());
                }
            } 
                    
        }
        
        return batchErrorsMap;
    }     
       
     public static List<Apttus_Config2__ProductAttributeGroupMember__c> createAttributeMemberRecord(Apttus_Config2__ProductAttributeGroup__c  attributeGroup,Product2 prod2,Map<string,Id> fieldExpMap,set<String>attrFieldSet){
         List<Apttus_Config2__ProductAttributeGroupMember__c>prodAttrGroupMemberList=new List<Apttus_Config2__ProductAttributeGroupMember__c>();
         String fieldUpdate =system.label.APTS_Bracket_Open;
         Apttus_Config2__ProductAttributeGroupMember__c prodGroupMem = new Apttus_Config2__ProductAttributeGroupMember__c ();
         prodGroupMem.Apttus_Config2__AttributeGroupId__c= attributeGroup.Id;
         prodGroupMem.Name=attributeGroup.Name;
         prodGroupMem.Apttus_Config2__ProductId__c=prod2.Id;
         prodGroupMem.Apttus_Config2__Sequence__c=decimal.valueOf(system.label.APTS_Sequence_Default_Value);
         if(attrFieldSet!=null){
             for(String s:attrFieldSet){
                 if(fieldExpMap!=null){
                     if(fieldExpMap.containsKey(s)){
                         string idValue =fieldExpMap.get(s);
                         fieldUpdate= fieldUpdate +label.APTS_Double_Quote+idValue+label.APTS_Double_Quote+label.APTS_CommaSeparator;}}}
                         fieldUpdate=fieldUpdate.removeEnd(label.APTS_CommaSeparator);
                         fieldUpdate =fieldUpdate+system.label.APTS_Bracket_Close;
                     
                 
               }
         //Commented as part of defect : 15636 | suggested by PrakashKumar Puthuchery
         /*if(fieldUpdate.length()>2){
         prodGroupMem.Apttus_Config2__FieldUpdateCriteriaIds__c= fieldUpdate;}*/
         prodGroupMem.APTS_AttributeGroupMemberExtId__c=attributeGroup.APTS_AttributeGroupExtId__c+label.APTS_Pipe_Symbol+prod2.ProductCode;
         prodAttrGroupMemberList.add(prodGroupMem); 
         return prodAttrGroupMemberList;
         }
     
          
     public static Map<Id, Product2> updateProducts(Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap,Map<Id, Product2> activeProductMap){
         for(Id productId : activeProductMap.KeySet()){
                if(batchErrorsMap.containsKey(productId)){
                    Product2 prodTemp=activeProductMap.get(productId);
                    prodTemp.APTS_Upserted_from_SAP__c=False;
                    prodTemp.APTS_BatchProcess_Status__c=system.label.APTS_Processed_with_Error;
                    activeProductMap.put(productId,prodTemp);
                }
                else{
                    Product2 prodTemp=activeProductMap.get(productId);
                    prodTemp.APTS_Upserted_from_SAP__c=False;
                    prodTemp.APTS_BatchProcess_Status__c=system.label.APTS_Processed;
                    activeProductMap.put(productId,prodTemp);
                }
            
            }
         return activeProductMap;
         
    } 
     
     public static Map<String,Id> getFieldExpMap(set<String>fieldExpSet){
         Map<String,Id> fieldExpMap= new Map<String,Id>();
         set<String>tempFieldValue=new set<String>();
         for(String s:fieldExpSet){
             tempFieldValue.add(system.label.APTS_Expression_For+EMPTY_STRING+s);
         }
         for(Apttus_Config2__FieldExpression__c fieldExp:[Select Name,Id from Apttus_Config2__FieldExpression__c where name IN:tempFieldValue])
            {
                if(fieldExp!=null){
                    string trimValue=fieldExp.name;
                    fieldExpMap.put(trimValue.remove(system.label.APTS_Expression_For+EMPTY_STRING),fieldExp.Id);
                }
            }
            return fieldExpMap;
        }
     
      public static void sendEmail(AsyncApexJob asyncJob){
        APTS_ProductPricingBatchSettings__c custSetting = APTS_ProductPricingBatchSettings__c.getInstance();
        String emailId = custSetting != null ? custSetting.APTS_Product_Batch_Notification_Email_ID__c: EMPTY_STRING;
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[]{emailId};
        message.Subject =system.label.APTS_ProductBatchRedistribution+ EMPTY_STRING+asyncJob.Status;
        message.plainTextBody = 'The Product Redistribution Batch processed '+ asyncJob.TotalJobItems +' batches with '+ asyncJob.NumberOfErrors + ' failures.';
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{message};
        try{
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }catch(Exception e){
        APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() ,'ProductRedistributionBatchHandler', APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,false,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);
        }
    }
    
    /** Method Name : runMaintenanceBatches
    * Description : Method to run Apttus Maintenance Batches related to Product Batch
    **/
    public static void runMaintenanceBatches(List<Id> productIdList){
    
        Set<ID> hierarchyIds = new Set<ID>();

        Apttus_Config2.AttributesUpdateJob attributeUpdateJob = new Apttus_Config2.AttributesUpdateJob();
        Database.executeBatch(attributeUpdateJob);
        
        Apttus_Config2.BundleUpdateJob bundleUpdateJob = new Apttus_Config2.BundleUpdateJob(productIdList);
        Database.executeBatch(bundleUpdateJob);
        
        // Commented as part of defect : 16981 
      /*  for(Apttus_Config2__ClassificationName__c category : [SELECT Id FROM Apttus_Config2__ClassificationName__c LIMIT 50000]){
            try{
                Apttus_Config2.HierarchyViewUpdateJob hierarchyUpdateJob = new Apttus_Config2.HierarchyViewUpdateJob(category.Id);
                Database.executeBatch(hierarchyUpdateJob);
            }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() ,'ProductRedistributionBatchHandler', APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,false);
                e.getMessage();
            }
        }*/

        //Defect : 16981 fix - START
        for(Apttus_Config2__ClassificationHierarchy__c category : [SELECT Id FROM Apttus_Config2__ClassificationHierarchy__c LIMIT 50000]){
            hierarchyIds.add(category.Id);
        }

        ID apexBatchJobId = Apttus_CpqApi.BatchUpdateService.updateCategoryViews(hierarchyIds);
        //Defect : 16981 fix - END

        Apttus_Config2.CriteriaUpdateJob criteriaUpdateJob = new Apttus_Config2.CriteriaUpdateJob(new List<String>{Label.APTS_All_Value});
        Database.executeBatch(criteriaUpdateJob);
        
        Apttus_Config2.ProductConstraintViewUpdateJob constraintUpdateJob = new Apttus_Config2.ProductConstraintViewUpdateJob();
        Database.executeBatch(constraintUpdateJob);
        
        Apttus_Config2.ProductFilterUpdateJob filterUpdateJob = new Apttus_Config2.ProductFilterUpdateJob();
        Database.executeBatch(filterUpdateJob);
    }
    
    public static Set<String> getCodesSet(String value){
         set<string> tempSet;
         if(String.IsNotBlank(value)){
             List<string> tempList=new List<String>();
             tempList=value.split(system.label.APTS_CommaSeparator);
             tempSet = new Set<String>(tempList);
         }
         else
            tempSet = new Set<String>(); 
         
         return tempSet;
     }
    
}