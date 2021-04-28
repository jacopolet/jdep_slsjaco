/**********************************************************************************
* @Author: Shahul
* @Company: Accenture
* @Description: Handler class to control various transaction events @ Laetransaction Object
* @Created Date: August 11, 2020
* @History:
*      <Name>              <Date>          <Description>
*      Shahul              11.08.2020       Created
v 1.2 - 14/01/2021 DQ -4871 Create 0001 transaction when No coverage get cancelled and All in Coverage is Activated in a single Conversion Order
v1.3- Bug Fix DQ_5121
**********************************************************************************/
public with sharing class APTS_LaeTransactionHandler implements ITriggerHandler{

    public static boolean isTriggerDisabled = true;
    public static final String ERRSUPERSEDED = system.label.APTS_LAETransactionerr;
    public static final String ALLCOVERAGE= system.label.APTS_ALLCOVERAGE;
    public static final String BCOVERAGE= system.label.APTS_BCOVERAGE;
    private static final String SERVICEFEE = 'Service Fee';
    private static final String RENTALFEE = 'Rental Fee';
    private static final String ADDITIONALSERVICEFEE = 'Additional Service Fee';
    private static final String PRODUCTSERVICE = 'Product/Service';
    private static final String NO_COVERAGE= 'NO COVERAGE';
    private static final String STR_ACTION_ACTIVATED = 'Activated';
            String isNoCoverage='Default';
            String asfstatus='Default';
            String isBCoverage='Default';
            String isACoverage='Default';
    
    public void BeforeInsert(List<SObject> newItems){
    
    Set<Id> setAssetId = new Set<Id>();
    Set<Id> primsetAssetId = new Set<Id>();
    Set<Id> accountAssetId = new Set<Id>();
    Set<Id> agrAssetId = new Set<Id>();
    Set<ID> businessObjectLineItemSet = new Set<ID>();
    Set<Date> setDate = new Set<Date>();
    Set<String> setBTT = new Set<String>();
    Map<Id,Date> startdateMap = new Map<Id, Date>();
    Map<Id,Date> enddateMap = new Map<Id, Date>();
    Map<Id,String> statusMap = new Map<Id, String>();
    Map<Id,String> existingtransMap = new Map<Id, String>();

        for(RTR_LAE_Transaction_Data__c lae : (List<RTR_LAE_Transaction_Data__c>)newItems){
            setAssetId.add(lae.APTS_Asset_Line_Item__c);
            setDate.add(lae.APTS_Contract_Effective_Date__c);
            setBTT.add(lae.APTS_Business_Transaction_Type__c);
        }
        system.debug('++DebugsetAssetId+++'+setAssetId);
        system.debug('++primsetAssetId+++'+primsetAssetId);
        system.debug('++DebugsetDate+++'+setDate);
        system.debug('++DebugsetBTT+++'+setBTT);
        //Venky START
            Id tempAssetId;
            Id insAssetId;
            List<Apttus_Config2__AssetLineItem__c> primeasset= new List<Apttus_Config2__AssetLineItem__c>();
            for(Apttus_Config2__AssetLineItem__c  ali:[SELECT Id,Apttus_Config2__BusinessObjectId__c,Apttus_Config2__BundleAssetId__c,Apttus_Config2__OptionId__r.name,Apttus_Config2__LineType__c,APTS_Financial_Asset_Status__c,Apttus_Config2__AssetStatus__c,
            APTS_Is_Primary_L1_Asset__c,Apttus_Config2__AccountId__c,APTS_relatedlist_agreement__c
            from Apttus_Config2__AssetLineItem__c where id in:setAssetId]){          
            primsetAssetId.add(ali.Apttus_Config2__BundleAssetId__c);
            businessObjectLineItemSet.add(ali.Apttus_Config2__BusinessObjectId__c);
            setAssetId.addall(primsetAssetId);
            accountAssetId.add(ali.Apttus_Config2__AccountId__c);
            agrAssetId.add(ali.APTS_relatedlist_agreement__c);
            }
            
            for(Apttus_Config2__AssetLineItem__c  ali:[SELECT Id,Apttus_Config2__ChargeType__c,Apttus_Config2__OptionId__r.name,Apttus_Config2__LineType__c,APTS_Financial_Asset_Status__c,Apttus_Config2__AssetStatus__c,APTS_Financial_Start_Date__c ,Apttus_Config2__EndDate__c
            FROM Apttus_Config2__AssetLineItem__c 
            WHERE (Id in: setAssetId or Apttus_Config2__BundleAssetId__c in: setAssetId) and
            (Apttus_Config2__ChargeType__c =:SERVICEFEE OR Apttus_Config2__ChargeType__c =:ADDITIONALSERVICEFEE OR Apttus_Config2__ChargeType__c =:RENTALFEE) 
            and (Apttus_Config2__AssetStatus__c='Activated' OR Apttus_Config2__AssetStatus__c='Cancelled') AND
            Apttus_Config2__AccountId__c in:accountAssetId AND APTS_relatedlist_agreement__c
            in:agrAssetId AND Apttus_Config2__BusinessObjectId__c in:businessObjectLineItemSet]){
                startdateMap.put(ali.Id,ali.APTS_Financial_Start_Date__c);
                enddateMap.put(ali.Id,ali.Apttus_Config2__EndDate__c);
                statusMap.put(ali.Id,ali.Apttus_Config2__AssetStatus__c);
                system.debug('ali++++'+ali);
                if(ali.Apttus_Config2__ChargeType__c ==ADDITIONALSERVICEFEE&&ali.APTS_Financial_Asset_Status__c=='Cancelled'&&ali.Apttus_Config2__AssetStatus__c=='Activated'&&ali.Apttus_Config2__LineType__c=='Product/Service'){
                    asfstatus='false';
                }
                if(ali.Apttus_Config2__ChargeType__c ==ADDITIONALSERVICEFEE&&ali.APTS_Financial_Asset_Status__c=='Activated'&&ali.Apttus_Config2__AssetStatus__c=='Activated'&&ali.Apttus_Config2__LineType__c=='Product/Service'){
                    asfstatus='true';
                }
                if(ali.Apttus_Config2__ChargeType__c==SERVICEFEE&&ali.APTS_Financial_Asset_Status__c=='Cancelled'&&ali.Apttus_Config2__AssetStatus__c=='Activated'&&ali.Apttus_Config2__LineType__c=='Product/Service'){
                    tempAssetId=ali.Id;
                }
                if(ali.Apttus_Config2__ChargeType__c==SERVICEFEE&&ali.APTS_Financial_Asset_Status__c=='Activated'&&ali.Apttus_Config2__AssetStatus__c=='Activated'&&ali.Apttus_Config2__LineType__c=='Product/Service'){
                    insAssetId=ali.Id;
                }
                //v 1.2 Start
               if(ali.Apttus_Config2__OptionId__r.name!=null && ali.Apttus_Config2__OptionId__r.name==NO_COVERAGE&&ali.Apttus_Config2__AssetStatus__c=='Cancelled'){
                    isNoCoverage='false';
                }
                if(ali.Apttus_Config2__OptionId__r.name!=null && ali.Apttus_Config2__OptionId__r.name==NO_COVERAGE&&ali.Apttus_Config2__AssetStatus__c=='Activated'){
                    isNoCoverage='true';
                }
                if(ali.Apttus_Config2__OptionId__r.name!=null && ali.Apttus_Config2__OptionId__r.name==ALLCOVERAGE&&ali.Apttus_Config2__AssetStatus__c=='Activated'){
                    isACoverage='true';
                }
                if(ali.Apttus_Config2__OptionId__r.name!=null && ali.Apttus_Config2__OptionId__r.name==ALLCOVERAGE&&ali.Apttus_Config2__AssetStatus__c=='Cancelled'){
                    isACoverage='false';
                }
                if(ali.Apttus_Config2__OptionId__r.name!=null && ali.Apttus_Config2__OptionId__r.name==BCOVERAGE&&ali.Apttus_Config2__AssetStatus__c=='Activated'){
                    isBCoverage='true';
                }
                if(ali.Apttus_Config2__OptionId__r.name!=null && ali.Apttus_Config2__OptionId__r.name==BCOVERAGE&&ali.Apttus_Config2__AssetStatus__c=='Cancelled'){
                    isBCoverage='false';
                }
                //v 1.2 END
                            system.debug('Assett*'+ali);
            }
            system.debug('tempAssetId***'+tempAssetId);
            system.debug('insAssetId***'+insAssetId);
            system.debug('isNoCoverage***'+isNoCoverage);
           system.debug('isACoverage***'+isACoverage);
           system.debug('isBCoverage***'+isBCoverage);
        //Venky END
        if(setAssetId.size() > 0 &&setDate.size() > 0 &&setBTT.size() > 0&&accountAssetId.size()>0 &&agrAssetId.size()>0){
            List<RTR_LAE_Transaction_Data__c> lstlaecount = [select id,name,APTS_Asset_Line_Item__c,APTS_Business_Transaction_Type__c,APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c,
            APTS_Contract_Effective_Date__c from RTR_LAE_Transaction_Data__c where APTS_Asset_Line_Item__c in :setAssetId AND (APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c='Activated' OR APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c='Cancelled') AND APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__c in:accountAssetId AND APTS_Asset_Line_Item__r.APTS_relatedlist_agreement__c in:agrAssetId];
            system.debug('++Debuglstlaecount+++'+lstlaecount);
            
            Map<String ,RTR_LAE_Transaction_Data__c> mapNameWiselaeount = new Map<String,RTR_LAE_Transaction_Data__c>();
            for(RTR_LAE_Transaction_Data__c lae: lstlaecount){
            if(lae.APTS_Business_Transaction_Type__c=='0001'&&lae.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c==SERVICEFEE){
            existingtransMap.put(lae.APTS_Asset_Line_Item__c,lae.APTS_Business_Transaction_Type__c);}
            if(setBTT.contains(lae.APTS_Business_Transaction_Type__c)&&setDate.contains(lae.APTS_Contract_Effective_Date__c )){
                mapNameWiselaeount.put(lae.APTS_Asset_Line_Item__c+lae.APTS_Business_Transaction_Type__c+lae.APTS_Contract_Effective_Date__c,lae);}
            }
            system.debug('++Debug mapNameWiselaeount+++'+mapNameWiselaeount);
            system.debug('++Debug existingtransMap+++'+existingtransMap);
            
            for(RTR_LAE_Transaction_Data__c lae : (List<RTR_LAE_Transaction_Data__c>)newItems){
                system.debug('++++++'+statusMap);
                system.debug('++++++'+lae.APTS_Asset_Line_Item__c);
                system.debug('+++cancelledservice+++'+tempAssetId);
                system.debug('+++ActiveinsAssetId+++'+insAssetId);
                system.debug('++++++'+lae.APTS_Business_Transaction_Type__c);
                system.debug('++++++'+isNoCoverage);
                system.debug('++++++'+isACoverage);
                system.debug('++++++'+isBCoverage);
                system.debug('++asfstatus++++'+asfstatus);
                
                if(mapNameWiselaeount.containsKey(lae.APTS_Asset_Line_Item__c+lae.APTS_Business_Transaction_Type__c+lae.APTS_Contract_Effective_Date__c))   
                {   
                    lae.APTS_Asset_Processed__c =True;  
                    lae.Error_Description__c =ERRSUPERSEDED;    
                }
                
                //Paid ADSF||Service-Activated || NoCoverage-YES || All or basic-Cancelled || ADSF-Activated
                if((lae.APTS_Asset_Line_Item__c==insAssetId&&(lae.APTS_Business_Transaction_Type__c=='0002' || lae.APTS_Business_Transaction_Type__c =='0004')&&(isACoverage=='false'||isBCoverage=='false')&&isNoCoverage=='true'&&asfstatus=='True')){
                     lae.APTS_Business_Transaction_Type__c ='0004';lae.APTS_Contract_Effective_Date__c=system.today();
                }
                //Paid ADSF||Service-cancelled || NoCoverage-YES || All or basic-Cancelled || ADSF-Cancelled
                if((lae.APTS_Asset_Line_Item__c==tempAssetId&&(lae.APTS_Business_Transaction_Type__c=='0002' || lae.APTS_Business_Transaction_Type__c =='0004')&&(isACoverage=='false'||isBCoverage=='false')&&isNoCoverage=='true'&&asfstatus=='false')){
                    lae.APTS_Business_Transaction_Type__c ='0002';
                      if(enddateMap.get(lae.APTS_Asset_Line_Item__c)!= NULL){lae.APTS_Contract_Effective_Date__c=enddateMap.get(lae.APTS_Asset_Line_Item__c);}
                }  
                //Paid ADSF||Service-cancelled || NoCoverage-YES || All or basic-Cancelled || ADSF-Cancelled
                if((lae.APTS_Asset_Line_Item__c==tempAssetId&&(lae.APTS_Business_Transaction_Type__c=='0002' || lae.APTS_Business_Transaction_Type__c =='0004')&&(isACoverage=='false'||isBCoverage=='false')&&isNoCoverage=='true'&&asfstatus=='Default')){
                    lae.APTS_Business_Transaction_Type__c ='0002';
                      if(enddateMap.get(lae.APTS_Asset_Line_Item__c)!= NULL){lae.APTS_Contract_Effective_Date__c=enddateMap.get(lae.APTS_Asset_Line_Item__c);}
                }   
                //FREE ADSF||Service-cancelled || NoCoverage-YES || All or basic-Cancelled || ADSF-Activated
                if((lae.APTS_Asset_Line_Item__c==tempAssetId&&(lae.APTS_Business_Transaction_Type__c=='0002' || lae.APTS_Business_Transaction_Type__c =='0004')&&(isACoverage=='false'||isBCoverage=='false')&&isNoCoverage=='true'&&asfstatus=='true')){
                    lae.APTS_Business_Transaction_Type__c ='0004';lae.APTS_Contract_Effective_Date__c=system.today();
                }
                //Duplicate check:1 
                //FREE ADSF||Service-cancelled || NoCoverage-YES || All or basic-Cancelled || ADSF-cancelled
                if((lae.APTS_Asset_Line_Item__c==tempAssetId&&(lae.APTS_Business_Transaction_Type__c=='0002' || lae.APTS_Business_Transaction_Type__c =='0004')&&(isACoverage=='false'||isBCoverage=='false')&&isNoCoverage=='true'&&asfstatus=='true')){
                    lae.APTS_Business_Transaction_Type__c ='0002';
                      if(enddateMap.get(lae.APTS_Asset_Line_Item__c)!= NULL){lae.APTS_Contract_Effective_Date__c=enddateMap.get(lae.APTS_Asset_Line_Item__c);}
                }
                //FREE or PAID ADSF||Service-Activated || NoCoverage-No || All or basic-either one Cancelled || ADSF-Activated/Cancelled
                if(lae.APTS_Asset_Line_Item__c==insAssetId&&(lae.APTS_Business_Transaction_Type__c=='0002' || lae.APTS_Business_Transaction_Type__c =='0004')&&((isACoverage=='true'&&isBCoverage=='false')||(isACoverage=='false'&&isBCoverage=='true'))&&isNoCoverage=='Default'&&(asfstatus=='true'||asfstatus=='false')){
                    lae.APTS_Business_Transaction_Type__c ='0004';lae.APTS_Contract_Effective_Date__c=system.today();
                }
                //PAID ADSF||Service-Activated || NoCoverage-Cancelled || All or basic-Activated || ADSF-Activated/Cancelled
                if(lae.APTS_Asset_Line_Item__c==insAssetId&&(lae.APTS_Business_Transaction_Type__c=='0002' || lae.APTS_Business_Transaction_Type__c =='0004')&&(isACoverage=='true'||isBCoverage=='true')&&isNoCoverage=='false'&&asfstatus=='Default'){
                    lae.APTS_Business_Transaction_Type__c ='0001';
                     if(startdateMap.get(lae.APTS_Asset_Line_Item__c)!= NULL){lae.APTS_Contract_Effective_Date__c=startdateMap.get(lae.APTS_Asset_Line_Item__c);}
                }
                //Free ADSF||Service-Activated || NoCoverage-Cancelled || All or basic-Cancelled || ADSF-Activated/Cancelled
                if(lae.APTS_Asset_Line_Item__c==insAssetId&&(lae.APTS_Business_Transaction_Type__c=='0002' || lae.APTS_Business_Transaction_Type__c =='0004')&&(isACoverage=='true'||isBCoverage=='true')&&isNoCoverage=='false'&&(asfstatus=='true'||asfstatus=='false')){
                   system.debug('newcheck'+lae.APTS_Business_Transaction_Type__c);
                   system.debug('newcheck_existingtransMap'+existingtransMap.get(lae.APTS_Asset_Line_Item__c));
                    if(!existingtransMap.isempty()&&existingtransMap.get(lae.APTS_Asset_Line_Item__c)=='0001'){
                    lae.APTS_Business_Transaction_Type__c ='0004';lae.APTS_Contract_Effective_Date__c=system.today();
                    }
                    else{lae.APTS_Business_Transaction_Type__c ='0001';
                    if(startdateMap.get(lae.APTS_Asset_Line_Item__c)!= NULL){lae.APTS_Contract_Effective_Date__c=startdateMap.get(lae.APTS_Asset_Line_Item__c);}}
                }
                //No ADSF||Service-Activated || NoCoverage-Yes || All or basic-Activated || ADSF-None
                if(lae.APTS_Asset_Line_Item__c==insAssetId&&(lae.APTS_Business_Transaction_Type__c=='0002' || lae.APTS_Business_Transaction_Type__c =='0004')&&(isACoverage=='false'||isBCoverage=='false')&&isNoCoverage=='true'&&asfstatus=='Default'){
                    lae.APTS_Business_Transaction_Type__c ='0002';
                      if(enddateMap.get(lae.APTS_Asset_Line_Item__c)!= NULL){lae.APTS_Contract_Effective_Date__c=enddateMap.get(lae.APTS_Asset_Line_Item__c);}
                }
                //No ADSF||Service-Activated || NoCoverage-Yes || All or basic-Cancelled || ADSF-None
                if(lae.APTS_Asset_Line_Item__c==insAssetId&&(lae.APTS_Business_Transaction_Type__c=='0002' || lae.APTS_Business_Transaction_Type__c =='0004')&&((isACoverage=='true'&&isBCoverage=='false')||(isACoverage=='false'&&isBCoverage=='true'))&&isNoCoverage=='Default'&&asfstatus=='Default'){
                    lae.APTS_Business_Transaction_Type__c ='0004';lae.APTS_Contract_Effective_Date__c=system.today();
                }
                
                
                
            }
            
        }
        
    }
 
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){
    
        Set<String> set005AssetId = new Set<String>();
        Set<Date> set005Date = new Set<Date>();
        Set<String> set005BTT = new Set<String>();
        List<RTR_LAE_Transaction_Data__c> lstlaecountnew=new List<RTR_LAE_Transaction_Data__c> ();
            for(RTR_LAE_Transaction_Data__c lae : (List<RTR_LAE_Transaction_Data__c>)newList){
                if(lae.APTS_Business_Transaction_Type__c.contains('005')){
                set005AssetId.add(lae.APTS_Asset_Line_Item__c);
                set005Date.add(lae.APTS_Contract_Effective_Date__c);
                set005BTT.add(lae.APTS_Business_Transaction_Type__c);
                }
            }
            system.debug('++DebugsetAssetId+++'+set005AssetId);
            system.debug('++DebugsetDate+++'+set005Date);
            system.debug('++DebugsetBTT+++'+set005BTT);
            
            if(set005AssetId.size() > 0 &&set005Date.size() > 0 &&set005BTT.size() > 0){
                lstlaecountnew = [select id,name,APTS_Asset_Line_Item__c,APTS_Business_Transaction_Type__c,APTS_Contract_Effective_Date__c from RTR_LAE_Transaction_Data__c where APTS_Asset_Line_Item__c in :set005AssetId and APTS_Business_Transaction_Type__c in:set005BTT and APTS_Contract_Effective_Date__c in:set005Date and APTS_Business_Transaction_Type__c like '%005%'];
                system.debug('++Debuglstlaecount+++'+lstlaecountnew);
                
                Map<String ,RTR_LAE_Transaction_Data__c> mapNameWiselaeount = new Map<String,RTR_LAE_Transaction_Data__c>();
                if(lstlaecountnew.size()>0){
                    for(RTR_LAE_Transaction_Data__c lae: lstlaecountnew){
                        mapNameWiselaeount.put(lae.APTS_Asset_Line_Item__c+lae.APTS_Business_Transaction_Type__c+lae.APTS_Contract_Effective_Date__c,lae);
                    }
                }
                system.debug('++Debug mapNameWiselaeount+++'+mapNameWiselaeount);
                
                for(RTR_LAE_Transaction_Data__c lae : (List<RTR_LAE_Transaction_Data__c>)newList){
                    RTR_LAE_Transaction_Data__c laeold=(RTR_LAE_Transaction_Data__c)Trigger.oldMap.get(lae.ID);
                    system.debug('++++Oldmaplaetrans+++'+laeold);
                    if(lae.APTS_Contract_Effective_Date__c!=laeold.APTS_Contract_Effective_Date__c){
                        if(mapNameWiselaeount.containsKey(lae.APTS_Asset_Line_Item__c+lae.APTS_Business_Transaction_Type__c+lae.APTS_Contract_Effective_Date__c)){
                            lae.APTS_Asset_Processed__c =True;
                            lae.Error_Description__c =ERRSUPERSEDED;
                        }
                    }
                }
                
            }
    }
 
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){}

    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
 
    public Boolean IsDisabled(){
    if (TriggerSettings__c.getInstance().LAETransaction__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
}