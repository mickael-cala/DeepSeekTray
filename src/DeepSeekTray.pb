EnableExplicit

; ==========================================
; CONSTANTES & GLOBALES
; ==========================================
#URL_CONSO = "https://platform.deepseek.com/usage"
#MAX_TRANCHES = 10 ; Sécurité : Prévention DoS local

Enumeration Windows
  #WinMain
  #WinToast
EndEnumeration

Enumeration Gadgets
  #TxtToastTitle
  #TxtToastMsg
EndEnumeration

Enumeration Timers
  #TimerMain = 1
  #TimerToast = 2
EndEnumeration

Global ImgPleine, ImgCreuse, TrayID = 1
Global AlertFired.b = #False
Global NbTranches = 0
Global EtatActuel.s, TempsRestant.s
Global FontIcon = LoadFont(#PB_Any, "Arial", 9, #PB_Font_Bold)
Global FontToastBold = LoadFont(#PB_Any, "Segoe UI", 10, #PB_Font_Bold)
Global FontToastReg = LoadFont(#PB_Any, "Segoe UI", 9)

Structure PeakSlot
  StartMin.l
  EndMin.l
EndStructure

Global Dim Slots.PeakSlot(0)

; ==========================================
; FONCTIONS UTILITAIRES (PARANO / UX)
; ==========================================

Procedure.s FormatAMPM(Heure.l, Minute.l)
  Protected ampm.s = "AM", h.l = Heure
  If h >= 12
    ampm = "PM"
    If h > 12 : h - 12 : EndIf
  EndIf
  If h = 0 : h = 12 : EndIf
  ProcedureReturn RSet(Str(h), 2, "0") + ":" + RSet(Str(Minute), 2, "0") + " " + ampm
EndProcedure

Procedure.b IsValidTimeFormat(t.s)
  If Len(t) <> 5 : ProcedureReturn #False : EndIf
  If Mid(t, 3, 1) <> ":" : ProcedureReturn #False : EndIf
  Protected h = Val(Left(t, 2)), m = Val(Right(t, 2))
  If h < 0 Or h > 23 : ProcedureReturn #False : EndIf
  If m < 0 Or m > 59 : ProcedureReturn #False : EndIf
  ProcedureReturn #True
EndProcedure

; Nouvelle fonction : retourne #True si le jour est un jour de semaine (Lun-Ven)
; wDayOfWeek : 0=Dimanche, 1=Lundi, ..., 6=Samedi
Procedure.b IsWeekday(dayOfWeek.l)
  If dayOfWeek >= 1 And dayOfWeek <= 5
    ProcedureReturn #True
  Else
    ProcedureReturn #False
  EndIf
EndProcedure

; ==========================================
; CHARGEMENT SÉCURISÉ (APPDATA)
; ==========================================

Procedure LoadConfig()
  Protected AppDir.s = GetUserDirectory(#PB_Directory_ProgramData) + "DeepSeekTray\"
  If FileSize(AppDir) <> -2 : CreateDirectory(AppDir) : EndIf
  Protected fichier$ = AppDir + "tarifs.ini"
  Protected timeStr$, startStr$, endStr$
  
  If FileSize(fichier$) < 0
    If CreatePreferences(fichier$)
      PreferenceGroup("Horaires_Pointe_UTC")
      PreferenceComment(" Heures de pointe UTC (HH:MM-HH:MM en 24h, Max " + Str(#MAX_TRANCHES) + " tranches) - Applicables uniquement du lundi au vendredi")
      WritePreferenceString("Tranche1", "01:00-04:00")
      WritePreferenceString("Tranche2", "06:00-10:00")
      ClosePreferences()
    EndIf
  EndIf
  
  If OpenPreferences(fichier$)
    PreferenceGroup("Horaires_Pointe_UTC")
    ExaminePreferenceKeys()
    
    NbTranches = 0
    While NextPreferenceKey() And NbTranches < #MAX_TRANCHES
      timeStr$ = PreferenceKeyValue()
      startStr$ = Trim(StringField(timeStr$, 1, "-"))
      endStr$ = Trim(StringField(timeStr$, 2, "-"))
      
      If IsValidTimeFormat(startStr$) And IsValidTimeFormat(endStr$)
        ReDim Slots(NbTranches)
        Slots(NbTranches)\StartMin = Val(StringField(startStr$, 1, ":")) * 60 + Val(StringField(startStr$, 2, ":"))
        Slots(NbTranches)\EndMin = Val(StringField(endStr$, 1, ":")) * 60 + Val(StringField(endStr$, 2, ":"))
        NbTranches + 1
      EndIf
    Wend
    ClosePreferences()
  EndIf
EndProcedure

; ==========================================
; CRÉATION VISUELLE (ACCESSIBILITÉ)
; ==========================================

Procedure CreateIcons()
  ImgPleine = CreateImage(#PB_Any, 16, 16, 32, $00000000)
  StartDrawing(ImageOutput(ImgPleine))
    DrawingMode(#PB_2DDrawing_AlphaBlend | #PB_2DDrawing_Transparent)
    Circle(8, 8, 7, $FF0000FF)
    DrawingFont(FontID(FontIcon))
    DrawText(6, 1, "!", $FFFFFFFF)
  StopDrawing()
  
  ImgCreuse = CreateImage(#PB_Any, 16, 16, 32, $00000000)
  StartDrawing(ImageOutput(ImgCreuse))
    DrawingMode(#PB_2DDrawing_AlphaBlend | #PB_2DDrawing_Transparent)
    Circle(8, 8, 7, $FF00C800)
    DrawingFont(FontID(FontIcon))
    DrawText(4, 1, "$", $FFFFFFFF)
  StopDrawing()
EndProcedure

; ==========================================
; FENÊTRE TOAST (ALERTE AU CENTRE)
; ==========================================

Procedure SetupToastWindow()
  OpenWindow(#WinToast, 0, 0, 320, 80, "", #PB_Window_BorderLess | #PB_Window_Tool | #PB_Window_Invisible | #PB_Window_ScreenCentered)
  SetWindowColor(#WinToast, $2D2D2D)
  
  TextGadget(#TxtToastTitle, 15, 15, 290, 20, "Alerte DeepSeek", #PB_Text_Center)
  SetGadgetColor(#TxtToastTitle, #PB_Gadget_BackColor, $2D2D2D)
  SetGadgetColor(#TxtToastTitle, #PB_Gadget_FrontColor, $00A8FF)
  SetGadgetFont(#TxtToastTitle, FontID(FontToastBold))
  
  TextGadget(#TxtToastMsg, 15, 40, 290, 20, "Passage en tarif POINTE dans 5 minutes !", #PB_Text_Center)
  SetGadgetColor(#TxtToastMsg, #PB_Gadget_BackColor, $2D2D2D)
  SetGadgetColor(#TxtToastMsg, #PB_Gadget_FrontColor, $FFFFFF)
  SetGadgetFont(#TxtToastMsg, FontID(FontToastReg))
EndProcedure

Procedure ShowToast(Title.s, Message.s)
  SetGadgetText(#TxtToastTitle, Title)
  SetGadgetText(#TxtToastMsg, Message)
  
  HideWindow(#WinToast, #False)
  StickyWindow(#WinToast, #True)
  
  AddWindowTimer(#WinMain, #TimerToast, 7000)
EndProcedure

; ==========================================
; MOTEUR PRINCIPAL (ADAPTÉ AU NOUVEAU TARIF)
; ==========================================

Procedure UpdateStatus()
  Protected st.SYSTEMTIME
  Protected currentMins.l, dayOfWeek.l, i.l, offset.l
  Protected startB.l, endB.l
  Protected isPeak.b = #False
  Protected minToChange.l = 999999
  Protected nextIsStart.b = #False
  Protected tempMin.l, currentDay.l, targetDay.l
  
  GetSystemTime_(@st)
  currentMins = st\wHour * 60 + st\wMinute
  dayOfWeek = st\wDayOfWeek   ; 0=Dim, 1=Lun, ..., 6=Sam
  
  ; ---- Déterminer si on est actuellement en pointe ----
  If IsWeekday(dayOfWeek)
    For i = 0 To NbTranches - 1
      ; Gestion des tranches qui passent minuit : on les découpe en deux
      If Slots(i)\StartMin < Slots(i)\EndMin
        ; Tranche normale (ex: 01:00-04:00)
        If currentMins >= Slots(i)\StartMin And currentMins < Slots(i)\EndMin
          isPeak = #True
          Break
        EndIf
      Else
        ; Tranche chevauchant minuit (ex: 22:00-02:00) -> on vérifie [start, 1440) ou [0, end)
        If currentMins >= Slots(i)\StartMin Or currentMins < Slots(i)\EndMin
          isPeak = #True
          Break
        EndIf
      EndIf
    Next
  Else
    isPeak = #False  ; Week-end : toujours hors pointe
  EndIf
  
  ; ---- Calcul du prochain changement (sur 7 jours) ----
  For offset = 0 To 6
    currentDay = (dayOfWeek + offset) % 7
    If Not IsWeekday(currentDay)
      Continue ; ce jour n'a pas de tranches de pointe -> on ignore
    EndIf
    
    For i = 0 To NbTranches - 1
      ; On traite les tranches normales et celles qui chevauchent minuit
      ; Pour simplifier, on considère que chaque tranche a un début et une fin
      ; Si StartMin < EndMin : une seule intervalle [start, end)
      ; Sinon : deux intervalles [start, 1440) et [0, end)
      
      ; Intervalle 1 : [start, end) si start < end, sinon [start, 1440)
      startB = Slots(i)\StartMin + offset * 1440
      If Slots(i)\StartMin < Slots(i)\EndMin
        endB = Slots(i)\EndMin + offset * 1440
      Else
        endB = (offset + 1) * 1440   ; fin de la journée
      EndIf
      
      ; On ne garde que les événements futurs par rapport à currentMins (jour 0)
      If startB > currentMins And (startB - currentMins) < minToChange
        minToChange = startB - currentMins
        nextIsStart = #True
      EndIf
      If endB > currentMins And (endB - currentMins) < minToChange
        minToChange = endB - currentMins
        nextIsStart = #False
      EndIf
      
      ; Si la tranche chevauche minuit, on a aussi l'intervalle [0, end) du lendemain
      If Slots(i)\StartMin >= Slots(i)\EndMin
        startB = (offset + 1) * 1440   ; début du jour suivant (0)
        endB = Slots(i)\EndMin + (offset + 1) * 1440
        If startB > currentMins And (startB - currentMins) < minToChange
          minToChange = startB - currentMins
          nextIsStart = #True
        EndIf
        If endB > currentMins And (endB - currentMins) < minToChange
          minToChange = endB - currentMins
          nextIsStart = #False
        EndIf
      EndIf
    Next
  Next
  
  ; Cas où aucun changement n'est trouvé (normalement pas possible)
  If minToChange = 999999
    minToChange = 0
    nextIsStart = #False
  EndIf
  
  Protected hRestant = minToChange / 60
  Protected mRestant = minToChange % 60
  TempsRestant = Str(hRestant) + "h" + RSet(Str(mRestant), 2, "0")
  Protected Tooltip.s
  
  If isPeak
    EtatActuel = "POINTE (x2)"
    Tooltip = "DeepSeek: POINTE (x2) | Fin dans " + TempsRestant
    ChangeSysTrayIcon(TrayID, ImageID(ImgPleine))
  Else
    EtatActuel = "HORS POINTE (x0.5)"
    Tooltip = "DeepSeek: HORS POINTE (x0.5) | Début dans " + TempsRestant
    ChangeSysTrayIcon(TrayID, ImageID(ImgCreuse))
  EndIf
  
  SysTrayIconToolTip(TrayID, Tooltip)
  
  ; Alerte 5 minutes avant le début de la pointe (uniquement si on est hors pointe et que le prochain événement est un début)
  If isPeak = #False And nextIsStart = #True And minToChange = 5
    If AlertFired = #False
      ShowToast("Alerte Tarif DeepSeek", "Passage en tarif POINTE (x2) dans 5 minutes !")
      AlertFired = #True
    EndIf
  ElseIf minToChange <> 5
    AlertFired = #False
  EndIf
EndProcedure

Procedure ShowMenu(hWnd)
  Protected st.SYSTEMTIME
  GetSystemTime_(@st)
  
  If IsMenu(0) : FreeMenu(0) : EndIf
  
  CreatePopupMenu(0)
  MenuItem(10, "Statut : " + EtatActuel) : DisableMenuItem(0, 10, 1)
  MenuItem(11, "Heure UTC : " + FormatAMPM(st\wHour, st\wMinute)) : DisableMenuItem(0, 11, 1)
  MenuItem(12, "Prochain changement : " + TempsRestant) : DisableMenuItem(0, 12, 1)
  MenuBar()
  
  MenuItem(15, "--- Horaires de Pointe (" + Str(NbTranches) + "/" + Str(#MAX_TRANCHES) + ") ---") : DisableMenuItem(0, 15, 1)
  Protected i.l, strStart.s, strEnd.s
  For i = 0 To NbTranches - 1
    strStart = FormatAMPM(Slots(i)\StartMin / 60, Slots(i)\StartMin % 60)
    strEnd   = FormatAMPM(Slots(i)\EndMin / 60, Slots(i)\EndMin % 60)
    MenuItem(40 + i, "  • " + strStart + " à " + strEnd + " (UTC, Lun-Ven)") : DisableMenuItem(0, 40 + i, 1)
  Next
  
  MenuBar()
  MenuItem(1, "Ouvrir tarifs.ini")
  MenuItem(2, "🔄 Actualiser (Recharge tarifs)")
  MenuBar()
  MenuItem(3, "❌ Quitter")
  
  DisplayPopupMenu(0, hWnd)
EndProcedure

; ==========================================
; DÉMARRAGE & BOUCLE PRINCIPALE
; ==========================================
LoadConfig()
CreateIcons()

OpenWindow(#WinMain, 0, 0, 10, 10, "DeepSeek Tray", #PB_Window_Invisible)
SetupToastWindow()

AddSysTrayIcon(TrayID, WindowID(#WinMain), ImageID(ImgCreuse))
UpdateStatus()

AddWindowTimer(#WinMain, #TimerMain, 5000)

Define Event

Repeat
  Event = WaitWindowEvent()
  
  If Event = #PB_Event_Timer
    If EventTimer() = #TimerMain
      UpdateStatus()
    ElseIf EventTimer() = #TimerToast
      HideWindow(#WinToast, #True)
      RemoveWindowTimer(#WinMain, #TimerToast)
    EndIf
  EndIf
  
  If Event = #PB_Event_SysTray
    If EventType() = #PB_EventType_LeftClick
      RunProgram(#URL_CONSO)
    ElseIf EventType() = #PB_EventType_RightClick
      ShowMenu(WindowID(#WinMain))
    EndIf
  EndIf
  
  If Event = #PB_Event_Menu
    Select EventMenu()
      Case 1
        RunProgram("explorer.exe", Chr(34) + GetUserDirectory(#PB_Directory_ProgramData) + "DeepSeekTray\" + Chr(34), "")
      Case 2
        LoadConfig()
        UpdateStatus()
        ShowToast("Mise à jour", "La configuration a été rechargée avec succès.")
      Case 3
        Break
    EndSelect
  EndIf
  
  If Event = #PB_Event_LeftClick And EventWindow() = #WinToast
    HideWindow(#WinToast, #True)
    RemoveWindowTimer(#WinMain, #TimerToast)
  EndIf

Until Event = #PB_Event_CloseWindow

RemoveSysTrayIcon(TrayID)
End

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 370
; Folding = --
; EnableXP
; DPIAware
; UseIcon = icon.ico
; Executable = DeepSeekTray.exe
; DisableDebugger