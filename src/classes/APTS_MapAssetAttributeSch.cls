global class APTS_MapAssetAttributeSch implements Schedulable {
    global void execute(SchedulableContext sc) {
        APTS_MapAssetAttributeBatch obj = new APTS_MapAssetAttributeBatch();
        Database.executeBatch(obj);
    }
}