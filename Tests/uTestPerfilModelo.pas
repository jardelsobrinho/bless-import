unit uTestPerfilModelo;

interface

uses
  System.SysUtils, TestFramework, uPerfilModelo, uTransformacoes;

type
  TTestPerfilModelo = class(TTestCase)
  private
    function Valida(ACampo: TCampoPerfil): string;
  published
    procedure TestNovoCampoNaoImporta;
    procedure TestValidarColuna;
    procedure TestValidarFixo;
    procedure TestValidarPadrao;
    procedure TestValidarConsulta;
    procedure TestValidarGeradoEExpressao;
    procedure TestCamposMapeados;
    procedure TestAdicionarCampoNaoDuplica;
    procedure TestAssignCopiaIndependente;
    procedure TestCodigosDeOrigem;
    procedure TestColunasDoModelo;
    procedure TestColunasUsadas;
    procedure TestCamposChave;
    procedure TestEstrategiaEAcaoErro;
  end;

implementation

function TTestPerfilModelo.Valida(ACampo: TCampoPerfil): string;
begin
  ACampo.ValidarConfiguracao(Result);
end;

procedure TTestPerfilModelo.TestNovoCampoNaoImporta;
var
  vCampo: TCampoPerfil;
begin
  vCampo := TCampoPerfil.Create('CGC');
  try
    CheckFalse(vCampo.Mapeado);
    CheckEquals('', Valida(vCampo), 'Campo não importado não tem o que validar');
    // Padrões das condições do valor padrão: inexistente e vazio sim, inválido não
    CheckTrue(vCampo.PadraoSeInexistente);
    CheckTrue(vCampo.PadraoSeVazio);
    CheckFalse(vCampo.PadraoSeInvalido);
  finally
    vCampo.Free;
  end;
end;

procedure TTestPerfilModelo.TestValidarColuna;
var
  vCampo: TCampoPerfil;
begin
  vCampo := TCampoPerfil.Create('CGC');
  try
    vCampo.Origem := ovColuna;
    CheckNotEquals('', Valida(vCampo), 'Coluna sem nome');
    vCampo.Coluna := 'CGC';
    CheckEquals('', Valida(vCampo));
  finally
    vCampo.Free;
  end;
end;

procedure TTestPerfilModelo.TestValidarFixo;
var
  vCampo: TCampoPerfil;
begin
  vCampo := TCampoPerfil.Create('CLIENTE');
  try
    vCampo.Origem := ovFixo;
    CheckNotEquals('', Valida(vCampo), 'Valor fixo vazio');
    vCampo.ValorFixo := 'T';
    CheckEquals('', Valida(vCampo));
  finally
    vCampo.Free;
  end;
end;

procedure TTestPerfilModelo.TestValidarPadrao;
var
  vCampo: TCampoPerfil;
begin
  vCampo := TCampoPerfil.Create('ATIVO');
  try
    vCampo.Origem := ovPadrao;
    vCampo.Coluna := 'Inativo';
    CheckNotEquals('', Valida(vCampo), 'Sem valor padrão');
    vCampo.ValorPadrao := 'S';
    CheckEquals('', Valida(vCampo));
    vCampo.PadraoSeInexistente := False;
    vCampo.PadraoSeVazio := False;
    vCampo.PadraoSeInvalido := False;
    CheckNotEquals('', Valida(vCampo), 'Padrão sem nenhuma condição nunca seria usado');
  finally
    vCampo.Free;
  end;
end;

procedure TTestPerfilModelo.TestValidarConsulta;
var
  vCampo: TCampoPerfil;
begin
  vCampo := TCampoPerfil.Create('FK_CLIENTE');
  try
    vCampo.Origem := ovConsulta;
    vCampo.Coluna := 'CGC';
    CheckNotEquals('', Valida(vCampo), 'Consulta sem tabela');
    vCampo.ConsultaTabela := 'FORNECEDOR';
    vCampo.ConsultaCampoPesquisa := 'CGC';
    CheckNotEquals('', Valida(vCampo), 'Consulta sem campo de retorno');
    vCampo.ConsultaCampoRetorno := 'CODIGO';
    CheckEquals('', Valida(vCampo));
  finally
    vCampo.Free;
  end;
end;

procedure TTestPerfilModelo.TestValidarGeradoEExpressao;
var
  vCampo: TCampoPerfil;
begin
  vCampo := TCampoPerfil.Create('CODIGO');
  try
    vCampo.Origem := ovGerado;
    CheckNotEquals('', Valida(vCampo), 'Sem generator');
    vCampo.Generator := 'GEN_FORNECEDOR';
    CheckEquals('', Valida(vCampo));
    CheckFalse(vCampo.UsaColuna);

    vCampo.Origem := ovExpressao;
    CheckNotEquals('', Valida(vCampo), 'Sem expressão');
    vCampo.Expressao := '{Endereco}, {Numero}';
    CheckEquals('', Valida(vCampo));
  finally
    vCampo.Free;
  end;
end;

procedure TTestPerfilModelo.TestCamposMapeados;
var
  vPerfil: TPerfil;
begin
  vPerfil := TPerfil.Create;
  try
    vPerfil.AdicionarCampo('A');
    vPerfil.AdicionarCampo('B').Origem := ovFixo;
    vPerfil.AdicionarCampo('C').Origem := ovColuna;
    CheckEquals(3, vPerfil.Campos.Count);
    CheckEquals(2, Length(vPerfil.CamposMapeados));
    CheckEquals('B', vPerfil.CamposMapeados[0].CampoDestino);
  finally
    vPerfil.Free;
  end;
end;

procedure TTestPerfilModelo.TestAdicionarCampoNaoDuplica;
var
  vPerfil: TPerfil;
begin
  vPerfil := TPerfil.Create;
  try
    vPerfil.AdicionarCampo('cgc').Origem := ovColuna;
    vPerfil.AdicionarCampo('CGC');
    CheckEquals(1, vPerfil.Campos.Count);
    CheckEquals('CGC', vPerfil.Campos[0].CampoDestino, 'Nome do campo fica em maiúsculas');
    CheckTrue(vPerfil.CampoPorNome('Cgc').Origem = ovColuna, 'Mantém o campo já existente');
  finally
    vPerfil.Free;
  end;
end;

procedure TTestPerfilModelo.TestAssignCopiaIndependente;
var
  vOriginal, vCopia: TPerfil;
  vTransformacao: TTransformacao;
begin
  vOriginal := TPerfil.Create;
  vCopia := TPerfil.Create;
  try
    vOriginal.Nome := 'Clientes';
    vOriginal.TabelaDestino := 'FORNECEDOR';
    vTransformacao.Tipo := ttCpfCnpj;
    vTransformacao.Parametro := '';
    vOriginal.AdicionarCampo('CGC');
    vOriginal.Campos[0].Origem := ovColuna;
    vOriginal.Campos[0].Coluna := 'CGC';
    vOriginal.Campos[0].Transformacoes := [vTransformacao];

    vCopia.Assign(vOriginal);
    CheckEquals('Clientes', vCopia.Nome);
    CheckEquals(1, vCopia.Campos.Count);
    CheckTrue(vCopia.Campos[0] <> vOriginal.Campos[0], 'Os campos da cópia são outros objetos');

    // Alterar a cópia não pode mexer no original (inclusive na lista de transformações)
    vCopia.Campos[0].Coluna := 'OUTRA';
    vCopia.Campos[0].Transformacoes[0].Parametro := 'FORMATADO';
    CheckEquals('CGC', vOriginal.Campos[0].Coluna);
    CheckEquals('', vOriginal.Campos[0].Transformacoes[0].Parametro);
  finally
    vCopia.Free;
    vOriginal.Free;
  end;
end;

procedure TTestPerfilModelo.TestCodigosDeOrigem;
var
  vOrigem, vLida: TOrigemValor;
begin
  for vOrigem := Succ(ovNaoImportar) to High(TOrigemValor) do
  begin
    CheckTrue(OrigemPorCodigo(cORIGENS[vOrigem].Codigo, vLida), cORIGENS[vOrigem].Codigo);
    CheckTrue(vLida = vOrigem, cORIGENS[vOrigem].Codigo);
  end;
  CheckFalse(OrigemPorCodigo('', vLida), '"Não importar" não é gravado no banco');
  CheckFalse(OrigemPorCodigo('XYZ', vLida));
  CheckTrue(AcaoNaoEncontradoPorCodigo('NULO') = aneNulo);
  CheckTrue(AcaoNaoEncontradoPorCodigo('') = anePendencia, 'Padrão seguro: pendência');
end;

procedure TTestPerfilModelo.TestColunasDoModelo;
var
  vColunas: TArray<string>;
begin
  vColunas := ColunasDoModelo('{valor}, { Numero } - {Bairro} / {numero}');
  CheckEquals(2, Length(vColunas), '{valor} não conta e repetidas (sem diferenciar maiúsculas) saem uma vez');
  CheckEquals('Numero', vColunas[0]);
  CheckEquals('Bairro', vColunas[1]);
  CheckEquals(0, Length(ColunasDoModelo('sem colunas')));
  CheckEquals(1, Length(ColunasDoModelo('{A} {sem fechar')), 'Chave sem fechar é ignorada');
end;

procedure TTestPerfilModelo.TestColunasUsadas;
var
  vCampo: TCampoPerfil;
  vTransformacao: TTransformacao;
  vColunas: TArray<string>;
begin
  vCampo := TCampoPerfil.Create('ENDERECO');
  try
    vCampo.Coluna := 'Endereco';
    CheckEquals(0, Length(vCampo.ColunasUsadas), 'Não importar não usa nenhuma coluna');

    vCampo.Origem := ovColuna;
    vTransformacao.Tipo := ttConcatenar;
    vTransformacao.Parametro := '{valor}, {Numero} - {endereco}';
    vCampo.Transformacoes := [vTransformacao];
    vColunas := vCampo.ColunasUsadas;
    CheckEquals(2, Length(vColunas), 'Coluna + concatenar, sem repetir Endereco');
    CheckEquals('Endereco', vColunas[0]);
    CheckEquals('Numero', vColunas[1]);

    vCampo.Origem := ovFixo;
    vCampo.ValorFixo := 'X';
    vColunas := vCampo.ColunasUsadas;
    CheckEquals(2, Length(vColunas), 'Valor fixo: só as colunas citadas no concatenar');
    CheckEquals('Numero', vColunas[0]);
    CheckEquals('endereco', vColunas[1]);

    vCampo.Origem := ovExpressao;
    vCampo.Expressao := '{Cidade}/{UF}';
    vCampo.Transformacoes := nil;
    vColunas := vCampo.ColunasUsadas;
    CheckEquals(2, Length(vColunas));
    CheckEquals('Cidade', vColunas[0]);
    CheckEquals('UF', vColunas[1]);

    vCampo.Origem := ovGerado;
    vCampo.Transformacoes := [vTransformacao];
    CheckEquals(0, Length(vCampo.ColunasUsadas), 'Valor gerado não lê a planilha');
  finally
    vCampo.Free;
  end;
end;

procedure TTestPerfilModelo.TestCamposChave;
var
  vPerfil: TPerfil;
  vChaves: TArray<string>;
begin
  vPerfil := TPerfil.Create;
  try
    CheckEquals(0, Length(vPerfil.ListaCamposChave));
    vPerfil.CamposChave := ' cgc ; Codigo,,';
    vChaves := vPerfil.ListaCamposChave;
    CheckEquals(2, Length(vChaves), 'Aceita ; e , e ignora vazios');
    CheckEquals('CGC', vChaves[0]);
    CheckEquals('CODIGO', vChaves[1]);

    vPerfil.DefinirCamposChave(['tipo', ' numero ', '']);
    CheckEquals('TIPO;NUMERO', vPerfil.CamposChave);
  finally
    vPerfil.Free;
  end;
end;

procedure TTestPerfilModelo.TestEstrategiaEAcaoErro;
var
  vEstrategia: TEstrategiaGravacao;
  vAcao: TAcaoErro;
  vPerfil: TPerfil;
begin
  for vEstrategia := Low(TEstrategiaGravacao) to High(TEstrategiaGravacao) do
    CheckTrue(EstrategiaPorCodigo(cESTRATEGIAS[vEstrategia].Codigo) = vEstrategia, cESTRATEGIAS[vEstrategia].Codigo);
  for vAcao := Low(TAcaoErro) to High(TAcaoErro) do
    CheckTrue(AcaoErroPorCodigo(cACOES_ERRO[vAcao].Codigo) = vAcao, cACOES_ERRO[vAcao].Codigo);
  // Código desconhecido (ou vazio) cai no padrão do banco: INSERIR / CONTINUAR
  CheckTrue(EstrategiaPorCodigo('XYZ') = egInserir);
  CheckTrue(AcaoErroPorCodigo('') = aeContinuar);

  CheckFalse(EstrategiaUsaChave(egInserir));
  CheckFalse(EstrategiaUsaChave(egSomenteValidar));
  CheckTrue(EstrategiaUsaChave(egIgnorarExistentes));
  CheckTrue(EstrategiaUsaChave(egAtualizar));
  CheckTrue(EstrategiaUsaChave(egInserirOuAtualizar));

  vPerfil := TPerfil.Create;
  try
    CheckTrue(vPerfil.Estrategia = egInserir, 'Perfil novo insere');
    CheckTrue(vPerfil.AcaoErro = aeContinuar, 'Perfil novo continua nos erros');
  finally
    vPerfil.Free;
  end;
end;

initialization
  RegisterTest(TTestPerfilModelo.Suite);

end.
