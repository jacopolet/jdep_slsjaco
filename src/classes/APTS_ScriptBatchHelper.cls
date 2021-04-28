public class APTS_ScriptBatchHelper {
    public static void processOrderLineItems(List<Apttus_Config2__OrderLineItem__c> lstOrderLineItem,String AttributeValueFields, String assetAdjLineItemFields){
        List<Database.SaveResult> srList = new List<Database.SaveResult>();        
        Map<Id,Id> mapOLIOldALI = new Map<Id,Id>();
        Map<Id,Id> mapMigratedAssetNewAsset = new Map<Id,Id>();
        Map<Id,Id> mapNewAssetMigratedParentAsset = new Map<Id,Id>();
        Map<Id,Id> mapNewAssetMigratedBundleAsset = new Map<Id,Id>();
        Map<Id,Id> mapNewAssetNewAttribute = new Map<Id,Id>(); 
        Set<Id> oldAssetIds = new Set<Id>();
        Set<Id> newAssetIds = new Set<Id>();
        
        //Loop over the order line items and create map for Old ALI and new ALI
        for(Apttus_Config2__OrderLineItem__c currentOLI : lstOrderLineItem){ 
            mapMigratedAssetNewAsset.put(currentOLI.APTS_Migrated_Asset_Line_Item__c,currentOLI.Apttus_Config2__AssetLineItemId__c);
            mapNewAssetMigratedParentAsset.put(currentOLI.Apttus_Config2__AssetLineItemId__c,currentOLI.APTS_Migrated_Asset_Line_Item__r.Apttus_Config2__ParentAssetId__c);
            mapNewAssetMigratedBundleAsset.put(currentOLI.Apttus_Config2__AssetLineItemId__c,currentOLI.APTS_Migrated_Asset_Line_Item__r.Apttus_Config2__BundleAssetId__c);
            mapOLIOldALI.put(currentOLI.Id, currentOLI.APTS_Migrated_Asset_Line_Item__c);
            oldAssetIds.add(currentOLI.APTS_Migrated_Asset_Line_Item__c);
            newAssetIds.add(currentOLI.Apttus_Config2__AssetLineItemId__c);
        }
        List<Apttus_Config2__AssetLineItem__c> lstNewALI = new List<Apttus_Config2__AssetLineItem__c>();
        lstNewALI =[SELECT Id, Apttus_CMConfig__AgreementId__c,Apttus_Config2__BusinessLineItemId__c,Apttus_Config2__BundleAssetId__c,Apttus_Config2__ParentAssetId__c FROM Apttus_Config2__AssetLineItem__c WHERE id IN: newAssetIds OR Apttus_Config2__BundleAssetId__c IN: mapMigratedAssetNewAsset.keyset() OR Apttus_Config2__ParentAssetId__c IN : mapMigratedAssetNewAsset.keyset()];
       
        //Query for Old Asset Attribute Value records
        System.debug('lstNewALI>>>>'+lstNewALI);
        String strQueryAssetAttribute = 'SELECT ' + AttributeValueFields + ' FROM Apttus_Config2__AssetAttributeValue__c WHERE Apttus_Config2__AssetLineItemId__c in : oldAssetIds';
        
        System.debug('strQueryAssetAttribute---'+strQueryAssetAttribute);       
        List<Apttus_Config2__AssetAttributeValue__c> lstAttributeValue = Database.query(strQueryAssetAttribute);
        List<Apttus_Config2__AssetAttributeValue__c> lstNewAttributeValue = new List<Apttus_Config2__AssetAttributeValue__c>();
        Apttus_Config2__AssetAttributeValue__c tempAV;
        //cloning asset attribute value
        if(lstAttributeValue.size() > 0){
            for(Apttus_Config2__AssetAttributeValue__c attributeRecord : lstAttributeValue){
                tempAV = attributeRecord.clone(false, true, false, false);
                if(mapMigratedAssetNewAsset.containsKey(attributeRecord.Apttus_Config2__AssetLineItemId__c))
                    tempAV.Apttus_Config2__AssetLineItemId__c = mapMigratedAssetNewAsset.get(attributeRecord.Apttus_Config2__AssetLineItemId__c);
                lstNewAttributeValue.add(tempAV);
            }
        }   
         System.debug('lstNewAttributeValue>>>'+lstNewAttributeValue);      
        //Insert cloned records
        if(lstNewAttributeValue.size()>0){
            srList = Database.insert(lstNewAttributeValue, false);
        }
        System.debug('srList>>>'+srList); 
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully created AssetAttributeValue. AssetAttributeValue Id: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        for(Apttus_Config2__AssetAttributeValue__c newAttribute : lstNewAttributeValue){
            mapNewAssetNewAttribute.put(newAttribute.Apttus_Config2__AssetLineItemId__c, newAttribute.id); 
        }
                        
        List<Apttus_Config2__AssetLineItem__c>  updateALI = new List<Apttus_Config2__AssetLineItem__c>();   
        for(Apttus_Config2__AssetLineItem__c newAsset : lstNewALI){ 
            if(mapNewAssetNewAttribute.containsKey(newAsset.id)){
                newAsset.Apttus_Config2__AttributeValueId__c = mapNewAssetNewAttribute.get(newAsset.id);                
            }
            if(mapMigratedAssetNewAsset.get(mapNewAssetMigratedParentAsset.get(newAsset.id)) != null){
                newAsset.Apttus_Config2__ParentAssetId__c = mapMigratedAssetNewAsset.get(mapNewAssetMigratedParentAsset.get(newAsset.id));
            }
            if(mapMigratedAssetNewAsset.get(mapNewAssetMigratedBundleAsset.get(newAsset.id)) != null){
                newAsset.Apttus_Config2__BundleAssetId__c = mapMigratedAssetNewAsset.get(mapNewAssetMigratedBundleAsset.get(newAsset.id));
            }       
            // Changes to Defect: #18247 - Update Option Asset to New Asset 
            if(mapMigratedAssetNewAsset.containskey(newAsset.Apttus_Config2__BundleAssetId__c)){
                newAsset.Apttus_Config2__BundleAssetId__c = mapMigratedAssetNewAsset.get(newAsset.Apttus_Config2__BundleAssetId__c);
            }
            if(mapMigratedAssetNewAsset.containskey(newAsset.Apttus_Config2__ParentAssetId__c)){
                newAsset.Apttus_Config2__ParentAssetId__c = mapMigratedAssetNewAsset.get(newAsset.Apttus_Config2__ParentAssetId__c);
            }           
            updateALI.add(newAsset);
        }
        System.debug('updateALI>>>'+updateALI);
        if(updateALI.size()>0){
            srList = Database.update(updateALI, false); 
        }
        
        //Query for Old Asset Adjustment Line Item records
        String strQueryAssetAdjLineItem = 'SELECT ' + assetAdjLineItemFields + ' FROM Apttus_Config2_AssetAdjustItem__c WHERE Apttus_Config2_AssetLineItemId__c in : oldAssetIds';
        
        System.debug('strQueryAssetAdjLineItem---'+strQueryAssetAdjLineItem);       
        List<Apttus_Config2_AssetAdjustItem__c> lstAssetAdjLineItem = Database.query(strQueryAssetAdjLineItem);
        List<Apttus_Config2_AssetAdjustItem__c> lstNewAssetAdjLineItem = new List<Apttus_Config2_AssetAdjustItem__c>();
        Apttus_Config2_AssetAdjustItem__c tempAALI;
        //cloning asset adjustment line item
        if(lstAssetAdjLineItem.size() > 0){
            for(Apttus_Config2_AssetAdjustItem__c assetAdjLineRecord : lstAssetAdjLineItem){
                tempAALI = assetAdjLineRecord.clone(false, true, false, false);
                if(mapMigratedAssetNewAsset.containsKey(assetAdjLineRecord.Apttus_Config2_AssetLineItemId__c))
                    tempAALI.Apttus_Config2_AssetLineItemId__c = mapMigratedAssetNewAsset.get(assetAdjLineRecord.Apttus_Config2_AssetLineItemId__c);
                lstNewAssetAdjLineItem.add(tempAALI);
            }
        }   
         System.debug('lstNewAssetAdjLineItem>>>'+lstNewAssetAdjLineItem);      
        //Insert cloned records
        if(lstNewAssetAdjLineItem.size()>0){
            srList = Database.insert(lstNewAssetAdjLineItem, false);
        }
        System.debug('srList>>>'+srList); 
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully created Asset Adjustment Line Item. AssetAdjustmentLineItem Id: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        //Query for Asset Counter Reading Data
        List<APTS_CounterReadingData__c> listAssetCounter = [select id, APTS_Asset_Line_Item__c, APTS_Atrribute_Value__c FROM  APTS_CounterReadingData__c where APTS_Asset_Line_Item__c in : oldAssetIds];
        
        List<APTS_CounterReadingData__c> listNewAssetCounter = new List<APTS_CounterReadingData__c>();
        System.debug('listAssetCounter---'+listAssetCounter);       
        for(APTS_CounterReadingData__c counterReading : listAssetCounter){
            if(mapMigratedAssetNewAsset.containsKey(counterReading.APTS_Asset_Line_Item__c)){
                counterReading.APTS_Asset_Line_Item__c = mapMigratedAssetNewAsset.get(counterReading.APTS_Asset_Line_Item__c);
                counterReading.APTS_Atrribute_Value__c = mapNewAssetNewAttribute.get(mapMigratedAssetNewAsset.get(counterReading.APTS_Asset_Line_Item__c));
                listNewAssetCounter.add(counterReading);
            }           
        }
        System.debug('listNewAssetCounter>>>'+listNewAssetCounter); 
        if(listNewAssetCounter.size()>0){
            srList = Database.update(listNewAssetCounter, false);
        }
        System.debug('srList>>>'+srList); 
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully created Counter reading. Counter reading Id: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        }
    }
    
    
    public static void InActivateAssetLineItems(List<Apttus_Config2__OrderLineItem__c> lstOrderLineItem,boolean deleteInActivateALI){  
       Map<Id,Apttus_Config2__AssetLineItem__c> assetLineItemMigratedUpdateMap = new Map<Id,Apttus_Config2__AssetLineItem__c>(); 
        for(Apttus_Config2__OrderLineItem__c currentOLI : lstOrderLineItem){ 
            if(currentOLI.APTS_Migrated_Asset_Line_Item__c != null){
                Apttus_Config2__AssetLineItem__c updateAsset = new Apttus_Config2__AssetLineItem__c(); 
                updateAsset.Id = currentOLI.APTS_Migrated_Asset_Line_Item__c;
                updateAsset.Apttus_Config2__IsInactive__c = true;
                updateAsset.APTS_Batch_Billing_Schedules__c = true;
                assetLineItemMigratedUpdateMap.put(updateAsset.Id,updateAsset);
            }
            
        }
         
        if(assetLineItemMigratedUpdateMap.size()>0){
            if(!deleteInActivateALI){
                update assetLineItemMigratedUpdateMap.values(); 
            }else{
                delete assetLineItemMigratedUpdateMap.values(); 
            } 
        }
        
    }
    
    public static void DeleteOrder(List<Apttus_Config2__Order__c> listOrder){   
        List <Apttus_Config2__Order__c> deleteListOrder  = new List <Apttus_Config2__Order__c>();
        for (Apttus_Config2__Order__c deleteOrder : listOrder ){
            deleteListOrder.add(deleteOrder);
        }
        if(deleteListOrder.size()>0){
            delete deleteListOrder;  
        }            
    }
}