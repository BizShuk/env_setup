## [Restful API](https://docs.docker.com/registry/spec/api/)

##### push to private remote registry
1. tag image with `host:port/image:tag` 10.128.112.11:5000/duck:v4
2. `docker push host:port/image:tag`

##### api
- `GET  /v2/` , version check

    200 , ok
    401 , Unauthorized
    404 , dont implement v2 of API


GET /v2/_catalog?n=<integer>
Retrieve a sorted, json list of repositories available in the registry.

    {
      "repositories": [
        <name>,
        ...
      ]
    }


GET /v2/<repo_name>/tags/list
show ths repo all tags

GET /v2/<repo_name>/manifests/<reference>
get the manifest

PUT /v2/<repo_name>/manifests/<reference>
put the manifest

DELETE /v2/<name>/manifests/<reference>
delete the manifest
<reference> = a digest