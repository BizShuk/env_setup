[JMeter](http://jmeter.apache.org/index.html)
======

### installation:

	1. download [JMeter](http://jmeter.apache.org/download_jmeter.cgi) and unzip
	2. install java runtime enviroment(jre) and set JAVA_HOME,bin path
	3. exec apache-jmeter/bin/jmeter.bat


### web test plan
	URI = http://192.168.2.52:9876/home/test_performance.default.lua

	1. right click label "test plan" on left menu,
		 and ADD->Threads(Users)->Thread Groups

		 - set "Number of Threads (users)"
		 - set "Ramp-Up Period (in seconds)" 啟動延遲
		 - set "Forever" if you want endless loop or just set how many times
		 
		 # unnessaary
		 - Delay Thread creation until needed
		 - Scheduler 定時器

	2. right click label "test plan" on left menu,
		 and ADD->Sampler->HTTP request

		 - set "name" for project name
		 - set "Server Name of IP"
		 - set "Port Number"
		 - set "Implementation" , ex: POST or GET
		 - set "Protocol", ex: HTTP
		 - set "Path" , ex: home/test_performance.default.lua
		 - set Params , ex: key -> value or body-data , or it can use variable setting(#variable+setting)

  3. right click label "test plan" on left menu,
		 and ADD->Listeners->any one 

		 it can detect all consequences

	4. execute on menu bar arrow icon



### variable setting

	- CSV data config 
		1. right click on "test plan" of left menu , and ADD-> ->CSV data config
		2. set Params
			- "name" , just name
			- "filename" , file should put in JMeter bin dir
			- "variable Names" , ex: a,b,c,d
			- "Delimiter" , default:"," 間隔符號

		3. used by ${variable_name}

