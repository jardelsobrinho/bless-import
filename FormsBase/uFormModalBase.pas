unit uFormModalBase;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uFormBase, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmFormModalBase = class(TfrmFormBase)
    pnlRodape: TPanel;
    btnFechar: TButton;
  end;

var
  frmFormModalBase: TfrmFormModalBase;

implementation

{$R *.dfm}

end.
