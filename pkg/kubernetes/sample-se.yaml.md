```yaml
apiVersion: <api version [v1]>
kind: <service category [Service|ReplicationCOntroller]>
metadata:
  name: <service name>                  # [\w\-]
  labels:
    name: <name>                        # [\w\_\-]
    context:
    app:
    # ...... anything you want


# for service spec
speac:
  ports:
  - port: <port>
    name: <port_name>                   # [\w\-]
    targetPort: <port>
    protocol: <protocol [TCP|UPD]>
  - port: ...
    name: ...
    targetPort: ...
    protocol: ...
  selector: # confitions for finding pods , same as lablels 
    name: <name>
    ...
```
