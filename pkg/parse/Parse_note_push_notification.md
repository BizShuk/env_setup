ref. [push tutorial](https://parse.com/tutorials/android-push-notifications)

> The Parse Android SDK chooses a reasonable default configuration so that you do not have to worry about GCM registration ids, sender ids, 
> or API keys. In particular, the SDK will automatically register your app for push at startup time using Parse's sender ID (1076345567071) 
> and will store the resulting registration ID in the deviceToken field of the app's current ParseInstallation.

according to above , it's may using GCM in parse backend.

multi sender id

### # push

##### # ways to push
Sending notifications is often done from the **Parse.com push console**, the **REST API** or from **Cloud Code**.

Cloud code 
```javascript
	var query = new Parse.Query(Parse.Installation);
	query.equalTo('gender', 'male');
	query.greaterThanOrEqualTo('age', 18);
	  
	Parse.Push.send({
	  where: query, // Set our Installation query
	  data: {
	    alert: "A test notification from Parse!"
	  }
	});
```

Access by REST api . predefined cloud function needed
```bash
	curl -X POST \
	  -H "X-Parse-Application-Id: your_app_id" \
	  -H "X-Parse-REST-API-Key: your_rest_api_key" \
	  -H "Content-Type: application/json" \
	  -d '{
	        "where": {
	          "gender": "male",
	          "age": { "$gte" :18 }
	        },
	        "data": {
	          "alert": "A test notification from Parse!"
	        }
	      }' \
	  https://api.parse.com/1/push
```

Console
- A/B testing 
	choose better one to send rest of user
- expired time limited
- msg type (msg , json)
- localization

### # CUSTOMIZING YOUR NOTIFICATIONS

##### # send JSON obj
JSONObject to package all of the data. There are some reserved fields that have a special meaning in Android.
- alert: the notification's message.
- uri: (Android only) an optional field that contains a URI. When the notification is opened, an Activity associated with opening the URI is launched.
- title: (Android, Windows 8, & Windows Phone 8 only) the value displayed in the Android system tray or Windows 8 toast notification.

##### # SETTING AN EXPIRATION DATE
```
ParsePush push = new ParsePush();
push.setExpirationTime(1424841505);
push.setQuery(everyoneQuery);
push.setMessage("Season tickets on sale until February 25th");
push.sendPushInBackground();
```

##### # Channel push
subscribe channel
```
	ParsePush.subscribeInBackground("Giants");
	ParsePush.unsubscribeInBackground("Giants");
```

SENDING PUSHES TO CHANNELS
```
	ParsePush push = new ParsePush();
	push.setChannel("Giants");
	push.setMessage("The Giants just scored! It's now 2-2 against the Mets.");
	push.sendInBackground();
```

channel with query
```
	// Create our Installation query
	ParseQuery pushQuery = ParseInstallation.getQuery();
	pushQuery.whereEqualTo("channels", "Giants"); // Set the channel
	pushQuery.whereEqualTo("scores", true);

	// Send push notification to query
	ParsePush push = new ParsePush();
	push.setQuery(pushQuery);
	push.setMessage("Giants scored against the A's! It's now 2-2.");
	push.sendInBackground();
```

##### # Audience
all segments are associated with installation object




### # Receiving Pushes 
```
	ParseInstallation.getCurrentInstallation()
	ParseInstallation.getCurrentInstallation().saveInBackground();
```

##### # MANAGING THE PUSH LIFECYCLE
3 phrases
-  A notification is received and com.parse.push.intent.OPEN
	ParsePushBroadcastReceiver to call onPushReceive
- user taps on a Notification, and the com.parse.push.intent.OPEN Intent is fired. 
	ParsePushBroadcastReceiver calls onPushOpen. 
- user dismisses a Notification
	com.parse.push.intent.DELETE Intent is fired. The ParsePushBroadcastReceiver calls onPushDismiss

##### # push by client 
set Client Push Enabled on push console




