unit u_SelectDirectory;

interface

uses FMX.Types;

function SelectDirectory(const ATitle: string; const aHwd:TWindowHandle; var ADir: string): boolean;

implementation

uses
System.SysUtils,
{$IFDEF MSWINDOWS}
FMX.Platform.Win, Winapi.Windows, Winapi.ShellAPI, ComObj, ShlObj, ActiveX;
{$ENDIF MSWINDOWS}
{$IFDEF MACOS}
Macapi.AppKit, Macapi.Foundation, Macapi.ObjectiveC;
{$ENDIF MACOS}
//
{var
 NewPath: string;
  begin
   if SelectDirectory('Please select directory...', NewPath) then
    begin
     edSearchPath.Text := NewPath;
    end;
}
//
{$IFDEF MSWINDOWS}
function BI_CallBack_Proc(hwnd: HWND; uMsg: UINT; lParam: DWORD;
lpData: DWORD): integer; stdcall;
var
PathName: array[0..MAX_PATH] of Char;
begin
case uMsg of
BFFM_INITIALIZED:
SendMessage(Hwnd, BFFM_SETSELECTION, Ord(True), Integer(lpData));
BFFM_SELCHANGED:
begin
SHGetPathFromIDList(PItemIDList(lParam), @PathName);
SendMessage(hwnd, BFFM_SETSTATUSTEXT, 0, Longint(PChar(@PathName)));
end;
end;
Result := 0;
end;
{$ENDIF MSWINDOWS}
//
function SelectDirectory(const ATitle: string; const aHwd:TWindowHandle; var ADir: string): boolean;
{$IFDEF MSWINDOWS}
var
hr: HRESULT;
FormHandle: THandle;
IDList: PItemIDList;
RootIDList: PItemIDList;
Malloc: IMalloc;
lpBuf: LPTSTR;
BI: TBrowseInfo;
sCaption: string;
begin
Result := False;
FormHandle := FMX.Platform.Win.WindowHandleToPlatform(aHwd).Wnd;
ADir := EmptyStr;
if (SHGetMalloc(Malloc) = S_OK) and (Malloc<>nil) then
begin
sCaption := ATitle;
FillChar(BI, SizeOf(BI), 0);
lpBuf := Malloc.Alloc(MAX_PATH);
RootIDList := nil;
SHGetSpecialFolderLocation(FormHandle, CSIDL_DESKTOP, RootIDList);
with BI do
begin
hwndOwner := FormHandle;
pidlRoot := RootIDList;
pszDisplayName := lpBuf;
lpszTitle := PWideChar(sCaption);
ulFlags := BIF_NEWDIALOGSTYLE or BIF_USENEWUI;
lpfn := @BI_CallBack_Proc;
lParam := 0;
iImage := 0;
end;
try
hr := CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
if (hr = S_OK) or (hr = S_FALSE) then
begin
IDList := SHBrowseForFolder(BI);
Result := IDList<>nil;
if Result then
begin
SHGetPathFromIDList(IDList, lpBuf);
ADir := StrPas(lpBuf);
Malloc.Free(RootIDList);
RootIDList := nil;
Malloc.Free(IDList);
IDList := nil;
end;
CoUnInitialize();
end;
finally
Malloc.Free(lpBuf);
end;
end;
{$ENDIF MSWINDOWS}
{$IFDEF MACOS}
var
LOpenDir: NSOpenPanel;
LInitialDir: NSURL;
LDlgResult: Integer;
begin
Result := False;
LOpenDir := TNSOpenPanel.Wrap(TNSOpenPanel.OCClass.openPanel);
LOpenDir.setAllowsMultipleSelection(False);
LOpenDir.setCanChooseFiles(False);
LOpenDir.setCanChooseDirectories(True);
if ADir<>'' then
begin
LInitialDir := TNSURL.Create;
LInitialDir.initFileURLWithPath(NSSTR(ADir));
LOpenDir.setDirectoryURL(LInitialDir);
end;
if ATitle<>'' then
LOpenDir.setTitle(NSSTR(ATitle));
LOpenDir.retain;
try
LDlgResult := LOpenDir.runModal;
if LDlgResult = NSOKButton then
begin
ADir := string(TNSUrl.Wrap(LOpenDir.URLs.objectAtIndex(0)).relativePath.UTF8String);
Result := True;
end;
finally
LOpenDir.release;
end;
{$ENDIF MACOS}
end;

end.
