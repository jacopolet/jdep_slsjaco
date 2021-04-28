@isTest
private class APTS_DummyApttusBatchTest {
	
	@isTest static void test_method_one() {

		Product2 instPord = new Product2(Name='Test');
		insert instPord;

			Apttus_Config2__ClassificationName__c instHier1 = new 	Apttus_Config2__ClassificationName__c(Apttus_Config2__Type__c='Offering',Apttus_Config2__HierarchyLabel__c='Coffee',Name='Coffee');
			Apttus_Config2__ClassificationName__c instHier2 = new 	Apttus_Config2__ClassificationName__c(Apttus_Config2__Type__c='Offering',Apttus_Config2__HierarchyLabel__c='Tea',Name='Tea');
insert instHier1;insert instHier2; 
		Apttus_Config2__ClassificationHierarchy__c instCategory1 = new Apttus_Config2__ClassificationHierarchy__c(name='Tea',Apttus_Config2__Label__c='Tea',Apttus_Config2__HierarchyId__c=instHier2.id);
		Apttus_Config2__ClassificationHierarchy__c instCategory2 = new Apttus_Config2__ClassificationHierarchy__c(name='Coffee',Apttus_Config2__HierarchyId__c=instHier1.id, Apttus_Config2__Label__c='Coffee');
		insert instCategory1;insert instCategory2;

		Apttus_Config2__ProductClassification__c instProdClass = new Apttus_Config2__ProductClassification__c(Apttus_Config2__ProductId__c=instPord.id,Apttus_Config2__ClassificationId__c=instCategory1.id);
		insert instProdClass;
		Apttus_Config2__ProductHierarchyView__c instView1 = new Apttus_Config2__ProductHierarchyView__c(Apttus_Config2__ChildProductId__c=instPord.id,Apttus_Config2__ChildLevel__c=2, Apttus_Config2__ParentLevel__c=1,Apttus_Config2__ParentClassificationId__c=instCategory1.id,Apttus_Config2__HierarchyId__c=instHier1.id);
		Apttus_Config2__ProductHierarchyView__c instView2 = new Apttus_Config2__ProductHierarchyView__c(Apttus_Config2__ChildProductId__c=instPord.id,Apttus_Config2__ChildLevel__c=2, Apttus_Config2__ParentLevel__c=1,Apttus_Config2__ParentClassificationId__c=instCategory2.id,Apttus_Config2__HierarchyId__c=instHier2.id);
		insert instView1;insert instView2;
		APTS_DummyApttusBatch instBatch = new APTS_DummyApttusBatch();
		Database.executeBatch(instBatch);
	}
	
}