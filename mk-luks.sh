#!/bin/bash
#Versao: 1.5

#Define a cifra, pode ser: twofish, aes, serpent
ciph=twofish

#Define o sistema de arquivo a ser usado
form=ext2

#Rótulo padrão, caso não informado
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

crypt(){
    pass=$(mktemp)
    chmod 600 "$pass"
    cont=true
    while $cont
    do
        read -s -p "Defina a senha de criptografia: " pwf
        echo
        if [ $pwf ]
        then
            read -s -p "Confirme a senha: " pwf2
            if [ $pwf == $pwf2 ]
            then
                echo -n $pwf > "$pass"
                cont=false
                echo
            else
                echo
                echo "Senhas não conferem, tente novamente"
            fi
        else
            echo
            echo "Senha em branco não!"
        fi
    done
    read -p "Defina o nome do volume: " label
    checksudo
    echo "Iniciando o processo, aguarde..." ; 
    sudo cryptsetup luksFormat -q -c "$ciph"-xts-plain64 -s 512 -h sha512 -i 5000 -y "$pcrypt" --key-file "$pass" --type luks2
    sudo cryptsetup luksOpen "$pcrypt" pdcrypt --key-file "$pass"
    sudo mkfs.$form -L $label /dev/mapper/pdcrypt
    sleep 5
    sudo cryptsetup luksClose pdcrypt
    rm "$pass"
    echo "Tudo pronto! Para montar e desmontar, especifique o dispositivo ou arquivo como parâmetro"
    echo "Ex: ./mk-luks.sh /dev/sdc1 ou ./mk-luks.sh teste.luks"
    echo "Você pode associar arquivos *.luks para ser aberto com este script, mas marque a opção abrir no console"
    exit
}

makedrive(){
    clear
    ls /dev/sd*
    read -p "Entre com o dispositivo a ser formatado: /dev/" pcrypt
    pcrypt=/dev/$pcrypt
    clear
    echo "Dispositivo selecionado: "$pcrypt
    echo "Cifra a ser usada: "$ciph
    echo "Sistema de arquivo a ser usado: "$form

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
    echo "Tamanho do arquivo: "$size
    echo "Cifra a ser usada: "$ciph
    echo "Sistema de arquivo a ser usado: "$form
    echo "Aguarde..."
    fallocate -l $size ~/$pcrypt
    mv ~/$pcrypt $(dirname "$SCRIPT")/
    crypt   
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
    if [[ -f $pcrypt || -e $pcrypt ]] 
    then
        cryptsetup isLuks $pcrypt        
        if [ $? == 0 ]
        then
            UUID=$(cryptsetup luksUUID $pcrypt)            
        else        
            echo "Não é um arquivo ou dispositivo LUKS"
            exit            
        fi        

        if [ -e /dev/mapper/$UUID ] 
        then
            echo "Pronto para desmontar "$pcrypt
            read -p "Enter para continuar ou Control+C para cancelar"
            checksudo
            sudo umount /dev/mapper/$UUID
            sudo rm -r /mnt/$UUID
            sudo cryptsetup luksClose $UUID
            exit            
        else
            checksudo
            sudo cryptsetup luksOpen "$pcrypt" $UUID
            sudo mkdir /mnt/$UUID
            sudo mount /dev/mapper/$UUID /mnt/$UUID
            sudo chmod 777 /mnt/$UUID
        fi
    else
        echo "Houve um erro"
        exit
    fi
fi
