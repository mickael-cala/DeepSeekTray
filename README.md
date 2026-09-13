# DeepSeekTray

Utilitaire SysTray léger pour Windows qui affiche dynamiquement le tarif actuel (Heures Pleines / Heures Creuses) basé sur des tranches horaires configurables.

## 🚀 Fonctionnalités

- **Léger et non-intrusif** : Consommation CPU ~0%, icône 16x16 générée dynamiquement
- **Logique métier avancée** : Gestion native des tranches chevauchant minuit (ex: 22:00-02:00)
- **Exclusion week-end** : Détection automatique des jours ouvrés
- **Accessibilité** : Double codage couleur + symbole (`!` rouge / `$` vert) pour les daltoniens
- **Configuration simple** : Fichier INI lisible et modifiable sans recompilation

## 📁 Structure du Projet

```text
DeepSeekTray/
├── src/                    # Code source PureBasic
│   ├── DeepSeekTray.pb     # Fichier principal
│   └── icon.ico            # Icône de fallback (optionnelle)
├── build/                  # Artifacts de compilation (ignoré par Git)
│   └── DeepSeekTray.exe    # Exécutable généré
├── tests/                  # Tests unitaires
│   ├── test_logic.pb       # Tests en PureBasic
│   └── test_logic.py       # Tests en Python (pour CI/CD)
├── docs/                   # Documentation technique
│   ├── architecture.txt    # Notes d'architecture
│   └── CHANGELOG.md        # Historique des versions
├── config/                 # Fichiers de configuration
│   └── tarifs.ini.example  # Modèle de configuration
├── build.bat               # Script de compilation automatisé
├── run_tests.bat           # Script d'exécution des tests Python
├── README.md               # Ce fichier
└── LICENSE.txt             # Licence du projet
```

## 🛠️ Installation et Utilisation

### 1. Configuration

1. Copiez le fichier modèle : `config\tarifs.ini.example` vers `%APPDATA%\DeepSeekTray\tarifs.ini`
   *(Chemin complet : `C:\Users\<VotreNom>\AppData\Roaming\DeepSeekTray\tarifs.ini`)*
2. Éditez le fichier avec vos tranches horaires. Exemple :

```ini
[Tranche1]
JourDebut=1
HeureDebut=08:00
JourFin=1
HeureFin=12:00
EstActive=1
```

> **Format des jours** : 1 = Lundi, 2 = Mardi, ..., 6 = Samedi, 7 = Dimanche  
> **Format des heures** : HH:MM (24h, avec zéro initial si nécessaire, ex: `09:30`)

### 2. Compilation (pour les développeurs)

Double-cliquez sur `build.bat` pour compiler automatiquement le projet en version x64 avec DPI Aware.

**Prérequis** : PureBasic installé dans l'un des emplacements suivants :
- `C:\Program Files\PureBasic\`
- `C:\Program Files (x86)\PureBasic\`
- `C:\PureBasic\`

*Si votre installation est ailleurs, modifiez le chemin dans `build.bat`.*

### 3. Tests Unitaires

Pour valider la logique métier (détection des tranches, chevauchement minuit, etc.) :

**Option A : Via Python (recommandé pour CI/CD)**
```cmd
run_tests.bat
```
*Ou manuellement : `python tests\test_logic.py`*

**Option B : Via PureBasic**
Ouvrez `tests\test_logic.pb` dans l'IDE PureBasic et exécutez-le. La console affichera le résumé des tests.

## ⚙️ Détails Techniques

- **Langage** : PureBasic 6.x (compatible 5.x)
- **Architecture** : x64 uniquement
- **Sous-système** : Windows (GUI)
- **DPI Aware** : Oui (rendu net sur écrans haute résolution)
- **Dépendances** : Aucune (bibliothèque standard PureBasic uniquement)

## 🐛 Dépannage

| Symptôme | Solution |
|----------|----------|
| L'icône ne s'affiche pas | Vérifiez que le fichier `%APPDATA%\DeepSeekTray\tarifs.ini` existe et est bien formaté |
| Erreur de compilation | Vérifiez que `pbcompiler.exe` est dans le PATH ou modifiez `build.bat` |
| Les tests échouent | Vérifiez que vous n'avez pas modifié la logique de `EstDansTranche` sans mettre à jour les tests |

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE.txt` pour plus de détails.

## 👤 Auteur

Développé par Mickael - Expert Windows/Linux/Termux/PureBasic
