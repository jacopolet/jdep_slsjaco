/*************************************************************
@Name: APTS_AssetMovementTxCEDSchedulable
@Author: Mahesh Chilaka
@CreateDate: 28-08-2020
@Description: Schedule Queueable class for updating Contract Effective Date on Transaction records for A005 and B005. DQ - 3607.
              This class will run on Daily at 11 PM.
@UsedBy: 
******************************************************************/
/*
@Version History : v1.0 - created
*/
public with sharing class APTS_AssetMovementTxCEDSchedulable implements Schedulable {
    public void execute(SchedulableContext sc){
        System.enqueueJob(new APTS_AssetMovementTxCEDUpdateQueueable());
    }
}