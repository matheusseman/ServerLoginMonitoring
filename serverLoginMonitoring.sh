#!/bin/bash
##########################################################################################################################
#------------------------------------------------------------------------------------------------------------------------#
#--------------------------------------------------- INFORMAÇÕES---------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------------------#
# Arquivo ~~~~ serverLoginMonitoring.sh
# Versão ~~~~~ v1.3
# Descrição ~~ Script para análise de logins mal-sucedidos em serviços
# Autor ~~~~~~ Matheus Seman < mateusseman@gmail.com >
#------------------------------------------------------------------------------------------------------------------------#
##########################################################################################################################
#------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------- VARIÁVEIS ---------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------------------#
VERSAO=v1.3 # Versionamento do script
SCRIPT=${0##*/} # Retorna o nome do script
SCRIPT_DIR=/usr/local/bin # Local de armazenamento do script
IP_REGEX="^([0-9]{1,3}\.){3}[0-9]{1,3}$" # Formato do IP X.X.X.X
IP_PUBLICO=$(curl -s ifconfig.me 2>/dev/null) # Endereço público do host
#------------------------------------------------------------------------------------------------------------------------#
##########################################################################################################################
#------------------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------ ARRAYS ----------------------------------------------------------#
# Arrays dinâmicos (Podem ser alterados para se adequar ao seu servidor) #-----------------------------------------------#
declare -a ORIGEMCONF=("$IP_PUBLICO" "127.0.0.1") # Array de armazenamento dos ips públicos confiáveis (não receberão banimento). Formato em "x.x.x.x" "y.y.y.y" "z.z.z.z"
declare -A POLITICASBAN=(
    [zimbra]="zimbra-smtp"
    [ssh]="sshd"
) # Políticas configuradas no arquivo jail.local 
declare -A LOGS=(
    [script]="/var/log/serverLoginMonitoring.log"
    [ssh]="/var/log/auth.log"
    [zimbra]="/var/log/zimbra.log"
) # Logs utilizados no script

# Arrays estáticos #-----------------------------------------------------------------------------------------------------#
declare -a TRIAGEMBAN # Endereços barrados pela triagem e serão banidos
declare -A ARGUMENTOS=(
    [opcao]=""
    [bypass]="false"
    [ban]="false"
    [recorrencia]=3
) # Argumentos passados como parametro
declare -A CORES=( 
    [none]="\033[m"
    [vermelho]="\033[1;31m"
    [verde]="\033[1;32m"
    [amarelo]="\033[1;33m"
) # Cores para melhor visualizaçao dos dados
declare -A DEPENDENCIAS=(
    [coreutils]="/usr/bin/tee"
    [less]="/usr/bin/less"
    [fail2ban]="/usr/bin/fail2ban-server"
) # Dependencias necessárias para execução do script
declare -A ENDERECOSAUTH # Endereços ip públicos origem do acesso

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

            --help | -help | help | -h              Fornece uma lista de ajuda;

            --version | -version | version | -v     Exibe Informações de versionamento e licença do script;

            --ssh | -ssh | ssh                      Exibe a quantidade de tentativas falhas de login no serviço SSH;

            --zimbra | -zimbra | zimbra             Exibe a quantidade de tentativas falhas de login no serviço Zimbra;

            --log | -log | log | -l                 Exibe o log com informações das falhas de autenticação;
                                                        Exemplos:
                                                            /usr/local/bin/$SCRIPT --log ssh
                                                            /usr/local/bin/$SCRIPT --log zimbra  
                                                        
            bypass                                  Opção para execução via crontab;
                                                        Exemplos:
                                                            /usr/local/bin/$SCRIPT --ssh bypass
                                                            /usr/local/bin/$SCRIPT --zimbra bypass

            ban                                     Opção para triagem dos endereços origem, executando o banimento em 
                                                    casos de X recorrências. Caso não informado, padrão será 3;
                                                        Exemplos:
                                                            /usr/local/bin/$SCRIPT --ssh ban 2
                                                            /usr/local/bin/$SCRIPT --zimbra bypass ban 6 

    Enviar report de bugs para < mateusseman@gmail.com >.
    "
    #--------------------------------------------------------------------------------------------------------------------#
} # Função para lista de ajuda do script

function _verifInstalacao_() {
    #--------------------------------------------------------------------------------------------------------------------#
    # Variáveis internas de controle #-----------------------------------------------------------------------------------#
    local instalacaoValidacao="false" # Variável de controle

    #--------------------------------------------------------------------------------------------------------------------#
    # Validação de dependências #----------------------------------------------------------------------------------------#    
    for dependencia in "${!DEPENDENCIAS[@]}" ; do # Percorre o array com as dependências do script
        if [[ ! -e "${DEPENDENCIAS[$dependencia]}" ]] ; then # Caso a dependencia não esteja instalada
            if [[ $instalacaoValidacao = "false" ]] ; then
                while true ; do
                    read -p "Para execução do script, os pacotes coreutils, less devem ser adicionados. Deseja prosseguir? [S/N]: " instalacaoForm
                    case $instalacaoForm in 
                        "não" | "nao" | "Não" | "Nao" | "NÃO" | "NAO" | "n" | "N") 
                            echo -e "${CORES[branco]}[ ${CORES[amarelo]}!${CORES[none]} ${CORES[branco]}]${CORES[none]} ~ Cancelando instalação..." ; sleep 1 ; exit 0                        
                        ;;
                        "sim" | "Sim" | "SIM" | "s" | "S") 
                            instalacaoValidacao="true"
                            break
                        ;;
                        *)
                            echo -e "[ ${CORES[vermelho]}✖${CORES[none]} ] ~ Opção inválida..." ; sleep 1
                        ;;
                    esac
                done
            fi     

            #------------------------------------------------------------------------------------------------------------#
            # Instalação da dependência #--------------------------------------------------------------------------------#
            if [[ $instalacaoValidacao = "true" ]] ; then
                if [ "$(id -u)" != "0" ] ; then # Caso o usuário não seja administrador
                    echo -e "[ ${CORES[vermelho]}✖${CORES[none]} ] ~ Operação permitida apenas para administradores, abortando..." ; exit 0
                else
                    echo -e "\n${CORES[branco]}[ ${CORES[amarelo]}!${CORES[none]} ${CORES[branco]}]${CORES[none]} ~ Baixando/instalando pacote $dependencia..." ; sleep 1

                    # Em distribuições de família Debian #---------------------------------------------------------------#
                    if [[ -e "/usr/bin/apt" ]] ; then
                        apt-get install $dependencia -y ; echo # Faz a instalação das dependencias
                        if [[ $? = 1 ]] ; then
                            echo -e "[ ${CORES[vermelho]}✖${CORES[none]} ] ~ Falha na instalação dos pacotes, abortando..." ; sleep 1 ; exit 0                
                        fi

                    # Em distribuições de família RedHat #---------------------------------------------------------------#
                    elif [[ -e "/usr/bin/yum" ]] ; then
                        yum install $dependencia -y ; echo # Faz a instalação das dependencias
                        if [[ $? = 1 ]] ; then
                            echo -e "[ ${CORES[vermelho]}✖${CORES[none]} ] ~ Falha na instalação dos pacotes, abortando..." ; sleep 1 ; exit 0                
                        fi
                    fi
                fi
            fi
        fi
    done

    # Finalização da instalação/configuração #---------------------------------------------------------------------------#
    if [[ $instalacaoValidacao = "true" ]] ; then
        echo -e "\n[ ${CORES[verde]}✓${CORES[none]} ] ~ Instalação finalizada!" ; exit 0
    fi
    #--------------------------------------------------------------------------------------------------------------------#
} # Função para instalação personalizada do script

function _verifArgumento_() {
    #--------------------------------------------------------------------------------------------------------------------#
    # Variáveis internas de controle #-----------------------------------------------------------------------------------#
    local argumentos="$@"
    local numeroRegexp="^[0-9]+$"

    # Triagem dos argumentos passados #----------------------------------------------------------------------------------#
    for argumento in $argumentos ; do
        if [[ $argumento = "bypass" ]] ; then # Para execuções via crontab
            ARGUMENTOS[bypass]="true"
        elif [[ $argumento = "ban" ]] ; then # Para habilitar o banimento automático
            ARGUMENTOS[ban]="true"
        elif [[ $argumento =~ $numeroRegexp ]] ; then
            ARGUMENTOS[recorrencia]=$argumento
        else
            ARGUMENTOS[opcao]="$argumento"
        fi
    done

    #--------------------------------------------------------------------------------------------------------------------#

} # Função para verificação dos argumentos

function _verifPolitica_() {
    #--------------------------------------------------------------------------------------------------------------------#
    # Variáveis internas de controle #-----------------------------------------------------------------------------------#
    local politicasExistentes=$(fail2ban-client status | grep "Jail list:" | awk -F ':' '{gsub(/^[ \t]+|,/, "", $2); print $2}') # Exibe as politicas existentes no arquivo de configuração jail.local
    declare -a politicasInvalidas

    
    for politicaFail2ban in ${!POLITICASBAN[@]} ; do # Percorre o array com as políticas Fail2ban definidas
        local politicaValidacao="false" # Variável de controle

        for validPolitica in $politicasExistentes ; do # Verifica a existência/execução destas políticas
            if [[ "${POLITICASBAN[$politicaFail2ban]}" = $validPolitica ]] ; then # Caso existe e esteja ativa
                politicaValidacao="true" ; break  
            fi
        done
        
        if [[ $politicaValidacao = "false" ]] ; then # Caso não exista e/ou não esteja em execução
            echo -e "[ ${CORES[vermelho]}✖${CORES[none]} ] ~ Politicas Fail2ban inválidas. Verifique o nome correto das políticas e se estas estão habilitadas."
            echo -e "Para mais informações, acesse: https://github.com/matheusseman/ServerLoginMonitoring" ; exit 0
        fi
    done    

} # Função para verificação das políticas Fail2ban

function _authZimbra_(){
    #--------------------------------------------------------------------------------------------------------------------#
    # Verificação de disponibilidade de serviço #------------------------------------------------------------------------#
    if [[ ! -e "${LOGS[zimbra]}" ]] ; then
        echo -e "[ ${CORES[vermelho]}✖${CORES[none]} ] ~ Log de serviço SSH não localizado. Verifique a documentação Github para mais informações: https://github.com/matheusseman/ServerLoginMonitoring" 
        exit 0
    fi

    # Variáveis internas de controle #-----------------------------------------------------------------------------------#
    local totalFalhasAuth=$(grep "auth failure" ${LOGS[zimbra]} | wc -l) # Faz a contagem de ocorrencias de falhas de autenticação
    local logZimbraAuth="/var/log/zimbraAuth.log" # Log para armazenamento dos dados resultantes da execução da função
    local linhaAnterior="" # Variável de comparação
    local politicaZimbra="${POLITICASBAN[zimbra]}"

    if [[ -e ${LOGS[script]} ]] ; then
        rm -f ${LOGS[script]} # Exclui o log para criação posterior
    fi

    echo -n > $logZimbraAuth # Faz a limpeza do arquivo de log com falhas de autenticação

    #--------------------------------------------------------------------------------------------------------------------#
    # Leitura de log de autenticação #-----------------------------------------------------------------------------------#
    if [[ ! "${ARGUMENTOS[bypass]}" = "true" ]] ; then # Caso argumento bypass seja passado (em caso de execuções via crontab)
        echo -e "[ ${CORES[amarelo]}!${CORES[none]} ] ~ Iniciando verificações... [Aguarde]" ; sleep 1
        echo -e "Mês Dia Horário: Origem > Conta de e-mail\n" # Exibe cabeçalho de saída
    fi
    
    while IFS= read -r linhaLog; do # Percorre todas as linhas do arquivo de log
        if [[ "$linhaAnterior" == *"auth failure"* && "$linhaAnterior" == *"user="* ]]; then
            local caixaPostal=$(echo $linhaAnterior | awk '{print $9}' | sed -n 's/.*\[user=\([^]]*\)\].*/\1/p') # Obtem o usuário no qual houve falha de autenticação
            local diaAuth=$(echo $linhaAnterior | awk '{print $2}') # Obtem o dia da falha de autenticação
            local mesAuth=$(echo $linhaAnterior | awk '{print $1}') # Obtem o mes da falha de autenticação
            local horarioAuth=$(echo $linhaAnterior | awk '{print $3}') # Obtem o horário da falha de autenticação
            local origemAuth=$(echo $linhaLog | sed -n 's/.*\[\([0-9.]\+\)\].*/\1/p') # Obtem o endereço IP público origem da falha de autenticação

            # Tratamento de dados de origem #----------------------------------------------------------------------------#
            if [[ $origemAuth =~ $IP_REGEX ]] ; then # Verifica se o endereço IP corresponde à expressão regular
                ((ENDERECOSAUTH["$origemAuth"]++)) # Endereço será adicionado à fila da triagem 
                local origemAuth=$(echo $linhaLog | sed -n 's/.*\[\([0-9.]\+\)\].*/\1/p') # Obtem o endereço IP público origem da falha de autenticação
            else
                local origemAuth="Desconhecido" # 
            fi

            if [[ "${ARGUMENTOS[bypass]}" = "true" ]] ; then # Caso argumento bypass seja passado (em caso de execuções via crontab)
                echo -e "$mesAuth $diaAuth $horarioAuth: $origemAuth > $caixaPostal" >> $logZimbraAuth # Salva as informações no log
            else
                echo -e "$mesAuth $diaAuth $horarioAuth: $origemAuth > $caixaPostal" | tee -a $logZimbraAuth # Exibe as informações e as salva simultaneamente no log
            fi
        fi
        linhaAnterior="$linhaLog"
    done < "${LOGS[zimbra]}"

    # Triagem do acesso #------------------------------------------------------------------------------------------------#
    if [[ "${ARGUMENTOS[ban]}" = "true" ]] ; then # Caso argumento ban esteja presente
        if systemctl is-active --quiet fail2ban ; then # Verifica a existência do serviço fail2ban  
            _triagemAuth_  $politicaZimbra
        fi
    fi
    #--------------------------------------------------------------------------------------------------------------------#
    # Output #-----------------------------------------------------------------------------------------------------------#
    if [[ ! "${ARGUMENTOS[bypass]}" = "true" ]] ; then # Caso argumento bypass seja passado (em caso de execuções via crontab)
        local enderecosBanZimbra=$(fail2ban-client status $politicaZimbra | grep "Banned IP list" | awk -F ':' '{gsub(/^[ \t]+/, "", $2); print $2}')
        
        echo -e "\nTotal: $totalFalhasAuth" # Exibe na stdout a quantidade total de falhas de autenticação SSH
        echo -e "Banidos: $enderecosBanZimbra" # Exibe os endereços em banimento no fail2ban para a política Zimbra
        echo -e "\nDados de falha de autenticação salvas em ${CORES[amarelo]}$logZimbraAuth${CORES[none]}"
        echo -e "Digite ${CORES[amarelo]}$SCRIPT --log zimbra${CORES[none]} para visualizá-lo"
    fi
    echo -e "zimbra: $totalFalhasAuth" > ${LOGS[script]} # Adiciona a contagem de ocorrencias no log

    #--------------------------------------------------------------------------------------------------------------------#
} # Função para visualização das falhas de autenticação Zimbra

function _authSSH_() {  
    #--------------------------------------------------------------------------------------------------------------------#
    # Verificação de disponibilidade de serviço #------------------------------------------------------------------------#
    echo -e "[ ${CORES[amarelo]}!${CORES[none]} ] ~ Iniciando verificações... [Aguarde]" ; sleep 1
    if [[ ! -e "${LOGS[ssh]}" ]] ; then
        echo -e "[ ${CORES[vermelho]}✖${CORES[none]} ] ~ Log de serviço SSH não localizado. Verifique a documentação Github para mais informações: https://github.com/matheusseman/ServerLoginMonitoring" 
        exit 0
    fi

    # Variáveis internas de controle #-----------------------------------------------------------------------------------#
    local totalFalhasAuth=$(grep "Failed password for" ${LOGS[ssh]} | wc -l) # Faz a contagem de ocorrencias de falhas de autenticação
    local logSSHAuth="/var/log/SSHAuth.log" # Log para armazenamento das informações obtidas no script
    local politicaSSH="${POLITICASBAN[ssh]}"
    
    if [[ -e ${LOGS[script]} ]] ; then
        rm -f ${LOGS[script]} # Exclui o log para criação posterior
    fi

    echo -n > $logSSHAuth # Faz a limpeza do arquivo de log com falhas de autenticação

    #--------------------------------------------------------------------------------------------------------------------#
    # Leitura de log de autenticação #-----------------------------------------------------------------------------------#
    if [[ ! "${ARGUMENTOS[bypass]}" = "true" ]] ; then # Caso argumento bypass seja passado (em caso de execuções via crontab)
        echo -e "Mês Dia Horário: Origem > Usuário\n" # Exibe as informações e as salva simultaneamente no log
    fi

    while IFS= read -r linhaLog; do # Percorre todas as linhas do arquivo de log
        if [[ "$linhaLog" == *"Failed password for"* ]]; then # Verifica se a linha contém a expressão "Failed password for"
            # Tratamento de dados de data #------------------------------------------------------------------------------#
            local mesAuth=$(echo $linhaLog | awk '{print $1}') # Obtem o mes da falha de autenticação
            local diaAuth=$(echo $linhaLog | awk '{print $2}') # Obtem o dia da falha de autenticação
            local horarioAuth=$(echo $linhaLog | awk '{print $3}') # Obtem o horário da falha de autenticação
            
            # Tratamento de dados de origem #----------------------------------------------------------------------------#
            local origemAuth=$(echo $linhaLog | awk '{print $11}') # Obtem o endereço IP origem da tentativa de autenticação
            if [[ ! $origemAuth =~ $IP_REGEX ]] ; then # Verifica se o endereço IP corresponde à expressão regular
                local usuarioAuth=$(echo $linhaLog | awk '{print $11}') # Obtem o usuário no qual houve falha de autenticação
                local origemAuth=$(echo $linhaLog | awk '{print $13}') # Obtem o endereço IP origem da tentativa de autenticação
                ((ENDERECOSAUTH["$origemAuth"]++)) # Endereço será adicionado à fila da triagem 
            else
                local usuarioAuth=$(echo $linhaLog | awk '{print $9}') # Obtem o usuário no qual houve falha de autenticação
                ((ENDERECOSAUTH["$origemAuth"]++)) # Endereço será adicionado à fila da triagem 
            fi

            # Tratamento de tipo de execução #---------------------------------------------------------------------------#
            if [[ "${ARGUMENTOS[bypass]}" = "true" ]] ; then # Caso argumento bypass seja passado (em caso de execuções via crontab)
                echo -e "$mesAuth $diaAuth $horarioAuth: $origemAuth > $usuarioAuth" >> $logSSHAuth # Salva as informações no log
            else
                echo -e "$mesAuth $diaAuth $horarioAuth: $origemAuth > $usuarioAuth" | tee -a $logSSHAuth # Exibe as informações e as salva simultaneamente no log
            fi
        fi
    done < "${LOGS[ssh]}"

    # Triagem do acesso #------------------------------------------------------------------------------------------------#
    if [[ "${ARGUMENTOS[ban]}" = "true" ]] ; then # Caso argumento ban esteja presente
        if systemctl is-active --quiet fail2ban ; then # Verifica a existência do serviço fail2ban
            _triagemAuth_ $politicaSSH
        fi
    fi
    
    #--------------------------------------------------------------------------------------------------------------------#
    # Output #-----------------------------------------------------------------------------------------------------------#
    if [[ ! "${ARGUMENTOS[bypass]}" = "true" ]] ; then # Caso argumento bypass seja passado (em caso de execuções via crontab)
        local enderecosBanSSH=$(fail2ban-client status $politicaSSH | grep "Banned IP list" | awk -F ':' '{gsub(/^[ \t]+/, "", $2); print $2}')
        
        echo -e "\nTotal: $totalFalhasAuth" # Exibe na stdout a quantidade total de falhas de autenticação SSH
        echo -e "Banidos: $enderecosBanSSH" # Exibe os endereços em banimento no fail2ban para a política SSH
        echo -e "\nDados de falha de autenticação salvas em ${CORES[amarelo]}$logSSHAuth${CORES[none]}"
        echo -e "Digite ${CORES[amarelo]}$SCRIPT --log ssh${CORES[none]} para visualizá-lo."
    fi
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
    if [[ "${ARGUMENTOS[opcao]}" = "ssh" ]] ; then # Caso argumento passado seja para o ssh
        less $logAuthSSH
    elif [[ "${ARGUMENTOS[opcao]}" = "zimbra" ]] ; then # Caso argumento passado seja para o zimbra
        less $logAuthZimbra
    fi
    #--------------------------------------------------------------------------------------------------------------------#

} # Função para visualização de log do script

function _triagemAuth_() {
    #--------------------------------------------------------------------------------------------------------------------#
    # Variáveis internas de controle #-----------------------------------------------------------------------------------#
    local politicaTriagem=$1 # Politica de triagem configurada no fail2ban
    
    # Caso a politica Fail2ban esteja operacional #---------------------------------------------------------------------------------------#
    if [[ ! "${ARGUMENTOS[bypass]}" = "true" ]] ; then # Caso argumento bypass seja passado (em caso de execuções via crontab)
        echo -e "\n[ ${CORES[amarelo]}!${CORES[none]} ] ~ Iniciando triagem... [Aguarde]"
    fi

    # Triagem para banimento #---------------------------------------------------------------------------------------#
    for chaveControle in "${!ENDERECOSAUTH[@]}"; do # Percorre a variável contendo todos os endereços origem com falha de autenticação
        local ipBanidos=$(fail2ban-client status $politicaTriagem | grep "Banned IP list" | awk -F ':' '{print $2}') # Comando para visualização dos ips já banidos 
        local tentativasAuth="${ENDERECOSAUTH[$chaveControle]}" # Total de tentativas de falhas de autenticação do ip do atacante
        local enderecoAuth="$chaveControle" # Endereço origem do atacante
        local banIp="true" # Variável de controle

        # Verificação de ip já está banido #-------------------------------------------------------------------------#
        for ipBanido in $ipBanidos; do
            if [[ $enderecoAuth = $ipBanido ]] ; then
                banIp="false"
            fi
        done

        # Verificação se a origem é confiável #----------------------------------------------------------------------#
        for enderecoConf in "${!ORIGEMCONF[@]}" ; do         
            if [[ $enderecoAuth = $enderecoConf ]] ; then # Caso seja nenhum dos ips confiáveis
                banIp="false"
            fi
        done

        if [[ $tentativasAuth -lt "${ARGUMENTOS[recorrencia]}" ]] ; then # Caso não exista x ocorrências de falhas de autenticação do mesmo ip público
            banIp="false"
        fi

        if [[ $banIp = "true" ]] ; then 
            TRIAGEMBAN+=("$enderecoAuth") # Endereço será adicionado à fila de banimentos
        fi
    done

    #----------------------------------------------------------------------------------------------------------------#
    # Banimento #--------------------------------------------------------------------------------------------------------#
    for ipAtacante in ${!TRIAGEMBAN[@]} ; do
        if [[ ${TRIAGEMBAN[$ipAtacante]} =~ $IP_REGEX ]] ; then # Verifica se o endereço IP corresponde à expressão regular
            fail2ban-client set $politicaTriagem banip ${TRIAGEMBAN[$ipAtacante]} &>/dev/null # Faz o banimento via fail2ban
        fi
    done

} # Função para triagem de tentativas de acesso mal-sucedidas

#------------------------------------------------------------------------------------------------------------------------#
if [ "$(id -u)" != "0" ] ; then # Caso o usuário não seja administrador
    echo -e "[ ${CORES[vermelho]}✖${CORES[none]} ] ~ Operação permitida apenas para administradores."
else
    #----------------------------------------------------------------------------------------------------------------------------#
    # Validações iniciais #------------------------------------------------------------------------------------------------------#
    _verifInstalacao_ # Instalação de dependências
    _verifPolitica_ # Verificação de políticas fail2ban
    _verifArgumento_ "$@" # Validação de argumentos informados

    #----------------------------------------------------------------------------------------------------------------------------#
    case "${ARGUMENTOS[opcao]}" in
        "--help" | "-help" | "help" | "-h") # Opções para lista de ajuda
            _ajudaScript_
        ;;
        "--version" | "-version" | "version" | "-v") # Opções para visualização de versionamento do script
            _versaoScript_
        ;;
        "--ssh" | "-ssh" | "ssh") # Opção para verificação de falhas de autenticação SSH
            _authSSH_
        ;;
        "--zimbra" | "-zimbra" | "zimbra") # Opção para verificação de falhas de autenticação SSH
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
