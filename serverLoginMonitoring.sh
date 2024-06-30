#!/bin/bash
##########################################################################################################################
#------------------------------------------------------------------------------------------------------------------------#
#--------------------------------------------------- INFORMAÇÕES---------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------------------#
# Arquivo ~~~~ serverLoginMonitoring.sh
# Versão ~~~~~ v1
# Descrição ~~ Script para análise de logins mal-sucedidos em serviços
# Autor ~~~~~~ Matheus Seman < mateusseman@gmail.com >
#------------------------------------------------------------------------------------------------------------------------#
##########################################################################################################################
#------------------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------ ARRAYS ----------------------------------------------------------#

# Arrays estáticos #-----------------------------------------------------------------------------------------------------#
declare -A CORES=( 
                  [none]="\033[m"
                  [vermelho]="\033[1;31m"
                  [verde]="\033[1;32m"
                  [amarelo]="\033[1;33m"
) # Cores para melhor visualizaçao dos dados

declare -A DEPENDENCIAS=(
        [tee]="/usr/bin/tee"
        [less]="/usr/bin/less"
) # Dependencias necessárias para execução do script

# Arrays dinâmicos (Devem ser alteradas em caso de caminhos absolutos diferentes) #--------------------------------------#
declare -A LOGS=(
    [script]="/var/log/loginMonitoring.log"
    [ssh]="/var/log/auth.log"
    [zimbra]="/var/log/zimbra.log"
) # Logs utilizados no script

#------------------------------------------------------------------------------------------------------------------------#
##########################################################################################################################
#------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------- VARIÁVEIS ---------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------------------#
VERSAO=v1 # Versionamento do script
SCRIPT=${0##*/} # Retorna o nome do script
SCRIPT_DIR=/usr/local/bin # Local de armazenamento dos scripts
ARGUMENTO=$2 # Argumento adicional ./LoginMonitoring.sh $1 $2
IP_REGEX="^([0-9]{1,3}\.){3}[0-9]{1,3}$" # Formato do IP X.X.X.X

#------------------------------------------------------------------------------------------------------------------------#
##########################################################################################################################
#------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------- FUNÇOES -----------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------------------#
function _versaoScript_() {
    #--------------------------------------------------------------------------------------------------------------------#
    echo -e "Script para análise de logins mal-sucedidos em serviços - (GNU Linux) $SCRIPT ${CORES[amarelo]}$VERSAO${CORES[none]}"               
    echo "Copyright (C) 2024 Free Software Foundation."                                                              
    echo "Este software é livre, você é livre para alterá-lo e redistribuí-lo."                                      
    echo -e "Escrito e desenvolvido por ${CORES[amarelo]}Matheus Seman${CORES[none]}."                                              
    #--------------------------------------------------------------------------------------------------------------------#
} # Funçao para informações sobre a versao do script

function _ajudaScript_() {
    #--------------------------------------------------------------------------------------------------------------------#
    echo "
    Uso: $SCRIPT [OPÇÃO...] 
    GNU "$SCRIPT" foi desenvolvido para análise de logins mal-sucedidos em serviços...

    Exemplos:

        Opções de argumento:

            --help | -help | help | -h                       Fornece uma lista de ajuda;

            --version | -version | version | -v              Exibe Informações de versionamento e licença do script;

            --ssh | -ssh | ssh                               Exibe a quantidade de tentativas falhas de login no serviço SSH;

            --zimbra | -zimbra | zimbra                      Exibe a quantidade de tentativas falhas de login no serviço Zimbra;

            --log | -log | log | -l                          Exibe o log com informações das falhas de autenticação;
                                                                Exemplos:
                                                                 /usr/local/bin/$SCRIPT --log ssh
                                                                 /usr/local/bin/$SCRIPT --log zimbra  
                                                      
            bypass                                           Opção para execução via crontab;
                                                                Exemplos:
                                                                 /usr/local/bin/$SCRIPT --ssh bypass
                                                                 /usr/local/bin/$SCRIPT --zimbra bypass

    Enviar report de bugs para < mateusseman@gmail.com >.
    "
    #--------------------------------------------------------------------------------------------------------------------#
} # Função para lista de ajuda do script

function _authZimbra_(){
    #--------------------------------------------------------------------------------------------------------------------#
    echo -e "[ ${CORES[amarelo]}!${CORES[none]} ] ~ Iniciando verificações... [Aguarde]"

    # Variáveis internas de controle #-----------------------------------------------------------------------------------#
    local totalFalhasAuth=$(grep "auth failure" ${LOGS[zimbra]} | wc -l) # Faz a contagem de ocorrencias de falhas de autenticação
    local logZimbraAuth="/var/log/zimbraAuth.log" # Log para armazenamento dos dados resultantes da execução da função
    local linhaAnterior="" # Variável de comparação

    if [[ -e ${LOGS[script]} ]] ; then
        rm -f ${LOGS[script]} # Exclui o log para criação posterior
    fi

    #--------------------------------------------------------------------------------------------------------------------#
    # Leitura de log de autenticação #-----------------------------------------------------------------------------------#
    if [[ $ARGUMENTO = "bypass" ]] ; then # Caso argumento bypass seja passado (em caso de execuções via crontab)
        echo -e "Mês Dia Horário: Origem > Conta de e-mail\n" > $logZimbraAuth # Salva as informações no log
    else
        echo ; echo -e "Mês Dia Horário: Origem > Conta de e-mail\n" | tee $logZimbraAuth # Exibe as informações e as salva simultaneamente no log
    fi
    
    while IFS= read -r linhaLog; do # Percorre todas as linhas do arquivo de log
        if [[ "$linhaAnterior" == *"auth failure"* && "$linhaAnterior" == *"user="* ]]; then
            local caixaPostal=$(echo $linhaAnterior | awk '{print $9}' | sed -n 's/.*\[user=\([^]]*\)\].*/\1/p') # Obtem o usuário no qual houve falha de autenticação
            local diaAuth=$(echo $linhaAnterior | awk '{print $2}') # Obtem o dia da falha de autenticação
            local mesAuth=$(echo $linhaAnterior | awk '{print $1}') # Obtem o mes da falha de autenticação
            local horarioAuth=$(echo $linhaAnterior | awk '{print $3}') # Obtem o horário da falha de autenticação
            local origemAuth=$(echo $linhaLog | sed -n 's/.*\[\([0-9.]\+\)\].*/\1/p') # Obtem o endereço IP público origem da falha de autenticação

            if [[ $ARGUMENTO = "bypass" ]] ; then # Caso argumento bypass seja passado (em caso de execuções via crontab)
                echo -e "$mesAuth $diaAuth $horarioAuth: $origemAuth > $caixaPostal" >> $logZimbraAuth # Salva as informações no log
            else
                echo -e "$mesAuth $diaAuth $horarioAuth: $origemAuth > $caixaPostal" | tee -a $logZimbraAuth # Exibe as informações e as salva simultaneamente no log
            fi
        fi
        linhaAnterior="$linhaLog"
    done < "${LOGS[zimbra]}"

    #--------------------------------------------------------------------------------------------------------------------#
    # Output #-----------------------------------------------------------------------------------------------------------#
    echo -e "\nTotal: $totalFalhasAuth\n" # Exibe na stdout a quantidade total de falhas de autenticação Zimbra
    echo -e "Dados de falha de autenticação salvas em ${CORES[amarelo]}$logZimbraAuth${CORES[none]}"
    echo -e "Digite ${CORES[amarelo]}$SCRIPT --log zimbra${CORES[none]} para visualizá-lo"
    echo -e "zimbra: $totalFalhasAuth" > ${LOGS[script]} # Adiciona a contagem de ocorrencias no log

    #--------------------------------------------------------------------------------------------------------------------#
} # Função para visualização das falhas de autenticação Zimbra

function _authSSH_() {
    #--------------------------------------------------------------------------------------------------------------------#
    echo -e "[ ${CORES[amarelo]}!${CORES[none]} ] ~ Iniciando verificações... [Aguarde]"

    # Variáveis internas de controle #-----------------------------------------------------------------------------------#
    local totalFalhasAuth=$(grep "Failed password for" ${LOGS[ssh]} | wc -l) # Faz a contagem de ocorrencias de falhas de autenticação
    local logSSHAuth="/var/log/SSHAuth.log" # Log para armazenamento das informações obtidas no script

    if [[ -e ${LOGS[script]} ]] ; then
        rm -f ${LOGS[script]} # Exclui o log para criação posterior
    fi

    #--------------------------------------------------------------------------------------------------------------------#
    # Leitura de log de autenticação #-----------------------------------------------------------------------------------#
    if [[ $ARGUMENTO = "bypass" ]] ; then # Caso argumento bypass seja passado (em caso de execuções via crontab)
        echo -e "Mês Dia Horário: Origem > Usuário\n" > $logSSHAuth # Salva as informações no log
    else
        echo ; echo -e "Mês Dia Horário: Origem > Usuário\n" | tee $logSSHAuth # Exibe as informações e as salva simultaneamente no log
    fi
    while IFS= read -r linhaLog; do # Percorre todas as linhas do arquivo de log
        if [[ "$linhaLog" == *"Failed password for"* ]]; then # Verifica se a linha contém a expressão "failed auth"
            # Tratamento de dados de data #------------------------------------------------------------------------------#
            local mesAuth=$(echo $linhaLog | awk '{print $1}') # Obtem o mes da falha de autenticação
            local diaAuth=$(echo $linhaLog | awk '{print $2}') # Obtem o dia da falha de autenticação
            local horarioAuth=$(echo $linhaLog | awk '{print $3}') # Obtem o horário da falha de autenticação
            
            # Tratamento de dados de origem #----------------------------------------------------------------------------#
            local origemAuth=$(echo $linhaLog | awk '{print $11}') # Obtem o endereço IP origem da tentativa de autenticação
            if [[ ! $origemAuth =~ $IP_REGEX ]] ; then # Verifica se o endereço IP corresponde à expressão regular
                local usuarioAuth=$(echo $linhaLog | awk '{print $11}') # Obtem o usuário no qual houve falha de autenticação
                local origemAuth=$(echo $linhaLog | awk '{print $13}') # Obtem o endereço IP origem da tentativa de autenticação
            else
                local usuarioAuth=$(echo $linhaLog | awk '{print $9}') # Obtem o usuário no qual houve falha de autenticação
            fi

            # Tratamento de tipo de execução #---------------------------------------------------------------------------#
            if [[ $ARGUMENTO = "bypass" ]] ; then # Caso argumento bypass seja passado (em caso de execuções via crontab)
                echo -e "$mesAuth $diaAuth $horarioAuth: $origemAuth > $usuarioAuth" >> $logSSHAuth # Salva as informações no log
            else
                echo -e "$mesAuth $diaAuth $horarioAuth: $origemAuth > $usuarioAuth" | tee -a $logSSHAuth # Exibe as informações e as salva simultaneamente no log
            fi
        fi
    done < "${LOGS[ssh]}"

    #--------------------------------------------------------------------------------------------------------------------#
    # Output #-----------------------------------------------------------------------------------------------------------#
    echo -e "\nTotal: $totalFalhasAuth\n" # Exibe na stdout a quantidade total de falhas de autenticação SSH
    echo -e "Dados de falha de autenticação salvas em ${CORES[amarelo]}$logSSHAuth${CORES[none]}"
    echo -e "Digite ${CORES[amarelo]}$SCRIPT --log ssh${CORES[none]} para visualizá-lo."
    echo -e "ssh: $totalFalhasAuth" > ${LOGS[script]} # Adiciona a contagem de ocorrencias no log

    #--------------------------------------------------------------------------------------------------------------------#

} # Função para visualização das falhas de autenticação SSH

function _exibeLog_() {
    #--------------------------------------------------------------------------------------------------------------------#
    # Variáveis internas de controle #-----------------------------------------------------------------------------------#
    local logAuthSSH="/var/log/SSHAuth.log" # Log para armazenamento das informações obtidas no script
    local logAuthZimbra="/var/log/zimbraAuth.log" # Log para armazenamento das informações obtidas no script

    #--------------------------------------------------------------------------------------------------------------------#
    # Verificação de tipo de log #---------------------------------------------------------------------------------------#
    if [[ $ARGUMENTO = "ssh" ]] ; then # Caso argumento passado seja para o ssh
        less $logAuthSSH
    elif [[ $ARGUMENTO = "zimbra" ]] ; then # Caso argumento passado seja para o zimbra
        less $logAuthZimbra
    fi
    #--------------------------------------------------------------------------------------------------------------------#

} # Função para visualização de log do script

#------------------------------------------------------------------------------------------------------------------------#
if [ "$(id -u)" != "0" ] ; then # Caso o usuário não seja administrador
    echo -e "[ ${CORES[vermelho]}✖${CORES[none]} ] ~ Operação permitida apenas para administradores."
else
    #----------------------------------------------------------------------------------------------------------------------------#
    # Verifica as dependências do script #---------------------------------------------------------------------------------------#
    instalacaoValidacao="false" # Variável de controle
    for dependencia in "${!DEPENDENCIAS[@]}" ; do # Percorre todo o array com as dependencias do script
        if [[ ! -e "${DEPENDENCIAS[$dependencia]}" ]] ; then # Caso a dependencia não esteja instalada
            if [[ $instalacaoValidacao = "false" ]] ; then
                read -p "Para execução do script, os pacotes tee e less devem ser adicionados. Deseja prosseguir? [S/N]:" instalacaoForm
                case $instalacaoForm in 
                    "não" | "nao" | "Não" | "Nao" | "NÃO" | "NAO" | "n" | "N") 
                        echo -e "${CORES[branco]}[ ${CORES[amarelo]}!${CORES[none]} ${CORES[branco]}]${CORES[none]} ~ Cancelando instalação..." ; sleep 1
                        exit 0
                    ;;
                    "sim" | "Sim" | "SIM" | "s" | "S") 
                        instalacaoValidacao="true"
                    ;;
                    *)
                        echo -e "[ ${CORES[vermelho]}✖${CORES[none]} ] ~ Opção inválida..." ; sleep 1
                    ;;
                esac                
            fi
            if [[ $instalacaoValidacao = "true" ]] ; then # Caso o usuário permita a instalação das dependências
                echo -e "${CORES[branco]}[ ${CORES[amarelo]}!${CORES[none]} ${CORES[branco]}]${CORES[none]} ~ Baixando/instalando pacote $dependencia..."
                apt-get install $dependencia -y # Faz a instalação das dependencias
                if [[ $? = 1 ]] ; then # Caso ocorra alguma falha na instalação
                    echo -e "[ ${CORES[vermelho]}✖${CORES[none]} ] ~ Falha na instalação dos pacotes, abortando..." ; sleep 1
                fi
            fi
        fi
    done

    #----------------------------------------------------------------------------------------------------------------------------#
    case "$1" in
        "--help" | "-help" | "help" | "-h") # Opções para lista de ajuda
            _ajudaScript_
        ;;
        "--version" | "-version" | "version" | "-v") # Opções para visualização de versionamento do script
            _versaoScript_
        ;;
        "--ssh" | "-ssh" | "ssh") # Opção para verificação de falhas de autenticação SSH
            _authSSH_
        ;;
        "--zimbra" | "-zimbra" | "zimbra") # Opção para verificação de falhas de autenticação Zimbra
            _authZimbra_
        ;;
        "--log" | "-log" | "log" | "-l") # Opções para visualização dos logs do script
            _exibeLog_
        ;;
        *) # Para outras opções ou vazia
            echo -e "[ ${CORES[vermelho]}✖${CORES[none]} ] ~ Opção inválida, digite ${CORES[amarelo]}$SCRIPT --help${CORES[none]} para obter uma lista de ajuda."
        ;;
    esac
fi
#------------------------------------------------------------------------------------------------------------------------#