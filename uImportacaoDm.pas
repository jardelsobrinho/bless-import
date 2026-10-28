unit uImportacaoDm;

{ Liga perfil, banco de destino e planilha para validar, pré-visualizar e gravar (Importar).
  Gravação: uma transação no destino com commit a cada cTAMANHO_LOTE linhas (ou uma só, em "desfazer tudo");
  cada execução fica registrada em EXECUCAO/EXECUCAO_ERRO no banco de configurações. }

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections, Data.DB, FireDAC.Stan.Param,
  FireDAC.Comp.Client, uPerfilModelo, uPerfisDm, uConexoesDm, uDmDestino, uLeitorXls, uImportador;

type
  TStatusExecucao = (seEmAndamento, seConcluida, seConcluidaComErros, seInterrompida, seCancelada, seDesfeita,
    seFalhou);

  TErroImportacao = record
    Linha: Integer;
    Campo: string;
    TipoErro: TTipoErro;
    ValorRecebido: string;
    Mensagem: string;
  end;

  TResumoImportacao = record
    IdExecucao: Integer;
    Status: TStatusExecucao;
    Mensagem: string;
    LinhaAtual: Integer;
    UltimaLinhaPlanilha: Integer;
    UltimaLinhaGravada: Integer;   // última linha com gravação confirmada (commit)
    Lidas: Integer;
    Inseridas: Integer;
    Atualizadas: Integer;
    Ignoradas: Integer;
    Validadas: Integer;
    ComErro: Integer;
    Vazias: Integer;
  end;

  // Chamado durante a importação; ACancelar = True interrompe
  TProgressoImportacao = reference to procedure(const AResumo: TResumoImportacao; var ACancelar: Boolean);

  TdmImportacao = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FDmPerfis: TdmPerfis;
    FDmConexoes: TdmConexoes;
    FDmDestino: TdmDestino;
    FLeitor: TLeitorXls;
    FPerfil: TPerfil;
    FCamposDestino: TArray<TCampoDestino>;
    FTabelaExiste: Boolean;
    FArquivoAberto: string;
    FNomesColunas: TArray<string>;
    FIndiceColunas: TDictionary<string, Integer>;
    procedure VerificarPerfil;
    procedure PrepararAba;
    function ObterCelulaDaLinha(ALinha: Integer): TObterCelula;
    procedure VerificarAntesDeGravar;
    function CriarExecucao(AIdExecucaoOrigem, ALinhaInicio: Integer): Integer;
    procedure AtualizarExecucao(const AResumo: TResumoImportacao; AFinal: Boolean);
  public
    // Lê o perfil gravado (sempre a versão mais recente) e conecta no destino
    procedure CarregarPerfil(AId: Integer);
    // Abre a planilha (só relê o arquivo se ele mudou) e aplica aba e linhas do perfil
    procedure AbrirPlanilha(const AArquivo: string);
    function PlanilhaAberta: Boolean;
    function ValidarPerfil: TArray<TProblemaPerfil>;
    // AMaximoLinhas = 0: todas as linhas. Linhas totalmente vazias são puladas e contadas em ALinhasVazias
    function PreVisualizar(AMaximoLinhas: Integer; out ALinhasVazias: Integer): TArray<TResultadoLinha>;
    function LinhasDeDados: Integer;
    function CamposMapeados: TArray<TCampoPerfil>;
    // Grava as linhas no destino conforme a estratégia do perfil; erros de linha não geram exceção
    // (ficam em AErros e em EXECUCAO_ERRO). Exceção só se o perfil não puder ser gravado.
    // Retomada: AIdExecucaoOrigem = execução interrompida e ALinhaInicio = linha da planilha onde continuar
    // (a ULTIMA_LINHA dela + 1); 0 = desde o começo.
    function Importar(AProgresso: TProgressoImportacao; out AErros: TArray<TErroImportacao>;
      AIdExecucaoOrigem: Integer = 0; ALinhaInicio: Integer = 0): TResumoImportacao;
    // Última linha da planilha aberta
    function UltimaLinhaPlanilha: Integer;
    // Descrição do banco de destino para a confirmação: "Nome (servidor:banco)"
    function DescricaoDestino: string;
    property Perfil: TPerfil read FPerfil;
    property DmPerfis: TdmPerfis read FDmPerfis;
  end;

const
  cSTATUS_EXECUCAO: array[TStatusExecucao] of TInfoOrigem = (
    (Codigo: 'EM_ANDAMENTO'; Nome: 'Em andamento'),
    (Codigo: 'CONCLUIDA'; Nome: 'Concluída'),
    (Codigo: 'CONCLUIDA_COM_ERROS'; Nome: 'Concluída com erros'),
    (Codigo: 'INTERROMPIDA'; Nome: 'Interrompida por erro'),
    (Codigo: 'CANCELADA'; Nome: 'Cancelada pelo usuário'),
    (Codigo: 'DESFEITA'; Nome: 'Desfeita (nada foi gravado)'),
    (Codigo: 'FALHOU'; Nome: 'Falhou'));

  cTIPOS_ERRO_CODIGO: array[TTipoErro] of string = ('', 'VALIDACAO', 'TRANSFORMACAO', 'REFERENCIA', 'GRAVACAO');

  cINTERVALO_PROGRESSO = 25;     // linhas entre avisos de progresso

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  uDmConexao;

type
  TResultadoGravacao = (rgInserida, rgAtualizada, rgIgnorada);

procedure TdmImportacao.DataModuleCreate(Sender: TObject);
begin
  FDmPerfis := TdmPerfis.Create(Self);
  FDmConexoes := TdmConexoes.Create(Self);
  FDmDestino := TdmDestino.Create(Self);
  FLeitor := TLeitorXls.Create;
  FIndiceColunas := TDictionary<string, Integer>.Create;
end;

procedure TdmImportacao.DataModuleDestroy(Sender: TObject);
begin
  FIndiceColunas.Free;
  FLeitor.Free;
  FPerfil.Free;
end;

procedure TdmImportacao.VerificarPerfil;
begin
  if FPerfil = nil then
    raise Exception.Create('Selecione o perfil de importação.');
end;

procedure TdmImportacao.CarregarPerfil(AId: Integer);
var
  vPerfil: TPerfil;
begin
  vPerfil := FDmPerfis.Carregar(AId);
  FPerfil.Free;
  FPerfil := vPerfil;

  FCamposDestino := nil;
  FTabelaExiste := False;
  try
    FDmDestino.Conectar(FDmConexoes.Carregar(FPerfil.IdConexao));
  except
    on E: Exception do
      raise Exception.Create('Não foi possível conectar ao banco de destino do perfil:' + sLineBreak + E.Message);
  end;
  FTabelaExiste := FDmDestino.ExisteTabela(FPerfil.TabelaDestino);
  if FTabelaExiste then
    FCamposDestino := FDmDestino.Campos(FPerfil.TabelaDestino);

  if FArquivoAberto <> '' then
    PrepararAba;
end;

procedure TdmImportacao.AbrirPlanilha(const AArquivo: string);
begin
  VerificarPerfil;
  if Trim(AArquivo) = '' then
    raise Exception.Create('Informe a planilha.');

  if not SameText(AArquivo, FArquivoAberto) then
  begin
    FArquivoAberto := '';
    FLeitor.Abrir(AArquivo);
    FArquivoAberto := AArquivo;
  end;
  PrepararAba;
end;

procedure TdmImportacao.PrepararAba;
var
  vAbas: TArray<string>;
  vIndice, i: Integer;
  vColunas: TArray<TColunaPlanilha>;
begin
  vAbas := FLeitor.Abas;
  vIndice := -1;
  if FPerfil.Aba = '' then
    vIndice := 0
  else
    for i := 0 to High(vAbas) do
      if SameText(vAbas[i], FPerfil.Aba) then
        vIndice := i;
  if vIndice < 0 then
    raise Exception.CreateFmt('A aba "%s" do perfil não existe na planilha (abas: %s).',
      [FPerfil.Aba, string.Join(', ', vAbas)]);

  FLeitor.SelecionarAba(vIndice);
  FLeitor.LinhaCabecalho := FPerfil.LinhaCabecalho;
  FLeitor.LinhaInicial := FPerfil.LinhaInicial;

  // Amostra de 1 linha: aqui só interessam os nomes das colunas
  vColunas := FLeitor.Colunas(1);
  FIndiceColunas.Clear;
  SetLength(FNomesColunas, Length(vColunas));
  for i := 0 to High(vColunas) do
  begin
    FNomesColunas[i] := vColunas[i].Nome;
    FIndiceColunas.AddOrSetValue(UpperCase(vColunas[i].Nome), vColunas[i].Indice);
  end;
end;

function TdmImportacao.PlanilhaAberta: Boolean;
begin
  Result := FArquivoAberto <> '';
end;

function TdmImportacao.LinhasDeDados: Integer;
begin
  if PlanilhaAberta then
    Result := FLeitor.UltimaLinha - FLeitor.LinhaInicial + 1
  else
    Result := 0;
end;

function TdmImportacao.CamposMapeados: TArray<TCampoPerfil>;
begin
  VerificarPerfil;
  Result := FPerfil.CamposMapeados;
end;

function TdmImportacao.ObterCelulaDaLinha(ALinha: Integer): TObterCelula;
begin
  Result :=
    function(const AColuna: string; out AValor: Variant; out ATexto: string): Boolean
    var
      vIndice: Integer;
      vCelula: TCelula;
    begin
      Result := FIndiceColunas.TryGetValue(UpperCase(Trim(AColuna)), vIndice);
      if Result then
      begin
        vCelula := FLeitor.Celula(ALinha, vIndice);
        AValor := vCelula.Valor;
        ATexto := vCelula.Texto;
      end
      else
      begin
        AValor := Null;
        ATexto := '';
      end;
    end;
end;

function TdmImportacao.ValidarPerfil: TArray<TProblemaPerfil>;
begin
  VerificarPerfil;
  Result := uImportador.ValidarPerfil(FPerfil, FTabelaExiste, FCamposDestino, PlanilhaAberta, FNomesColunas,
    FDmDestino.Generators, FDmDestino.Tabelas,
    function(ATabela: string): TArray<TCampoDestino>
    begin
      Result := FDmDestino.Campos(ATabela);
    end,
    function(ASql: string): string
    begin
      Result := FDmDestino.TestarSql(ASql);
    end);
end;

function TdmImportacao.PreVisualizar(AMaximoLinhas: Integer; out ALinhasVazias: Integer): TArray<TResultadoLinha>;
var
  vResolvedor: TResolvedorValores;
  vConsultas: TConsultaReferencias;
  vResultados: TList<TResultadoLinha>;
  vLinha, vUltima: Integer;
begin
  VerificarPerfil;
  if not PlanilhaAberta then
    raise Exception.Create('Abra a planilha antes de pré-visualizar.');
  if not FTabelaExiste then
    raise Exception.CreateFmt('A tabela de destino %s não existe no banco.', [FPerfil.TabelaDestino]);

  ALinhasVazias := 0;
  vResultados := TList<TResultadoLinha>.Create;
  vConsultas := TConsultaReferencias.Create(FDmDestino);
  vResolvedor := TResolvedorValores.Create(FPerfil, FCamposDestino);
  try
    vResolvedor.Consultar := vConsultas.Consultar;
    vResolvedor.ConsultarSql := vConsultas.ConsultarSql;
    vUltima := FLeitor.UltimaLinha;
    vLinha := FLeitor.LinhaInicial;
    while (vLinha <= vUltima) and ((AMaximoLinhas = 0) or (vResultados.Count < AMaximoLinhas)) do
    begin
      if FLeitor.LinhaVazia(vLinha) then
        Inc(ALinhasVazias)
      else
        vResultados.Add(vResolvedor.ResolverLinha(vLinha, ObterCelulaDaLinha(vLinha)));
      Inc(vLinha);
    end;
    Result := vResultados.ToArray;
  finally
    vResolvedor.Free;
    vConsultas.Free;
    vResultados.Free;
  end;
end;

{ Gravação }

function TdmImportacao.DescricaoDestino: string;
begin
  Result := Format('%s (%s:%s)', [FDmDestino.Conexao.Nome, FDmDestino.Conexao.Servidor, FDmDestino.Conexao.Banco]);
end;

procedure TdmImportacao.VerificarAntesDeGravar;
var
  vProblema: TProblemaPerfil;
  vMensagem: string;
  vErros: Integer;
begin
  VerificarPerfil;
  if not PlanilhaAberta then
    raise Exception.Create('Abra a planilha antes de importar.');
  if not FTabelaExiste then
    raise Exception.CreateFmt('A tabela de destino %s não existe no banco.', [FPerfil.TabelaDestino]);

  vMensagem := '';
  vErros := 0;
  for vProblema in ValidarPerfil do
    if vProblema.Gravidade = gvErro then
    begin
      Inc(vErros);
      if vErros <= 10 then
      begin
        if vProblema.Campo = '' then
          vMensagem := vMensagem + sLineBreak + '  ' + vProblema.Mensagem
        else
          vMensagem := vMensagem + sLineBreak + '  ' + vProblema.Campo + ': ' + vProblema.Mensagem;
      end;
    end;
  if vErros > 0 then
    raise Exception.CreateFmt('O perfil tem %d erro(s) e não pode ser gravado:%s', [vErros, vMensagem]);
end;

function TdmImportacao.CriarExecucao(AIdExecucaoOrigem, ALinhaInicio: Integer): Integer;
var
  vQry: TFDQuery;
begin
  vQry := TFDQuery.Create(nil);
  try
    vQry.Connection := dmConexao.cnConexao;
    vQry.SQL.Text :=
      'insert into EXECUCAO (ID_PERFIL, VERSAO_PERFIL, ARQUIVO, ABA, CONEXAO, TABELA_DESTINO, ESTRATEGIA, ' +
      'ACAO_ERRO, STATUS, ID_EXECUCAO_ORIGEM, LINHA_INICIO) ' +
      'values (:ID_PERFIL, :VERSAO_PERFIL, :ARQUIVO, :ABA, :CONEXAO, :TABELA_DESTINO, :ESTRATEGIA, :ACAO_ERRO, ' +
      ':STATUS, :ID_EXECUCAO_ORIGEM, :LINHA_INICIO) returning ID';
    vQry.ParamByName('ID_EXECUCAO_ORIGEM').DataType := ftInteger;
    if AIdExecucaoOrigem > 0 then
      vQry.ParamByName('ID_EXECUCAO_ORIGEM').AsInteger := AIdExecucaoOrigem
    else
      vQry.ParamByName('ID_EXECUCAO_ORIGEM').Clear;
    vQry.ParamByName('LINHA_INICIO').AsInteger := ALinhaInicio;
    vQry.ParamByName('ID_PERFIL').AsInteger := FPerfil.Id;
    vQry.ParamByName('VERSAO_PERFIL').AsInteger := FPerfil.Versao;
    vQry.ParamByName('ARQUIVO').AsString := Copy(FArquivoAberto, 1, 500);
    vQry.ParamByName('ABA').AsString := FPerfil.Aba;
    vQry.ParamByName('CONEXAO').AsString := Copy(DescricaoDestino, 1, 400);
    vQry.ParamByName('TABELA_DESTINO').AsString := FPerfil.TabelaDestino;
    vQry.ParamByName('ESTRATEGIA').AsString := cESTRATEGIAS[FPerfil.Estrategia].Codigo;
    vQry.ParamByName('ACAO_ERRO').AsString := cACOES_ERRO[FPerfil.AcaoErro].Codigo;
    vQry.ParamByName('STATUS').AsString := cSTATUS_EXECUCAO[seEmAndamento].Codigo;

    dmConexao.StartTransaction;
    try
      vQry.Open;
      Result := vQry.Fields[0].AsInteger;
      vQry.Close;
      dmConexao.Commit;
    except
      dmConexao.Rollback;
      raise;
    end;
  finally
    vQry.Free;
  end;
end;

procedure TdmImportacao.AtualizarExecucao(const AResumo: TResumoImportacao; AFinal: Boolean);
var
  vQry: TFDQuery;
begin
  vQry := TFDQuery.Create(nil);
  try
    vQry.Connection := dmConexao.cnConexao;
    vQry.SQL.Text :=
      'update EXECUCAO set STATUS = :STATUS, LINHAS_LIDAS = :LIDAS, INSERIDAS = :INSERIDAS, ' +
      'ATUALIZADAS = :ATUALIZADAS, IGNORADAS = :IGNORADAS, VALIDADAS = :VALIDADAS, COM_ERRO = :COM_ERRO, ' +
      'VAZIAS = :VAZIAS, ULTIMA_LINHA = :ULTIMA_LINHA, MENSAGEM = :MENSAGEM';
    if AFinal then
      vQry.SQL.Add(', FIM = current_timestamp');
    vQry.SQL.Add(' where ID = :ID');
    vQry.ParamByName('STATUS').AsString := cSTATUS_EXECUCAO[AResumo.Status].Codigo;
    vQry.ParamByName('LIDAS').AsInteger := AResumo.Lidas;
    vQry.ParamByName('INSERIDAS').AsInteger := AResumo.Inseridas;
    vQry.ParamByName('ATUALIZADAS').AsInteger := AResumo.Atualizadas;
    vQry.ParamByName('IGNORADAS').AsInteger := AResumo.Ignoradas;
    vQry.ParamByName('VALIDADAS').AsInteger := AResumo.Validadas;
    vQry.ParamByName('COM_ERRO').AsInteger := AResumo.ComErro;
    vQry.ParamByName('VAZIAS').AsInteger := AResumo.Vazias;
    vQry.ParamByName('ULTIMA_LINHA').AsInteger := AResumo.UltimaLinhaGravada;
    vQry.ParamByName('MENSAGEM').AsString := Copy(AResumo.Mensagem, 1, 1000);
    vQry.ParamByName('ID').AsInteger := AResumo.IdExecucao;

    // Confirma junto os erros registrados até aqui (RegistrarErro deixa a transação aberta)
    dmConexao.StartTransaction;
    try
      vQry.ExecSQL;
      dmConexao.Commit;
    except
      dmConexao.Rollback;
      raise;
    end;
  finally
    vQry.Free;
  end;
end;

function TdmImportacao.UltimaLinhaPlanilha: Integer;
begin
  if PlanilhaAberta then
    Result := FLeitor.UltimaLinha
  else
    Result := 0;
end;

function TdmImportacao.Importar(AProgresso: TProgressoImportacao; out AErros: TArray<TErroImportacao>;
  AIdExecucaoOrigem, ALinhaInicio: Integer): TResumoImportacao;
var
  vResumo: TResumoImportacao;
  vErros: TList<TErroImportacao>;
  vQryErro: TFDQuery;
  vConsultas: TConsultaReferencias;
  vResolvedor: TResolvedorValores;
  vCampos: TArray<TCampoPerfil>;
  vDestinos: TArray<TCampoDestino>;
  vIndicesChave: TArray<Integer>;

  procedure RegistrarErro(ALinha: Integer; const ACampo: string; ATipo: TTipoErro;
    const ARecebido, AMensagem: string);
  var
    vErro: TErroImportacao;
  begin
    vErro.Linha := ALinha;
    vErro.Campo := ACampo;
    vErro.TipoErro := ATipo;
    vErro.ValorRecebido := ARecebido;
    vErro.Mensagem := AMensagem;
    vErros.Add(vErro);

    dmConexao.StartTransaction;
    vQryErro.ParamByName('ID_EXECUCAO').AsInteger := vResumo.IdExecucao;
    vQryErro.ParamByName('LINHA').AsInteger := ALinha;
    vQryErro.ParamByName('CAMPO').AsString := ACampo;
    vQryErro.ParamByName('TIPO_ERRO').AsString := cTIPOS_ERRO_CODIGO[ATipo];
    vQryErro.ParamByName('VALOR_RECEBIDO').AsString := Copy(ARecebido, 1, 1000);
    vQryErro.ParamByName('MENSAGEM').AsString := Copy(AMensagem, 1, 2000);
    vQryErro.ExecSQL;
  end;

  function EhChave(AIndice: Integer): Boolean;
  var
    vIndice: Integer;
  begin
    for vIndice in vIndicesChave do
      if vIndice = AIndice then
        Exit(True);
    Result := False;
  end;

  function GravarLinha(const ALinha: TResultadoLinha): TResultadoGravacao;
  var
    vChaves, vCamposGravar: TArray<TCampoDestino>;
    vValoresChave, vValoresGravar: TArray<Variant>;
    vValor: TValorResolvido;
    vQuantidade, i: Integer;
  begin
    vChaves := nil;
    vValoresChave := nil;
    for i in vIndicesChave do
    begin
      vChaves := vChaves + [vDestinos[i]];
      vValoresChave := vValoresChave + [ALinha.Valores[i].Valor];
    end;

    vQuantidade := 0;
    if EstrategiaUsaChave(FPerfil.Estrategia) then
    begin
      vQuantidade := FDmDestino.ContarRegistros(FPerfil.TabelaDestino, vChaves, vValoresChave);
      if vQuantidade > 1 then
        raise Exception.CreateFmt('os campos-chave (%s) identificam %d registros no destino; a linha não foi gravada',
          [FPerfil.CamposChave, vQuantidade]);
    end;
    if (FPerfil.Estrategia = egIgnorarExistentes) and (vQuantidade = 1) then
      Exit(rgIgnorada);
    if (FPerfil.Estrategia = egAtualizar) and (vQuantidade = 0) then
      Exit(rgIgnorada);

    vCamposGravar := nil;
    vValoresGravar := nil;

    // Atualização: campos que não são chave nem gerados; vazio na planilha não apaga o valor que já existe
    if (FPerfil.Estrategia in [egAtualizar, egInserirOuAtualizar]) and (vQuantidade = 1) then
    begin
      for i := 0 to High(vCampos) do
      begin
        vValor := ALinha.Valores[i];
        if EhChave(i) or (vValor.Fonte = fvGerado) or VarIsNull(vValor.Valor) then
          Continue;
        vCamposGravar := vCamposGravar + [vDestinos[i]];
        vValoresGravar := vValoresGravar + [vValor.Valor];
      end;
      if Length(vCamposGravar) = 0 then
        Exit(rgIgnorada);
      FDmDestino.Atualizar(FPerfil.TabelaDestino, vCamposGravar, vValoresGravar, vChaves, vValoresChave);
      Exit(rgAtualizada);
    end;

    // Inserção: gerados pegam o próximo valor do generator; nulo em campo com DEFAULT fica com o padrão do banco
    for i := 0 to High(vCampos) do
    begin
      vValor := ALinha.Valores[i];
      if vValor.Fonte = fvGerado then
      begin
        vCamposGravar := vCamposGravar + [vDestinos[i]];
        vValoresGravar := vValoresGravar + [FDmDestino.ProximoValor(vCampos[i].Generator)];
      end
      else if VarIsNull(vValor.Valor) and (vDestinos[i].Padrao <> '') then
        Continue
      else
      begin
        vCamposGravar := vCamposGravar + [vDestinos[i]];
        vValoresGravar := vValoresGravar + [vValor.Valor];
      end;
    end;
    FDmDestino.Inserir(FPerfil.TabelaDestino, vCamposGravar, vValoresGravar);
    Result := rgInserida;
  end;

var
  vGravar, vTudoOuNada, vErroNaLinha, vCancelar: Boolean;
  vLinha, vNoLote, vPrimeiraLinha, vPontoAnterior, i: Integer;
  vNome: string;
  vResultado: TResultadoLinha;
  vValor: TValorResolvido;
begin
  VerificarAntesDeGravar;
  AErros := nil;
  vResumo := Default(TResumoImportacao);
  vResumo.Status := seEmAndamento;
  vResumo.UltimaLinhaPlanilha := FLeitor.UltimaLinha;

  // Retomada: começa depois da última linha confirmada da execução anterior
  vPrimeiraLinha := FLeitor.LinhaInicial;
  if ALinhaInicio > vPrimeiraLinha then
    vPrimeiraLinha := ALinhaInicio;
  if vPrimeiraLinha > vResumo.UltimaLinhaPlanilha then
    raise Exception.CreateFmt('A linha %d está depois do fim da planilha (última linha: %d): não há o que importar.',
      [vPrimeiraLinha, vResumo.UltimaLinhaPlanilha]);
  // Ponto de retomada que vale se nada desta execução for confirmado
  if AIdExecucaoOrigem > 0 then
    vPontoAnterior := vPrimeiraLinha - 1
  else
    vPontoAnterior := 0;
  vResumo.UltimaLinhaGravada := vPontoAnterior;
  vGravar := FPerfil.Estrategia <> egSomenteValidar;
  vTudoOuNada := FPerfil.AcaoErro = aeDesfazerTudo;
  vCancelar := False;

  vErros := TList<TErroImportacao>.Create;
  vQryErro := TFDQuery.Create(nil);
  // As consultas usam a mesma conexão/transação da gravação: enxergam o que esta importação já inseriu
  vConsultas := TConsultaReferencias.Create(FDmDestino);
  vResolvedor := TResolvedorValores.Create(FPerfil, FCamposDestino);
  try
    vResolvedor.Consultar := vConsultas.Consultar;
    vResolvedor.ConsultarSql := vConsultas.ConsultarSql;
    vQryErro.Connection := dmConexao.cnConexao;
    vQryErro.SQL.Text :=
      'insert into EXECUCAO_ERRO (ID_EXECUCAO, LINHA, CAMPO, TIPO_ERRO, VALOR_RECEBIDO, MENSAGEM) ' +
      'values (:ID_EXECUCAO, :LINHA, :CAMPO, :TIPO_ERRO, :VALOR_RECEBIDO, :MENSAGEM)';

    vCampos := vResolvedor.Campos;
    vDestinos := vResolvedor.Destinos;
    vIndicesChave := nil;
    if EstrategiaUsaChave(FPerfil.Estrategia) then
      for vNome in FPerfil.ListaCamposChave do
        for i := 0 to High(vCampos) do
          if SameText(vCampos[i].CampoDestino, vNome) then
            vIndicesChave := vIndicesChave + [i];

    vResumo.IdExecucao := CriarExecucao(AIdExecucaoOrigem, vPrimeiraLinha);
    try
      if vGravar then
        FDmDestino.IniciarTransacao;
      vNoLote := 0;
      vLinha := vPrimeiraLinha;
      while vLinha <= vResumo.UltimaLinhaPlanilha do
      begin
        vResumo.LinhaAtual := vLinha;
        if FLeitor.LinhaVazia(vLinha) then
          Inc(vResumo.Vazias)
        else
        begin
          Inc(vResumo.Lidas);
          vResultado := vResolvedor.ResolverLinha(vLinha, ObterCelulaDaLinha(vLinha));

          vErroNaLinha := not vResultado.Valida;
          if vErroNaLinha then
            for vValor in vResultado.Valores do
              if not vValor.Ok then
                RegistrarErro(vLinha, vValor.Campo, vValor.TipoErro, vValor.ValorRecebido, vValor.Mensagem);

          if not vErroNaLinha then
            for i in vIndicesChave do
              if VarIsNull(vResultado.Valores[i].Valor) then
              begin
                RegistrarErro(vLinha, vCampos[i].CampoDestino, teValidacao, vResultado.Valores[i].ValorRecebido,
                  'campo-chave sem valor: não dá para saber se o registro já existe');
                vErroNaLinha := True;
              end;

          if not vErroNaLinha then
          begin
            if not vGravar then
              Inc(vResumo.Validadas)
            else
              try
                case GravarLinha(vResultado) of
                  rgInserida:
                    Inc(vResumo.Inseridas);
                  rgAtualizada:
                    Inc(vResumo.Atualizadas);
                  rgIgnorada:
                    Inc(vResumo.Ignoradas);
                end;
                Inc(vNoLote);
              except
                on E: Exception do
                begin
                  RegistrarErro(vLinha, '', teGravacao, '', E.Message);
                  vErroNaLinha := True;
                end;
              end;
          end;

          if vErroNaLinha then
          begin
            Inc(vResumo.ComErro);
            if FPerfil.AcaoErro = aeParar then
            begin
              vResumo.Status := seInterrompida;
              vResumo.Mensagem := Format('Parou na linha %d por causa de um erro.', [vLinha]);
              Break;
            end;
            if FPerfil.AcaoErro = aeDesfazerTudo then
            begin
              vResumo.Status := seDesfeita;
              vResumo.Mensagem := Format('Erro na linha %d: tudo foi desfeito.', [vLinha]);
              Break;
            end;
          end;
        end;

        // Commit por lote (exceto em "desfazer tudo", que é uma transação só)
        if vGravar and not vTudoOuNada and (vNoLote >= cTAMANHO_LOTE) then
        begin
          FDmDestino.ConfirmarTransacao;
          FDmDestino.IniciarTransacao;
          vResumo.UltimaLinhaGravada := vLinha;
          vNoLote := 0;
          AtualizarExecucao(vResumo, False);
        end;

        if Assigned(AProgresso) and (((vLinha - FLeitor.LinhaInicial) mod cINTERVALO_PROGRESSO = 0) or
          (vLinha = vResumo.UltimaLinhaPlanilha)) then
        begin
          AProgresso(vResumo, vCancelar);
          if vCancelar then
          begin
            vResumo.Status := seCancelada;
            vResumo.Mensagem := Format('Cancelada pelo usuário na linha %d.', [vLinha]);
            Break;
          end;
        end;
        Inc(vLinha);
      end;

      // Fecha a transação do destino conforme o resultado
      if vGravar then
      begin
        if (vResumo.Status = seDesfeita) or ((vResumo.Status = seCancelada) and vTudoOuNada) then
        begin
          FDmDestino.DesfazerTransacao;
          vResumo.Mensagem := vResumo.Mensagem + Format(' Nada foi gravado (%d inserções e %d atualizações desfeitas).',
            [vResumo.Inseridas, vResumo.Atualizadas]);
          vResumo.Inseridas := 0;
          vResumo.Atualizadas := 0;
          vResumo.UltimaLinhaGravada := vPontoAnterior;
        end
        else
        begin
          FDmDestino.ConfirmarTransacao;
          case vResumo.Status of
            seInterrompida:
              vResumo.UltimaLinhaGravada := vResumo.LinhaAtual - 1;  // a linha com erro fica para depois
            seCancelada:
              vResumo.UltimaLinhaGravada := vResumo.LinhaAtual;
          else
            vResumo.UltimaLinhaGravada := vResumo.UltimaLinhaPlanilha;
          end;
        end;
      end;

      if vResumo.Status = seEmAndamento then
      begin
        if vResumo.ComErro = 0 then
          vResumo.Status := seConcluida
        else
          vResumo.Status := seConcluidaComErros;
      end;
    except
      on E: Exception do
      begin
        // Falha geral (ex.: conexão caiu): perde só o que não foi confirmado
        FDmDestino.DesfazerTransacao;
        vResumo.Status := seFalhou;
        vResumo.Mensagem := Format('Falha na linha %d: %s. Gravação confirmada até a linha %d; os contadores ' +
          'incluem linhas do último lote, que foram desfeitas.', [vResumo.LinhaAtual, E.Message,
          vResumo.UltimaLinhaGravada]);
      end;
    end;

    if vResumo.Mensagem = '' then
      vResumo.Mensagem := cSTATUS_EXECUCAO[vResumo.Status].Nome + '.';
    AtualizarExecucao(vResumo, True);
    AErros := vErros.ToArray;
    Result := vResumo;
  finally
    vResolvedor.Free;
    vConsultas.Free;
    vQryErro.Free;
    vErros.Free;
  end;
end;

end.
