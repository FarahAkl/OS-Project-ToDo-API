## 📚 To Do API Project

### Simple API built with node.js, express and mongoDB

1- Install Dependences 

```
npm init -y
npm i express
npm i mongoose

```

2-  Write app.js code

3- Add docker file

4- Build my app on docker and install mongo image

```
docker network create my-network

docker run -d --name mongo --network my-network -p 27017:27017 mongo

docker build -t todo .

docker run -d -p 3070:3000 --name todo --network my-network todo

```

5- Test the app on git bash

```
curl -X POST http://127.0.0.1:3070/todos \
  -H "Content-Type: application/json" \
  -d '{"task": "Finish assignment"}'

```

**Note:** test run on port 3070