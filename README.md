<div align="center">
  <img src="figures/banner.png" alt="Project Banner" width="100%">
  <br><br>
  <h1>ML vs GNN pour la Détection d'Intrusions Réseau</h1>
  <p>
    <img src="https://img.shields.io/badge/Python-3.12-3776AB?style=flat&logo=python&logoColor=white" alt="Python" />
    <img src="https://img.shields.io/badge/PyTorch-2.0.1-EE4C2C?style=flat&logo=pytorch&logoColor=white" alt="PyTorch" />
    <img src="https://img.shields.io/badge/scikit--learn-1.3.0-F7931E?style=flat&logo=scikit-learn&logoColor=white" alt="scikit-learn" />
    <img src="https://img.shields.io/badge/LaTeX-Rapport-008080?style=flat&logo=latex&logoColor=white" alt="LaTeX" />
    <img src="https://img.shields.io/badge/Dataset-CSE--CIC--IDS2018-blue?style=flat" alt="Dataset" />
  </p>
</div>

> [!NOTE]
> **Projet de Synthèse — Automne 2025**  
> Évaluation comparative de 12 modèles ML tabulaires et 3 architectures Graph Neural Networks (GNN) pour la détection d'intrusions réseau sur le dataset CSE-CIC-IDS2018.

---
 
## Table des matières
 
1. [Contexte & Motivation](#contexte--motivation)
2. [Dataset & Préparation](#dataset--préparation)
3. [Approches Testées](#approches-testées)
4. [Méthodologie Complète](#méthodologie-complète)
5. [Résultats Observés](#résultats-observés)
6. [Limitations Connues](#limitations-connues)
7. [Reproduction](#reproduction)
8. [Structure du Dépôt](#structure-du-dépôt)
---
 
## Contexte & Motivation
 
### Problème
 
Les **Intrusion Detection Systems (IDS)** opérationnels détectent les intrusions réseau en classifiant les flux. Deux défis majeurs :
 
1. **Déséquilibre extrême** — 82% du trafic est bénin → accuracy seule est inutile
2. **Classes ultra-minoritaires** — Certains types d'attaques (LOIC-UDP, Infiltration) apparaissent en < 5 exemples par jour
Les modèles ML classiques (XGBoost, etc.) ne capturent pas les **relations structurelles** entre flux :
- Flux d'une même attaque DDoS partagent des patterns similaires
- Graphe de similarité pourrait exploiter ces clusters
### Hypothèse du Projet
 
Les **Graph Neural Networks** qui construisent un graphe k-NN entre flux peuvent :
- Exploiter la structure implicite du trafic
- Améliorer la détection des classes rares via **message passing**
- Surpasser les modèles tabulaires sur des métriques justes (F1-macro, balanced accuracy)
---
 
## Dataset & Préparation
 
### Source
 
**CSE-CIC-IDS2018** — Canadian Institute for Cybersecurity ([Kaggle](https://www.kaggle.com/datasets/solarmainframe/ids-intrusion-csv))
 
- **500 000 flux réseau** au total
- **79 caractéristiques** (durée, nb paquets, bytes, flags TCP/UDP, etc.)
- **10 classes d'attaques** :
  - Benign (~82%)
  - DDoS / DoS variations
  - Brute Force (SSH, FTP)
  - Botnet, Infiltration, Web Attack, Heartbleed, Slowhttptest, etc.
### Preprocessing
 
```
Raw Dataset (500k flux)
    ↓
[1] Sous-échantillonnage stratifié → 100k flux (class distribution préservée)
    ↓
[2] Standardisation Z-score (mean=0, std=1)
    ↓
[3] Pas d'imputation (0 valeurs manquantes détectées)
    ↓
Ready for ML & GNN
```
 
## Approches Testées
 
### A. Modèles ML Tabulaires (Notebook 1)
 
12 algorithmes, tous avec **Temporal CV** (TimeSeriesSplit, 3 folds) :
 
| Algorithme | Paramètres | Notes |
|-----------|-----------|-------|
| XGBoost | default | Baseline principal |
| LightGBM | default | Gradient boosting alternatif |
| Random Forest | n_estimators=100, max_depth=20 | Ensemble référence |
| Extra Trees | n_estimators=100 | Variante RF |
| Gradient Boosting | n_estimators=100, max_depth=5 | GB classique |
| HistGradientBoosting | max_leaf_nodes=31 | Scalable GB |
| Decision Tree | max_depth=10 | Baseline simple |
| Logistic Regression | max_iter=1000 | Linéaire |
| SGD | loss='log_loss', max_iter=1000 | SGD linéaire |
| LinearSVC | C=1.0 | SVM linéaire |
| Gaussian NB | default | Naïve Bayes |
| Bernoulli NB | alpha=1.0 | Naïve Bayes binaire |
 
**Métrique clés** : Accuracy, F1-macro, F1-weighted, Balanced Accuracy, MCC
 
### B. Graph Neural Networks (Notebook 2)
 
3 architectures entraînées sur graphe k-NN :
 
| Architecture | Couches | Features | Notes |
|---|---|---|---|
| **GCN** | 2-3 conv | [79 → 64 → 32 → 10] | Kipf & Welling (2017) |
| **GAT** | 2-3 attention | [79 → 8 heads × 8 → 10] | Veličković et al. (2018) |
| **GraphSAGE** | 2-3 aggregation | [79 → 64 → 32 → 10] | Hamilton et al. (2017) |
 
**Graphe** : k-NN avec k=10, euclidienne, non orienté
- **Nœuds** : 100 000
- **Arêtes** : ~484 602 (degré moyen 9.69)
- **Construction** : FAISS pour k-NN rapide
---
 
## Méthodologie Complète
 
### Étape 1 : Baseline Tabulaire (Temporal CV)
 
```python
# TimeSeriesSplit respecte la chronologie
splitter = TimeSeriesSplit(n_splits=3)
 
for train_idx, test_idx in splitter.split(X):
    X_train, X_test = X[train_idx], X[test_idx]
    y_train, y_test = y[train_idx], y[test_idx]
    
    # XGBoost (et tous les autres)
    model = XGBClassifier()
    model.fit(X_train, y_train)
    y_pred = model.predict(X_test)
    
    # Metrics
    scores.append({
        'accuracy': accuracy_score(y_test, y_pred),
        'f1_macro': f1_score(y_test, y_pred, average='macro'),
        'balanced_acc': balanced_accuracy_score(y_test, y_pred),
        'mcc': matthews_corrcoef(y_test, y_pred),
    })
```
 
**Résultat** : XGBoost F1-macro 23.9% (classe rares non détectées)
 
### Étape 2 : Construction Graphe k-NN
 
```python
# QUESTION CRITIQUE : À quel point du pipeline?
# Option A : k-NN sur 100k complets (train + test mélangés)
# Option B : k-NN par fold Temporal CV (train uniquement)
 
# Actuellement implémenté (Notebook 2) : Option A [⚠️ POTENTIEL LEAKAGE]
# Comment reproduced: Voir docs/Features_Noeuds_Aretes.md
```
 
### Étape 3 : Entraînement GNN
 
Deux protocoles d'évaluation :
 
#### **Protocole Transductif**
```
Graphe complet (train + test) → Masques nodes [train / val / test]
Pendant entraînement : message passing voit toute la structure
→ Nœuds test peuvent avoir arêtes vers nœuds train
→ Plus performant (F1: 98.6%) MAIS OPTIMISTE
```
 
#### **Protocole Inductif** (plus réaliste pour IDS)
```
Entraînement : graphe train uniquement
Inférence : nœuds test ajoutés, pas d'arêtes internes
→ Reflète un vrai système IDS (flux nouveau = isolé)
→ Moins performant que transductif
```
 
---
 
## Résultats Observés
 
### Performance par Modèle
 
```
┌─────────────────────────┬──────────┬──────────┬──────────────┬──────────┐
│ Modèle                  │ Accuracy │ F1-macro │ Balanced Acc │ MCC      │
├─────────────────────────┼──────────┼──────────┼──────────────┼──────────┤
│ XGBoost                 │ 91.5%    │ 23.9%    │ 33.0%        │ ~0.25    │
│ Random Forest           │ ~91%     │ ~24%     │ ~33%         │ ~0.25    │
│ LightGBM                │ ~91%     │ ~24%     │ ~32%         │ ~0.24    │
│ ... (autres tabulaires) │ 85-91%   │ 15-24%   │ 25-33%       │ 0.15-0.25│
│                         │          │          │              │          │
│ GCN (transductif)       │ ~99%     │ ~97%     │ ~96%         │ ~0.96    │
│ GAT (transductif)       │ ~99%     │ ~97%     │ ~96%         │ ~0.96    │
│ GraphSAGE (transductif) │ 99.89%   │ 98.58%   │ ~98%         │ ~0.99    │
│ GraphSAGE (inductif)    │ 99.93%   │ 98.97%   │ ~99%         │ ~0.99    │
└─────────────────────────┴──────────┴──────────┴──────────────┴──────────┘
```
 
### Écart Inquiétant
 
**XGBoost → GraphSAGE : +75 points de F1-macro**
 
Possible explication :
- ✅ **Légitime** : Structure graphe capture vraiment les clusters d'attaques
- ⚠️ **Data leakage** : Arêtes k-NN relient train et test → prédictions gonflées
- ⚠️ **Overfitting** : GNN mémorise plutôt que généralise
---
 
## Limitations Connues
 
### 🔴 Critique
 
#### 1. **Possible Data Leakage dans Graphe k-NN**
 
Le graphe k-NN est construit sur **l'ensemble complet (train + test)**.  
Si un nœud test a une arête vers un nœud train, le message passing peut "fuir" l'information.
 
**À vérifier** :
```python
# Pour chaque edge (src, dst) dans le graphe final
# Si src ∈ test_set et dst ∈ train_set → LEAKAGE CONFIRMÉ
```
 
**Impact** : Les performances GNN (+98% F1) sont possiblement **artificiellement gonflées**.
 
#### 2. **Temporal CV Absent des GNN**
 
Notebook 1 utilise TimeSeriesSplit → respecte la chronologie.  
Notebook 2 (GNN) n'applique **pas** Temporal CV visible.
 
**À vérifier** :
- Graphe k-NN est-il refait pour chaque fold?
- Ou construit une seule fois sur données mélangées?
#### 3. **Absence d'Ablation Study**
 
On ne sait pas si la performance vient de :
- La structure du graphe k-NN
- Ou juste des 79 features? (GNN peut utiliser features sans arêtes)
**À faire** : Comparer GNN avec graphe aléatoire.
 
### 🟡 Modéré
 
#### 4. **Hyperparamètres ML par Défaut**
 
XGBoost, LightGBM, etc. utilisent paramètres par défaut.  
GraphSAGE a probablement reçu du tuning.
 
**Biais** : Comparaison pas équitable.
 
#### 5. **Classe LOIC-UDP : 3 exemples**
 
Claim : "GraphSAGE détecte à 100% F1 avec 3 exemples"
 
**Doute** : 
- 3 exemples = 1-2 par fold Temporal CV
- Hard d'avoir F1 = 100% sur 1-2 exemples (sauf si leakage)
- Matrice de confusion sur cette classe?
#### 6. **Pas de Stabilité / Intervalles de Confiance**
 
Résultats rapportés comme points fixes.  
Où sont les barres d'erreur sur 3 folds Temporal CV?
 
### 🟢 Mineur
 
#### 7. **Ensemble Train/Val/Test Implicite**
 
GNN utilise masques train/val/test.  
Comment sont-ils déterminés? Aléatoire? Split temporel?
 
---
 
## Reproduction
 
### Prérequis
 
```bash
# Core
pip install numpy==1.24 pandas==2.0 scikit-learn==1.3.0
 
# ML
pip install xgboost lightgbm
 
# GNN
pip install torch==2.0.1 torch-geometric
 
# Utils
pip install faiss-cpu networkx jupyter
```
 
**Hardware recommandé** :
- Notebook 1 (ML tabulaire) : CPU 4-core, 8 GB RAM → 5-10 min
- Notebook 2 (GNN) : GPU (Colab T4) → 20-30 min | CPU only → 2+ heures
### Lancer les Notebooks
 
```bash
# 1. ML Tabulaires + Temporal CV
jupyter notebook notebooks/01_CICIDS2018_Temporal_CV.ipynb
 
# 2. Construction Graphe + GNN
jupyter notebook notebooks/02_GNN_CICIDS2018_Complete_Execution.ipynb
```
 
### Compiler Rapport
 
```bash
# Windows CMD
compile.bat
 
# Windows PowerShell
./compile.ps1
 
# Linux/Mac
pdflatex -interaction=nonstopmode rapport/Projet_de_synthese_final.tex
```
 
---
 
## Structure du Dépôt
 
```
ml-gnn-intrusion-detection/
│
├── README.md ................................. (ce fichier)
│
├── notebooks/
│   ├── 01_CICIDS2018_Temporal_CV.ipynb
│   │   └─ ML tabulaires + TimeSeriesSplit CV
│   │
│   └── 02_GNN_CICIDS2018_Complete_Execution.ipynb
│       └─ k-NN graph build + GCN/GAT/GraphSAGE training
│
├── rapport/
│   ├── Projet_de_synthese_final.tex ........ Source LaTeX (1470 lignes)
│   ├── Projet_de_synthese_final.pdf ........ Rapport compilé
│   └── includes/ ............................ Figures, tables intégrées
│
├── presentation/
│   ├── presentation_soutenance.tex ......... Beamer source
│   ├── presentation_soutenance.pdf ......... Slides de soutenance
│   ├── Texte_Presentation.txt ............. Script long (~15 min)
│   └── Texte_Presentation_Courte.txt ...... Script court (5 min)
│
├── figures/
│   ├── banner.png .......................... Logo/bannière
│   ├── Screenshot1.png ..................... F1-Score vs Accuracy
│   ├── confusion_xgboost.png ............... Matrice confusion XGBoost
│   ├── confusion_graphsage.png ............. Matrice confusion GraphSAGE
│   └── ... (autres visualizations)
│
├── docs/
│   ├── Features_Noeuds_Aretes.md .......... Documentation technique
│   │   └─ Détail construction k-NN graph
│   │
│   └── METHODOLOGY.md (À CRÉER)
│       └─ Clarification Temporal CV, data leakage
│
├── compile.bat .............................. Script compiltion Windows CMD
├── compile.ps1 .............................. Script compiltion PowerShell
└── .gitignore ............................... Données exclues du repo
```
 
---
 
## Next Steps (Action Items)
 
### Pour valider les résultats
 
- [ ] **Code audit** : Vérifier k-NN construction (train-only ou complet?)
- [ ] **Data leakage check** : Lister edges entre train/test
- [ ] **Temporal CV GNN** : Refaire Notebook 2 avec TimeSeriesSplit par fold
- [ ] **Ablation study** : GNN avec graphe aléatoire vs k-NN
- [ ] **Stabilité** : Rapporter std/intervals pour chaque métrique
### Pour présentation
 
- [ ] Réécrire claims GNN (enlever "+75 F1" sans caveat)
- [ ] Ajouter section "Limitations" à rapport
- [ ] Préparer discours pour soutenance : "Résultats prometteurs MAIS à confirmer"
---
 
## Auteur
 
**Cedric Tanekeu**  
Université du Québec en Outaouais (UQO)  
Département d'Informatique  
Projet de Synthèse — Automne 2025
 
---
 
## Références
 
- Hamilton, W. L., Ying, R., & Leskovec, S. (2017). *Inductive Representation Learning on Large Graphs*. ICML.
- Kipf, T., & Welling, M. (2017). *Semi-Supervised Classification with Graph Convolutional Networks*. ICLR.
- Veličković, P., Cucurull, G., Casanova, A., Romero, A., Liò, P., & Bengio, Y. (2018). *Graph Attention Networks*. ICLR.
- Sharafaldin, I., Lippmann, R. P., & Ghorbani, A. A. (2018). Toward an Operational Machine Learning System for Intrusion Detection. [SSRN](https://ssrn.com/abstract=3513622).
---
 

