#!/bin/bash

# 导入工具包
source ./tool.sh

funCreateRootCert(){
    outPath=$1
    defSubj="/C=CN/ST=Guangdong/L=Shenzhen/O=xx/OU=chain/CN=ca/emailAddress=xx@xx.com"

    if [ -d ${outPath} ]; then
        echo "have root cert"
        exit 1
    fi

    # 判断并新建目录
    funCheckAndCreateDir ${outPath}

    openssl ecparam -name secp256k1 -out ${outPath}/root.param
    openssl genpkey -paramfile ${outPath}/root.param -out ${outPath}/root.key

    openssl req -new -sha256 -nodes -key ${outPath}/root.key -out ${outPath}/root.csr -config ./config.cnf -extensions v4_req -subj ${defSubj}

    openssl x509 -sha256 -req -in ${outPath}/root.csr -out ${outPath}/root.crt -signkey ${outPath}/root.key -days 36500 -extfile ./config.cnf -extensions v4_req
}

# funCreateRootCert ./root

funCreateOrgCert(){
    outPath=$1
    rootPath=$2

    defSubj="/C=CN/ST=Guangdong/L=Shenzhen/O=org/OU=chain/CN=org/emailAddress=xx@xx.com"

    # 判断并新建目录
    funCheckAndCreateDir ${outPath}

    openssl ecparam -name secp256k1 -out ${outPath}/org.param
    openssl genpkey -paramfile ${outPath}/org.param -out ${outPath}/org.key

    openssl req -new -sha256 -nodes -key ${outPath}/org.key -out ${outPath}/org.csr -config ./config.cnf -extensions v4_req -subj ${defSubj}

    openssl x509 -sha256 -req -days 365 -in ${outPath}/org.csr -out ${outPath}/org.crt -CA ${rootPath}/root.crt -CAkey ${rootPath}/root.key -CAserial ${outPath}/serial.srl -CAcreateserial -extfile ./config.cnf -extensions v4_req
}

# funCreateOrgCert ./org1 ./root

funCreateNodeCert(){
    outPath=$1
    orgCertPath=$2

    defSubj="/C=CN/ST=Guangdong/L=Shenzhen/O=node0/OU=chain/CN=org/emailAddress=xx@xx.com"

    # 判断并新建目录
    funCheckAndCreateDir ${outPath}

    openssl ecparam -name secp256k1 -out ${outPath}/node.param
    openssl genpkey -paramfile ${outPath}/node.param -out ${outPath}/node.key

    openssl req -new -sha256 -nodes -key ${outPath}/node.key -out ${outPath}/node.csr -config ./config.cnf -extensions v3_req -subj ${defSubj}

    openssl x509 -sha256 -req -days 365 -in ${outPath}/node.csr -out ${outPath}/node.crt -CA ${orgCertPath}/org.crt -CAkey ${orgCertPath}/org.key -CAserial ${outPath}/serial.srl -CAcreateserial -extfile ./config.cnf -extensions v3_req

    openssl ec -in ${outPath}/node.key -text -noout | sed -n '7,11p' | tr -d ": \n" | awk '{print substr($0,3);}' | cat >${outPath}/node.nodeid

    cat ${orgCertPath}/org.crt >> ${outPath}/node.crt
}

# funCreateNodeCert ./node1 ./org1

funHelp(){

cat << EOF
Usage:
    -r|-R <root cert path>                              [Required]
        e.g:
            bash create.sh -r ./root
    -o|-O <org cert output path> <root cert path>       [Required]
        e.g:
            bash create.sh -o ./org1 ./root
    -n|-N <node cert output path> <org cert path>       [Required]
        e.g:
            bash create.sh -n ./node1 ./org1
    -h|help help
EOF

}


main(){

    funName=$1

    case $funName in
        -r|-R)
            OUT_PATH=${2}
            funCreateRootCert ${OUT_PATH}
            ;;
        -o|-O)
            OUT_PATH=${2}
            ROOT_PATH=${3}
            funCreateOrgCert ${OUT_PATH} ${ROOT_PATH}
            ;;
        -n|-N)
            OUT_PATH=${2}
            ORG_PATH=${3}
            funCreateNodeCert ${OUT_PATH} ${ORG_PATH}
            ;;
        -h|help)
            funHelp
            ;;
    esac
}


main "$@"
