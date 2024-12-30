if [ -f /opt/zimbra/onlyoffice/bin/process_id.json ]; then
	cp -af /opt/zimbra/onlyoffice/bin/process_id.json /opt/zimbra/onlyoffice/bin/process_id.json.bak
	chmod 775 /opt/zimbra/onlyoffice/bin/process_id.json.bak
	chown zimbra:zimbra /opt/zimbra/onlyoffice/bin/process_id.json.bak
fi
