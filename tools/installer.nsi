; NSIS installer script for Restaurant CV Analyzer
; Usage: makensis -DINFILE="C:\path\to\dist\restaurant_cv_analyzer_desktop.exe" installer.nsi

!include "MUI2.nsh"

!define APP_NAME "Restaurant CV Analyzer"
!ifndef VERSION
  !define VERSION "0.1.0"
!endif
!ifndef INFILE
  !define INFILE "dist\\restaurant_cv_analyzer_desktop.exe"
!endif
!ifndef APP_EXE_NAME
  !define APP_EXE_NAME "restaurant_cv_analyzer_desktop.exe"
!endif

; Optional icon (absolute or relative path). If provided at compile time, pass -DICON and -DICON_NAME.
!ifdef ICON
  Icon "${ICON}"
!endif

Name "${APP_NAME} ${VERSION}"
OutFile "dist\\${APP_NAME}-${VERSION}-Setup.exe"
InstallDir "$PROGRAMFILES\\${APP_NAME}"
RequestExecutionLevel admin

!insertmacro MUI_HEADER_TEXT "${APP_NAME}" "Installer for ${APP_NAME} v${VERSION}"

Page directory
Page instfiles

Section "Install"
  SetOutPath "$INSTDIR"
  ; include the prebuilt exe file. INFILE should be an absolute or relative path provided at compile time
  File "${INFILE}"
  ; if an ICON was provided, include it so we can use it for the shortcut
  !ifdef ICON
    File "${ICON}"
  !endif

  ; Create Start Menu folder and add a shortcut with the app name and version
  CreateDirectory "$SMPROGRAMS\\${APP_NAME}"
  ; Shortcut name includes version for clarity
  !ifdef ICON_NAME
    CreateShortCut "$SMPROGRAMS\\${APP_NAME}\\${APP_NAME} ${VERSION}.lnk" "$INSTDIR\\${APP_EXE_NAME}" "" "$INSTDIR\\${ICON_NAME}" 0
  !else
    CreateShortCut "$SMPROGRAMS\\${APP_NAME}\\${APP_NAME} ${VERSION}.lnk" "$INSTDIR\\${APP_EXE_NAME}"
  !endif

  WriteUninstaller "$INSTDIR\\Uninstall.exe"
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\\${APP_EXE_NAME}"
  Delete "$SMPROGRAMS\\${APP_NAME}\\${APP_NAME} ${VERSION}.lnk"
  Delete "$INSTDIR\\Uninstall.exe"
  RMDir "$SMPROGRAMS\\${APP_NAME}"
  RMDir "$INSTDIR"
SectionEnd
