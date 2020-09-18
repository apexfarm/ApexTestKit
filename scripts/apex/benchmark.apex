Savepoint sp = Database.setSavepoint();
Datetime startTime = Datetime.now();
List<Account> accounts = new List<Account>();
for (Integer i = 0; i < 1000; i++) {
    accounts.add(new Account(
        Name = 'Name-' + i
    ));
}
insert accounts;
Datetime endTime = Datetime.now();
System.debug(endTime.getTime() - startTime.getTime());
Database.rollback(sp);


Savepoint sp = Database.setSavepoint();
Datetime startTime = Datetime.now();
ATK.prepare(Account.SObjectType, 1000)
    .field(Account.Name).index('Name-{0000}')
    .field(Account.Phone).index('+86 186 7777 {0000}')
    .field(Account.Description).repeat('Description...')
    .save();
Datetime endTime = Datetime.now();
System.debug(endTime.getTime() - startTime.getTime());
Database.rollback(sp);


Savepoint sp = Database.setSavepoint();
Datetime startTime = Datetime.now();
ATK.prepare(Account.SObjectType, 1000)
    .field(Account.Name).index('Name-{0000}')
    .field(Account.CreatedById).repeat(ATKCore.FAKEID.get(User.SObjectType, 1))
    .field(Account.CreatedDate).repeat(Datetime.newInstance(2020, 1, 1))
    .field(Account.LastModifiedById).repeat(ATKCore.FAKEID.get(User.SObjectType, 1))
    .field(Account.LastModifiedDate).repeat(Datetime.newInstance(2020, 1, 1))
    .mock();
Datetime endTime = Datetime.now();
System.debug(endTime.getTime() - startTime.getTime());
Database.rollback(sp);