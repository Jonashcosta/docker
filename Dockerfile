FROM debian:11.0
ENV TZ=America/Fortaleza
RUN apt-get update && apt install htop --yes && apt install systemctl --yes
RUN apt-get install bind9 dnsutils --yes && \  
apt-get install wget --yes && \
apt-get install -y tzdata && \
wget https://www.internic.net/domain/named.root -O /usr/share/dns/root.hints && \
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
 echo > /etc/bind/named.conf.options && \
echo '// ACL "autorizados" essa colocamos os IPs que são autorizados a fazer consultas recursivas neste servidor. \n \
  // Neste caso vou incluir os IPs que foram nos delegados bem como de localhost e todos IPs privados. \n \
  acl autorizados { \n \
          127.0.0.1; \n \
          ::1; \n \
          192.168.0.0/16; \n \
          172.16.0.0/12; \n \
          100.64.0.0/10; \n \
          10.0.0.0/8; \n \
          2001:db8::/32; \n \
          fd00::/8;  \n \
          fe80::/10;  \n \
          fc00::/8;    \n \     
          45.171.228.0/23; \n \
          2804:5a10::/32; \n \
  }; \n \
  options { \n \ 
      // O diretório de trabalho do servidor \n \ 
      // Quaisquer caminho não informado será tomado como padrão este diretório \n \ 
      directory "/var/cache/bind"; \n \    
      //Suporte a DNSSEC \n \
      dnssec-validation auto; \n \ 
      // Conforme RFC1035 \n \
      // https://www.ietf.org/rfc/rfc1035.txt \n \ 
      // Se o servidor deve responder negativamente (NXDOMAIN) para consultas de domínios que não existem. \n \ 
      auth-nxdomain no; \n \
      // Respondendo para IPv4 e IPv6 \n \ 
      // Porta 53 estará aberta para ambos v4 e v6 (pode ser informar apenas os IPs que ficarão ouvindo) \n \
      // ex listen-on { 127.0.0.1; 45.80.48.2; };  \n \
      // ex listen-on-v6 { ::1; 2804:f123:bebe:cafe::2; }; \n \
      // ou any para todos os IPs das interfaces (recomendado, pricipalmente em anycast) \n \
      listen-on { any; }; \n \
      listen-on-v6 { any; }; \n \
      // Serve como uma ferramenta de mitigação para o problema de ataques de amplificação de DNS \n \
      // No momento, a implementação de RRL (Response Rate Limiting)é recomendada apenas para servidores autoritativos \n \
      // Se seu servidor será apenas autoritativo descomente as linhas a baixo. (https://kb.isc.org/docs/aa-00994) \n \
      //rate-limit { \n \
      //    responses-per-second 15; \n \
      //    window 5; \n \
      //}; \n \
      // Informações adicionais em suas respostas DNS \n \
      // Melhora o desempenho do servidor, reduzindo os volumes de dados de saída. \n \
      // O padrão BIND é (no) não. \n \
      minimal-responses yes; \n \
      // Reduzir o tráfego da rede e aumentar o desempenho, o servidor armazena respostas negativas. \n \
      // é usado para definir um tempo máximo de retenção para essas respostas no servidor. (segundos) \n \
      // Determina por quanto tempo o servidor irá acreditar nas informações armazenadas em cache de  \n \
      // respostas negativas (NXDOMAIN) antes de buscar novamente informações. \n \
      max-ncache-ttl 300; \n \
      // Desativar recursão. Por padrão já é yes. \n \
      // recursion no; \n \
      // Especifica quais hosts estão autorizados a fazer consultas \n \
      // recursivas através deste servidor. \n \
      // Aqui que você vai informar os IPs da sua rede que você irá permitir consultar os DNS. \n \
      allow-recursion { autorizados; }; \n \
      // Endereço estão autorizados a emitir consultas ao cache local, \n \
      // sem acesso ao cache local as consultas recursivas são inúteis. \n \
      allow-query-cache { autorizados; }; \n \
      // Especifica quais hosts estão autorizados a “fazer perguntas” ao seu DNS.  \n \
      // Se for apenas recursivo pode informa a ACL “autorizados”  \n \
      // allow-query { autorizados; }; \n \
      allow-query { any; }; \n \
      // Especifica quais hosts estão autorizados a receber transferências de zona a partir do servidor. \n \
      // Seu servidor Secundário, no nosso ex vou deixar então o ips dos dois servidores v4 e v6. \n \
      allow-transfer { \n \
          45.171.228.19; \n \
          2804:5a10:bebe:cafe::3; \n \
      }; \n \
      also-notify { \n \
          45.171.228.19; \n \
          2804:5a10:bebe:cafe::3; \n \
      }; \n \
      // Esta opção faz com que o servidor slave ao fazer a transferência de zonas \n \
      // mastes deste servidor no formato binário (raw) do arquivo ou texto (text) \n \
      // text será legível por humanos, já raw formato é mais eficiente em termos de desempenho. \n \
      // masterfile-format raw; \n \
      masterfile-format text; \n \
      // Para evitar que vase a versao do Bind, definimos um nome \n \
      // Reza a lenda que deixar RR DNS Server seu servidor nunca sofrerá ataques. \n \
      version "RR DNS Server – Do good"; \n \
      // Define a quant. máxima de memória a ser usada para o cache do servidor (bytes ou porcentagem) \n \
      // Por padrão no debian 10/bind9 ele reserva 90% da memoria física. Então não se apavore com log ex.: \n \
      // Servidor com 2GB: none:106: "max-cache-size 90%" - setting to 1795MB (out of 1994MB) \n \
      // Recomendo não alterar \n \
      // max-cache-size 512M; \n \
      // max-cache-size 50%; \n \
      // Isso define o tempo mínimo para o qual o servidor armazena  \n \
      // em cache as respostas positivas, em segundos. \n \
      // Ex o tiktok.com manda tempo de ttl de 20 segundos,  \n \
      // e você quer ignorar esse valor 20 e setar que o minimo seja 90. \n \
      // que é o máximo permitido. \n \
      min-cache-ttl 90; \n \
      // Não recomendado alterar para menos que 24h. \n \
      // Define o tempo máximo durante o qual o servidor armazena (informado pelo dono do domínio) \n \
      // em cache as respostas positivas, em segundos. O max-cache-ttl padrão é 604800 (uma semana) \n \ 
      // max-cache-ttl 86400; // 24h  \n \
  }; '> /etc/bind/named.conf.options 

#USER bind
CMD [ "/usr/sbin/named" ,"-f","-u" ,"bind" ]
EXPOSE 53/tcp
EXPOSE 53/udp
