unit uPerfis;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uFormTabBase, Vcl.StdCtrls, Vcl.ExtCtrls, Data.DB, Vcl.Grids,
  Vcl.DBGrids, uPerfisDm;

type
  TfrmPerfis = class(TfrmFormTabBase)
    pnlBotoes: TPanel;
    btnNovo: TButton;
    btnEditar: TButton;
    btnDuplicar: TButton;
    btnExcluir: TButton;
    grdPerfis: TDBGrid;
    procedure FormCreate(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnDuplicarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure grdPerfisDblClick(Sender: TObject);
  private
    FDm: TdmPerfis;
    function PerfilSelecionado: Boolean;
  end;

var
  frmPerfis: TfrmPerfis;

implementation

{$R *.dfm}

uses
  uPerfilEdicao, uMensagens;

procedure TfrmPerfis.FormCreate(Sender: TObject);
begin
  FDm := TdmPerfis.Create(Self);
  grdPerfis.DataSource := FDm.dsPerfis;
  FDm.Pesquisar;
end;

function TfrmPerfis.PerfilSelecionado: Boolean;
begin
  Result := FDm.IdSelecionado > 0;
  if not Result then
    TMensagens.Alerta('Selecione um perfil.');
end;

procedure TfrmPerfis.btnNovoClick(Sender: TObject);
begin
  TfrmPerfilEdicao.Editar(FDm, 0);
end;

procedure TfrmPerfis.btnEditarClick(Sender: TObject);
begin
  if PerfilSelecionado then
    TfrmPerfilEdicao.Editar(FDm, FDm.IdSelecionado);
end;

procedure TfrmPerfis.btnDuplicarClick(Sender: TObject);
var
  vNovoId: Integer;
begin
  if not PerfilSelecionado then
    Exit;

  vNovoId := FDm.Duplicar(FDm.IdSelecionado);
  TMensagens.Info('Perfil duplicado como "' + FDm.qryPerfis.FieldByName('NOME').AsString + '".');
  if TMensagens.Confirmacao('Deseja editar a cópia agora?') then
    TfrmPerfilEdicao.Editar(FDm, vNovoId);
end;

procedure TfrmPerfis.btnExcluirClick(Sender: TObject);
begin
  if not PerfilSelecionado then
    Exit;

  if TMensagens.Confirmacao('Excluir o perfil "' + FDm.qryPerfis.FieldByName('NOME').AsString +
    '" e todo o seu mapeamento?') then
    FDm.Excluir(FDm.IdSelecionado);
end;

procedure TfrmPerfis.grdPerfisDblClick(Sender: TObject);
begin
  btnEditar.Click;
end;

end.
