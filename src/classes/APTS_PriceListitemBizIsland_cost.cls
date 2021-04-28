/**********************************************************************************
 * @Author: Keerthana
 * @Company: Accenture
 * @Description: Handles the Contents/file creation for Bizisland Pricelistitem and cost
 * @Created Date: Oct 4, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      Keerthana          10.09.2018       Created
 **********************************************************************************/
global class APTS_PriceListitemBizIsland_cost implements Database.Batchable<sObject>, Database.Stateful {
   
    global String csvColumnHeader;
    global List<String> csvRowValues = new List<String>();
   
    global Database.QueryLocator start(Database.BatchableContext BC){
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        String query;
        if(customSetting.Delta_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'PriceListitemBizIsland_costDelta'][0];
            query = bizmdt.APTS_Query__c; 
        }else if(customSetting.Full_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'PriceListitemBizIsland_costFull'][0];
            query = bizmdt.APTS_Query__c;
        }else{
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'PriceListitemBizIsland_costDelta'][0];
            query = bizmdt.APTS_Query__c;
        }
            return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        String Status;
        String salesorg = '';
        String disChan = '';
        String uom = '';
        //String plan ='';
        for(Apttus_Config2__PriceListItem__c p : (List<Apttus_Config2__PriceListItem__c>) scope){
        if(p.CreatedDate.date()==System.Today())
            Status = 'New';
            else if(p.LastModifiedDate.date() ==System.Today())
            Status='Modified';
            else 
            Status='Not Modified';
            if((Status == 'Modified' || Status == 'New') && p.isDeleted == true)
            Status = 'Deleted';
            if(p.APTS_Sales_Org__c != NULL && p.APTS_Sales_Org__c.contains('SAP_')){
                salesorg = p.APTS_Sales_Org__c.replace('SAP_','');
            }else if(p.APTS_Sales_Org__c != NULL){
                salesorg = p.APTS_Sales_Org__c;
            }
            if(p.APTS_Distribution_Channel__c != NULL && p.APTS_Distribution_Channel__c.contains('SAP_')){
                disChan = p.APTS_Distribution_Channel__c.replace('SAP_','');
            }else if(p.APTS_Distribution_Channel__c != NULL){
               disChan = p.APTS_Distribution_Channel__c;
            }
                                                                                                                                                                                                    if(p.Apttus_Config2__PriceUom__c != NULL && p.Apttus_Config2__PriceUom__c.contains('SAP_')){
                uom = p.Apttus_Config2__PriceUom__c.replace('SAP_','');
            }else if (p.Apttus_Config2__PriceUom__c != NULL){
                uom = p.Apttus_Config2__PriceUom__c;
            }
            /*if(p.APTS_Plant__c != NULL && p.APTS_Plant__c.contains('SAP_')){
                plan = p.APTS_Plant__c.replace('SAP_','');
            }else if (p.APTS_Plant__c != NULL){
                plan = p.APTS_Plant__c;
            }*/
    
            String rowStrn = salesorg+','+disChan+','+p.APTS_Plant__c+','+p.Apttus_Config2__ProductCode__c+','+p.Apttus_Config2__Cost__c+','+p.CurrencyIsoCode+','+p.Apttus_Config2__ProductId__r.APTS_Cost_Price_Unit__c+','+uom+','+Status;
            csvRowValues.add(rowStrn);
            salesorg = '';
            disChan = '';
            uom = '';
        }
   
    }
    global void finish(Database.BatchableContext BC){
    
        Bonsai__c cs = Bonsai__c.getAll().values();
        Date d=system.today();
        String Bon='Bonsai Request'+' '+d;
        list<BizIsland_Request__c> biz=[SELECT Id, Name,Version__c FROM BizIsland_Request__c where name=:Bon];
            if(!biz.isEmpty()){
                csvColumnHeader ='Sales Organization,Distribution Channel,Plant,Product Number,Cost Price,Cost Price Currency,Price Unit,Base Unit of Measure,Status\n';
                String csvFile = csvColumnHeader + String.join(csvRowValues,'\n');
                APTS_BizIslandContentGenerator bizz=new APTS_BizIslandContentGenerator();
                    if(cs.Delta_Load__c){
                         String documentName = ' DELTA REPORT PROD_COST_WEBSHOP';
                         bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
                    }else if(cs.Full_Load__c){
                        String documentName = 'FULL REPORT PROD_COST_WEBSHOP';
                        bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
                    }
                biz[0].APTS_Notify_Bonsai__c = true;
                update biz;
            }
            
        }
    }