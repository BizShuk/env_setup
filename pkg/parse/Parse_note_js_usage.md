### # note
- [Parse limitaion](http://profi.co/all-the-limits-of-parse/)
- File deleted by [REST API](https://www.parse.com/docs/rest#files-deleting-files)
- authrithon
	for third-party authrithon
- email Verified rule
- add collaborator
- export data

### # class = table
- four default class
	- _User
	- _Installation  
		same device is with different token and Id , when rest cach and data
		"deviceToken":APA91b HXYl-i6_euG1k4zWTCMdVfV003pgJRJmVNwGxSMb1P61Z1z9d_5BjUBxNgFW1j1ZENaOiyIxrEkvoGDw90UKVBxNvza4eftmpyMaT1brbWUO4eqN4Od_nEE7156YcX2Oei6B1h
		"deviceToken":APA91b Fyq5fhaDy8yUfh-tgN71pdeGwm0biD2iVC8nOilByNVzRkud5cIOvG4IAwDDfdLJkddTmHHm7ChbbBp81QRQ7mTREFqgKnQ025xMbULEjHRQjBwRCEMhfKiFFIT5VRCALyZubT
		"deviceToken":APA91b GGbm398wXiqXp4PloYpJsCK4m8P1UBoYIW9Y3LkN4OJcXxLCoyaNA3wuf8hI6bAAaRvUSKI-2tVYYXxDLHEtshIhy25iZn8UAs40Wew-2M8cHQudUTbBd41O1zsPMxWurV-uuP
		"installationId": "86c6013b-ff33-4cd7-a9e9-be0406cb22f5",
		"installationId": "69c467a6-1a08-449c-865f-004e629d7ca0",
		"installationId": "682a7312-6f43-4d2b-9e47-50f1564b0852",
	- _Role
	- Session


### # object = row
- limitation
	- size is 128kb 
	- no more than 64 fields and field name is not longer than 1024 chars

```javascript 
	{ // default property
		objectId: "xWMyZ4YEGZ",
		createdAt:"2011-06-10T18:33:42Z", 
		updatedAt:"2011-06-10T18:33:42Z"
	}

	var objectId  = object.id;
	var updatedAt = object.updatedAt;
	var createdAt = object.createdAt;
```

### # key = property

### # value  
- ref. [data type](https://www.parse.com/docs/js/guide#data)
any json encodable include String Number Boolean Array Object Date Parse.File Parse.Object Parse.Relation Null , 

- pointer
	point to other class
- GeoPoint
	geo location property
- Object
	hash
- array
	array
- relation
	related to multi object in the same class
- Date
	just date
- file
	use Parse.File to save it , ref to File



### # basic Parse object

**new object**
```javascript 
	var Class = Parse.Object.extned( class_name );
	var object = new Class();
```
or
```javascript
	var GameClass = Parse.Object( class_name , object_method , class_method );

	# object_method = {
			method_name : function(){}
		}
	# class_method = {
			method_name : function(){}
		}
```

**set , get , unset , add property**
```javascript
	object.get( key );
	object.set( key , value );

	// \for array field
	object.add( key , value );
	object.addUnique( key , value );
	object.remove( key )
```

**save** and **update**
```javascript
	object.save(null,{
		success : function( object ){},
		error 	: function( object , error )
	});
```

**query**
```javascript
	var query = new Parse.Query( Class );

	
	// query condition
	query.equalTo( key , value );			// include object.id
	query.notEqualTo( key , value );
	query.limit(Number)

	// sortable condition
	query.lessThan("wins", 50);
	query.lessThanOrEqualTo("wins", 50);
	query.greaterThan("wins", 50);
	query.greaterThanOrEqualTo("wins", 50);
	query.ascending( key );									
	query.descending( key );								
	query.containedIn( key ,[ value1 , value2 , value3 ]);
	query.notContainedIn( key ,[ value1 , value2 , value3 ]);
	query.exists( key );
	query.doesNotExist( key );
	query.include( key );				// key set
	query.include( [ key . key . key ....] ) 	// ***** connected by dot

	// ?
	var userQuery = new Parse.Query(Parse.User);
	userQuery.matchesKeyInQuery( key , value , query);
	userQuery.doesNotmatchesKeyInQuery( key , value , query);

	// select out columns
	query.select( key , key , .... )

	// array condition
	query.equalTo( "arraykey" , value );
	query.containsAll( "arraykey" , [ value , value , value ])

	// string condition
	query.startsWith( key , value )

	// query condition
	query.matchesQuery( key , query );
	query.doesNotMatchesQuery( key , query );


	// or condition
	var mixed_query = Parse.Query.or( query1 , query2 );

	

	// query submit
	query.get( objectId , {
		success : function( object ){},
		error 	: funciton( object , error ){}
	});

	query.first({
		success : function(){},
		error		: function(){}
	})

	query.count({
		success : function(){},
		error		: function(){}
	})

	


```

**fetch** , checkout last data
```javascript
	object.fetch({
		success : function(){},
		error 	: function(){}
	});
```


**increment** and **decrement** if the field is Number , and there is a issue for multi clients access same property
```javascript
	object.increment(key);
	object.decrement(key);
```

**destroy object**
```javascript
	object.destroy({
		success : function(){},
		error 	: function(){}
	})
```



### Relational data

**single relation** and **get relational object**
```javascript
	obj1.set("parent",obj2)	// set obj2.id to obj1.parent

	var obj2 = obj1.get("parent")
	obj2.fetch({
		success : function(){},
		error		: function(){}
	})
```

**multi relation**
```javascript
	var user = Parse.User.current();
	var relation = user.relation(class_name);
	relation.add( obj );

	relation.add( [ obj1 , obj2 , obj3 ] )

```

**relation query**
```javascript
	var query = relation.query();	
	
	query.find({										// get result of 
		success : function(){},
		error		: function(){}
	});
```


###### User inherited from Object

**default key **
- username
- password
- email ( optional )

**sign up**
```javascript
	var user = new Parse.User();
	user.signUp(null,{
		success : function(){},
		error		: function(){}
	});
```

**login**
```javascript
	Parse.User.logIn( username , password , {
		success : function(){},
		error		: function(){}
	});
```

**logout**
```javascript
	Parse.User.logOut()
```


**email Verified**  When a Parse.User\'s email is set or modified, emailVerified is set to false. 
```javascript
	user.set( "emailVerified" , false )
```

**current user**
```javascript
	var currentUser = Parse.User.current();
```


### # Session
session and installationId are pair
it\'ll create by login or signup , and destroy by logout

##### # get session
```javascript
	var user = Parse.User.current();
	user.getSessionToken();
```

**session token** to get current user by developer server
```javascript
Parse.User.become("session-token-here")
```




### # File

##### # new file object
```
var base64 = "V29ya2luZyBhdCBQYXJzZSBpcyBncmVhdCE=";
var file = new Parse.File("myfile.txt", { base64: base64 }); 	
```
or
```
var bytes = [ 0xBE, 0xEF, 0xCA, 0xFE ];
var file = new Parse.File("myfile.txt", bytes);
```

Parse will auto-detect the type of file you are uploading based on the file extension, 
but you can specify the Content-Type with a third parameter:
`var file = new Parse.File("myfile.zzz", fileData, "image/png");`

##### # save
```
parseFile.save().then(function() {
  // The file has been saved to Parse.
}, function(error) {
  // The file either could not be read, or could not be saved to Parse.
});
```

##### # associate with a object
```javascript
var jobApplication = new Parse.Object("JobApplication");
jobApplication.set("applicantName", "Joe Smith");
jobApplication.set("applicantResumeFile", parseFile);
jobApplication.save();
```

##### # delete files 
files are referenced by objects using the [REST API](https://www.parse.com/docs/rest#files-deleting-files)



### # ACL

###### # ACL usage sample
```javascript
	var postACL = new Parse.ACL(Parse.User.current());
	postACL.setPublicReadAccess(true);		

	var publicPost = new Post();	// a Parse Object
	publicPost.setACL(postACL);
	publicPost.save();

```


##### # setReadAccess  , setWriteAccess
```javascript
	var acl = new Parse.ACL();
	acl.setReadAccess(user_id,true);

	acl.setWriteAccess(user_id,true);
```

##### # setPublicReadAccess , setPublicWriteAccess 
```javascript
	acl.setPublicReadAccess(true);
	acl.setPublicWriteAccess(true);
```


### # Config
may be implement by parse app/config/*
- limitation
	- up to 100 parameters in your config and a total size of 128KB across all parameters.
- supported type
	- string
	- number
	- Date
	- Parse.File
	- Parse.GeoPoint
	- JS Array
	- JS Object

```javascript
	Parse.Config.get().then(function(config){

	},function(error){

	});
```