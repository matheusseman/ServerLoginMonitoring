# serverLoginMonitoring.sh

## Descrição
Este script foi desenvolvido para análise de falhas de autenticação em serviços. Inicialmente, foi criado para funcionar em sistemas da família Debian, sendo implementado, neste exemplo específico, em um servidor Ubuntu Server 22.04, com serviço de acesso remoto seguro (SSH) instalado.

![example](https://github.com/matheusseman/ServerLoginMonitoring/assets/119596051/e0ebdbec-3f40-46a6-a45c-576b16b7650c)

O script é compatível, em sua versão atual, com serviços SSH e Zimbra, permitindo assim visualizar de forma facilitada as tentativas de acesso mal-sucedidas nestes serviços, no seguinte formato:
- **SSH:** `Mês Dia Horário: Origem > Usuário`
- **Zimbra:** `Mês Dia Horário: Origem > Conta de e-mail`

## Configuração
O script deve ser alocado no diretório `/usr/local/bin`.

## Funcionalidades
- Verificação de falhas de autenticação em serviços SSH e Zimbra.
- Visualização e armazenamento de logs de falhas de autenticação.
- Compatível com execução via crontab.

## Dependências
O script depende dos seguintes pacotes:
- `tee`
- `less`

Se estas dependências não estiverem instaladas, o script solicitará a permissão para instalá-las automaticamente.

## Uso
O script oferece várias opções de argumento para facilitar seu uso:

### Opções de Argumento
- `--help | -help | help | -h`:
  Fornece uma lista de ajuda.
- `--version | -version | version | -v`:
  Exibe informações de versionamento e licença do script.
- `--ssh | -ssh | ssh`:
  Exibe a quantidade de tentativas falhas de login no serviço SSH.
- `--zimbra | -zimbra | zimbra`:
  Exibe a quantidade de tentativas falhas de login no serviço Zimbra.
- `--log | -log | log | -l`:
  Exibe o log com informações das falhas de autenticação.
  Exemplos:
  - `/usr/local/bin/serverLoginMonitoring.sh --log ssh`
  - `/usr/local/bin/serverLoginMonitoring.sh --log zimbra`
- `bypass`:
  Opção para execução via crontab.
  Exemplos:
  - `/usr/local/bin/serverLoginMonitoring.sh --ssh bypass`
  - `/usr/local/bin/serverLoginMonitoring.sh --zimbra bypass`

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
4. Para executar via crontab (SSH):
    ```bash
    ./serverLoginMonitoring.sh --ssh bypass
    ```

## Futuras Implementações
Está prevista a integração dos dados de saída do script com a central de monitoramento Zabbix. Isso permitirá a visualização dessas informações em dashboards, além de gerar alertas automáticos para administradores. Essa funcionalidade será detalhada em futuros repositórios no GitHub, proporcionando uma camada adicional de segurança e monitoramento proativo.

