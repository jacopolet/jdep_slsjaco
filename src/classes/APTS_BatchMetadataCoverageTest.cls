@isTest
public class APTS_BatchMetadataCoverageTest {
	static testMethod void testMetadataCoverageMethod(){
		List<SObject> metadataCoverageRecords;

		Test.startTest();
			metadataCoverageRecords = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
				'SELECT MasterLabel FROM APTS_Batch_Queries__mdt'
				);
		Test.stopTest();
	}

	public static void setMetadata(String query, List<SObject> records){
		APTS_BatchMetadataCoverage.MetadataCoverageRecordsMap.put(query, records);
	}
}