#!/bin/bash

# Configuration
CONTAINER_NAME="llm_research"
IMAGE_NAME="llm_research_env"
HOST_DIR="/home/user/llm_research_bind"
CONTAINER_DIR="/home/tomori/bind"
JUPYTER_PORT="8888"

# Function to check if container exists
container_exists() {
    docker ps -a -q -f name=$CONTAINER_NAME
}

# Function to check if container is running
container_running() {
    docker ps -q -f name=$CONTAINER_NAME
}

# Build Docker image
build() {
    echo "Building Docker image: $IMAGE_NAME"
    docker build -t $IMAGE_NAME .
}

# Run container
run() {
    if [ $(container_running) ]; then
        echo "Container is already running. Use 'attach' to connect."
        exit 1
    fi
    
    if [ $(container_exists) ]; then
        echo "Starting existing container..."
        docker start $CONTAINER_NAME
    else
        echo "Creating and starting new container..."
        mkdir -p $HOST_DIR
        docker run -d \
            --gpus all \
            -v $HOST_DIR:$CONTAINER_DIR \
            -p $JUPYTER_PORT:8888 \
            --name $CONTAINER_NAME \
            $IMAGE_NAME
    fi
}

# Attach to running container
attach() {
    if [ ! $(container_running) ]; then
        echo "Container is not running. Starting it..."
        run
    fi
    docker exec -it $CONTAINER_NAME bash
}

# Stop container
stop() {
    if [ $(container_running) ]; then
        echo "Stopping container..."
        docker stop $CONTAINER_NAME
    else
        echo "Container is not running."
    fi
}

# Remove container
remove() {
    stop
    if [ $(container_exists) ]; then
        echo "Removing container..."
        docker rm $CONTAINER_NAME
    else
        echo "Container does not exist."
    fi
}

# Start JupyterLab
start_jupyter() {
    if [ ! $(container_running) ]; then
        echo "Starting container..."
        run
    fi
    echo "Starting JupyterLab..."
    docker exec $CONTAINER_NAME bash -c "source /home/tomori/env/LLM/bin/activate && jupyter lab --ip=0.0.0.0 --port=8888 --no-browser"
    echo "JupyterLab started. Check container logs for the access URL and token."
}

# Show container logs
logs() {
    docker logs $CONTAINER_NAME
}

# Debug container state
debug() {
    echo "Container status:"
    docker ps -a -f name=$CONTAINER_NAME
    echo -e "\nContainer logs:"
    docker logs $CONTAINER_NAME
    if [ $(container_running) ]; then
        echo -e "\nChecking /home/tomori contents:"
        docker exec $CONTAINER_NAME ls -la /home/tomori
        echo -e "\nChecking /home/tomori/bind contents:"
        docker exec $CONTAINER_NAME ls -la /home/tomori/bind
        echo -e "\nChecking Python environment:"
        docker exec $CONTAINER_NAME bash -c "source /home/tomori/env/LLM/bin/activate && python --version && pip list"
        echo -e "\nChecking Jupyter kernels:"
        docker exec $CONTAINER_NAME bash -c "jupyter kernelspec list"
    else
        echo -e "\nContainer is not running, cannot inspect directories or environment."
    fi
}

# Display help
help() {
    echo "Usage: $0 {build|run|attach|stop|remove|jupyter|logs|debug|help}"
    echo "Commands:"
    echo "  build   - Build the Docker image"
    echo "  run     - Run the container in detached mode"
    echo "  attach  - Attach to the running container"
    echo "  stop    - Stop the running container"
    echo "  remove  - Remove the container"
    echo "  jupyter - Start JupyterLab in the container"
    echo "  logs    - Show container logs"
    echo "  debug   - Inspect container state and directories"
    echo "  help    - Display this help message"
}

# Handle commands
case "$1" in
    build)
        build
        ;;
    run)
        run
        ;;
    attach)
        attach
        ;;
    stop)
        stop
        ;;
    remove)
        remove
        ;;
    jupyter)
        start_jupyter
        ;;
    logs)
        logs
        ;;
    debug)
        debug
        ;;
    help|*)
        help
        ;;
esac
