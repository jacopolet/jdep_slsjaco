/**********************************************************************************
 * @Author: Jason Mactal
 * @Company: Accenture
 * @Description: Gets the value of Warehousing Cost for Agreement
 * @Created Date: May 7, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      5.07.2018       Created
 * 
 **********************************************************************************/
public with sharing class APTS_WarehousingCost {
    
    /*@methodName - getWarehousingCost
    * @description - method used to get Warehousing Cost
    * @param - List<Apttus__APTS_Agreement__c>
    * @return - List<Apttus__APTS_Agreement__c>
    */
    public void getWarehousingCost (List<Apttus__APTS_Agreement__c> agreementList) {
        
        try{
            Set<string> preferredWayofDeliverySet = new Set<string>();
            Set<string> salesOrgsMap = new Set<string>();
            Map<string,List<APTS_Warehousing_Cost__c>> warehousingCostMap= new Map<string,List<APTS_Warehousing_Cost__c>>();
            
            for(Apttus__APTS_Agreement__c agg: agreementList){
                if(agg.APTS_Preferred_way_of_ingredient_deliver__c != NULL && string.isNotBlank(agg.APTS_Preferred_way_of_ingredient_deliver__c))
                preferredWayofDeliverySet.add(agg.APTS_Preferred_way_of_ingredient_deliver__c);
                salesOrgsMap.add(agg.APTS_Region__c);
            }
            
            for(APTS_Warehousing_Cost__c whCost: [SELECT Id, APTS_WC_PrefDelivery__c, APTS_WC_SalesOrg__c, APTS_WC_WarehouseCost__c, APTS_WC_DistributionCost__c, APTS_Start_Date__c, APTS_End_Date__c
                                                         FROM APTS_Warehousing_Cost__c
                                                         WHERE APTS_WC_PrefDelivery__c IN: preferredWayofDeliverySet AND APTS_WC_SalesOrg__c IN: salesOrgsMap]){
                if (warehousingCostMap.containsKey(whCost.APTS_WC_PrefDelivery__c)) {
                    warehousingCostMap.get(whCost.APTS_WC_PrefDelivery__c).add(whCost);
                } else {
                    warehousingCostMap.put(whCost.APTS_WC_PrefDelivery__c, new List<APTS_Warehousing_Cost__c> {whCost});
                }
            }
            
            //Set the warehousing cost depending on the Preferred Way of Delivery, SalesOrg, and Pricing Date
            for(Apttus__APTS_Agreement__c agg: agreementList){
                if(agg.APTS_Preferred_way_of_ingredient_deliver__c != NULL && agg.APTS_Region__c != NULL && agg.APTS_PricingDate__c !=NULL && warehousingCostMap.containsKey(agg.APTS_Preferred_way_of_ingredient_deliver__c)){
                    for(APTS_Warehousing_Cost__c whCost: warehousingCostMap.get(agg.APTS_Preferred_way_of_ingredient_deliver__c)){
                        if(agg.APTS_Region__c == whCost.APTS_WC_SalesOrg__c && agg.APTS_PricingDate__c >= whCost.APTS_Start_Date__c && agg.APTS_PricingDate__c <= whCost.APTS_End_Date__c){
                            agg.APTS_WarehousingCost__c = whCost.id;
                            agg.APTS_Warehousing_Cost__c = whCost.APTS_WC_WarehouseCost__c;
                            agg.APTS_Distribution_Cost__c = whCost.APTS_WC_DistributionCost__c;
                        }
                    }
                }
            }
        }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Agreement', null,'CPQ',false,true,'cpqerror@accenture.com',true);
        }
        
    }
}