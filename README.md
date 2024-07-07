# serverLoginMonitoring.sh

## 📑 Descrição
Este script foi desenvolvido para análise de falhas de autenticação em serviços. Inicialmente, foi criado para funcionar em sistemas das família Debian e RedHat.

![example](https://github.com/matheusseman/ServerLoginMonitoring/assets/119596051/e0ebdbec-3f40-46a6-a45c-576b16b7650c)

O script é compatível, em sua versão atual, com serviços SSH e Zimbra, permitindo assim visualizar de forma facilitada as tentativas de acesso mal-sucedidas nestes serviços, no seguinte formato:
- **SSH:** `Mês Dia Horário: Origem > Usuário`
- **Zimbra:** `Mês Dia Horário: Origem > Caixa Postal`

## 💡 Funcionalidades
- Verificação de falhas de autenticação em serviços SSH e Zimbra.
- Visualização e armazenamento de logs de falhas de autenticação.
- Compatível com execução via crontab.
- [Integração com monitoramento Zabbix](https://github.com/matheusseman/ServerLoginMonitoring/tree/main/Zabbix).

## 🔧 Configuração
Para que o script tenha seu funcionamento correto, devem ser respeitados alguns critérios:
- O script deve ser alocado no diretório `/usr/local/bin`.
- Deve receber permissão de execução com `chmod a+x /usr/local/bin/serverLoginMonitoring.sh`.

## 🚩 Dependências
O script depende dos seguintes pacotes:
- `tee`
- `less`

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

### Exemplos de Uso
1. Para visualizar tentativas falhas de login no serviço SSH:
   
    ```bash
    ./serverLoginMonitoring.sh --ssh
    ```
    
3. Para visualizar tentativas falhas de login no serviço Zimbra:
   
    ```bash
    ./serverLoginMonitoring.sh --zimbra
    ```
    
5. Para exibir o log de falhas de autenticação SSH:
   
    ```bash
    ./serverLoginMonitoring.sh --log ssh
    ```
    
7. Para executação via crontab (SSH):
   
    ```bash
    ./serverLoginMonitoring.sh --ssh bypass
    ```

## 🚀 Integração com Zabbix
O script possuí [integração com monitoramento Zabbix](https://github.com/matheusseman/ServerLoginMonitoring/tree/main/Zabbix), podendo gerar alertas e widgets para exibição das informações de falhas de autenticação.


