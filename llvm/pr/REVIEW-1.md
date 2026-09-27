# Review-Hilfe: PR llvm/llvm-project#226840 „[SystemZ][z/OS] Keep weak references weak“ (Issue #226835)

Für die Antworten auf Review-Fragen (nach der LLVM-AI-Policy beantwortest du sie selbst).
Der PR entspricht LLVM-Patch 0010 dieses Repos, auf upstream `main` übertragen
(Code dort in `SystemZXPLINKAsmPrinter.cpp` statt `SystemZAsmPrinter.cpp`).

## Worum es geht

`extern_weak` (C: `__attribute__((weak))` bei einer Deklaration, Pascal: `weakexternal`) heißt:
Fehlt das Symbol beim Binden, ist das kein Fehler, die Adresse ist dann 0.

Auf z/OS waren zwei Arten von Referenzen trotzdem immer „stark“:

1. **Adresse einer externen Funktion** (`&f` bzw. `f` als Wert): z/OS nimmt dafür einen
   Funktionsdeskriptor über ein Hilfssymbol `f@indirect` (ein V-Con im ADA, der Binder setzt
   dort den Deskriptor ein). Nur `f` selbst wurde als weak markiert, `f@indirect` nie.
2. **Externe Daten**: Eine Referenz auf eine externe Variable ist im GOFF eine „Part Reference“
   (PR) im WSA. Die PR-Attribute (`GOFF::PRAttr`) hatten gar kein Feld für die Bindungsstärke.

Folge: Der Binder meldet IEW2456E (Symbol unaufgelöst), das Programm wird nicht gebunden.

## Die Änderung (3 Stellen + Test)

- `SystemZXPLINKAsmPrinter.cpp`: Ist das Funktionssymbol weak, bekommt `f@indirect`
  `MCSA_WeakReference` (setzt im GOFF-Symbol „extern + weak“).
- `MCGOFFAttributes.h`: `PRAttr` bekommt `BindingStrength` (Standard: strong, also für alle
  bisherigen Aufrufer unverändert).
- `GOFFObjectWriter.cpp`: PR-Konstruktor schreibt die Bindungsstärke ins Verhaltensattribut
  (Byte 4, gleiche Stelle wie bei ER/LD), `defineExtern` übergibt die des Symbols.
- Test `zos-extern-weak.ll`: HLASM-Ausgabe (`WXTRN wf@indirect`) und Objektbytes (ESD von ER
  und PR mit Bindungsstärke weak).

## Mögliche Fragen

- **„Ist das weak-Attribut beim Ausgeben des ADA schon gesetzt?“** Ja:
  `AsmPrinter::doFinalization` gibt die weak-Referenzen (Schleife über `global_objects` mit
  `hasExternalWeakLinkage`) vor `emitEndOfAsmFile` aus; der ADA wird in `emitEndOfAsmFile`
  geschrieben. Der Test zeigt `WXTRN wf@indirect`.
- **„Akzeptiert der Binder eine weak PR?“** Ja, auf z/OS 3.1 getestet: das C-Programm mit
  `extern int wv __attribute__((weak))` bindet und liefert `&wv == 0`.
- **„Warum nicht gleich `MCSA_Weak`?“** `MCSA_WeakReference` ist das, was AsmPrinter für
  `extern_weak` verwendet; im GOFF-Symbol wirken beide gleich (extern + weak).
- **„Was ist mit dem HLASM-Streamer bei Daten?“** Für die PR schreibt er `CATTR PART(...)`
  ohne Bindungsstärke; das ist unverändert (nur die Objektdatei war das Problem). Wie eine
  schwache Part-Referenz in HLASM aussieht, ist nicht geprüft – falls der Reviewer das
  möchte, nachfragen, wie IBM XL C / Open XL sie im Listing ausgibt.
- **„Warum Test per `od`?“** `llvm-readobj` kann GOFF nicht lesen; andere Tests
  (`zos-symbol-2.ll`, `zos-section-1.ll`) prüfen die Objektbytes genauso.

## Stand

- Lit: `test/CodeGen/SystemZ test/MC/SystemZ test/MC/GOFF` grün (Zahl im PR).
- z/OS 3.1: C-Probe `pf4/weak_c.c` bindet und läuft (`&wv nil, wf nil`); FPC-Test
  `tweaklib2` läuft.
