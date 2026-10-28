unit uConexoes;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uFormTabBase, Vcl.StdCtrls, Vcl.ExtCtrls, Data.DB, Vcl.Grids,
  Vcl.DBGrids, uConexoesDm;

type
  TfrmConexoes = class(TfrmFormTabBase)
    pnlBotoes: TPanel;
    btnNovo: TButton;
    btnEditar: TButton;
    btnExcluir: TButton;
    btnTestar: TButton;
    grdConexoes: TDBGrid;
    procedure FormCreate(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure btnTestarClick(Sender: TObject);
    procedure grdConexoesDblClick(Sender: TObject);
  private
    FDm: TdmConexoes;
    function ConexaoSelecionada: Boolean;
  end;

var
  frmConexoes: TfrmConexoes;

implementation

{$R *.dfm}

uses
  uConexaoDados, uConexaoEdicao, uMensagens;

procedure TfrmConexoes.FormCreate(Sender: TObject);
begin
  FDm := TdmConexoes.Create(Self);
  grdConexoes.DataSource := FDm.dsConexoes;
  FDm.Pesquisar;
end;

function TfrmConexoes.ConexaoSelecionada: Boolean;
begin
  Result := FDm.IdSelecionado > 0;
  if not Result then
    TMensagens.Alerta('Selecione uma conexão.');
end;

procedure TfrmConexoes.btnNovoClick(Sender: TObject);
var
  vDados: TConexaoDados;
begin
  vDados := TConexaoDados.Novo;
  TfrmConexaoEdicao.Editar(FDm, vDados);
end;

procedure TfrmConexoes.btnEditarClick(Sender: TObject);
var
  vDados: TConexaoDados;
begin
  if not ConexaoSelecionada then
    Exit;

  vDados := FDm.Carregar(FDm.IdSelecionado);
  TfrmConexaoEdicao.Editar(FDm, vDados);
end;

procedure TfrmConexoes.btnExcluirClick(Sender: TObject);
begin
  if not ConexaoSelecionada then
    Exit;

  if TMensagens.Confirmacao('Excluir a conexão "' + FDm.qryConexoes.FieldByName('NOME').AsString + '"?') then
    FDm.Excluir(FDm.IdSelecionado);
end;

procedure TfrmConexoes.btnTestarClick(Sender: TObject);
begin
  if not ConexaoSelecionada then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    try
      TestarConexao(FDm.Carregar(FDm.IdSelecionado));
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        TMensagens.Alerta('Falha ao conectar:' + sLineBreak + sLineBreak + E.Message);
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  TMensagens.Info('Conexão realizada com sucesso.');
end;

procedure TfrmConexoes.grdConexoesDblClick(Sender: TObject);
begin
  btnEditar.Click;
end;

end.
