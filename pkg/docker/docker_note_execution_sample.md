## log docker log

    JOB=$(docker run -d ubuntu /bin/sh -c "while true; do echo Hello world; sleep 1; done")
    docker logs $JOB
    docker kill $JOB

## bind tcp port

    JOB=$(docker run -d -p 4444 ubuntu:12.10 /bin/nc -l 4444)
    PORT=$(docker port $JOB 4444 | awk -F: '{ print $2 }')  # this port 4444 mean container private port , not bind to container
    echo hello world | nc 127.0.0.1 $PORT
    echo "Daemon received: $(docker logs $JOB)"