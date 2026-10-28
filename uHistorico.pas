unit uHistorico;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uFormTabBase, Vcl.StdCtrls, Vcl.ExtCtrls, Data.DB, Vcl.Grids,
  Vcl.DBGrids, uHistoricoDm, uPerfisDm;

type
  TfrmHistorico = class(TfrmFormTabBase)
    pnlFiltros: TPanel;
    lblPerfil: TLabel;
    cbxPerfil: TComboBox;
    btnAtualizar: TButton;
    btnRetomar: TButton;
    grdExecucoes: TDBGrid;
    splErros: TSplitter;
    pnlErros: TPanel;
    lblErros: TLabel;
    grdErros: TDBGrid;
    procedure FormCreate(Sender: TObject);
    procedure btnAtualizarClick(Sender: TObject);
    procedure cbxPerfilChange(Sender: TObject);
    procedure btnRetomarClick(Sender: TObject);
    procedure grdExecucoesDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn;
      State: TGridDrawState);
  private
    FDm: TdmHistorico;
    FDmPerfis: TdmPerfis;
    procedure CarregarPerfis;
    function IdPerfilFiltro: Integer;
    procedure AtualizarErros(DataSet: TDataSet);
  end;

var
  frmHistorico: TfrmHistorico;

implementation

{$R *.dfm}

uses
  uMensagens, uPrincipal, uImportacao;

const
  cCOR_ERRO = $00C8C8FF;
  cCOR_AVISO = $00C8F0FF;
  cCOR_OK = $00E3F7E3;

procedure TfrmHistorico.FormCreate(Sender: TObject);
begin
  FDm := TdmHistorico.Create(Self);
  FDmPerfis := TdmPerfis.Create(Self);
  grdExecucoes.DataSource := FDm.dsExecucoes;
  grdErros.DataSource := FDm.dsErros;
  FDm.qryErros.AfterOpen := AtualizarErros;
  CarregarPerfis;
  FDm.Pesquisar(0);
end;

procedure TfrmHistorico.CarregarPerfis;
begin
  cbxPerfil.Items.Clear;
  cbxPerfil.Items.AddObject('(todos os perfis)', TObject(0));
  FDmPerfis.Pesquisar;
  FDmPerfis.qryPerfis.First;
  while not FDmPerfis.qryPerfis.Eof do
  begin
    cbxPerfil.Items.AddObject(FDmPerfis.qryPerfis.FieldByName('NOME').AsString,
      TObject(FDmPerfis.qryPerfis.FieldByName('ID').AsInteger));
    FDmPerfis.qryPerfis.Next;
  end;
  cbxPerfil.ItemIndex := 0;
end;

function TfrmHistorico.IdPerfilFiltro: Integer;
begin
  if cbxPerfil.ItemIndex < 0 then
    Result := 0
  else
    Result := Integer(cbxPerfil.Items.Objects[cbxPerfil.ItemIndex]);
end;

procedure TfrmHistorico.cbxPerfilChange(Sender: TObject);
begin
  FDm.Pesquisar(IdPerfilFiltro);
end;

procedure TfrmHistorico.btnAtualizarClick(Sender: TObject);
begin
  FDm.Pesquisar(IdPerfilFiltro);
end;

procedure TfrmHistorico.AtualizarErros(DataSet: TDataSet);
begin
  if FDm.IdSelecionado = 0 then
    lblErros.Caption := 'Erros'
  else
    lblErros.Caption := Format('Erros da execução %d (%d)', [FDm.IdSelecionado, DataSet.RecordCount]);
end;

procedure TfrmHistorico.grdExecucoesDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer;
  Column: TColumn; State: TGridDrawState);
var
  vStatus: string;
begin
  // Cor pela situação: verde concluída, amarelo com erros, vermelho parada/falha
  if not (gdSelected in State) and (Column.FieldName = 'SITUACAO') then
  begin
    vStatus := FDm.qryExecucoes.FieldByName('STATUS').AsString;
    if vStatus = 'CONCLUIDA' then
      grdExecucoes.Canvas.Brush.Color := cCOR_OK
    else if vStatus = 'CONCLUIDA_COM_ERROS' then
      grdExecucoes.Canvas.Brush.Color := cCOR_AVISO
    else if vStatus <> 'EM_ANDAMENTO' then
      grdExecucoes.Canvas.Brush.Color := cCOR_ERRO;
  end;
  grdExecucoes.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

procedure TfrmHistorico.btnRetomarClick(Sender: TObject);
var
  vDados: TDadosRetomada;
  vForm: TForm;
begin
  vDados := FDm.DadosRetomada;
  if vDados.IdExecucao = 0 then
  begin
    TMensagens.Alerta('Selecione uma execução.');
    Exit;
  end;
  if not StatusRetomavel(vDados.Status) then
  begin
    TMensagens.Alerta('Só dá para retomar uma execução interrompida, cancelada ou que falhou.' + sLineBreak +
      'Para importar de novo uma planilha inteira, use a tela de importação (com "Inserir só os novos" para não ' +
      'duplicar).');
    Exit;
  end;
  // Retomar duas vezes do mesmo ponto gravaria de novo o que a outra retomada já gravou
  if vDados.RetomadaPor > 0 then
  begin
    TMensagens.Alerta(Format('Esta execução já foi retomada pela execução %d. Se ela também parou, retome a %d.',
      [vDados.RetomadaPor, vDados.RetomadaPor]));
    Exit;
  end;
  if (vDados.VersaoAtual <> vDados.VersaoPerfil) and not TMensagens.Confirmacao(Format(
    'O perfil mudou depois desta execução (versão %d, agora %d).' + sLineBreak +
    'A retomada vai usar o perfil atual. Continuar?', [vDados.VersaoPerfil, vDados.VersaoAtual])) then
    Exit;

  vForm := frmPrincipal.AbrirFormEmAba(TfrmImportacao);
  (vForm as TfrmImportacao).PrepararRetomada(vDados.IdExecucao, vDados.IdPerfil, vDados.Arquivo,
    vDados.LinhaInicio);
end;

end.
