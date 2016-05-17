# Parse_ analytics

> log all queries for analytic
>  
>




##### # audience
[daily , weekly , monthly]
- installations
- users

##### # event
- api requests
- analytics requeyr
- file requests
- push notification
- app opens
- push opens

##### # data
- row statistic of each class

##### # retention
- % user remained in 28 days after signup

##### # performance
- served request
- request limit 
- dropped requests
- total requests
- storage data and transfering

##### # slow queries
**immediatly show query log**

Definition:
- Count 
    The percentage of queries that took longer than 1 second. Row will be colored in red if Slow% is higher than 25% Slow% 
- Timeouts  
- Median (ms) 
    90% of queries returned before this time
- P90 (ms) 

### #crashes for iOS , android

1. import `ParseCrashReporting-*.jar`

2. enable crash log
	`ParseCrashReporting.enable(this);`
3. crash testing
	`throw new RuntimeException("Test Exception!");`
4. show on crash dashboard
	it'll merge same Exception, and count installations , ocuurrences , and it's immediate.





##### #explorer
this is log of operation
- Request
- Type
- Class
- Installation ID
- Parse User ID
- Parse SDK
- Parse SDK Version
- OS
- OS Version
- App Build Version
- App Display Version
- **Timestamp (s)**
- **Latency (s)**
