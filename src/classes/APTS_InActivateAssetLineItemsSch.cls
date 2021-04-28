global class APTS_InActivateAssetLineItemsSch implements Schedulable {
    global void execute(SchedulableContext sc) {
        APTS_InActivateAssetLineItemsBatch obj = new APTS_InActivateAssetLineItemsBatch();
        Database.executeBatch(obj);
    }
}