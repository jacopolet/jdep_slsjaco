/*************************************************************
@Name: APTS_AccountAssetsViewLightningCtrl
@Author: Wendy Kelley
@CreateDate: 29/01/2018
@Description: Controller class to fetch active machine assets for an account
@UsedBy: APTS_AccountAssetsView.cmp 
******************************************************************/
//V101 28-Aug-2019 Renuka:DFT2C-1017 Added fields in Agreement query.
//v102  Mahesh Chilaka : 05/09/2019 - LAE/RAR Redesign (Creation of Transaction record logic update) - DFT2C-853.
//v103  Sai Sagar - Populate Movment From Location and Account - DFT2C-1898
//v104  Sai Sagar - Populate Last Related Agreement - DFT2C-1246
//v105 Venky Muppalaneni- poupulating change of owner ship and Financial Agreement  - DQ-3911  
//v106 Shahul - Added new Assetlineitemtrigger skipper logic
public with Sharing class APTS_AccountAssetsViewLightningCtrl {

    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String TEMPDEACTIVATED = System.Label.APTS_TemporaryDeactivated;
    private static final String OPTION = System.Label.APTS_Option;
    private static final String INSTALLATION = System.Label.APTS_Installation;
    private static final String DEINSTALLATION = System.Label.APTS_De_installation;
    private static final String CANCELLED = System.Label.APTS_Cancelled;
    private static final String ActiveAssetQuery = 'Active_Asset_Movement'; 
    private static Id recordId;  
    @TestVisible private static List<APTS_Batch_Queries__mdt> activeAssetQueryMdt { 
        get {
            if ( activeAssetQueryMdt == null ){
            activeAssetQueryMdt = [ select id,APTS_Query_String__c from APTS_Batch_Queries__mdt where DeveloperName  =:ActiveAssetQuery limit 1 ]; 
            }
            return activeAssetQueryMdt;
        } set;
    }
    
    /**
    * @author        Wendy Kelley
    * @date          29/01/2018
    * @description   Method for loading bundle products asset line items
    * @params        Id
    * @return        List<Apttus_Config2__AssetLineItem__c>
    * @revision(s)
    */
    @AuraEnabled
    public static List<Apttus_Config2__AssetLineItem__c> getBundleAssetLineItems(Id accountId) {
        List<Apttus_Config2__AssetLineItem__c> assetList = new List<Apttus_Config2__AssetLineItem__c>();
        recordId = accountId;
        try {
            String queryString = '';      
            if(activeAssetQueryMdt != null && activeAssetQueryMdt.size() > 0){
                queryString = activeAssetQueryMdt[activeAssetQueryMdt.size()-1].APTS_Query_String__c;
                assetList = Database.query(queryString);
            }                                                        
        }catch(Exception ex){
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage()+''+ex.getStackTraceString() ,'APTS_AccountAssetsViewLightningCtrl', recordId,'CLM',false,false,null,true);
        }        
        return assetList;
    }
    
    /**
    * @author        V. Shankaranarayanan
    * @date          29/08/2018
    * @description   Method to get deactivated ALIs
    * @params        Id
    * @return        List<Apttus_Config2__AssetLineItem__c>
    * @revision(s)
    */
    @AuraEnabled
    public static List<Apttus_Config2__AssetLineItem__c> getDeactivatedAssetLineItems(Id accountId) {
        try{
            String subStatus = Label.APTS_TemporaryDeactivated;
            String queryString = 'SELECT Id, Name, Apttus_Config2__StartDate__c, Apttus_Config2__EndDate__c, ' +
                                            ' APTS_Serial_Number__c, Apttus_Config2__LocationId__r.Name, '+
                                            ' Serial_Number__c, APTS_Contract_Type__c, ' +
                                            ' Apttus_CMConfig__AgreementId__c, Apttus_CMConfig__AgreementId__r.Name, ' +
                                            ' Apttus_Config2__AccountId__c, Apttus_Config2__AccountId__r.Name, ' +
                                            ' Apttus_Config2__ShipToAccountId__c, Apttus_Config2__ShipToAccountId__r.Name, ' +
                                            ' Apttus_Config2__AssetStatus__c ' +
                                            ' FROM  Apttus_Config2__AssetLineItem__c ' +
                                            ' WHERE Apttus_Config2__AccountId__c =: accountId ' +
                                            ' AND Apttus_Config2__LineType__c = \'Product/Service\' AND TOLABEL(Apttus_Config2__ProductId__r.Family) IN (\'Machines\',\'Concepts\')'+
                                            ' AND Apttus_Config2__IsPrimaryLine__c =TRUE '+
                                            ' AND (APTS_Sub_Status__c =: subStatus OR Apttus_Config2__AssetStatus__c =: CANCELLED) '+
                                            ' ORDER BY LastModifiedDate DESC LIMIT 50000';
            return Database.query(queryString);
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() ,'APTS_AccountAssetsViewLightningCtrl', recordId,'CLM',false,false,null,true); return null;}
    }
    
    /**
    * @author        V. Shankaranarayanan
    * @date          29/08/2018
    * @description   Method to get ALIs based on the Serial Number
    * @params        Id, String
    * @return        List<Apttus_Config2__AssetLineItem__c>
    * @revision(s)
    */
    @AuraEnabled
    public static List<Apttus_Config2__AssetLineItem__c> getALIsBySerialNo(Id accountId, String serialNo) {
        try{
            List<Apttus_Config2__AssetLineItem__c> assetList = new List<Apttus_Config2__AssetLineItem__c>();
            String searchText = '%'+serialNo+'%';
            String queryString = '';      
            if(activeAssetQueryMdt != null && activeAssetQueryMdt.size() > 0){
                queryString = activeAssetQueryMdt[activeAssetQueryMdt.size()-1].APTS_Query_String__c;
                if (queryString != null && searchText != null ){
                    queryString = queryString + 'AND APTS_Serial_Number__c LIKE: searchText ';
                }
                assetList = Database.query(queryString);
            }   
            return assetList;
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() ,'APTS_AccountAssetsViewLightningCtrl', recordId,'CLM',false,false,null,true); return null;}
    }
    
    /**
    * @author        V. Shankaranarayanan
    * @date          29/08/2018
    * @description   Method to activate or deactivate ALIs
    * @params        List<Apttus_Config2__AssetLineItem__c>, String
    * @return        void
    * @revision(s)
    */
    @AuraEnabled
    public static void updateAssets(List<String> assetIdList, String status) {
        Set<Id> physicalAssetIdSet = new Set<Id>();
        List<Apttus_Config2__AssetLineItem__c> aLIUpdateList = new List<Apttus_Config2__AssetLineItem__c>();
        for(Apttus_Config2__AssetLineItem__c asset : [SELECT Id, 
                                                      Name, 
                                                      APTS_Sub_Status__c, 
                                                      APTS_Sub_Status_Update_Date__c, 
                                                      APTS_Physical_Asset__c 
                                                      FROM Apttus_Config2__AssetLineItem__c 
                                                      WHERE (Apttus_Config2__LineType__c =: OPTION AND Apttus_Config2__BundleAssetId__c IN: assetIdList) 
                                                      OR Id IN: assetIdList LIMIT 50000]){
            if(INSTALLATION.equalsIgnoreCase(status)){
                asset.APTS_Sub_Status__c = null;
                asset.APTS_Sub_Status_Update_Date__c = null;
                if(asset.APTS_Physical_Asset__c != null) {
                    physicalAssetIdSet.add(asset.APTS_Physical_Asset__c);
                }
                aLIUpdateList.add(asset);
            }else if(DEINSTALLATION.equalsIgnoreCase(status)){
                asset.APTS_Sub_Status__c = TEMPDEACTIVATED;
                asset.APTS_Sub_Status_Update_Date__c = system.today();
                if(asset.APTS_Physical_Asset__c != null) {
                    physicalAssetIdSet.add(asset.APTS_Physical_Asset__c);
                }
                aLIUpdateList.add(asset);
            }
        }
        
        try{
            update aLIUpdateList;
            
            if(!physicalAssetIdSet.isEmpty()){
                if(INSTALLATION.equalsIgnoreCase(status)){
                    updatePhysicalAssets(physicalAssetIdSet, ACTIVATED);
                }else if(DEINSTALLATION.equalsIgnoreCase(status)){
                    updatePhysicalAssets(physicalAssetIdSet, CANCELLED);
                }
            }
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() ,'APTS_AccountAssetsViewLightningCtrl', recordId,'CLM',false,false,null,true);}
    }
    
    /**
    * @author        V. Shankaranarayanan
    * @date          29/08/2018
    * @description   Method to update Physical Assets based on ALI status
    * @params        Set<Id>, String
    * @return        void
    * @revision(s)
    */
    public static void updatePhysicalAssets(Set<Id> physicalAssetIdSet, String status) {
        List<PhysicalAsset__c> physicalAssetUpdateList = new List<PhysicalAsset__c>();
        for(Id phyAssetId : physicalAssetIdSet) {
            PhysicalAsset__c oPhAsset = new PhysicalAsset__c(Id=phyAssetId, AssetStatus__c = status);
            physicalAssetUpdateList.add(oPhAsset);
        }
        try{
            update physicalAssetUpdateList;
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() ,'APTS_AccountAssetsViewLightningCtrl', recordId,'CLM',false,false,null,false);}
    }

 public static Map<String,Date> calculateMinPendingBillingDate(Set<Id> AssetIds){
       Map<String,Date> minPendingBillingDateMap = new Map<String,Date>(); 
        for(AggregateResult billingSch : [select Apttus_Billing__AssetLineItemId__c,MIN(Apttus_Billing__ReadyForInvoiceDate__c) from Apttus_Billing__BillingSchedule__c where Apttus_Billing__Status__c ='Pending Billing' and Apttus_Billing__AssetLineItemId__c IN: AssetIds and Apttus_Billing__PeriodStartDate__c > TODAY group by Apttus_Billing__AssetLineItemId__c]){
            if(minPendingBillingDateMap.get(String.valueOf(billingSch.get('Apttus_Billing__AssetLineItemId__c')))==null){
                minPendingBillingDateMap.put(String.valueOf(billingSch.get('Apttus_Billing__AssetLineItemId__c')),Date.valueOf(billingSch.get('expr0')));
            }
            System.debug('*******minPendingBillingDateMap======>'+minPendingBillingDateMap);
        }
        return minPendingBillingDateMap;
    }
    /**
    * @author        Santosh Kumar
    * @date          04/09/2018
    * @description   Method to create Admin Orders
    * @params        Set<Id>, Id, Id
    * @return        void
    * @revision(s)
    **/
    @AuraEnabled
    public static string createAdminOrder(List<String> assetIdList, Id accountId, Id aggid, APTS_Order_LSP_Details__c olsprecord, String accountlocId,Boolean changeOfOwner) {

        try{
            Apttus_Config2__Order__c oOrder;
            Apttus_Config2__LineItem__c oLineItem;
            Set<Id> assetIdSet = new Set<Id>();
            Map<String,Date> minAssetPendingBillingDateMap = new Map<String,Date>();           


            Id newAccountlocId;
            if(accountlocId != null) {
                newAccountlocId = Id.valueOf(accountlocId);
            }
            
            Database.insert(olsprecord);
            Account oAccount = [SELECT Id, Apttus_Config2__BillingPreferenceId__c, Apttus_Config2__PaymentTermId__c,
                                              Language__c, Sales_Organization__c, Division__c, Distribution_Channel__c,
                                              Bill_To_Payer_Account__c, Related_Payer_Account__c, Related_Payer_Machines_Services__c
                                              FROM Account WHERE Id =:accountId LIMIT 1];

            Apttus__APTS_Agreement__c oAgreement = [SELECT Id, Name, Apttus__Agreement_Number__c, Apttus_CMConfig__PriceListId__c,Apttus_CMConfig__BillingPreferenceId__c, Apttus__Account__c, Apttus_CMConfig__PONumber__c,
                                                            Apttus_CMConfig__PaymentTermId__c, APTS_Language__c, APTS_Distribution_Channel__c,
                                                            APTS_Bill_to_Party_Ingredients__c, APTS_Payer_Ingredients__c, APTS_Bill_to_Party_MachServ__c,
                                                            APTS_Payer_Machines_Services__c,APTS_Check_on_Account_Machines__c,APTS_Check_on_Account_Ingredients__c FROM Apttus__APTS_Agreement__c WHERE Id =:aggid LIMIT 1];

            //Create Admin Order
            oOrder = APTS_CLMUtil.createAdminOrder(oAgreement,oAccount,'Conversion Order');
            if(newAccountlocId != null)
            oOrder.Apttus_Config2__LocationId__c = newAccountlocId; 
             //v105 << ++  
            oOrder.APTS_Change_of_Ownership__c=changeOfOwner;
            oOrder.APTS_Admin_Movement__c=true;
             //v105 >> ++
            //<<!- v103 - Only One Asset can be selected for Each Movement
            if(assetIdList != null && assetIdList.size() == 1){
                List<Apttus_Config2__AssetLineItem__c> assetLineReclist = [Select id,Apttus_Config2__LocationId__c,Apttus_Config2__AccountId__c from Apttus_Config2__AssetLineItem__c where id =: assetIdList ]; 
                if(assetLineReclist.size() > 0){
                    oOrder.APTS_Movement_From_Account__c = assetLineReclist[assetLineReclist.size()-1].Apttus_Config2__AccountId__c;
                    oOrder.APTS_Location_From__c = assetLineReclist[assetLineReclist.size()-1].Apttus_Config2__LocationId__c;  
                }
            }
            // v103 ->>
            Database.insert(oOrder);    
            //Create cart for Order
            Id cartId = APTS_OrderUtils.createCart(oOrder.Id);
               if (cartId != null || Test.isRunningTest()) {
            for(Apttus_Config2__AssetLineItem__c Asli:[select id,Apttus_Config2__LineType__c,Apttus_Config2__BundleAssetId__c from Apttus_Config2__AssetLineItem__c where Apttus_Config2__BundleAssetId__c IN:assetIdList and Apttus_Config2__LineType__c='Option']){
            assetIdSet.add(Asli.Id);
            }
            }
             if(!assetIdSet.isEmpty()){
                minAssetPendingBillingDateMap = calculateMinPendingBillingDate(assetIdSet);
            }

            Map<Id, Apttus_Config2__LineItem__c> mapIdLineItem = new Map<Id, Apttus_Config2__LineItem__c>();
            if(assetIdList.size() > 0){
                mapIdLineItem = APTS_OrderUtils.changeAssets(cartId, assetIdList);
            }

            if(!mapIdLineItem.isEmpty()) {
                for(Apttus_Config2__LineItem__c oLineItemrec : mapIdLineItem.values()) {
                      oLineItemrec.Apttus_Config2__LocationId__c = newAccountlocId;
                      oLineItemrec.APTS_Order_LSP_Detail__c = olsprecord.Id;
                        if(oLineItemrec.Apttus_Config2__LineType__c=='Option' && oLineItemrec.Apttus_Config2__PriceType__c!='One Time' ){
                    //oLineItemrec.Apttus_Config2__StartDate__c= minAssetPendingBillingDateMap.get(oLineItemrec.Apttus_Config2__AssetLineItemId__c);
                    oLineItemrec.Apttus_Config2__StartDate__c= minAssetPendingBillingDateMap.get(oLineItemrec.Apttus_Config2__AssetLineItemId__c)!=null?minAssetPendingBillingDateMap.get(oLineItemrec.Apttus_Config2__AssetLineItemId__c):oLineItemrec.Apttus_Config2__StartDate__c;
                    oLineItemrec.Apttus_Config2__SellingTerm__c=null;        
                    }
                }
                Database.update(mapIdLineItem.values());
             if(oAgreement != null){
                 Set<String> asstIds = new Set<String>(assetIdList);
                 //v102 << ++ Mahesh Chilaka : 05/09/2019 - LAE/RAR Redesign (Creation of Transaction record logic update) - DFT2C-853.
                 Map<Id, Boolean> mapAssetLineItem = new Map<Id, Boolean>();
                //v102 ++ >>

                 List<Apttus_Config2__AssetLineItem__c> chgAgrLst = [select Id,APTS_Financial_Agreement__r.Apttus__Agreement_Number__c, Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c, Apttus_CMConfig__AgreementId__c, Apttus_Config2__AccountId__c, Apttus_CMConfig__AgreementLineItemId__c from Apttus_Config2__AssetLineItem__c where (Id IN :asstIds OR Apttus_Config2__BundleAssetId__c IN :asstIds)];
                 for(Apttus_Config2__AssetLineItem__c chgAgr : chgAgrLst){
system.debug('+++++accountId'+accountId);
system.debug('+++++chgAgr.Apttus_Config2__AccountId__c'+chgAgr.Apttus_Config2__AccountId__c);
                     //v102 << ++
                     if(asstIds.contains(chgAgr.Id)){
                        if(chgAgr.APTS_Financial_Agreement__r.Apttus__Agreement_Number__c != oAgreement.Apttus__Agreement_Number__c || (chgAgr.Apttus_Config2__AccountId__c!=accountId&&accountId!=null)){
                            mapAssetLineItem.put(chgAgr.Id, true);
                        }
                     }
                     //v102 ++ >>
                     //<<<v104 ++
                     chgAgr.APTS_relatedlist_agreement__c = oAgreement.Id;
                      //<<<v105 ++
                     if(oOrder.APTS_Change_of_Ownership__c!=null && oOrder.APTS_Change_of_Ownership__c ){
                        chgAgr.APTS_Financial_Agreement__c = oAgreement.Id; 
                     }
                      // +++ v105 >>
                     // +++ v104 >>
                     chgAgr.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
                     chgAgr.Apttus_CMConfig__AgreementLineItemId__c = null;                     
                 }
                 //v102 << ++ 
                 if(!mapAssetLineItem.isEmpty()){ APTS_AssetLineItemTriggerHandler.createTransDataOnContractChanged(mapAssetLineItem,changeOfOwner,TRUE); }
                 //v102 ++ >>

                 if(chgAgrLst != null){
                     //v106 -- START
                     APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = true;
                     Database.upsert(chgAgrLst);
                     APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = false;
                     //v106 --END
                     /*APTS_CheckRecursive.processedSet.add('APTS_AssetLineItemTriggerHandlerBeforeUpdate');
                     APTS_CheckRecursive.processedSet.add('APTS_AssetLineItemTriggerHandlerAfterUpdate');
                     Database.upsert(chgAgrLst);*/
                 }                     
             }             
             System.enqueueJob(new APTS_AdminOrderQueue(cartId,oOrder.Id,false));
            }
            return 'processed';
        }
        catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage()+'__Stack__'+ex.getStackTraceString() ,'APTS_AccountAssetsViewLightningCtrl', recordId,'CLM',false,false,null,true);return 'error';}

    }
    
    /**
    * @author        V. Shankaranarayanan
    * @date          25/01/2019
    * @description   Method to get the keyprefix of certain objects used in the component
    * @params        NIL
    * @return        Map<String, String>
    * @revision(s)
    */
    @AuraEnabled
    public static Map<String, String> getKeyPrefixes(){
        Map<String, String> keyPrefixMap = new Map<String, String>();
        keyPrefixMap.put('Account', String.valueOf(Schema.getGlobalDescribe().get('Account').getDescribe().getKeyPrefix()));
        keyPrefixMap.put('Apttus__APTS_Agreement__c', String.valueOf(Schema.getGlobalDescribe().get('Apttus__APTS_Agreement__c').getDescribe().getKeyPrefix()));
        keyPrefixMap.put('Apttus_Config2__AccountLocation__c', String.valueOf(Schema.getGlobalDescribe().get('Apttus_Config2__AccountLocation__c').getDescribe().getKeyPrefix()));
        return keyPrefixMap;
    }
    
    /**
    * @author        V. Shankaranarayanan
    * @date          08/03/2019
    * @description   Method to call Movement Order Utils
    * @params        Id, Id, Id, APTS_Order_LSP_Details__c, Id, Date, Date 
    * @return        String
    * @revision(s)   Akanksha Replacing install/de-install dates with movement date
    */
    @AuraEnabled
    public static string invokeMovementUtil(Id assetId, Id accountId, Id aggid, APTS_Order_LSP_Details__c olsprecord, Id accountlocId, Date movementDate,Boolean changeOfOwner) {
        try{
            return APTS_MovementOrderUtils.validate(assetId, aggid, accountId, olsprecord, accountlocId, movementDate,changeOfOwner);
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', String.valueOf(ex) ,'APTS_AccountAssetsViewLightningCtrl', accountId,'CLM',false,false,null,true);return String.valueOf(ex.getMessage());}
    }


    @AuraEnabled
    public static List<Apttus_Config2__AccountLocation__c> getAccountLocations(String selectedSoldTo) {
        try{    
            return [Select id,name,SAP_Customer_ID__c from Apttus_Config2__AccountLocation__c where Apttus_Config2__AccountId__c =: selectedSoldTo];
        }catch(Exception ex){
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', String.valueOf(ex) ,'APTS_AccountAssetsViewLightningCtrl', selectedSoldTo,'CLM',false,false,null,true);return null;
        }
    }


    @AuraEnabled
    public static List<Apttus__APTS_Agreement__c> getRelatedAgreements(String selectedSoldToId) {
        try{    
            Set<Id> realtedAccounts = new Set<Id>();
            Set<String> setAgStatus = APTS_OrderConstants.STANDARD_ORDER_AG_STATUS;
            Map<String,Apttus__APTS_Agreement__c> agreementsToDisplay = new Map<String,Apttus__APTS_Agreement__c>();
            if(selectedSoldToId != null){
                List<Account> selectedSoldTO = [Select id,ParentId,Parent.parentId from account where id =: selectedSoldToId ];
                if(selectedSoldTO.size() > 0){
                    if(selectedSoldTO[selectedSoldTO.size()-1].ParentId != null){ 
                        realtedAccounts.add(selectedSoldTo[selectedSoldTO.size()-1].ParentId);
                        if(selectedSoldTO[selectedSoldTO.size()-1].Parent.ParentId != null){
                            realtedAccounts.add(selectedSoldTo[selectedSoldTO.size()-1].Parent.ParentId);
                        }
                    }
                }
                realtedAccounts.add(selectedSoldToId);
            }
                  
            for(Apttus__APTS_Agreement__c agg : [SELECT Id,Name,RecordType.Name, Apttus__FF_Agreement_Number__c,
                                    Apttus__Account__r.APTS_Account_Level__c  FROM Apttus__APTS_Agreement__c                        
                                    WHERE Apttus__Account__c IN :realtedAccounts AND 
                                    Apttus__Status_Category__c = :APTS_OrderConstants.IN_EFFECT
                                    AND Apttus__Status__c IN :setAgStatus AND //v109
                                    RecordType.Name != :APTS_OrderConstants.REGISTRATION_FORM 
                                    order by Apttus__Account__r.APTS_Account_Level__c desc]){
                if(!agreementsToDisplay.containsKey(agg.RecordType.Name)){
                    agreementsToDisplay.put(agg.RecordType.Name,agg);  
                }                
            }      
            return agreementsToDisplay.values();
            
        }catch(Exception ex){
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', String.valueOf(ex) ,'APTS_AccountAssetsViewLightningCtrl', selectedSoldToId,'CLM',false,false,null,true);return null;
        }
    }
}