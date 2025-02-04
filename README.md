# React Native Service with Docker

This README provides instructions for setting up and running a React Native service using Docker.

## Prerequisites

- **Node.js**: Ensure you have Node.js installed on your machine.
- **Docker**: Install Docker and Docker Desktop.
- **React Native CLI**: Familiarity with React Native development is recommended.

## Steps to Run the Service

1. **Install Dependencies**
   Open your terminal and navigate to your project directory. Run the following command to install the necessary npm packages:

npm install


2. **Start Docker Desktop**
Make sure Docker Desktop is running on your machine. This is essential for building and running Docker containers.

3. **Build the Docker Image**
Execute the following command to build the Docker image. Ensure that the image name does not change:

docker build -t react-native-builder:latest -f src/Dockerfile .


4. **Start the Server**
After building the image, start the server by running:

npm run dev


5. **Accessing the Application**
You can hit the URL expected by your application. Below is a sample JSON configuration that your application might expect:
{
"url": "https://en.wikipedia.org/",
"appName": "WikipediaApp",
"config": {
"name": "WikipediaApp",
"bundleId": "com.example.wikipedia",
"version": "1.0.0"
}
}
