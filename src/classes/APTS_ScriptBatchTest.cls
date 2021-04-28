@istest
public class APTS_ScriptBatchTest { 
    
    @testSetup
    private static void testDataSetup() { 
        TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.APTS_Order_Trigger__c = false;
        objTriggerSettings.APTS_OrderLineItemTrigger__c = false;
        insert objTriggerSettings; 
    }
    public static testmethod void DeleteOrderBatchTest(){
        Apttus_Config2__Order__c orderobj = new Apttus_Config2__Order__c(); 
        insert orderobj;  
        //Set metadata   
        APTS_BatchMetadataCoverageTest.setMetadata(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_Control__c,'+
            'APTS_Triggers__c '+
            'FROM APTS_Batch_Queries__mdt '+ 
            'WHERE DeveloperName = \'Order_Deletion\'',
            (List<APTS_Batch_Queries__mdt>) JSON.deserialize('[{"APTS_Query_String__c":"Select Id FROM Apttus_Config2__Order__c",'+ '"APTS_Triggers__c":"Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c,APTS_Order_Trigger__c,APTS_OrderLineItemTrigger__c",'+
                                                             '"APTS_Control__c":"true"}]', 
                                                             List<APTS_Batch_Queries__mdt>.class
                                                            )
        );
        
        test.startTest();
        /*APTS_DeleteOrderSch scheduler = new APTS_DeleteOrderSch();      
        String sch = '0 28 * * * ?';
        system.schedule('Test APTS_DeleteOrderSch', sch, scheduler);*/
        test.stopTest();
        
    } 
    
    public static testmethod void MapAssetAttributeBatchTest(){
        Apttus_Config2__Order__c orderobj = new Apttus_Config2__Order__c(); 
        insert orderobj;
        Apttus_Config2__AssetLineItem__c astlineitm = new Apttus_Config2__AssetLineItem__c();
        astlineitm.Name ='Test';
        insert astlineitm;
        
        Apttus_Config2__AssetAttributeValue__c Attribute = new Apttus_Config2__AssetAttributeValue__c(); 
        Attribute.Apttus_Config2__AssetLineItemId__c = astlineitm.id;
        insert Attribute;
        Apttus_Config2__OrderLineItem__c orderltobj = new Apttus_Config2__OrderLineItem__c(); 
        orderltobj.Apttus_Config2__OrderId__c = orderobj.id;
        orderltobj.Apttus_Config2__AssetLineItemId__c = astlineitm.id;
        orderltobj.APTS_Migrated_Asset_Line_Item__c = astlineitm.id;
        insert orderltobj;  
        
        Apttus_Config2_AssetAdjustItem__c aca = new Apttus_Config2_AssetAdjustItem__c();
        aca.Apttus_Config2_AssetLineItemId__c = orderltobj.APTS_Migrated_Asset_Line_Item__c;
        insert aca;
        
        APTS_CounterReadingData__c acr = new APTS_CounterReadingData__c();
        acr.APTS_Asset_Line_Item__c = orderltobj.APTS_Migrated_Asset_Line_Item__c;
        insert acr;
        //Set metadata   
        APTS_BatchMetadataCoverageTest.setMetadata(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_Control__c,'+
            'APTS_Triggers__c '+
            'FROM APTS_Batch_Queries__mdt '+ 
            'WHERE DeveloperName = \'Order_Line_Items\'',
            (List<APTS_Batch_Queries__mdt>) JSON.deserialize('[{"APTS_Query_String__c":"SELECT Id, APTS_Migrated_Asset_Line_Item__r.Apttus_Config2__ParentAssetId__c,APTS_Migrated_Asset_Line_Item__c,APTS_Migrated_Asset_Line_Item__r.Apttus_Config2__BundleAssetId__c,Apttus_Config2__AssetLineItemId__c FROM Apttus_Config2__OrderLineItem__c",'+ '"APTS_Triggers__c":"Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c,APTS_Order_Trigger__c,APTS_OrderLineItemTrigger__c",'+
                                                             '"APTS_Control__c":"true"}]', 
                                                             List<APTS_Batch_Queries__mdt>.class
                                                            )
        );
        
        test.startTest();
        APTS_MapAssetAttributeSch scheduler = new APTS_MapAssetAttributeSch();      
        String sch = '0 28 * * * ?';
        system.schedule('Test APTS_MapAssetAttributeSch', sch, scheduler); 
        test.stopTest(); 
    } 
    
    public static testmethod void InActivateAssetLineItemsBatchTest(){
        Apttus_Config2__Order__c orderobj = new Apttus_Config2__Order__c(); 
        insert orderobj;
        Apttus_Config2__AssetLineItem__c astlineitm = new Apttus_Config2__AssetLineItem__c();
        astlineitm.Name ='Test';
        insert astlineitm;
         
        Apttus_Config2__OrderLineItem__c orderltobj = new Apttus_Config2__OrderLineItem__c(); 
        orderltobj.Apttus_Config2__OrderId__c = orderobj.id; 
        orderltobj.APTS_Migrated_Asset_Line_Item__c = astlineitm.id;
        insert orderltobj;  
        
        
        
        //Set metadata   
        APTS_BatchMetadataCoverageTest.setMetadata(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_Control__c,'+
            'APTS_Triggers__c '+
            'FROM APTS_Batch_Queries__mdt '+ 
            'WHERE DeveloperName = \'Order_Line_Items\'',
            (List<APTS_Batch_Queries__mdt>) JSON.deserialize('[{"APTS_Query_String__c":"SELECT Id, APTS_Migrated_Asset_Line_Item__c,Apttus_Config2__AssetLineItemId__c FROM Apttus_Config2__OrderLineItem__c",'+ '"APTS_Triggers__c":"Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c,APTS_Order_Trigger__c,APTS_OrderLineItemTrigger__c",'+
                                                             '"APTS_Control__c":"true"}]', 
                                                             List<APTS_Batch_Queries__mdt>.class
                                                            )
        );
        
        test.startTest();
        APTS_InActivateAssetLineItemsSch scheduler = new APTS_InActivateAssetLineItemsSch();      
        String sch = '0 28 * * * ?';
        system.schedule('Test APTS_InActivateAssetLineItemsSch', sch, scheduler); 
        test.stopTest(); 
    }
}