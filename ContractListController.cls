public without sharing class ContractListController {
    @AuraEnabled(cacheable=false)
    public static Decimal getDistance(String SS_name, String CityName, String prefectures) {
        List<DistanceMST__c> distanceMst = [select distance__c from DistanceMST__c where SS_name__c = :SS_name and CityName__c=:CityName and prefectures__c = :prefectures LIMIT 1];
        
        if (distanceMst.size() > 0) {
            return distanceMst[0].distance__c;
        }
        return null;
    }
    @AuraEnabled(cacheable=false)
    public static List<Contract__c> getContracts(String condition) {
        Date today = Date.today();
        String query = 'SELECT Id,Name, Product_kana__c,delivery_destination__r.name,Simple_number__c, registration_date__c,'+
            'RecordType.Name,breed__c,construction_name__c,packing_style__c,Product_kana_cal__c,status__c, '+
            'Contract_number_cal__c, Contract_number__c, delivery_destination__c,shipment_base__c,delivery_criteria__c, '+
            'delivery_date_start_date__c, delivery_date_end_date__c, transport_company_ref__c, transport_company_ref__r.name, '+
            'breed__r.cal_Name_Text__c FROM Contract__c '
             + condition + ' ORDER BY registration_date__c desc limit 2001';
        List<Contract__c>  results = Database.query(query);
        // 获取字段的描述信息
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Contract__c.fields.getMap();
        Schema.DescribeFieldResult packingStyleResult = fieldMap.get('packing_style__c').getDescribe();
        List<Schema.PicklistEntry> packingStylelistValues = packingStyleResult.getPicklistValues();
        Schema.DescribeFieldResult deliveryCriteriaResult = fieldMap.get('delivery_criteria__c').getDescribe();
        List<Schema.PicklistEntry> deliveryCriterialistValues = deliveryCriteriaResult.getPicklistValues();

        // 获取所有的picklist选项
        for (Contract__c contract : results) {
            for (Schema.PicklistEntry entry : packingStylelistValues) {                
                if (entry.getValue() == contract.packing_style__c) {
                    contract.packing_style__c = entry.getLabel();
                    break;
                }
            }
            for (Schema.PicklistEntry entry : deliveryCriterialistValues) {                
                if (entry.getValue() == contract.delivery_criteria__c) {
                    contract.delivery_criteria__c = entry.getLabel();
                    break;
                }
            }
        }
        return results;
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getShipRequestContracts(String condition) {
        Date today = Date.today();
        String query = 'SELECT Id,Name, Product_kana__c,delivery_destination__r.name,simple_number__c, registration_date__c,'+
            'RecordType.Name,breed__c,construction_name__c,packing_style__c,Product_kana_cal__c,status__c, '+
            'Contract_number_cal__c, Contract_number__c, delivery_destination__c,shipment_base__c,ShippingBase_rel__r.Name,delivery_criteria__c, '+
            'delivery_date_start_date__c, delivery_date_end_date__c, transport_company_ref__c, transport_company_ref__r.name '+
            'FROM Contract__c '
                + condition + ' ORDER BY registration_date__c desc';
        List<Contract__c> Contacts = Database.query(query);
        List<String> idList = new List<String>();
        for (Contract__c c : Contacts) {
            idList.add(c.id);
        }
        List<Map<String, Object>> returnResult = new List<Map<String, Object>>();
        // Query total shipment quantities for each contract
        Map<Id, Decimal> shipmentQuantitiesLast = new Map<Id, Decimal>();
        Map<Id, Decimal> shipmentQuantities = new Map<Id, Decimal>();
        AggregateResult[] lastResults = [
            SELECT Contract__c, SUM(Quantity__c) TotalQuantity
            FROM Shipping_Result__c
            WHERE Ship_date__c = LAST_MONTH
            AND Contract__c IN :idList
            GROUP BY Contract__c
        ];
        AggregateResult[] results = [
            SELECT Contract__c, SUM(Quantity__c) TotalQuantity
            FROM Shipping_Result__c
            WHERE Ship_date__c = THIS_MONTH
            AND Contract__c IN :idList
            GROUP BY Contract__c
        ];
        // Map shipment quantities to their respective contracts
        for (AggregateResult result : results) {
            shipmentQuantities.put((Id)result.get('Contract__c'), (Decimal)result.get('TotalQuantity'));
        }
        // Map shipment quantities to their respective contracts
        for (AggregateResult result : lastResults) {
            shipmentQuantitiesLast.put((Id)result.get('Contract__c'), (Decimal)result.get('TotalQuantity'));
        }

            // 获取字段的描述信息
            Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Contract__c.fields.getMap();
            Schema.DescribeFieldResult packingStyleResult = fieldMap.get('packing_style__c').getDescribe();
            List<Schema.PicklistEntry> packingStylelistValues = packingStyleResult.getPicklistValues();
            Schema.DescribeFieldResult deliveryCriteriaResult = fieldMap.get('delivery_criteria__c').getDescribe();
            List<Schema.PicklistEntry> deliveryCriterialistValues = deliveryCriteriaResult.getPicklistValues();
        
        for (Contract__c contract : Contacts) {
            for (Schema.PicklistEntry entry : packingStylelistValues) {                
                if (entry.getValue() == contract.packing_style__c) {
                    contract.packing_style__c = entry.getLabel();
                    break;
                }
            }
            for (Schema.PicklistEntry entry : deliveryCriterialistValues) {                
                if (entry.getValue() == contract.delivery_criteria__c) {
                    contract.delivery_criteria__c = entry.getLabel();
                    break;
                }
            }
            Map<String, Object> fields = new Map<String, Object>();           
            fields.put('Id', contract.Id);
            fields.put('Name', contract.Name);
            fields.put('Contract_number__c', contract.Contract_number__c);
            fields.put('RecordType', contract.RecordType);
            fields.put('simple_number__c', contract.simple_number__c);
            fields.put('delivery_destination__r', contract.delivery_destination__r);
            fields.put('shipment_base__c', contract.ShippingBase_rel__r!=null?contract.ShippingBase_rel__r.Name:'');
            fields.put('construction_name__c', contract.construction_name__c);
            fields.put('Product_kana__c', contract.Product_kana__c);
            fields.put('transport_company_ref__r', contract.transport_company_ref__r);
            fields.put('packing_style__c', contract.packing_style__c);
            fields.put('delivery_criteria__c', contract.delivery_criteria__c);
            fields.put('registration_date__c', contract.registration_date__c);
            fields.put('TotalQuantity', shipmentQuantities.get(contract.Id));
            fields.put('LastTotalQuantity', shipmentQuantitiesLast.get(contract.Id));
            returnResult.add(fields);
        }        
        return returnResult;
    }

    
    @AuraEnabled(cacheable=true)
    public static List<RecordType> getContractRecordTypes() {
        return [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Contract__c'];
    }

    // (品目マスタ)
    @AuraEnabled(cacheable=true)
    public static List<Product2> getProducts() {
        return [SELECT Id, Name, cal_Name_Text__c FROM Product2];
    }
}