if [ -f /opt/zimbra/onlyoffice/bin/jq ]; then
	chmod +x /opt/zimbra/onlyoffice/bin/jq
fi

if [ -f /opt/zimbra/onlyoffice/bin/zmonlyofficeconfig ]; then
	chmod +x /opt/zimbra/onlyoffice/bin/zmonlyofficeconfig
fi

if [ -f /opt/zimbra/onlyoffice/bin/process_id.json.bak ]; then
	mv -f /opt/zimbra/onlyoffice/bin/process_id.json.bak /opt/zimbra/onlyoffice/bin/process_id.json
	/opt/zimbra/onlyoffice/bin/zmonlyofficeconfig
fi

if [ -d /opt/zimbra/onlyoffice ]; then
  chown -R root:root /opt/zimbra/onlyoffice/
  if [ -f /opt/zimbra/onlyoffice/bin/process_id.json ]; then
    chmod 775 /opt/zimbra/onlyoffice/bin/process_id.json
    chown zimbra:zimbra /opt/zimbra/onlyoffice/bin/process_id.json
  fi
  mkdir -p /opt/zimbra/onlyoffice/documentserver/App_Data/cache
  chmod 755 /opt/zimbra/onlyoffice/documentserver/App_Data
  chown -R zimbra:zimbra /opt/zimbra/onlyoffice/documentserver/App_Data/cache/
fi
