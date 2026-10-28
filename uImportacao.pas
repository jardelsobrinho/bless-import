unit uImportacao;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Types, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uFormTabBase, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.ComCtrls,
  uImportacaoDm, uImportador, uPerfilModelo;

type
  TfrmImportacao = class(TfrmFormTabBase)
    pnlTopo: TPanel;
    lblPerfil: TLabel;
    cbxPerfil: TComboBox;
    lblPlanilha: TLabel;
    edtPlanilha: TEdit;
    btnProcurar: TButton;
    lblLinhas: TLabel;
    edtLinhas: TEdit;
    udLinhas: TUpDown;
    lblTodas: TLabel;
    btnValidar: TButton;
    btnPreVisualizar: TButton;
    btnImportar: TButton;
    pbProgresso: TProgressBar;
    btnCancelar: TButton;
    lblRetomada: TLabel;
    btnNaoRetomar: TButton;
    lblResumo: TLabel;
    pcResultado: TPageControl;
    tabProblemas: TTabSheet;
    grdProblemas: TStringGrid;
    tabPrevia: TTabSheet;
    pnlLegenda: TPanel;
    lblLegenda: TLabel;
    lblLegendaPlanilha: TLabel;
    lblLegendaFixo: TLabel;
    lblLegendaPadrao: TLabel;
    lblLegendaExpressao: TLabel;
    lblLegendaConsulta: TLabel;
    lblLegendaGerado: TLabel;
    lblLegendaErro: TLabel;
    grdPrevia: TStringGrid;
    mmoDetalhe: TMemo;
    tabErros: TTabSheet;
    grdErros: TStringGrid;
    dlgAbrir: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure cbxPerfilDropDown(Sender: TObject);
    procedure cbxPerfilChange(Sender: TObject);
    procedure btnProcurarClick(Sender: TObject);
    procedure btnValidarClick(Sender: TObject);
    procedure btnPreVisualizarClick(Sender: TObject);
    procedure grdProblemasDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure grdPreviaDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure grdPreviaSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure grdErrosDblClick(Sender: TObject);
    procedure btnImportarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnNaoRetomarClick(Sender: TObject);
  private
    FDm: TdmImportacao;
    FProblemas: TArray<TProblemaPerfil>;
    FResultados: TArray<TResultadoLinha>;
    FCampos: TArray<TCampoPerfil>;
    FImportando: Boolean;
    FCancelar: Boolean;
    FErrosDaPrevia: Boolean;   // a aba Erros mostra erros da prévia (duplo clique leva à célula) ou da importação
    // Retomada de uma execução interrompida (0 = importação normal, desde o começo)
    FRetomadaExecucao: Integer;
    FRetomadaLinha: Integer;
    FRetomadaArquivo: string;
    FPreparandoRetomada: Boolean;
    procedure LimparRetomada;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure HabilitarControles(AHabilitar: Boolean);
    procedure MostrarErrosImportacao(const AErros: TArray<TErroImportacao>);
  public
    // Chamado pelo histórico: deixa a tela pronta para continuar a execução a partir da linha indicada
    procedure PrepararRetomada(AIdExecucao, AIdPerfil: Integer; const AArquivo: string; ALinhaInicio: Integer);
    procedure CarregarPerfis;
    function IdPerfilSelecionado: Integer;
    function Preparar: Boolean;
    procedure MostrarProblemas;
    procedure MostrarPrevia(ALinhasVazias: Integer);
    procedure MostrarDetalhe(ALinhaResultado, AIndiceCampo: Integer);
    function CorDaFonte(AFonte: TFonteValor): TColor;
    procedure LimparGrade(AGrade: TStringGrid; const ATitulos: array of string);
  end;

var
  frmImportacao: TfrmImportacao;

implementation

{$R *.dfm}

uses
  uTransformacoes, uMensagens;

const
  cCOR_FIXO = $00FFF0E0;
  cCOR_PADRAO = $00D0F8FF;
  cCOR_EXPRESSAO = $00FFE0F0;
  cCOR_CONSULTA = $00FFFFE0;
  cCOR_GERADO = $00E8E8E8;
  cCOR_ERRO = $00C8C8FF;
  cCOR_AVISO = $00C8F0FF;

  cCOLUNAS_FIXAS_PREVIA = 2;  // Linha, Situação

procedure TfrmImportacao.FormCreate(Sender: TObject);
begin
  FDm := TdmImportacao.Create(Self);
  // Não deixa fechar a aba no meio de uma importação
  OnCloseQuery := FormCloseQuery;
  lblLegendaPlanilha.Color := clWindow;
  lblLegendaFixo.Color := cCOR_FIXO;
  lblLegendaPadrao.Color := cCOR_PADRAO;
  lblLegendaExpressao.Color := cCOR_EXPRESSAO;
  lblLegendaConsulta.Color := cCOR_CONSULTA;
  lblLegendaGerado.Color := cCOR_GERADO;
  lblLegendaErro.Color := cCOR_ERRO;

  LimparGrade(grdProblemas, ['Gravidade', 'Campo', 'Problema']);
  LimparGrade(grdPrevia, ['Linha', 'Situação']);
  LimparGrade(grdErros, ['Linha', 'Campo', 'Tipo de erro', 'Valor recebido', 'Mensagem']);
  CarregarPerfis;
  pcResultado.ActivePage := tabPrevia;
end;

procedure TfrmImportacao.LimparGrade(AGrade: TStringGrid; const ATitulos: array of string);
var
  i: Integer;
begin
  for i := 0 to AGrade.RowCount - 1 do
    AGrade.Rows[i].Clear;
  AGrade.RowCount := 2;
  if Length(ATitulos) > 0 then
    AGrade.ColCount := Length(ATitulos);
  for i := 0 to High(ATitulos) do
    AGrade.Cells[i, 0] := ATitulos[i];
end;

{ Perfil e planilha }

procedure TfrmImportacao.CarregarPerfis;
var
  vSelecionado: Integer;
  i: Integer;
begin
  vSelecionado := IdPerfilSelecionado;
  cbxPerfil.Items.Clear;
  FDm.DmPerfis.Pesquisar;
  FDm.DmPerfis.qryPerfis.First;
  while not FDm.DmPerfis.qryPerfis.Eof do
  begin
    cbxPerfil.Items.AddObject(FDm.DmPerfis.qryPerfis.FieldByName('NOME').AsString + '  (' +
      FDm.DmPerfis.qryPerfis.FieldByName('TABELA_DESTINO').AsString + ')',
      TObject(FDm.DmPerfis.qryPerfis.FieldByName('ID').AsInteger));
    FDm.DmPerfis.qryPerfis.Next;
  end;
  for i := 0 to cbxPerfil.Items.Count - 1 do
    if Integer(cbxPerfil.Items.Objects[i]) = vSelecionado then
      cbxPerfil.ItemIndex := i;
end;

function TfrmImportacao.IdPerfilSelecionado: Integer;
begin
  if cbxPerfil.ItemIndex < 0 then
    Result := 0
  else
    Result := Integer(cbxPerfil.Items.Objects[cbxPerfil.ItemIndex]);
end;

procedure TfrmImportacao.cbxPerfilDropDown(Sender: TObject);
begin
  CarregarPerfis;
end;

procedure TfrmImportacao.cbxPerfilChange(Sender: TObject);
begin
  // Trocar o perfil à mão desfaz a retomada preparada pelo histórico
  if not FPreparandoRetomada then
    LimparRetomada;
  if IdPerfilSelecionado = 0 then
    Exit;
  Screen.Cursor := crHourGlass;
  try
    try
      FDm.CarregarPerfil(IdPerfilSelecionado);
      edtPlanilha.Text := FDm.Perfil.ArquivoExemplo;
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        TMensagens.Alerta(E.Message);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmImportacao.btnProcurarClick(Sender: TObject);
begin
  if edtPlanilha.Text <> '' then
    dlgAbrir.InitialDir := ExtractFileDir(edtPlanilha.Text);
  if dlgAbrir.Execute then
    edtPlanilha.Text := dlgAbrir.FileName;
end;

function TfrmImportacao.Preparar: Boolean;
begin
  Result := False;
  if IdPerfilSelecionado = 0 then
  begin
    TMensagens.Alerta('Selecione o perfil de importação.');
    Exit;
  end;

  lblResumo.Caption := 'Carregando perfil e planilha, aguarde...';
  lblResumo.Update;
  Screen.Cursor := crHourGlass;
  try
    try
      // Sempre relê o perfil: pode ter sido alterado na tela de perfis
      FDm.CarregarPerfil(IdPerfilSelecionado);
      FDm.AbrirPlanilha(Trim(edtPlanilha.Text));
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        lblResumo.Caption := '';
        TMensagens.Alerta(E.Message);
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  FProblemas := FDm.ValidarPerfil;
  MostrarProblemas;
  Result := True;
end;

{ Validação }

procedure TfrmImportacao.btnValidarClick(Sender: TObject);
var
  vErros: Integer;
  vProblema: TProblemaPerfil;
begin
  if not Preparar then
    Exit;

  vErros := 0;
  for vProblema in FProblemas do
    if vProblema.Gravidade = gvErro then
      Inc(vErros);
  lblResumo.Caption := Format('Validação do perfil: %d erros, %d avisos  |  planilha com %d linhas de dados',
    [vErros, Length(FProblemas) - vErros, FDm.LinhasDeDados]);
  pcResultado.ActivePage := tabProblemas;
  if Length(FProblemas) = 0 then
    TMensagens.Info('Nenhum problema encontrado no perfil.');
end;

procedure TfrmImportacao.MostrarProblemas;
var
  i: Integer;
begin
  LimparGrade(grdProblemas, ['Gravidade', 'Campo', 'Problema']);
  if Length(FProblemas) > 0 then
    grdProblemas.RowCount := Length(FProblemas) + 1;
  for i := 0 to High(FProblemas) do
  begin
    grdProblemas.Cells[0, i + 1] := cGRAVIDADES[FProblemas[i].Gravidade];
    grdProblemas.Cells[1, i + 1] := FProblemas[i].Campo;
    grdProblemas.Cells[2, i + 1] := FProblemas[i].Mensagem;
  end;
  tabProblemas.Caption := Format('Problemas do perfil (%d)', [Length(FProblemas)]);
end;

procedure TfrmImportacao.grdProblemasDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
  State: TGridDrawState);
var
  vCanvas: TCanvas;
begin
  if (ARow = 0) or (ARow > Length(FProblemas)) then
    Exit;
  vCanvas := grdProblemas.Canvas;
  if gdSelected in State then
  begin
    vCanvas.Brush.Color := clHighlight;
    vCanvas.Font.Color := clHighlightText;
  end
  else
  begin
    vCanvas.Font.Color := clWindowText;
    if FProblemas[ARow - 1].Gravidade = gvErro then
      vCanvas.Brush.Color := cCOR_ERRO
    else
      vCanvas.Brush.Color := cCOR_AVISO;
  end;
  vCanvas.FillRect(Rect);
  vCanvas.TextRect(Rect, Rect.Left + 4, Rect.Top + 3, grdProblemas.Cells[ACol, ARow]);
end;

{ Pré-visualização }

procedure TfrmImportacao.btnPreVisualizarClick(Sender: TObject);
var
  vLinhasVazias: Integer;
begin
  if not Preparar then
    Exit;

  lblResumo.Caption := 'Simulando as linhas, aguarde...';
  lblResumo.Update;
  Screen.Cursor := crHourGlass;
  try
    try
      FCampos := FDm.CamposMapeados;
      FResultados := FDm.PreVisualizar(udLinhas.Position, vLinhasVazias);
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        lblResumo.Caption := '';
        TMensagens.Alerta(E.Message);
        Exit;
      end;
    end;
    MostrarPrevia(vLinhasVazias);
  finally
    Screen.Cursor := crDefault;
  end;
  pcResultado.ActivePage := tabPrevia;
end;

procedure TfrmImportacao.MostrarPrevia(ALinhasVazias: Integer);
var
  vLinha, c, vErros, vValidas, vLinhaErro: Integer;
  vValor: TValorResolvido;
  vPorTipo: array[TTipoErro] of Integer;
  vTipo: TTipoErro;
  vTexto: string;
begin
  // Grade da prévia: Linha | Situação | um campo de destino por coluna
  LimparGrade(grdPrevia, []);
  grdPrevia.ColCount := cCOLUNAS_FIXAS_PREVIA + Length(FCampos);
  grdPrevia.Cells[0, 0] := 'Linha';
  grdPrevia.Cells[1, 0] := 'Situação';
  for c := 0 to High(FCampos) do
  begin
    grdPrevia.Cells[cCOLUNAS_FIXAS_PREVIA + c, 0] := FCampos[c].CampoDestino;
    grdPrevia.ColWidths[cCOLUNAS_FIXAS_PREVIA + c] := 130;
  end;
  if Length(FResultados) > 0 then
    grdPrevia.RowCount := Length(FResultados) + 1;

  LimparGrade(grdErros, ['Linha', 'Campo', 'Tipo de erro', 'Valor recebido', 'Mensagem']);
  vErros := 0;
  for vLinha := 0 to High(FResultados) do
    Inc(vErros, FResultados[vLinha].QuantidadeErros);
  if vErros > 0 then
    grdErros.RowCount := vErros + 1;
  FillChar(vPorTipo, SizeOf(vPorTipo), 0);
  vValidas := 0;
  vLinhaErro := 0;

  for vLinha := 0 to High(FResultados) do
  begin
    grdPrevia.Cells[0, vLinha + 1] := IntToStr(FResultados[vLinha].Linha);
    vErros := FResultados[vLinha].QuantidadeErros;
    if vErros = 0 then
    begin
      grdPrevia.Cells[1, vLinha + 1] := 'OK';
      Inc(vValidas);
    end
    else
      grdPrevia.Cells[1, vLinha + 1] := Format('%d erro(s)', [vErros]);

    for c := 0 to High(FResultados[vLinha].Valores) do
    begin
      vValor := FResultados[vLinha].Valores[c];
      if not vValor.Ok then
      begin
        vTexto := 'ERRO: ' + vValor.ValorRecebido;
        Inc(vPorTipo[vValor.TipoErro]);

        Inc(vLinhaErro);
        grdErros.Cells[0, vLinhaErro] := IntToStr(FResultados[vLinha].Linha);
        grdErros.Cells[1, vLinhaErro] := vValor.Campo;
        grdErros.Cells[2, vLinhaErro] := cTIPOS_ERRO[vValor.TipoErro];
        grdErros.Cells[3, vLinhaErro] := vValor.ValorRecebido;
        grdErros.Cells[4, vLinhaErro] := vValor.Mensagem;
        // Guarda onde está o erro na prévia para mostrar o detalhe ao clicar
        grdErros.Objects[0, vLinhaErro] := TObject(vLinha);
        grdErros.Objects[1, vLinhaErro] := TObject(c);
      end
      else if vValor.Fonte = fvGerado then
        vTexto := '(' + FCampos[c].Generator + ')'
      else if VarIsNull(vValor.Valor) then
        vTexto := ''
      else
        vTexto := ValorParaTexto(vValor.Valor);
      grdPrevia.Cells[cCOLUNAS_FIXAS_PREVIA + c, vLinha + 1] := vTexto;
    end;
  end;

  tabPrevia.Caption := Format('Pré-visualização (%d linhas)', [Length(FResultados)]);
  tabErros.Caption := Format('Erros (%d)', [vLinhaErro]);
  FErrosDaPrevia := True;

  vTexto := '';
  for vTipo := Succ(teNenhum) to High(TTipoErro) do
    if vPorTipo[vTipo] > 0 then
      vTexto := vTexto + Format('  %s: %d', [cTIPOS_ERRO[vTipo], vPorTipo[vTipo]]);
  if vTexto = '' then
    vTexto := '  nenhum';
  lblResumo.Caption := Format('Linhas simuladas: %d  |  válidas: %d  |  com erro: %d  |  vazias puladas: %d  |  ' +
    'planilha: %d linhas  |  erros por tipo:%s',
    [Length(FResultados), vValidas, Length(FResultados) - vValidas, ALinhasVazias, FDm.LinhasDeDados, vTexto]);

  // O detalhe só aparece quando o usuário clica numa célula
  mmoDetalhe.Clear;
  if Length(FResultados) > 0 then
    mmoDetalhe.Lines.Add('Clique numa célula para ver de onde veio o valor, o valor recebido, o valor final e o erro.');
end;

function TfrmImportacao.CorDaFonte(AFonte: TFonteValor): TColor;
begin
  case AFonte of
    fvFixo:
      Result := cCOR_FIXO;
    fvPadrao:
      Result := cCOR_PADRAO;
    fvExpressao:
      Result := cCOR_EXPRESSAO;
    fvConsulta:
      Result := cCOR_CONSULTA;
    fvGerado:
      Result := cCOR_GERADO;
  else
    Result := clWindow;
  end;
end;

procedure TfrmImportacao.grdPreviaDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
  State: TGridDrawState);
var
  vCanvas: TCanvas;
  vValor: TValorResolvido;
begin
  if (ARow = 0) or (ARow > Length(FResultados)) or (ACol < 1) then
    Exit;

  vCanvas := grdPrevia.Canvas;
  vCanvas.Font.Color := clWindowText;
  if ACol = 1 then
  begin
    if FResultados[ARow - 1].Valida then
      vCanvas.Brush.Color := clWindow
    else
      vCanvas.Brush.Color := cCOR_ERRO;
  end
  else
  begin
    vValor := FResultados[ARow - 1].Valores[ACol - cCOLUNAS_FIXAS_PREVIA];
    if not vValor.Ok then
      vCanvas.Brush.Color := cCOR_ERRO
    else
      vCanvas.Brush.Color := CorDaFonte(vValor.Fonte);
  end;
  if gdSelected in State then
  begin
    vCanvas.Brush.Color := clHighlight;
    vCanvas.Font.Color := clHighlightText;
  end;
  vCanvas.FillRect(Rect);
  vCanvas.TextRect(Rect, Rect.Left + 4, Rect.Top + 3, grdPrevia.Cells[ACol, ARow]);
end;

procedure TfrmImportacao.grdPreviaSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  if (ARow >= 1) and (ARow <= Length(FResultados)) then
  begin
    if ACol < cCOLUNAS_FIXAS_PREVIA then
      MostrarDetalhe(ARow - 1, -1)
    else
      MostrarDetalhe(ARow - 1, ACol - cCOLUNAS_FIXAS_PREVIA);
  end;
end;

procedure TfrmImportacao.grdErrosDblClick(Sender: TObject);
var
  vLinha, vCampo: Integer;
begin
  // Vai para a célula do erro na prévia (erros da importação não têm célula na prévia)
  if not FErrosDaPrevia or (grdErros.Row < 1) or (grdErros.Cells[0, grdErros.Row] = '') then
    Exit;
  vLinha := Integer(grdErros.Objects[0, grdErros.Row]);
  vCampo := Integer(grdErros.Objects[1, grdErros.Row]);
  pcResultado.ActivePage := tabPrevia;
  grdPrevia.Row := vLinha + 1;
  grdPrevia.Col := cCOLUNAS_FIXAS_PREVIA + vCampo;
  MostrarDetalhe(vLinha, vCampo);
  grdPrevia.SetFocus;
end;

{ Importação (gravação) }

procedure TfrmImportacao.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not FImportando;
  if not CanClose then
    TMensagens.Alerta('Há uma importação em andamento. Use "Cancelar" e aguarde ela parar antes de fechar.');
end;

procedure TfrmImportacao.HabilitarControles(AHabilitar: Boolean);
begin
  cbxPerfil.Enabled := AHabilitar;
  edtPlanilha.Enabled := AHabilitar;
  btnProcurar.Enabled := AHabilitar;
  edtLinhas.Enabled := AHabilitar;
  udLinhas.Enabled := AHabilitar;
  btnValidar.Enabled := AHabilitar;
  btnPreVisualizar.Enabled := AHabilitar;
  btnImportar.Enabled := AHabilitar;
  btnFechar.Enabled := AHabilitar;
  pbProgresso.Visible := not AHabilitar;
  btnCancelar.Visible := not AHabilitar;
  btnCancelar.Enabled := True;
  // O aviso de retomada divide o espaço com a barra de progresso
  lblRetomada.Visible := AHabilitar and (FRetomadaExecucao > 0);
  btnNaoRetomar.Visible := AHabilitar and (FRetomadaExecucao > 0);
end;

{ Retomada }

procedure TfrmImportacao.PrepararRetomada(AIdExecucao, AIdPerfil: Integer; const AArquivo: string;
  ALinhaInicio: Integer);
var
  i: Integer;
begin
  if FImportando then
  begin
    TMensagens.Alerta('Há uma importação em andamento nesta tela.');
    Exit;
  end;

  FPreparandoRetomada := True;
  try
    CarregarPerfis;
    cbxPerfil.ItemIndex := -1;
    for i := 0 to cbxPerfil.Items.Count - 1 do
      if Integer(cbxPerfil.Items.Objects[i]) = AIdPerfil then
        cbxPerfil.ItemIndex := i;
    if cbxPerfil.ItemIndex < 0 then
    begin
      TMensagens.Alerta('O perfil desta execução não existe mais.');
      Exit;
    end;
    cbxPerfilChange(nil);
    edtPlanilha.Text := AArquivo;
  finally
    FPreparandoRetomada := False;
  end;

  FRetomadaExecucao := AIdExecucao;
  FRetomadaLinha := ALinhaInicio;
  FRetomadaArquivo := AArquivo;
  lblRetomada.Caption := Format('Retomando a execução %d a partir da linha %d da planilha (o que veio antes já ' +
    'foi gravado).', [AIdExecucao, ALinhaInicio]);
  lblRetomada.Visible := True;
  btnNaoRetomar.Visible := True;
  lblResumo.Caption := 'Confira a planilha e clique em Importar para continuar.';
end;

procedure TfrmImportacao.LimparRetomada;
begin
  FRetomadaExecucao := 0;
  FRetomadaLinha := 0;
  FRetomadaArquivo := '';
  lblRetomada.Visible := False;
  btnNaoRetomar.Visible := False;
end;

procedure TfrmImportacao.btnNaoRetomarClick(Sender: TObject);
begin
  LimparRetomada;
  lblResumo.Caption := 'Retomada desfeita: a importação vai começar do início da planilha.';
end;

procedure TfrmImportacao.btnImportarClick(Sender: TObject);
var
  vProblema: TProblemaPerfil;
  vResumo: TResumoImportacao;
  vErros: TArray<TErroImportacao>;
  vMensagem, vInicioLinhas: string;
begin
  if FImportando or not Preparar then
    Exit;

  for vProblema in FProblemas do
    if vProblema.Gravidade = gvErro then
    begin
      pcResultado.ActivePage := tabProblemas;
      TMensagens.Alerta('O perfil tem erros (aba "Problemas do perfil"). Corrija o perfil antes de importar.');
      Exit;
    end;

  // Confirmação mostrando exatamente onde vai gravar
  if FDm.Perfil.Estrategia = egSomenteValidar then
    vInicioLinhas := 'Validar (sem gravar nada)'
  else
    vInicioLinhas := 'GRAVAR';
  vMensagem := Format('%s %d linhas da planilha?' + sLineBreak + sLineBreak +
    'Perfil: %s' + sLineBreak +
    'Planilha: %s' + sLineBreak +
    'Banco de destino: %s' + sLineBreak +
    'Tabela: %s' + sLineBreak +
    'Estratégia: %s' + sLineBreak +
    'Em caso de erro: %s',
    [vInicioLinhas, FDm.LinhasDeDados, FDm.Perfil.Nome, Trim(edtPlanilha.Text), FDm.DescricaoDestino,
    FDm.Perfil.TabelaDestino, cESTRATEGIAS[FDm.Perfil.Estrategia].Nome, cACOES_ERRO[FDm.Perfil.AcaoErro].Nome]);
  if EstrategiaUsaChave(FDm.Perfil.Estrategia) then
    vMensagem := vMensagem + sLineBreak + 'Campos-chave: ' + FDm.Perfil.CamposChave;
  if FRetomadaExecucao > 0 then
  begin
    vMensagem := vMensagem + sLineBreak + sLineBreak + Format('RETOMADA da execução %d: começa na linha %d ' +
      '(%d linhas restantes).', [FRetomadaExecucao, FRetomadaLinha, FDm.UltimaLinhaPlanilha - FRetomadaLinha + 1]);
    if not SameText(Trim(edtPlanilha.Text), FRetomadaArquivo) then
      vMensagem := vMensagem + sLineBreak + 'ATENÇÃO: a planilha é diferente da usada na execução original (' +
        FRetomadaArquivo + '); as linhas podem não corresponder.';
  end;
  if not TMensagens.Confirmacao(vMensagem) then
    Exit;

  FImportando := True;
  FCancelar := False;
  HabilitarControles(False);
  pbProgresso.Min := 0;
  pbProgresso.Max := FDm.LinhasDeDados;
  pbProgresso.Position := 0;
  try
    try
      vResumo := FDm.Importar(
        procedure(const AResumo: TResumoImportacao; var ACancelar: Boolean)
        begin
          // Sem threads: atualiza a tela e processa o clique em "Cancelar" entre as linhas
          pbProgresso.Position := AResumo.LinhaAtual - FDm.Perfil.LinhaInicial + 1;
          lblResumo.Caption := Format('Linha %d de %d  |  inseridas: %d  |  atualizadas: %d  |  ignoradas: %d  |  ' +
            'validadas: %d  |  com erro: %d', [AResumo.LinhaAtual, AResumo.UltimaLinhaPlanilha, AResumo.Inseridas,
            AResumo.Atualizadas, AResumo.Ignoradas, AResumo.Validadas, AResumo.ComErro]);
          Application.ProcessMessages;
          ACancelar := FCancelar;
        end, vErros, FRetomadaExecucao, FRetomadaLinha);
      // Retomada usada: a próxima importação desta tela é normal (para continuar de novo, use o histórico)
      LimparRetomada;
    except
      on E: Exception do
      begin
        lblResumo.Caption := '';
        TMensagens.Alerta(E.Message);
        Exit;
      end;
    end;
  finally
    FImportando := False;
    HabilitarControles(True);
  end;

  MostrarErrosImportacao(vErros);
  lblResumo.Caption := Format('Execução %d: %s  |  lidas: %d  |  inseridas: %d  |  atualizadas: %d  |  ' +
    'ignoradas: %d  |  validadas: %d  |  com erro: %d  |  vazias: %d',
    [vResumo.IdExecucao, cSTATUS_EXECUCAO[vResumo.Status].Nome, vResumo.Lidas, vResumo.Inseridas,
    vResumo.Atualizadas, vResumo.Ignoradas, vResumo.Validadas, vResumo.ComErro, vResumo.Vazias]);
  if Length(vErros) > 0 then
    pcResultado.ActivePage := tabErros;

  vMensagem := Format('%s' + sLineBreak + sLineBreak +
    'Linhas lidas: %d' + sLineBreak +
    'Inseridas: %d' + sLineBreak +
    'Atualizadas: %d' + sLineBreak +
    'Ignoradas (já existiam / não encontradas): %d' + sLineBreak +
    'Validadas sem gravar: %d' + sLineBreak +
    'Com erro: %d (veja a aba Erros)',
    [vResumo.Mensagem, vResumo.Lidas, vResumo.Inseridas, vResumo.Atualizadas, vResumo.Ignoradas,
    vResumo.Validadas, vResumo.ComErro]);
  if vResumo.Status in [seConcluida, seConcluidaComErros] then
    TMensagens.Info(vMensagem)
  else
    TMensagens.Alerta(vMensagem);
end;

procedure TfrmImportacao.btnCancelarClick(Sender: TObject);
begin
  if TMensagens.Confirmacao('Cancelar a importação?' + sLineBreak + sLineBreak +
    'O que já foi gravado fica gravado (exceto no modo "desfazer tudo", em que nada é gravado).') then
  begin
    FCancelar := True;
    btnCancelar.Enabled := False;
    lblResumo.Caption := 'Cancelando...';
  end;
end;

procedure TfrmImportacao.MostrarErrosImportacao(const AErros: TArray<TErroImportacao>);
var
  i: Integer;
begin
  LimparGrade(grdErros, ['Linha', 'Campo', 'Tipo de erro', 'Valor recebido', 'Mensagem']);
  if Length(AErros) > 0 then
    grdErros.RowCount := Length(AErros) + 1;
  for i := 0 to High(AErros) do
  begin
    grdErros.Cells[0, i + 1] := IntToStr(AErros[i].Linha);
    grdErros.Cells[1, i + 1] := AErros[i].Campo;
    grdErros.Cells[2, i + 1] := cTIPOS_ERRO[AErros[i].TipoErro];
    grdErros.Cells[3, i + 1] := AErros[i].ValorRecebido;
    grdErros.Cells[4, i + 1] := AErros[i].Mensagem;
  end;
  tabErros.Caption := Format('Erros da importação (%d)', [Length(AErros)]);
  FErrosDaPrevia := False;
end;

procedure TfrmImportacao.MostrarDetalhe(ALinhaResultado, AIndiceCampo: Integer);
var
  vResultado: TResultadoLinha;
  vValor: TValorResolvido;
  vCampo: TCampoPerfil;
  vOrigem: string;
  c: Integer;
begin
  mmoDetalhe.Lines.BeginUpdate;
  try
    mmoDetalhe.Clear;
    vResultado := FResultados[ALinhaResultado];

    // Clique em Linha/Situação: resume os erros da linha
    if AIndiceCampo < 0 then
    begin
      mmoDetalhe.Lines.Add(Format('Linha %d da planilha: %d erro(s)', [vResultado.Linha, vResultado.QuantidadeErros]));
      for c := 0 to High(vResultado.Valores) do
        if not vResultado.Valores[c].Ok then
          mmoDetalhe.Lines.Add(Format('  %s (%s): %s', [vResultado.Valores[c].Campo,
            cTIPOS_ERRO[vResultado.Valores[c].TipoErro], vResultado.Valores[c].Mensagem]));
      Exit;
    end;

    vValor := vResultado.Valores[AIndiceCampo];
    vCampo := FCampos[AIndiceCampo];
    case vValor.Fonte of
      fvColuna, fvConsulta:
        if vCampo.Origem = ovConsultaSql then
          vOrigem := 'Consulta SQL: ' + StringReplace(Trim(vCampo.ConsultaSql), sLineBreak, ' ', [rfReplaceAll])
        else
          vOrigem := Format('%s (coluna "%s")', [cFONTES[vValor.Fonte], vCampo.Coluna]);
      fvPadrao:
        vOrigem := Format('%s "%s" (coluna "%s")', [cFONTES[vValor.Fonte], vCampo.ValorPadrao, vCampo.Coluna]);
      fvExpressao:
        vOrigem := Format('%s %s', [cFONTES[vValor.Fonte], vCampo.Expressao]);
      fvGerado:
        vOrigem := Format('%s pelo %s', [cFONTES[vValor.Fonte], vCampo.Generator]);
    else
      vOrigem := cFONTES[vValor.Fonte];
    end;

    mmoDetalhe.Lines.Add(Format('Linha %d  |  campo %s', [vResultado.Linha, vValor.Campo]));
    mmoDetalhe.Lines.Add('Origem do valor: ' + vOrigem);
    mmoDetalhe.Lines.Add('Valor recebido: ' + vValor.ValorRecebido);
    if vValor.Ok then
    begin
      if vValor.Fonte = fvGerado then
        mmoDetalhe.Lines.Add('Valor final: gerado ao gravar')
      else if VarIsNull(vValor.Valor) then
        mmoDetalhe.Lines.Add('Valor final: (nulo)')
      else
        mmoDetalhe.Lines.Add('Valor final: ' + ValorParaTexto(vValor.Valor));
      if vValor.Mensagem <> '' then
        mmoDetalhe.Lines.Add('Observação: ' + vValor.Mensagem);
    end
    else
      mmoDetalhe.Lines.Add(Format('ERRO de %s: %s', [cTIPOS_ERRO[vValor.TipoErro], vValor.Mensagem]));
  finally
    mmoDetalhe.Lines.EndUpdate;
  end;
end;

end.
