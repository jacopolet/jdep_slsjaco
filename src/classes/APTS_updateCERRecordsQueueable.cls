/*******************************************************************************************
  Name            : APTS_updateCERRecordsQueueable
  Created By      : Sai Sagar
  Created Date    : 09/12/2018
  Description     :This Apex Class is Update CER for Child Accounts
  Version history : 
  Test Class      : APTS_updateCERRescordsQueueableTest
 
  v100 - Aftab
 *********************************************************************************************/
public class APTS_updateCERRecordsQueueable implements Queueable {

	List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c> ();
	List<APTS_CER_Transaction__c> cerTransList = new List<APTS_CER_Transaction__c> ();
	List<APTS_CER_Transaction__c> deleteCerTransList = new List<APTS_CER_Transaction__c> ();

	string batchSize = System.label.CERQueueableBatchSize;
	public APTS_updateCERRecordsQueueable() {
		if ((batchSize != null && !batchSize.isNumeric()) ||(batchSize == null)||Test.isRunningTest()) {
			batchSize = '50';
		}
		//this.agreementList = database.query('SELECT Id, RecordTypeId, Apttus__Account__c,APTS_CER_Batch_Executed__c FROM Apttus__APTS_Agreement__c WHERE APTS_CER_Batch_Executed__c=true limit '+batchSize);
		this.cerTransList = database.query('SELECT Id, APTS_Agreement_Id__c FROM APTS_CER_Transaction__c  order by Hierarchy_Level__c asc limit ' + batchSize);
	}
	public void execute(QueueableContext context) {
		try {

			Set<String> agreementIdSet = new Set<String> ();
			if (cerTransList.size() > 0) {
				Integer lstSize = cerTransList.size();
				//List<APTS_CER_Transaction__c> cerTrans = cerTransList;
				for (APTS_CER_Transaction__c trnsrecord : cerTransList) {
					agreementIdSet.add(trnsrecord.APTS_Agreement_Id__c);
				}

				agreementList = [SELECT Id, RecordTypeId, Apttus__Account__c, APTS_CER_Batch_Executed__c FROM Apttus__APTS_Agreement__c WHERE Id IN :agreementIdSet];

				if (agreementIdSet.size() > 0)
				{
					APTS_ManageCER.manageCERRecords(agreementList, APTS_ManageCER.BATCH, APTS_ManageCER.DMLUPDATE);
					deleteCerTransList=[SELECT Id, APTS_Agreement_Id__c FROM APTS_CER_Transaction__c where id in :cerTransList];
					if(deleteCerTransList.size()>0)
					delete deleteCerTransList;
					if (lstSize == Integer.valueOf(batchSize))
					{
						System.enqueueJob(new APTS_updateCERRecordsQueueable());
					}

				}

			}

		} catch(Exception ex) {
			String strSobjects = '';
			for (Apttus__APTS_Agreement__c agr :agreementList)
					strSobjects = strSobjects + '; ' + agr.Id;
			APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex','Message =' + ex.getMessage()+' Caused by ='+ex.getStackTraceString(), 'CER', strSobjects, 'CPQ', false, false, null, true);
		}
	}

	/*public void execute(QueueableContext context) {
	  try{
	  system.debug('batchSize  batch==>' + batchSize );
	  system.debug('agreementList batch==>' + agreementList);
	  if(agreementList.size() > 0)
	  {
	  APTS_ManageCER.manageCERRecords(agreementList,APTS_ManageCER.BATCH,APTS_ManageCER.DMLUPDATE); 
	  List<Apttus__APTS_Agreement__c> updateList = new List<Apttus__APTS_Agreement__c>();
	  for(Apttus__APTS_Agreement__c agr:agreementList)
	  {
	  agr.APTS_CER_Batch_Executed__c=false;
	  updateList.add(agr);
	  }
	  update updateList;
	  if(agreementList.size() == Integer.valueOf(batchSize))
	  {
	  System.enqueueJob(new APTS_updateCERRecordsQueueable());
	  }
	  }
	 
	  }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Batch', ex.getStackTraceString(), 'CER', null, 'CPQ', false, false, null, true);}   
	  //}     
	  }*/
}