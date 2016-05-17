### pricing and limitation

##### # basic file system
- Storage 20GB ( $0.03/GB extra )
- DB Storage 20GB ( $200/GB extra )
- File transfer ( $0.10/GB extra )

| Plan      | Cost    | Reqs/s     | bg job     |
| -------   | ------: | ---------: | ---------: |
|           |   Free  |     30     |      1     |
|           |    100  |     40     |      1     |
|           |         |            |            |
|           |    ...  |       ...  |     ...    |
|           |         |            |            |
|           |   5700  |    600     |      29    |

**公式**： 多 10reqs 多 $100 , 可以執行 Cost+100/200個job


##### # Push
- A/B Testing ( Unlimited )
- Custom Segmentation ( Unlimited )
- Scheduling ( Unlimited )

| Plan   | Cost   | notify  |
| -------| ------:| ------: |
|        | Free   |    1000 |
|        |  ...   |    ...  |
|        |  950   |   20000 |

**公式**:  $0.05 for 1000 nofities 

##### # Analytics
- Custom Events ( Unlimited )
- Instant Breakdowns ( Unlimited )
- Advanced Reports ( Unlimited )


### Limits and Other Considerations
ref. [link](https://parse.com/docs/js/guide#performance-limits-and-other-considerations)

##### # Apps
- only create up to 100 Parse Config keys , Use Parse Objects if you need more
- only create up to 200 classes
- Only the first 100 classes will be displayed in the Data Browser

##### # Objects
- limited in size to 128 KB.  no more 64 fields for better index
- field nameno longer than 1,024 characters

##### # Files
- up to 10 MB for each,  no limit on how many Parse Files.
- ??? Parse Hosting, on the other hand, supports files up to 500 MB, ideal for Unity projects.
- can't be accessed via HTTPS.

##### # Queries
- cloud functions will be killed after **15 secs**, and four triggers will be killed in **3 secs**
- return 100 objects by default. up to 1,000.
- le result set. This includes any resolved pointers. You can use skip and limit to page through results.

- maximum skip is 10,000.  If you need to get more objects, we recommend sorting the results and then 
using a constraint on the sort column to filter out the first 10,000 results. 
You will then be able to continue paging through results starting from a skip value of 0. 
For example, you can sort your results by createdAt ASC and then filter out any objects older than 
the createdAt value of the 10,000th object when starting again from 0.

- Alternatively, you may use the each() method in the JavaScript SDK to page through all objects that match the query.
- Skips and limits can only be used on the outer query.
- You may increase the limit of a inner query to 1,000, but skip cannot be used to get more results past the first 1,000.
- Constraints that collide with each other will result in only one of the constraint being applied. An example of this would be two equalTo constraints over the same key with two different values, which contradicts itself (perhaps you're looking for 'contains').
- Regular expression queries are deprecated and an app can make no more than 80 regex queries / minute.
- Count operations are limited to 160 count queries / minute period for each application. The limit applies to all requests made by all clients of the application. If you need to query counts more frequently, you may want to design your system so the results can be cached in your client application.
- No geo-queries inside compound OR queries.
  Using $exists: false is not advised.
- The each query method in the JavaScript SDK cannot be used in conjunction with queries using geo-point constraints.
- A maximum of 500,000 objects will be scanned per query. If your constraints do not successfully limit the scope of the search, this can result in queries with incomplete results.
- A containsAll query constraint can only take up to 9 items in the comparison array.


##### # uploading constraints
- limited to 500 MB
- can't upload 500 hosted files
- file name should be start wiht [a-zA-Z] and only in [a-zA-Z0-9_- @] , 
- skip vim and emacs autosave files 

##### # Push Notifications
- upload up to 6 APNs certificates per app.
- Delivery of notifications is a “best effort”, not guaranteed. It is not intended to deliver data to your app, only to notify the user that there is new data available.

##### # Cload neworking
- 8 concurrent httprequests per cloud code reuqest

##### # Cloud Code
- limited to **128 KB**.
- must return within **15 seconds**. Use webhooks if you need more time.
- **save/delete hooks** must return within **3 secs**. Use webhooks if you need more time.
- **Webhooks** must return within **30 seconds**.
- Background jobs will be terminated after **15 minutes**.
- Apps can run one job concurrently by default, but this can be increased by increasing your requests/second in your Account Overview page.
- Additional background jobs over quota will fail to run. They will not be queued.
- The params payload that is passed to a Cloud Function is limited to 50 MB.
- When using console to log information and errors, the message string will be limited to 1 KB.
- Only the first 100 messages logged by a Cloud function will be persisted in the Cloud Code logs.


[other, tested by  unofficial](http://profi.co/all-the-limits-of-parse/)
- 160 API requests per minute for ENTIRE app (not one instance!) (changed to 30+ req/s but it costs quite a lot
- limited number of COUNT operations (differs every time, but surely under 160)
- if you are counting objects with the count higher that just a 1000, the system switches to “approximate count”
- any function can not take longer than 3 seconds
- if that function is in a cloud that time can last 7 seconds
- scheduled jobs can last a maximum of 15 minutes, but you have to put ALL of your code in one function (which basically makes it unreadable for later usages)
- maximum of 2 concurrent jobs (threads)
- no mutex/lock/semaphore logic
- no custom atomic operations (just a few are available, and they are not that useful)
- this makes it very very hard to solve concurrency problems
- log system remembers only 100 last logs
- live logging in the system has a tendency to simply skip a log or two (which makes debugging really funny)
- you can pull a maximum of 1000 objects in a request, which also applies on inner queries
- push notifications have delay (even up to one hour)
- LIMIT SKIP operation can skip a maximum of 10 000 objects
- no DISTINCT operation, you have to implement distinct yourself by parsing data
- lack of incase sensitive string queries, you need to store additional lowercase column in your database
- uptime of parse system is also an issues. Quite a few times, parse was unavailable in general for 30minutes
- no native Paypal integration support, or ability to implement paypals SDK – we had to use separate node.js hosting server to support payments and cash distribution through Paypay
- no debugger when writing cloudcode – you have to rely on logs only, and they have their own issues mentioned above
- no option to delete an entire class from parse via API. image if you wanted to drop logs ?


### # Config
up to 100 parameters in your config and a total size of 128KB across all parameters.