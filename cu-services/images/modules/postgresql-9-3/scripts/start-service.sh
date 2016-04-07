#!/bin/bash

# Ajout des variables d'environnement
export CU_USER=$1
export CU_PASSWORD=$2
export CU_DATABASE_NAME=$3
export CU_ROOT_PASSWORD=$4
export CU_SSH_USER=$5

# Database password for Manager
export MANAGER_DATABASE_PASSWORD=$6
# To do difference between main and test env
export ENV_EXEC=$7
export CU_DATABASE_DNS=$8

# Callback bound to the application stop
terminate_handler() {
  echo "/cloudunit/java/jdk1.7.0_55/bin/java -jar /cloudunit/tools/cloudunitAgent-1.0-SNAPSHOT.jar MODULE $MYSQL_ENDPOINT $HOSTNAME STOP $MANAGER_DATABASE_PASSWORD" > /cloudunit/command.txt
  service postgresql stop
  CODE=$?
  if [[ "$CODE" -eq "0" ]]; then
    /cloudunit/java/jdk1.7.0_55/bin/java -jar /cloudunit/tools/cloudunitAgent-1.0-SNAPSHOT.jar MODULE $MYSQL_ENDPOINT $HOSTNAME STOP $MANAGER_DATABASE_PASSWORD
  else
    /cloudunit/java/jdk1.7.0_55/bin/java -jar /cloudunit/tools/cloudunitAgent-1.0-SNAPSHOT.jar MODULE $MYSQL_ENDPOINT $HOSTNAME FAIL $MANAGER_DATABASE_PASSWORD
  fi
  exit $CODE;
}

trap 'terminate_handler' SIGTERM

if [ $ENV_EXEC = "integration" ];
then
    export MYSQL_ENDPOINT=cuplatform_testmysql_1.mysql.cloud.unit
else
    export MYSQL_ENDPOINT=$CU_DATABASE_DNS
fi

# ############
# First call #
# ############
if [ ! -f /init-service-ok ]; then

	# Préparation du dossier de données de postgres
	mv /var/lib/postgresql/9.3/main /cloudunit/database
	chown postgres:postgres -R /cloudunit/database
	chmod 0700 -R /cloudunit/database

	useradd $CU_SSH_USER && echo "$CU_SSH_USER:$CU_ROOT_PASSWORD" | chpasswd
	echo "root:$CU_ROOT_PASSWORD" | chpasswd

	chmod 600 -R /etc/ssh
	/usr/sbin/sshd

	mkdir -p $CU_USER_HOME/.ssh
	usermod -d $CU_USER_HOME $CU_SSH_USER
	usermod -s /bin/bash $CU_SSH_USER
	# TODO : verify these two lines ???
	cp /root/.bashrc $CU_USER_HOME
	cp /root/.profile $CU_USER_HOME

	# Creation a dedicated superadmin docker for post. No use of root
	/etc/init.d/postgresql start
	su - postgres -c "psql --command \"CREATE USER docker WITH SUPERUSER PASSWORD '$CU_ROOT_PASSWORD';\""
	su - postgres -c "createdb -O docker docker"
	/etc/init.d/postgresql stop
	
	# Transformation des variables en variables d'environnement
	chown -R $CU_SSH_USER:$CU_SSH_USER $CU_USER_HOME

	sed -i -e"s:deny from all:# deny from all:g" /etc/apache2/conf.d/phppgadmin
	sed -i -e"s:# allow from all:allow from all:g" /etc/apache2/conf.d/phppgadmin

	/etc/init.d/postgresql start
	/usr/sbin/apachectl start

	## SURTOUT NE PAS SUPPRIMER LA TEMPO !
	sleep 5
	## Création du compte généré dynamiquement côté Java
	psql -U docker --command "CREATE USER $CU_USER WITH SUPERUSER PASSWORD '$CU_PASSWORD'"
	## Création de la base de données du compte et association avec -O (owner) de la BDD et du compte
	su - postgres -c "createdb -O $CU_USER $CU_DATABASE_NAME"
	
	touch /init-service-ok
else
    # Here : not the first start.
    # we use classic command
	/usr/sbin/sshd
	service postgresql start
	/usr/sbin/apachectl start
fi

RETURN=1
count=0
# ########################
# Waiting for sshd start #
# ########################
until [[ "$RETURN" -eq "0" ]] || [[ $count -gt $kwait ]]; do
	echo -n -e  "\nWaiting for ssh\n"
	nc -z localhost 22
	RETURN=$?
	sleep 1
	let count=$count+1;
done

# ###########################
# Waiting for Postgre start #
# ###########################
RETURN=1
count2=0
until [[ "$RETURN" -eq "0" ]] || [[ $count2 -gt $kwait ]]; do
    nc -z localhost 5432
    RETURN=$?
    echo -n -e "\nWaiting for Postgre to start"
    sleep 1
    let count2=$count2+1;
done

# ####################################
# If postgre is started we notify it #
# ####################################
if [[ $count -gt $kwait ]] && [[ $count2 -gt $kwait ]]; then
    /cloudunit/java/jdk1.7.0_55/bin/java -jar /cloudunit/tools/cloudunitAgent-1.0-SNAPSHOT.jar MODULE $MYSQL_ENDPOINT $HOSTNAME START $MANAGER_DATABASE_PASSWORD
else
    /cloudunit/java/jdk1.7.0_55/bin/java -jar /cloudunit/tools/cloudunitAgent-1.0-SNAPSHOT.jar MODULE $MYSQL_ENDPOINT $HOSTNAME FAIL $MANAGER_DATABASE_PASSWORD
fi

# Blocking step
while true
do
  tail -f /dev/null & wait ${!}
done