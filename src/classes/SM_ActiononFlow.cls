//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   July 29 2020
// Usage        :   Workaround for Get Records on flow so it doesn't meet SOQL 101 error
//
//-------------------------------------------------------------------------------------------//
global without sharing class SM_ActiononFlow {
    @InvocableMethod
    public static List<List<Task>> getSelectedTask(List<List<String>> input) {
        List<String> valrec = new List<String>();
        for (List<String> llrec: input){
            for (String lrec : llrec){
                valrec.add(lrec);
            }
        }

        List<Task> taskrecords = [Select Id, Status, Reason__c from Task where Id IN :valrec];
        List<List<Task>> listfinal = new List<List<Task>>();
        listfinal.add(taskrecords);

        return listfinal;
    }
}