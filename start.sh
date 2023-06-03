#!/usr/bin/env bash
export PYTHONUNBUFFERED=1
source /venv/bin/activate

# Sync venv to workspace to support Network volumes
echo "Syncing venv to workspace, please wait..."
rsync -au --remove-source-files /venv/ /workspace/venv/

# Sync Web UI to workspace to support Network volumes
echo "Syncing Stable Diffusion Web UI to workspace, please wait..."
rsync -au --remove-source-files /stable-diffusion-webui/ /workspace/stable-diffusion-webui/

# Sync Kohya_ss to workspace to support Network volumes
echo "Syncing Kohya_ss to workspace, please wait..."
rsync -au --remove-source-files /kohya_ss/ /workspace/kohya_ss/

if [[ ${PUBLIC_KEY} ]]
then
    echo "Installing SSH public key"
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    cd ~/.ssh
    echo ${PUBLIC_KEY} >> authorized_keys
    chmod 700 -R ~/.ssh
    cd /
    service ssh start
    echo "SSH Service Started"
fi

if [[ ${JUPYTER_PASSWORD} ]]
then
    echo "Starting Jupyter lab"
    ln -sf /examples /workspace
    ln -sf /root/welcome.ipynb /workspace

    cd /
    nohup jupyter lab --allow-root \
        --no-browser \
        --port=8888 \
        --ip=* \
        --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
        --ServerApp.token=${JUPYTER_PASSWORD} \
        --ServerApp.allow_origin=* \
        --ServerApp.preferred_dir=/workspace &
    echo "Jupyter Lab Started"
fi

if [[ ${DOWNLOAD_MODELS} ]]
then
  # Download Stable Diffusion v1.5 model
  wget -O /stable-diffusion-webui/models/Stable-diffusion/v1-5-pruned.safetensors  https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.safetensors

  # Download VAE
  wget -O /stable-diffusion-webui/models/VAE/vae-ft-mse-840000-ema-pruned.safetensors https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors
fi

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the applications not be started automatically"
    echo "You can launch them manually using the launcher scripts:"
    echo ""
    echo "   Stable Diffusion Web UI:"
    echo "   ---------------------------------------------"
    echo "   cd /workspace/stable-diffusion-webui"
    echo "   ./webui.sh -f"
    echo ""
    echo "   Kohya_ss"
    echo "   ---------------------------------------------"
    echo "   cd /workspace/kohya_ss"
    echo "   ./gui.sh --listen 0.0.0.0 --server_port 3010"
else
    mkdir -p /workspace/logs
    echo "Starting Stable Diffusion Web UI"
    cd /workspace/stable-diffusion-webui && nohup /workspace/stable-diffusion-webui/webui.sh -f > /workspace/logs/webui.log &

    echo "Starting Kohya_ss through launcher script"
    cd /workspace/kohya_ss && nohup ./gui.sh --listen 0.0.0.0 --headlesss --server_port 3010 > /workspace/logs/kohya_ss.log &
fi

if [ ${ENABLE_TENSORBOARD} ]; then
    echo "Staring Tensorboard"
    cd /workspace
    mkdir -p /workspace/logs/ti
    mkdir -p /workspace/logs/dreambooth
    ln -s /workspace/stable-diffusion-webui/models/dreambooth /workspace/logs/dreambooth
    ln -s /workspace/stable-diffusion-webui/textual_inversion /workspace/logs/ti
    nohup tensorboard --logdir=/workspace/logs --port=6006 --host=0.0.0.0 &
    echo "Tensorboard Started"
fi

echo "Container Started"

sleep infinity