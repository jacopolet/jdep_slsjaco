/*
* Description: Batch Apex for associating Frequency Conversion Rate with products
* Class Name: APTS_ProductReplacementCodeMapping
* Created by: Shahul (Shahul.nizam.moideen@accenture.com)
v1.1 17/11/2021- DQ-4389 - Date Restriction for Product Replacement 
v1.2 12/6/2020 - DQ-4390 - Product Replacement Logic updation on Sales Org Level
* Date Created: 03/26/2017
*/
//V1.3 18-Feb-2021 Aarthi : DQ-5243 - Update related Sales orgs on replaced product

global class APTS_ProductReplacementCodeMapping implements Database.Batchable<sObject> 
{
public Static String EMPTY_STRING = ' ';
public static boolean deleteTriggerSettingsEntry;
public static boolean updateTriggerSettingsEntry;

    global Database.QueryLocator start(Database.BatchableContext BC)
         {
            String strProdQry = APTS_ProductRedistributionBatchHandler.getObjectQuery('APTS_Product_Replacement_Codes__c');
            //DQ-4389 - v1.1         
            strProdQry +=  EMPTY_STRING + Label.APTS_ProductReplacementCodeMappingQuery;
            return Database.getQueryLocator(strProdQry);
         }
         
    global void execute(Database.BatchableContext BC, List<APTS_Product_Replacement_Codes__c> scope) 
    {
         Map<id,APTS_Product_Replacement_Codes__c> ProdReplaceRecordsToUpdate = new Map<id,APTS_Product_Replacement_Codes__c>();
         Map<id,APTS_Product_Replacement_Codes__c> OldProdReplaceRecordsToUpdate = new Map<id,APTS_Product_Replacement_Codes__c>();
         Map<id,product2> ProdRecordsToUpdate = new Map<id,product2>();
         Set<String> setOfProductCodes = new Set<String>();
         Set<string> replaceprocessedCodes=new Set<string>();        
         Set<String> setOfSalesOrgs = new Set<String>();
         List<String> AvoidDupCodes = new List<String>();
         Map<Id,APTS_Sales_Org_Data__c> SalesOrgRecordsToUpdate;
         Set<String> setOfReplacedProductCodes = new Set<String>();
         Set<String> ReplCode=new Set<String>();
         list<APTS_Sales_Org_Data__c> lstSalesOrgData= new List<APTS_Sales_Org_Data__c>();
         
         try
         {
            for(APTS_Product_Replacement_Codes__c P2: scope)
             {
               setOfProductCodes.add(P2.APTS_Product_Code__c);
               setOfReplacedProductCodes.add(P2.APTS_Replacement_Product_Code__c);
               setOfSalesOrgs.add(P2.APTS_Sales_Org__c);
             }
            list<APTS_Product_Replacement_Codes__c> oldreplacecode=[select id,name,APTS_Replacement_Product_Code__c,APTS_Sales_Org__c from APTS_Product_Replacement_Codes__c where APTS_Sales_Org__c IN:setOfSalesOrgs AND APTS_Replacement_Product_Code__c IN:setOfProductCodes];
            lstSalesOrgData = [Select id,APTS_Replaced_by__c,APTS_Sales_Org_Data_Name__c,APTS_Product_Code__c from APTS_Sales_Org_Data__c where APTS_Product_Code__c IN :setOfProductCodes and APTS_Sales_Org_Data_Name__c IN :setOfSalesOrgs];
            for(APTS_Product_Replacement_Codes__c P2old: oldreplacecode)
            {
                P2old.APTS_Valid_To__c=system.today().ADDDAYs(-1);
                OldProdReplaceRecordsToUpdate.put(P2old.id,P2old);
            }
                
            for(String str:setOfProductCodes)
            {
                str='%'+str+'%';
                replaceprocessedCodes.add(str);
            }
            Map<String, List<APTS_Product_Replacement_Codes__c>> mapOfReplacementProd = new Map<String, List<APTS_Product_Replacement_Codes__c>>();
            String strrepQry;
            strrepQry = APTS_ProductRedistributionBatchHandler.getObjectQuery(Label.Apttus_CPQAdmin.Product2);
            strrepQry += label.APTS_ReplacmentQuery;
         
            for(APTS_Product_Replacement_Codes__c REPL:Scope)
            {
                if(mapOfReplacementProd.containsKey(REPL.APTS_Product_Code__c))
                 {
                  mapOfReplacementProd.get(REPL.APTS_Product_Code__c).add(REPL);
                 } 
                else 
                 {
                  mapOfReplacementProd.put(REPL.APTS_Product_Code__c, new List<APTS_Product_Replacement_Codes__c> {REPL});
                 }
       
            } 
            
        for(Product2 prod : Database.query(strrepQry))
            { 
            SalesOrgRecordsToUpdate = new Map<Id,APTS_Sales_Org_Data__c>();
            AvoidDupCodes = new List<String>();
              
             for(APTS_Sales_Org_Data__c instSalesOrg : lstSalesOrgData)
                {                   
                    List<APTS_Product_Replacement_Codes__c> listOfRepls = mapOfReplacementProd.get(instSalesOrg.APTS_Product_Code__c);
                    for(APTS_Product_Replacement_Codes__c REPL : listOfRepls) 
                    {
                        REPL.APTS_Product__c = prod.Id;
                        REPL.APTS_Valid_To__c=system.today().ADDYEARS(100);
                        prod.APTS_Has_Replacement__c=true;
                        List<String> AvoidDupCodeslist =new List<String>();
                        if(!AvoidDupCodes.contains(REPL.APTS_Replacement_Product_Code__c))
                            AvoidDupCodeslist.add(REPL.APTS_Replacement_Product_Code__c);                      
                     
                        if(REPL.APTS_Sales_Org__c.contains(instSalesOrg.APTS_Sales_Org_Data_Name__c) && REPL.APTS_Product_Code__c == instSalesOrg.APTS_Product_Code__c)
                        {
                            if(instSalesOrg.APTS_Replaced_by__c != null){ 
                                instSalesOrg.APTS_Replaced_by__c=instSalesOrg.APTS_Replaced_by__c+','+AvoidDupCodeslist[0];
                            }                    
                            else if(AvoidDupCodeslist!= null && AvoidDupCodeslist.size()>0){
                                instSalesOrg.APTS_Replaced_by__c=AvoidDupCodeslist[0];
                            }
                            SalesOrgRecordsToUpdate.put(instSalesOrg.id,instSalesOrg);  
                        }
                        ProdReplaceRecordsToUpdate.put(REPL.id,REPL);
                    }
               }        
              
            }               
                  List<Database.SaveResult> prodDmlResult = Database.update(SalesOrgRecordsToUpdate.values());
                  List<Database.SaveResult> oldprodDmlResult = Database.update(OldProdReplaceRecordsToUpdate.values());
                  List<Database.SaveResult> ReplDmlResult = Database.update(ProdReplaceRecordsToUpdate.values());

                  //V1.3 ++ <<
                  Set<Id> setPRCIds = new Set<Id>();
                  for (Database.SaveResult sr : ReplDmlResult) {
                    if (sr.isSuccess()) {
                        setPRCIds.add(sr.getId());
                    }
                }
                if(!setPRCIds.isEmpty())
                {
                    updateRelatedSalesOrgData(setPRCIds);
                }
                  //V1.3 ++ >>

            }
            catch(Exception e){
            
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Batch',e.getMessage()+'\n\n'+e.getStackTraceString() ,'Product Replacement Code','','CPQ',false,true,'cpqerror@accenture.com',true);             
            }     
        }
        
    global void finish(Database.BatchableContext BC) {
        if(System.Label.APTS_UOMBatchSize!=null && Integer.valueOf(System.Label.APTS_UOMBatchSize)!=0){
            APTS_CreateUOMsBatch uomBatch = new APTS_CreateUOMsBatch();
            Database.executeBatch(uomBatch,Integer.valueOf(System.Label.APTS_UOMBatchSize));
        }
    }
    //V1.3 ++ <<
    public void updateRelatedSalesOrgData(Set<Id> setPRCIds)
    {
            Map<id,APTS_Product_Replacement_Codes__c> mapProductReplacementCodes = new Map<Id, APTS_Product_Replacement_Codes__c>([Select id, APTS_Product__c, APTS_Product_Code__c, Name, APTS_Sales_Org__c, APTS_Valid_From__c, APTS_Valid_To__c, Plant_status__c, APTS_Replacement_Product_Code__c from APTS_Product_Replacement_Codes__c where id in: setPRCIds]);
            List<APTS_Product_Replacement_Codes__c> lstProductReplacementCodes = new List<APTS_Product_Replacement_Codes__c>();
            Map<string, APTS_Product_Replacement_Codes__c> mapExtIDWithProdReplCode = new Map<string, APTS_Product_Replacement_Codes__c>();
            Map<string, APTS_Product_Replacement_Codes__c> mapExtIDWithProdReplCodeOriginal = new Map<string, APTS_Product_Replacement_Codes__c>();
            try{
                    if(!mapProductReplacementCodes.isEmpty())
                    {
                            boolean bReplacedCodeChange = false;
                            for(APTS_Product_Replacement_Codes__c oProdRepl :mapProductReplacementCodes.Values())
                            {
                                    lstProductReplacementCodes.add(oProdRepl);
                                    string tempExtID = oProdRepl.APTS_Product_Code__c + '|' + oProdRepl.APTS_Sales_Org__c;                                            
                                    mapExtIDWithProdReplCodeOriginal.put(tempExtID, oProdRepl);
                                    DateTime currentDate = Date.Today(); 
                                    if(currentDate >= oProdRepl.APTS_Valid_From__c && currentDate < oProdRepl.APTS_Valid_To__c && oProdRepl.Plant_status__c == 'SAP_01')
                                    {
                                            tempExtID = oProdRepl.APTS_Replacement_Product_Code__c + '|' + oProdRepl.APTS_Sales_Org__c;
                                            mapExtIDWithProdReplCode.put(tempExtID, oProdRepl);
                                    }                                    
                            }
                            if(!lstProductReplacementCodes.isEmpty())
                            {
                                    //Do updates to the sales Org
                                    /* Make the existing Sales Org data against the APTS_Sales_Org__c in Product replacement record as Blocked for selling.
                                    - check if ther exists sales org data with combi replacedByPRod|sales org (External ID)
                                    - Else Create new entry on the sales org data against that product, copy old values and set APTS_Replaced_by__c = new replaced code from product replacement record
                                    - Update the external ID field with the replaced product code whereever applicable
                                    - Check if the current date on > Valid from & < valid to */
                                    Map<id, APTS_Sales_Org_Data__c> mapSalesOrgData = new Map<Id, APTS_Sales_Org_Data__c>([Select id, APTS_Sales_Org_Data_Ext_ID__c, APTS_Sales_Org_Data_Name__c, APTS_Replaced_by__c, APTS_Product__c, APTS_Distribution_chain_specific_materia__c, APTS_Product_Code__c, APTS_Price_List__c,APTS_Selling_Unit__c, APTS_Cost_Price_Unit__c, APTS_Sales_Org_Description__c, APTS_Distribution_channel__c, APTS_Default_Delivery_Plant__c, APTS_Profit_Center__c, APTS_SAP_Local_Hierarchy_Code__c, APTS_Cost_Price__c, APTS_VAT_Indicator__c, APTS_Workshop_Indicator__c, APTS_Item_category_group_from_material_m__c, APTS_Tax_Classification_Material_1__c, APTS_Tax_Classification_Material_2__c, APTS_Tax_Classification_Material_3__c, APTS_Product_web_enabled__c, APTS_Product_web_enabled_backend__c, Web_Enabled__c from APTS_Sales_Org_Data__c where APTS_Sales_Org_Data_Ext_ID__c in : mapExtIDWithProdReplCode.KeySet() OR APTS_Sales_Org_Data_Ext_ID__c in : mapExtIDWithProdReplCodeOriginal.KeySet()]);
                                    system.debug('160 :: mapSalesOrgData :: '+mapSalesOrgData.values());
                                    List<APTS_Sales_Org_Data__c> lstSalesOrgDataToUpsert = new List<APTS_Sales_Org_Data__c>();
                                    List<APTS_Sales_Org_Data__c> lstSalesOrgDataToInsert = new List<APTS_Sales_Org_Data__c>();
                                    
                                    if(!mapSalesOrgData.isEmpty())
                                    {
                                            Map<string, APTS_Sales_Org_Data__c> mapSalesOrgDataWithExtID = new Map<string, APTS_Sales_Org_Data__c>();
                                            for(APTS_Sales_Org_Data__c oSalesOrg : mapSalesOrgData.Values())
                                            {
                                                    mapSalesOrgDataWithExtID.put(oSalesOrg.APTS_Sales_Org_Data_Ext_ID__c,oSalesOrg);                                                        
                                            }
                                            for(APTS_Product_Replacement_Codes__c oProdRepl : mapExtIDWithProdReplCodeOriginal.Values())
                                            {
                                                    string tempReplaceExtID = oProdRepl.APTS_Replacement_Product_Code__c + '|' + oProdRepl.APTS_Sales_Org__c;
                                                    string tempExtID = oProdRepl.APTS_Product_Code__c + '|' + oProdRepl.APTS_Sales_Org__c;
                                            
                                                    if(!mapSalesOrgDataWithExtID.isEmpty())
                                                    {
                                                            //Get the sales Org with original Product code ExtID and make it blocked for selling
                                                            if(mapSalesOrgDataWithExtID.KeySet().contains(tempExtID))
                                                            {
                                                                    APTS_Sales_Org_Data__c tempSalesOrg = mapSalesOrgDataWithExtID.get(tempExtID);                                                               
                                                                    tempSalesOrg.APTS_Distribution_chain_specific_materia__c = 'SAP_02';      
                                                                    tempSalesOrg.APTS_Replaced_by__c = ''; 
                                                                    lstSalesOrgDataToUpsert.add(tempSalesOrg);
                                                            }  
                                                            //Get the sales org with replaced ExtID combination
                                                            if(mapSalesOrgDataWithExtID.KeySet().contains(tempReplaceExtID))
                                                            {
                                                                            APTS_Sales_Org_Data__c tempSalesOrg = mapSalesOrgDataWithExtID.get(tempReplaceExtID);                                                                
                                                                            tempSalesOrg.APTS_Product__c = oProdRepl.APTS_Product__c;
                                                                            tempSalesOrg.APTS_Product_Code__c = oProdRepl.APTS_Product_Code__c;
                                                                            tempSalesOrg.APTS_Distribution_chain_specific_materia__c = oProdRepl.Plant_status__c;
                                                                            tempSalesOrg.APTS_Replaced_by__c = oProdRepl.APTS_Replacement_Product_Code__c;                                                         
                                                                            lstSalesOrgDataToUpsert.add(tempSalesOrg);
                                                            }
                                                            else {
                                                                    //Insert new Sales Org - clone                                                                                                                      
                                                                    APTS_Sales_Org_Data__c oSalesOrgOriginal = mapSalesOrgDataWithExtID.get(tempExtID);
                                                                    APTS_Sales_Org_Data__c oSalesOrg = oSalesOrgOriginal.clone(false, true, false, false);
                                                                    oSalesOrg.id = null;
                                                                    oSalesOrg.APTS_Distribution_chain_specific_materia__c = oProdRepl.Plant_status__c;       
                                                                    oSalesOrg.APTS_Sales_Org_Data_Ext_ID__c = tempReplaceExtID;
                                                                    oSalesOrg.APTS_Replaced_by__c = oProdRepl.APTS_Replacement_Product_Code__c; 
                                                                    oSalesOrg.APTS_Product__c = oProdRepl.APTS_Product__c;
                                                                    oSalesOrg.APTS_Product_Code__c = oProdRepl.APTS_Product_Code__c;
                                                                    system.debug('208 :: oSalesOrg.APTS_Replaced_by__c :: '+oProdRepl.APTS_Replacement_Product_Code__c);
                                                                    lstSalesOrgDataToUpsert.add(oSalesOrg);                                                                   
                                                                }          
                                                    }
                                            }
                                            system.debug('212 :: lstSalesOrgDataToUpsert :: '+lstSalesOrgDataToUpsert);
                                            if(!lstSalesOrgDataToUpsert.isEmpty())
                                            {
                                                    disableSalesOrgDataTrigger(true);
                                                    database.upsert(lstSalesOrgDataToUpsert, false);  
                                                    disableSalesOrgDataTrigger(false);                                                 
                                            }
                                            /*if(!lstSalesOrgDataToInsert.isEmpty())
                                            {
                                                disableSalesOrgDataTrigger(true);
                                                Database.Insert(lstSalesOrgDataToInsert, false);
                                                disableSalesOrgDataTrigger(false);
                                                system.debug('lstSalesOrgDataToInsert :: '+lstSalesOrgDataToInsert);
                                            } */
                                        }                                    
                            }
                    }
            }
            catch(Exception e){
                APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Batch',e.getMessage()+'\n\n'+e.getStackTraceString() ,'Product Replacement Code','','CPQ',false,true,'cpqerror@accenture.com',true);             
            }
    }
    public void disableSalesOrgDataTrigger(Boolean bDisableTrigger)
    {        
        if(bDisableTrigger)
        {
            TriggerSettings__c oTriggerSettings = new TriggerSettings__c();
            if(TriggerSettings__c.getValues(UserInfo.getUserId())==null){            
                oTriggerSettings.SetupOwnerId = UserInfo.getUserId();
                oTriggerSettings.SalesOrgDataTrigger__c = false;                
                deleteTriggerSettingsEntry = true;
            }
            else{
                oTriggerSettings = TriggerSettings__c.getValues(UserInfo.getUserId());    
                if(oTriggerSettings.SalesOrgDataTrigger__c){ 
                    updateTriggerSettingsEntry = true;   
                    oTriggerSettings.SalesOrgDataTrigger__c=false;                    
                }
            }
            Database.Upsert(oTriggerSettings, false);
        }
        else {
            TriggerSettings__c oTriggerSettings = TriggerSettings__c.getValues(UserInfo.getUserId());    
            if(deleteTriggerSettingsEntry){
                 Database.delete(oTriggerSettings, false);
            }else if(updateTriggerSettingsEntry) {
                oTriggerSettings.SalesOrgDataTrigger__c = true;
                Database.update(oTriggerSettings, false);
            }    
        }
    }
    //V1.3 ++ >>
}