# serverLoginMonitoring.sh

## 📑 Descrição
Este script foi desenvolvido para análise e tratamento de falhas de autenticação em serviços. Inicialmente, foi criado para funcionar em sistemas das família Debian e RedHat.

![image](https://github.com/user-attachments/assets/24bd5853-1d63-4adc-a916-126abeedc78e)

O script é compatível, em sua versão atual, com serviços SSH e Zimbra, permitindo assim visualizar de forma facilitada as tentativas de acesso mal-sucedidas nestes serviços, no seguinte formato:
- **SSH:** `Mês Dia Horário: Origem > Usuário`
- **Zimbra:** `Mês Dia Horário: Origem > Caixa Postal`

## 💡 Funcionalidades
- Verificação de falhas de autenticação em serviços SSH e Zimbra.
- Visualização e armazenamento de logs de falhas de autenticação.
- Banimento de acessos com recorrência de mesma origem.
- Compatível com execução via crontab.
- [Integração com monitoramento Zabbix](https://github.com/matheusseman/ServerLoginMonitoring/tree/main/Zabbix).

## 🔧 Configuração
Para que o script tenha seu funcionamento correto, devem ser respeitados alguns critérios:
- O script deve ser alocado no diretório `/usr/local/bin`.
- Deve receber permissão de execução com `chmod a+x /usr/local/bin/serverLoginMonitoring.sh`.
- Deve ser executado com privilégios administrativos.
- As políticas Fail2ban para SSH ou Zimbra já devem estar configuradas e ativas.

### ✏️ Personalização
Para o funcionamento correto do script, as seguintes personalizações devem ser executadas:
- Atualize o array `ORIGEMCONF` com todos os ips confiáveis aos quais não devem ser banidos pelo Fail2ban.
- Atualize o array `POLITICASBAN` com os nomes das políticas Fail2ban configuradas em seu servidor, para os serviços Zimbra e SSH.
- Atualize o array `LOGS` com o caminho absoluto dos logs, caso sejam diferentes.

## 🚩 Dependências
O script depende dos seguintes pacotes:
- `tee`
- `less`
- `fail2ban`

Se estas dependências não estiverem instaladas, o script solicitará a permissão para instalá-las automaticamente.

## 💻 Uso
O script oferece várias opções de argumento para facilitar seu uso:

### Opções de Argumento
- `--help | -help | help | -h`:
  Fornece uma lista de ajuda.
- `--version | -version | version | -v`:
  Exibe informações de versionamento e licença do script.
- `--ssh | -ssh | ssh`:
  Exibe informações sobre as tentativas falhas de login no serviço SSH.
- `--zimbra | -zimbra | zimbra`:
  Exibe informações sobre as tentativas falhas de login no serviço Zimbra.
- `--log | -log | log | -l`:
  Exibe o log com informações das falhas de autenticação.
  - `/usr/local/bin/serverLoginMonitoring.sh --log ssh`
  - `/usr/local/bin/serverLoginMonitoring.sh --log zimbra`

- `bypass`:
  Opção para execução via crontab.
  - `/usr/local/bin/serverLoginMonitoring.sh --ssh bypass`
  - `/usr/local/bin/serverLoginMonitoring.sh --zimbra bypass`

- `ban`:
  Opção para triagem dos endereços origem, executando o banimento em casos de X recorrências (padrão 3).
  - `/usr/local/bin/serverLoginMonitoring.sh --ssh ban 4`
  - `/usr/local/bin/serverLoginMonitoring.sh --zimbra bypass ban 2`

### Exemplos de Uso
1. Para visualizar tentativas falhas de login no serviço SSH:
   
    ```bash
    ./serverLoginMonitoring.sh --ssh
    ```
    
2. Para visualizar tentativas falhas de login no serviço Zimbra:
   
    ```bash
    ./serverLoginMonitoring.sh --zimbra
    ```
    
3. Para exibir o log de falhas de autenticação SSH:
   
    ```bash
    ./serverLoginMonitoring.sh --log ssh
    ```
    
4. Para executação via crontab (SSH):
   
    ```bash
    ./serverLoginMonitoring.sh --ssh bypass
    ```

4. Para efetuar o banimento de tentativas SSH com 6 recorrências:
   
    ```bash
    ./serverLoginMonitoring.sh --ssh bypass ban 6
    ```

## 🚀 Integração com Zabbix
O script possuí [integração com monitoramento Zabbix](https://github.com/matheusseman/ServerLoginMonitoring/tree/main/Zabbix), podendo gerar alertas e widgets para exibição das informações de falhas de autenticação.


