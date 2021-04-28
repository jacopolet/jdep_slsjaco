/*************************************************************
@Name: APTS_ATPResultWrapper
@Author: Galin Georgiev
@CreateDate: 25-01-2018
@Description: Class to hold ATP results
@UsedBy: APTS_OrderWSUtils
******************************************************************/
//Added Custom logging --> Sethukkarasi

public class APTS_ATPResultWrapper {

    public List<Apttus_Config2__LineItem__c> lineItemsToUpdateList;
    public List<Apttus_Config2__TaxBreakup__c> taxBreakupsToInsertList;
    public List<APTS_Order_Freight_Data__c> freightDataToInsertList;
    private static final String EMAIL = System.Label.APTS_Email;

    public APTS_ATPResultWrapper(){
        //try{

        this.lineItemsToUpdateList = new List<Apttus_Config2__LineItem__c>();
        this.taxBreakupsToInsertList = new List<Apttus_Config2__TaxBreakup__c>();       
        this.freightDataToInsertList = new List<APTS_Order_Freight_Data__c>();
          /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
    }

    public APTS_ATPResultWrapper(List<Apttus_Config2__LineItem__c> lineItemsToUpdateList, List<Apttus_Config2__TaxBreakup__c> taxBreakupsToInsertList, List<APTS_Order_Freight_Data__c> freightDataToInsertList) {
        //try{

        this.lineItemsToUpdateList = lineItemsToUpdateList;
        this.taxBreakupsToInsertList = taxBreakupsToInsertList;     
        this.freightDataToInsertList = freightDataToInsertList;
          /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
    }
}