```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello-world
spec:  # specification of the pod’s contents
  restartPolicy: [Never | Always]
  containers:
  - name: hello
    env:
    - name: MESSAGE
      value: "hello world"
    image: "ubuntu:14.04"
    command: ["/bin/sh","-c"]
    args: ["/bin/echo \"${MESSAGE}\""]
    imagePullPolicy: IfNotPresent
```
