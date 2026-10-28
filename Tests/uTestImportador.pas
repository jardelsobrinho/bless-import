unit uTestImportador;

interface

uses
  System.SysUtils, System.Variants, System.DateUtils, TestFramework, uImportador, uPerfilModelo, uTransformacoes,
  uDmDestino;

type
  TTestImportador = class(TTestCase)
  private
    FNomes: TArray<string>;
    FValores: TArray<Variant>;
    procedure Linha(const ANomes: array of string; const AValores: array of Variant);
    function ObterCelula: TObterCelula;
    function Destino(const ANome, ATipoSql: string; ACategoria: TCategoriaCampo; ATamanho: Integer = 0;
      AEscala: Integer = 0; AObrigatorio: Boolean = False; const APadrao: string = ''): TCampoDestino;
    function Resolver(ACampo: TCampoPerfil; const ADestino: TCampoDestino): TValorResolvido;
    function Transformacao(ATipo: TTipoTransformacao; const AParametro: string = ''): TTransformacao;
    function TemProblema(const AProblemas: TArray<TProblemaPerfil>; AGravidade: TGravidade;
      const ACampo, ATrecho: string): Boolean;
  published
    procedure TestFixoSempreAplica;
    procedure TestFixoConvertidoParaOTipoDoCampo;
    procedure TestFixoIncompativel;
    procedure TestColunaVaziaFicaNula;
    procedure TestObrigatorioSemValor;
    procedure TestPadraoSoQuandoVazio;
    procedure TestPadraoNaoAplicaComValor;
    procedure TestPadraoColunaInexistente;
    procedure TestPadraoValorInvalido;
    procedure TestPadraoVazioDepoisDaTransformacao;
    procedure TestColunaInexistenteSemPadrao;
    procedure TestTextoEmCampoInteiroPedeConversao;
    procedure TestTextoMaiorQueOCampo;
    procedure TestCasasDecimais;
    procedure TestNumeroEmCampoTexto;
    procedure TestDataComHora;
    procedure TestExpressao;
    procedure TestGerado;
    procedure TestCampoInexistenteNoDestino;
    procedure TestResolvedorLinha;
    procedure TestValidarPerfil;
    procedure TestValidarPerfilTabelaInexistente;
    procedure TestValidarCamposChave;
    procedure TestConsultaEncontrada;
    procedure TestConsultaNaoEncontrada;
    procedure TestConsultaAmbiguaEFalha;
    procedure TestConsultaSemValorNaoPesquisa;
    procedure TestConsultaSemBanco;
    procedure TestValidarConsulta;
    procedure TestMontarSqlManual;
    procedure TestConsultaSql;
    procedure TestConsultaSqlNaoEncontradaEErros;
    procedure TestValidarConsultaSql;
  end;

implementation

procedure TTestImportador.Linha(const ANomes: array of string; const AValores: array of Variant);
var
  i: Integer;
begin
  SetLength(FNomes, Length(ANomes));
  SetLength(FValores, Length(AValores));
  for i := 0 to High(ANomes) do
  begin
    FNomes[i] := ANomes[i];
    FValores[i] := AValores[i];
  end;
end;

function TTestImportador.ObterCelula: TObterCelula;
var
  vNomes: TArray<string>;
  vValores: TArray<Variant>;
begin
  vNomes := FNomes;
  vValores := FValores;
  Result :=
    function(const AColuna: string; out AValor: Variant; out ATexto: string): Boolean
    var
      i: Integer;
    begin
      for i := 0 to High(vNomes) do
        if SameText(vNomes[i], AColuna) then
        begin
          AValor := vValores[i];
          ATexto := ValorParaTexto(AValor);
          Exit(True);
        end;
      AValor := Null;
      ATexto := '';
      Result := False;
    end;
end;

function TTestImportador.Destino(const ANome, ATipoSql: string; ACategoria: TCategoriaCampo; ATamanho,
  AEscala: Integer; AObrigatorio: Boolean; const APadrao: string): TCampoDestino;
begin
  Result := Default(TCampoDestino);
  Result.Nome := ANome;
  Result.TipoSql := ATipoSql;
  Result.Categoria := ACategoria;
  Result.Tamanho := ATamanho;
  Result.Escala := AEscala;
  Result.Obrigatorio := AObrigatorio;
  Result.Padrao := APadrao;
end;

function TTestImportador.Resolver(ACampo: TCampoPerfil; const ADestino: TCampoDestino): TValorResolvido;
begin
  Result := ResolverCampo(ACampo, ADestino, True, ObterCelula());
end;

function TTestImportador.Transformacao(ATipo: TTipoTransformacao; const AParametro: string): TTransformacao;
begin
  Result.Tipo := ATipo;
  Result.Parametro := AParametro;
end;

function TTestImportador.TemProblema(const AProblemas: TArray<TProblemaPerfil>; AGravidade: TGravidade;
  const ACampo, ATrecho: string): Boolean;
var
  vProblema: TProblemaPerfil;
begin
  for vProblema in AProblemas do
    if (vProblema.Gravidade = AGravidade) and SameText(vProblema.Campo, ACampo) and
      (Pos(UpperCase(ATrecho), UpperCase(vProblema.Mensagem)) > 0) then
      Exit(True);
  Result := False;
end;

procedure TTestImportador.TestFixoSempreAplica;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  // A planilha tem uma coluna CLIENTE, mas o valor fixo não olha para ela
  Linha(['CLIENTE'], ['F']);
  vCampo := TCampoPerfil.Create('CLIENTE');
  try
    vCampo.Origem := ovFixo;
    vCampo.ValorFixo := 'T';
    vResultado := Resolver(vCampo, Destino('CLIENTE', 'VARCHAR(1)', ccTexto, 1));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals('T', VarToStr(vResultado.Valor));
    CheckTrue(vResultado.Fonte = fvFixo);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestFixoConvertidoParaOTipoDoCampo;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha([], []);
  vCampo := TCampoPerfil.Create('COD_EMPRESA');
  try
    vCampo.Origem := ovFixo;
    vCampo.ValorFixo := '1';
    vResultado := Resolver(vCampo, Destino('COD_EMPRESA', 'INTEGER', ccInteiro));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals(1, Integer(vResultado.Valor));

    vCampo.ValorFixo := '1.234,50';
    vResultado := Resolver(vCampo, Destino('VALOR', 'NUMERIC(15,2)', ccDecimal, 15, 2));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals(1234.5, Double(vResultado.Valor), 0.001);

    vCampo.ValorFixo := '01/02/2024';
    vResultado := Resolver(vCampo, Destino('DATA', 'DATE', ccData));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals('01/02/2024', FormatDateTime('dd/mm/yyyy', vResultado.Valor));
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestFixoIncompativel;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha([], []);
  vCampo := TCampoPerfil.Create('COD_EMPRESA');
  try
    vCampo.Origem := ovFixo;
    vCampo.ValorFixo := 'UM';
    vResultado := Resolver(vCampo, Destino('COD_EMPRESA', 'INTEGER', ccInteiro));
    CheckFalse(vResultado.Ok);
    CheckTrue(vResultado.TipoErro = teValidacao);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestColunaVaziaFicaNula;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['Fax'], ['   ']);
  vCampo := TCampoPerfil.Create('FAX');
  try
    vCampo.Origem := ovColuna;
    vCampo.Coluna := 'Fax';
    vResultado := Resolver(vCampo, Destino('FAX', 'VARCHAR(20)', ccTexto, 20));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckTrue(VarIsNull(vResultado.Valor), 'Coluna vazia sem padrão continua vazia (nulo)');
    CheckTrue(vResultado.Fonte = fvColuna);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestObrigatorioSemValor;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['UF'], [Null]);
  vCampo := TCampoPerfil.Create('SIGLA_UF');
  try
    vCampo.Origem := ovColuna;
    vCampo.Coluna := 'UF';
    vResultado := Resolver(vCampo, Destino('SIGLA_UF', 'VARCHAR(2)', ccTexto, 2, 0, True));
    CheckFalse(vResultado.Ok);
    CheckTrue(vResultado.TipoErro = teValidacao);
    CheckTrue(Pos('obrigatório', vResultado.Mensagem) > 0, vResultado.Mensagem);

    // Obrigatório com DEFAULT no banco aceita nulo
    vResultado := Resolver(vCampo, Destino('SIGLA_UF', 'VARCHAR(2)', ccTexto, 2, 0, True, '''MG'''));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestPadraoSoQuandoVazio;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['Inativo'], ['']);
  vCampo := TCampoPerfil.Create('ATIVO');
  try
    vCampo.Origem := ovPadrao;
    vCampo.Coluna := 'Inativo';
    vCampo.ValorPadrao := 'S';
    vCampo.PadraoSeVazio := True;
    vResultado := Resolver(vCampo, Destino('ATIVO', 'VARCHAR(1)', ccTexto, 1));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals('S', VarToStr(vResultado.Valor));
    CheckTrue(vResultado.Fonte = fvPadrao, 'A origem mostrada é o valor padrão');

    // Sem a condição "vazio" marcada, o padrão não entra
    vCampo.PadraoSeVazio := False;
    vResultado := Resolver(vCampo, Destino('ATIVO', 'VARCHAR(1)', ccTexto, 1));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckTrue(VarIsNull(vResultado.Valor));
    CheckTrue(vResultado.Fonte = fvColuna);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestPadraoNaoAplicaComValor;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['Inativo'], ['N']);
  vCampo := TCampoPerfil.Create('ATIVO');
  try
    vCampo.Origem := ovPadrao;
    vCampo.Coluna := 'Inativo';
    vCampo.ValorPadrao := 'S';
    vCampo.PadraoSeInexistente := True;
    vCampo.PadraoSeVazio := True;
    vCampo.PadraoSeInvalido := True;
    vResultado := Resolver(vCampo, Destino('ATIVO', 'VARCHAR(1)', ccTexto, 1));
    CheckEquals('N', VarToStr(vResultado.Valor), 'Com valor válido, o padrão não substitui o da planilha');
    CheckTrue(vResultado.Fonte = fvColuna);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestPadraoColunaInexistente;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['Outra'], ['X']);
  vCampo := TCampoPerfil.Create('ATIVO');
  try
    vCampo.Origem := ovPadrao;
    vCampo.Coluna := 'ATIVO';
    vCampo.ValorPadrao := 'S';
    vCampo.PadraoSeInexistente := True;
    vResultado := Resolver(vCampo, Destino('ATIVO', 'VARCHAR(1)', ccTexto, 1));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals('S', VarToStr(vResultado.Valor));

    vCampo.PadraoSeInexistente := False;
    vResultado := Resolver(vCampo, Destino('ATIVO', 'VARCHAR(1)', ccTexto, 1));
    CheckFalse(vResultado.Ok, 'Sem a condição marcada, coluna inexistente é erro');
    CheckTrue(vResultado.TipoErro = teValidacao);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestPadraoValorInvalido;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  // Data que não existe: a transformação falha
  Linha(['Data de Emissao'], ['31/02/2020']);
  vCampo := TCampoPerfil.Create('DATA_EMISSAO');
  try
    vCampo.Origem := ovPadrao;
    vCampo.Coluna := 'Data de Emissao';
    vCampo.ValorPadrao := '01/01/2000';
    vCampo.Transformacoes := [Transformacao(ttTextoParaData)];
    vCampo.PadraoSeInvalido := False;
    vResultado := Resolver(vCampo, Destino('DATA_EMISSAO', 'DATE', ccData));
    CheckFalse(vResultado.Ok, 'Inválido sem a condição marcada é erro, nunca padrão silencioso');
    CheckTrue(vResultado.TipoErro = teTransformacao);

    vCampo.PadraoSeInvalido := True;
    vResultado := Resolver(vCampo, Destino('DATA_EMISSAO', 'DATE', ccData));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals('01/01/2000', FormatDateTime('dd/mm/yyyy', vResultado.Valor),
      'O padrão é o valor final, convertido para o tipo do campo');
    CheckTrue(vResultado.Fonte = fvPadrao);
    CheckTrue(Pos('padrão', vResultado.Mensagem) > 0, 'Registra que houve troca: ' + vResultado.Mensagem);

    // Padrão que não serve para o campo: erro de validação
    vCampo.ValorPadrao := '99/99/9999';
    vResultado := Resolver(vCampo, Destino('DATA_EMISSAO', 'DATE', ccData));
    CheckFalse(vResultado.Ok);
    CheckTrue(vResultado.TipoErro = teValidacao);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestPadraoVazioDepoisDaTransformacao;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  // 00 0000-0000 = "sem telefone": a transformação devolve vazio
  Linha(['Telefone'], ['00 0000-0000']);
  vCampo := TCampoPerfil.Create('CODIGO_DDD');
  try
    vCampo.Origem := ovColuna;
    vCampo.Coluna := 'Telefone';
    vCampo.Transformacoes := [Transformacao(ttDdd)];
    vResultado := Resolver(vCampo, Destino('CODIGO_DDD', 'VARCHAR(2)', ccTexto, 2));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckTrue(VarIsNull(vResultado.Valor), 'Coluna simples: fica vazio');

    vCampo.Origem := ovPadrao;
    vCampo.ValorPadrao := '31';
    vCampo.PadraoSeVazio := True;
    vResultado := Resolver(vCampo, Destino('CODIGO_DDD', 'VARCHAR(2)', ccTexto, 2));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals('31', VarToStr(vResultado.Valor), 'Vazio depois da transformação usa o padrão');
    CheckTrue(vResultado.Fonte = fvPadrao);

    vCampo.PadraoSeVazio := False;
    vResultado := Resolver(vCampo, Destino('CODIGO_DDD', 'VARCHAR(2)', ccTexto, 2));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckTrue(VarIsNull(vResultado.Valor), 'Sem a condição "vazia", não usa o padrão');
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestColunaInexistenteSemPadrao;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['A'], ['1']);
  vCampo := TCampoPerfil.Create('CEP');
  try
    vCampo.Origem := ovColuna;
    vCampo.Coluna := 'CEP';
    vResultado := Resolver(vCampo, Destino('CEP', 'VARCHAR(10)', ccTexto, 10));
    CheckFalse(vResultado.Ok);
    CheckTrue(vResultado.TipoErro = teValidacao);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestTextoEmCampoInteiroPedeConversao;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['Codigo'], ['0010']);
  vCampo := TCampoPerfil.Create('CODIGO');
  try
    vCampo.Origem := ovColuna;
    vCampo.Coluna := 'Codigo';
    vResultado := Resolver(vCampo, Destino('CODIGO', 'INTEGER', ccInteiro));
    CheckFalse(vResultado.Ok, 'Texto da planilha não vira número sem transformação');
    CheckTrue(Pos('transformação', vResultado.Mensagem) > 0, vResultado.Mensagem);

    vCampo.Transformacoes := [Transformacao(ttTextoParaInteiro)];
    vResultado := Resolver(vCampo, Destino('CODIGO', 'INTEGER', ccInteiro));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals(10, Integer(vResultado.Valor));

    vResultado := Resolver(vCampo, Destino('CODIGO', 'SMALLINT', ccInteiro));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    Linha(['Codigo'], ['70000']);
    vResultado := Resolver(vCampo, Destino('CODIGO', 'SMALLINT', ccInteiro));
    CheckFalse(vResultado.Ok, '70000 não cabe em SMALLINT');
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestTextoMaiorQueOCampo;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['UF'], ['MGX']);
  vCampo := TCampoPerfil.Create('SIGLA_UF');
  try
    vCampo.Origem := ovColuna;
    vCampo.Coluna := 'UF';
    vResultado := Resolver(vCampo, Destino('SIGLA_UF', 'VARCHAR(2)', ccTexto, 2));
    CheckFalse(vResultado.Ok, 'Não corta o texto em silêncio');
    CheckTrue(vResultado.TipoErro = teValidacao);

    vCampo.Transformacoes := [Transformacao(ttParteTexto, '1,2')];
    vResultado := Resolver(vCampo, Destino('SIGLA_UF', 'VARCHAR(2)', ccTexto, 2));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals('MG', VarToStr(vResultado.Valor));
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestCasasDecimais;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['Valor'], [601.215]);
  vCampo := TCampoPerfil.Create('VALOR');
  try
    vCampo.Origem := ovColuna;
    vCampo.Coluna := 'Valor';
    vResultado := Resolver(vCampo, Destino('VALOR', 'NUMERIC(15,2)', ccDecimal, 15, 2));
    CheckFalse(vResultado.Ok, 'Três casas num NUMERIC(15,2) mudaria o valor ao gravar');

    vCampo.Transformacoes := [Transformacao(ttArredondar, '2')];
    vResultado := Resolver(vCampo, Destino('VALOR', 'NUMERIC(15,2)', ccDecimal, 15, 2));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals(601.22, Double(vResultado.Valor), 0.0001);

    // DOUBLE PRECISION não tem escala fixa
    vCampo.Transformacoes := nil;
    vResultado := Resolver(vCampo, Destino('VALOR', 'DOUBLE PRECISION', ccDecimal));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);

    Linha(['Valor'], [123456.0]);
    vResultado := Resolver(vCampo, Destino('VALOR', 'NUMERIC(5,2)', ccDecimal, 5, 2));
    CheckFalse(vResultado.Ok, '123456 não cabe em NUMERIC(5,2)');
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestNumeroEmCampoTexto;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['Numero'], [1008.0]);
  vCampo := TCampoPerfil.Create('NUMERO');
  try
    vCampo.Origem := ovColuna;
    vCampo.Coluna := 'Numero';
    vResultado := Resolver(vCampo, Destino('NUMERO', 'VARCHAR(10)', ccTexto, 10));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals('1008', VarToStr(vResultado.Valor));
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestDataComHora;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['Data'], [VarFromDateTime(EncodeDateTime(2021, 2, 24, 16, 44, 0, 0))]);
  vCampo := TCampoPerfil.Create('DATA');
  try
    vCampo.Origem := ovColuna;
    vCampo.Coluna := 'Data';
    vResultado := Resolver(vCampo, Destino('DATA', 'DATE', ccData));
    CheckFalse(vResultado.Ok, 'Hora não é descartada em silêncio num campo DATE');

    vResultado := Resolver(vCampo, Destino('DATA', 'TIMESTAMP', ccDataHora));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);

    vCampo.Transformacoes := [Transformacao(ttTextoParaData)];
    vResultado := Resolver(vCampo, Destino('DATA', 'DATE', ccData));
    CheckTrue(vResultado.Ok, 'Texto para data mantém só a data: ' + vResultado.Mensagem);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestExpressao;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['Endereco', 'Bairro'], ['RUA A, 10', 'CENTRO']);
  vCampo := TCampoPerfil.Create('ENDERECO');
  try
    vCampo.Origem := ovExpressao;
    vCampo.Expressao := '{Endereco} - {Bairro}';
    vResultado := Resolver(vCampo, Destino('ENDERECO', 'VARCHAR(100)', ccTexto, 100));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals('RUA A, 10 - CENTRO', VarToStr(vResultado.Valor));
    CheckTrue(vResultado.Fonte = fvExpressao);

    vCampo.Expressao := '{Endereco} {Numero}';
    vResultado := Resolver(vCampo, Destino('ENDERECO', 'VARCHAR(100)', ccTexto, 100));
    CheckFalse(vResultado.Ok, 'Coluna inexistente na expressão');
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestGerado;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha([], []);
  vCampo := TCampoPerfil.Create('CODIGO');
  try
    vCampo.Origem := ovGerado;
    vCampo.Generator := 'GEN_FORNECEDOR';
    vResultado := Resolver(vCampo, Destino('CODIGO', 'INTEGER', ccInteiro, 0, 0, True));
    CheckTrue(vResultado.Ok, 'Obrigatório gerado não é "sem valor": ' + vResultado.Mensagem);
    CheckTrue(vResultado.Fonte = fvGerado);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestCampoInexistenteNoDestino;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['A'], ['1']);
  vCampo := TCampoPerfil.Create('VELHO');
  try
    vCampo.Origem := ovFixo;
    vCampo.ValorFixo := '1';
    vResultado := ResolverCampo(vCampo, Default(TCampoDestino), False, ObterCelula());
    CheckFalse(vResultado.Ok);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestResolvedorLinha;
var
  vPerfil: TPerfil;
  vResolvedor: TResolvedorValores;
  vResultado: TResultadoLinha;
begin
  vPerfil := TPerfil.Create;
  try
    vPerfil.AdicionarCampo('CGC').Origem := ovColuna;
    vPerfil.CampoPorNome('CGC').Coluna := 'CGC';
    vPerfil.CampoPorNome('CGC').Transformacoes := [Transformacao(ttCpfCnpj)];
    vPerfil.AdicionarCampo('CLIENTE').Origem := ovFixo;
    vPerfil.CampoPorNome('CLIENTE').ValorFixo := 'T';
    vPerfil.AdicionarCampo('FAX');

    vResolvedor := TResolvedorValores.Create(vPerfil, [Destino('CGC', 'VARCHAR(14)', ccTexto, 14, 0, True),
      Destino('CLIENTE', 'VARCHAR(1)', ccTexto, 1), Destino('FAX', 'VARCHAR(20)', ccTexto, 20)]);
    try
      CheckEquals(2, Length(vResolvedor.Campos), 'Só os campos mapeados');

      Linha(['CGC'], ['12.194.177/0001-55']);
      vResultado := vResolvedor.ResolverLinha(2, ObterCelula());
      CheckEquals(2, vResultado.Linha);
      CheckTrue(vResultado.Valida);
      CheckEquals('12194177000155', VarToStr(vResultado.Valores[0].Valor));
      CheckEquals('T', VarToStr(vResultado.Valores[1].Valor));

      Linha(['CGC'], ['12.194.177/0001-00']);
      vResultado := vResolvedor.ResolverLinha(3, ObterCelula());
      CheckFalse(vResultado.Valida);
      CheckEquals(1, vResultado.QuantidadeErros);
      CheckTrue(vResultado.Valores[0].TipoErro = teTransformacao);
    finally
      vResolvedor.Free;
    end;
  finally
    vPerfil.Free;
  end;
end;

procedure TTestImportador.TestValidarPerfil;
var
  vPerfil: TPerfil;
  vProblemas: TArray<TProblemaPerfil>;
  vDestinos: TArray<TCampoDestino>;
begin
  vPerfil := TPerfil.Create;
  try
    vPerfil.TabelaDestino := 'FORNECEDOR';
    vPerfil.AdicionarCampo('CGC').Origem := ovColuna;
    vPerfil.CampoPorNome('CGC').Coluna := 'CNPJ';                   // não existe na planilha
    vPerfil.AdicionarCampo('CODIGO').Origem := ovGerado;
    vPerfil.CampoPorNome('CODIGO').Generator := 'GEN_NAO_EXISTE';
    vPerfil.AdicionarCampo('CLIENTE').Origem := ovFixo;
    vPerfil.CampoPorNome('CLIENTE').ValorFixo := 'TT';             // VARCHAR(1)
    vPerfil.AdicionarCampo('ATIVO').Origem := ovPadrao;
    vPerfil.CampoPorNome('ATIVO').Coluna := 'Ativo';               // não existe, mas tem padrão
    vPerfil.CampoPorNome('ATIVO').ValorPadrao := 'S';
    vPerfil.AdicionarCampo('VELHO').Origem := ovFixo;
    vPerfil.CampoPorNome('VELHO').ValorFixo := '1';

    vDestinos := [Destino('CGC', 'VARCHAR(14)', ccTexto, 14, 0, True), Destino('CODIGO', 'INTEGER', ccInteiro, 0, 0, True),
      Destino('CLIENTE', 'VARCHAR(1)', ccTexto, 1), Destino('ATIVO', 'VARCHAR(1)', ccTexto, 1),
      Destino('RAZAO_SOCIAL', 'VARCHAR(100)', ccTexto, 100, 0, True),
      Destino('SITUACAO', 'INTEGER', ccInteiro, 0, 0, True, '1')];

    vProblemas := ValidarPerfil(vPerfil, True, vDestinos, True, ['CGC', 'Razao Social'], ['GEN_FORNECEDOR'],
      ['FORNECEDOR']);

    CheckTrue(TemProblema(vProblemas, gvErro, 'CGC', 'CNPJ'), 'Coluna inexistente');
    CheckTrue(TemProblema(vProblemas, gvErro, 'CODIGO', 'GEN_NAO_EXISTE'), 'Generator inexistente');
    CheckTrue(TemProblema(vProblemas, gvErro, 'CLIENTE', 'caracteres'), 'Valor fixo maior que o campo');
    CheckTrue(TemProblema(vProblemas, gvAviso, 'ATIVO', 'padrão'), 'Coluna inexistente com padrão = aviso');
    CheckTrue(TemProblema(vProblemas, gvErro, 'VELHO', 'não existe na tabela'), 'Campo removido da tabela');
    CheckTrue(TemProblema(vProblemas, gvErro, 'RAZAO_SOCIAL', 'obrigatório'), 'Obrigatório sem mapeamento');
    CheckTrue(TemProblema(vProblemas, gvAviso, 'SITUACAO', 'padrão do banco'), 'Obrigatório com DEFAULT = aviso');
    CheckEquals(7, Length(vProblemas), 'Nenhum problema a mais');
  finally
    vPerfil.Free;
  end;
end;

procedure TTestImportador.TestValidarPerfilTabelaInexistente;
var
  vPerfil: TPerfil;
  vProblemas: TArray<TProblemaPerfil>;
begin
  vPerfil := TPerfil.Create;
  try
    vPerfil.TabelaDestino := 'NAO_EXISTE';
    vProblemas := ValidarPerfil(vPerfil, False, nil, False, nil, nil, nil);
    CheckEquals(1, Length(vProblemas));
    CheckTrue(vProblemas[0].Gravidade = gvErro);
  finally
    vPerfil.Free;
  end;
end;

procedure TTestImportador.TestValidarCamposChave;
var
  vPerfil: TPerfil;
  vDestinos: TArray<TCampoDestino>;
  vProblemas: TArray<TProblemaPerfil>;
begin
  vDestinos := [Destino('CGC', 'VARCHAR(14)', ccTexto, 14, 0, True), Destino('CODIGO', 'INTEGER', ccInteiro),
    Destino('FAX', 'VARCHAR(20)', ccTexto, 20)];
  vPerfil := TPerfil.Create;
  try
    vPerfil.TabelaDestino := 'FORNECEDOR';
    vPerfil.AdicionarCampo('CGC').Origem := ovColuna;
    vPerfil.CampoPorNome('CGC').Coluna := 'CGC';
    vPerfil.AdicionarCampo('CODIGO').Origem := ovGerado;
    vPerfil.CampoPorNome('CODIGO').Generator := 'GEN_FORNECEDOR';

    // Inserir não usa chave
    vPerfil.Estrategia := egInserir;
    vProblemas := ValidarPerfil(vPerfil, True, vDestinos, True, ['CGC'], ['GEN_FORNECEDOR'], ['FORNECEDOR']);
    CheckEquals(0, Length(vProblemas), 'Inserir sem campos-chave é válido');

    vPerfil.Estrategia := egIgnorarExistentes;
    vProblemas := ValidarPerfil(vPerfil, True, vDestinos, True, ['CGC'], ['GEN_FORNECEDOR'], ['FORNECEDOR']);
    CheckTrue(TemProblema(vProblemas, gvErro, '', 'campos-chave'), 'Estratégia com chave e sem campos-chave');

    vPerfil.CamposChave := 'CGC;FAX;CODIGO;NAO_EXISTE';
    vProblemas := ValidarPerfil(vPerfil, True, vDestinos, True, ['CGC'], ['GEN_FORNECEDOR'], ['FORNECEDOR']);
    CheckFalse(TemProblema(vProblemas, gvErro, 'CGC', 'chave'), 'CGC mapeado é uma chave válida');
    CheckTrue(TemProblema(vProblemas, gvErro, 'FAX', 'sem mapeamento'), 'Chave não mapeada');
    CheckTrue(TemProblema(vProblemas, gvErro, 'CODIGO', 'gerado'), 'Chave gerada');
    CheckTrue(TemProblema(vProblemas, gvErro, 'NAO_EXISTE', 'não existe'), 'Chave que não existe na tabela');

    vPerfil.CamposChave := 'CGC';
    vProblemas := ValidarPerfil(vPerfil, True, vDestinos, True, ['CGC'], ['GEN_FORNECEDOR'], ['FORNECEDOR']);
    CheckEquals(0, Length(vProblemas), 'Chave CGC mapeada pela coluna: sem problemas');
  finally
    vPerfil.Free;
  end;
end;

// Banco simulado: FORNECEDOR com CGC 12194177000155 -> CODIGO 10 e CGC 11111111111111 repetido
function ConsultaSimulada(var AChamadas: Integer; var AUltimoValor: string): TConsultarReferencia;
var
  vChamadas: ^Integer;
  vUltimo: ^string;
begin
  vChamadas := @AChamadas;
  vUltimo := @AUltimoValor;
  Result :=
    function(const ATabela, ACampoPesquisa, ACampoRetorno: string; const AValor: Variant; out ARetorno: Variant;
      out AMensagem: string): Integer
    begin
      Inc(vChamadas^);
      vUltimo^ := VarToStr(AValor);
      ARetorno := Null;
      AMensagem := '';
      if VarToStr(AValor) = '12194177000155' then
      begin
        ARetorno := 10;
        Result := 1;
      end
      else if VarToStr(AValor) = '11111111111111' then
        Result := 2
      else if VarToStr(AValor) = 'ERRO' then
      begin
        AMensagem := 'falha simulada';
        Result := -1;
      end
      else
        Result := 0;
    end;
end;

function CampoConsulta: TCampoPerfil;
begin
  Result := TCampoPerfil.Create('FK_CLIENTE');
  Result.Origem := ovConsulta;
  Result.Coluna := 'CGC';
  Result.ConsultaTabela := 'FORNECEDOR';
  Result.ConsultaCampoPesquisa := 'CGC';
  Result.ConsultaCampoRetorno := 'CODIGO';
end;

procedure TTestImportador.TestConsultaEncontrada;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
  vChamadas: Integer;
  vUltimo: string;
begin
  vChamadas := 0;
  // A transformação (CPF/CNPJ) roda antes: a pesquisa recebe só os dígitos
  Linha(['CGC'], ['12.194.177/0001-55']);
  vCampo := CampoConsulta;
  try
    vCampo.Transformacoes := [Transformacao(ttCpfCnpj)];
    vResultado := ResolverCampo(vCampo, Destino('FK_CLIENTE', 'INTEGER', ccInteiro), True, ObterCelula(),
      ConsultaSimulada(vChamadas, vUltimo));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals(10, Integer(vResultado.Valor), 'Grava o CODIGO achado, não o CGC');
    CheckTrue(vResultado.Fonte = fvConsulta);
    CheckEquals('12194177000155', vUltimo, 'Pesquisou com o valor já transformado');
    CheckEquals(1, vChamadas);

    // Retorno incompatível com o campo de destino: erro de validação
    vResultado := ResolverCampo(vCampo, Destino('FK_CLIENTE', 'VARCHAR(1)', ccTexto, 1), True, ObterCelula(),
      ConsultaSimulada(vChamadas, vUltimo));
    CheckFalse(vResultado.Ok, '"10" não cabe em VARCHAR(1)');
    CheckTrue(vResultado.TipoErro = teValidacao);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestConsultaNaoEncontrada;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
  vChamadas: Integer;
  vUltimo: string;
begin
  vChamadas := 0;
  Linha(['CGC'], ['99999999000199']);
  vCampo := CampoConsulta;
  try
    vCampo.ConsultaSeNaoAchar := anePendencia;
    vResultado := ResolverCampo(vCampo, Destino('FK_CLIENTE', 'INTEGER', ccInteiro), True, ObterCelula(),
      ConsultaSimulada(vChamadas, vUltimo));
    CheckFalse(vResultado.Ok, 'Pendência: a linha não pode ser gravada');
    CheckTrue(vResultado.TipoErro = teReferencia);

    vCampo.ConsultaSeNaoAchar := aneNulo;
    vResultado := ResolverCampo(vCampo, Destino('FK_CLIENTE', 'INTEGER', ccInteiro), True, ObterCelula(),
      ConsultaSimulada(vChamadas, vUltimo));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckTrue(VarIsNull(vResultado.Valor), 'Gravar nulo');
    CheckTrue(Pos('não encontrado', vResultado.Mensagem) > 0, 'Avisa que não achou: ' + vResultado.Mensagem);

    // "Gravar nulo" num campo obrigatório continua sendo erro
    vResultado := ResolverCampo(vCampo, Destino('FK_CLIENTE', 'INTEGER', ccInteiro, 0, 0, True), True, ObterCelula(),
      ConsultaSimulada(vChamadas, vUltimo));
    CheckFalse(vResultado.Ok);
    CheckTrue(vResultado.TipoErro = teValidacao);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestConsultaAmbiguaEFalha;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
  vChamadas: Integer;
  vUltimo: string;
begin
  vChamadas := 0;
  vCampo := CampoConsulta;
  try
    vCampo.ConsultaSeNaoAchar := aneNulo;
    Linha(['CGC'], ['11111111111111']);
    vResultado := ResolverCampo(vCampo, Destino('FK_CLIENTE', 'INTEGER', ccInteiro), True, ObterCelula(),
      ConsultaSimulada(vChamadas, vUltimo));
    CheckFalse(vResultado.Ok, 'Mais de um registro nunca é escolhido ao acaso');
    CheckTrue(vResultado.TipoErro = teReferencia);

    Linha(['CGC'], ['ERRO']);
    vResultado := ResolverCampo(vCampo, Destino('FK_CLIENTE', 'INTEGER', ccInteiro), True, ObterCelula(),
      ConsultaSimulada(vChamadas, vUltimo));
    CheckFalse(vResultado.Ok);
    CheckTrue(vResultado.TipoErro = teReferencia);
    CheckEquals('falha simulada', vResultado.Mensagem);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestConsultaSemValorNaoPesquisa;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
  vChamadas: Integer;
  vUltimo: string;
begin
  vChamadas := 0;
  Linha(['CGC'], ['  ']);
  vCampo := CampoConsulta;
  try
    vResultado := ResolverCampo(vCampo, Destino('FK_CLIENTE', 'INTEGER', ccInteiro), True, ObterCelula(),
      ConsultaSimulada(vChamadas, vUltimo));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckTrue(VarIsNull(vResultado.Valor));
    CheckEquals(0, vChamadas, 'Valor vazio não vai ao banco');
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestConsultaSemBanco;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
begin
  Linha(['CGC'], ['12194177000155']);
  vCampo := CampoConsulta;
  try
    vResultado := ResolverCampo(vCampo, Destino('FK_CLIENTE', 'INTEGER', ccInteiro), True, ObterCelula());
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals('12194177000155', VarToStr(vResultado.Valor), 'Sem banco: mostra só o valor de pesquisa');
    CheckTrue(Pos('sem consulta', vResultado.Mensagem) > 0, vResultado.Mensagem);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestValidarConsulta;
var
  vPerfil: TPerfil;
  vProblemas: TArray<TProblemaPerfil>;
  vCamposFornecedor: TArray<TCampoDestino>;
begin
  vCamposFornecedor := [Destino('CGC', 'VARCHAR(14)', ccTexto, 14), Destino('CODIGO', 'INTEGER', ccInteiro)];
  vPerfil := TPerfil.Create;
  try
    vPerfil.TabelaDestino := 'LANCAMENTO';
    vPerfil.Campos.Add(CampoConsulta);

    vProblemas := ValidarPerfil(vPerfil, True, [Destino('FK_CLIENTE', 'INTEGER', ccInteiro)], True, ['CGC'], nil,
      ['FORNECEDOR', 'LANCAMENTO'],
      function(ATabela: string): TArray<TCampoDestino>
      begin
        Result := vCamposFornecedor;
      end);
    CheckEquals(0, Length(vProblemas), 'Consulta bem configurada: sem problemas');

    vPerfil.CampoPorNome('FK_CLIENTE').ConsultaCampoRetorno := 'NAO_EXISTE';
    vPerfil.CampoPorNome('FK_CLIENTE').ConsultaCampoPesquisa := 'CNPJ';
    vProblemas := ValidarPerfil(vPerfil, True, [Destino('FK_CLIENTE', 'INTEGER', ccInteiro)], True, ['CGC'], nil,
      ['FORNECEDOR', 'LANCAMENTO'],
      function(ATabela: string): TArray<TCampoDestino>
      begin
        Result := vCamposFornecedor;
      end);
    CheckTrue(TemProblema(vProblemas, gvErro, 'FK_CLIENTE', 'pesquisa CNPJ'), 'Campo de pesquisa inexistente');
    CheckTrue(TemProblema(vProblemas, gvErro, 'FK_CLIENTE', 'retorno NAO_EXISTE'), 'Campo de retorno inexistente');

    // Retorno texto num campo inteiro: aviso
    vPerfil.CampoPorNome('FK_CLIENTE').ConsultaCampoPesquisa := 'CODIGO';
    vPerfil.CampoPorNome('FK_CLIENTE').ConsultaCampoRetorno := 'CGC';
    vProblemas := ValidarPerfil(vPerfil, True, [Destino('FK_CLIENTE', 'INTEGER', ccInteiro)], True, ['CGC'], nil,
      ['FORNECEDOR', 'LANCAMENTO'],
      function(ATabela: string): TArray<TCampoDestino>
      begin
        Result := vCamposFornecedor;
      end);
    CheckTrue(TemProblema(vProblemas, gvAviso, 'FK_CLIENTE', 'combinam'), 'Tipos diferentes: aviso');

    vPerfil.CampoPorNome('FK_CLIENTE').ConsultaTabela := 'NAO_EXISTE';
    vProblemas := ValidarPerfil(vPerfil, True, [Destino('FK_CLIENTE', 'INTEGER', ccInteiro)], True, ['CGC'], nil,
      ['FORNECEDOR', 'LANCAMENTO']);
    CheckTrue(TemProblema(vProblemas, gvErro, 'FK_CLIENTE', 'tabela de consulta'), 'Tabela de consulta inexistente');
  finally
    vPerfil.Free;
  end;
end;

procedure TTestImportador.TestMontarSqlManual;
var
  vNomes: TArray<string>;
  vSql: string;
begin
  vNomes := MontarSqlManual('select CODIGO from CIDADE where NOME = {Cidade} and UF = { UF } and X = {valor}', vSql);
  CheckEquals('select CODIGO from CIDADE where NOME = :P0 and UF = :P1 and X = :P2', vSql);
  CheckEquals(3, Length(vNomes));
  CheckEquals('Cidade', vNomes[0]);
  CheckEquals('UF', vNomes[1]);
  CheckEquals('valor', vNomes[2]);

  vNomes := MontarSqlManual('select 1 from RDB$DATABASE', vSql);
  CheckEquals(0, Length(vNomes));
  CheckEquals('select 1 from RDB$DATABASE', vSql);
end;

// Banco simulado para a consulta SQL: guarda o SQL e os parâmetros recebidos
function ConsultaSqlSimulada(var ASql: string; var AValores: TArray<Variant>; AResultado: Integer;
  const ARetorno: Variant): TConsultarSql;
var
  vSql: ^string;
  vValores: ^TArray<Variant>;
  vRetorno: Variant;
begin
  vSql := @ASql;
  vValores := @AValores;
  vRetorno := ARetorno;
  Result :=
    function(const ASqlRecebido: string; const AValoresRecebidos: TArray<Variant>; out ARetornoConsulta: Variant;
      out AMensagem: string): Integer
    begin
      vSql^ := ASqlRecebido;
      vValores^ := AValoresRecebidos;
      ARetornoConsulta := vRetorno;
      AMensagem := 'falha simulada';
      Result := AResultado;
    end;
end;

function CampoConsultaSql: TCampoPerfil;
begin
  Result := TCampoPerfil.Create('FK_CIDADE');
  Result.Origem := ovConsultaSql;
  Result.Coluna := 'Cidade';
  Result.ConsultaSql := 'select CODIGO from CIDADE where NOME = {valor} and SIGLA_UF = {UF}';
end;

procedure TTestImportador.TestConsultaSql;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
  vSql: string;
  vValores: TArray<Variant>;
begin
  Linha(['Cidade', 'UF'], ['  mancio lima ', 'AC']);
  vCampo := CampoConsultaSql;
  try
    // {valor} vem da coluna do campo já transformada; {UF} vem da planilha como está
    vCampo.Transformacoes := [Transformacao(ttRemoverEspacos), Transformacao(ttMaiusculas)];
    vResultado := ResolverCampo(vCampo, Destino('FK_CIDADE', 'INTEGER', ccInteiro), True, ObterCelula(), nil,
      ConsultaSqlSimulada(vSql, vValores, 1, 1200));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckEquals(1200, Integer(vResultado.Valor));
    CheckTrue(vResultado.Fonte = fvConsulta);
    CheckEquals('select CODIGO from CIDADE where NOME = :P0 and SIGLA_UF = :P1', vSql);
    CheckEquals(2, Length(vValores));
    CheckEquals('MANCIO LIMA', VarToStr(vValores[0]));
    CheckEquals('AC', VarToStr(vValores[1]));

    // Sem banco: só descreve a consulta
    vResultado := ResolverCampo(vCampo, Destino('FK_CIDADE', 'INTEGER', ccInteiro), True, ObterCelula());
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckTrue(Pos('sem consulta', vResultado.Mensagem) > 0, vResultado.Mensagem);

    // Coluna usada no SQL que não existe na planilha
    vCampo.ConsultaSql := 'select CODIGO from CIDADE where NOME = {valor} and PAIS = {Pais}';
    vResultado := ResolverCampo(vCampo, Destino('FK_CIDADE', 'INTEGER', ccInteiro), True, ObterCelula(), nil,
      ConsultaSqlSimulada(vSql, vValores, 1, 1200));
    CheckFalse(vResultado.Ok);
    CheckTrue(vResultado.TipoErro = teValidacao);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestConsultaSqlNaoEncontradaEErros;
var
  vCampo: TCampoPerfil;
  vResultado: TValorResolvido;
  vSql: string;
  vValores: TArray<Variant>;
begin
  Linha(['Cidade', 'UF'], ['XYZ', 'AC']);
  vCampo := CampoConsultaSql;
  try
    vCampo.ConsultaSeNaoAchar := anePendencia;
    vResultado := ResolverCampo(vCampo, Destino('FK_CIDADE', 'INTEGER', ccInteiro), True, ObterCelula(), nil,
      ConsultaSqlSimulada(vSql, vValores, 0, Null));
    CheckFalse(vResultado.Ok, 'Pendência');
    CheckTrue(vResultado.TipoErro = teReferencia);

    vCampo.ConsultaSeNaoAchar := aneNulo;
    vResultado := ResolverCampo(vCampo, Destino('FK_CIDADE', 'INTEGER', ccInteiro), True, ObterCelula(), nil,
      ConsultaSqlSimulada(vSql, vValores, 0, Null));
    CheckTrue(vResultado.Ok, vResultado.Mensagem);
    CheckTrue(VarIsNull(vResultado.Valor));

    vResultado := ResolverCampo(vCampo, Destino('FK_CIDADE', 'INTEGER', ccInteiro), True, ObterCelula(), nil,
      ConsultaSqlSimulada(vSql, vValores, 2, 1));
    CheckFalse(vResultado.Ok, 'Mais de uma linha');
    CheckTrue(vResultado.TipoErro = teReferencia);

    vResultado := ResolverCampo(vCampo, Destino('FK_CIDADE', 'INTEGER', ccInteiro), True, ObterCelula(), nil,
      ConsultaSqlSimulada(vSql, vValores, -1, Null));
    CheckFalse(vResultado.Ok);
    CheckTrue(Pos('falha simulada', vResultado.Mensagem) > 0, vResultado.Mensagem);

    // Retorno que não serve para o campo de destino
    vResultado := ResolverCampo(vCampo, Destino('FK_CIDADE', 'INTEGER', ccInteiro), True, ObterCelula(), nil,
      ConsultaSqlSimulada(vSql, vValores, 1, 'ABC'));
    CheckFalse(vResultado.Ok);
    CheckTrue(vResultado.TipoErro = teValidacao);
  finally
    vCampo.Free;
  end;
end;

procedure TTestImportador.TestValidarConsultaSql;
var
  vPerfil: TPerfil;
  vProblemas: TArray<TProblemaPerfil>;
  vMensagem: string;
  vSqlTestado: string;
begin
  vPerfil := TPerfil.Create;
  try
    vPerfil.TabelaDestino := 'FORNECEDOR';
    vPerfil.Campos.Add(CampoConsultaSql);

    vProblemas := ValidarPerfil(vPerfil, True, [Destino('FK_CIDADE', 'INTEGER', ccInteiro)], True, ['Cidade', 'UF'],
      nil, ['FORNECEDOR'], nil,
      function(ASql: string): string
      begin
        vSqlTestado := ASql;
        Result := '';
      end);
    CheckEquals(0, Length(vProblemas), 'SELECT válido');
    CheckEquals('select CODIGO from CIDADE where NOME = :P0 and SIGLA_UF = :P1', vSqlTestado,
      'O banco recebe o SQL já com parâmetros');

    vProblemas := ValidarPerfil(vPerfil, True, [Destino('FK_CIDADE', 'INTEGER', ccInteiro)], True, ['Cidade', 'UF'],
      nil, ['FORNECEDOR'], nil,
      function(ASql: string): string
      begin
        Result := 'Table unknown CIDADES';
      end);
    CheckTrue(TemProblema(vProblemas, gvErro, 'FK_CIDADE', 'Table unknown'), 'Erro do banco aparece na validação');

    vPerfil.Campos[0].ConsultaSql := 'delete from CIDADE where NOME = {valor}';
    vProblemas := ValidarPerfil(vPerfil, True, [Destino('FK_CIDADE', 'INTEGER', ccInteiro)], True, ['Cidade', 'UF'],
      nil, ['FORNECEDOR']);
    CheckTrue(TemProblema(vProblemas, gvErro, 'FK_CIDADE', 'SELECT'), 'Só SELECT');

    vPerfil.Campos[0].ConsultaSql := 'select 1 from RDB$DATABASE; delete from CIDADE';
    vProblemas := ValidarPerfil(vPerfil, True, [Destino('FK_CIDADE', 'INTEGER', ccInteiro)], True, ['Cidade', 'UF'],
      nil, ['FORNECEDOR']);
    CheckTrue(TemProblema(vProblemas, gvErro, 'FK_CIDADE', ';'), 'Um comando só');

    // {valor} sem coluna no campo
    vPerfil.Campos[0].ConsultaSql := 'select CODIGO from CIDADE where NOME = {valor}';
    vPerfil.Campos[0].Coluna := '';
    CheckFalse(vPerfil.Campos[0].ValidarConfiguracao(vMensagem));
    // Sem {valor} a coluna é opcional
    vPerfil.Campos[0].ConsultaSql := 'select CODIGO from CIDADE where NOME = {Cidade}';
    CheckTrue(vPerfil.Campos[0].ValidarConfiguracao(vMensagem), vMensagem);
    CheckEquals(1, Length(vPerfil.Campos[0].ColunasUsadas));
    CheckEquals('Cidade', vPerfil.Campos[0].ColunasUsadas[0]);
  finally
    vPerfil.Free;
  end;
end;

initialization
  RegisterTest(TTestImportador.Suite);

end.
