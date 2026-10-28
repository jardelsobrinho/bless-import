unit uMensagens;

interface

uses
  Vcl.Dialogs, Vcl.Controls, System.UITypes;

type
  TMensagens = class
  public
    class procedure Info(const AMensagem: string); static;
    class procedure Alerta(const AMensagem: string); static;
    class function Confirmacao(const AMensagem: string): Boolean; static;
  end;

implementation

class procedure TMensagens.Alerta(const AMensagem: string);
begin
  MessageDlg(AMensagem, mtWarning, [mbOK], 0);
end;

class function TMensagens.Confirmacao(const AMensagem: string): Boolean;
begin
  Result := MessageDlg(AMensagem, mtConfirmation, [mbYes, mbNo], 0, mbNo) = mrYes;
end;

class procedure TMensagens.Info(const AMensagem: string);
begin
  MessageDlg(AMensagem, mtInformation, [mbOK], 0);
end;

end.
