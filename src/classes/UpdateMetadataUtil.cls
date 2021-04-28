public class UpdateMetadataUtil implements MetaData.DeployCallback {
    
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context){
        if (result.status == Metadata.DeployStatus.Succeeded){
            System.debug('Success: ' + result);
        }else {
            System.debug('Failed: ' + result);
        }
    }
    
    public static void updateMetadata (List<Call_List_Day_Counter__mdt> custommetadatalist){
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        String thislabel;
        for (Call_List_Day_Counter__mdt clds : custommetadatalist){
            Metadata.CustomMetadata customMetadata = new Metadata.customMetadata();
            thislabel = clds.label;
            customMetadata.fullname = 'Call_List_Day_Counter' + '.' + thislabel;
            customMetadata.label = thislabel;
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = 'Counter__c';
            customField.Value = clds.Counter__c;
            customMetadata.values.add(customField);
            mdContainer.addMetadata(customMetadata);
        }
        
        UpdateMetadataUtil callback = new UpdateMetadataUtil();
        ID jobId = Test.isRunningTest() ? '7071x0000000000' : Metadata.Operations.enqueueDeployment(mdContainer, callback);
    }
    
}