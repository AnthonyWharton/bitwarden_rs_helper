#!/bin/bash
# Copyright 2019 Anthony Wharton
# bitwarden_rs.sh - helper for setting up bitwarden_rs with docker-compose
# Run ./bitwarden_rs.sh help for usage

# Formatting convenience functions
rs=$(echo -e "\e[0m")
re=$(echo -e "\e[31m")
gr=$(echo -e "\e[32m")
yl=$(echo -e "\e[33m")
bl=$(echo -e "\e[34m")
ma=$(echo -e "\e[35m")
cy=$(echo -e "\e[36m")

# Change directory to location of bitwarden_rs.sh
cd "${0%/*}"
source script_config

# Installs the Let's Encrypt certificates
function install_certs {
	cd docker
	cat <<-EOF
	${yl}Now setting up certificates with Let's Encrypt for ${cy}${DOMAIN}
	${yl}Reminders for certificate expiry will be sent to ${cy}${EMAIL}${rs}
	EOF

	# Comment out HTTPS server
	sed -i '/.*__HTTPS_MARK__.*/,${s/^/#/}' ../nginx/conf.d/vault.conf

	# Start nginx server
	docker-compose up -d nginx

	# Get initial certificate
	docker-compose run --rm --entrypoint \
		"certbot certonly \
			--noninteractive \
			--rsa-key-size 4096 \
			--webroot \
			--webroot-path /var/www/certbot \
			--domain ${DOMAIN} \
			--agree-tos \
			--email ${EMAIL} \
			--no-eff-email
			--logs-dir /etc/letsencrypt/logs" \
		certbot

	if [ $? -ne 0 ]; then
		cat <<-EOF
		${re}Something has gone wrong generating certificates.
		Please check the above error(s).${rs}
		EOF
		sed -i '/.*__HTTPS_MARK__.*/,${s/^#//}' \
			../nginx/conf.d/vault.conf
		exit 1
	fi

	# Cleanup old containers
	docker-compose down

	# Uncomment HTTPS server
	sed -i '/.*__HTTPS_MARK__.*/,${s/^#//}' ../nginx/conf.d/vault.conf
	cd ..
}

# Installs a cron job to update the certs every day
function install_cron {
	CRON_LINE=$(echo -e "25 *\t* * *\tbitwarden\t$(pwd)/bitwarden_rs.sh u")
	echo "${yl}Installing cron job into ${cy}/etc/crontab${rs}"
	if [ "$EUID" -ne 0 ]; then
		echo "${re}You need to be root in order to install the automatic cron job"
		echo "${yl}Attempting with sudo...${rs}"
		sudo bash -c "echo \"# Automatic rule for bitwarden_rs certificate updates\" >> /etc/crontab"
		if [ $? -ne 0 ]; then
			cat <<-EOF
			${re}Aborting cron installation.
			${yl}Please add the following line to your ${cy}/etc/crontab ${yl}file and restart the cron service yourself.

			${cy}${CRON_LINE}${rs}


			EOF
			return
		fi
		sudo bash -c "echo \"${CRON_LINE}\" >> /etc/crontab"
		sudo systemctl restart cron.service
	else
		echo "# Automatic rule for bitwarden_rs certificate updates" >> /etc/crontab
		echo "${CRON_LINE}" >> /etc/crontab
		systemctl restart cron.service
	fi

	if [ $? -ne 0 ]; then
		echo "${re}Could not automatically restart cron."
		echo "${ye}Please restart the cron service yourself."
	fi
}

# Updates the Let's Encrypt certificates if required
function update_certs {
	cd docker
	cat <<-EOF
	${yl}Renewing certificates with Let's Encrypt for ${cy}${DOMAIN}
	${yl}Reminders for certificate expiry will be sent to ${cy}${EMAIL}
	EOF

	# Start nginx server
	docker-compose up -d nginx

	# Get initial certificate
	docker-compose run --rm --entrypoint \
		"certbot renew --logs-dir /etc/letsencrypt/logs" \
		certbot

	if [ $? -ne 0 ]; then
		cat <<-EOF
		${re}Something has gone wrong generating certificates.
		Please check the above error(s).
		EOF
		exit 1
	fi

	# Cleanup old containers
	docker-compose down
	cd ..
}

# Puts the docker-compose instance up
function dc_up {
	cd docker
	docker-compose up -d
	cd ..
}

# Tears the docker-compose instance down
function dc_down {
	cd docker
	docker-compose down
	cd ..
}

# Updates the images in the docker-compose config
function dc_pull {
	cd docker
	docker-compose pull
	cd ..
}

# Prints the program usage instructions
function usage {
	cat <<-EOF
	${yl}Helper for bitwarden_rs management.
	Usage: ./bitwarden_rs.sh ${cy}COMMAND

	    ${cy}i${bl}[nstall] ${yl}- sets up a fresh installation
	    ${cy}u${bl}[p]      ${yl}- updates binaries, renews certs and starts bitwarden_rs
	    ${cy}d${bl}[own]    ${yl}- stops bitwarden_rs
	    ${cy}h${bl}[elp]    ${yl}- prints this message${rs}
	EOF
}

# Parse command
case "$1" in
	i|install)
		dc_down
		dc_pull
		install_certs
		install_cron
		echo "${gr}Done!${yl} Installation complete."
		echo "Now run ${bl}./bitwarden_rs.sh up${rs} to run bitwarden_rs."
		;;
	u|up)
		dc_down
		dc_pull
		update_certs
		dc_up
		echo "${gr}Done!${yl} bitwarden_rs is now running."
		;;
	d|down)
		dc_down
		echo "${gr}Done!${yl} bitwarden_rs has been stopped."
		;;
	*)
		if [ "$1" != "help" -a "$1" != "h" ]; then
			echo "${re}Unknown command!${rs}"
		fi
		usage
		;;
esac
