/**
 * Vanilla Database Insert
 */
Savepoint sp = Database.setSavepoint();
Datetime startTime = Datetime.now();
Integer startCPU = Limits.getCpuTime();
List<Account> accounts = new List<Account>();
for (Integer i = 0; i < 1000; i++) {
    accounts.add(new Account(
        Name = 'Name-' + i
    ));
}
insert accounts;
Datetime endTime = Datetime.now();
Integer endCPU = Limits.getCpuTime();
System.debug(endTime.getTime() - startTime.getTime());
System.debug('CPU: ' + (endCPU - startCPU));
Database.rollback(sp);

/**
 * ApexTextKit Save
 */
sp = Database.setSavepoint();
startTime = Datetime.now();
startCPU = Limits.getCpuTime();
ATK.prepare(Account.SObjectType, 1000)
    .field(Account.Name).index('Name-{0000}')
    .field(Account.Phone).index('+86 186 7777 {0000}')
    .field(Account.Description).repeat('Description...')
    .save();
endTime = Datetime.now();
endCPU = Limits.getCpuTime();
System.debug(endTime.getTime() - startTime.getTime());
System.debug('CPU: ' + (endCPU - startCPU));
Database.rollback(sp);

/**
 * ApexTextKit Mock
 */
sp = Database.setSavepoint();
startTime = Datetime.now();
startCPU = Limits.getCpuTime();
ATK.prepare(Account.SObjectType, 1000)
    .field(Account.Name).index('Name-{0000}')
    .field(Account.CreatedById).repeat(ATKCore.FAKEID.get(User.SObjectType, 1))
    .field(Account.CreatedDate).repeat(Datetime.newInstance(2020, 1, 1))
    .field(Account.LastModifiedById).repeat(ATKCore.FAKEID.get(User.SObjectType, 1))
    .field(Account.LastModifiedDate).repeat(Datetime.newInstance(2020, 1, 1))
    .mock();
endTime = Datetime.now();
endCPU = Limits.getCpuTime();
System.debug(endTime.getTime() - startTime.getTime());
System.debug('CPU: ' + (endCPU - startCPU));
Database.rollback(sp);