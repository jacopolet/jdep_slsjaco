/*************************************************************
@Name: APTS_AssetRollupLineCreation
@Author: Rahul Garje
@CreateDate: 18-07-2018
@Description: Batch class created for migration purposes to create Rollup Lines.
@UsedBy: 
******************************************************************/
global class APTS_AssetRollupLineCreation implements Database.Batchable<sObject> {
    String assetRollupQuery;
    String assetLineItemRollup;  
    Set<String> setTriggers;
    
    global APTS_AssetRollupLineCreation(){
        //Get the query from custom metadata
        List<APTS_Batch_Queries__mdt> lstMetadata = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
            'SELECT APTS_Query_String__c,'+
            'APTS_Batch_Name__c,'+
            'APTS_Triggers__c,'+
            'APTS_Control__c,'+
            'DeveloperName '+
            'FROM APTS_Batch_Queries__mdt '+
            'WHERE DeveloperName = \'CreateAssetRollup\''
        );
        
        List<APTS_Batch_Queries__mdt> assetLineItemSubQuery = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
            'SELECT APTS_Query_String__c,'+
            'APTS_Batch_Name__c,'+
            'APTS_Triggers__c,'+
            'APTS_Control__c,'+
            'DeveloperName '+
            'FROM APTS_Batch_Queries__mdt '+
            'WHERE DeveloperName = \'Asset_LineItem_Rollup\''
        );
        
        if(assetLineItemSubQuery.size()>0){
            assetLineItemRollup = assetLineItemSubQuery[0].APTS_Query_String__c;
        } 
        
        List<String> splitString = lstMetadata[0].APTS_Triggers__c.split(',');
        setTriggers = new Set<String>(splitString);
        if(lstMetadata.size()>0){
            assetRollupQuery = lstMetadata[0].APTS_Query_String__c;
        } 
    }
    //start method
    global Database.QueryLocator start(Database.BatchableContext BC){
         //Inactivate triggers
        APTS_BillingSchedulesLoadBatchHelper.modifyTriggers(setTriggers,'Deactivate');
        //Query to get all the Agreement and associated Asset Line Item migrated from Data Migration (identified by using Source system != '')
        return Database.getQueryLocator(assetRollupQuery);
    }
    
    //Execute method with Agreement as a scope.
    global void execute(Database.BatchableContext BC, List<Apttus__APTS_Agreement__c> scope){
        
        List<Apttus_Config2__AssetLineItem__c> assetRollUpList = new List<Apttus_Config2__AssetLineItem__c>(); // List to create Rollup lines.
        List<Apttus_Config2__AssetLineItem__c> updateAssetList = New List<Apttus_Config2__AssetLineItem__c>(); //List to update primary Asset with Pricing fields.
        Map<String,List<Apttus_Config2__AssetLineItem__c>> bundleWithOptionAssets = new Map<String,List<Apttus_Config2__AssetLineItem__c>>(); //Map to hold Bundle Asset with Option Asset
        Map<String,List<Apttus_Config2__AssetLineItem__c>> bundleWithRollUpAssets = new Map<String,List<Apttus_Config2__AssetLineItem__c>>(); //Map to hold Bundle with Rollup Lines already created
        //To Optimize the Code as part of 2019 CR - SAI SAGAR 17th Sep 2018
        Map<Id,List<Apttus_Config2__AssetLineItem__c>> agreementWithBundleAssets = new Map<Id,List<Apttus_Config2__AssetLineItem__c>>(); //Map to hold Agreement and Asset Lines Bundels

        Database.SaveResult[] srList;
        List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>();
        Set<Id> agreementid = New Set<Id>();
        
        for(Apttus__APTS_Agreement__c agreementlist: scope){
            agreementid.add(agreementlist.id);
        }
        
        for(Apttus_Config2__AssetLineItem__c processAssets : Database.Query(assetLineItemRollup)){
            if(processAssets.Apttus_Config2__LineType__c == 'Option'){
                if(bundleWithOptionAssets.containsKey(processAssets.Apttus_Config2__ProductId__c+'-'+processAssets.Apttus_Config2__ParentBundleNumber__c)){
                    List<Apttus_Config2__AssetLineItem__c> optionProductList = bundleWithOptionAssets.get(processAssets.Apttus_Config2__ProductId__c+'-'+processAssets.Apttus_Config2__ParentBundleNumber__c);
                    optionProductList.add(processAssets);
                    bundleWithOptionAssets.put(processAssets.Apttus_Config2__ProductId__c+'-'+processAssets.Apttus_Config2__ParentBundleNumber__c,optionProductList);       
                } else { 
                    List<Apttus_Config2__AssetLineItem__c> optionProductList = new  List<Apttus_Config2__AssetLineItem__c> ();
                    optionProductList.add(processAssets);               
                    bundleWithOptionAssets.put(processAssets.Apttus_Config2__ProductId__c+'-'+processAssets.Apttus_Config2__ParentBundleNumber__c,optionProductList);
                }
            }
                        
            //Condition to store Bundle Assets with Rollup Asset Lines. //if there are multiple bundles within the Agreement.
            if(processAssets.Apttus_Config2__LineType__c == 'Product/Service') {
                if(bundleWithRollUpAssets.containsKey(processAssets.Apttus_Config2__ProductId__c+'-'+processAssets.Apttus_Config2__PrimaryLineNumber__c)){ 
                    List<Apttus_Config2__AssetLineItem__c> rollUpAssetList = bundleWithRollUpAssets.get(processAssets.Apttus_Config2__ProductId__c+'-'+processAssets.Apttus_Config2__PrimaryLineNumber__c);
                    rollUpAssetList.add(processAssets);
                    bundleWithRollUpAssets.put(processAssets.Apttus_Config2__ProductId__c+'-'+processAssets.Apttus_Config2__PrimaryLineNumber__c,rollUpAssetList);        
                } else {
                    List<Apttus_Config2__AssetLineItem__c> rollUpAssetList = new  List<Apttus_Config2__AssetLineItem__c> ();
                    rollUpAssetList.add(processAssets);               
                    bundleWithRollUpAssets.put(processAssets.Apttus_Config2__ProductId__c+'-'+processAssets.Apttus_Config2__PrimaryLineNumber__c,rollUpAssetList);
                }   
                if(processAssets.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c == 'Standalone'){
                    processAssets = APTS_AssetRollupLineCreation.setPrimaryLineOne(processAssets);
                    if(processAssets.APTS_Is_Primary_L1_Line__c){
                        updateAssetList.add(processAssets);
                    }                                               
                }
            }
            if(processAssets.Apttus_Config2__OptionId__c == null && processAssets.Apttus_Config2__IsOptionRollupLine__c == false){
                if(agreementWithBundleAssets.containsKey(processAssets.Apttus_CMConfig__AgreementId__c)){
                    agreementWithBundleAssets.get(processAssets.Apttus_CMConfig__AgreementId__c).add(processAssets); 
                }else{
                    List<Apttus_Config2__AssetLineItem__c> bundleAssetsList = new List<Apttus_Config2__AssetLineItem__c>();
                    bundleAssetsList.add(processAssets);
                    agreementWithBundleAssets.put(processAssets.Apttus_CMConfig__AgreementId__c,bundleAssetsList);              
                } 
            }          
        }
        
        //Iterate through the scope Agreement list.
        for (Apttus__APTS_Agreement__c agreementlist: scope) {
         try{  
            //Query to get all the Bundle Asset with Rollup lines used to update pricing logic fields.
            // Commented - To Optimize the Code as part of 2019 CR - SAI SAGAR 17th Sep 2018
            //List<Apttus_Config2__AssetLineItem__c> assettoUpdateCheckList= [Select id ,Apttus_Config2__ChargeType__c ,Apttus_Config2__ProductId__c,Apttus_Config2__ExtendedPrice__c,Apttus_Config2__ParentAssetId__r.Apttus_Config2__PrimaryLineNumber__c,Apttus_Config2__PrimaryLineNumber__c,Apttus_Config2__ParentBundleNumber__c,Apttus_Config2__BaseExtendedPrice__c,Apttus_Config2__NetPrice__c,Apttus_Config2__BasePrice__c,Apttus_Config2__SellingTerm__c,Apttus_Config2__AdjustedPrice__c,Apttus_Config2__Quantity__c,Apttus_Config2__OptionPrice__c from Apttus_Config2__AssetLineItem__c where Apttus_Config2__OptionId__c = null and Apttus_Config2__IsOptionRollupLine__c = false and Apttus_CMConfig__AgreementId__c =:agreementlist.id];
            List<Apttus_Config2__AssetLineItem__c> assettoUpdateCheckList = new List<Apttus_Config2__AssetLineItem__c>();
            if(agreementWithBundleAssets.containsKey(agreementlist.id)){
                assettoUpdateCheckList.addAll(agreementWithBundleAssets.get(agreementlist.id));
            }           
            
            Map<String, Apttus_Config2__AssetLineItem__c> bundlePrdctChargeTypewithOptnPrdct = New Map<String, Apttus_Config2__AssetLineItem__c>(); //to hold unique parent bundle Asset with Charge Type and value as Bundle Asset
            for(Apttus_Config2__AssetLineItem__c bundleAsset : assettoUpdateCheckList){
                bundlePrdctChargeTypewithOptnPrdct.put(bundleAsset.Apttus_Config2__ProductId__c+';'+bundleAsset.Apttus_Config2__ChargeType__c+';'+bundleAsset.Apttus_Config2__PrimaryLineNumber__c,bundleAsset);
            }
            
            Map<String,ID> optionChargeTypestoBundleProduct = new Map<String,ID>(); 
            List<Apttus_Config2__AssetLineItem__c> rollUpProductList = New List<Apttus_Config2__AssetLineItem__c>();
            
            //Iterate through the bundle product list 
            for (String bundleProducts: bundleWithOptionAssets.keySet()) {
                List<Apttus_Config2__AssetLineItem__c> optionProductList = bundleWithOptionAssets.get(bundleProducts); //Get all the Option Product Associated that bundle product.
                Map<String,Apttus_Config2__AssetLineItem__c>  toCheckExistingFetched = new Map<String,Apttus_Config2__AssetLineItem__c>(); //Check already Bundle with same charge type is fetched.
                Decimal updateBaseExtendedPrice = 0;
                Decimal updateOptionPrice = 0;
                Decimal updateExtendedPrice=0;
                Decimal updateAdjustedPrice = 0;
                Decimal updateNetPrice = 0;
                
                //iterate through all the option products inside the bundle products
                for(Apttus_Config2__AssetLineItem__c sumOptionFields : optionProductList ){
                    List<Apttus_Config2__AssetLineItem__c> updateAsset = new List<Apttus_Config2__AssetLineItem__c>(); //List to hold the Bundle/Primary Asset need to be updated
                    if(bundlePrdctChargeTypewithOptnPrdct.get(sumOptionFields.Apttus_Config2__ProductId__c+';'+sumOptionFields.Apttus_Config2__ChargeType__c+';'+sumOptionFields.Apttus_Config2__ParentBundleNumber__c)!=null)
                    updateAsset.add(bundlePrdctChargeTypewithOptnPrdct.get(sumOptionFields.Apttus_Config2__ProductId__c+';'+sumOptionFields.Apttus_Config2__ChargeType__c+';'+sumOptionFields.Apttus_Config2__ParentBundleNumber__c));
                
                    if(updateAsset!=null & updateAsset.size()>0){ 
                        updateAsset[0].Apttus_Config2__BaseExtendedPrice__c = 0;    
                        updateAsset[0].Apttus_Config2__OptionPrice__c = 0;
                        updateAsset[0].Apttus_Config2__ExtendedPrice__c = 0;
                        updateAsset[0].Apttus_Config2__AdjustedPrice__c = 0;
                        updateAsset[0].Apttus_Config2__NetPrice__c = 0;
                        if(toCheckExistingFetched.containsKey(updateAsset[0].id)){
                            Apttus_Config2__AssetLineItem__c temp = toCheckExistingFetched.get(updateAsset[0].id);
                            updateBaseExtendedPrice = updateBaseExtendedPrice + (temp.Apttus_Config2__BasePrice__c == null ?0:temp.Apttus_Config2__BasePrice__c) * temp.Apttus_Config2__Quantity__c * temp.Apttus_Config2__SellingTerm__c;
                            temp.Apttus_Config2__BaseExtendedPrice__c = updateBaseExtendedPrice;
                            updateOptionPrice = updateOptionPrice + (temp.Apttus_Config2__OptionPrice__c == null?0:temp.Apttus_Config2__OptionPrice__c)+(sumOptionFields.Apttus_Config2__AdjustedPrice__c == null?0:sumOptionFields.Apttus_Config2__AdjustedPrice__c);
                            temp.Apttus_Config2__OptionPrice__c = updateOptionPrice;
                            updateExtendedPrice = (temp.Apttus_Config2__BaseExtendedPrice__c == null?0:temp.Apttus_Config2__BaseExtendedPrice__c) + (updateOptionPrice * temp.Apttus_Config2__Quantity__c);
                            temp.Apttus_Config2__ExtendedPrice__c = updateExtendedPrice;
                            updateAdjustedPrice = updateExtendedPrice;
                            temp.Apttus_Config2__AdjustedPrice__c = updateAdjustedPrice;
                            updateNetPrice = updateAdjustedPrice;
                            temp.Apttus_Config2__NetPrice__c = updateNetPrice;
                            temp.Apttus_Config2__NetUnitPrice__c = (updateNetPrice == 0?0: updateNetPrice/ (temp.Apttus_Config2__Quantity__c * temp.Apttus_Config2__SellingTerm__c));                    
                            toCheckExistingFetched.put(temp.id,temp);
                        }
                        else{
                            if(updateAsset[0].Apttus_Config2__OptionPrice__c==null){updateAsset[0].Apttus_Config2__OptionPrice__c=0;}
                            System.debug('updateAsset[0]'+ updateAsset[0]);
                            updateBaseExtendedPrice = updateBaseExtendedPrice + (updateAsset[0].Apttus_Config2__BasePrice__c == null ? 0:updateAsset[0].Apttus_Config2__BasePrice__c) * updateAsset[0].Apttus_Config2__Quantity__c *updateAsset[0].Apttus_Config2__SellingTerm__c;
                            updateAsset[0].Apttus_Config2__BaseExtendedPrice__c = updateBaseExtendedPrice;
                            updateOptionPrice = updateOptionPrice + (updateAsset[0].Apttus_Config2__OptionPrice__c == null?0:updateAsset[0].Apttus_Config2__OptionPrice__c)+(sumOptionFields.Apttus_Config2__AdjustedPrice__c == null?0:sumOptionFields.Apttus_Config2__AdjustedPrice__c);
                            updateAsset[0].Apttus_Config2__OptionPrice__c = updateOptionPrice;
                            updateExtendedPrice = (updateAsset[0].Apttus_Config2__BaseExtendedPrice__c== null?0:updateAsset[0].Apttus_Config2__BaseExtendedPrice__c)+ (updateOptionPrice * updateAsset[0].Apttus_Config2__Quantity__c);
                            updateAsset[0].Apttus_Config2__ExtendedPrice__c = updateExtendedPrice;
                            updateAdjustedPrice = updateExtendedPrice;  
                            updateAsset[0].Apttus_Config2__AdjustedPrice__c = updateAdjustedPrice;
                            updateNetPrice = updateAdjustedPrice;
                            updateAsset[0].Apttus_Config2__NetPrice__c = updateNetPrice;
                            updateAsset[0].Apttus_Config2__NetUnitPrice__c = (updateNetPrice == 0?0: updateNetPrice/ (updateAsset[0].Apttus_Config2__Quantity__c * updateAsset[0].Apttus_Config2__SellingTerm__c));
                            toCheckExistingFetched.put(updateAsset[0].id,updateAsset[0]);
                        }
                    }           
                }
                rollUpProductList = bundleWithRollUpAssets.get(bundleProducts); //List to hold bundle Asset 
                System.debug('rollUpProductList-->'+rollUpProductList);
                System.debug('bundleWithRollUpAssets.get(bundleProducts)-->'+bundleWithRollUpAssets.get(bundleProducts));
                Set<String> rollUpExists = New Set<String>(); //String to hold Charge Type 
                
                //Iterate over Rollup Asset to get the Charge Type
                if(rollUpProductList != null && rollUpProductList.Size() > 0){
                    for(Apttus_Config2__AssetLineItem__c rolluplist :rollUpProductList){                        
                        if(toCheckExistingFetched.containsKey(rolluplist.id)){
                            Apttus_Config2__AssetLineItem__c mappedAsset = new Apttus_Config2__AssetLineItem__c();
                            mappedAsset = toCheckExistingFetched.get(rolluplist.id);
                            mappedAsset  = APTS_AssetRollupLineCreation.setPrimaryLineOne(mappedAsset);
                            if(mappedAsset.APTS_Is_Primary_L1_Line__c){
                                toCheckExistingFetched.put(mappedAsset.id,mappedAsset);
                            }                           
                        }else{
                            rolluplist = APTS_AssetRollupLineCreation.setPrimaryLineOne(rolluplist);
                            if(rolluplist.APTS_Is_Primary_L1_Line__c){
                                toCheckExistingFetched.put(rolluplist.id,rolluplist);
                            }                           
                        }
                        rollUpExists.add(rolluplist.Apttus_Config2__ChargeType__c); //add the Charge Type for the existing/Primary Roll ups
                    }
                }   
                System.debug('updateAssetList size---->'+updateAssetList.size());
                updateAssetList.addALL(toCheckExistingFetched.values());
                System.debug('updateAssetList---->'+updateAssetList);
                System.debug('rollUpExists-->'+rollUpExists);
                Map<String,List<Apttus_Config2__AssetLineItem__c>> chargeTypeWithOptionAsset = New Map<String,List<Apttus_Config2__AssetLineItem__c>>();  //Map to get the ChargeType with Option Assets.
                optionChargeTypestoBundleProduct = new Map<String,ID>();
                Integer itemSequence = 1;               
                
                //Iterate over the option Assets and store in the map with key as a CT and OptionAsset as Value
                for (Apttus_Config2__AssetLineItem__c getChargeTypes:optionProductList) {
                    if (chargeTypeWithOptionAsset.containsKey(getChargeTypes.Apttus_Config2__ChargeType__c)) {
                        List<Apttus_Config2__AssetLineItem__c> tempList = chargeTypeWithOptionAsset.get(getChargeTypes.Apttus_Config2__ChargeType__c); 
                        tempList.add(getChargeTypes);
                        chargeTypeWithOptionAsset.put(getChargeTypes.Apttus_Config2__ChargeType__c,tempList);    
                    } else {
                        List<Apttus_Config2__AssetLineItem__c> tempList = New List<Apttus_Config2__AssetLineItem__c>();
                        tempList.add(getChargeTypes);
                        chargeTypeWithOptionAsset.put(getChargeTypes.Apttus_Config2__ChargeType__c,tempList);
                    }                       
                }
                
                //Iterate over the option Asset and create the rollup lines.
                for(Apttus_Config2__AssetLineItem__c processOptionAsset: optionProductList){   
                    if((optionChargeTypestoBundleProduct.get(processOptionAsset.Apttus_Config2__ChargeType__c) != processOptionAsset.Apttus_Config2__ProductId__c) || Test.isRunningTest()){
                        
                        //Check if the Rollup already exist then don't create a Rollup line.
                        if(!rollUpExists.contains(processOptionAsset.Apttus_Config2__ChargeType__c)){                  
                            Apttus_Config2__AssetLineItem__c createRollUpAsset = new Apttus_Config2__AssetLineItem__c();
                            createRollUpAsset.Name = processOptionAsset.Apttus_Config2__ProductId__r.Name;
                            createRollUpAsset.Apttus_Config2__LineNumber__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__LineNumber__c;
                            createRollUpAsset.Apttus_Config2__BusinessObjectId__c = processOptionAsset.Apttus_Config2__BusinessObjectId__c;
                            createRollUpAsset.Apttus_Config2__BusinessObjectType__c = processOptionAsset.Apttus_Config2__BusinessObjectType__c;
                            createRollUpAsset.Apttus_Config2__LineType__c ='Product/Service';
                            createRollUpAsset.Apttus_Config2__AssetStatus__c = processOptionAsset.Apttus_Config2__AssetStatus__c;
                            createRollUpAsset.Apttus_Config2__Description__c = processOptionAsset.Apttus_Config2__ProductId__r.Name+'_DM';
                            createRollUpAsset.Apttus_Config2__ProductId__c = processOptionAsset.Apttus_Config2__ProductId__c;
                            createRollUpAsset.Apttus_Config2__ChargeType__c = processOptionAsset.Apttus_Config2__ChargeType__c;
                            createRollUpAsset.Apttus_Config2__BundleAssetId__c = processOptionAsset.Apttus_Config2__BundleAssetId__c;
                            createRollUpAsset.Apttus_Config2__AccountId__c = processOptionAsset.Apttus_Config2__AccountId__c;
                            createRollUpAsset.Apttus_CMConfig__AgreementId__c = processOptionAsset.Apttus_CMConfig__AgreementId__c;
                            createRollUpAsset.Apttus_Config2__IsOptionRollupLine__c = True;
                            createRollUpAsset.Apttus_Config2__HasOptions__c = True;
                            createRollUpAsset.Apttus_Config2__BillToAccountId__c = processOptionAsset.Apttus_Config2__BillToAccountId__c;
                            
                            //09-July-2018
                            createRollUpAsset.APTS_SourceSystem__c = processOptionAsset.APTS_SourceSystem__c;
                            createRollUpAsset.Apttus_Config2__BillingPreferenceId__c = processOptionAsset.Apttus_Config2__BillingPreferenceId__c;  //RG: Fix for ALM D-17300
                            createRollUpAsset.Apttus_Config2__AttributeValueId__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__AttributeValueId__c;
                            createRollUpAsset.APTS_MigrationDate__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.APTS_MigrationDate__c;
                            createRollUpAsset.Apttus_Config2__BillingFrequency__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__BillingFrequency__c;
                            createRollUpAsset.Apttus_Config2__SellingTerm__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__SellingTerm__c;
                            createRollUpAsset.Apttus_Config2__PrimaryLineNumber__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__PrimaryLineNumber__c;
                            createRollUpAsset.Apttus_Config2__PriceListId__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__PriceListId__c;
                            createRollUpAsset.Apttus_Config2__ShipToAccountId__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__ShipToAccountId__c;
                            createRollUpAsset.Apttus_Config2__OriginalStartDate__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__OriginalStartDate__c;
                            createRollUpAsset.Apttus_Config2__StartDate__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__StartDate__c;
                            createRollUpAsset.Apttus_Config2__EndDate__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c;
                            createRollUpAsset.Apttus_Config2__Quantity__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__Quantity__c;
                            createRollUpAsset.Apttus_Config2__DeltaQuantity__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__DeltaQuantity__c;
                            createRollUpAsset.Apttus_Config2__PriceUom__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__PriceUom__c;
                            createRollUpAsset.Apttus_Config2__BasePriceMethod__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__BasePriceMethod__c;
                            createRollUpAsset.Apttus_Config2__PriceMethod__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__PriceMethod__c;
                            createRollUpAsset.Apttus_Config2__PriceType__c = processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__PriceType__c; 
                            itemSequence = itemSequence + (processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__ItemSequence__c == null?0:Integer.valueOf(processOptionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__ItemSequence__c));
                            createRollUpAsset.Apttus_Config2__ItemSequence__c = itemSequence;
                            
                            // 13th Sep 2018
                            createRollUpAsset.APTS_Type_Of_Contract__c = processOptionAsset.APTS_Type_Of_Contract__c;
                            createRollUpAsset = APTS_AssetRollupLineCreation.setPrimaryLineOne(createRollUpAsset);

                            List<Apttus_Config2__AssetLineItem__c> tempList = chargeTypeWithOptionAsset.get(processOptionAsset.Apttus_Config2__ChargeType__c);
                            
                            Decimal OptionPrice = 0;
                            Decimal ExtendedPrice=0;
                            Decimal AdjustedPrice = 0;
                            Decimal NetPrice = 0;
                            Date BillingStartDate;
                            Date BillingEndDate;
                            
                            Date FirstStartDate = tempList[0].Apttus_Config2__BillingStartDate__c;
                            Date FirstEndtDate = tempList[0].Apttus_Config2__BillingEndDate__c;
                            
                            BillingStartDate = FirstStartDate;
                            BillingEndDate = FirstEndtDate;
                            
                            for(Apttus_Config2__AssetLineItem__c itr:tempList){
                                if(itr.Apttus_Config2__AdjustedPrice__c != null){
                                    OptionPrice = OptionPrice + itr.Apttus_Config2__AdjustedPrice__c;
                                } 
                                if(itr.Apttus_Config2__BillingStartDate__c <= FirstStartDate){
                                    BillingStartDate = itr.Apttus_Config2__BillingStartDate__c;
                                }
                                if(itr.Apttus_Config2__BillingEndDate__c >= FirstEndtDate){
                                    BillingEndDate = itr.Apttus_Config2__BillingEndDate__c;
                                }
                            }
                            ExtendedPrice = ((createRollUpAsset.Apttus_Config2__BaseExtendedPrice__c == null?0:createRollUpAsset.Apttus_Config2__BaseExtendedPrice__c)+ (OptionPrice * (createRollUpAsset.Apttus_Config2__Quantity__c == null ? 1:createRollUpAsset.Apttus_Config2__Quantity__c)));  //(BP + OP) * Quantity * Selling Term   
                            AdjustedPrice = ExtendedPrice;
                            NetPrice = AdjustedPrice;
                            
                            createRollUpAsset.Apttus_Config2__BillingStartDate__c = BillingStartDate;
                            createRollUpAsset.Apttus_Config2__BillingEndDate__c = BillingEndDate;
                            createRollUpAsset.Apttus_Config2__OptionPrice__c = OptionPrice;
                            createRollUpAsset.Apttus_Config2__ExtendedPrice__c = ExtendedPrice;
                            createRollUpAsset.Apttus_Config2__AdjustedPrice__c = AdjustedPrice;
                            createRollUpAsset.Apttus_Config2__NetPrice__c = NetPrice;  
                            createRollUpAsset.Apttus_Config2__NetUnitPrice__c = (NetPrice == 0?0: NetPrice / (createRollUpAsset.Apttus_Config2__Quantity__c * createRollUpAsset.Apttus_Config2__SellingTerm__c));                    
                            optionChargeTypestoBundleProduct.put(processOptionAsset.Apttus_Config2__ChargeType__c,processOptionAsset.Apttus_Config2__ProductId__c); //compare with the previous record
                            assetRollUpList.add(createRollUpAsset);
                        } 
                    }               
                }  
            } 
          } catch(Exception e){
                System.debug('exception-->'+e);
                APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Batch', e.getStackTraceString()+e ,'Asset Line Item',agreementlist.id,'CLM',false,true,'rgarje@apttus.com',true);
            }    
        }
        // Update the already Asset with Pricing Logic
        if(updateAssetList != null && updateAssetList.size()>0) {
             srList = Database.update(updateAssetList,false); 
            
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully updated ALI. ALI Id: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        lstErrorLogs.add(APTS_BillingSchedulesLoadBatchHelper.createBatchErrorObject(err.getStatusCode() + ': ' + err.getMessage() + '--' + + err.getFields(), sr.getId(),'Apttus_Config2__AssetLineItem__c'));
                        
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Fields that affected this error: ' + err.getFields());
                    }
                }
            }  
        }
        // Create a New Rollup Lines
        if(assetRollUpList != null && assetRollUpList.size()>0) {
            srList = Database.insert(assetRollUpList,false); 
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully created ALItem. ALI Id: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        lstErrorLogs.add(APTS_BillingSchedulesLoadBatchHelper.createBatchErrorObject(err.getStatusCode() + ': ' + err.getMessage() + '--' + + err.getFields(), sr.getId(),'Apttus_Config2__AssetLineItem__c'));

                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Fields that affected this error: ' + err.getFields());
                    }
                }
            }  
        }
        
        //Register error logs
        System.debug('lstErrorLogs--->'+lstErrorLogs);
        if(lstErrorLogs.size() > 0){
            insert lstErrorLogs;
        }  
    }
    global void finish(Database.BatchableContext BC){
        //Activate triggers
        APTS_BillingSchedulesLoadBatchHelper.modifyTriggers(setTriggers,'Activate');   
    }

    global static Apttus_Config2__AssetLineItem__c setPrimaryLineOne(Apttus_Config2__AssetLineItem__c lineItem){
        if(lineItem != null && lineItem.APTS_Type_Of_Contract__c != null && lineItem.APTS_Type_Of_Contract__c != null &&
            (((lineItem.APTS_Type_Of_Contract__c == 'Sales' || lineItem.APTS_Type_Of_Contract__c == 'Trial' ) && 
                lineItem.Apttus_Config2__ChargeType__c == 'Sales Price') ||
            ((lineItem.APTS_Type_Of_Contract__c == 'Rent' || lineItem.APTS_Type_Of_Contract__c == 'RentBuy' || 
                lineItem.APTS_Type_Of_Contract__c == 'Free On Loan' || lineItem.APTS_Type_Of_Contract__c == 'Consumption' ) && 
                lineItem.Apttus_Config2__ChargeType__c == 'Rental Fee'))) {
            lineItem.APTS_Is_Primary_L1_Line__c = true;         
        }       
        return lineItem;
    }
}