unit uFormTabBase;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, uFormBase, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmFormTabBase = class(TfrmFormBase)
    pnlRodape: TPanel;
    btnFechar: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnFecharClick(Sender: TObject);
  end;

var
  frmFormTabBase: TfrmFormTabBase;

implementation

{$R *.dfm}

procedure TfrmFormTabBase.btnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmFormTabBase.FormClose(Sender: TObject; var Action: TCloseAction);
var
  vAba: TTabSheet;
  vPaginas: TPageControl;
  vIndice: Integer;
begin
  // Dentro de uma aba do frmPrincipal: libera a aba (e o form junto) depois que o evento terminar
  if Assigned(Parent) and (Parent is TTabSheet) then
  begin
    vAba := TTabSheet(Parent);
    vPaginas := vAba.PageControl;
    vIndice := vAba.PageIndex;

    // Mostra a aba seguinte; se a fechada era a última, a anterior
    if vIndice < vPaginas.PageCount - 1 then
      vPaginas.ActivePageIndex := vIndice + 1
    else if vIndice > 0 then
      vPaginas.ActivePageIndex := vIndice - 1
    else
      vPaginas.ActivePage := nil;

    TThread.ForceQueue(nil,
      procedure
      begin
        vAba.Free;
      end);
  end;
end;

end.
