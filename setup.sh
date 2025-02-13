#!/bin/bash

echo "[INFO] Début du déploiement..."

# Mise à jour du système
sudo apt update -y

# Ajout du dépôt officiel de Jenkins
echo "[INFO] Ajout du dépôt Jenkins..."
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Mise à jour après l'ajout des dépôts
sudo apt update -y
sudo apt-get update -y

# Installation des services nécessaires
echo "[INFO] Installation de Java, Jenkins et MySQL..."
sudo apt install -y openjdk-17-jdk -y

sudo apt-get install jenkins mysql-server -y

# Installation de Gitea via Snap
echo "[INFO] Installation de Gitea..."
sudo snap install gitea

# Vérifier si le dossier resources existe
if [ ! -d "./resources" ]; then
    echo "[ERREUR] Le dossier resources est introuvable !"
    exit 1
fi

# Configuration de Jenkins
if [ -d "./resources/jenkins" ]; then
    echo "[INFO] Mise à jour de la configuration de Jenkins..."
    if [ -f "./resources/jenkins-home.tar.gz" ]; then
        sudo tar -xzvf ./resources/jenkins-home.tar.gz -C /var/lib/jenkins
        sudo chown -R jenkins:jenkins /var/lib/jenkins
    else
        echo "[ERREUR] Fichier jenkins-home.tar.gz introuvable !"
        exit 1
    fi
fi

# Configuration de MySQL
# Configuration de MySQL
if [ -d "./resources/mysql" ]; then
    echo "[INFO] Configuration de MySQL..."
    
    # Connexion à MySQL et création de l'utilisateur giteauser avec tous les privilèges
    sudo mysql -u root -p <<EOF
    CREATE DATABASE IF NOT EXISTS gitea-db;
    CREATE USER IF NOT EXISTS 'giteauser'@'localhost' IDENTIFIED BY 'test';
    GRANT ALL PRIVILEGES ON gitea-db.* TO 'giteauser'@'localhost' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
EOF

    # Importation du fichier SQL s'il existe
    if [ -f "./resources/gitea.sql" ]; then
        sudo mysql -u giteauser -p test gitea-db < ./resources/gitea.sql
    else
        echo "[ERREUR] Fichier gitea.sql introuvable !"
        exit 1
    fi
fi


# Configuration de Gitea
if [ -f "./resources/gitea/app.ini" ]; then
    echo "[INFO] Mise à jour de la configuration de Gitea..."
    if [ -f "./resources/gitea-repos.tar.gz" ]; then
        sudo tar -xzvf ./resources/gitea-repos.tar.gz -C /var/lib/gitea
        sudo chown -R gitea:gitea /var/lib/gitea
    else
        echo "[ERREUR] Fichier gitea-repos.tar.gz introuvable !"
        exit 1
    fi
fi

# Redémarrage des services
echo "[INFO] Redémarrage des services..."
sudo systemctl restart jenkins
sudo systemctl restart mysql
sudo snap restart gitea

# Vérification du statut des services
for service in jenkins mysql; do
    if systemctl is-active --quiet $service; then
        echo "[INFO] Le service $service est actif."
    else
        echo "[ERREUR] Le service $service n'a pas démarré correctement !"
        exit 1
    fi
done

# Vérification de Gitea (snap utilise une autre commande)
if snap services gitea | grep -q "active"; then
    echo "[INFO] Le service Gitea est actif."
else
    echo "[ERREUR] Le service Gitea n'a pas démarré correctement !"
    exit 1
fi

echo "[INFO] Déploiement terminé avec succès."
