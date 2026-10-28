unit uPerfilEdicao;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Types, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uFormModalBase, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.ComCtrls,
  Vcl.CheckLst, uPerfilModelo, uPerfisDm, uConexoesDm, uDmDestino, uLeitorXls, uTransformacoes, uImportador;

type
  // Uma linha do painel "Colunas da planilha"
  TUsoColuna = record
    Nome: string;
    Tipo: string;
    UsadaEm: string;    // campos de destino que leem esta coluna
    Existe: Boolean;    // False = citada no perfil mas não existe na planilha carregada
  end;

  TfrmPerfilEdicao = class(TfrmFormModalBase)
    btnGravar: TButton;
    btnSugerir: TButton;
    lblResumo: TLabel;
    pnlPerfil: TPanel;
    lblNome: TLabel;
    edtNome: TEdit;
    lblDescricao: TLabel;
    edtDescricao: TEdit;
    lblConexao: TLabel;
    cbxConexao: TComboBox;
    lblTabela: TLabel;
    cbxTabela: TComboBox;
    lblInfoTabela: TLabel;
    lblPlanilha: TLabel;
    edtPlanilha: TEdit;
    btnProcurar: TButton;
    btnCarregarPlanilha: TButton;
    lblAba: TLabel;
    cbxAba: TComboBox;
    lblLinhaCabecalho: TLabel;
    edtLinhaCabecalho: TEdit;
    udLinhaCabecalho: TUpDown;
    lblLinhaInicial: TLabel;
    edtLinhaInicial: TEdit;
    udLinhaInicial: TUpDown;
    lblInfoPlanilha: TLabel;
    dlgAbrir: TOpenDialog;
    pcPrincipal: TPageControl;
    tsBancoDestino: TTabSheet;
    tsGravacao: TTabSheet;
    lblEstrategia: TLabel;
    cbxEstrategia: TComboBox;
    lblAcaoErro: TLabel;
    cbxAcaoErro: TComboBox;
    lblCamposChave: TLabel;
    lblAjudaChave: TLabel;
    clbCamposChave: TCheckListBox;
    lblAjudaEstrategia: TLabel;
    TabSheet2: TTabSheet;
    grdCampos: TStringGrid;
    splDetalhe: TSplitter;
    pnlDetalhe: TPanel;
    lblCampo: TLabel;
    lblCampoInfo: TLabel;
    lblOrigem: TLabel;
    cbxOrigem: TComboBox;
    pnlColuna: TPanel;
    lblColuna: TLabel;
    cbxColuna: TComboBox;
    pnlFixo: TPanel;
    lblValorFixo: TLabel;
    edtValorFixo: TEdit;
    pnlPadrao: TPanel;
    lblValorPadrao: TLabel;
    lblUsarPadrao: TLabel;
    edtValorPadrao: TEdit;
    chkSeInexistente: TCheckBox;
    chkSeVazio: TCheckBox;
    chkSeInvalido: TCheckBox;
    pnlGerado: TPanel;
    lblGenerator: TLabel;
    cbxGenerator: TComboBox;
    pnlExpressao: TPanel;
    lblExpressao: TLabel;
    lblAjudaExpressao: TLabel;
    edtExpressao: TEdit;
    pnlConsulta: TPanel;
    lblConsultaTabela: TLabel;
    lblConsultaPesquisa: TLabel;
    lblConsultaRetorno: TLabel;
    lblConsultaSeNaoAchar: TLabel;
    cbxConsultaTabela: TComboBox;
    edtConsultaPesquisa: TEdit;
    edtConsultaRetorno: TEdit;
    cbxConsultaSeNaoAchar: TComboBox;
    pnlConsultaSql: TPanel;
    lblConsultaSql: TLabel;
    mmoConsultaSql: TMemo;
    btnTestarSql: TButton;
    lblConsultaSqlSeNaoAchar: TLabel;
    cbxConsultaSqlSeNaoAchar: TComboBox;
    lblAjudaConsultaSql: TLabel;
    grpTransformacoes: TGroupBox;
    lblAjudaTransformacao: TLabel;
    lblExemplo: TLabel;
    lstTransformacoes: TListBox;
    btnSubir: TButton;
    btnDescer: TButton;
    btnRemover: TButton;
    cbxTipoTransformacao: TComboBox;
    edtParametroTransformacao: TEdit;
    btnAdicionarTransformacao: TButton;
    btnAlterarTransformacao: TButton;
    pnlColunas: TPanel;
    lblColunasPlanilha: TLabel;
    chkSoNaoUsadas: TCheckBox;
    grdColunas: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbxConexaoChange(Sender: TObject);
    procedure cbxTabelaSelect(Sender: TObject);
    procedure cbxTabelaExit(Sender: TObject);
    procedure btnProcurarClick(Sender: TObject);
    procedure btnCarregarPlanilhaClick(Sender: TObject);
    procedure cbxAbaChange(Sender: TObject);
    procedure edtLinhaChange(Sender: TObject);
    procedure grdCamposClick(Sender: TObject);
    procedure cbxEstrategiaChange(Sender: TObject);
    procedure chkSoNaoUsadasClick(Sender: TObject);
    procedure grdColunasDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure grdColunasDblClick(Sender: TObject);
    procedure grdCamposDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure OpcaoChange(Sender: TObject);
    procedure btnTestarSqlClick(Sender: TObject);
    procedure lstTransformacoesClick(Sender: TObject);
    procedure cbxTipoTransformacaoChange(Sender: TObject);
    procedure btnAdicionarTransformacaoClick(Sender: TObject);
    procedure btnAlterarTransformacaoClick(Sender: TObject);
    procedure btnRemoverClick(Sender: TObject);
    procedure btnSubirClick(Sender: TObject);
    procedure btnDescerClick(Sender: TObject);
    procedure btnSugerirClick(Sender: TObject);
    procedure btnGravarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FDm: TdmPerfis;
    FDmConexoes: TdmConexoes;
    FDmDestino: TdmDestino;
    FConsultas: TConsultaReferencias;
    FLeitor: TLeitorXls;
    FPerfil: TPerfil;
    FCamposDestino: TArray<TCampoDestino>;
    FColunas: TArray<TColunaPlanilha>;
    FPlanilhaCarregada: Boolean;
    FLinhas: TArray<string>;
    FUsoColunas: TArray<TUsoColuna>;
    FCarregando: Boolean;
    FOrdemColuna: Integer;       // coluna da grade de campos usada na ordenação (-1 = ordem do banco)
    FOrdemDecrescente: Boolean;
    procedure AtualizarColunasUsadas;
    procedure AtualizarTitulosCampos;
    procedure OrdenarLinhas;
    procedure grdCamposFixedCellClick(Sender: TObject; ACol, ARow: Integer);
    procedure CarregarTela;
    procedure CarregarConexoes;
    procedure ConectarDestino;
    procedure CarregarCamposDestino;
    procedure CarregarPlanilha(const AAba: string);
    procedure AtualizarColunas;
    procedure MontarGrade;
    procedure PreencherLinha(ARow: Integer);
    procedure AtualizarResumo;
    function CampoDaLinha(ARow: Integer): TCampoPerfil;
    function CampoSelecionado: TCampoPerfil;
    function CampoDestinoPorNome(const ANome: string; out ACampo: TCampoDestino): Boolean;
    function ColunaPorNome(const ANome: string; out AColuna: TColunaPlanilha): Boolean;
    function ObterCelulaExemplo: TObterCelula;
    function CalcularExemplo(ACampo: TCampoPerfil; out AOriginal, AResultado: string): Boolean;
    procedure MostrarDetalhe;
    procedure LerDetalhe;
    procedure AjustarPainelOrigem;
    procedure MostrarTransformacoes(AIndiceSelecionado: Integer = -1);
    procedure AtualizarExemplo;
    procedure LerCabecalho;
    procedure PreencherCamposChave;
    procedure AtualizarAjudaEstrategia;
    function CamposChaveMarcados: TArray<string>;
    function LerTransformacaoDaTela(out ATransformacao: TTransformacao): Boolean;
    procedure LimparTransformacaoDaTela;
  public
    class function Editar(ADm: TdmPerfis; AId: Integer): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.Generics.Collections, System.Generics.Defaults, uMensagens;

const
  cCOL_CAMPO = 0;
  cCOL_TIPO = 1;
  cCOL_OBRIGATORIO = 2;
  cCOL_ORIGEM = 3;
  cCOL_VALOR = 4;
  cCOL_EXEMPLO = 5;
  cCOL_TRANSFORMACOES = 6;

  cTITULOS_CAMPOS: array[cCOL_CAMPO..cCOL_TRANSFORMACOES] of string = ('Campo de destino', 'Tipo', 'Obrig.',
    'Origem do valor', 'Coluna / valor', 'Exemplo (resultado)', 'Transformações');

  cCOR_MAPEADO = $00E3F7E3;
  cCOR_OBRIGATORIO_SEM_MAPEAMENTO = $00DCDCFF;
  cCOR_NAO_EXISTE = $00C8E6FF;

type
  // Linha da grade de campos durante a ordenação
  TChaveOrdenacao = record
    Nome: string;
    Chave: string;
    Posicao: Integer;
  end;

// Compara nomes ignorando maiúsculas, acentos, espaços e símbolos: "Razao Social" = "RAZAO_SOCIAL"
function NomeNormalizado(const ANome: string): string;
const
  cCOM_ACENTO = 'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
  cSEM_ACENTO = 'AAAAAEEEEIIIIOOOOOUUUUCN';
var
  vCaractere: Char;
  vPosicao: Integer;
begin
  Result := '';
  for vCaractere in AnsiUpperCase(ANome) do
  begin
    vPosicao := Pos(vCaractere, cCOM_ACENTO);
    if vPosicao > 0 then
      Result := Result + cSEM_ACENTO[vPosicao]
    else if CharInSet(vCaractere, ['A'..'Z', '0'..'9']) then
      Result := Result + vCaractere;
  end;
end;

class function TfrmPerfilEdicao.Editar(ADm: TdmPerfis; AId: Integer): Boolean;
var
  vForm: TfrmPerfilEdicao;
begin
  vForm := TfrmPerfilEdicao.Create(nil);
  try
    vForm.FDm := ADm;
    if AId > 0 then
    begin
      vForm.FPerfil.Free;
      vForm.FPerfil := ADm.Carregar(AId);
    end;
    vForm.CarregarTela;
    Result := vForm.ShowModal = mrOk;
  finally
    vForm.Free;
  end;
end;

procedure TfrmPerfilEdicao.FormCreate(Sender: TObject);
var
  vOrigem: TOrigemValor;
  vAcao: TAcaoNaoEncontrado;
  vTipo: TTipoTransformacao;
  vEstrategia: TEstrategiaGravacao;
  vAcaoErro: TAcaoErro;
begin
  FPerfil := TPerfil.Create;
  FLeitor := TLeitorXls.Create;
  FDmConexoes := TdmConexoes.Create(Self);
  FDmDestino := TdmDestino.Create(Self);
  FConsultas := TConsultaReferencias.Create(FDmDestino);

  for vOrigem := Low(TOrigemValor) to High(TOrigemValor) do
    cbxOrigem.Items.Add(cORIGENS[vOrigem].Nome);
  for vAcao := Low(TAcaoNaoEncontrado) to High(TAcaoNaoEncontrado) do
  begin
    cbxConsultaSeNaoAchar.Items.Add(cACOES_NAO_ENCONTRADO[vAcao].Nome);
    cbxConsultaSqlSeNaoAchar.Items.Add(cACOES_NAO_ENCONTRADO[vAcao].Nome);
  end;
  for vTipo := Low(TTipoTransformacao) to High(TTipoTransformacao) do
    cbxTipoTransformacao.Items.Add(cTRANSFORMACOES[vTipo].Nome);
  for vEstrategia := Low(TEstrategiaGravacao) to High(TEstrategiaGravacao) do
    cbxEstrategia.Items.Add(cESTRATEGIAS[vEstrategia].Nome);
  for vAcaoErro := Low(TAcaoErro) to High(TAcaoErro) do
    cbxAcaoErro.Items.Add(cACOES_ERRO[vAcaoErro].Nome);

  // Clique no título de uma coluna ordena a grade de campos
  FOrdemColuna := -1;
  FOrdemDecrescente := False;
  grdCampos.Options := grdCampos.Options + [goFixedRowClick, goFixedHotTrack];
  grdCampos.OnFixedCellClick := grdCamposFixedCellClick;
  AtualizarTitulosCampos;

  grdColunas.Cells[0, 0] := 'Coluna da planilha';
  grdColunas.Cells[1, 0] := 'Tipo';
  grdColunas.Cells[2, 0] := 'Usada em';
end;

procedure TfrmPerfilEdicao.FormDestroy(Sender: TObject);
begin
  FPerfil.Free;
  FLeitor.Free;
  FConsultas.Free;
end;

procedure TfrmPerfilEdicao.FormShow(Sender: TObject);
begin
  inherited;
  pcPrincipal.ActivePage := tsBancoDestino;
end;

{ Carga inicial }

procedure TfrmPerfilEdicao.CarregarTela;
begin
  FCarregando := True;
  try
    if FPerfil.Id = 0 then
      Caption := 'Novo perfil de importação'
    else
      Caption := Format('Perfil de importação: %s (versão %d)', [FPerfil.Nome, FPerfil.Versao]);

    edtNome.Text := FPerfil.Nome;
    edtDescricao.Text := FPerfil.Descricao;
    cbxEstrategia.ItemIndex := Ord(FPerfil.Estrategia);
    cbxAcaoErro.ItemIndex := Ord(FPerfil.AcaoErro);
    AtualizarAjudaEstrategia;
    edtPlanilha.Text := FPerfil.ArquivoExemplo;
    udLinhaCabecalho.Position := FPerfil.LinhaCabecalho;
    udLinhaInicial.Position := FPerfil.LinhaInicial;

    CarregarConexoes;
    ConectarDestino;
    cbxTabela.Text := FPerfil.TabelaDestino;
    CarregarCamposDestino;
  finally
    FCarregando := False;
  end;

  if FPerfil.ArquivoExemplo <> '' then
  begin
    if FileExists(FPerfil.ArquivoExemplo) then
      CarregarPlanilha(FPerfil.Aba)
    else
      lblInfoPlanilha.Caption := 'Planilha não encontrada: carregue outra para ver colunas e exemplos.';
  end;

  MontarGrade;
end;

procedure TfrmPerfilEdicao.CarregarConexoes;
var
  i: Integer;
begin
  cbxConexao.Items.Clear;
  FDmConexoes.Pesquisar;
  FDmConexoes.qryConexoes.First;
  while not FDmConexoes.qryConexoes.Eof do
  begin
    cbxConexao.Items.AddObject(FDmConexoes.qryConexoes.FieldByName('NOME').AsString + ' (' +
      FDmConexoes.qryConexoes.FieldByName('ERP').AsString + ')',
      TObject(FDmConexoes.qryConexoes.FieldByName('ID').AsInteger));
    FDmConexoes.qryConexoes.Next;
  end;

  cbxConexao.ItemIndex := -1;
  for i := 0 to cbxConexao.Items.Count - 1 do
    if Integer(cbxConexao.Items.Objects[i]) = FPerfil.IdConexao then
      cbxConexao.ItemIndex := i;
end;

procedure TfrmPerfilEdicao.ConectarDestino;
var
  vTabelas: TArray<string>;
begin
  cbxTabela.Items.Clear;
  cbxGenerator.Items.Clear;
  cbxConsultaTabela.Items.Clear;
  FDmDestino.Desconectar;
  // Cache das consultas vale só para esta conexão
  FConsultas.Free;
  FConsultas := TConsultaReferencias.Create(FDmDestino);
  lblInfoTabela.Caption := '';
  if FPerfil.IdConexao <= 0 then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    try
      FDmDestino.Conectar(FDmConexoes.Carregar(FPerfil.IdConexao));
      vTabelas := FDmDestino.Tabelas;
      cbxTabela.Items.AddStrings(vTabelas);
      cbxConsultaTabela.Items.AddStrings(vTabelas);
      cbxGenerator.Items.AddStrings(FDmDestino.Generators);
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        lblInfoTabela.Caption := 'Sem conexão com o destino';
        TMensagens.Alerta('Não foi possível conectar ao banco de destino:' + sLineBreak + sLineBreak + E.Message);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmPerfilEdicao.CarregarCamposDestino;
var
  vCampo: TCampoDestino;
  i: Integer;
begin
  // Título da aba acompanha a tabela escolhida
  if FPerfil.TabelaDestino = '' then
    tsBancoDestino.Caption := 'Tabela de Destino'
  else
    tsBancoDestino.Caption := Format('Tabela ''%s''', [FPerfil.TabelaDestino]);

  FCamposDestino := nil;
  if (FPerfil.TabelaDestino = '') or not FDmDestino.Conectado then
    Exit;

  if not FDmDestino.ExisteTabela(FPerfil.TabelaDestino) then
  begin
    lblInfoTabela.Caption := 'Tabela não encontrada no destino';
    Exit;
  end;

  FCamposDestino := FDmDestino.Campos(FPerfil.TabelaDestino);
  lblInfoTabela.Caption := Format('%d campos', [Length(FCamposDestino)]);

  // Tira os campos não mapeados de outra tabela e cria os desta (campos mapeados sempre ficam)
  for i := FPerfil.Campos.Count - 1 downto 0 do
    if not FPerfil.Campos[i].Mapeado then
      FPerfil.Campos.Delete(i);
  for vCampo in FCamposDestino do
    FPerfil.AdicionarCampo(vCampo.Nome);

  PreencherCamposChave;
end;

procedure TfrmPerfilEdicao.PreencherCamposChave;
var
  vNomes: TStringList;
  vChaves: TArray<string>;
  vCampo: TCampoDestino;
  vChave: string;
  i: Integer;
begin
  // Campos da tabela em ordem alfabética; marcados os campos-chave do perfil (ou a chave primária, como sugestão)
  vChaves := FPerfil.ListaCamposChave;
  if Length(vChaves) = 0 then
    vChaves := FDmDestino.ChavePrimaria(FPerfil.TabelaDestino);

  vNomes := TStringList.Create;
  try
    for vCampo in FCamposDestino do
      if not vCampo.Calculado then
        vNomes.Add(vCampo.Nome);
    vNomes.Sort;
    clbCamposChave.Items.Assign(vNomes);
  finally
    vNomes.Free;
  end;

  for i := 0 to clbCamposChave.Items.Count - 1 do
    for vChave in vChaves do
      if SameText(clbCamposChave.Items[i], vChave) then
        clbCamposChave.Checked[i] := True;
end;

procedure TfrmPerfilEdicao.AtualizarAjudaEstrategia;
var
  vEstrategia: TEstrategiaGravacao;
  vTexto: string;
begin
  if cbxEstrategia.ItemIndex < 0 then
    Exit;
  vEstrategia := TEstrategiaGravacao(cbxEstrategia.ItemIndex);
  clbCamposChave.Enabled := EstrategiaUsaChave(vEstrategia);

  case vEstrategia of
    egInserir:
      vTexto := 'Insere todas as linhas válidas. Se o registro já existir, o banco recusa (chave duplicada) e ' +
        'a linha vai para os erros. Não usa os campos-chave.';
    egIgnorarExistentes:
      vTexto := 'Procura cada linha pelos campos-chave: se já existir, ignora; se não existir, insere. ' +
        'Bom para reimportar a mesma planilha sem duplicar.';
    egAtualizar:
      vTexto := 'Procura cada linha pelos campos-chave: se existir, atualiza; se não existir, ignora (não insere).';
    egInserirOuAtualizar:
      vTexto := 'Procura cada linha pelos campos-chave: se existir, atualiza; se não existir, insere.';
    egSomenteValidar:
      vTexto := 'Lê e valida todas as linhas e registra os erros, sem gravar nada no destino.';
  end;
  if vEstrategia in [egAtualizar, egInserirOuAtualizar] then
    vTexto := vTexto + sLineBreak + sLineBreak + 'Na atualização: os campos-chave e os valores gerados não são ' +
      'alterados, e um valor vazio na planilha não apaga o valor que já existe no destino.';
  if EstrategiaUsaChave(vEstrategia) then
    vTexto := vTexto + sLineBreak + sLineBreak + 'Se os campos-chave encontrarem mais de um registro, a linha ' +
      'não é gravada e vai para os erros.';

  if cbxAcaoErro.ItemIndex = Ord(aeDesfazerTudo) then
    vTexto := vTexto + sLineBreak + sLineBreak + '"Desfazer tudo" grava numa transação só: qualquer erro (ou ' +
      'cancelar) desfaz a importação inteira.'
  else
    vTexto := vTexto + sLineBreak + sLineBreak + Format('A gravação é confirmada a cada %d linhas.',
      [cTAMANHO_LOTE]);
  lblAjudaEstrategia.Caption := vTexto;
end;

procedure TfrmPerfilEdicao.cbxEstrategiaChange(Sender: TObject);
begin
  AtualizarAjudaEstrategia;
end;

{ Planilha }

procedure TfrmPerfilEdicao.CarregarPlanilha(const AAba: string);
var
  vIndiceAba: Integer;
begin
  FPlanilhaCarregada := False;
  FColunas := nil;
  cbxAba.Items.Clear;
  lblInfoPlanilha.Caption := 'Carregando planilha, aguarde...';
  lblInfoPlanilha.Update;

  Screen.Cursor := crHourGlass;
  try
    try
      FLeitor.Abrir(edtPlanilha.Text);
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        lblInfoPlanilha.Caption := 'Planilha não carregada';
        TMensagens.Alerta(E.Message);
        Exit;
      end;
    end;

    FCarregando := True;
    try
      cbxAba.Items.AddStrings(FLeitor.Abas);
      vIndiceAba := cbxAba.Items.IndexOf(AAba);
      if vIndiceAba < 0 then
        vIndiceAba := 0;
      cbxAba.ItemIndex := vIndiceAba;
      FLeitor.SelecionarAba(vIndiceAba);
    finally
      FCarregando := False;
    end;

    FPlanilhaCarregada := True;
    FPerfil.ArquivoExemplo := edtPlanilha.Text;
    AtualizarColunas;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmPerfilEdicao.AtualizarColunas;
var
  vColuna: TColunaPlanilha;
  vNomes: TStringList;
begin
  FPerfil.Aba := cbxAba.Text;
  FPerfil.LinhaCabecalho := udLinhaCabecalho.Position;
  FPerfil.LinhaInicial := udLinhaInicial.Position;
  if not FPlanilhaCarregada then
    Exit;

  if FPerfil.LinhaInicial <= FPerfil.LinhaCabecalho then
  begin
    lblInfoPlanilha.Caption := 'A linha inicial deve ficar depois da linha do cabeçalho';
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    FLeitor.LinhaCabecalho := FPerfil.LinhaCabecalho;
    FLeitor.LinhaInicial := FPerfil.LinhaInicial;
    FColunas := FLeitor.Colunas;
  finally
    Screen.Cursor := crDefault;
  end;

  // Lista de colunas em ordem alfabética (sem diferenciar maiúsculas)
  vNomes := TStringList.Create;
  try
    vNomes.CaseSensitive := False;
    for vColuna in FColunas do
      vNomes.Add(vColuna.Nome);
    vNomes.Sort;
    cbxColuna.Items.Assign(vNomes);
  finally
    vNomes.Free;
  end;

  lblInfoPlanilha.Caption := Format('%d linhas de dados, %d colunas',
    [FLeitor.UltimaLinha - FPerfil.LinhaInicial + 1, Length(FColunas)]);
  MontarGrade;
end;

procedure TfrmPerfilEdicao.btnProcurarClick(Sender: TObject);
begin
  if edtPlanilha.Text <> '' then
    dlgAbrir.InitialDir := ExtractFileDir(edtPlanilha.Text);
  if dlgAbrir.Execute then
  begin
    edtPlanilha.Text := dlgAbrir.FileName;
    CarregarPlanilha('');
  end;
end;

procedure TfrmPerfilEdicao.btnCarregarPlanilhaClick(Sender: TObject);
begin
  if Trim(edtPlanilha.Text) = '' then
  begin
    TMensagens.Alerta('Informe a planilha.');
    Exit;
  end;
  CarregarPlanilha(cbxAba.Text);
end;

procedure TfrmPerfilEdicao.cbxAbaChange(Sender: TObject);
begin
  if FCarregando or not FPlanilhaCarregada then
    Exit;
  FLeitor.SelecionarAba(cbxAba.ItemIndex);
  AtualizarColunas;
end;

procedure TfrmPerfilEdicao.edtLinhaChange(Sender: TObject);
begin
  if FCarregando then
    Exit;
  AtualizarColunas;
end;

{ Conexão e tabela }

procedure TfrmPerfilEdicao.cbxConexaoChange(Sender: TObject);
begin
  if FCarregando or (cbxConexao.ItemIndex < 0) then
    Exit;
  FPerfil.IdConexao := Integer(cbxConexao.Items.Objects[cbxConexao.ItemIndex]);
  ConectarDestino;
  CarregarCamposDestino;
  MontarGrade;
end;

procedure TfrmPerfilEdicao.cbxTabelaSelect(Sender: TObject);
begin
  if FCarregando then
    Exit;
  if UpperCase(Trim(cbxTabela.Text)) = FPerfil.TabelaDestino then
    Exit;
  FPerfil.TabelaDestino := UpperCase(Trim(cbxTabela.Text));
  CarregarCamposDestino;
  MontarGrade;
end;

procedure TfrmPerfilEdicao.cbxTabelaExit(Sender: TObject);
begin
  cbxTabelaSelect(Sender);
end;

{ Grade de campos }

function TfrmPerfilEdicao.CampoDestinoPorNome(const ANome: string; out ACampo: TCampoDestino): Boolean;
var
  vCampo: TCampoDestino;
begin
  for vCampo in FCamposDestino do
    if SameText(vCampo.Nome, ANome) then
    begin
      ACampo := vCampo;
      Exit(True);
    end;
  ACampo := Default(TCampoDestino);
  Result := False;
end;

function TfrmPerfilEdicao.ColunaPorNome(const ANome: string; out AColuna: TColunaPlanilha): Boolean;
var
  vColuna: TColunaPlanilha;
begin
  for vColuna in FColunas do
    if SameText(vColuna.Nome, Trim(ANome)) then
    begin
      AColuna := vColuna;
      Exit(True);
    end;
  AColuna := Default(TColunaPlanilha);
  Result := False;
end;

function TfrmPerfilEdicao.CampoDaLinha(ARow: Integer): TCampoPerfil;
begin
  if (ARow < 1) or (ARow > Length(FLinhas)) then
    Exit(nil);
  Result := FPerfil.CampoPorNome(FLinhas[ARow - 1]);
end;

function TfrmPerfilEdicao.CampoSelecionado: TCampoPerfil;
begin
  Result := CampoDaLinha(grdCampos.Row);
end;

procedure TfrmPerfilEdicao.MontarGrade;
var
  vCampoDestino: TCampoDestino;
  vCampo: TCampoPerfil;
  vSelecionado: string;
  i: Integer;
begin
  vSelecionado := '';
  if CampoSelecionado <> nil then
    vSelecionado := CampoSelecionado.CampoDestino;

  // Campos da tabela na ordem do banco; depois os mapeados que não existem mais na tabela
  FLinhas := nil;
  for vCampoDestino in FCamposDestino do
    FLinhas := FLinhas + [vCampoDestino.Nome];
  for vCampo in FPerfil.Campos do
    if vCampo.Mapeado and not CampoDestinoPorNome(vCampo.CampoDestino, vCampoDestino) then
      FLinhas := FLinhas + [vCampo.CampoDestino];

  if Length(FLinhas) = 0 then
  begin
    grdCampos.RowCount := 2;
    grdCampos.Rows[1].Clear;
  end
  else
    grdCampos.RowCount := Length(FLinhas) + 1;

  for i := 1 to Length(FLinhas) do
    PreencherLinha(i);
  if FOrdemColuna >= 0 then
    OrdenarLinhas;

  for i := 1 to Length(FLinhas) do
    if SameText(FLinhas[i - 1], vSelecionado) then
      grdCampos.Row := i;

  grdCampos.Invalidate;
  MostrarDetalhe;
  AtualizarResumo;
  AtualizarColunasUsadas;
end;

procedure TfrmPerfilEdicao.AtualizarTitulosCampos;
var
  c: Integer;
begin
  for c := cCOL_CAMPO to cCOL_TRANSFORMACOES do
  begin
    grdCampos.Cells[c, 0] := cTITULOS_CAMPOS[c];
    if c = FOrdemColuna then
    begin
      if FOrdemDecrescente then
        grdCampos.Cells[c, 0] := cTITULOS_CAMPOS[c] + '  ▼'
      else
        grdCampos.Cells[c, 0] := cTITULOS_CAMPOS[c] + '  ▲';
    end;
  end;
end;

procedure TfrmPerfilEdicao.OrdenarLinhas;
var
  vChaves: TArray<TChaveOrdenacao>;
  vDecrescente: Boolean;
  i: Integer;
begin
  // Ordena pelo texto exibido na coluna escolhida; vazios sempre no fim; empate mantém a ordem do banco
  SetLength(vChaves, Length(FLinhas));
  for i := 0 to High(FLinhas) do
  begin
    vChaves[i].Nome := FLinhas[i];
    vChaves[i].Chave := Trim(grdCampos.Cells[FOrdemColuna, i + 1]);
    vChaves[i].Posicao := i;
  end;

  vDecrescente := FOrdemDecrescente;
  TArray.Sort<TChaveOrdenacao>(vChaves, TComparer<TChaveOrdenacao>.Construct(
    function(const A, B: TChaveOrdenacao): Integer
    begin
      if (A.Chave = '') <> (B.Chave = '') then
      begin
        if A.Chave = '' then
          Exit(1)
        else
          Exit(-1);
      end;
      Result := CompareText(A.Chave, B.Chave);
      if vDecrescente then
        Result := -Result;
      if Result = 0 then
        Result := A.Posicao - B.Posicao;
    end));

  for i := 0 to High(vChaves) do
    FLinhas[i] := vChaves[i].Nome;
  for i := 1 to Length(FLinhas) do
    PreencherLinha(i);
end;

procedure TfrmPerfilEdicao.grdCamposFixedCellClick(Sender: TObject; ACol, ARow: Integer);
begin
  if ARow <> 0 then
    Exit;

  // Mesmo título: inverte a ordem; outro título: crescente por ele
  if ACol = FOrdemColuna then
    FOrdemDecrescente := not FOrdemDecrescente
  else
  begin
    FOrdemColuna := ACol;
    FOrdemDecrescente := False;
  end;
  AtualizarTitulosCampos;
  MontarGrade;
end;

procedure TfrmPerfilEdicao.PreencherLinha(ARow: Integer);
var
  vCampo: TCampoPerfil;
  vCampoDestino: TCampoDestino;
  vOriginal, vResultado, vNomes: string;
  vTransformacao: TTransformacao;
begin
  vCampo := CampoDaLinha(ARow);
  if vCampo = nil then
    Exit;

  grdCampos.Cells[cCOL_CAMPO, ARow] := vCampo.CampoDestino;
  if CampoDestinoPorNome(vCampo.CampoDestino, vCampoDestino) then
  begin
    grdCampos.Cells[cCOL_TIPO, ARow] := vCampoDestino.TipoSql;
    if vCampoDestino.Obrigatorio then
      grdCampos.Cells[cCOL_OBRIGATORIO, ARow] := 'Sim'
    else
      grdCampos.Cells[cCOL_OBRIGATORIO, ARow] := '';
  end
  else
  begin
    grdCampos.Cells[cCOL_TIPO, ARow] := '(não existe na tabela)';
    grdCampos.Cells[cCOL_OBRIGATORIO, ARow] := '';
  end;

  if vCampo.Mapeado then
    grdCampos.Cells[cCOL_ORIGEM, ARow] := cORIGENS[vCampo.Origem].Nome
  else
    grdCampos.Cells[cCOL_ORIGEM, ARow] := '';
  grdCampos.Cells[cCOL_VALOR, ARow] := vCampo.Resumo;

  CalcularExemplo(vCampo, vOriginal, vResultado);
  grdCampos.Cells[cCOL_EXEMPLO, ARow] := vResultado;

  vNomes := '';
  for vTransformacao in vCampo.Transformacoes do
  begin
    if vNomes <> '' then
      vNomes := vNomes + ' > ';
    vNomes := vNomes + cTRANSFORMACOES[vTransformacao.Tipo].Nome;
  end;
  grdCampos.Cells[cCOL_TRANSFORMACOES, ARow] := vNomes;
end;

procedure TfrmPerfilEdicao.grdCamposDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
  State: TGridDrawState);
var
  vCampo: TCampoPerfil;
  vCampoDestino: TCampoDestino;
  vCanvas: TCanvas;
begin
  if ARow = 0 then
    Exit;
  vCampo := CampoDaLinha(ARow);
  if vCampo = nil then
    Exit;

  vCanvas := grdCampos.Canvas;
  if gdSelected in State then
  begin
    vCanvas.Brush.Color := clHighlight;
    vCanvas.Font.Color := clHighlightText;
  end
  else
  begin
    vCanvas.Font.Color := clWindowText;
    if not CampoDestinoPorNome(vCampo.CampoDestino, vCampoDestino) and (Length(FCamposDestino) > 0) then
      vCanvas.Brush.Color := cCOR_NAO_EXISTE
    else if vCampo.Mapeado then
      vCanvas.Brush.Color := cCOR_MAPEADO
    else if vCampoDestino.Obrigatorio then
      vCanvas.Brush.Color := cCOR_OBRIGATORIO_SEM_MAPEAMENTO
    else
      vCanvas.Brush.Color := clWindow;
  end;
  vCanvas.FillRect(Rect);
  vCanvas.TextRect(Rect, Rect.Left + 4, Rect.Top + 3, grdCampos.Cells[ACol, ARow]);
end;

procedure TfrmPerfilEdicao.grdCamposClick(Sender: TObject);
begin
  // OnClick do TStringGrid dispara depois que a linha atual mudou (mouse ou teclado)
  MostrarDetalhe;
end;

procedure TfrmPerfilEdicao.AtualizarResumo;
var
  vCampoDestino: TCampoDestino;
  vCampo: TCampoPerfil;
  vObrigatoriosSemMapeamento: Integer;
begin
  vObrigatoriosSemMapeamento := 0;
  for vCampoDestino in FCamposDestino do
    if vCampoDestino.Obrigatorio then
    begin
      vCampo := FPerfil.CampoPorNome(vCampoDestino.Nome);
      if (vCampo = nil) or not vCampo.Mapeado then
        Inc(vObrigatoriosSemMapeamento);
    end;
  lblResumo.Caption := Format('%d campos mapeados  |  %d obrigatórios sem mapeamento',
    [Length(FPerfil.CamposMapeados), vObrigatoriosSemMapeamento]);
end;

{ Colunas da planilha e onde são usadas }

procedure TfrmPerfilEdicao.AtualizarColunasUsadas;
var
  vUso: TDictionary<string, TUsoColuna>;
  vCampo: TCampoPerfil;
  vNome: string;
  vColuna: TColunaPlanilha;
  vLinha: TUsoColuna;
  vSobras: TArray<TUsoColuna>;
  vUsadas, i: Integer;
begin
  vUso := TDictionary<string, TUsoColuna>.Create;
  try
    // Coluna (em maiúsculas) -> campos de destino que a usam
    for vCampo in FPerfil.CamposMapeados do
      for vNome in vCampo.ColunasUsadas do
      begin
        if vUso.TryGetValue(UpperCase(vNome), vLinha) then
          vLinha.UsadaEm := vLinha.UsadaEm + ', ' + vCampo.CampoDestino
        else
        begin
          vLinha.Nome := vNome;
          vLinha.Tipo := '';
          vLinha.UsadaEm := vCampo.CampoDestino;
          vLinha.Existe := True;
        end;
        vUso.AddOrSetValue(UpperCase(vNome), vLinha);
      end;

    // Colunas da planilha na ordem da planilha
    FUsoColunas := nil;
    vUsadas := 0;
    for vColuna in FColunas do
    begin
      if vUso.TryGetValue(UpperCase(vColuna.Nome), vLinha) then
      begin
        Inc(vUsadas);
        vUso.Remove(UpperCase(vColuna.Nome));
      end
      else
        vLinha.UsadaEm := '';
      vLinha.Nome := vColuna.Nome;
      vLinha.Tipo := vColuna.Tipo;
      vLinha.Existe := True;
      if not (chkSoNaoUsadas.Checked and (vLinha.UsadaEm <> '')) then
        FUsoColunas := FUsoColunas + [vLinha];
    end;

    // Sobraram as citadas no perfil que não existem na planilha (ou todas, se a planilha não foi carregada)
    if not chkSoNaoUsadas.Checked then
    begin
      vSobras := vUso.Values.ToArray;
      TArray.Sort<TUsoColuna>(vSobras, TComparer<TUsoColuna>.Construct(
        function(const A, B: TUsoColuna): Integer
        begin
          Result := CompareText(A.Nome, B.Nome);
        end));
      for i := 0 to High(vSobras) do
      begin
        vSobras[i].Existe := not FPlanilhaCarregada;
        if FPlanilhaCarregada then
          vSobras[i].Tipo := '(não existe)';
        FUsoColunas := FUsoColunas + [vSobras[i]];
      end;
    end;
  finally
    vUso.Free;
  end;

  for i := 1 to grdColunas.RowCount - 1 do
    grdColunas.Rows[i].Clear;
  if Length(FUsoColunas) = 0 then
    grdColunas.RowCount := 2
  else
    grdColunas.RowCount := Length(FUsoColunas) + 1;
  for i := 0 to High(FUsoColunas) do
  begin
    grdColunas.Cells[0, i + 1] := FUsoColunas[i].Nome;
    grdColunas.Cells[1, i + 1] := FUsoColunas[i].Tipo;
    grdColunas.Cells[2, i + 1] := FUsoColunas[i].UsadaEm;
  end;

  if FPlanilhaCarregada then
    lblColunasPlanilha.Caption := Format('Colunas da planilha: %d de %d usadas', [vUsadas, Length(FColunas)])
  else
    lblColunasPlanilha.Caption := 'Colunas usadas no perfil (carregue a planilha)';
  grdColunas.Invalidate;
end;

procedure TfrmPerfilEdicao.chkSoNaoUsadasClick(Sender: TObject);
begin
  AtualizarColunasUsadas;
end;

procedure TfrmPerfilEdicao.grdColunasDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
  State: TGridDrawState);
var
  vCanvas: TCanvas;
begin
  if (ARow = 0) or (ARow > Length(FUsoColunas)) then
    Exit;

  vCanvas := grdColunas.Canvas;
  if gdSelected in State then
  begin
    vCanvas.Brush.Color := clHighlight;
    vCanvas.Font.Color := clHighlightText;
  end
  else
  begin
    vCanvas.Font.Color := clWindowText;
    if not FUsoColunas[ARow - 1].Existe then
      vCanvas.Brush.Color := cCOR_NAO_EXISTE
    else if FUsoColunas[ARow - 1].UsadaEm <> '' then
      vCanvas.Brush.Color := cCOR_MAPEADO
    else
      vCanvas.Brush.Color := clWindow;
  end;
  vCanvas.FillRect(Rect);
  vCanvas.TextRect(Rect, Rect.Left + 4, Rect.Top + 3, grdColunas.Cells[ACol, ARow]);
end;

procedure TfrmPerfilEdicao.grdColunasDblClick(Sender: TObject);
var
  vCampo: TCampoPerfil;
  vColuna: string;
begin
  if (grdColunas.Row < 1) or (grdColunas.Row > Length(FUsoColunas)) then
    Exit;
  if not FUsoColunas[grdColunas.Row - 1].Existe then
  begin
    TMensagens.Alerta('Esta coluna não existe na planilha carregada.');
    Exit;
  end;
  vCampo := CampoSelecionado;
  if vCampo = nil then
  begin
    TMensagens.Alerta('Selecione na grade o campo de destino que vai receber esta coluna.');
    Exit;
  end;
  vColuna := FUsoColunas[grdColunas.Row - 1].Nome;

  // Duplo clique liga a coluna ao campo selecionado (na expressão, acrescenta {Coluna})
  case vCampo.Origem of
    ovNaoImportar:
      begin
        vCampo.Origem := ovColuna;
        vCampo.Coluna := vColuna;
      end;
    ovColuna, ovPadrao, ovConsulta:
      vCampo.Coluna := vColuna;
    ovExpressao:
      vCampo.Expressao := vCampo.Expressao + '{' + vColuna + '}';
    ovFixo, ovGerado:
      begin
        if not TMensagens.Confirmacao(Format('O campo %s está como "%s". Trocar para a coluna "%s"?',
          [vCampo.CampoDestino, cORIGENS[vCampo.Origem].Nome, vColuna])) then
          Exit;
        vCampo.Origem := ovColuna;
        vCampo.Coluna := vColuna;
      end;
  end;

  PreencherLinha(grdCampos.Row);
  grdCampos.Invalidate;
  MostrarDetalhe;
  AtualizarResumo;
  AtualizarColunasUsadas;
end;

{ Exemplo }

function TfrmPerfilEdicao.ObterCelulaExemplo: TObterCelula;
begin
  Result :=
    function(const AColuna: string; out AValor: Variant; out ATexto: string): Boolean
    var
      vColuna: TColunaPlanilha;
    begin
      Result := ColunaPorNome(AColuna, vColuna);
      if Result then
      begin
        AValor := vColuna.ExemploValor;
        ATexto := vColuna.Exemplo;
      end
      else
      begin
        AValor := Null;
        ATexto := '';
      end;
    end;
end;

function TfrmPerfilEdicao.CalcularExemplo(ACampo: TCampoPerfil; out AOriginal, AResultado: string): Boolean;
var
  vDestino: TCampoDestino;
  vTemDestino: Boolean;
  vResolvido: TValorResolvido;
begin
  // Usa a mesma regra da importação (uImportador), aplicada ao primeiro valor não vazio de cada coluna
  Result := True;
  AOriginal := '';
  AResultado := '';
  if not ACampo.Mapeado then
    Exit;
  if not FPlanilhaCarregada and (ACampo.Origem in [ovColuna, ovPadrao, ovConsulta, ovExpressao, ovConsultaSql]) then
  begin
    AResultado := '(carregue a planilha)';
    Exit;
  end;

  vTemDestino := CampoDestinoPorNome(ACampo.CampoDestino, vDestino);
  if not vTemDestino and (Length(FCamposDestino) = 0) then
  begin
    // Sem conexão com o destino: mostra o valor sem conferir o tipo do campo
    vDestino.Categoria := ccTextoLongo;
    vTemDestino := True;
  end;

  // Com conexão, a origem Consulta pesquisa no destino de verdade (com cache)
  if FDmDestino.Conectado then
    vResolvido := ResolverCampo(ACampo, vDestino, vTemDestino, ObterCelulaExemplo(), FConsultas.Consultar,
      FConsultas.ConsultarSql)
  else
    vResolvido := ResolverCampo(ACampo, vDestino, vTemDestino, ObterCelulaExemplo());
  AOriginal := vResolvido.ValorRecebido;
  if not vResolvido.Ok then
  begin
    AResultado := 'ERRO: ' + vResolvido.Mensagem;
    Exit(False);
  end;

  if vResolvido.Fonte = fvGerado then
    AResultado := '(próximo valor de ' + ACampo.Generator + ')'
  else if VarIsNull(vResolvido.Valor) then
    AResultado := '(nulo)'
  else
    AResultado := ValorParaTexto(vResolvido.Valor);
  if vResolvido.Fonte = fvPadrao then
    AResultado := AResultado + '  (padrão)';
  if (vResolvido.Fonte = fvConsulta) and not FDmDestino.Conectado then
    AResultado := AResultado + '  -> pesquisa em ' + ACampo.ConsultaTabela
  else if vResolvido.Fonte = fvConsulta then
    AResultado := AResultado + '  (de ' + ACampo.ConsultaTabela + ')';
end;

procedure TfrmPerfilEdicao.AtualizarExemplo;
var
  vCampo: TCampoPerfil;
  vOriginal, vResultado: string;
begin
  vCampo := CampoSelecionado;
  if (vCampo = nil) or not vCampo.Mapeado then
  begin
    lblExemplo.Caption := '';
    Exit;
  end;

  CalcularExemplo(vCampo, vOriginal, vResultado);
  if vCampo.Origem in [ovColuna, ovPadrao, ovConsulta, ovExpressao, ovConsultaSql] then
    lblExemplo.Caption := 'Exemplo: "' + vOriginal + '"  ->  "' + vResultado + '"'
  else
    lblExemplo.Caption := 'Resultado: ' + vResultado;
end;

{ Painel do campo selecionado }

procedure TfrmPerfilEdicao.MostrarDetalhe;
var
  vCampo: TCampoPerfil;
  vCampoDestino: TCampoDestino;
begin
  vCampo := CampoSelecionado;
  pnlDetalhe.Enabled := vCampo <> nil;

  FCarregando := True;
  try
    if vCampo = nil then
    begin
      lblCampo.Caption := '';
      lblCampoInfo.Caption := '';
      cbxOrigem.ItemIndex := -1;
      lstTransformacoes.Clear;
      AjustarPainelOrigem;
      Exit;
    end;

    lblCampo.Caption := vCampo.CampoDestino;
    if CampoDestinoPorNome(vCampo.CampoDestino, vCampoDestino) then
    begin
      lblCampoInfo.Caption := vCampoDestino.TipoSql;
      if vCampoDestino.Obrigatorio then
        lblCampoInfo.Caption := lblCampoInfo.Caption + '  |  obrigatório';
      if vCampoDestino.ChavePrimaria then
        lblCampoInfo.Caption := lblCampoInfo.Caption + '  |  chave primária';
      if vCampoDestino.Referencia <> '' then
        lblCampoInfo.Caption := lblCampoInfo.Caption + '  |  FK ' + vCampoDestino.Referencia;
    end
    else
      lblCampoInfo.Caption := '(não existe na tabela de destino)';

    cbxOrigem.ItemIndex := Ord(vCampo.Origem);
    cbxColuna.Text := vCampo.Coluna;
    edtValorFixo.Text := vCampo.ValorFixo;
    edtValorPadrao.Text := vCampo.ValorPadrao;
    chkSeInexistente.Checked := vCampo.PadraoSeInexistente;
    chkSeVazio.Checked := vCampo.PadraoSeVazio;
    chkSeInvalido.Checked := vCampo.PadraoSeInvalido;
    cbxGenerator.Text := vCampo.Generator;
    edtExpressao.Text := vCampo.Expressao;
    cbxConsultaTabela.Text := vCampo.ConsultaTabela;
    edtConsultaPesquisa.Text := vCampo.ConsultaCampoPesquisa;
    edtConsultaRetorno.Text := vCampo.ConsultaCampoRetorno;
    cbxConsultaSeNaoAchar.ItemIndex := Ord(vCampo.ConsultaSeNaoAchar);
    cbxConsultaSqlSeNaoAchar.ItemIndex := Ord(vCampo.ConsultaSeNaoAchar);
    mmoConsultaSql.Text := vCampo.ConsultaSql;
    MostrarTransformacoes;
    LimparTransformacaoDaTela;
    AjustarPainelOrigem;
  finally
    FCarregando := False;
  end;
  AtualizarExemplo;
end;

procedure TfrmPerfilEdicao.AjustarPainelOrigem;
var
  vOrigem: TOrigemValor;
  vTopo: Integer;

  procedure Posicionar(APainel: TPanel; AVisivel: Boolean);
  begin
    APainel.Visible := AVisivel;
    if AVisivel then
    begin
      APainel.Top := vTopo;
      Inc(vTopo, APainel.Height);
    end;
  end;

begin
  if cbxOrigem.ItemIndex < 0 then
    vOrigem := ovNaoImportar
  else
    vOrigem := TOrigemValor(cbxOrigem.ItemIndex);

  vTopo := cbxOrigem.Top + cbxOrigem.Height + 8;
  Posicionar(pnlColuna, vOrigem in [ovColuna, ovPadrao, ovConsulta, ovConsultaSql]);
  Posicionar(pnlFixo, vOrigem = ovFixo);
  Posicionar(pnlPadrao, vOrigem = ovPadrao);
  Posicionar(pnlGerado, vOrigem = ovGerado);
  Posicionar(pnlExpressao, vOrigem = ovExpressao);
  Posicionar(pnlConsulta, vOrigem = ovConsulta);
  Posicionar(pnlConsultaSql, vOrigem = ovConsultaSql);

  // Valor gerado vem do banco: não passa por transformações
  grpTransformacoes.Visible := not (vOrigem in [ovNaoImportar, ovGerado]);
end;

procedure TfrmPerfilEdicao.LerDetalhe;
var
  vCampo: TCampoPerfil;
begin
  vCampo := CampoSelecionado;
  if vCampo = nil then
    Exit;

  if cbxOrigem.ItemIndex >= 0 then
    vCampo.Origem := TOrigemValor(cbxOrigem.ItemIndex);
  vCampo.Coluna := Trim(cbxColuna.Text);
  vCampo.ValorFixo := edtValorFixo.Text;
  vCampo.ValorPadrao := edtValorPadrao.Text;
  vCampo.PadraoSeInexistente := chkSeInexistente.Checked;
  vCampo.PadraoSeVazio := chkSeVazio.Checked;
  vCampo.PadraoSeInvalido := chkSeInvalido.Checked;
  vCampo.Generator := Trim(cbxGenerator.Text);
  vCampo.Expressao := edtExpressao.Text;
  vCampo.ConsultaTabela := UpperCase(Trim(cbxConsultaTabela.Text));
  vCampo.ConsultaCampoPesquisa := UpperCase(Trim(edtConsultaPesquisa.Text));
  vCampo.ConsultaCampoRetorno := UpperCase(Trim(edtConsultaRetorno.Text));
  // "Se não encontrar" existe nos dois painéis de consulta: vale o da origem escolhida
  if (vCampo.Origem = ovConsultaSql) and (cbxConsultaSqlSeNaoAchar.ItemIndex >= 0) then
    vCampo.ConsultaSeNaoAchar := TAcaoNaoEncontrado(cbxConsultaSqlSeNaoAchar.ItemIndex)
  else if cbxConsultaSeNaoAchar.ItemIndex >= 0 then
    vCampo.ConsultaSeNaoAchar := TAcaoNaoEncontrado(cbxConsultaSeNaoAchar.ItemIndex);
  vCampo.ConsultaSql := Trim(mmoConsultaSql.Text);
end;

procedure TfrmPerfilEdicao.OpcaoChange(Sender: TObject);
begin
  if FCarregando then
    Exit;
  LerDetalhe;
  if Sender = cbxOrigem then
    AjustarPainelOrigem;
  PreencherLinha(grdCampos.Row);
  grdCampos.Invalidate;
  AtualizarExemplo;
  AtualizarResumo;
  AtualizarColunasUsadas;
end;

procedure TfrmPerfilEdicao.btnTestarSqlClick(Sender: TObject);
var
  vCampo: TCampoPerfil;
  vMensagem, vOriginal, vResultado, vSqlFinal: string;
begin
  vCampo := CampoSelecionado;
  if vCampo = nil then
    Exit;
  OpcaoChange(nil);
  if not FDmDestino.Conectado then
  begin
    TMensagens.Alerta('Sem conexão com o banco de destino: escolha a conexão do perfil.');
    Exit;
  end;

  // Primeiro confere o SQL no banco (sintaxe, tabelas, campos); depois executa com os valores de exemplo
  MontarSqlManual(vCampo.ConsultaSql, vSqlFinal);
  vMensagem := FDmDestino.TestarSql(vSqlFinal);
  if vMensagem <> '' then
  begin
    TMensagens.Alerta('O SELECT tem problema:' + sLineBreak + sLineBreak + vMensagem);
    Exit;
  end;
  if not FPlanilhaCarregada then
  begin
    TMensagens.Info('O SELECT é válido. Carregue a planilha para testar com valores de exemplo.');
    Exit;
  end;

  if CalcularExemplo(vCampo, vOriginal, vResultado) then
    TMensagens.Info('O SELECT é válido.' + sLineBreak + sLineBreak + 'Com os valores de exemplo da planilha: ' +
      vResultado)
  else
    TMensagens.Alerta('O SELECT é válido, mas com os valores de exemplo da planilha:' + sLineBreak + sLineBreak +
      vResultado);
end;

{ Transformações }

procedure TfrmPerfilEdicao.MostrarTransformacoes(AIndiceSelecionado: Integer);
var
  vCampo: TCampoPerfil;
  vTransformacao: TTransformacao;
  vTexto: string;
begin
  lstTransformacoes.Items.BeginUpdate;
  try
    lstTransformacoes.Clear;
    vCampo := CampoSelecionado;
    if vCampo <> nil then
      for vTransformacao in vCampo.Transformacoes do
      begin
        vTexto := cTRANSFORMACOES[vTransformacao.Tipo].Nome;
        if vTransformacao.Parametro <> '' then
          vTexto := vTexto + '  [' + vTransformacao.Parametro + ']';
        lstTransformacoes.Items.Add(vTexto);
      end;
  finally
    lstTransformacoes.Items.EndUpdate;
  end;
  if (AIndiceSelecionado >= 0) and (AIndiceSelecionado < lstTransformacoes.Count) then
    lstTransformacoes.ItemIndex := AIndiceSelecionado;
end;

procedure TfrmPerfilEdicao.lstTransformacoesClick(Sender: TObject);
var
  vCampo: TCampoPerfil;
  vIndice: Integer;
begin
  vCampo := CampoSelecionado;
  vIndice := lstTransformacoes.ItemIndex;
  if (vCampo = nil) or (vIndice < 0) then
    Exit;
  cbxTipoTransformacao.ItemIndex := Ord(vCampo.Transformacoes[vIndice].Tipo);
  edtParametroTransformacao.Text := vCampo.Transformacoes[vIndice].Parametro;
  cbxTipoTransformacaoChange(nil);
end;

procedure TfrmPerfilEdicao.LimparTransformacaoDaTela;
begin
  cbxTipoTransformacao.ItemIndex := -1;
  edtParametroTransformacao.Text := '';
  lblAjudaTransformacao.Caption := '';
end;

procedure TfrmPerfilEdicao.cbxTipoTransformacaoChange(Sender: TObject);
begin
  // Trocar o tipo pelo combo limpa o parâmetro (o de um tipo não serve para outro);
  // Sender = nil quando o tipo vem da lista (lstTransformacoesClick), que já preencheu o parâmetro
  if Sender <> nil then
    edtParametroTransformacao.Text := '';

  if cbxTipoTransformacao.ItemIndex < 0 then
    lblAjudaTransformacao.Caption := ''
  else if cTRANSFORMACOES[TTipoTransformacao(cbxTipoTransformacao.ItemIndex)].AjudaParametro = '' then
    lblAjudaTransformacao.Caption := 'Sem parâmetro.'
  else
    lblAjudaTransformacao.Caption := 'Parâmetro: ' +
      cTRANSFORMACOES[TTipoTransformacao(cbxTipoTransformacao.ItemIndex)].AjudaParametro;
end;

function TfrmPerfilEdicao.LerTransformacaoDaTela(out ATransformacao: TTransformacao): Boolean;
begin
  Result := (CampoSelecionado <> nil) and (cbxTipoTransformacao.ItemIndex >= 0);
  if not Result then
  begin
    TMensagens.Alerta('Selecione o tipo de transformação.');
    Exit;
  end;
  ATransformacao.Tipo := TTipoTransformacao(cbxTipoTransformacao.ItemIndex);
  ATransformacao.Parametro := edtParametroTransformacao.Text;
end;

procedure TfrmPerfilEdicao.btnAdicionarTransformacaoClick(Sender: TObject);
var
  vTransformacao: TTransformacao;
  vCampo: TCampoPerfil;
begin
  if not LerTransformacaoDaTela(vTransformacao) then
    Exit;
  vCampo := CampoSelecionado;
  vCampo.Transformacoes := vCampo.Transformacoes + [vTransformacao];
  MostrarTransformacoes;
  LimparTransformacaoDaTela;
  OpcaoChange(nil);
end;

procedure TfrmPerfilEdicao.btnAlterarTransformacaoClick(Sender: TObject);
var
  vTransformacao: TTransformacao;
  vCampo: TCampoPerfil;
  vIndice: Integer;
begin
  vIndice := lstTransformacoes.ItemIndex;
  if vIndice < 0 then
  begin
    TMensagens.Alerta('Selecione na lista a transformação que será alterada.');
    Exit;
  end;
  if not LerTransformacaoDaTela(vTransformacao) then
    Exit;
  vCampo := CampoSelecionado;
  vCampo.Transformacoes[vIndice] := vTransformacao;
  MostrarTransformacoes;
  LimparTransformacaoDaTela;
  OpcaoChange(nil);
end;

procedure TfrmPerfilEdicao.btnRemoverClick(Sender: TObject);
var
  vCampo: TCampoPerfil;
  vIndice: Integer;
begin
  vCampo := CampoSelecionado;
  vIndice := lstTransformacoes.ItemIndex;
  if (vCampo = nil) or (vIndice < 0) then
    Exit;
  Delete(vCampo.Transformacoes, vIndice, 1);
  MostrarTransformacoes(vIndice - 1);
  OpcaoChange(nil);
end;

procedure TfrmPerfilEdicao.btnSubirClick(Sender: TObject);
var
  vCampo: TCampoPerfil;
  vIndice: Integer;
  vTemporaria: TTransformacao;
begin
  vCampo := CampoSelecionado;
  vIndice := lstTransformacoes.ItemIndex;
  if (vCampo = nil) or (vIndice < 1) then
    Exit;
  vTemporaria := vCampo.Transformacoes[vIndice - 1];
  vCampo.Transformacoes[vIndice - 1] := vCampo.Transformacoes[vIndice];
  vCampo.Transformacoes[vIndice] := vTemporaria;
  MostrarTransformacoes(vIndice - 1);
  OpcaoChange(nil);
end;

procedure TfrmPerfilEdicao.btnDescerClick(Sender: TObject);
var
  vCampo: TCampoPerfil;
  vIndice: Integer;
  vTemporaria: TTransformacao;
begin
  vCampo := CampoSelecionado;
  vIndice := lstTransformacoes.ItemIndex;
  if (vCampo = nil) or (vIndice < 0) or (vIndice >= High(vCampo.Transformacoes)) then
    Exit;
  vTemporaria := vCampo.Transformacoes[vIndice + 1];
  vCampo.Transformacoes[vIndice + 1] := vCampo.Transformacoes[vIndice];
  vCampo.Transformacoes[vIndice] := vTemporaria;
  MostrarTransformacoes(vIndice + 1);
  OpcaoChange(nil);
end;

{ Sugestão de mapeamento }

procedure TfrmPerfilEdicao.btnSugerirClick(Sender: TObject);
var
  vCampoDestino: TCampoDestino;
  vCampo: TCampoPerfil;
  vColuna: TColunaPlanilha;
  vTransformacao: TTransformacao;
  vSugeridos: Integer;
begin
  if not FPlanilhaCarregada or (Length(FCamposDestino) = 0) then
  begin
    TMensagens.Alerta('Carregue a tabela de destino e a planilha antes de sugerir o mapeamento.');
    Exit;
  end;

  vSugeridos := 0;
  for vCampoDestino in FCamposDestino do
  begin
    vCampo := FPerfil.AdicionarCampo(vCampoDestino.Nome);
    if vCampo.Mapeado or vCampoDestino.Calculado then
      Continue;

    for vColuna in FColunas do
      if NomeNormalizado(vColuna.Nome) = NomeNormalizado(vCampoDestino.Nome) then
      begin
        vCampo.Origem := ovColuna;
        vCampo.Coluna := vColuna.Nome;
        vCampo.Transformacoes := nil;

        // Coluna de texto num campo numérico ou de data precisa de conversão explícita
        if vColuna.Tipo = 'Texto' then
        begin
          vTransformacao.Parametro := '';
          case vCampoDestino.Categoria of
            ccInteiro:
              begin
                vTransformacao.Tipo := ttTextoParaInteiro;
                vCampo.Transformacoes := [vTransformacao];
              end;
            ccDecimal:
              begin
                vTransformacao.Tipo := ttTextoParaDecimal;
                vCampo.Transformacoes := [vTransformacao];
              end;
            ccData:
              begin
                vTransformacao.Tipo := ttTextoParaData;
                vCampo.Transformacoes := [vTransformacao];
              end;
            ccDataHora:
              begin
                vTransformacao.Tipo := ttTextoParaDataHora;
                vCampo.Transformacoes := [vTransformacao];
              end;
          end;
        end;
        Inc(vSugeridos);
        Break;
      end;
  end;

  MontarGrade;
  TMensagens.Info(Format('%d campos mapeados pelo nome da coluna. Confira cada um antes de gravar.',
    [vSugeridos]));
end;

{ Gravação }

procedure TfrmPerfilEdicao.LerCabecalho;
begin
  FPerfil.Nome := Trim(edtNome.Text);
  FPerfil.Descricao := Trim(edtDescricao.Text);
  FPerfil.TabelaDestino := UpperCase(Trim(cbxTabela.Text));
  FPerfil.ArquivoExemplo := Trim(edtPlanilha.Text);
  FPerfil.Aba := cbxAba.Text;
  FPerfil.LinhaCabecalho := udLinhaCabecalho.Position;
  FPerfil.LinhaInicial := udLinhaInicial.Position;
  if cbxConexao.ItemIndex >= 0 then
    FPerfil.IdConexao := Integer(cbxConexao.Items.Objects[cbxConexao.ItemIndex]);

  FPerfil.Estrategia := TEstrategiaGravacao(cbxEstrategia.ItemIndex);
  FPerfil.AcaoErro := TAcaoErro(cbxAcaoErro.ItemIndex);
  // Sem a lista (destino fora do ar), mantém os campos-chave que o perfil já tinha
  if clbCamposChave.Items.Count > 0 then
    FPerfil.DefinirCamposChave(CamposChaveMarcados);
end;

function TfrmPerfilEdicao.CamposChaveMarcados: TArray<string>;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to clbCamposChave.Items.Count - 1 do
    if clbCamposChave.Checked[i] then
      Result := Result + [clbCamposChave.Items[i]];
end;

procedure TfrmPerfilEdicao.btnGravarClick(Sender: TObject);
var
  vCampoDestino: TCampoDestino;
  vCampo: TCampoPerfil;
  vFaltando: string;
begin
  LerCabecalho;

  vFaltando := '';
  for vCampoDestino in FCamposDestino do
    if vCampoDestino.Obrigatorio then
    begin
      vCampo := FPerfil.CampoPorNome(vCampoDestino.Nome);
      if (vCampo = nil) or not vCampo.Mapeado then
        vFaltando := vFaltando + sLineBreak + '  ' + vCampoDestino.Nome;
    end;
  if (vFaltando <> '') and not TMensagens.Confirmacao('Campos obrigatórios sem mapeamento:' + vFaltando +
    sLineBreak + sLineBreak + 'A importação vai falhar sem eles. Gravar mesmo assim?') then
    Exit;

  try
    FDm.Gravar(FPerfil);
  except
    on E: Exception do
    begin
      TMensagens.Alerta(E.Message);
      Exit;
    end;
  end;
  ModalResult := mrOk;
end;

end.
