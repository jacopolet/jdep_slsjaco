/*************************************************************
@Name: APTS_IndexationBatch_Phase1_Test
@Author: Akhilesh Arjunan
@CreateDate: 06/14/2019
@Description: Apex Class to test APTS_IndexationBatch_Phase1 Class 
******************************************************************/
@isTest
private class APTS_IndexationBatch_Phase1_Test{
    
    @isTest
    static void standardindexmethod(){
        
        Account acc = APTS_TestUtils.createGrandParentAccount();
        Database.insert(acc,false);
        
        Contact cont = APTS_TestUtils.createContact();
        Database.insert(cont,false);
        
        Apttus_Config2__PriceList__c plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
        
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(cont.Id,null,plist.Id,acc.Id);
        aggr.Apttus__Contract_End_Date__c = System.today()-1;
        aggr.Apttus__Account__c = acc.Id;
        aggr.Apttus__Status_Category__c = 'In Effect';
        aggr.Apttus__Status__c = 'Activated';
        aggr.Apttus__Contract_Start_Date__c = System.today()-50;
        aggr.Apttus__Auto_Renewal__c = true;
        insert aggr;
        
        Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
        tstAsset.Apttus_Config2__LineNumber__c = 1;
        tstAsset.Apttus_Config2__PrimaryLineNumber__c = 1;
        tstAsset.Apttus_Config2__NetPrice__c = 100;
        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.APTS_Old_Net_Price__c = 100;
        //tstAsset.APTS_Is_Primary_L1_Asset__r.name = asset.Name;
        tstAsset.Apttus_Config2__HasOptions__c = true;
        tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset.APTS_Type_Of_Contract__c = 'Sales';
        tstAsset.APTS_Is_Primary_L1_Line__c = true;
        tstAsset.Apttus_Config2__IsPrimaryLine__c = true;
        tstAsset.Apttus_CMConfig__AgreementId__c = aggr.Id;
        tstAsset.APTS_relatedlist_agreement__c = aggr.Id;
        tstAsset.Apttus_Config2__AccountId__c = acc.Id;
        tstAsset.APTS_Option_Group_Text__c = 'Technical Service';
        tstAsset.APTS_Is_Indexation_Executed__c = false;
        tstAsset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
        insert tstAsset;
        
        List<Apttus_Config2__AssetLineItem__c> assetlst = new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__AssetLineItem__c asset = new Apttus_Config2__AssetLineItem__c();
        //asset.Name = 'Test Asset';
        asset.Apttus_Config2__AssetStatus__c = 'Activated';
        asset.APTS_Old_Net_Price__c = 100;
        asset.Apttus_Config2__LineType__c = 'option';
        asset.Apttus_Config2__ChargeType__c = 'Sales Price';
        asset.APTS_Type_Of_Contract__c = 'Sales';
        asset.Apttus_CMConfig__AgreementId__c = aggr.Id;
        asset.APTS_relatedlist_agreement__c = aggr.Id;
        asset.Apttus_Config2__AccountId__c = acc.Id;
        asset.APTS_Option_Group_Text__c = 'Technical Service';
        asset.APTS_Is_Indexation_Executed__c = false;
        asset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
        asset.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
        asset.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
        assetlst.add(asset);
        //insert asset;   
        
        Apttus_Config2__AssetLineItem__c asset1 = new Apttus_Config2__AssetLineItem__c();
        //asset.Name = 'Test Asset';
        asset1.Apttus_Config2__AssetStatus__c = 'Activated';
        asset1.APTS_Old_Net_Price__c = 100;
        asset1.Apttus_Config2__LineType__c = 'option';
        asset.Apttus_Config2__ChargeType__c = 'Service Fee';
        asset.APTS_Type_Of_Contract__c = 'Rent';
        asset1.Apttus_CMConfig__AgreementId__c = aggr.Id;
        asset1.APTS_relatedlist_agreement__c = aggr.Id;
        asset1.Apttus_Config2__AccountId__c = acc.Id;
        asset1.APTS_Option_Group_Text__c = 'Machine Care';
        asset1.APTS_Is_Indexation_Executed__c = false;
        asset1.Apttus_Config2__EndDate__c = Date.today().addDays(100);
        asset1.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
        asset1.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
        assetlst.add(asset1);
        
        Apttus_Config2__AssetLineItem__c asset2 = new Apttus_Config2__AssetLineItem__c();
        //asset.Name = 'Test Asset';
        asset2.Apttus_Config2__AssetStatus__c = 'Activated';
        asset2.APTS_Old_Net_Price__c = 100;
        asset2.Apttus_Config2__LineType__c = 'option';
        asset2.Apttus_Config2__ChargeType__c = 'Sales Price';
        asset2.APTS_Type_Of_Contract__c = 'Sales';
        asset2.Apttus_CMConfig__AgreementId__c = aggr.Id;
        asset2.APTS_relatedlist_agreement__c = aggr.Id;
        asset2.Apttus_Config2__AccountId__c = acc.Id;
        asset2.APTS_Option_Group_Text__c = 'Value Added Machine Care';
        asset2.APTS_Is_Indexation_Executed__c = false;
        asset2.Apttus_Config2__EndDate__c = Date.today().addDays(100);
        asset2.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
        asset2.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
        assetlst.add(asset2);
        Database.insert(assetlst,false);  
        
        APTS_Index_Contract__c cntrct = new APTS_Index_Contract__c();
        cntrct.APTS_Indexation_Category__c = 'Technical Services';
        cntrct.APTS_Index_Type__c = 'Standard Indexation';
        cntrct.APTS_Frequency__c = 'Yearly';
        cntrct.APTS_Start_Date__c = system.today();
        cntrct.APTS_Contract__c = aggr.Id;
        //cntrct.APTS_Indexation_Number__c = '123';
        //cntrct.APTS_Index_Country__c = 'Netherlands';
        Database.insert(cntrct,false);
        
        test.startTest();
        APTS_IndexationBatch_Phase1 b = new APTS_IndexationBatch_Phase1('Netherlands');
        Database.executeBatch(b,200);      
        test.stopTest();
    }
    
    @isTest
    static void nonstandardindexmethod(){
        try{
            List<APTS_Indexation_Executing__c> indexExecuteList=new list <APTS_Indexation_Executing__c>();
            
            Account acc = APTS_TestUtils.createaccount();
            Database.insert(acc,false);
            
            Contact cont = APTS_TestUtils.createContact();
            Database.insert(cont,false);
            
            Apttus_Config2__PriceList__c plist = APTS_TestUtils.createPriceList();
            Database.insert(plist,false);
            
            List<Apttus__APTS_Agreement__c> agrlst = new List<Apttus__APTS_Agreement__c>(); 
            
            Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(cont.Id,null,plist.Id,acc.Id);
            aggr.Apttus__Contract_End_Date__c = System.today()-1;
            aggr.Apttus__Account__c = acc.Id;
            aggr.Apttus__Status_Category__c = 'In Effect';
            aggr.Apttus__Status__c = 'Activated';
            aggr.Apttus__Contract_Start_Date__c = System.today()-50;
            aggr.Apttus__Auto_Renewal__c = true;
            agrlst.add(aggr);
            Database.insert(agrlst,false); 
            
            Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
            tstAsset.Apttus_Config2__LineNumber__c = 1;
            tstAsset.Apttus_Config2__PrimaryLineNumber__c = 1;
            tstAsset.Apttus_Config2__NetPrice__c = 100;
            tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
            tstAsset.APTS_Old_Net_Price__c = 100;
            //tstAsset.APTS_Is_Primary_L1_Asset__r.name = asset.Name;
            tstAsset.Apttus_Config2__HasOptions__c = true;
            tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
            tstAsset.Apttus_Config2__ChargeType__c = 'Sales Price';
            tstAsset.APTS_Type_Of_Contract__c = 'Sales';
            tstAsset.APTS_Is_Primary_L1_Line__c = true;
            tstAsset.Apttus_Config2__IsPrimaryLine__c = true;
            tstAsset.Apttus_CMConfig__AgreementId__c = agrlst[0].Id;
            tstAsset.APTS_relatedlist_agreement__c = agrlst[0].Id;
            tstAsset.Apttus_Config2__AccountId__c = acc.Id;
            tstAsset.APTS_Option_Group_Text__c = 'Technical Service';
            tstAsset.APTS_Is_Indexation_Executed__c = false;
            tstAsset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
            insert tstAsset;
            
            List<Apttus_Config2__AssetLineItem__c> assetlst = new List<Apttus_Config2__AssetLineItem__c>();
            Apttus_Config2__AssetLineItem__c asset = new Apttus_Config2__AssetLineItem__c();
            asset.Apttus_Config2__AssetStatus__c = 'Activated';
            asset.APTS_Old_Net_Price__c = 100;
            asset.Apttus_Config2__LineType__c = 'option';
            asset.Apttus_Config2__ChargeType__c = 'Service Fee';
            asset.APTS_Type_Of_Contract__c = 'Rent';
            asset.Apttus_CMConfig__AgreementId__c = agrlst[0].Id;
            asset.APTS_relatedlist_agreement__c = agrlst[0].Id;
            asset.Apttus_Config2__AccountId__c = acc.Id;
            asset.APTS_Option_Group_Text__c = 'Technical Service';
            asset.APTS_Is_Indexation_Executed__c = false;
            asset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
            asset.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
            asset.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
            assetlst.add(asset);
            //insert asset;   
            
            Apttus_Config2__AssetLineItem__c asset1 = new Apttus_Config2__AssetLineItem__c();
            //asset.Name = 'Test Asset';
            asset1.Apttus_Config2__AssetStatus__c = 'Activated';
            asset1.APTS_Old_Net_Price__c = 100;
            asset1.Apttus_Config2__LineType__c = 'option';
            asset1.Apttus_Config2__ChargeType__c = 'Sales Price';
            asset1.APTS_Type_Of_Contract__c = 'Sales';
            asset1.Apttus_CMConfig__AgreementId__c = agrlst[0].Id;
            asset1.APTS_relatedlist_agreement__c = agrlst[0].Id;
            asset1.Apttus_Config2__AccountId__c = acc.Id;
            asset1.APTS_Option_Group_Text__c = 'Machine Care';
            asset1.APTS_Is_Indexation_Executed__c = false;
            asset1.Apttus_Config2__EndDate__c = Date.today().addDays(100);
            asset1.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
            asset1.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
            assetlst.add(asset1);
            
            Apttus_Config2__AssetLineItem__c asset2 = new Apttus_Config2__AssetLineItem__c();
            asset2.Apttus_Config2__AssetStatus__c = 'Activated';
            asset2.APTS_Old_Net_Price__c = 100;
            asset2.Apttus_Config2__LineType__c = 'option';
            asset2.Apttus_Config2__ChargeType__c = 'Sales Price';
            asset2.APTS_Type_Of_Contract__c = 'Sales';
            asset2.Apttus_CMConfig__AgreementId__c = agrlst[0].Id;
            asset2.APTS_relatedlist_agreement__c = agrlst[0].Id;
            asset2.Apttus_Config2__AccountId__c = acc.Id;
            asset2.APTS_Option_Group_Text__c = 'Value Added Machine Care';
            asset2.APTS_Is_Indexation_Executed__c = false;
            asset2.Apttus_Config2__EndDate__c = Date.today().addDays(100);
            asset2.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
            asset2.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
            assetlst.add(asset2);
            Database.insert(assetlst,false);  
            
            APTS_Index_Contract__c cntrct = new APTS_Index_Contract__c();
            cntrct.APTS_Indexation_Category__c = 'Technical Services';
            cntrct.APTS_Index_Type__c = 'Non-Standard Indexation';
            cntrct.APTS_Frequency__c = 'Yearly';
            cntrct.APTS_Start_Date__c = system.today();
            cntrct.APTS_Contract__c = aggr.Id;
            //cntrct.APTS_Indexation_Number__c = '123';
            //cntrct.APTS_Index_Country__c = 'Netherlands';
            Database.insert(cntrct,false);
            
            test.startTest();
            APTS_IndexationBatch_Phase1 b = new APTS_IndexationBatch_Phase1(system.today());
            Database.executeBatch(b,200);  
            test.stopTest();
            
        }
        catch(Exception ex){
            system.debug('***'+string.valueOf(ex));
        }
    }
}