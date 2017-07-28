# Whitepages degrees of separation application

This is an application that lets the user connect 2 individuals by tracing the shortest path between them. A given person has 3 types of connections - associated people; addresses he/she has lived at or lives in; phone number(s). Those associated people have similar connections. Other people may have lived at the same addresses and similarly, may have shared the same phone numbers. This is like a graph problem where nodes are either persons, addresses or phone numbers. Those nodes have edges connecting them to represent the connection. This application does a breadth first search from a source person to a destination person and the displays the resulting edges. The maximum depth is capped at 4 to avoid long latencies for the end user. 

The application has been written in ruby on rails and uses bootstrap for the ui styling. There is a dockerfile so that one can deploy in a docker. 

Assumption - If the source person resolves to multiple person records in the whitepages system, the first person record is taken as the source node. Otherwise, this becomes a many to many graph traversal problem and that can lead high latencies for the user experience. 

#Building Docker Container

Run in the project directory - 

```bash
docker build . -t wp-graph-search
```

#Running the application

## Set the API key - 

Set the provided Pro API key in the `.env.production` file.

## Run the docker container

Run in the project directory

```bash
docker run -it -p 3000:3000 --env-file ./.env.production wp-graph-search:latest
```

## Open the application in the browser

```
http://localhost:3000/
```

Enter any 2 persons' name, city and state code and hit submit. 