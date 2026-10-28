unit uPerfilModelo;

{ Modelo do perfil de importação (sem tela e sem banco).
  Durante a edição o perfil tem um TCampoPerfil para cada campo da tabela de destino; só os mapeados
  (Origem <> ovNaoImportar) são gravados no banco. }

interface

uses
  System.SysUtils, System.Generics.Collections, uTransformacoes;

type
  // Origem do valor de um campo de destino. Não há precedência implícita entre elas:
  // - ovColuna: só o valor da coluna (vazio continua vazio)
  // - ovPadrao: o valor da coluna, trocado pelo padrão SÓ nas condições marcadas
  // - ovConsultaSql: SELECT escrito no perfil; {Coluna} e {valor} viram parâmetros
  TOrigemValor = (ovNaoImportar, ovColuna, ovFixo, ovPadrao, ovConsulta, ovGerado, ovExpressao, ovConsultaSql);

  // O que fazer quando a consulta ao banco não encontra o registro
  TAcaoNaoEncontrado = (anePendencia, aneNulo);

  // Como gravar cada linha válida (as que precisam saber se o registro existe usam os campos-chave)
  TEstrategiaGravacao = (egInserir, egIgnorarExistentes, egAtualizar, egInserirOuAtualizar, egSomenteValidar);

  // O que fazer quando uma linha tem erro
  TAcaoErro = (aeContinuar, aeParar, aeDesfazerTudo);

  TInfoOrigem = record
    Codigo: string;
    Nome: string;
  end;

  TCampoPerfil = class
  public
    CampoDestino: string;
    Origem: TOrigemValor;
    Coluna: string;
    ValorFixo: string;
    ValorPadrao: string;
    PadraoSeInexistente: Boolean;
    PadraoSeVazio: Boolean;
    PadraoSeInvalido: Boolean;
    Generator: string;
    Expressao: string;
    ConsultaTabela: string;
    ConsultaCampoPesquisa: string;
    ConsultaCampoRetorno: string;
    ConsultaSeNaoAchar: TAcaoNaoEncontrado;
    ConsultaSql: string;       // ovConsultaSql: SELECT com {Coluna} e {valor}
    Transformacoes: TArray<TTransformacao>;
    constructor Create(const ACampoDestino: string);
    procedure Assign(AOrigem: TCampoPerfil);
    function Mapeado: Boolean;
    function UsaColuna: Boolean;
    // Confere se a origem escolhida tem tudo o que precisa (não consulta planilha nem banco)
    function ValidarConfiguracao(out AMensagem: string): Boolean;
    // Resumo para a grade: coluna, valor fixo, generator...
    function Resumo: string;
    // Colunas da planilha que este campo lê: a coluna da origem e as citadas como {Coluna}
    // na expressão ou em transformações Concatenar
    function ColunasUsadas: TArray<string>;
  end;

  TPerfil = class
  private
    FCampos: TObjectList<TCampoPerfil>;
  public
    Id: Integer;
    Nome: string;
    Descricao: string;
    IdConexao: Integer;
    TabelaDestino: string;
    ArquivoExemplo: string;
    Aba: string;
    LinhaCabecalho: Integer;
    LinhaInicial: Integer;
    Estrategia: TEstrategiaGravacao;
    CamposChave: string;       // campos que identificam o registro no destino, separados por ";"
    AcaoErro: TAcaoErro;
    Versao: Integer;
    DataAlteracao: TDateTime;
    constructor Create;
    destructor Destroy; override;
    procedure Assign(AOrigem: TPerfil);
    function CampoPorNome(const ANome: string): TCampoPerfil;
    function AdicionarCampo(const ANome: string): TCampoPerfil;
    function CamposMapeados: TArray<TCampoPerfil>;
    function ListaCamposChave: TArray<string>;
    procedure DefinirCamposChave(const ACampos: TArray<string>);
    property Campos: TObjectList<TCampoPerfil> read FCampos;
  end;

const
  cORIGENS: array[TOrigemValor] of TInfoOrigem = (
    (Codigo: ''; Nome: 'Não importar'),
    (Codigo: 'COLUNA'; Nome: 'Coluna da planilha'),
    (Codigo: 'FIXO'; Nome: 'Valor fixo'),
    (Codigo: 'PADRAO'; Nome: 'Coluna com valor padrão'),
    (Codigo: 'CONSULTA'; Nome: 'Consulta ao banco'),
    (Codigo: 'GERADO'; Nome: 'Valor gerado (generator)'),
    (Codigo: 'EXPRESSAO'; Nome: 'Expressão'),
    (Codigo: 'CONSULTA_SQL'; Nome: 'Consulta SQL (manual)'));

  cACOES_NAO_ENCONTRADO: array[TAcaoNaoEncontrado] of TInfoOrigem = (
    (Codigo: 'PENDENCIA'; Nome: 'Pendência (não grava o registro)'),
    (Codigo: 'NULO'; Nome: 'Gravar nulo'));

  cESTRATEGIAS: array[TEstrategiaGravacao] of TInfoOrigem = (
    (Codigo: 'INSERIR'; Nome: 'Inserir'),
    (Codigo: 'IGNORAR_EXISTENTES'; Nome: 'Inserir só os novos (ignorar existentes)'),
    (Codigo: 'ATUALIZAR'; Nome: 'Atualizar só os existentes'),
    (Codigo: 'INSERIR_OU_ATUALIZAR'; Nome: 'Inserir os novos e atualizar os existentes'),
    (Codigo: 'SO_VALIDAR'; Nome: 'Só validar (não grava nada)'));

  cACOES_ERRO: array[TAcaoErro] of TInfoOrigem = (
    (Codigo: 'CONTINUAR'; Nome: 'Registrar o erro e continuar com as próximas linhas'),
    (Codigo: 'PARAR'; Nome: 'Parar a importação (mantém o que já foi gravado)'),
    (Codigo: 'DESFAZER_TUDO'; Nome: 'Parar e desfazer tudo (grava tudo ou nada)'));

function OrigemPorCodigo(const ACodigo: string; out AOrigem: TOrigemValor): Boolean;
function AcaoNaoEncontradoPorCodigo(const ACodigo: string): TAcaoNaoEncontrado;
function EstrategiaPorCodigo(const ACodigo: string): TEstrategiaGravacao;
function AcaoErroPorCodigo(const ACodigo: string): TAcaoErro;
// A estratégia precisa saber se o registro já existe no destino (usa os campos-chave)?
function EstrategiaUsaChave(AEstrategia: TEstrategiaGravacao): Boolean;

implementation

function OrigemPorCodigo(const ACodigo: string; out AOrigem: TOrigemValor): Boolean;
var
  vOrigem: TOrigemValor;
begin
  for vOrigem := Succ(ovNaoImportar) to High(TOrigemValor) do
    if SameText(cORIGENS[vOrigem].Codigo, Trim(ACodigo)) then
    begin
      AOrigem := vOrigem;
      Exit(True);
    end;
  Result := False;
end;

function AcaoNaoEncontradoPorCodigo(const ACodigo: string): TAcaoNaoEncontrado;
var
  vAcao: TAcaoNaoEncontrado;
begin
  for vAcao := Low(TAcaoNaoEncontrado) to High(TAcaoNaoEncontrado) do
    if SameText(cACOES_NAO_ENCONTRADO[vAcao].Codigo, Trim(ACodigo)) then
      Exit(vAcao);
  Result := anePendencia;
end;

function EstrategiaPorCodigo(const ACodigo: string): TEstrategiaGravacao;
var
  vEstrategia: TEstrategiaGravacao;
begin
  for vEstrategia := Low(TEstrategiaGravacao) to High(TEstrategiaGravacao) do
    if SameText(cESTRATEGIAS[vEstrategia].Codigo, Trim(ACodigo)) then
      Exit(vEstrategia);
  Result := egInserir;
end;

function AcaoErroPorCodigo(const ACodigo: string): TAcaoErro;
var
  vAcao: TAcaoErro;
begin
  for vAcao := Low(TAcaoErro) to High(TAcaoErro) do
    if SameText(cACOES_ERRO[vAcao].Codigo, Trim(ACodigo)) then
      Exit(vAcao);
  Result := aeContinuar;
end;

function EstrategiaUsaChave(AEstrategia: TEstrategiaGravacao): Boolean;
begin
  Result := AEstrategia in [egIgnorarExistentes, egAtualizar, egInserirOuAtualizar];
end;

{ TCampoPerfil }

constructor TCampoPerfil.Create(const ACampoDestino: string);
begin
  inherited Create;
  CampoDestino := ACampoDestino;
  Origem := ovNaoImportar;
  PadraoSeInexistente := True;
  PadraoSeVazio := True;
  PadraoSeInvalido := False;
  ConsultaSeNaoAchar := anePendencia;
end;

procedure TCampoPerfil.Assign(AOrigem: TCampoPerfil);
begin
  CampoDestino := AOrigem.CampoDestino;
  Origem := AOrigem.Origem;
  Coluna := AOrigem.Coluna;
  ValorFixo := AOrigem.ValorFixo;
  ValorPadrao := AOrigem.ValorPadrao;
  PadraoSeInexistente := AOrigem.PadraoSeInexistente;
  PadraoSeVazio := AOrigem.PadraoSeVazio;
  PadraoSeInvalido := AOrigem.PadraoSeInvalido;
  Generator := AOrigem.Generator;
  Expressao := AOrigem.Expressao;
  ConsultaTabela := AOrigem.ConsultaTabela;
  ConsultaCampoPesquisa := AOrigem.ConsultaCampoPesquisa;
  ConsultaCampoRetorno := AOrigem.ConsultaCampoRetorno;
  ConsultaSeNaoAchar := AOrigem.ConsultaSeNaoAchar;
  ConsultaSql := AOrigem.ConsultaSql;
  Transformacoes := Copy(AOrigem.Transformacoes);
end;

function TCampoPerfil.Mapeado: Boolean;
begin
  Result := Origem <> ovNaoImportar;
end;

function TCampoPerfil.UsaColuna: Boolean;
begin
  Result := Origem in [ovColuna, ovPadrao, ovConsulta];
end;

function TCampoPerfil.ValidarConfiguracao(out AMensagem: string): Boolean;
begin
  AMensagem := '';
  if UsaColuna and (Trim(Coluna) = '') then
    AMensagem := 'informe a coluna da planilha'
  else
    case Origem of
      ovFixo:
        if ValorFixo = '' then
          AMensagem := 'informe o valor fixo';
      ovPadrao:
        if ValorPadrao = '' then
          AMensagem := 'informe o valor padrão'
        else if not (PadraoSeInexistente or PadraoSeVazio or PadraoSeInvalido) then
          AMensagem := 'marque ao menos uma condição para usar o valor padrão';
      ovConsulta:
        if (Trim(ConsultaTabela) = '') or (Trim(ConsultaCampoPesquisa) = '') or
          (Trim(ConsultaCampoRetorno) = '') then
          AMensagem := 'informe a tabela, o campo de pesquisa e o campo de retorno da consulta';
      ovGerado:
        if Trim(Generator) = '' then
          AMensagem := 'informe o generator';
      ovExpressao:
        if Trim(Expressao) = '' then
          AMensagem := 'informe a expressão';
      ovConsultaSql:
        if Trim(ConsultaSql) = '' then
          AMensagem := 'informe o SELECT da consulta'
        else if (Pos('{valor}', LowerCase(ConsultaSql)) > 0) and (Trim(Coluna) = '') then
          AMensagem := 'a consulta usa {valor}: informe a coluna da planilha que fornece esse valor';
    end;
  Result := AMensagem = '';
end;

function TCampoPerfil.ColunasUsadas: TArray<string>;
var
  vLista: TArray<string>;

  procedure Adicionar(const ANome: string);
  var
    vExistente: string;
  begin
    if Trim(ANome) = '' then
      Exit;
    for vExistente in vLista do
      if SameText(vExistente, Trim(ANome)) then
        Exit;
    vLista := vLista + [Trim(ANome)];
  end;

var
  vNome: string;
  vTransformacao: TTransformacao;
begin
  vLista := nil;
  Result := nil;
  if not Mapeado then
    Exit;

  if UsaColuna then
    Adicionar(Coluna);
  if Origem = ovExpressao then
    for vNome in ColunasDoModelo(Expressao) do
      Adicionar(vNome);
  if Origem = ovConsultaSql then
  begin
    Adicionar(Coluna);
    for vNome in ColunasDoModelo(ConsultaSql) do
      Adicionar(vNome);
  end;
  // Valor gerado não passa por transformações
  if Origem <> ovGerado then
    for vTransformacao in Transformacoes do
      if vTransformacao.Tipo = ttConcatenar then
        for vNome in ColunasDoModelo(vTransformacao.Parametro) do
          Adicionar(vNome);
  Result := vLista;
end;

function TCampoPerfil.Resumo: string;
begin
  case Origem of
    ovColuna:
      Result := Coluna;
    ovFixo:
      Result := '= ' + ValorFixo;
    ovPadrao:
      Result := Coluna + '  (padrão: ' + ValorPadrao + ')';
    ovConsulta:
      Result := Coluna + ' -> ' + ConsultaTabela + '.' + ConsultaCampoRetorno;
    ovGerado:
      Result := Generator;
    ovExpressao:
      Result := Expressao;
    ovConsultaSql:
      Result := 'SQL: ' + StringReplace(Trim(ConsultaSql), sLineBreak, ' ', [rfReplaceAll]);
  else
    Result := '';
  end;
end;

{ TPerfil }

constructor TPerfil.Create;
begin
  inherited Create;
  FCampos := TObjectList<TCampoPerfil>.Create(True);
  LinhaCabecalho := 1;
  LinhaInicial := 2;
  Estrategia := egInserir;
  AcaoErro := aeContinuar;
  Versao := 0;
end;

destructor TPerfil.Destroy;
begin
  FCampos.Free;
  inherited;
end;

procedure TPerfil.Assign(AOrigem: TPerfil);
var
  vCampo: TCampoPerfil;
begin
  Id := AOrigem.Id;
  Nome := AOrigem.Nome;
  Descricao := AOrigem.Descricao;
  IdConexao := AOrigem.IdConexao;
  TabelaDestino := AOrigem.TabelaDestino;
  ArquivoExemplo := AOrigem.ArquivoExemplo;
  Aba := AOrigem.Aba;
  LinhaCabecalho := AOrigem.LinhaCabecalho;
  LinhaInicial := AOrigem.LinhaInicial;
  Estrategia := AOrigem.Estrategia;
  CamposChave := AOrigem.CamposChave;
  AcaoErro := AOrigem.AcaoErro;
  Versao := AOrigem.Versao;
  DataAlteracao := AOrigem.DataAlteracao;

  FCampos.Clear;
  for vCampo in AOrigem.Campos do
    AdicionarCampo(vCampo.CampoDestino).Assign(vCampo);
end;

function TPerfil.CampoPorNome(const ANome: string): TCampoPerfil;
var
  vCampo: TCampoPerfil;
begin
  for vCampo in FCampos do
    if SameText(vCampo.CampoDestino, ANome) then
      Exit(vCampo);
  Result := nil;
end;

function TPerfil.AdicionarCampo(const ANome: string): TCampoPerfil;
begin
  Result := CampoPorNome(ANome);
  if Result = nil then
  begin
    Result := TCampoPerfil.Create(UpperCase(Trim(ANome)));
    FCampos.Add(Result);
  end;
end;

function TPerfil.ListaCamposChave: TArray<string>;
var
  vCampo: string;
begin
  Result := nil;
  for vCampo in CamposChave.Split([';', ',']) do
    if Trim(vCampo) <> '' then
      Result := Result + [UpperCase(Trim(vCampo))];
end;

procedure TPerfil.DefinirCamposChave(const ACampos: TArray<string>);
var
  vCampo: string;
begin
  CamposChave := '';
  for vCampo in ACampos do
    if Trim(vCampo) <> '' then
    begin
      if CamposChave <> '' then
        CamposChave := CamposChave + ';';
      CamposChave := CamposChave + UpperCase(Trim(vCampo));
    end;
end;

function TPerfil.CamposMapeados: TArray<TCampoPerfil>;
var
  vCampo: TCampoPerfil;
begin
  Result := nil;
  for vCampo in FCampos do
    if vCampo.Mapeado then
      Result := Result + [vCampo];
end;

end.
