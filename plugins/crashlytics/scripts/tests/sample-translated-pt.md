# Relatório de queda

## Detailed Analysis

### Crash: NullPointerException em PaymentProcessor

**Informações básicas:**
- Exception: java.lang.NullPointerException
- Versão: 2.3.4
- Component: UI

### Rastreio de pilha

```
NullPointerException
  at PaymentProcessor.processPayment(PaymentProcessor.java:45)
  at PaymentFragment.onPayClicked(PaymentFragment.kt:89)
  at android.view.View.performClick(View.java:7124)
```

### Arquivos verificados

- `PaymentProcessor.java`: linhas 40-50, author: John Smith, commit: abc123

### Comandos executados

```
git blame origin/master -- PaymentProcessor.java -L 40,50
git log origin/master --oneline -10
```

### Causa raiz

O campo card pode ser null quando o pagamento inicia antes da validação. Race condition entre validação assíncrona e clique.

### Correção proposta

**Antes:**

```java
String number = card.getNumber();
```

**Depois:**

```java
if (card == null) return;
String number = card.getNumber();
```

### Responsável

**John Smith** — git blame linha 45.

### Contexto & Prevenção

- **Gatilho**: Usuário toca Pagar antes do término da validação.
- **Por que agora**: Refactor CardValidator em v2.3.0 tornou validação assíncrona.
- **Prevenção**: Desabilitar botão Pagar até validação completa.

## JIRA Brief

**Crash**: NullPointerException
**Component**: UI
**Assignee**: John Smith (git blame: PaymentProcessor.java:45)
**Problem**: Queda ao tocar Pagar.
**Stack trace**:
```
at PaymentProcessor.processPayment(PaymentProcessor.java:45)
at PaymentFragment.onPayClicked(PaymentFragment.kt:89)
```
**Cause**: Card null quando validação incompleta.
**Fix**:
```java
// Before:
String number = card.getNumber();
// After:
if (card == null) return;
String number = card.getNumber();
```
**Reproduction**:
1. Abrir tela de pagamento
2. Tocar Pagar antes da validação
3. App quebra
**Firebase**: https://console.firebase.google.com/test
