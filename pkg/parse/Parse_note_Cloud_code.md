cloud code and performance


### triggers
- beforeSave
- afterSave
- beforeDelete
- afterDelete

	register for class(table) save or delete

- before status
	if failed, it'll stop whole process , not go to save and delete
- after status
	if failed , error will log on cloud error log , but it's not changing save and delete

#:failed is including timeout , syntax error.



### # Cloud code
note :  it should do version control by self 


- limitation
	- 15 secs
	- 3 secs for triggers

##### # installation
on linux and mac
```bash
curl -s https://www.parse.com/downloads/cloud_code/installer.sh | sudo /bin/bash
parse update
```

##### # setup
```bash
parse new
#Type "new" or "existing": existing
new
```

##### # App structure
```
.
├── cloud
│   └── main.js 		// for cloud code
├── config
│   └── global.json
└── public
    └── index.html		// web hosting
```

##### # access by curl
```
curl -X POST \
 -H "X-Parse-Application-Id: ${APP_ID}" \
 -H "X-Parse-REST-API-Key: ${REST_KEY}" \
 -H "Content-Type: application/json" \
 -d '{}' \
 https://api.parse.com/1/functions/hello
```

##### # cloud code sample
process will be canceled after response.success or response.error 
```
Parse.Cloud.define("hello", function(request, response) {
  // do what ever you want ,ex : access parse object
  response.success("Hello world!");

});
```

##### # deploy 
```
	parse deploy 
		-d = --description , note for deployment
		-f = --force , force a deploy even no changes
		development , watch the source directory for any updates and deploy them to Parse. It also provides a live stream of Cloud Code logs.

	parse default app_name	// set default deploy app
```
run once when it\'s deployed
```
	Parse.Cloud.run('hello', {}, {
		success: function(result) {
		// result is 'Hello world!'
		},
	  	error: function(error) {
		}
	});
```


##### # error code
ref. [link](https://parse.com/docs/js/guide#errors)

##### # roll back
`parse rollback`

##### # list release
`parse release [-v v14]`

##### #  SDK version
`parse jssdk -a`


##### # log
- limitation
	- 100 msg per requests
	- each line are limited to 1 KB



### # advanced cloud code

##### # access network
Valid port numbers are 80, 443, and all numbers from 1025 through 65535.
```javascript

Parse.Cloud.httpRequest({
	method: 'POST',
	url: 'http://www.parse.com/',
	// two way for params
	params: {
		q : 'Sean Plott'
	},
	params: 'q=Sean Plott',
	headers: {
		'Content-Type': 'application/json;charset=utf-8'
	},
	body: {
		title: 'Vote for Pedro',
		body: 'If you vote for Pedro, your wildest dreams will come true'
	},
	followRedirects: true	// for http 3xx reponse code
}).then(function(httpResponse) {		// success
	console.log(httpResponse.text);
},function(httpResponse) {				// error
	console.error('Request failed with response code ' + httpResponse.status);
});

```

##### # response object
- status - The HTTP Response status.
- headers - The response headers
- buffer - The raw byte representation of the response body.
- text - The raw response body.
- data - The parsed response, if Cloud Code knows how to parse the content-type that was sent.
- cookies - The cookies sent by the server. They are Parse.Cloud.Cookie objects.


##### # module
ref. [tutorial](https://parse.com/tutorials/integrating-with-third-party-services)





### # webhook
don\'t work with specific classes ( ex: _User  and _Installation )
like triggers , but it\'s on server you build

- limitation
	- 30 secs for time out
	- all post method
	- only https connection , Self-signed certificates will not be accepted
	- send secret key ( on daskboard in key session ) is only known by you in header ( X-Parse.Webhook-Key )

##### # webhook params
json content_body for request , ref. [blog](http://blog.parse.com/announcements/introducing-cloud-code-webhooks/)
params sample  
```
	// Sent to webhook 
	{
	  "master": false, 
	  "user": { 
	    "createdAt": "2015-03-24T20:19:00.542Z", 
	    "objectId": "lValKpphWN", 
	    "sessionToken": "orU3ClA7sqMIN8g4KtmLe7eDM", 
	    "updatedAt": "2015-03-24T20:19:00.542Z", 
	    "username": "Matt" 
	  }, 
	  "installationId": "b3ab24c6-2282-69fa-eeea-c1b36ea497c2", 
	  "params": {}, 
	  "functionName": "helloWorld" 
	}
```


### # background job
- can be scheduled
- state( job ) replace response( cloud code )
- cannot be triggered from the client SDK

```
Parse.Cloud.job("userMigration", function(request, status) {
	// Set up to modify user data
	Parse.Cloud.useMasterKey();
	var counter = 0;
	// Query for all users
	var query = new Parse.Query(Parse.User);
	query.each(function(user) {
		// Update to plan value passed in
		user.set("plan", request.params.plan);
		if (counter % 100 === 0) {
			// Set the  job\'s progress status
			status.message(counter + " users processed.");
	  	}
		counter += 1;
		return user.save();
	}).then(function() {
		// Set the job\'s success status
		status.success("Migration completed successfully.");
	}, function(error) {
		// Set the job\'s error status
		status.error("Uh oh, something went wrong.");
	});
});
```

### # hosting
- in parse app/public
- limitation
	- limited to 500MB
	- no more 500 files
	- only these for name ,  alphanumeric characters, dashes, underscores, spaces, and \'@\' signs.
	- skip emacs and vim autosave files.
	- any type you want
- [custom domain names](https://parse.com/docs/js/guide#hosting-custom-domain-names)



### # performance

##### # smart indexing
- The first generates simple (single field)  indexes foreach API request
- The second does offline processing to pick good compound indexes based on real API traffic patterns

??? to test how many fields will be indexed

##### # The simple indexing strategy looks at every API request and attempts to pick good indexes based on the following:
- The query constraint\'s likelihood of providing the smallest search space.
- The number of possible values a field may have based on its data type. We consider data types with a **larger number of possible values** to have a **higher entropy**.

##### # The order of a query constraint\'s usefulness is:
- Equal to
- Contained In
- Less than, Less than or Equal to, Greater than, Greater than or Equal to
- Prefix string matches
- Not equal to
- Not contained \in
- Everything \else

score each query \for three top-scoring fields \for each query


##### #no good for index
- Not Equal To
- Not Contained In

##### #slow query
- Regular Expressions
- Ordered By
- partial string matching

##### # example 
bad
```
var query = new Parse.Query(Parse.User);
query.notEqualTo("state", "Invited");
```
better
```
query.containedIn("state", ["SignedUp", "Verified"]);
```


##### # count and average 
use cloud function to do this