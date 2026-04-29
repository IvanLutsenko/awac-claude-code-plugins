# Rapport de plantage

## Detailed Analysis

### Crash: NullPointerException dans PaymentProcessor

**Informations de base:**
- Exception: java.lang.NullPointerException
- Version: 2.3.4
- Component: UI

### Analyse de pile

```
NullPointerException
  at PaymentProcessor.processPayment(PaymentProcessor.java:45)
  at PaymentFragment.onPayClicked(PaymentFragment.kt:89)
  at android.view.View.performClick(View.java:7124)
```

### Fichiers vérifiés

- `PaymentProcessor.java`: lignes 40-50, author: John Smith, commit: abc123

### Commandes exécutées

```
git blame origin/master -- PaymentProcessor.java -L 40,50
git log origin/master --oneline -10
```

### Cause racine

Le champ card peut être null si le paiement démarre avant la fin de la validation. Race condition entre validation asynchrone et clic.

### Correctif proposé

**Avant:**

```java
String number = card.getNumber();
```

**Après:**

```java
if (card == null) return;
String number = card.getNumber();
```

### Assigné

**John Smith** — git blame ligne 45.

### Contexte & Prévention

- **Déclencheur**: L'utilisateur tape Payer avant fin de validation.
- **Pourquoi maintenant**: Refactor CardValidator en v2.3.0 a rendu la validation asynchrone.
- **Prévention**: Désactiver le bouton Payer jusqu'à la fin de validation.

## JIRA Brief

**Crash**: NullPointerException
**Component**: UI
**Assignee**: John Smith (git blame: PaymentProcessor.java:45)
**Problem**: Plantage au tap sur Payer.
**Stack trace**:
```
at PaymentProcessor.processPayment(PaymentProcessor.java:45)
at PaymentFragment.onPayClicked(PaymentFragment.kt:89)
```
**Cause**: Card null quand validation incomplète.
**Fix**:
```java
// Before:
String number = card.getNumber();
// After:
if (card == null) return;
String number = card.getNumber();
```
**Reproduction**:
1. Ouvrir l'écran de paiement
2. Taper Payer avant validation
3. L'app plante
**Firebase**: https://console.firebase.google.com/test
