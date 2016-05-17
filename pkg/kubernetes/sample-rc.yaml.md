```yaml
apiVersion: <api version [v1]>
kind: <service category [Service|ReplicationCOntroller | pod]>
metadata:
	name: <service name>
	labels:													 # tags about this service
		name:
		context:
		app:
		# ...... anything you want


# for service spec
speac:
	replicas: <number>								# how many pods you want to create
	selector:												 # what is this for?
		<label>: <value>
	template:
		metadata:
			labels:
				<label>: <value>
		spec:
            imagePullSecrets:
            - name: myregistrykey
            
            volumes:  # ref [volumn](http://kubernetes.io/v1.0/docs/user-guide/volumes.html)
            - name:  <volumn name>
                emptyDir: {}
            - name: <volumn name>
                secret:
                    secretName: <secret name>
            restartPolicy: [Always|Never],

		    dnsPolicy: ClusterFirst,
		    serviceAccountName": default,
		    serviceAccount": default,
		    nodeName: gke-buildlets-e43731b5-node-flc5


			container:
			- name: <pod name>						# if write this at template->metadata->name , what's going?
				image: <docker image name [host:port/repo:tag]>
				imagePullPolicy: [Always|Never]
				terminationMessagePath: /dev/termination-log

                env:
                - name: GIT_REPO
                   value: http://github.com/some/repo.git

				ports:											# what is multi-port format?
				- containerPort: <port>
					name: <container port name>
					protocol: <protocol [TCP|UDP]>
				- containerPort: ...
					name: ...
					protocol: ...


				livenessProbe:
					httpGet:
						path: /healthz
						port: 8080
						scheme: HTTP
					initialDelaySeconds: 30
					timeoutSeconds: 5

				resources:
					limits:
						cpu: 100m
						memory: 50Mi
				
				command:										# this will overide docker cmd 
				- /usr/local/bin/nginx
				- -s reload
				
				args:
				- -machines=http://localhost:4001
				- -addr=0.0.0.0:53
				- -domain=cluster.local.
				- -verbose=true
				

				volumeMounts:
				- name: <volumn name>
					mountPath: <container path>

				readinessProbe:
					httpGet:
						path: /healthz
						port: 8080
						scheme: HTTP
					initialDelaySeconds: 1
					timeoutSeconds: 5
		status: {
   			"phase": "Pending",
    		"conditions": [
      			{
        			"type": "Ready",
        			"status": "False"
      			}
    		],
    		"hostIP": "10.240.72.26",
    		"podIP": "10.0.0.27",
    		"startTime": "2015-10-02T19:25:30Z",
    		"containerStatuses": [
      			{
        			"name": "buildlet",
        			"state": {
          				"waiting": {
            				"reason": "API error (500): Cannot start container efae12ec3f2de65eef0ac4a55830ede97ea7390b810c71e2bb7bdb17c20afc50: [8] System error: exec: \"sleep 10\": executable file not found in $PATH\n"
          				}
        			},
        			"lastState": {},
        			"ready": false,
        			"restartCount": 13,
        			"image": "gcr.io/go-dashboard-dev/linux-x86-std:latest",
        			"imageID": "docker://358d7a6c2440e014b0b830aa8e0c2dcfb2d889ddd8eafaaf5bd1365b3406ca1d",
        			"containerID": "docker://efae12ec3f2de65eef0ac4a55830ede97ea7390b810c71e2bb7bdb17c20afc50"
      			}
    		]
  		}
```
