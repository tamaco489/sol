#!/bin/bash

ENV="stg"
ORIGINAL_DOMAIN=""
DIRECTORIES=("route53" "acm") # domainを変数として保持するtfvarsファイルがあるディレクトリを指定

# ファイルが存在するかどうかを確認
check_file_exists() {
    if [ ! -f "$1" ]; then
        echo "File not found: $1"
        exit 1
    fi
}

# 置換
revert_domain() {
    local file_path=$1
    sed -i "" "s/domain = \".*\"/domain = \"$ORIGINAL_DOMAIN\"/" "$file_path"
}

# メイン処理
main() {
    for dir in "${DIRECTORIES[@]}"; do
        FILE_PATH="../${dir}/tfvars/${ENV}.tfvars"
        if [ -f "$FILE_PATH" ]; then
            revert_domain "$FILE_PATH"
            echo "Domain has been reverted in $FILE_PATH"
        else
            echo "File not found: $FILE_PATH"
        fi
    done
}

# スクリプトの実行
main
