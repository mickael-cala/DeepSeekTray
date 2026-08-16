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
      PreferenceComment(" Heures de pointe UTC (HH:MM-HH:MM en 24h, Max " + Str(#MAX_TRANCHES) + " tranches)")
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
  ; Ajout du drapeau #PB_Window_ScreenCentered pour centrer automatiquement
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
  
  ; Plus besoin de calculer la position, la fenêtre est déjà centrée !
  HideWindow(#WinToast, #False)
  StickyWindow(#WinToast, #True)
  
  AddWindowTimer(#WinMain, #TimerToast, 7000)
EndProcedure

; ==========================================
; MOTEUR PRINCIPAL
; ==========================================

Procedure UpdateStatus()
  Protected st.SYSTEMTIME
  Protected currentMins.l, day.l, i.l, offset.l
  Protected startB.l, endB.l
  Protected isPeak.b = #False
  Protected minToChange.l = 999999
  Protected nextIsStart.b = #False
  
  GetSystemTime_(@st) 
  currentMins = st\wHour * 60 + st\wMinute
  
  For day = 0 To 1
    offset = day * 1440
    For i = 0 To NbTranches - 1
      startB = Slots(i)\StartMin + offset
      endB = Slots(i)\EndMin + offset
      
      If day = 0 And currentMins >= Slots(i)\StartMin And currentMins < Slots(i)\EndMin
        isPeak = #True
      EndIf
      
      If startB > currentMins And (startB - currentMins) < minToChange
        minToChange = startB - currentMins
        nextIsStart = #True
      EndIf
      If endB > currentMins And (endB - currentMins) < minToChange
        minToChange = endB - currentMins
        nextIsStart = #False
      EndIf
    Next
  Next
  
  Protected hRestant = minToChange / 60
  Protected mRestant = minToChange % 60
  TempsRestant = Str(hRestant) + "h" + RSet(Str(mRestant), 2, "0")
  Protected Tooltip.s
  
  If isPeak
    EtatActuel = "POINTE"
    Tooltip = "DeepSeek: POINTE | Fin dans " + TempsRestant
    ChangeSysTrayIcon(TrayID, ImageID(ImgPleine))
  Else
    EtatActuel = "HORS POINTE"
    Tooltip = "DeepSeek: HORS POINTE | Début dans " + TempsRestant
    ChangeSysTrayIcon(TrayID, ImageID(ImgCreuse))
  EndIf
  
  SysTrayIconToolTip(TrayID, Tooltip)
  
  If isPeak = #False And nextIsStart = #True And minToChange = 5
    If AlertFired = #False
      ShowToast("Alerte Tarif DeepSeek", "Passage en tarif POINTE dans 5 minutes !")
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
    MenuItem(40 + i, "  • " + strStart + " à " + strEnd) : DisableMenuItem(0, 40 + i, 1)
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
; CursorPosition = 283
; FirstLine = 272
; Folding = --
; EnableXP
; DPIAware
; UseIcon = icon.ico
; Executable = DeepSeekTray.exe
; DisableDebugger