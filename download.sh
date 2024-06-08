#!/usr/bin/env bash

# Copyright (c) Meta Platforms, Inc. and affiliates.
# This software may be used and distributed according to the terms of the Llama 2 Community License Agreement.

set -e

read -p "Enter the URL from email: " https://download6.llamameta.net/*?Policy=eyJTdGF0ZW1lbnQiOlt7InVuaXF1ZV9oYXNoIjoidmxyZ2M5bmUzN2hpYWtoaDA3Y3NubXo3IiwiUmVzb3VyY2UiOiJodHRwczpcL1wvZG93bmxvYWQ2LmxsYW1hbWV0YS5uZXRcLyoiLCJDb25kaXRpb24iOnsiRGF0ZUxlc3NUaGFuIjp7IkFXUzpFcG9jaFRpbWUiOjE3MTc5NDgyNzJ9fX1dfQ__&Signature=Z4AG8RF3vaVdf-nhOshE33xoV4Nlyod6wDCNNphf9o%7ExA8pm-iU5tbi057NF4dwk2686NHQB%7Ey89vGIWwwt0CUP2dRzz5ZKMRpAmNCTwBSWlOTJ%7EYstPYhoMXsaFskEmX4JdM-XqMiOPRUssCesLw%7E1JORN%7EUs37z1niBMF8QX5tkRuCCPVvNt-Ytkr2ZZE5LhFDDa%7E3FYrZMVELPmK1VjkNqKrdDopt4KNoqTfVAXNCvRPMG%7E%7EH01j3U0P6-oMxoOzsWdW75EXWQN4xNeUkEHgINy6mWfiun6PepRTqVO66j2yi6ED8LM4q3qXEVu1OpsHhlwr-jD%7EbYUwxxSE1qw__&Key-Pair-Id=K15QRJLYKIFSLZ&Download-Request-ID=434927612648665"
echo ""
read -p "Enter the list of models to download without spaces (8B,8B-instruct,70B,70B-instruct), or press Enter for all: " MODEL_SIZE
TARGET_FOLDER="."             # where all files should end up
mkdir -p ${TARGET_FOLDER}

if [[ $MODEL_SIZE == "" ]]; then
    MODEL_SIZE="8B,8B-instruct,70B,70B-instruct"
fi

echo "Downloading LICENSE and Acceptable Usage Policy"
wget --continue ${PRESIGNED_URL/'*'/"LICENSE"} -O ${TARGET_FOLDER}"/LICENSE"
wget --continue ${PRESIGNED_URL/'*'/"USE_POLICY"} -O ${TARGET_FOLDER}"/USE_POLICY"

for m in ${MODEL_SIZE//,/ }
do
    if [[ $m == "8B" ]] || [[ $m == "8b" ]]; then
        SHARD=0
        MODEL_FOLDER_PATH="Meta-Llama-3-8B"
        MODEL_PATH="8b_pre_trained"
    elif [[ $m == "8B-instruct" ]] || [[ $m == "8b-instruct" ]] || [[ $m == "8b-Instruct" ]] || [[ $m == "8B-Instruct" ]]; then
        SHARD=0
        MODEL_FOLDER_PATH="Meta-Llama-3-8B-Instruct"
        MODEL_PATH="8b_instruction_tuned"
    elif [[ $m == "70B" ]] || [[ $m == "70b" ]]; then
        SHARD=7
        MODEL_FOLDER_PATH="Meta-Llama-3-70B"
        MODEL_PATH="70b_pre_trained"
    elif [[ $m == "70B-instruct" ]] || [[ $m == "70b-instruct" ]] || [[ $m == "70b-Instruct" ]] || [[ $m == "70B-Instruct" ]]; then
        SHARD=7
        MODEL_FOLDER_PATH="Meta-Llama-3-70B-Instruct"
        MODEL_PATH="70b_instruction_tuned"
    fi

    echo "Downloading ${MODEL_PATH}"
    mkdir -p ${TARGET_FOLDER}"/${MODEL_FOLDER_PATH}"

    for s in $(seq -f "0%g" 0 ${SHARD})
    do
        wget --continue ${PRESIGNED_URL/'*'/"${MODEL_PATH}/consolidated.${s}.pth"} -O ${TARGET_FOLDER}"/${MODEL_FOLDER_PATH}/consolidated.${s}.pth"
    done

    wget --continue ${PRESIGNED_URL/'*'/"${MODEL_PATH}/params.json"} -O ${TARGET_FOLDER}"/${MODEL_FOLDER_PATH}/params.json"
    wget --continue ${PRESIGNED_URL/'*'/"${MODEL_PATH}/tokenizer.model"} -O ${TARGET_FOLDER}"/${MODEL_FOLDER_PATH}/tokenizer.model"
    wget --continue ${PRESIGNED_URL/'*'/"${MODEL_PATH}/checklist.chk"} -O ${TARGET_FOLDER}"/${MODEL_FOLDER_PATH}/checklist.chk"
    echo "Checking checksums"
    CPU_ARCH=$(uname -m)
    if [[ "$CPU_ARCH" == "arm64" ]]; then
      (cd ${TARGET_FOLDER}"/${MODEL_FOLDER_PATH}" && md5 checklist.chk)
    else
      (cd ${TARGET_FOLDER}"/${MODEL_FOLDER_PATH}" && md5sum -c checklist.chk)
    fi
done
