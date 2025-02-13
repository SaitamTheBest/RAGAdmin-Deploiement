#!/bin/bash

echo "[INFO] Début du déploiement..."

# Mise à jour du système et installation des services
sudo apt update -y
echo "[INFO] Installation de Jenkins, Gitea et MySQL..."
sudo apt install -y openjdk-11-jdk gitea jenkins mysql-server

# Vérifier si le dossier resources existe
if [ ! -d "./resources" ]; then
    echo "[ERREUR] Le dossier resources est introuvable !"
    exit 1
fi

# Configuration de Jenkins
if [ -d "./resources/jenkins" ]; then
    echo "[INFO] Mise à jour de la configuration de Jenkins..."
    sudo tar -xzvf jenkins-home.tar.gz -C /var/lib/jenkins
    sudo chown -R jenkins:jenkins /var/lib/jenkins
fi

# Configuration de MySQL
if [ -d "./resources/mysql" ]; then
    echo "[INFO] Configuration de MySQL..."
    
    sudo mysql -u root -p giteadb < gitea.sql
fi

# Configuration de Gitea
if [ -f "./resources/gitea/app.ini" ]; then
    echo "[INFO] Mise à jour de la configuration de Gitea..."
    sudo tar -xzvf ./resources/gitea-repos.tar.gz -C /var/lib/gitea
    sudo chown -R gitea:gitea /var/lib/gitea
fi

# Redémarrage des services pour appliquer les changements
echo "[INFO] Redémarrage des services..."
sudo systemctl restart gitea
sudo systemctl restart jenkins
sudo systemctl restart mysql

echo "[INFO] Déploiement terminé avec succès."
