/*
* Description: Trigger handler class to populate Replaced Product Code in Price list Item
* Class Name: APTS_ProductRepalcementTriggerHandler
* Created by: Shahul (Shahul.nizam.moideen@accenture.com)
v1.1 - DQ-4000/DQ-4389 - 25/10/2020 - Lavanya
* Date Created: 08/1/2017
*/


public with sharing class APTS_ProductRepalcementTriggerHandler implements ITriggerHandler
{
public static final String ERRORCLASS='ProductReplacementcode';

public void BeforeInsert(List<SObject> newItems){}
public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){}
public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems)
{
//DQ-4000
List<APTS_Product_Replacement_Codes__c> newprcList = (List<APTS_Product_Replacement_Codes__c>) newList;
PriceListItemUpdate(newprcList);
//DQ-4000
}

public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems)
{  
//DQ-4000
List<APTS_Product_Replacement_Codes__c> newprcList = (List<APTS_Product_Replacement_Codes__c>) newList;
PriceListItemUpdate(newprcList);
//DQ-4000
}

public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}

public Boolean IsDisabled(){return false;}

/*Method Name :  PriceListItemUpdate
Description : Does update on PLI for APTS_Product_Code__c- Modified as part of DQ-4000
*/
    
public void PriceListItemUpdate(List<APTS_Product_Replacement_Codes__c> ProductReplacementCodeList)
{
        try
        {
        Set<String> setProductIds = new Set<String>();
        Set<String> setSalesOrg = new Set<String>();
        list<String> setReplaceProdCode = new list<String>();
        Map<String,String> mapProdReplProd = new Map<String,String>();
        List<String> lstreplacementcodes = new List<String>();   
        list<Apttus_Config2__PriceListItem__c> UpdatePlilist=new list<Apttus_Config2__PriceListItem__c>();
        for(APTS_Product_Replacement_Codes__c PRC:ProductReplacementCodeList)
        {//DQ-4389 - PLI update Works only for valid date
        if(PRC.APTS_Valid_From__c <= System.now())
        {
        setProductIds.add(PRC.APTS_Product_Code__c);
        setSalesOrg.add(PRC.APTS_Sales_Org__c);  
        mapProdReplProd.put(PRC.APTS_Product_Code__c,PRC.APTS_Replacement_Product_Code__c);
        }
        } 
        
         
        list<Apttus_Config2__PriceListItem__c> ReplaceCodeInPLI=[select id,name,Apttus_Config2__ProductCode__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductCode__c IN:setProductIds AND Apttus_Config2__PriceListId__r.APTS_SalesOrg__c IN:setSalesOrg order by createddate asc];
        
        
        for (Apttus_Config2__PriceListItem__c PLI: ReplaceCodeInPLI)
        {
        List<String> replacementcodesForPLI = new List<String>();
        if(!mapProdReplProd.isEmpty() && mapProdReplProd.get(PLI.Apttus_Config2__ProductCode__c) != null)
        {
        PLI.APTS_Product_Code__c= mapProdReplProd.get(PLI.Apttus_Config2__ProductCode__c);          
        UpdatePlilist.add(PLI);
        }
        }
        if(UpdatePlilist.size()>0)
        {
        update UpdatePlilist;
        
        }        
}catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), ERRORCLASS, ex.getMessage() + '\n\n' + ex.getStackTraceString() ,ERRORCLASS,ERRORCLASS,ERRORCLASS, false, false, null, true);}  }

}