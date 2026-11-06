unit uTestPerfilArquivo;

interface

uses
  System.SysUtils, System.Generics.Collections, TestFramework, uPerfilModelo, uTransformacoes, uPerfilArquivo;

type
  TTestPerfilArquivo = class(TTestCase)
  private
    function PerfilCompleto: TPerfil;
    function Ler(const ATexto: string): TObjectList<TPerfilExportado>;
    procedure VerificarErro(const ATexto, ATrechoDaMensagem: string);
  published
    procedure TestIdaEVolta;
    procedure TestVariosPerfis;
    procedure TestNaoLevaIdNemNaoMapeados;
    procedure TestFormatoDesconhecido;
    procedure TestArquivoInvalido;
    procedure TestOrigemDesconhecida;
    procedure TestTransformacaoDesconhecida;
    procedure TestEstrategiaDesconhecida;
    procedure TestPerfilSemNomeOuTabela;
  end;

implementation

function Transf(ATipo: TTipoTransformacao; const AParametro: string = ''): TTransformacao;
begin
  Result.Tipo := ATipo;
  Result.Parametro := AParametro;
end;

function TTestPerfilArquivo.PerfilCompleto: TPerfil;
var
  vCampo: TCampoPerfil;
begin
  Result := TPerfil.Create;
  Result.Id := 99;
  Result.Nome := 'Clientes (São João)';
  Result.Descricao := 'Descrição com acentos: ç, ã, é' + sLineBreak + 'e quebra de linha';
  Result.IdConexao := 7;
  Result.TabelaDestino := 'FORNECEDOR';
  Result.ArquivoExemplo := 'F:\Pasta com espaço\CLIENTES.xls';
  Result.Aba := 'Sheet1';
  Result.LinhaCabecalho := 3;
  Result.LinhaInicial := 5;
  Result.Estrategia := egInserirOuAtualizar;
  Result.CamposChave := 'CGC';
  Result.AcaoErro := aeDesfazerTudo;
  Result.Versao := 12;

  vCampo := Result.AdicionarCampo('CGC');
  vCampo.Origem := ovColuna;
  vCampo.Coluna := 'CGC';
  vCampo.Transformacoes := [Transf(ttCpfCnpj), Transf(ttDePara, 'A=1;B=2;*=3')];

  vCampo := Result.AdicionarCampo('CLIENTE');
  vCampo.Origem := ovFixo;
  vCampo.ValorFixo := 'T';

  vCampo := Result.AdicionarCampo('NUMERO_DOC');
  vCampo.Origem := ovPadrao;
  vCampo.Coluna := 'Numero do Documento';
  vCampo.ValorPadrao := 'S/N';
  vCampo.PadraoSeInexistente := False;
  vCampo.PadraoSeVazio := True;
  vCampo.PadraoSeInvalido := True;

  vCampo := Result.AdicionarCampo('FK_PAIS');
  vCampo.Origem := ovConsulta;
  vCampo.Coluna := 'Pais';
  vCampo.ConsultaTabela := 'PAIS';
  vCampo.ConsultaCampoPesquisa := 'NOME';
  vCampo.ConsultaCampoRetorno := 'CODIGO';
  vCampo.ConsultaSeNaoAchar := aneNulo;

  vCampo := Result.AdicionarCampo('CODIGO');
  vCampo.Origem := ovGerado;
  vCampo.Generator := 'GEN_FORNECEDOR';

  vCampo := Result.AdicionarCampo('OBS');
  vCampo.Origem := ovExpressao;
  vCampo.Expressao := 'MIGRADO: {Descricao} - "aspas" e \barra';

  vCampo := Result.AdicionarCampo('FK_CIDADE');
  vCampo.Origem := ovConsultaSql;
  vCampo.Coluna := 'Cidade';
  vCampo.ConsultaSql := 'select max(CODIGO)' + sLineBreak + 'from CIDADE' + sLineBreak +
    'where UPPER(NOME) = UPPER({valor}) and UF = {UF}';
  vCampo.Transformacoes := [Transf(ttSubtrairColuna, 'Valor do Juros'), Transf(ttArredondar, '2')];

  // Não mapeado: não vai para o arquivo
  Result.AdicionarCampo('FAX');
end;

function TTestPerfilArquivo.Ler(const ATexto: string): TObjectList<TPerfilExportado>;
begin
  Result := JsonParaPerfis(ATexto);
end;

procedure TTestPerfilArquivo.VerificarErro(const ATexto, ATrechoDaMensagem: string);
var
  vLista: TObjectList<TPerfilExportado>;
begin
  try
    vLista := JsonParaPerfis(ATexto);
    vLista.Free;
    Fail('Deveria recusar o arquivo: ' + ATrechoDaMensagem);
  except
    on E: ETestFailure do
      raise;
    on E: Exception do
      CheckTrue(Pos(ATrechoDaMensagem, E.Message) > 0, 'Mensagem inesperada: ' + E.Message);
  end;
end;

procedure TTestPerfilArquivo.TestIdaEVolta;
var
  vOriginal, vLido: TPerfil;
  vLista: TObjectList<TPerfilExportado>;
  vCampoOriginal, vCampoLido: TCampoPerfil;
  i, j: Integer;
begin
  vOriginal := PerfilCompleto;
  try
    vLista := Ler(PerfisParaJson([vOriginal], ['CONEXAO SIDI']));
    try
      CheckEquals(1, vLista.Count);
      CheckEquals('CONEXAO SIDI', vLista[0].Conexao);
      vLido := vLista[0].Perfil;
      CheckEquals(vOriginal.Nome, vLido.Nome);
      CheckEquals(vOriginal.Descricao, vLido.Descricao);
      CheckEquals(vOriginal.TabelaDestino, vLido.TabelaDestino);
      CheckEquals(vOriginal.ArquivoExemplo, vLido.ArquivoExemplo);
      CheckEquals(vOriginal.Aba, vLido.Aba);
      CheckEquals(3, vLido.LinhaCabecalho);
      CheckEquals(5, vLido.LinhaInicial);
      CheckTrue(vLido.Estrategia = egInserirOuAtualizar, 'estratégia');
      CheckEquals('CGC', vLido.CamposChave);
      CheckTrue(vLido.AcaoErro = aeDesfazerTudo, 'ação em erro');

      CheckEquals(Length(vOriginal.CamposMapeados), Length(vLido.CamposMapeados));
      for i := 0 to High(vOriginal.CamposMapeados) do
      begin
        vCampoOriginal := vOriginal.CamposMapeados[i];
        vCampoLido := vLido.CamposMapeados[i];
        CheckEquals(vCampoOriginal.CampoDestino, vCampoLido.CampoDestino, 'ordem dos campos');
        CheckTrue(vCampoOriginal.Origem = vCampoLido.Origem, vCampoOriginal.CampoDestino + ': origem');
        CheckEquals(vCampoOriginal.Coluna, vCampoLido.Coluna);
        CheckEquals(vCampoOriginal.ValorFixo, vCampoLido.ValorFixo);
        CheckEquals(vCampoOriginal.ValorPadrao, vCampoLido.ValorPadrao);
        CheckEquals(vCampoOriginal.PadraoSeInexistente, vCampoLido.PadraoSeInexistente);
        CheckEquals(vCampoOriginal.PadraoSeVazio, vCampoLido.PadraoSeVazio);
        CheckEquals(vCampoOriginal.PadraoSeInvalido, vCampoLido.PadraoSeInvalido);
        CheckEquals(vCampoOriginal.Generator, vCampoLido.Generator);
        CheckEquals(vCampoOriginal.Expressao, vCampoLido.Expressao);
        CheckEquals(vCampoOriginal.ConsultaTabela, vCampoLido.ConsultaTabela);
        CheckEquals(vCampoOriginal.ConsultaCampoPesquisa, vCampoLido.ConsultaCampoPesquisa);
        CheckEquals(vCampoOriginal.ConsultaCampoRetorno, vCampoLido.ConsultaCampoRetorno);
        CheckTrue(vCampoOriginal.ConsultaSeNaoAchar = vCampoLido.ConsultaSeNaoAchar,
          vCampoOriginal.CampoDestino + ': consulta sem resultado');
        CheckEquals(vCampoOriginal.ConsultaSql, vCampoLido.ConsultaSql);
        CheckEquals(Length(vCampoOriginal.Transformacoes), Length(vCampoLido.Transformacoes));
        for j := 0 to High(vCampoOriginal.Transformacoes) do
        begin
          CheckTrue(vCampoOriginal.Transformacoes[j].Tipo = vCampoLido.Transformacoes[j].Tipo, 'transformação');
          CheckEquals(vCampoOriginal.Transformacoes[j].Parametro, vCampoLido.Transformacoes[j].Parametro);
        end;
      end;
    finally
      vLista.Free;
    end;
  finally
    vOriginal.Free;
  end;
end;

procedure TTestPerfilArquivo.TestVariosPerfis;
var
  vPrimeiro, vSegundo: TPerfil;
  vLista: TObjectList<TPerfilExportado>;
begin
  vPrimeiro := PerfilCompleto;
  vSegundo := PerfilCompleto;
  try
    vSegundo.Nome := 'Fornecedores';
    vLista := Ler(PerfisParaJson([vPrimeiro, vSegundo], ['A', 'B']));
    try
      CheckEquals(2, vLista.Count);
      CheckEquals('Fornecedores', vLista[1].Perfil.Nome);
      CheckEquals('B', vLista[1].Conexao);
    finally
      vLista.Free;
    end;
  finally
    vPrimeiro.Free;
    vSegundo.Free;
  end;
end;

procedure TTestPerfilArquivo.TestNaoLevaIdNemNaoMapeados;
var
  vPerfil: TPerfil;
  vTexto: string;
  vLista: TObjectList<TPerfilExportado>;
begin
  vPerfil := PerfilCompleto;
  try
    vTexto := PerfisParaJson([vPerfil], ['X']);
    CheckFalse(Pos('"FAX"', vTexto) > 0, 'Campo não mapeado não deveria ir para o arquivo');
    CheckFalse(Pos('senha', LowerCase(vTexto)) > 0, 'O arquivo nunca leva senha');
    vLista := Ler(vTexto);
    try
      CheckEquals(0, vLista[0].Perfil.Id, 'O perfil lido é novo (sem ID)');
      CheckEquals(0, vLista[0].Perfil.IdConexao, 'A conexão é escolhida na importação');
    finally
      vLista.Free;
    end;
  finally
    vPerfil.Free;
  end;
end;

procedure TTestPerfilArquivo.TestFormatoDesconhecido;
begin
  VerificarErro('{"formato": 2, "perfis": []}', 'Formato de arquivo 2');
  VerificarErro('{"programa": "outro"}', 'sem "formato"');
  VerificarErro('{"formato": 1, "perfis": []}', 'nenhum perfil');
end;

procedure TTestPerfilArquivo.TestArquivoInvalido;
begin
  VerificarErro('isto não é JSON', 'JSON inválido');
  VerificarErro('[1, 2]', 'JSON inválido');
end;

procedure TTestPerfilArquivo.TestOrigemDesconhecida;
var
  vPerfil: TPerfil;
  vTexto: string;
begin
  vPerfil := PerfilCompleto;
  try
    vTexto := PerfisParaJson([vPerfil], ['X']);
  finally
    vPerfil.Free;
  end;
  VerificarErro(StringReplace(vTexto, '"FIXO"', '"MAGICA"', []), 'origem "MAGICA" desconhecida');
  // A mensagem diz qual perfil e qual campo
  VerificarErro(StringReplace(vTexto, '"FIXO"', '"MAGICA"', []), 'Campo CLIENTE');
end;

procedure TTestPerfilArquivo.TestTransformacaoDesconhecida;
var
  vPerfil: TPerfil;
  vTexto: string;
begin
  vPerfil := PerfilCompleto;
  try
    vTexto := PerfisParaJson([vPerfil], ['X']);
  finally
    vPerfil.Free;
  end;
  VerificarErro(StringReplace(vTexto, '"CPF_CNPJ"', '"INVENTADA"', []), 'transformação "INVENTADA" desconhecida');
end;

procedure TTestPerfilArquivo.TestEstrategiaDesconhecida;
var
  vPerfil: TPerfil;
  vTexto: string;
begin
  vPerfil := PerfilCompleto;
  try
    vTexto := PerfisParaJson([vPerfil], ['X']);
  finally
    vPerfil.Free;
  end;
  VerificarErro(StringReplace(vTexto, '"INSERIR_OU_ATUALIZAR"', '"APAGAR"', []), 'Estratégia "APAGAR"');
end;

procedure TTestPerfilArquivo.TestPerfilSemNomeOuTabela;
begin
  VerificarErro('{"formato": 1, "perfis": [{"tabelaDestino": "X"}]}', '"nome" não foi informado');
  VerificarErro('{"formato": 1, "perfis": [{"nome": "P", "estrategia": "INSERIR"}]}',
    '"tabelaDestino" não foi informado');
end;

initialization
  RegisterTest(TTestPerfilArquivo.Suite);

end.
