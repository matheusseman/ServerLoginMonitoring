# Descrição
Template para importação na central Zabbix com o propósito de visualizar informações de falhas de autenticação SSH ou Zimbra em servidores Linux.


# Atenção
Antes de iniciar os procedimentos, garanta que já executou a configuração do script serverLoginMonitoring, disponível em https://github.com/matheusseman/ServerLoginMonitoring.

# Configuração
Para realizar a integração do script com a central Zabbix, siga os passos abaixo:
- Na central Zabbix, execute a importação do template linuxLoginMonitoring.yaml.
- Na central Zabbix, adicione os hosts aos quais efetuou a configuração do script serverLoginMonitoring no Template 'Linux Login Monitoring'.
- Adicione as seguintes linhas no crontab do servidor Linux (faça as modificações necessárias):
    '# # Script para monitoramento de tentativas falhas de login SSH
    # Á cada 2 minutos
    # Todos os dias
    */2 *   * * *   /usr/local/bin/login-monitoring.sh --ssh bypass'

- Reinicie o agente de monitoramento Zabbix nos hosts.
    'bash: systemctl restart zabbix-agent'

# Dashboards
Para visualizar detalhes das falhas de autenticação no dashboard Zabbix, execute os passos abaixo:
- Na central Zabbix, acesse o dashboard ao qual deseja adicionar as informações
- No dashboard, adicione um widget do tipo 'Plain Text"
 - Selecione o item 'Log falhas de autenticação SSH' para visualizar dados de falha de autenticação SSH
 - Selecione o item 'Log falhas de autenticação Zimbra' para visualizar dados de falha de autenticação Zimbra


# Alertas
Os alertas serão configurados automaticamente em todos os hosts que forem adicionados ao Template 'Linux Login Monitoring'.

Desta maneira, basta aguardar a coleta dos dados do host (garanta que a execução do script foi devidamente configurada no servidor Linux).









