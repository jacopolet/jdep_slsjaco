/*************************************************************
@Name: APTS_ReturnOrderBatch 
@Author: Sneha Jaiwant
@CreateDate: 18-11-2020
@Description: DQ4474 To update de-installation orders which stuck with order header Status Custom “Activated”/"Returned". 
******************************************************************/


global without sharing class APTS_ReturnOrderBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private String query;
    
    private List<Apttus_Config2__OrderLineItem__c> orderLineItemToUpdateList = new List<Apttus_Config2__OrderLineItem__c> ();
    
    global APTS_ReturnOrderBatch() {
        
        query = 'SELECT Id, APTS_Installation_Date_Authorized__c, APTS_De_installation_Date_Authorized__c,Apttus_Config2__OrderId__r.APTS_Invoice__c,' +
            'Apttus_Config2__OrderId__r.APTS_GoodsIssue_Status__c,APTS_Is_Primary_L1_Line__c, Apttus_Config2__ActivatedDate__c,' +
            'Apttus_Config2__OrderId__c, APTS_SAP_OrderType__c,Apttus_Config2__Status__c,Apttus_Config2__LineType__c,Apttus_Config2__OrderId__r.Apttus_Config2__Status__c'+ 
            ' FROM Apttus_Config2__OrderLineItem__c ' +
            'WHERE' + 
            '(APTS_SAP_OrderType__c = \'XB13\' and APTS_Is_Primary_L1_Line__c=true and (Apttus_Config2__Status__c=\'Activated\' OR Apttus_Config2__Status__c=\'Returned\') and ((Apttus_Config2__OrderId__r.Apttus_Config2__Status__c = \'Activated\' OR Apttus_Config2__OrderId__r.Apttus_Config2__Status__c = \'Returned\' OR Apttus_Config2__OrderId__r.Apttus_Config2__Status__c = \'Partially Fulfilled\' OR Apttus_Config2__OrderId__r.Apttus_Config2__Status__c = \'Fulfilled\') and  Apttus_Config2__OrderId__r.APTS_Status__c != \'Completed\'))';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext BC, List<Apttus_Config2__OrderLineItem__c> scope) {
        Set<Id> orderIdSet = new Set<Id> ();
         Set<Id> oliorderIdSet = new Set<Id> ();
        Set<Id> oliset= new Set<Id> ();
            
        try{
            for(Apttus_Config2__OrderLineItem__c oli:scope){
                if(oli.APTS_Is_Primary_L1_Line__c== true && oli.Apttus_Config2__Status__c =='Activated'){
                oliset.add(oli.id);
                oliorderIdSet.add(oli.Apttus_Config2__OrderId__c);
                }
                
                
            }         
            
            List<Apttus_Config2__Order__c> orderList=new List<Apttus_Config2__Order__c>();
            Apttus_Config2__Order__c order;
            Set<Id> oLineset= new Set<Id> ();
            
            for(Apttus_Config2__OrderFulfillmentLineItem__c ofli:[select id,Apttus_Config2__OrderId__c, APTS_GoodsIssue_Status__c,APTS_Fulfilled_Quantity__c,APTS_Material_Number_SAP__c,Apttus_Config2__OrderLineItemId__r.APTS_Replaced_Product_Code__c,Apttus_Config2__OrderLineItemId__c   from Apttus_Config2__OrderFulfillmentLineItem__c where Apttus_Config2__OrderId__c in: oliorderIdSet and (Apttus_Config2__OrderLineItemId__c in: oliset OR Apttus_Config2__OrderLineItemId__r.APTS_Is_Primary_L1_Parent__c in: oliset) and APTS_GoodsIssue_Status__c='Completely Processed' and APTS_Fulfilled_Quantity__c = 1]){
                if(ofli.APTS_Material_Number_SAP__c != null && ofli.APTS_Material_Number_SAP__c.contains(ofli.Apttus_Config2__OrderLineItemId__r.APTS_Replaced_Product_Code__c)){
                    orderIdSet.add(ofli.Apttus_Config2__OrderId__c);
                    oLineset.add(ofli.Apttus_Config2__OrderLineItemId__c);
                    
                }
                
            }
            for(Apttus_Config2__OrderLineItem__c ollst:[select id,APTS_Is_Primary_L1_Parent__c,Apttus_Config2__OrderId__c,Apttus_Config2__Status__c,Apttus_Config2__OrderId__r.APTS_Invoice__c,Apttus_Config2__OrderId__r.Apttus_Config2__Status__c from Apttus_Config2__OrderLineItem__c where (Id IN:oLineset OR APTS_Is_Primary_L1_Parent__c IN:oLineset)] ){
                ollst.Apttus_Config2__Status__c ='Returned';
                ollst.APTS_Status__c  ='Returned';
                orderLineItemToUpdateList.add(ollst);
              
            }
            APTS_OrderUtils.stopOrderLineItemTrigger();
            APTS_OrderUtils.stopOrderTrigger();
            database.update(orderLineItemToUpdateList ,false);
            
           Map<Id,Apttus_Config2__OrderLineItem__c> oliMap = new Map<Id,Apttus_Config2__OrderLineItem__c>([select id,APTS_Is_Primary_L1_Parent__c,Apttus_Config2__OrderId__c,Apttus_Config2__Status__c,Apttus_Config2__OrderId__r.APTS_Invoice__c,Apttus_Config2__OrderId__r.Apttus_Config2__Status__c,Apttus_Config2__OrderId__r.APTS_Status__c from Apttus_Config2__OrderLineItem__c where Apttus_Config2__OrderId__c In:orderIdSet and APTS_Is_Primary_L1_Line__c= true]); 
           Map<Id,Integer> mapOrderwithBundles = new Map<Id,Integer>();
          
           for(Apttus_Config2__OrderLineItem__c orderline:oliMap.values()){
           integer count=0;
           if(orderline.Apttus_Config2__Status__c != 'Returned'){
           if(mapOrderwithBundles.isEmpty() || !mapOrderwithBundles.containsKey(orderline.Apttus_Config2__OrderId__c) ){
           
           mapOrderwithBundles.put(orderline.Apttus_Config2__OrderId__c,count+1);
           }
           else{
           Integer countoli = mapOrderwithBundles.get(orderline.Apttus_Config2__OrderId__c);
            mapOrderwithBundles.put(orderline.Apttus_Config2__OrderId__c,countoli+1);
           }
           }
            else{
             mapOrderwithBundles.put(orderline.Apttus_Config2__OrderId__c,0);
            }
            }
            for(Apttus_Config2__Order__c ord:[select id ,APTS_Invoice__c,Apttus_Config2__Status__c,APTS_Status__c from Apttus_Config2__Order__c where  (id IN: orderIdSet and (Apttus_Config2__Status__c='Activated' OR Apttus_Config2__Status__c='Fulfilled') ) OR (Apttus_Config2__Status__c='Returned' and APTS_Status__c NOT IN('Completed','Cancelled'))]){
            integer tempcount =mapOrderwithBundles.get(ord.Id);
            if(tempcount == 0 || ord.Apttus_Config2__Status__c =='Returned')   
             { 
            if(ord.APTS_Invoice__c != null){
                    ord.APTS_Status__c ='Completed';
                    ord.Apttus_Config2__Status__c='Returned';

            }
            else{
                    ord.APTS_Status__c ='Returned';
                    ord.Apttus_Config2__Status__c='Returned';

            }
            orderList.add(ord);
            }
            }
            
            APTS_OrderUtils.stopOrderTrigger();
            database.update(orderList,false);
            
        }
        catch(Exception e){
         APTS_CustomLogging.createErrorLog('Return Order Batch', APTS_CPQConstants.APEX_NAME, 'Line # ' + e.getLineNumber() + '_' + e.getMessage() , 'Order', null, 'OM', false, false, null, true);

        }
    }
    
    
    
    
    
    global void finish(Database.BatchableContext BC) {
            APTS_OrderUtils.startOrderTrigger();
            APTS_OrderUtils.startOrderLineItemTrigger();
            
    }
}