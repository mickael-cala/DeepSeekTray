; ============================================================================
; Tests unitaires pour la logique métier de DeepSeekTray
; Ce script teste les cas limites sans interface graphique
; ============================================================================

EnableExplicit

; ============================================================================
; Constantes et Types (copiés du projet principal pour isolation des tests)
; ============================================================================

#MAX_TRANCHES = 10

Structure TrancheHoraire
  JourDebut.i
  HeureDebut.i
  JourFin.i
  HeureFin.i
  EstActive.i
EndStructure

; ============================================================================
; Fonctions utilitaires à tester
; ============================================================================

Procedure.i IsValidTimeFormat(TimeStr.s)
  ; Format attendu : HH:MM
  If Len(TimeStr) <> 5
    ProcedureReturn #False
  EndIf
  If Mid(TimeStr, 3, 1) <> ":"
    ProcedureReturn #False
  EndIf
  Protected h.i = Val(Mid(TimeStr, 1, 2))
  Protected m.i = Val(Mid(TimeStr, 4, 2))
  If h >= 0 And h <= 23 And m >= 0 And m <= 59
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.i TimeToMinutes(TimeStr.s)
  Protected h.i = Val(Mid(TimeStr, 1, 2))
  Protected m.i = Val(Mid(TimeStr, 4, 2))
  ProcedureReturn h * 60 + m
EndProcedure

Procedure.i IsWeekday(DayOfWeek.i)
  ; 1 = Lundi, 7 = Dimanche
  If DayOfWeek >= 1 And DayOfWeek <= 5
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.i EstDansTranche(JourTest.i, HeureTestMinutes.i, Tranche.TrancheHoraire)
  ; Cas simple : même jour
  If Tranche\JourDebut = Tranche\JourFin
    If JourTest = Tranche\JourDebut
      If HeureTestMinutes >= Tranche\HeureDebut And HeureTestMinutes <= Tranche\HeureFin
        ProcedureReturn #True
      EndIf
    EndIf
  Else
    ; Cas chevauchement minuit : JourDebut < JourFin (ex: Vendredi 22h -> Samedi 02h)
    ; Ou chevauchement semaine : Dimanche 22h -> Lundi 02h (JourDebut=7, JourFin=1)
    
    ; Si on est le jour de début et après l'heure de début
    If JourTest = Tranche\JourDebut And HeureTestMinutes >= Tranche\HeureDebut
      ProcedureReturn #True
    EndIf
    
    ; Si on est le jour de fin et avant l'heure de fin
    If JourTest = Tranche\JourFin And HeureTestMinutes <= Tranche\HeureFin
      ProcedureReturn #True
    EndIf
    
    ; Cas spécial : chevauchement Dimanche (7) -> Lundi (1)
    If Tranche\JourDebut = 7 And Tranche\JourFin = 1
      If (JourTest = 7 And HeureTestMinutes >= Tranche\HeureDebut) Or (JourTest = 1 And HeureTestMinutes <= Tranche\HeureFin)
        ProcedureReturn #True
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn #False
EndProcedure

; ============================================================================
; Framework de test simple
; ============================================================================

Global TestsReussis.i = 0
Global TestsEchoues.i = 0
Global TotalTests.i = 0

Procedure RunTest(NomTest.s, Condition.i)
  TotalTests + 1
  If Condition
    TestsReussis + 1
    Debug "[PASS] " + NomTest
  Else
    TestsEchoues + 1
    Debug "[FAIL] " + NomTest
  EndIf
EndProcedure

; ============================================================================
; Suite de tests
; ============================================================================

Procedure RunAllTests()
  Debug "============================================================"
  Debug " Démarrage des tests unitaires DeepSeekTray"
  Debug "============================================================"
  Debug ""
  
  ; ---------------------------------------------------------
  ; Tests de validation de format horaire
  ; ---------------------------------------------------------
  Debug "--- Tests IsValidTimeFormat ---"
  RunTest("Format valide 09:30", IsValidTimeFormat("09:30") = #True)
  RunTest("Format valide 23:59", IsValidTimeFormat("23:59") = #True)
  RunTest("Format valide 00:00", IsValidTimeFormat("00:00") = #True)
  RunTest("Format invalide 24:00", IsValidTimeFormat("24:00") = #False)
  RunTest("Format invalide 12:60", IsValidTimeFormat("12:60") = #False)
  RunTest("Format invalide 9:30 (manque 0)", IsValidTimeFormat("9:30") = #False)
  RunTest("Format invalide texte", IsValidTimeFormat("abcde") = #False)
  RunTest("Format invalide vide", IsValidTimeFormat("") = #False)
  Debug ""
  
  ; ---------------------------------------------------------
  ; Tests de conversion temps
  ; ---------------------------------------------------------
  Debug "--- Tests TimeToMinutes ---"
  RunTest("00:00 = 0 min", TimeToMinutes("00:00") = 0)
  RunTest("01:30 = 90 min", TimeToMinutes("01:30") = 90)
  RunTest("23:59 = 1439 min", TimeToMinutes("23:59") = 1439)
  Debug ""
  
  ; ---------------------------------------------------------
  ; Tests jours de la semaine
  ; ---------------------------------------------------------
  Debug "--- Tests IsWeekday ---"
  RunTest("Lundi (1) est weekday", IsWeekday(1) = #True)
  RunTest("Mercredi (3) est weekday", IsWeekday(3) = #True)
  RunTest("Vendredi (5) est weekday", IsWeekday(5) = #True)
  RunTest("Samedi (6) n'est pas weekday", IsWeekday(6) = #False)
  RunTest("Dimanche (7) n'est pas weekday", IsWeekday(7) = #False)
  Debug ""
  
  ; ---------------------------------------------------------
  ; Tests logique métier : Tranches horaires
  ; ---------------------------------------------------------
  Debug "--- Tests EstDansTranche ---"
  
  Protected Tranche1.TrancheHoraire
  Tranche1\JourDebut = 1 ; Lundi
  Tranche1\HeureDebut = TimeToMinutes("09:00") ; 540
  Tranche1\JourFin = 1   ; Lundi
  Tranche1\HeureFin = TimeToMinutes("17:00")   ; 1020
  
  RunTest("Lundi 10:00 dans tranche 09:00-17:00", EstDansTranche(1, 600, Tranche1) = #True)
  RunTest("Lundi 08:00 hors tranche 09:00-17:00", EstDansTranche(1, 480, Tranche1) = #False)
  RunTest("Lundi 18:00 hors tranche 09:00-17:00", EstDansTranche(1, 1080, Tranche1) = #False)
  RunTest("Mardi 10:00 hors tranche Lundi", EstDansTranche(2, 600, Tranche1) = #False)
  
  ; Test chevauchement minuit (Vendredi 22:00 -> Samedi 02:00)
  Protected Tranche2.TrancheHoraire
  Tranche2\JourDebut = 5 ; Vendredi
  Tranche2\HeureDebut = TimeToMinutes("22:00") ; 1320
  Tranche2\JourFin = 6   ; Samedi
  Tranche2\HeureFin = TimeToMinutes("02:00")   ; 120
  
  RunTest("Vendredi 23:00 dans tranche 22:00-02:00", EstDansTranche(5, 1380, Tranche2) = #True)
  RunTest("Samedi 01:00 dans tranche 22:00-02:00", EstDansTranche(6, 60, Tranche2) = #True)
  RunTest("Vendredi 21:00 hors tranche 22:00-02:00", EstDansTranche(5, 1260, Tranche2) = #False)
  RunTest("Samedi 03:00 hors tranche 22:00-02:00", EstDansTranche(6, 180, Tranche2) = #False)
  RunTest("Jeudi 23:00 hors tranche Vendredi-Samedi", EstDansTranche(4, 1380, Tranche2) = #False)
  
  ; Test chevauchement Dimanche -> Lundi
  Protected Tranche3.TrancheHoraire
  Tranche3\JourDebut = 7 ; Dimanche
  Tranche3\HeureDebut = TimeToMinutes("22:00") ; 1320
  Tranche3\JourFin = 1   ; Lundi
  Tranche3\HeureFin = TimeToMinutes("02:00")   ; 120
  
  RunTest("Dimanche 23:00 dans tranche Dim-Lun", EstDansTranche(7, 1380, Tranche3) = #True)
  RunTest("Lundi 01:00 dans tranche Dim-Lun", EstDansTranche(1, 60, Tranche3) = #True)
  RunTest("Samedi 23:00 hors tranche Dim-Lun", EstDansTranche(6, 1380, Tranche3) = #False)
  
  Debug ""
  Debug "============================================================"
  Debug " Résumé des tests"
  Debug "============================================================"
  Debug "Total tests  : " + Str(TotalTests)
  Debug "Réussis      : " + Str(TestsReussis) + " (" + Str(Round(TestsReussis * 100.0 / TotalTests, #PB_Round_Nearest)) + "%)"
  Debug "Échoués      : " + Str(TestsEchoues)
  Debug "============================================================"
  
  If TestsEchoues = 0
    Debug "✓ TOUS LES TESTS SONT PASSÉS AVEC SUCCÈS"
  Else
    Debug "✗ CERTAINS TESTS ONT ÉCHOUÉ - VÉRIFIER LA LOGIQUE"
  EndIf
EndProcedure

; ============================================================================
; Point d'entrée
; ============================================================================

RunAllTests()

; Attendre une touche avant de fermer la console
Input()
