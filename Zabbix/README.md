# linuxLoginMonitoring.yaml

## 📝 Descrição
Template para importação na central Zabbix com o propósito de visualizar informações de falhas de autenticação SSH ou Zimbra em servidores Linux.

## 🚩 Atenção
Antes de iniciar os procedimentos, garanta que já executou a configuração do script [serverLoginMonitoring.sh](https://github.com/matheusseman/ServerLoginMonitoring) no servidor Linux.

## 📦 Conteúdo
### Itens
- Log falhas de autenticação SSH
- Log falhas de autenticação Zimbra
- Falhas de autenticação SSH - Total
- Falhas de autenticação Zimbra - Total

### Triggers
- SSH: Falha de autenticação em {HOST.NAME}
- Zimbra: Falha de autenticação em {HOST.NAME}
 
## 🔧 Configuração
Para realizar a integração do script com a central Zabbix, siga os passos abaixo:
- Na central Zabbix, execute a importação do template `linuxLoginMonitoring.yaml`.
- Na central Zabbix, adicione o(s) host(s) no Template `Linux Login Monitoring`.
- No(s) servidor(es) Linux, adicione as seguintes linhas no crontab do usuário root (faça as modificações necessárias):
  - SSH
    
      ```bash
        # Script para monitoramento de tentativas falhas de login SSH
        # Á cada 2 minutos
        # Todos os dias
        */2 *   * * *   /usr/local/bin/login-monitoring.sh --ssh bypass
  
  - Zimbra
    
      ```bash
        # Script para monitoramento de tentativas falhas de login SSH
        # Á cada 5 minutos
        # Todos os dias
        */5 *   * * *   /usr/local/bin/login-monitoring.sh --zimbra bypass

- No(s) servidor(es) Linux, reinicie os agentes de monitoramento Zabbix.

    ```bash
    systemctl restart zabbix-agent

### 🔔 Alertas
Os alertas serão configurados automaticamente em todos os hosts que forem adicionados ao Template `Linux Login Monitoring`.

![image](https://github.com/matheusseman/ServerLoginMonitoring/assets/119596051/7a0a996f-6b47-44c2-98cc-340015247a9e)

Desta maneira, basta aguardar a coleta dos dados do host (garanta que a execução do script foi devidamente configurada no servidor Linux).


### 📈 Dashboards
Para visualizar detalhes das falhas de autenticação no dashboard Zabbix, execute os passos abaixo:
- Na central Zabbix, acesse o dashboard ao qual deseja adicionar as informações.
- No dashboard, adicione um widget do tipo 'Plain Text".
 - Selecione o item `Log falhas de autenticação SSH` ou `Log falhas de autenticação Zimbra`, dependendo do seu interesse.

   ![image](https://github.com/matheusseman/ServerLoginMonitoring/assets/119596051/d29a77c2-c9ca-44b5-8004-075e0fca8c4c)









