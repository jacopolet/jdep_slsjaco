global class APTS_OLIActivationBatch implements Database.Batchable<sObject>,Database.Stateful{
    Set<String> ORDER_TYPE = new Set<String> {'Standard Order','Route Sales Order', 'Operating Order'};
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
    List<String> assetlist =new List<String>();
    String q1 = 'Select id,Name, APTS_Asset_Line_Item__c, APTS_Error_Message__c, APTS_Has_Error__c, APTS_Is_Updated__c from APTS_Asset_Correction_Configuration__c';
   
        List<APTS_Asset_Correction_Configuration__c> lstorder = Database.query(q1);
            for(APTS_Asset_Correction_Configuration__c cs:lstorder){
            assetlist.add(cs.Name);   
        }
        String query='SELECT id,Apttus_Config2__Status__c, Apttus_Config2__ActivatedDate__c, Apttus_Config2__ReadyForBillingDate__c,APTS_Requested_Delivery_Date__c, APTS_Status__c, Apttus_Config2__AssetLineItemId__c from Apttus_Config2__OrderLineItem__c where id IN:assetlist and Apttus_Config2__OrderId__r.APTS_Order_Type__c IN:ORDER_TYPE order by CreatedDate desc';
        
    return Database.getQueryLocator(query);
}
    global void execute(Database.BatchableContext BC, List<Apttus_Config2__OrderLineItem__c> scope){
      
       Map<Id, Apttus_Config2__OrderLineItem__c> orderLineItemToActivateMap = new Map<Id, Apttus_Config2__OrderLineItem__c>();
       try{
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : scope) {
             if(oOrderLineItem.APTS_Status__c=='Fulfilled' &&  oOrderLineItem.Apttus_Config2__ActivatedDate__c== null && oOrderLineItem.Apttus_Config2__ReadyForBillingDate__c == null){
                oOrderLineItem.Apttus_Config2__ActivatedDate__c = (oOrderLineItem.APTS_Requested_Delivery_Date__c != null) ? oOrderLineItem.APTS_Requested_Delivery_Date__c : DateTime.now();
                oOrderLineItem.Apttus_Config2__ReadyForBillingDate__c = (oOrderLineItem.APTS_Requested_Delivery_Date__c != null) ? oOrderLineItem.APTS_Requested_Delivery_Date__c : DateTime.now();
                oOrderLineItem.APTS_Status__c = APTS_OrderConstants.ACTIVATED;
                
                orderLineItemToActivateMap.put(oOrderLineItem.Id, oOrderLineItem);
                 
        }
            
           
        }
         if (!orderLineItemToActivateMap.isEmpty()) {
               System.enqueueJob(new APTS_ActivateOrderQueueable(orderLineItemToActivateMap.values()));
         }
           
    }catch(Exception e){
    }
    }
    global void finish(Database.BatchableContext BC){
         
            }
    
}