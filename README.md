# DeepSeek API Pricing Tracker 📉

Un utilitaire ultra-léger pour la barre des tâches Windows (SysTray) qui surveille en temps réel les horaires de pointe (Peak) et hors pointe (Off-Peak) de l'API DeepSeek, afin d'optimiser les coûts de tokens.

Développé en **PureBasic**, cet outil consomme \~0% de CPU et se veut sécurisé, accessible et non-intrusif.



## 🤝 Contribution

Les pull requests sont les bienvenues. Pour des changements majeurs, veuillez ouvrir une issue au préalable pour discuter de ce que vous aimeriez changer.



## 📄 Licence

Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.



## ✨ Fonctionnalités (UI/UX \& Cyber-sécurisé)

* **Temps Réel UTC :** Calcul précis basé sur l'heure UTC (l'heure de référence des serveurs DeepSeek).
* **Notifications intelligentes (Toast) :** Alerte visuelle non-intrusive (ne vole pas le focus) 5 minutes avant le passage en tarif fort.
* **Accessibilité (Colorblind-friendly) :** Les icônes utilisent à la fois des couleurs et des symboles (Point d'exclamation rouge `!` pour la pointe, Dollar vert `$` pour le tarif réduit).
* **Configuration Dynamique :** Les tranches horaires sont modifiables à chaud via un fichier `.ini` sécurisé.
* **Sécurité anti-DoS :** Parsing robuste des entrées avec limite stricte du nombre de tranches en mémoire.
* **Action Rapide :** Un clic gauche sur l'icône ouvre instantanément votre tableau de bord de consommation web.



## 🚀 Installation \& Compilation

1. Téléchargez et installez [PureBasic](https://www.purebasic.com/) (Version 6.0+ recommandée).
2. Ouvrez le fichier `DeepSeekTray.pb` dans l'IDE PureBasic.
3. Allez dans **Compilateur > Options du compilateur.**
Dans l'onglet Général, coche Utiliser une icône.
Sélectionner le fichier icon.ico.
4. Allez dans **Compilateur > Créer un exécutable...**
5. Lancez votre exécutable !

<img width="360" height="302" alt="image" src="https://github.com/user-attachments/assets/891bc56e-1cbd-43ac-a4c4-4585558311bb" />


## ⚙️ Configuration (`tarifs.ini`)

Au premier lancement, le programme génère automatiquement un fichier de configuration sécurisé dans votre dossier utilisateur Windows :
`%APPDATA%\\\\DeepSeekTray\\\\tarifs.ini`

Pour le modifier :

1. Faites un clic **droit** sur l'icône dans la barre des tâches.
2. Cliquez sur **Ouvrir tarifs.ini**.
3. Ajoutez ou modifiez vos tranches horaires (format 24h UTC).
4. Enregistrez le fichier, refaites un clic droit et choisissez **Actualiser**.



**Exemple de fichier `tarifs.ini` :**

```ini
\\\[Horaires\\\_Pointe\\\_UTC]
; Heures de pointe UTC (HH:MM-HH:MM en 24h, Max 10 tranches)
Tranche1 = 01:00-04:00
Tranche2 = 06:00-10:00


