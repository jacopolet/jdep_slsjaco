global class APTS_cerCachceleanupBatch implements Database.Batchable<sObject> {
     global Database.QueryLocator start(Database.BatchableContext BC) {
             //String  fullQueryString =  'select id,name,Configuration__c, Name__c,Sub_Type__c from CERDiscountCache__c where Configuration__c IN:configiddellist limit 50000';
             set<id> configidfull=new set<id>();
             set<id> configiddellist=new set<id>();
             for(CERDiscountCache__c cer:[select id,name,Configuration__c, Name__c,Sub_Type__c from CERDiscountCache__c limit 50000]){
             configidfull.add(cer.Configuration__c);
             }
             system.debug('++configidfull+++'+configidfull);
             list<Apttus_Config2__ProductConfiguration__c > configlist=[select id,Apttus_Config2__Status__c,Apttus_CMConfig__AgreementId__r.Apttus__Status_Category__c,Apttus_CMConfig__AgreementId__r.Apttus__Status__c from Apttus_Config2__ProductConfiguration__c where id IN:configidfull];
             for(Apttus_Config2__ProductConfiguration__c pc:[select id,Apttus_Config2__Status__c,Apttus_CMConfig__AgreementId__r.Apttus__Status_Category__c,Apttus_CMConfig__AgreementId__r.Apttus__Status__c from Apttus_Config2__ProductConfiguration__c where id IN:configidfull]){
             if(pc.Apttus_CMConfig__AgreementId__r.Apttus__Status__c=='Cancelled Request'||
             pc.Apttus_CMConfig__AgreementId__r.Apttus__Status__c=='Superseded' ||
             pc.Apttus_CMConfig__AgreementId__r.Apttus__Status__c=='Expired' ||
             pc.Apttus_CMConfig__AgreementId__r.Apttus__Status__c=='Terminated'){
             configiddellist.add(pc.Id); 
             }
             else if(pc.Apttus_Config2__Status__c=='Superseded'||
             pc.Apttus_Config2__Status__c=='Finalized'){
             configiddellist.add(pc.Id);
             }
             }
             system.debug('++configiddellist+++'+configiddellist);
             String  fullQueryString='select id,Apttus_Config2__Status__c,Apttus_CMConfig__AgreementId__r.Apttus__Status_Category__c,Apttus_CMConfig__AgreementId__r.Apttus__Status__c from Apttus_Config2__ProductConfiguration__c where id IN:configiddellist';
             system.debug('++fullQueryString+++'+fullQueryString);
             return Database.getQueryLocator(fullQueryString);
             }
             
     global void execute(Database.BatchableContext BC, List<sObject> scope) {
      system.debug('++debug_cache+++'+scope);
      list<id> deleteCERCachedel=new list<Id>();
      list<CERDiscountCache__c> deleteCERCachedel1=new list<CERDiscountCache__c>();
      list<Apttus_Config2__ProductConfiguration__c> newlist=(List<Apttus_Config2__ProductConfiguration__c>)scope;
      for(Apttus_Config2__ProductConfiguration__c pr:newlist){
      deleteCERCachedel.add(pr.Id);
      }
      deleteCERCachedel1=[select id from CERDiscountCache__c where Configuration__c IN:deleteCERCachedel];
         if(deleteCERCachedel1.size()>0){
         Delete deleteCERCachedel1;
         }
         
     
     } 
       global void finish(Database.BatchableContext BC) {}
}