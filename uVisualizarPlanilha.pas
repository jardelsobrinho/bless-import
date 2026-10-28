unit uVisualizarPlanilha;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uFormTabBase, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.ComCtrls,
  uLeitorXls;

type
  TfrmVisualizarPlanilha = class(TfrmFormTabBase)
    pnlFiltros: TPanel;
    btnAbrir: TButton;
    lblArquivo: TLabel;
    lblAba: TLabel;
    cbxAba: TComboBox;
    lblLinhaCabecalho: TLabel;
    edtLinhaCabecalho: TEdit;
    udLinhaCabecalho: TUpDown;
    lblLinhaInicial: TLabel;
    edtLinhaInicial: TEdit;
    udLinhaInicial: TUpDown;
    btnAtualizar: TButton;
    lblResumo: TLabel;
    grdColunas: TStringGrid;
    splColunas: TSplitter;
    grdDados: TStringGrid;
    dlgAbrir: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAbrirClick(Sender: TObject);
    procedure cbxAbaChange(Sender: TObject);
    procedure btnAtualizarClick(Sender: TObject);
  private
    FLeitor: TLeitorXls;
    procedure LimparGrade(AGrade: TStringGrid);
    procedure Atualizar;
    procedure PreencherColunas;
    procedure PreencherDados;
  end;

var
  frmVisualizarPlanilha: TfrmVisualizarPlanilha;

implementation

{$R *.dfm}

uses
  System.Diagnostics, uMensagens;

const
  cLINHAS_PREVIA = 200;

procedure TfrmVisualizarPlanilha.FormCreate(Sender: TObject);
begin
  FLeitor := TLeitorXls.Create;
  LimparGrade(grdColunas);
  LimparGrade(grdDados);
end;

procedure TfrmVisualizarPlanilha.FormDestroy(Sender: TObject);
begin
  FLeitor.Free;
end;

procedure TfrmVisualizarPlanilha.LimparGrade(AGrade: TStringGrid);
var
  i: Integer;
begin
  for i := 0 to AGrade.RowCount - 1 do
    AGrade.Rows[i].Clear;
  AGrade.RowCount := 2;
end;

procedure TfrmVisualizarPlanilha.btnAbrirClick(Sender: TObject);
var
  vCronometro: TStopwatch;
begin
  if not dlgAbrir.Execute then
    Exit;

  // Sem threads: a tela fica parada durante a leitura (planilhas grandes podem levar mais de 1 minuto)
  lblResumo.Caption := 'Carregando planilha, aguarde...';
  lblResumo.Update;
  Screen.Cursor := crHourGlass;
  try
    vCronometro := TStopwatch.StartNew;
    try
      FLeitor.Abrir(dlgAbrir.FileName);
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        lblResumo.Caption := '';
        lblArquivo.Caption := '';
        cbxAba.Clear;
        LimparGrade(grdColunas);
        LimparGrade(grdDados);
        TMensagens.Alerta(E.Message);
        Exit;
      end;
    end;
    vCronometro.Stop;

    lblArquivo.Caption := FLeitor.Arquivo;
    cbxAba.Items.Clear;
    cbxAba.Items.AddStrings(FLeitor.Abas);
    cbxAba.ItemIndex := 0;
    Atualizar;
    lblResumo.Caption := lblResumo.Caption + Format('   |   aberta em %.1f s', [vCronometro.ElapsedMilliseconds / 1000]);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmVisualizarPlanilha.cbxAbaChange(Sender: TObject);
begin
  if FLeitor.Arquivo = '' then
    Exit;
  FLeitor.SelecionarAba(cbxAba.ItemIndex);
  Atualizar;
end;

procedure TfrmVisualizarPlanilha.btnAtualizarClick(Sender: TObject);
begin
  if FLeitor.Arquivo = '' then
  begin
    TMensagens.Alerta('Abra uma planilha.');
    Exit;
  end;
  Atualizar;
end;

procedure TfrmVisualizarPlanilha.Atualizar;
begin
  if (udLinhaCabecalho.Position > 0) and (udLinhaInicial.Position <= udLinhaCabecalho.Position) then
  begin
    TMensagens.Alerta('A linha inicial dos dados deve ficar depois da linha do cabeçalho.');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    FLeitor.LinhaCabecalho := udLinhaCabecalho.Position;
    FLeitor.LinhaInicial := udLinhaInicial.Position;
    PreencherColunas;
    PreencherDados;
    lblResumo.Caption := Format('Linhas de dados: %d   |   Colunas: %d',
      [FLeitor.UltimaLinha - FLeitor.LinhaInicial + 1, FLeitor.QuantidadeColunas]);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmVisualizarPlanilha.PreencherColunas;
var
  vColunas: TArray<TColunaPlanilha>;
  i: Integer;
begin
  LimparGrade(grdColunas);
  vColunas := FLeitor.Colunas;

  grdColunas.ColCount := 4;
  grdColunas.Cells[0, 0] := 'Col.';
  grdColunas.Cells[1, 0] := 'Nome';
  grdColunas.Cells[2, 0] := 'Tipo';
  grdColunas.Cells[3, 0] := 'Exemplo';
  grdColunas.RowCount := Length(vColunas) + 1;
  if Length(vColunas) = 0 then
    grdColunas.RowCount := 2;

  for i := 0 to High(vColunas) do
  begin
    grdColunas.Cells[0, i + 1] := vColunas[i].Letra;
    grdColunas.Cells[1, i + 1] := vColunas[i].Nome;
    grdColunas.Cells[2, i + 1] := vColunas[i].Tipo;
    grdColunas.Cells[3, i + 1] := vColunas[i].Exemplo;
  end;
end;

procedure TfrmVisualizarPlanilha.PreencherDados;
var
  vColunas: TArray<TColunaPlanilha>;
  vLinha, vUltima, vGradeLinha, c: Integer;
begin
  LimparGrade(grdDados);
  vColunas := FLeitor.Colunas(1);

  // Coluna 0 = número da linha no Excel
  grdDados.ColCount := Length(vColunas) + 1;
  if grdDados.ColCount < 2 then
    grdDados.ColCount := 2;
  grdDados.Cells[0, 0] := 'Linha';
  for c := 0 to High(vColunas) do
  begin
    grdDados.Cells[c + 1, 0] := vColunas[c].Nome;
    grdDados.ColWidths[c + 1] := 120;
  end;

  vUltima := FLeitor.LinhaInicial + cLINHAS_PREVIA - 1;
  if vUltima > FLeitor.UltimaLinha then
    vUltima := FLeitor.UltimaLinha;

  grdDados.RowCount := vUltima - FLeitor.LinhaInicial + 2;
  if grdDados.RowCount < 2 then
    grdDados.RowCount := 2;

  vGradeLinha := 1;
  for vLinha := FLeitor.LinhaInicial to vUltima do
  begin
    grdDados.Cells[0, vGradeLinha] := IntToStr(vLinha);
    for c := 0 to High(vColunas) do
      grdDados.Cells[c + 1, vGradeLinha] := FLeitor.Celula(vLinha, c).Texto;
    Inc(vGradeLinha);
  end;
end;

end.
