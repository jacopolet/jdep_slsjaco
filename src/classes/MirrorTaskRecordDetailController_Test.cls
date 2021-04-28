@isTest
public class MirrorTaskRecordDetailController_Test {
    static testMethod void test() {
         Id inboundRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        //Create new expense and insert it into the database        
         Task t = new Task(RecordTypeId= inboundRecordTypeId,
                             Status='Open', Priority='High');
         MirrorTaskRecordDetailController.saveTask(t);
         MirrorTaskRecordDetailController.getTask(t.id);
         
         insert t;
         
         Task getTask = [Select Status FROM Task WHERE Id = : t.id];

        //Assert the name field and saved expense
        System.assertEquals('Open', getTask.Status);
    }
}