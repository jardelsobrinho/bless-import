unit uPerfilArquivo;

{ Exportação e importação de perfis em arquivo JSON (sem tela e sem banco), para levar perfis de um banco
  de configuração para outro.
  - O arquivo leva o perfil e os campos mapeados com os mesmos códigos gravados no banco; não leva ID,
    versão, datas nem a conexão (só o nome dela, como referência; nunca a senha).
  - A leitura é estrita: formato, origem, estratégia ou transformação desconhecida é erro (nunca troca
    por um valor padrão em silêncio). }

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.DateUtils, System.Generics.Collections, uPerfilModelo,
  uTransformacoes;

const
  cFORMATO_ARQUIVO = 1;
  cEXTENSAO_ARQUIVO = '.blessperfil.json';

type
  TPerfilExportado = class
  public
    Perfil: TPerfil;
    Conexao: string;  // nome da conexão no banco de origem (só referência)
    constructor Create;
    destructor Destroy; override;
  end;

// AConexoes[i] = nome da conexão de APerfis[i]
function PerfisParaJson(const APerfis: TArray<TPerfil>; const AConexoes: TArray<string>): string;
// O chamador libera a lista (ela libera os perfis)
function JsonParaPerfis(const ATexto: string): TObjectList<TPerfilExportado>;

implementation

constructor TPerfilExportado.Create;
begin
  inherited Create;
  Perfil := TPerfil.Create;
end;

destructor TPerfilExportado.Destroy;
begin
  Perfil.Free;
  inherited;
end;

{ Gravação }

procedure AdicionarTexto(AObjeto: TJSONObject; const ANome, AValor: string);
begin
  // Texto vazio fica de fora para o arquivo ficar legível
  if AValor <> '' then
    AObjeto.AddPair(ANome, AValor);
end;

function CampoParaJson(ACampo: TCampoPerfil): TJSONObject;
var
  vLista: TJSONArray;
  vTransformacao: TTransformacao;
  vItem: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('campo', ACampo.CampoDestino);
  Result.AddPair('origem', cORIGENS[ACampo.Origem].Codigo);
  AdicionarTexto(Result, 'coluna', ACampo.Coluna);
  AdicionarTexto(Result, 'valorFixo', ACampo.ValorFixo);
  AdicionarTexto(Result, 'valorPadrao', ACampo.ValorPadrao);
  Result.AddPair('padraoSeInexistente', TJSONBool.Create(ACampo.PadraoSeInexistente));
  Result.AddPair('padraoSeVazio', TJSONBool.Create(ACampo.PadraoSeVazio));
  Result.AddPair('padraoSeInvalido', TJSONBool.Create(ACampo.PadraoSeInvalido));
  AdicionarTexto(Result, 'generator', ACampo.Generator);
  AdicionarTexto(Result, 'expressao', ACampo.Expressao);
  AdicionarTexto(Result, 'consultaTabela', ACampo.ConsultaTabela);
  AdicionarTexto(Result, 'consultaCampoPesquisa', ACampo.ConsultaCampoPesquisa);
  AdicionarTexto(Result, 'consultaCampoRetorno', ACampo.ConsultaCampoRetorno);
  Result.AddPair('consultaSeNaoAchar', cACOES_NAO_ENCONTRADO[ACampo.ConsultaSeNaoAchar].Codigo);
  AdicionarTexto(Result, 'consultaSql', ACampo.ConsultaSql);

  vLista := TJSONArray.Create;
  for vTransformacao in ACampo.Transformacoes do
  begin
    vItem := TJSONObject.Create;
    vItem.AddPair('codigo', cTRANSFORMACOES[vTransformacao.Tipo].Codigo);
    AdicionarTexto(vItem, 'parametro', vTransformacao.Parametro);
    vLista.AddElement(vItem);
  end;
  Result.AddPair('transformacoes', vLista);
end;

function PerfilParaJson(APerfil: TPerfil; const AConexao: string): TJSONObject;
var
  vCampos: TJSONArray;
  vCampo: TCampoPerfil;
begin
  Result := TJSONObject.Create;
  Result.AddPair('nome', APerfil.Nome);
  AdicionarTexto(Result, 'descricao', APerfil.Descricao);
  AdicionarTexto(Result, 'conexao', AConexao);
  Result.AddPair('tabelaDestino', APerfil.TabelaDestino);
  AdicionarTexto(Result, 'arquivoExemplo', APerfil.ArquivoExemplo);
  AdicionarTexto(Result, 'aba', APerfil.Aba);
  Result.AddPair('linhaCabecalho', TJSONNumber.Create(APerfil.LinhaCabecalho));
  Result.AddPair('linhaInicial', TJSONNumber.Create(APerfil.LinhaInicial));
  Result.AddPair('estrategia', cESTRATEGIAS[APerfil.Estrategia].Codigo);
  AdicionarTexto(Result, 'camposChave', APerfil.CamposChave);
  Result.AddPair('acaoErro', cACOES_ERRO[APerfil.AcaoErro].Codigo);

  vCampos := TJSONArray.Create;
  for vCampo in APerfil.CamposMapeados do
    vCampos.AddElement(CampoParaJson(vCampo));
  Result.AddPair('campos', vCampos);
end;

function PerfisParaJson(const APerfis: TArray<TPerfil>; const AConexoes: TArray<string>): string;
var
  vRaiz: TJSONObject;
  vLista: TJSONArray;
  i: Integer;
  vConexao: string;
begin
  vRaiz := TJSONObject.Create;
  try
    vRaiz.AddPair('formato', TJSONNumber.Create(cFORMATO_ARQUIVO));
    vRaiz.AddPair('programa', 'BlessImport');
    vRaiz.AddPair('exportadoEm', DateToISO8601(Now, False));
    vLista := TJSONArray.Create;
    for i := 0 to High(APerfis) do
    begin
      if i <= High(AConexoes) then
        vConexao := AConexoes[i]
      else
        vConexao := '';
      vLista.AddElement(PerfilParaJson(APerfis[i], vConexao));
    end;
    vRaiz.AddPair('perfis', vLista);
    Result := vRaiz.Format(2);
  finally
    vRaiz.Free;
  end;
end;

{ Leitura }

function LerTexto(AObjeto: TJSONObject; const ANome: string): string;
var
  vValor: TJSONValue;
begin
  vValor := AObjeto.GetValue(ANome);
  if (vValor = nil) or (vValor is TJSONNull) then
    Result := ''
  else if vValor is TJSONString then
    Result := TJSONString(vValor).Value
  else
    raise Exception.CreateFmt('"%s" deveria ser um texto.', [ANome]);
end;

function LerTextoObrigatorio(AObjeto: TJSONObject; const ANome: string): string;
begin
  Result := LerTexto(AObjeto, ANome);
  if Trim(Result) = '' then
    raise Exception.CreateFmt('"%s" não foi informado.', [ANome]);
end;

function LerInteiro(AObjeto: TJSONObject; const ANome: string): Integer;
var
  vValor: TJSONValue;
begin
  vValor := AObjeto.GetValue(ANome);
  if not (vValor is TJSONNumber) then
    raise Exception.CreateFmt('"%s" deveria ser um número.', [ANome]);
  Result := TJSONNumber(vValor).AsInt;
end;

function LerBooleano(AObjeto: TJSONObject; const ANome: string): Boolean;
var
  vValor: TJSONValue;
begin
  vValor := AObjeto.GetValue(ANome);
  if not (vValor is TJSONBool) then
    raise Exception.CreateFmt('"%s" deveria ser true ou false.', [ANome]);
  Result := TJSONBool(vValor).AsBoolean;
end;

function LerLista(AObjeto: TJSONObject; const ANome: string): TJSONArray;
var
  vValor: TJSONValue;
begin
  vValor := AObjeto.GetValue(ANome);
  if vValor = nil then
    Exit(nil);
  if not (vValor is TJSONArray) then
    raise Exception.CreateFmt('"%s" deveria ser uma lista.', [ANome]);
  Result := TJSONArray(vValor);
end;

function ComoObjeto(AValor: TJSONValue; const ADescricao: string): TJSONObject;
begin
  if not (AValor is TJSONObject) then
    raise Exception.CreateFmt('%s deveria ser um objeto.', [ADescricao]);
  Result := TJSONObject(AValor);
end;

function EstrategiaDoArquivo(const ACodigo: string): TEstrategiaGravacao;
var
  vEstrategia: TEstrategiaGravacao;
begin
  for vEstrategia := Low(TEstrategiaGravacao) to High(TEstrategiaGravacao) do
    if SameText(cESTRATEGIAS[vEstrategia].Codigo, Trim(ACodigo)) then
      Exit(vEstrategia);
  raise Exception.CreateFmt('Estratégia "%s" desconhecida.', [ACodigo]);
end;

function AcaoErroDoArquivo(const ACodigo: string): TAcaoErro;
var
  vAcao: TAcaoErro;
begin
  for vAcao := Low(TAcaoErro) to High(TAcaoErro) do
    if SameText(cACOES_ERRO[vAcao].Codigo, Trim(ACodigo)) then
      Exit(vAcao);
  raise Exception.CreateFmt('Ação em erro "%s" desconhecida.', [ACodigo]);
end;

function NaoEncontradoDoArquivo(const ACodigo: string): TAcaoNaoEncontrado;
var
  vAcao: TAcaoNaoEncontrado;
begin
  if Trim(ACodigo) = '' then
    Exit(anePendencia);
  for vAcao := Low(TAcaoNaoEncontrado) to High(TAcaoNaoEncontrado) do
    if SameText(cACOES_NAO_ENCONTRADO[vAcao].Codigo, Trim(ACodigo)) then
      Exit(vAcao);
  raise Exception.CreateFmt('Ação "%s" para consulta sem resultado desconhecida.', [ACodigo]);
end;

procedure LerCampo(AObjeto: TJSONObject; APerfil: TPerfil);
var
  vCampo: TCampoPerfil;
  vOrigem: TOrigemValor;
  vNome, vCodigo: string;
  vLista: TJSONArray;
  vItem: TJSONValue;
  vTransformacao: TTransformacao;
  vItemObjeto: TJSONObject;
begin
  vNome := UpperCase(Trim(LerTextoObrigatorio(AObjeto, 'campo')));
  try
    if APerfil.CampoPorNome(vNome) <> nil then
      raise Exception.Create('campo repetido no perfil.');
    vCodigo := LerTextoObrigatorio(AObjeto, 'origem');
    if not OrigemPorCodigo(vCodigo, vOrigem) then
      raise Exception.CreateFmt('origem "%s" desconhecida.', [vCodigo]);

    vCampo := APerfil.AdicionarCampo(vNome);
    vCampo.Origem := vOrigem;
    vCampo.Coluna := LerTexto(AObjeto, 'coluna');
    vCampo.ValorFixo := LerTexto(AObjeto, 'valorFixo');
    vCampo.ValorPadrao := LerTexto(AObjeto, 'valorPadrao');
    vCampo.PadraoSeInexistente := LerBooleano(AObjeto, 'padraoSeInexistente');
    vCampo.PadraoSeVazio := LerBooleano(AObjeto, 'padraoSeVazio');
    vCampo.PadraoSeInvalido := LerBooleano(AObjeto, 'padraoSeInvalido');
    vCampo.Generator := LerTexto(AObjeto, 'generator');
    vCampo.Expressao := LerTexto(AObjeto, 'expressao');
    vCampo.ConsultaTabela := LerTexto(AObjeto, 'consultaTabela');
    vCampo.ConsultaCampoPesquisa := LerTexto(AObjeto, 'consultaCampoPesquisa');
    vCampo.ConsultaCampoRetorno := LerTexto(AObjeto, 'consultaCampoRetorno');
    vCampo.ConsultaSeNaoAchar := NaoEncontradoDoArquivo(LerTexto(AObjeto, 'consultaSeNaoAchar'));
    vCampo.ConsultaSql := LerTexto(AObjeto, 'consultaSql');

    vCampo.Transformacoes := nil;
    vLista := LerLista(AObjeto, 'transformacoes');
    if vLista <> nil then
      for vItem in vLista do
      begin
        vItemObjeto := ComoObjeto(vItem, 'Cada transformação');
        vCodigo := LerTextoObrigatorio(vItemObjeto, 'codigo');
        if not TipoPorCodigo(vCodigo, vTransformacao.Tipo) then
          raise Exception.CreateFmt('transformação "%s" desconhecida.', [vCodigo]);
        vTransformacao.Parametro := LerTexto(vItemObjeto, 'parametro');
        vCampo.Transformacoes := vCampo.Transformacoes + [vTransformacao];
      end;
  except
    on E: Exception do
      raise Exception.CreateFmt('Campo %s: %s', [vNome, E.Message]);
  end;
end;

procedure LerPerfil(AObjeto: TJSONObject; AItem: TPerfilExportado);
var
  vPerfil: TPerfil;
  vCampos: TJSONArray;
  vCampo: TJSONValue;
begin
  vPerfil := AItem.Perfil;
  vPerfil.Nome := Trim(LerTextoObrigatorio(AObjeto, 'nome'));
  try
    vPerfil.Descricao := LerTexto(AObjeto, 'descricao');
    AItem.Conexao := LerTexto(AObjeto, 'conexao');
    vPerfil.TabelaDestino := UpperCase(Trim(LerTextoObrigatorio(AObjeto, 'tabelaDestino')));
    vPerfil.ArquivoExemplo := LerTexto(AObjeto, 'arquivoExemplo');
    vPerfil.Aba := LerTexto(AObjeto, 'aba');
    vPerfil.LinhaCabecalho := LerInteiro(AObjeto, 'linhaCabecalho');
    vPerfil.LinhaInicial := LerInteiro(AObjeto, 'linhaInicial');
    vPerfil.Estrategia := EstrategiaDoArquivo(LerTextoObrigatorio(AObjeto, 'estrategia'));
    vPerfil.CamposChave := LerTexto(AObjeto, 'camposChave');
    vPerfil.AcaoErro := AcaoErroDoArquivo(LerTextoObrigatorio(AObjeto, 'acaoErro'));

    vCampos := LerLista(AObjeto, 'campos');
    if vCampos = nil then
      raise Exception.Create('"campos" não foi informado.');
    for vCampo in vCampos do
      LerCampo(ComoObjeto(vCampo, 'Cada campo'), vPerfil);
  except
    on E: Exception do
      raise Exception.CreateFmt('Perfil "%s": %s', [vPerfil.Nome, E.Message]);
  end;
end;

function JsonParaPerfis(const ATexto: string): TObjectList<TPerfilExportado>;
var
  vValor, vItem: TJSONValue;
  vRaiz: TJSONObject;
  vLista: TJSONArray;
  vPerfil: TPerfilExportado;
  vFormato, vPosicao: Integer;
begin
  vValor := TJSONObject.ParseJSONValue(ATexto);
  if not (vValor is TJSONObject) then
  begin
    vValor.Free;
    raise Exception.Create('O arquivo não é um arquivo de perfis do BlessImport (JSON inválido).');
  end;

  Result := TObjectList<TPerfilExportado>.Create(True);
  try
    try
      vRaiz := TJSONObject(vValor);
      if vRaiz.GetValue('formato') = nil then
        raise Exception.Create('O arquivo não é um arquivo de perfis do BlessImport (sem "formato").');
      vFormato := LerInteiro(vRaiz, 'formato');
      if vFormato <> cFORMATO_ARQUIVO then
        raise Exception.CreateFmt('Formato de arquivo %d não suportado (este programa lê o formato %d).',
          [vFormato, cFORMATO_ARQUIVO]);

      vLista := LerLista(vRaiz, 'perfis');
      if (vLista = nil) or (vLista.Count = 0) then
        raise Exception.Create('O arquivo não tem nenhum perfil.');
      vPosicao := 0;
      for vItem in vLista do
      begin
        Inc(vPosicao);
        vPerfil := TPerfilExportado.Create;
        Result.Add(vPerfil);
        LerPerfil(ComoObjeto(vItem, Format('O perfil %d', [vPosicao])), vPerfil);
      end;
    finally
      vValor.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
