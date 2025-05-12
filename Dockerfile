# Use NVIDIA CUDA base image as specified
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies and basic development tools
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3-pip \
    tmux \
    git \
    vim \
    htop \
    wget \
    curl \
    nano \
    unzip \
    screen \
    build-essential \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create user tomori with sudo privileges
RUN useradd -m -s /bin/bash tomori && \
    mkdir -p /etc/sudoers.d && \
    echo "tomori ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/tomori && \
    chmod 0440 /etc/sudoers.d/tomori

# Switch to tomori user
USER tomori
WORKDIR /home/tomori

# Create and activate Python virtual environment
RUN python3.12 -m venv /home/tomori/env/LLM
ENV PATH="/home/tomori/env/LLM/bin:$PATH"

# Upgrade pip and install Python packages
RUN pip install --upgrade pip && \
    pip install \
    torch \
    vllm \
    transformers \
    accelerate \
    numpy \
    scipy \
    pandas \
    matplotlib \
    scikit-learn \
    gpustat \
    jupyterlab \
    ipykernel ipywidgets \
    datasets \
    peft \
    trl \
    bitsandbytes \
    tensorboard \
    seaborn \
    tqdm

# Register LLM environment as a Jupyter kernel
RUN python -m ipykernel install --user --name LLM --display-name "Python 3.12 (LLM)"

# Configure JupyterLab
RUN jupyter lab --generate-config && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> /home/tomori/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.port = 8888" >> /home/tomori/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.open_browser = False" >> /home/tomori/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.allow_remote_access = True" >> /home/tomori/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.root_dir = '/'" >> /home/tomori/.jupyter/jupyter_lab_config.py

# Expose JupyterLab port
EXPOSE 8888

# Override NVIDIA entrypoint
ENTRYPOINT []

# Keep container running
CMD ["tail", "-f", "/dev/null"]
