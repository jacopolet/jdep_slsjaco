/**********************************************************************************
 * @Author: 
 * @Company: Accenture
 * @Description: Handles the Contents/file creation for Bizisland CER
 * @Created Date: Mar 25, 2019
 * @History:
 *      <Name>              <Date>          <Description>
 *                 25.03.2019       Created
 **********************************************************************************/
 global class APTS_CERBizIslandExt  implements Database.Batchable<sObject>, Database.Stateful { 

 
     global List<String> csvRowValues = new List<String>();

     global Database.QueryLocator start(Database.BatchableContext bc) {
     string query = 'SELECT Id, Sales_Organization__c ,Distribution_Channel__c ,'+
                        ' ID_Level__c , Agreement_number__c , Customer_Number__c , Product_number__c ,'+
                        ' List_Price__c ,   Net_Price_Incl_Indirect_Tax__c , Customer_Currency__c , '+
                        'Base_unit_of_measure__c , Discount_in_customer_currency__c , '+
                        'Indirect_tax_amount_in_customer_currency__c ,  Status__c, isExecuted__c '+
                    'FROM CER_Bizisland__c WHERE isExecuted__c = false AND CreatedDate = TODAY LIMIT 100000';
     return Database.getQueryLocator(query);
     }
     
     global void execute (Database.BatchableContext BC, list<CER_Bizisland__c> scope) {
        String strCSVContent='';
        for(CER_Bizisland__c cerBiz : scope){
             strCSVContent = cerBiz.Sales_Organization__c+','+cerBiz.Distribution_Channel__c+','+cerBiz.ID_Level__c+','+cerBiz.Agreement_number__c+',';
             strCSVContent += cerBiz.Customer_Number__c+','+cerBiz.Product_number__c+','+cerBiz.List_Price__c+','+cerBiz.Net_Price_Incl_Indirect_Tax__c+','+cerBiz.Customer_Currency__c+',';
             strCSVContent += cerBiz.Base_unit_of_measure__c+','+cerBiz.Discount_in_customer_currency__c+','+cerBiz.Indirect_tax_amount_in_customer_currency__c+','+cerBiz.Status__c;
             csvRowValues.add(strCSVContent);
             cerBiz.isExecuted__c = true;
        }

        Database.update((List<CER_Bizisland__c>)scope, false);
     }
     
     global void finish(Database.BatchableContext BC) {

        try
        {
             String csvColumnHeader;
             Bonsai__c cs = Bonsai__c.getAll().values();
            Date d=system.today();
            String Bon='Bonsai Request'+' '+d;
            list<BizIsland_Request__c> biz=[ SELECT Id, Name,Version__c FROM BizIsland_Request__c where name=:Bon];
            if(!biz.isEmpty()){
            csvColumnHeader ='Sales Organization,Distribution Channel,ID Level,Agreement Number,Customer Number,Product Number,List Price,Net Price Incl. Indirect Tax,Customer Currency,Base unit of measure,Discount in customer currency,Indirect tax amount in customer currency,Status\n';
            String csvFile = csvColumnHeader + String.join(csvRowValues,'\n');
                         
            APTS_BizIslandContentGenerator bizz=new APTS_BizIslandContentGenerator();
                 if(cs.Full_Load__c){
                    String documentName = 'FULL REPORT CUSTPRICE_WEBSHOP';
                    bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
                        
                  }           
            }
            List<CER_Bizisland__c> listCERBIZ = [SELECT Id FROM CER_Bizisland__c WHERE isExecuted__c = false AND CreatedDate = TODAY LIMIT 10000];
            if(!listCERBIZ.isEmpty()){
                APTS_CERBizIslandExt prcAgain = new APTS_CERBizIslandExt();
                Database.executeBatch(prcAgain,200);
            }
            else {
                APTS_PriceListitemBizIsland prc = new APTS_PriceListitemBizIsland();
                Database.executeBatch(prc,200);
            }

        }
        catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(),'Batch', e.getStackTraceString()+'::Line Number:'+e.getLineNumber() ,'APTS_Contract_Entitlement_Repository__c', '' ,'CPQ', False, False,'', true);
        } 
     }
 }