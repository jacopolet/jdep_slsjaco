public class APTS_OrderApprovalEmailController{

    public Id orderId {get; set;}
    public Apttus_Config2__Order__c getorder(){
        Apttus_Config2__Order__c order = [select name,Id,Owner.Name from Apttus_Config2__Order__c where Id =: orderId];
        return order;
    }
    public List<Apttus_Config2__OrderLineItem__c> getorderLineItems(){
        List<Apttus_Config2__OrderLineItem__c> listOrderLineItems = [select id,Apttus_Config2__AdjustmentAmount__c,Apttus_Config2__AdjustmentType__c,name from Apttus_Config2__OrderLineItem__c where Apttus_Config2__OrderId__c =: orderId];
        return listOrderLineItems;
    }
}