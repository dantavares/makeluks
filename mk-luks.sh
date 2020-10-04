#!/bin/bash
#Versao: 1.5

#Define a cifra, pode ser: twofish, aes, serpent
ciph=twofish

#Define o sistema de arquivo a ser usado
form=ext2

label=pdcrypt

#####################################################################################

checksudo(){
    echo Entre com a senha do usuario:
    if [ $(sudo id -u) != 0 ] 
    then
        echo "Parece que tem algo errado com a senha do usuário"
        echo "Tente novamente quando tiver certeza sobre isso"
        exit
    fi
}

checkfile(){
    if [[ $(blkid -s TYPE -o value $pcrypt) != "crypto_LUKS" ]]
    then
        echo "Não é um arquivo de criptografia LUKS"
        exit
    fi
}

crypt(){
    pwf=$(mktemp) pwf2=$(mktemp)
    chmod 600 "$pwf" "$pwf2"
    while [ ! -s "$pwf" ]
    do
        /lib/cryptsetup/askpass "Defina a senha de criptografia:" >"$pwf"
        echo
        if [ -s "$pwf" ]
        then
            /lib/cryptsetup/askpass "Confirme a senha:" >"$pwf2"
            echo
            diff -q --label $'\b\b\b\b\b\b\b\b primeira' "$pwf" \
				--label "segunda senha" "$pwf2" || shred -u "$pwf"
            shred -u "$pwf2"
        else
            echo -e "Senha em branco nao!\n"
        fi
    done
    read -p "Defina o nome do volume: " label
    checksudo
    echo "Iniciando o processo, aguarde..." ; 
    sudo cryptsetup luksFormat -q -c "$ciph"-xts-plain64 -s 512 -h sha512 -i 5000 -y "$pcrypt" --key-file "$pwf" --use-random
    sudo cryptsetup luksOpen "$pcrypt" pdcrypt --key-file "$pwf"
    sudo mkfs.$form -L $label /dev/mapper/pdcrypt
    sleep 5
    sudo cryptsetup luksClose pdcrypt
    clear
    echo Tudo pronto! Reinsira o dispositivo para começar a usar
    exit
}

makedrive(){
    clear
    ls /dev/sd*
    read -p "Entre com o dispositivo a ser formatado: /dev/" pcrypt
    pcrypt=/dev/$pcrypt
    clear
    echo "Dispositivo selecionado: " $pcrypt
    echo "Cifra a ser usada: " $ciph
    echo "Sistema de arquivo a ser usado: " $form

    while true; do
        read -p "Tem certeza que deseja continuar? Dados poderão ser perdidos S ou N: " sn
        case $sn in
            [Ss]* ) crypt;;
            [Nn]* ) exit;;
            * ) echo "Responda S(sim) ou N(não): ";;
        esac
    done
}

makefile(){
    clear
    pcrypt=sem_nome
    read -p "Defina o nome do arquivo: " pcrypt
    pcrypt=$pcrypt.luks
    read -p "Defina o tamanho do arquivo Ex: 100M, 1G : " size
    clear
    echo "Nome do arquivo: "$pcrypt
    echo "Tamanho do arquivo: " $size
    echo "Cifra a ser usada: " $ciph
    echo "Sistema de arquivo a ser usado: " $form
    echo "Aguarde..."
    fallocate -l $size /tmp/$pcrypt
    mv /tmp/$pcrypt $(dirname "$SCRIPT")/
    crypt   
}

decrypt(){
    checksudo
    sudo cryptsetup luksOpen "$pcrypt" $UUID
}

if [[ $1 == "" ]]
then
    while true; do
        read -p "Deseja criar um arquivo(A) ou um drive(D) criptografado? " ad
            case $ad in
                [Aa]* ) makefile;;
                [Dd]* ) makedrive;;
                * ) echo "Responda A(arquivo) ou D(drive): ";;
            esac
    done
else
    pcrypt=$1
    if [ -f $pcrypt ] 
    then
        checkfile
        UUID=$(blkid -s UUID -o value "$pcrypt")
        if [ -e /dev/mapper/$UUID ] 
        then
            echo "Pronto para desmontar "$pcrypt
            read -p "Enter para continuar ou Control+C para cancelar"
            checksudo
            sudo umount /dev/mapper/$UUID
            sudo cryptsetup luksClose $UUID
            exit            
        else
            decrypt
        fi
    else
        exit
    fi
fi
