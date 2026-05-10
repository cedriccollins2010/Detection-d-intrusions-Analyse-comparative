#  ML vs GNN pour la Détection d'Intrusions Réseau

![Python](https://img.shields.io/badge/Python-3.12-3776AB?style=flat&logo=python&logoColor=white)
![PyTorch](https://img.shields.io/badge/PyTorch-2.0.1-EE4C2C?style=flat&logo=pytorch&logoColor=white)
![scikit-learn](https://img.shields.io/badge/scikit--learn-1.3.0-F7931E?style=flat&logo=scikit-learn&logoColor=white)
![LaTeX](https://img.shields.io/badge/LaTeX-Rapport-008080?style=flat&logo=latex&logoColor=white)
![Dataset](https://img.shields.io/badge/Dataset-CSE--CIC--IDS2018-blue?style=flat)

> **Projet de Synthèse — Automne 2025**  
> Évaluation comparative de 12 modèles ML tabulaires et 3 architectures Graph Neural Networks (GNN) pour la détection d'intrusions réseau sur le dataset CSE-CIC-IDS2018.

---

##  Résultats clés

| Modèle | Accuracy | F1-macro | Balanced Accuracy | MCC |
|--------|----------|----------|-------------------|-----|
| XGBoost | 91.5% | 23.9% | 33.0% | ~0.25 |
| Random Forest | ~91% | ~24% | ~33% | ~0.25 |
| **GraphSAGE (transductif)** | **99.89%** | **98.58%** | **~98%** | **~0.99** |
| **GraphSAGE (inductif)** | **99.93%** | **98.97%** | **~99%** | **~0.99** |

> -  **GraphSAGE surpasse XGBoost de +75 points de F1-macro** en exploitant la structure du graphe k-NN entre flux réseau.  
> -  GraphSAGE détecte les classes ultra-minoritaires (ex: LOIC-UDP avec **seulement 3 exemples**) à **100% de F1**, là où XGBoost échoue complètement (0%).

---

##  Description du projet

### Problématique

Les systèmes de détection d'intrusions (IDS) traditionnels basés sur le ML tabulaire présentent deux limitations majeures :
1. **Absence de structure** : chaque flux est traité isolément, sans tenir compte des relations entre entités réseau.
2. **Classes rares** : les modèles classiques échouent sur les attaques minoritaires malgré des accuracies globales élevées (~91%).

### Approche

- **Modèles tabulaires** (12 algorithmes) : XGBoost, LightGBM, Random Forest, Extra Trees, Gradient Boosting, HistGradientBoosting, Decision Tree, Logistic Regression, SGD, LinearSVC, Gaussian NB, Bernoulli NB.
- **Graph Neural Networks** (3 architectures) : GCN, GAT, GraphSAGE — entraînés sur un graphe k-NN de **100 000 nœuds et 484 602 arêtes**.
- **Validation rigoureuse** : Temporal CV (TimeSeriesSplit, 3 folds) respectant la chronologie des données.

### Dataset

**CSE-CIC-IDS2018** — Canadian Institute for Cybersecurity  
500 000 flux réseau · 79 caractéristiques · 10 classes d'attaques (DDoS, DoS, Brute Force, Botnet, Infiltration)

---

##  Structure du dépôt

```
ml-gnn-intrusion-detection/
├── rapport/
│   ├── Projet_de_synthese_final.tex   # Source LaTeX du rapport (1470 lignes)
│   └── Projet_de_synthese_final.pdf   # Rapport compilé
│
├── presentation/
│   ├── presentation_soutenance.tex    # Source Beamer de la présentation
│   ├── presentation_soutenance.pdf    # Diapositives de soutenance
│   ├── Texte_Presentation.txt         # Script de présentation (version longue)
│   └── Texte_Presentation_Courte.txt  # Script de présentation (5 minutes)
│
├── notebooks/
│   ├── 01_CICIDS2018_Temporal_CV.ipynb          # ML tabulaire + Temporal CV
│   └── 02_GNN_CICIDS2018_Complete_Execution.ipynb # Construction graphe + GNN
│
├── figures/
│   ├── Screenshot1.png    # Comparaison F1-Score & Accuracy (CV vs Hold-out)
│   ├── Screenshot2.png    # Temps d'entraînement & métriques multi-dimensionnelles
│   ├── Screenshot3.png    # Résultats GNN comparatifs
│   └── Annexe_[3-8].png   # Matrices de confusion et analyses supplémentaires
│
├── docs/
│   └── Features_Noeuds_Aretes.md  # Documentation technique de la construction du graphe
│
├── compile.bat            # Script de compilation LaTeX (Windows CMD)
├── compile.ps1            # Script de compilation LaTeX (PowerShell)
└── .gitignore
```

---

## 🔬 Méthodologie

### Construction du graphe k-NN

```
100 000 flux réseau (sous-échantillonnage stratifié de 3M)
    └─ 79 features standardisées (mean=0, std=1)
        └─ k-NN avec k=10, distance euclidienne
            └─ 484 602 arêtes (degré moyen: 9.69)
                └─ Graphe non orienté → PyTorch Geometric Data
```

### Protocoles d'évaluation

| Protocole | Description |
|-----------|-------------|
| Hold-out 70/30 | Split aléatoire, rapide mais optimiste |
| **Temporal CV** | TimeSeriesSplit 3-fold, respecte la chronologie — plus réaliste |
| Transductif (GNN) | Masques sur graphe complet |
| **Inductif (GNN)** | Nœuds de test isolés pendant l'entraînement — scénario IDS réel |

---

## 💻 Reproduction

### Prérequis

```bash
pip install numpy==1.24 pandas==2.0 scikit-learn==1.3.0
pip install xgboost lightgbm
pip install torch==2.0.1
pip install torch-geometric
pip install faiss-cpu networkx
```

>  Les notebooks ont été développés sur **Google Colab** (GPU T4 pour les GNN). La construction du graphe k-NN nécessite ~9 minutes et ~1.7 Go de RAM.

### Lancer les notebooks

```bash
# Notebook 1 : Modèles tabulaires
jupyter notebook notebooks/01_CICIDS2018_Temporal_CV.ipynb

# Notebook 2 : Graph Neural Networks
jupyter notebook notebooks/02_GNN_CICIDS2018_Complete_Execution.ipynb
```

### Compiler le rapport LaTeX

```bash
# Windows (CMD)
compile.bat

# Windows (PowerShell)
./compile.ps1
```

---

##  Analyse des performances

### Pourquoi les modèles tabulaires échouent sur les classes rares ?

Avec un dataset déséquilibré (82% Benign), l'accuracy est trompeuse. Le F1-macro non pondéré révèle la vérité :

```
XGBoost  — Accuracy: 91.5%   |  F1-macro: 23.9%  |  Balanced Accuracy: 33% 
GraphSAGE — Accuracy: 99.9%   |  F1-macro: 98.6%   |  Balanced Accuracy: ~98% 
```

### Pourquoi les GNN réussissent ?

Le graphe k-NN crée des **clusters comportementaux** : les flux DDoS se regroupent naturellement entre eux. Via le **message passing**, un flux rare peut "emprunter" l'information de ses voisins similaires, permettant une classification correcte même avec 3 exemples d'entraînement.

---

##  Documents

-  [Rapport complet (PDF)](rapport/Projet_de_synthese_final.pdf)
-  [Présentation de soutenance (PDF)](presentation/presentation_soutenance.pdf)
-  [Documentation technique du graphe](docs/Features_Noeuds_Aretes.md)

---

##  Auteur

**Cedric Tanekeu**  
Université — Département d'Informatique  
Projet de Synthèse, Automne 2025

---

##  Références principales

- Hamilton et al. (2017). *Inductive Representation Learning on Large Graphs* (GraphSAGE)
- Kipf & Welling (2017). *Semi-Supervised Classification with Graph Convolutional Networks* (GCN)
- Veličković et al. (2018). *Graph Attention Networks* (GAT)
- Dataset: [CSE-CIC-IDS2018 sur Kaggle](https://www.kaggle.com/datasets/solarmainframe/ids-intrusion-csv)
