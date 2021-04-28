/*************************************************************
@Name: APTS_OrderLineItemWrapper
@Author: Galin Georgiev
@CreateDate: 25-01-2018
@Description: Order line item wrapper class
@UsedBy: APTS_CreateOrderController, APTS_OrderUtils
******************************************************************/
//Added Custom logging --> Sethukkarasi

public class APTS_OrderLineItemWrapper {

    public Boolean selected {get; set;}
    public Apttus_Config2__OrderLineItem__c oOrderLineItem {get; set;}
    public Integer returnedQuantity {get; set;}
    private static final String EMAIL = System.Label.APTS_Email;

    public APTS_OrderLineItemWrapper() {
        //try{
        this.selected = false;
        this.oOrderLineItem = null;
        this.returnedQuantity = 0;
         /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
    }   

    public APTS_OrderLineItemWrapper(Boolean selected, Apttus_Config2__OrderLineItem__c oOrderLineItem, Integer returnedQuantity) {
        //try{
        this.selected = selected;
        this.oOrderLineItem = oOrderLineItem;
        this.returnedQuantity = returnedQuantity;
         /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
    }
}