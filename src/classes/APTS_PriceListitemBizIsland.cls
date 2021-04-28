/**********************************************************************************
 * @Author: Keerthana
 * @Company: Accenture
 * @Description: Handles the Contents/file creation for Bizisland Product
 * @Created Date: Oct 10, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      Keerthana              10.10.2018       Created
 Defect 23065 - Changing field mapping of List Price Local Currency ExIndirect Tax,Local Currency List Price
 **********************************************************************************/
global class APTS_PriceListitemBizIsland implements Database.Batchable<sObject>, Database.Stateful {
   
    global String csvColumnHeader;
    global List<String> csvRowValues = new List<String>();
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        String query;
        //Set<string> salesorganization = new set<string>{'SAP_0975'};
        if(customSetting.Delta_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'PriceListitemBizIslandDelta'][0];
            query = bizmdt.APTS_Query__c; 
        }else if(customSetting.Full_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'PriceListitemBizIslandFull'][0];
            query = bizmdt.APTS_Query__c;
        }else{
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'PriceListitemBizIslandDelta'][0];
            query = bizmdt.APTS_Query__c;
        }
            return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        String Status;
        String Pricelist;
        String salesorg = '';
        String disChan = '';
        String uom = '';
        for(Apttus_Config2__PriceListItem__c p : (List<Apttus_Config2__PriceListItem__c>) scope){
        if(p.CreatedDate.date()==System.Today())
            Status = 'New';
            else if(p.LastModifiedDate.date() ==System.Today())
            Status='Modified';
            else 
            Status='Not Modified';
            if((Status == 'Modified' || Status == 'New') && p.isDeleted == true)
            Status = 'Deleted';
            if((!p.Apttus_Config2__PriceListId__r.Name.contains('Export')) && p.Apttus_Config2__PriceListId__r.CurrencyIsoCode=='DKK')
            Pricelist='DK10';
            else if(p.Apttus_Config2__PriceListId__r.Name.contains('Export') && p.Apttus_Config2__PriceListId__r.CurrencyIsoCode=='DKK')
            Pricelist='DK30';
            else if(p.Apttus_Config2__PriceListId__r.Name.contains('Export') && p.Apttus_Config2__PriceListId__r.CurrencyIsoCode=='EUR')
            Pricelist='DK20';
            else
            Pricelist='DK40';
            
            if(p.APTS_Sales_Org__c != NULL && p.APTS_Sales_Org__c.contains('SAP_')){
                salesorg = p.APTS_Sales_Org__c.replace('SAP_','');
            }
            else if(p.APTS_Sales_Org__c != NULL){
                salesorg = p.APTS_Sales_Org__c;
            }
            if(p.APTS_Distribution_Channel__c != NULL && p.APTS_Distribution_Channel__c.contains('SAP_')){
                disChan = p.APTS_Distribution_Channel__c.replace('SAP_','');
            }else if(p.APTS_Distribution_Channel__c != NULL){
               disChan = p.APTS_Distribution_Channel__c;
            }
              if(p.Apttus_Config2__PriceUom__c!= NULL && p.Apttus_Config2__PriceUom__c.contains('SAP_')){
                uom = p.Apttus_Config2__PriceUom__c.replace('SAP_','');
            }else if (p.Apttus_Config2__PriceUom__c!= NULL){
                uom = p.Apttus_Config2__PriceUom__c;
            }
            String rowStrn = salesorg+','+disChan+','+Pricelist+','+p.Apttus_Config2__ProductCode__c+','+p.Apttus_Config2__ListPrice__c+','+p.CurrencyIsoCode+',1,'+uom+','+Status;
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
        list<BizIsland_Request__c> biz=[ SELECT Id, Name,Version__c FROM BizIsland_Request__c where name=:Bon];
            if(!biz.isEmpty()){
                csvColumnHeader ='Sales Organization,Distribution Channel,Price List Type,Product Number,List Price Local Currency ExIndirect Tax,Local Currency List Price,List Price Unit,Unit of Measure,Status\n';
                String csvFile = csvColumnHeader + String.join(csvRowValues,'\n');
                APTS_BizIslandContentGenerator bizz=new APTS_BizIslandContentGenerator();
                if(cs.Delta_Load__c){
                    String documentName = ' DELTA REPORT PRICE_DATA';
                    bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
                }else if(cs.Full_Load__c){
                    String documentName = 'FULL REPORT PRICE_DATA';
                    bizz.addAttachmentsToBonsai(biz[0],csvFile,documentName);
                }
     
                APTS_PriceListitemBizIsland_cost prc = new APTS_PriceListitemBizIsland_cost();
                Database.executeBatch(prc,200);
            }
        }   
            
    }