Savepoint sp = Database.setSavepoint();

CampaignBuilder campaignBuilder = new CampaignBuilder();
ATK.SaveResult result = ATK.prepare(Campaign.SObjectType, 4)
    .build(campaignBuilder)
    .withChildren(Campaign.SObjectType, Campaign.ParentId, 4)
        .build(campaignBuilder)
        .withChildren(Campaign.SObjectType, Campaign.ParentId, 4)
            .build(campaignBuilder)
            .withChildren(Campaign.SObjectType, Campaign.ParentId, 4)
                .build(campaignBuilder)
                .withChildren(Campaign.SObjectType, Campaign.ParentId, 4)
                    .build(campaignBuilder)
    .save(true);

convertLeads(result);

Database.rollback(sp);

class CampaignBuilder implements ATK.EntityBuilder {
    public void build(ATK.Entity campaignEntity, Integer size) {
        campaignEntity
            .field(Campaign.Type).repeat('Partners')
            .field(Campaign.Name).index('Name-{0000}')
            .field(Campaign.StartDate).repeat(Date.newInstance(2020, 1, 1))
            .field(Campaign.EndDate).repeat(Date.newInstance(2020, 1, 1).addMonths(1))
            .withChildren(CampaignMember.SObjectType, CampaignMember.CampaignId, size * 2)
                .withParents(Lead.SObjectType, CampaignMember.LeadId, size * 2)
                    .field(Lead.Company).index('Name-{0000}')
                    .field(Lead.LastName).index('Name-{0000}')
                    .field(Lead.Email).index('test.user+{0000}@email.com')
                    .field(Lead.MobilePhone).index('+86 186 7777 {0000}')
            .also(2); // Reset the current working SObjectType back to Campaign
    }
}

public void convertLeads(ATK.SaveResult result) {
    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];

    for (Integer i = 4; i > -1; i--) {
        List<SObject> leads =  result.get(Lead.SObjectType, i);
        for (SObject obj : leads) {
            Lead lead = (Lead)obj;
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            lc.setDoNotCreateOpportunity(true);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            System.assert(lcr.isSuccess());
        }

        Map<Id, SObject> campaigns =  new Map<Id, SObject>(result.get(Campaign.SObjectType, i));
        for (Campaign camp : [
            SELECT
                NumberOfContacts,
                HierarchyNumberOfContacts
            FROM Campaign
            WHERE Id IN :campaigns.keySet()]) {
            System.assertEquals(2, camp.NumberOfContacts);
            System.assertEquals(2 * (5 - i), camp.HierarchyNumberOfContacts);
        }
    }
}