/*
@Version History : v1.0 - created
v1.1 - 09/09/2019 - LAE/RAR Redesign (Introduced new field Agreement on Billing Schedule object and assign the value) - DFT2C-853.
v2.1 - DQ-56- Lavanya- Contract Chnage Make Billing Schedules Invoiced for Onetime in New assets as its already paid in old FOL/rental Assets. 
v2.2 | DQ-2541 | 17-June-20 | Apttus workaround for Delta amount at last (Needs to be removed post Patch is provided)
v2.3 | DQ-3948 | 24-sep-2020 | Replace the Agreement field population from OOTB Agreement field to Financial Agreement from assetline item.
v2.4 | DQ-4580 | 19-11-2020 | After delta amount is applied remove the value from map so its not applied to other BS
*/
//
public without sharing class APTS_BillingScheduleTriggerHandler implements ITriggerHandler{
    public Static String BILLING_SCHEDULE = 'Apttus_Billing__BillingSchedule__c';
    public Static String INFORMATIONAL = 'Informational';
    public Static String Invoiced = 'Invoiced';

    //10-May-2019: Defect 24345/CR 2303 - To bypass the Billing Schedule Trigger when required
    public static Boolean isSkipBillingScheduleTrigger = false;

    public Boolean IsDisabled(){
    return (TriggerSettings__c.getInstance().APTS_BillingScheduleTrigger__c== true ? false : true);
    }

    public void beforeInsert(List<SObject> newList){
        try{
            set<Id> setAssetId = new set<Id>();
            map<ID,Id> mapAssetId = new map<ID,Id>();
            map<Id,boolean> mapAssetIsrollup = new map<Id,boolean>();
            map<Id,Id> mapBSAssetIds  = new map<Id,Id>();
            ID assetAgreeId ;
            Set<Id> setOneTimeCheck= new Set<id>();
            
            map<id,Apttus_Config2__AssetLineItem__c> assetDetailMap  = new map<id,Apttus_Config2__AssetLineItem__c>();
            Decimal deltafeeAmount = 0;
            map<String,Apttus_Billing__BillingSchedule__c> combineToSinglePeriodtMap = new map<String,Apttus_Billing__BillingSchedule__c>();
            Map<Id,Decimal> deltaValueMap = new Map<Id,Decimal>();
            //09-Sept-2019 Mahesh Chilaka : DFT2C-856.
            map<Id, Id> mapBSAssetAgreeIds = new map<Id, Id>();
            //v2.2 | 17-June-20 | Apttus workaround for Delta amount at last - START
            for(Apttus_Billing__BillingSchedule__c billSch : (List<Apttus_Billing__BillingSchedule__c>)newList) {
                setAssetId.add(billSch.Apttus_Billing__AssetLineItemId__c);
                mapAssetId.put(billSch.Id,billSch.Apttus_Billing__AssetLineItemId__c);
                System.debug('#########billSch.Apttus_Billing__AssetLineItemId__c=====>'+billSch.Apttus_Billing__AssetLineItemId__c);
                System.debug('#########billSch.Apttus_Billing__FeeAmount__c=====>'+billSch.Apttus_Billing__FeeAmount__c);
                System.debug('#########billSch.Apttus_Billing__IsSuperseded__c=====>'+billSch.Apttus_Billing__IsSuperseded__c);
                System.debug('#########billSch.Apttus_Billing__Type__c=====>'+billSch.Apttus_Billing__Type__c);
                if(billSch.Apttus_Billing__FeeAmount__c!=0 && !billSch.Apttus_Billing__IsSuperseded__c && billSch.Apttus_Billing__Type__c.equalsIgnoreCase('Contracted')){
                    if(combineToSinglePeriodtMap.get(billSch.Apttus_Billing__AssetLineItemId__c+billSch.Apttus_Billing__PeriodEndDate__c.format())==null){
                        combineToSinglePeriodtMap.put(billSch.Apttus_Billing__AssetLineItemId__c+billSch.Apttus_Billing__PeriodEndDate__c.format(),billSch);
                    }
                }
            }
            //v2.2 | 17-June-20 | Apttus workaround for Delta amount at last - END
            //09-Sept-2019 Mahesh Chilaka : DFT2C-856 - Added new agreement field in the query.
            for(Apttus_Config2__AssetLineItem__c astLine : [SELECT Id,
                                                            APTS_OneTimeInvoiceCheck__c,
                                                            Apttus_CMConfig__AgreementId__c, 
                                                            APTS_relatedlist_agreement__c, 
                                                            APTS_Is_Primary_L1_Asset__c,
                                                            APTS_Financial_Agreement__c, 
                                                            APTS_Is_Primary_L1_Asset__r.Apttus_CMConfig__AgreementId__c,
                                                            APTS_Is_Primary_L1_Asset__r.APTS_Financial_Agreement__c,
                                                            APTS_Is_Primary_L1_Asset__r.APTS_relatedlist_agreement__c,
                                                            Apttus_Config2__IsOptionRollupLine__c,
                                                            Apttus_Config2__AdjustedPrice__c,
                                                            Apttus_Config2__StartDate__c,
                                                            Apttus_Config2__OriginalStartDate__c,
                                                            Apttus_Config2__EndDate__c,
                                                            Apttus_Config2__LineType__c
                                                            FROM Apttus_Config2__AssetLineItem__c 
                                                            WHERE Id IN : setAssetId]){

                mapAssetIsrollup.put(astLine.Id,astLine.Apttus_Config2__IsOptionRollupLine__c);
                mapBSAssetIds.put(astLine.Id,astLine.Id);
                //v2.2 | 17-June-20 | Apttus workaround for Delta amount at last - START
                if(astLine.Apttus_Config2__AdjustedPrice__c==0 && astLine.Apttus_Config2__StartDate__c!=astLine.Apttus_Config2__OriginalStartDate__c && astLine.Apttus_Config2__LineType__c.equalsIgnoreCase('Option')){
                    assetDetailMap.put(astLine.Id,astLine);
                }
                //v2.2 | 17-June-20 | Apttus workaround for Delta amount at last - END
                //09-Sept-2019 Mahesh Chilaka : DFT2C-856 -START 
                //v2.3 START
                if(astLine.APTS_Financial_Agreement__c != null){
                    assetAgreeId = astLine.APTS_Financial_Agreement__c != null?astLine.APTS_Financial_Agreement__c:null;
                    }else if(astLine.APTS_Is_Primary_L1_Asset__c != null && (astLine.APTS_Is_Primary_L1_Asset__r.Apttus_CMConfig__AgreementId__c != null || astLine.APTS_Is_Primary_L1_Asset__r.APTS_relatedlist_agreement__c != null)){
                    assetAgreeId = astLine.APTS_Is_Primary_L1_Asset__r.APTS_Financial_Agreement__c != null ? astLine.APTS_Is_Primary_L1_Asset__r.APTS_Financial_Agreement__c:null;
                }
                if(astLine.APTS_OneTimeInvoiceCheck__c == true){
                    setOneTimeCheck.add(astLine.id);    
                }
                //DQ-56
                if(assetAgreeId != null){
                    mapBsAssetAgreeIds.put(astLine.Id, assetAgreeId);
                }

                // DFT2C-856 END.
            }
            //v2.2 | 17-June-20 | Apttus workaround for Delta amount at last - START
            System.debug('*****combineToSinglePeriodtMap=======>'+combineToSinglePeriodtMap);
            System.debug('*****assetDetailMap=======>'+assetDetailMap);
            if(!assetDetailMap.isEmpty()){
                For(Apttus_Billing__BillingSchedule__c deltaAmountBS : combineToSinglePeriodtMap.values()){
                    System.debug('*****deltaAmountBS.Apttus_Billing__AssetLineItemId__c=======>'+deltaAmountBS.Apttus_Billing__AssetLineItemId__c);
                    if(assetDetailMap.get(deltaAmountBS.Apttus_Billing__AssetLineItemId__c)!=null){
                        System.debug('*****assetDetailMap.get(deltaAmountBS.Apttus_Billing__AssetLineItemId__c).Apttus_Config2__EndDate__c=======>'+assetDetailMap.get(deltaAmountBS.Apttus_Billing__AssetLineItemId__c).Apttus_Config2__EndDate__c);
                        System.debug('*****deltaAmountBS.Apttus_Billing__PeriodEndDate__c=======>'+deltaAmountBS.Apttus_Billing__PeriodEndDate__c);
                        if(assetDetailMap.get(deltaAmountBS.Apttus_Billing__AssetLineItemId__c).Apttus_Config2__EndDate__c == deltaAmountBS.Apttus_Billing__PeriodEndDate__c){
                            System.debug('*****deltaAmountBS.Apttus_Billing__FeeAmount__c=======>'+deltaAmountBS.Apttus_Billing__FeeAmount__c);
                            if(deltaAmountBS.Apttus_Billing__FeeAmount__c!=0){
                                deltafeeAmount = deltaAmountBS.Apttus_Billing__FeeAmount__c;
                                deltaAmountBS.Apttus_Billing__FeeAmount__c=0;
                                if(deltaValueMap.get(deltaAmountBS.Apttus_Billing__AssetLineItemId__c)==null){
                                    deltaValueMap.put(deltaAmountBS.Apttus_Billing__AssetLineItemId__c,deltafeeAmount);
                                }
                                combineToSinglePeriodtMap.remove(deltaAmountBS.Apttus_Billing__AssetLineItemId__c+deltaAmountBS.Apttus_Billing__PeriodEndDate__c.format());
                            }
                        }
                    }
                }
            }
            //v2.2 | 17-June-20 | Apttus workaround for Delta amount at last - END
            system.debug('map asset Id after --> '+mapAssetIsrollup);
            for(Apttus_Billing__BillingSchedule__c billSch : (List<Apttus_Billing__BillingSchedule__c>)newList) {
                system.debug('billSch -- > Before'+billSch.Id);
                system.debug('mapAssetId.get(billSch.Id) -- > Before'+mapAssetId.get(billSch.Id));
                system.debug('mapAssetIsrollup -- > Before'+mapAssetIsrollup.get(mapAssetId.get(billSch.Id)));
                system.debug('BS -- > Before'+billSch.Apttus_Billing__Type__c);
                if(mapBSAssetIds.containsKey(billSch.Apttus_Billing__AssetLineItemId__c) && mapAssetIsrollup.get(mapBSAssetIds.get(billSch.Apttus_Billing__AssetLineItemId__c)) && billSch.Apttus_Billing__Type__c != INFORMATIONAL)
                {
                billSch.Apttus_Billing__Type__c = INFORMATIONAL;
                }
               // if(setOneTimeCheck.contains(billSch.Apttus_Billing__AssetLineItemId__c))
                //billSch.Apttus_Billing__Status__c=Invoiced; //DQ-56


                //09-Sept-2019 Mahesh Chilaka : DFT2C-856 -START 
                if(mapBsAssetAgreeIds.containsKey(billSch.Apttus_Billing__AssetLineItemId__c)) {
                billSch.APTS_Agreement__c = mapBsAssetAgreeIds.get(billSch.Apttus_Billing__AssetLineItemId__c);
                }
                // DFT2C-856 END.
                //v2.2 | 17-June-20 | Apttus workaround for Delta amount at last - START
                System.debug('deltafeeAmount============>'+deltafeeAmount);
                System.debug('deltaValueMap============>'+deltaValueMap);
                System.debug('combineToSinglePeriodtMap============>'+combineToSinglePeriodtMap);
                System.debug('billSch.Apttus_Billing__IsSuperseded__c============>'+billSch.Apttus_Billing__IsSuperseded__c);
                System.debug('billSch.Apttus_Billing__FeeAmount__c============>'+billSch.Apttus_Billing__FeeAmount__c);
                System.debug('billSch.Apttus_Billing__Type__c============>'+billSch.Apttus_Billing__Type__c);
                if(!combineToSinglePeriodtMap.isEmpty() && billSch.Apttus_Billing__FeeAmount__c!=0 
                && !billSch.Apttus_Billing__IsSuperseded__c && billSch.Apttus_Billing__Type__c.equalsIgnoreCase('Contracted')
                && assetDetailMap.get(billSch.Apttus_Billing__AssetLineItemId__c)!=null && !deltaValueMap.isEmpty()){
                    if(combineToSinglePeriodtMap.get(billSch.Apttus_Billing__AssetLineItemId__c+billSch.Apttus_Billing__PeriodEndDate__c.format())!=null && deltaValueMap.get(billSch.Apttus_Billing__AssetLineItemId__c)!=null){
                        billSch.APTS_Delta_amount_added__c = deltaValueMap.get(billSch.Apttus_Billing__AssetLineItemId__c);
                        billSch.Apttus_Billing__FeeAmount__c += deltaValueMap.get(billSch.Apttus_Billing__AssetLineItemId__c);
                        //<--v2.4
                        deltaValueMap.remove(billSch.Apttus_Billing__AssetLineItemId__c);
                        //v2.4-->
                    }else{
                        billSch.Apttus_Billing__FeeAmount__c =0;
                    }
                }
                //v2.2 | 17-June-20 | Apttus workaround for Delta amount at last - END
            }
        }catch (Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage() + '\n\n' + ex.getStackTraceString() ,'BillingTrigger',null, 'BIR', false, false, null, true);}   
    }

    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems,List<SObject> oldList, Map<Id, SObject> oldItems){

        Map<Id, Apttus_Billing__BillingSchedule__c> billschNewMap = (Map<Id, Apttus_Billing__BillingSchedule__c>) newItems;
        Map<Id, Apttus_Billing__BillingSchedule__c> billschOldMap = (Map<Id, Apttus_Billing__BillingSchedule__c>) oldItems;
        try{
        system.debug('udpate from hanlder');
        set<Id> setAssetId = new set<Id>();
        map<ID,Id> mapAssetId = new map<ID,Id>();
        map<Id,boolean> mapAssetIsrollup = new map<Id,boolean>();
        Set<Id> setOneTimeCheck= new Set<id>();
        for(Apttus_Billing__BillingSchedule__c billSch : billschNewMap.values()) {                        
            setAssetId.add(billSch.Apttus_Billing__AssetLineItemId__c);
            mapAssetId.put(billSch.Id,billSch.Apttus_Billing__AssetLineItemId__c);
        }
        for(Apttus_Config2__AssetLineItem__c astLine : [Select Id,Apttus_Config2__IsOptionRollupLine__c,APTS_OneTimeInvoiceCheck__c from Apttus_Config2__AssetLineItem__c where Id IN : setAssetId]){
            mapAssetIsrollup.put(astLine.Id,astLine.Apttus_Config2__IsOptionRollupLine__c);
            if(astLine.APTS_OneTimeInvoiceCheck__c == true)
                setOneTimeCheck.add(astLine.id);
        }
        for(Apttus_Billing__BillingSchedule__c billSch : (List<Apttus_Billing__BillingSchedule__c>)newList) {
            system.debug('mapAssetId.get(billSch.Id) -- > '+mapAssetId.get(billSch.Id));
            system.debug('mapAssetIsrollup -- > '+mapAssetIsrollup.get(mapAssetId.get(billSch.Id)));
            system.debug('BS -- > '+billSch.Apttus_Billing__Type__c);
            if(mapAssetId.get(billSch.Id)!= null && mapAssetIsrollup.get(mapAssetId.get(billSch.Id)) && billSch.Apttus_Billing__Type__c != INFORMATIONAL){
                billSch.Apttus_Billing__Type__c = INFORMATIONAL;
            }
           // if(setOneTimeCheck.contains(billSch.Apttus_Billing__AssetLineItemId__c))
               // billSch.Apttus_Billing__Status__c=Invoiced; //DQ-56
                System.debug(billSch);
        }

        }catch (Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage() ,'BillingTrigger','otc', 'Billing', false, false, null, true);}   
    }

    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){ }

    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){}

    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}


}