# Reporte de fallo

## Detailed Analysis

### Crash: NullPointerException en PaymentProcessor

**Información básica:**
- Exception: java.lang.NullPointerException
- Versión: 2.3.4
- Component: UI

### Análisis de stack

```
NullPointerException
  at PaymentProcessor.processPayment(PaymentProcessor.java:45)
  at PaymentFragment.onPayClicked(PaymentFragment.kt:89)
  at android.view.View.performClick(View.java:7124)
```

### Archivos revisados

- `PaymentProcessor.java`: líneas 40-50, author: John Smith, commit: abc123

### Comandos ejecutados

```
git blame origin/master -- PaymentProcessor.java -L 40,50
git log origin/master --oneline -10
```

### Causa raíz

El campo card puede ser null cuando se inicia el pago antes de que termine la validación de la tarjeta. Es un problema de carrera entre validación asincrónica y el clic.

### Corrección propuesta

**Antes:**

```java
String number = card.getNumber();
```

**Después:**

```java
if (card == null) return;
String number = card.getNumber();
```

### Asignado

**John Smith** — git blame línea 45.

### Contexto y prevención

- **Desencadenante**: El usuario toca Pagar antes de validación.
- **Por qué ahora**: Refactor de CardValidator en v2.3.0 hizo asincrónica la validación.
- **Prevención**: Deshabilitar botón hasta validación completa.

## JIRA Brief

**Crash**: NullPointerException
**Component**: UI
**Assignee**: John Smith (git blame: PaymentProcessor.java:45)
**Problem**: Crash al tocar Pagar.
**Stack trace**:
```
at PaymentProcessor.processPayment(PaymentProcessor.java:45)
at PaymentFragment.onPayClicked(PaymentFragment.kt:89)
```
**Cause**: Card null cuando validación incompleta.
**Fix**:
```java
// Before:
String number = card.getNumber();
// After:
if (card == null) return;
String number = card.getNumber();
```
**Reproduction**:
1. Abrir pantalla de pago
2. Tocar Pagar antes de validación
3. App falla
**Firebase**: https://console.firebase.google.com/test
