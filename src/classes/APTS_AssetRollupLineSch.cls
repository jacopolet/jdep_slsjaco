global class APTS_AssetRollupLineSch implements Schedulable {
  global void execute(SchedulableContext sc) {
    APTS_AssetRollupLineCreation obj = new APTS_AssetRollupLineCreation();
    Database.executeBatch(obj,1);
  }
}