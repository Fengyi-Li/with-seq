#!/bin/bash

SEQ_TAG="2023.1.8847"

if ! type seqcli >/dev/null 2>&1
then
    echo "installing seqcli"
    wget https://github.com/datalust/seqcli/releases/download/v2021.3.510/seqcli-2021.3.510-linux-x64.tar.gz -P /tmp

    sudo tar -C /usr/local -xzf /tmp/seqcli-2021.3.510-linux-x64.tar.gz

    sudo cp -s /usr/local/seqcli-2021.3.510-linux-x64/seqcli /usr/bin/seqcli
    sudo chmod +x /usr/bin/seqcli
else 
    echo "seqcli already installed, skipping"
fi

if [ "$( docker container inspect -f '{{.State.Running}}' seq )" == "true" ]; 
then
    echo "seq container already running, skipping"
else
    echo "starting seq server"

    docker run --name seq -d --restart unless-stopped -e ACCEPT_EULA=Y -p 5341:80 datalust/seq:$SEQ_TAG

    echo "waiting for seq to start..."
    for _ in {0..9}
    do
        (seqcli workspace list) > /dev/null 2>&1
        result=$?

        if [[ $result -eq 0 ]];
        then
            break
        else
            sleep 1
        fi
    done

    if [[ $result -ne 0 ]];
    then
        echo "seq didn't start in time, something may be wrong"
    fi
fi

# This workspace gets created in each new seq instance, but there are a lot of issues getting 
# configs from it so it's easier to just ignore it and use a default empty workspace.
seqcli workspace remove -o user-admin -t Personal > /dev/null 2>&1 || :

