unit uImportador;

{ Núcleo da importação (sem tela): resolve o valor final de cada campo numa linha da planilha e valida o perfil.
  Ordem para cada campo (sem precedência implícita):
    1. valor de origem: coluna / valor fixo / expressão
       - ovPadrao: coluna inexistente ou vazia -> valor padrão, só se a condição estiver marcada
         ("vazia" vale também para o valor que fica vazio depois das transformações)
    2. transformações do campo, em ordem (tratam o valor da planilha, do fixo ou da expressão)
       - ovPadrao com "inválido" marcado: se a transformação falhar, usa o padrão
       - o valor padrão é o valor final: NÃO passa pelas transformações
    3. conversão para o tipo do campo de destino (ConverterParaDestino): nunca silenciosa;
       só o texto digitado no perfil (valor fixo/padrão) é convertido automaticamente para o tipo do campo. }

interface

uses
  System.SysUtils, System.Variants, System.Math, System.DateUtils, System.Generics.Collections, uPerfilModelo,
  uTransformacoes, uDmDestino;

type
  // De onde veio o valor final
  TFonteValor = (fvNenhuma, fvColuna, fvFixo, fvPadrao, fvConsulta, fvGerado, fvExpressao);

  TTipoErro = (teNenhum, teValidacao, teTransformacao, teReferencia, teGravacao);

  TValorResolvido = record
    Campo: string;
    Fonte: TFonteValor;
    ValorRecebido: string;  // valor de origem como texto, antes das transformações
    Valor: Variant;         // valor final, já no tipo do campo de destino (Null = nulo)
    TipoErro: TTipoErro;
    Mensagem: string;       // erro (TipoErro <> teNenhum) ou observação
    function Ok: Boolean;
  end;

  TResultadoLinha = record
    Linha: Integer;         // linha da planilha (como no Excel)
    Valores: TArray<TValorResolvido>;
    function Valida: Boolean;
    function QuantidadeErros: Integer;
  end;

  // Lê uma coluna da linha atual. False = a coluna não existe na planilha
  TObterCelula = reference to function(const AColuna: string; out AValor: Variant; out ATexto: string): Boolean;

  // Origem "Consulta": procura AValor em ATabela.ACampoPesquisa e devolve ACampoRetorno em ARetorno.
  // Resultado: -1 = erro (AMensagem), 0 = não achou, 1 = achou, 2 = achou mais de um
  TConsultarReferencia = reference to function(const ATabela, ACampoPesquisa, ACampoRetorno: string;
    const AValor: Variant; out ARetorno: Variant; out AMensagem: string): Integer;

  // Origem "Consulta SQL": executa ASql (já com :P0, :P1...) com AValores. Mesmos códigos de TConsultarReferencia
  TConsultarSql = reference to function(const ASql: string; const AValores: TArray<Variant>; out ARetorno: Variant;
    out AMensagem: string): Integer;

  // Consultas ao banco de destino para a origem "Consulta", com cache dos valores encontrados.
  // Uma instância por execução (pré-visualização, importação ou tela de perfil): o cache não deve durar mais que isso.
  // "Não encontrado" não vai para o cache: o registro pode ser inserido pela própria importação.
  TConsultaReferencias = class
  private
    FDestino: TdmDestino;
    FCamposPorTabela: TDictionary<string, TArray<TCampoDestino>>;
    FEncontrados: TDictionary<string, Variant>;
    FConsultasAoBanco: Integer;
    FUsosDoCache: Integer;
    function CampoDaTabela(const ATabela, ACampo: string; out ADefinicao: TCampoDestino): Boolean;
  public
    constructor Create(ADestino: TdmDestino);
    destructor Destroy; override;
    function Consultar(const ATabela, ACampoPesquisa, ACampoRetorno: string; const AValor: Variant;
      out ARetorno: Variant; out AMensagem: string): Integer;
    function ConsultarSql(const ASql: string; const AValores: TArray<Variant>; out ARetorno: Variant;
      out AMensagem: string): Integer;
    property ConsultasAoBanco: Integer read FConsultasAoBanco;
    property UsosDoCache: Integer read FUsosDoCache;
  end;

  TGravidade = (gvErro, gvAviso);

  TProblemaPerfil = record
    Gravidade: TGravidade;
    Campo: string;
    Mensagem: string;
  end;

  // Resolve as linhas de um perfil: guarda os campos mapeados e o campo de destino de cada um
  TResolvedorValores = class
  private
    FCampos: TArray<TCampoPerfil>;
    FDestinos: TArray<TCampoDestino>;
    FTemDestino: TArray<Boolean>;
    FConsultar: TConsultarReferencia;
    FConsultarSql: TConsultarSql;
  public
    constructor Create(APerfil: TPerfil; const ACamposDestino: TArray<TCampoDestino>);
    function ResolverLinha(ALinha: Integer; AObterCelula: TObterCelula): TResultadoLinha;
    property Campos: TArray<TCampoPerfil> read FCampos;
    property Destinos: TArray<TCampoDestino> read FDestinos;   // mesma ordem de Campos
    // Sem consulta (nil), a origem "Consulta" devolve só o valor de pesquisa, com um aviso
    property Consultar: TConsultarReferencia read FConsultar write FConsultar;
    property ConsultarSql: TConsultarSql read FConsultarSql write FConsultarSql;
  end;

const
  cFONTES: array[TFonteValor] of string = ('', 'Planilha', 'Valor fixo', 'Valor padrão', 'Consulta', 'Gerado',
    'Expressão');
  cTIPOS_ERRO: array[TTipoErro] of string = ('', 'Validação', 'Transformação', 'Referência', 'Gravação');
  cGRAVIDADES: array[TGravidade] of string = ('Erro', 'Aviso');

  cTAMANHO_LOTE = 200;   // linhas gravadas por commit na importação

function ResolverCampo(ACampo: TCampoPerfil; const ADestino: TCampoDestino; ATemDestino: Boolean;
  AObterCelula: TObterCelula; AConsultar: TConsultarReferencia = nil;
  AConsultarSql: TConsultarSql = nil): TValorResolvido;

// Troca {Coluna} e {valor} do SELECT manual por :P0, :P1... e devolve os nomes na ordem dos parâmetros
function MontarSqlManual(const ASql: string; out ASqlFinal: string): TArray<string>;

// Confere e converte o valor para o campo de destino. AValorConfigurado = texto digitado no perfil
// (valor fixo/padrão), que pode ser convertido para o tipo do campo; valores da planilha não são.
function ConverterParaDestino(const AValor: Variant; const ACampo: TCampoDestino; AValorConfigurado: Boolean;
  out AResultado: Variant; out AMensagem: string): Boolean;

// Problemas do perfil que dá para ver sem ler as linhas: campos, colunas, generators, tabelas, valores fixos...
// APlanilhaCarregada = False pula a conferência das colunas. ACamposDaTabela (opcional) devolve os campos de
// uma tabela do destino, para conferir os campos de pesquisa e retorno das consultas.
function ValidarPerfil(APerfil: TPerfil; ATabelaExiste: Boolean; const ACamposDestino: TArray<TCampoDestino>;
  APlanilhaCarregada: Boolean; const AColunas, AGenerators, ATabelas: TArray<string>;
  ACamposDaTabela: TFunc<string, TArray<TCampoDestino>> = nil;
  ATestarSql: TFunc<string, string> = nil): TArray<TProblemaPerfil>;

implementation

function Contem(const ALista: TArray<string>; const AValor: string): Boolean;
var
  vItem: string;
begin
  for vItem in ALista do
    if SameText(Trim(vItem), Trim(AValor)) then
      Exit(True);
  Result := False;
end;

{ TValorResolvido }

function TValorResolvido.Ok: Boolean;
begin
  Result := TipoErro = teNenhum;
end;

{ TResultadoLinha }

function TResultadoLinha.QuantidadeErros: Integer;
var
  vValor: TValorResolvido;
begin
  Result := 0;
  for vValor in Valores do
    if not vValor.Ok then
      Inc(Result);
end;

function TResultadoLinha.Valida: Boolean;
begin
  Result := QuantidadeErros = 0;
end;

{ Conversão para o destino }

function ConverterParaDestino(const AValor: Variant; const ACampo: TCampoDestino; AValorConfigurado: Boolean;
  out AResultado: Variant; out AMensagem: string): Boolean;
var
  vValor: Variant;
  vConvertido: TResultadoTransformacao;
  vNumero, vEscalado: Double;
  vTexto: string;
  vTipo: string;
begin
  Result := False;
  AResultado := Null;
  AMensagem := '';
  vValor := AValor;

  if EhVazio(vValor) then
  begin
    if ACampo.Obrigatorio and (ACampo.Padrao = '') then
    begin
      AMensagem := 'campo obrigatório sem valor';
      Exit;
    end;
    Exit(True);
  end;

  // Texto digitado no perfil (ex.: valor fixo "1" num campo INTEGER) vira o tipo do campo
  if AValorConfigurado and EhTexto(vValor) then
  begin
    vConvertido.Sucesso := True;
    vConvertido.Valor := vValor;
    case ACampo.Categoria of
      ccInteiro:
        vConvertido := Transformar(ttTextoParaInteiro, vValor, '');
      ccDecimal:
        vConvertido := Transformar(ttTextoParaDecimal, vValor, 'BR');
      ccData:
        vConvertido := Transformar(ttTextoParaData, vValor, '');
      ccDataHora:
        vConvertido := Transformar(ttTextoParaDataHora, vValor, '');
      ccBooleano:
        begin
          vConvertido := Transformar(ttTextoParaBooleano, vValor, 'S/N');
          if vConvertido.Sucesso then
            vConvertido.Valor := VarToStr(vConvertido.Valor) = 'S';
        end;
    end;
    if not vConvertido.Sucesso then
    begin
      AMensagem := 'valor configurado incompatível com ' + ACampo.TipoSql + ': ' + vConvertido.Mensagem;
      Exit;
    end;
    vValor := vConvertido.Valor;
  end;

  case ACampo.Categoria of
    ccTexto, ccTextoLongo:
      begin
        if EhTexto(vValor) then
          vTexto := VarToStr(vValor)
        else
          vTexto := ValorParaTexto(vValor);
        if (ACampo.Categoria = ccTexto) and (ACampo.Tamanho > 0) and (Length(vTexto) > ACampo.Tamanho) then
        begin
          AMensagem := Format('"%s" tem %d caracteres; o campo %s aceita no máximo %d',
            [vTexto, Length(vTexto), ACampo.TipoSql, ACampo.Tamanho]);
          Exit;
        end;
        AResultado := vTexto;
      end;

    ccInteiro:
      begin
        if not EhNumero(vValor) then
        begin
          AMensagem := Format('"%s" não é um número; o campo %s precisa de uma transformação de conversão ' +
            '(ex.: Texto para inteiro)', [ValorParaTexto(vValor), ACampo.TipoSql]);
          Exit;
        end;
        vNumero := vValor;
        if Frac(vNumero) <> 0 then
        begin
          AMensagem := Format('"%s" tem casas decimais; o campo %s só aceita inteiros',
            [ValorParaTexto(vValor), ACampo.TipoSql]);
          Exit;
        end;
        vTipo := UpperCase(ACampo.TipoSql);
        if ((vTipo = 'SMALLINT') and ((vNumero < -32768) or (vNumero > 32767))) or
          ((vTipo = 'INTEGER') and ((vNumero < -2147483648.0) or (vNumero > 2147483647.0))) or
          (Abs(vNumero) > 9.2E18) then
        begin
          AMensagem := Format('"%s" está fora da faixa do campo %s', [ValorParaTexto(vValor), ACampo.TipoSql]);
          Exit;
        end;
        AResultado := Trunc(vNumero);
      end;

    ccDecimal:
      begin
        if not EhNumero(vValor) then
        begin
          AMensagem := Format('"%s" não é um número; o campo %s precisa de uma transformação de conversão ' +
            '(ex.: Texto para decimal)', [ValorParaTexto(vValor), ACampo.TipoSql]);
          Exit;
        end;
        vNumero := vValor;
        vTipo := UpperCase(ACampo.TipoSql);
        if vTipo.StartsWith('NUMERIC') or vTipo.StartsWith('DECIMAL') then
        begin
          // Mais casas que o campo guarda mudaria o valor ao gravar: o perfil precisa arredondar
          vEscalado := vNumero * IntPower(10, ACampo.Escala);
          if Abs(vEscalado - Round(vEscalado)) > 0.000001 then
          begin
            AMensagem := Format('"%s" tem mais de %d casas decimais (%s); use a transformação Arredondar',
              [ValorParaTexto(vValor), ACampo.Escala, ACampo.TipoSql]);
            Exit;
          end;
          if (ACampo.Tamanho > 0) and (Abs(vNumero) >= IntPower(10, ACampo.Tamanho - ACampo.Escala)) then
          begin
            AMensagem := Format('"%s" é grande demais para o campo %s', [ValorParaTexto(vValor), ACampo.TipoSql]);
            Exit;
          end;
          vNumero := Round(vEscalado) / IntPower(10, ACampo.Escala);
        end;
        AResultado := vNumero;
      end;

    ccData:
      begin
        if not EhData(vValor) then
        begin
          AMensagem := Format('"%s" não é uma data; o campo %s precisa de uma transformação de conversão ' +
            '(ex.: Texto para data)', [ValorParaTexto(vValor), ACampo.TipoSql]);
          Exit;
        end;
        if TimeOf(vValor) <> 0 then
        begin
          AMensagem := Format('"%s" tem hora; o campo %s guarda só a data', [ValorParaTexto(vValor), ACampo.TipoSql]);
          Exit;
        end;
        AResultado := VarFromDateTime(DateOf(vValor));
      end;

    ccDataHora:
      begin
        if not EhData(vValor) then
        begin
          AMensagem := Format('"%s" não é uma data; o campo %s precisa de uma transformação de conversão ' +
            '(ex.: Texto para data e hora)', [ValorParaTexto(vValor), ACampo.TipoSql]);
          Exit;
        end;
        AResultado := VarFromDateTime(vValor);
      end;

    ccHora:
      begin
        if not EhData(vValor) then
        begin
          AMensagem := Format('"%s" não é uma hora (campo %s)', [ValorParaTexto(vValor), ACampo.TipoSql]);
          Exit;
        end;
        AResultado := VarFromDateTime(TimeOf(vValor));
      end;

    ccBooleano:
      begin
        if (VarType(vValor) and varTypeMask) <> varBoolean then
        begin
          AMensagem := Format('"%s" não é verdadeiro/falso (campo %s)', [ValorParaTexto(vValor), ACampo.TipoSql]);
          Exit;
        end;
        AResultado := vValor;
      end;
  else
    AMensagem := 'tipo de campo não suportado na importação: ' + ACampo.TipoSql;
    Exit;
  end;

  Result := True;
end;

{ Resolução de um campo }

function ResolverCampo(ACampo: TCampoPerfil; const ADestino: TCampoDestino; ATemDestino: Boolean;
  AObterCelula: TObterCelula; AConsultar: TConsultarReferencia; AConsultarSql: TConsultarSql): TValorResolvido;
var
  vValor: Variant;
  vTexto, vMensagem, vErroOriginal: string;
  vExiste: Boolean;
  vObterColuna: TObterValorColuna;
  vTransformado, vExpressao: TResultadoTransformacao;
  vFinal, vRetorno: Variant;
  vNomesParametros: TArray<string>;
  vParametros: TArray<Variant>;
  vSqlFinal, vDescricao: string;
  i: Integer;

  procedure Falhar(ATipo: TTipoErro; const AMensagem: string);
  begin
    Result.TipoErro := ATipo;
    Result.Mensagem := AMensagem;
    Result.Valor := Null;
  end;

begin
  Result.Campo := ACampo.CampoDestino;
  Result.Fonte := fvNenhuma;
  Result.ValorRecebido := '';
  Result.Valor := Null;
  Result.TipoErro := teNenhum;
  Result.Mensagem := '';
  vValor := Null;

  // Concatenar/expressão leem outras colunas da mesma linha
  vObterColuna :=
    function(const ANomeColuna: string; out AValor: Variant): Boolean
    var
      vTextoColuna: string;
    begin
      Result := Assigned(AObterCelula) and AObterCelula(ANomeColuna, AValor, vTextoColuna);
    end;

  if not ATemDestino then
  begin
    Falhar(teValidacao, 'o campo não existe na tabela de destino');
    Exit;
  end;

  // 1. Valor de origem
  case ACampo.Origem of
    ovNaoImportar:
      Exit;

    ovGerado:
      begin
        Result.Fonte := fvGerado;
        Result.Mensagem := 'gerado pelo ' + ACampo.Generator + ' ao gravar';
        Exit;
      end;

    ovFixo:
      begin
        Result.Fonte := fvFixo;
        vValor := ACampo.ValorFixo;
        Result.ValorRecebido := ACampo.ValorFixo;
      end;

    ovExpressao:
      begin
        Result.Fonte := fvExpressao;
        vExpressao := Transformar(ttConcatenar, Null, ACampo.Expressao, vObterColuna);
        if not vExpressao.Sucesso then
        begin
          Falhar(teTransformacao, 'Expressão: ' + vExpressao.Mensagem);
          Exit;
        end;
        vValor := vExpressao.Valor;
        Result.ValorRecebido := VarToStr(vValor);
      end;

    ovConsultaSql:
      begin
        // A coluna é opcional: só fornece o {valor} da consulta
        Result.Fonte := fvConsulta;
        if Trim(ACampo.Coluna) <> '' then
        begin
          if not (Assigned(AObterCelula) and AObterCelula(ACampo.Coluna, vValor, vTexto)) then
          begin
            Falhar(teValidacao, Format('a coluna "%s" não existe na planilha', [ACampo.Coluna]));
            Exit;
          end;
          Result.ValorRecebido := vTexto;
          if EhVazio(vValor) then
            vValor := Null;
        end;
      end;

    ovColuna, ovPadrao, ovConsulta:
      begin
        if ACampo.Origem = ovConsulta then
          Result.Fonte := fvConsulta
        else
          Result.Fonte := fvColuna;

        vExiste := Assigned(AObterCelula) and AObterCelula(ACampo.Coluna, vValor, vTexto);
        if not vExiste then
        begin
          if (ACampo.Origem = ovPadrao) and ACampo.PadraoSeInexistente then
          begin
            Result.Fonte := fvPadrao;
            Result.ValorRecebido := '(coluna não existe)';
            vValor := ACampo.ValorPadrao;
          end
          else
          begin
            Falhar(teValidacao, Format('a coluna "%s" não existe na planilha', [ACampo.Coluna]));
            Exit;
          end;
        end
        else
        begin
          Result.ValorRecebido := vTexto;
          if EhVazio(vValor) then
          begin
            vValor := Null;
            if (ACampo.Origem = ovPadrao) and ACampo.PadraoSeVazio then
            begin
              Result.Fonte := fvPadrao;
              vValor := ACampo.ValorPadrao;
            end;
          end;
        end;
      end;
  end;

  // 2. Transformações (o valor padrão já é o valor final e não passa por elas)
  if Result.Fonte <> fvPadrao then
  begin
    vTransformado := AplicarTransformacoes(ACampo.Transformacoes, vValor, vObterColuna);
    if vTransformado.Sucesso then
      vValor := vTransformado.Valor
    else if (ACampo.Origem = ovPadrao) and ACampo.PadraoSeInvalido then
    begin
      vErroOriginal := vTransformado.Mensagem;
      Result.Fonte := fvPadrao;
      Result.Mensagem := 'valor inválido trocado pelo padrão (' + vErroOriginal + ')';
      vValor := ACampo.ValorPadrao;
    end
    else
    begin
      Falhar(teTransformacao, vTransformado.Mensagem);
      Exit;
    end;

    // Vazio depois das transformações (ex.: telefone 00 0000-0000) também conta como "vazio"
    if (Result.Fonte <> fvPadrao) and (ACampo.Origem = ovPadrao) and ACampo.PadraoSeVazio and EhVazio(vValor) then
    begin
      Result.Fonte := fvPadrao;
      Result.Mensagem := 'vazio depois das transformações: usado o padrão';
      vValor := ACampo.ValorPadrao;
    end;
  end;

  // Consulta: o valor acima é a chave de pesquisa; o valor do campo é o retorno do registro achado
  if ACampo.Origem = ovConsulta then
  begin
    if not Assigned(AConsultar) then
    begin
      // Sem acesso ao banco (ex.: tela sem conexão): mostra só a chave de pesquisa
      Result.Valor := vValor;
      Result.Mensagem := Format('valor de pesquisa em %s.%s (sem consulta ao banco aqui)',
        [ACampo.ConsultaTabela, ACampo.ConsultaCampoPesquisa]);
      Exit;
    end;

    if not EhVazio(vValor) then
    begin
      case AConsultar(ACampo.ConsultaTabela, ACampo.ConsultaCampoPesquisa, ACampo.ConsultaCampoRetorno, vValor,
        vRetorno, vMensagem) of
        1:
          begin
            Result.Mensagem := Format('encontrado em %s.%s = %s', [ACampo.ConsultaTabela,
              ACampo.ConsultaCampoPesquisa, ValorParaTexto(vValor)]);
            vValor := vRetorno;
          end;
        0:
          if ACampo.ConsultaSeNaoAchar = aneNulo then
          begin
            Result.Mensagem := Format('não encontrado em %s.%s = %s: gravado nulo', [ACampo.ConsultaTabela,
              ACampo.ConsultaCampoPesquisa, ValorParaTexto(vValor)]);
            vValor := Null;
          end
          else
          begin
            Falhar(teReferencia, Format('não encontrado em %s.%s = "%s"', [ACampo.ConsultaTabela,
              ACampo.ConsultaCampoPesquisa, ValorParaTexto(vValor)]));
            Exit;
          end;
        2:
          begin
            Falhar(teReferencia, Format('mais de um registro em %s com %s = "%s"', [ACampo.ConsultaTabela,
              ACampo.ConsultaCampoPesquisa, ValorParaTexto(vValor)]));
            Exit;
          end;
      else
        Falhar(teReferencia, vMensagem);
        Exit;
      end;
    end;
  end;

  // Consulta SQL manual: {Coluna} e {valor} viram parâmetros; o campo recebe a 1ª coluna da 1ª linha
  if ACampo.Origem = ovConsultaSql then
  begin
    vNomesParametros := MontarSqlManual(ACampo.ConsultaSql, vSqlFinal);
    SetLength(vParametros, Length(vNomesParametros));
    vDescricao := '';
    for i := 0 to High(vNomesParametros) do
    begin
      if SameText(vNomesParametros[i], 'valor') then
        vParametros[i] := vValor
      else if not (Assigned(AObterCelula) and AObterCelula(vNomesParametros[i], vParametros[i], vTexto)) then
      begin
        Falhar(teValidacao, Format('a coluna "%s" usada na consulta SQL não existe na planilha',
          [vNomesParametros[i]]));
        Exit;
      end
      else if EhVazio(vParametros[i]) then
        vParametros[i] := Null;
      if vDescricao <> '' then
        vDescricao := vDescricao + ', ';
      vDescricao := vDescricao + vNomesParametros[i] + ' = ' + ValorParaTexto(vParametros[i]);
    end;

    if not Assigned(AConsultarSql) then
    begin
      Result.Valor := vValor;
      Result.Mensagem := 'consulta SQL com ' + vDescricao + ' (sem consulta ao banco aqui)';
      Exit;
    end;

    case AConsultarSql(vSqlFinal, vParametros, vRetorno, vMensagem) of
      1:
        begin
          Result.Mensagem := 'encontrado pela consulta SQL com ' + vDescricao;
          vValor := vRetorno;
        end;
      0:
        if ACampo.ConsultaSeNaoAchar = aneNulo then
        begin
          Result.Mensagem := 'a consulta SQL não achou nada com ' + vDescricao + ': gravado nulo';
          vValor := Null;
        end
        else
        begin
          Falhar(teReferencia, 'a consulta SQL não achou nada com ' + vDescricao);
          Exit;
        end;
      2:
        begin
          Falhar(teReferencia, 'a consulta SQL achou mais de uma linha com ' + vDescricao);
          Exit;
        end;
    else
      Falhar(teReferencia, 'consulta SQL: ' + vMensagem);
      Exit;
    end;
  end;

  // 3. Tipo do campo de destino
  if not ConverterParaDestino(vValor, ADestino, Result.Fonte in [fvFixo, fvPadrao], vFinal, vMensagem) then
  begin
    if Result.Fonte = fvPadrao then
      vMensagem := 'valor padrão: ' + vMensagem;
    Falhar(teValidacao, vMensagem);
    Exit;
  end;
  Result.Valor := vFinal;
end;

{ TResolvedorValores }

constructor TResolvedorValores.Create(APerfil: TPerfil; const ACamposDestino: TArray<TCampoDestino>);
var
  vCampo: TCampoPerfil;
  vDestino: TCampoDestino;
  i: Integer;
begin
  inherited Create;
  FCampos := APerfil.CamposMapeados;
  SetLength(FDestinos, Length(FCampos));
  SetLength(FTemDestino, Length(FCampos));
  for i := 0 to High(FCampos) do
  begin
    vCampo := FCampos[i];
    FTemDestino[i] := False;
    FDestinos[i] := Default(TCampoDestino);
    for vDestino in ACamposDestino do
      if SameText(vDestino.Nome, vCampo.CampoDestino) then
      begin
        FDestinos[i] := vDestino;
        FTemDestino[i] := True;
        Break;
      end;
  end;
end;

function TResolvedorValores.ResolverLinha(ALinha: Integer; AObterCelula: TObterCelula): TResultadoLinha;
var
  i: Integer;
begin
  Result.Linha := ALinha;
  SetLength(Result.Valores, Length(FCampos));
  for i := 0 to High(FCampos) do
    Result.Valores[i] := ResolverCampo(FCampos[i], FDestinos[i], FTemDestino[i], AObterCelula, FConsultar,
      FConsultarSql);
end;

{ Consulta SQL manual }

function MontarSqlManual(const ASql: string; out ASqlFinal: string): TArray<string>;
var
  vInicio, vFim, vPosicao: Integer;
begin
  Result := nil;
  ASqlFinal := '';
  vPosicao := 1;
  vInicio := Pos('{', ASql);
  while vInicio > 0 do
  begin
    vFim := Pos('}', ASql, vInicio + 1);
    if vFim = 0 then
      Break;
    ASqlFinal := ASqlFinal + Copy(ASql, vPosicao, vInicio - vPosicao) + ':P' + IntToStr(Length(Result));
    Result := Result + [Trim(Copy(ASql, vInicio + 1, vFim - vInicio - 1))];
    vPosicao := vFim + 1;
    vInicio := Pos('{', ASql, vPosicao);
  end;
  ASqlFinal := ASqlFinal + Copy(ASql, vPosicao, MaxInt);
end;

{ TConsultaReferencias }

constructor TConsultaReferencias.Create(ADestino: TdmDestino);
begin
  inherited Create;
  FDestino := ADestino;
  FCamposPorTabela := TDictionary<string, TArray<TCampoDestino>>.Create;
  FEncontrados := TDictionary<string, Variant>.Create;
end;

destructor TConsultaReferencias.Destroy;
begin
  FEncontrados.Free;
  FCamposPorTabela.Free;
  inherited;
end;

function TConsultaReferencias.CampoDaTabela(const ATabela, ACampo: string; out ADefinicao: TCampoDestino): Boolean;
var
  vCampos: TArray<TCampoDestino>;
  vCampo: TCampoDestino;
begin
  // Metadados de cada tabela consultada são lidos uma vez só
  if not FCamposPorTabela.TryGetValue(UpperCase(ATabela), vCampos) then
  begin
    vCampos := FDestino.Campos(ATabela);
    FCamposPorTabela.Add(UpperCase(ATabela), vCampos);
  end;
  for vCampo in vCampos do
    if SameText(vCampo.Nome, ACampo) then
    begin
      ADefinicao := vCampo;
      Exit(True);
    end;
  ADefinicao := Default(TCampoDestino);
  Result := False;
end;

function TConsultaReferencias.Consultar(const ATabela, ACampoPesquisa, ACampoRetorno: string;
  const AValor: Variant; out ARetorno: Variant; out AMensagem: string): Integer;
var
  vPesquisa, vRetorno: TCampoDestino;
  vValorPesquisa: Variant;
  vChave, vMensagem: string;
begin
  ARetorno := Null;
  AMensagem := '';
  try
    if not CampoDaTabela(ATabela, ACampoPesquisa, vPesquisa) then
    begin
      AMensagem := Format('o campo de pesquisa %s não existe na tabela %s', [ACampoPesquisa, ATabela]);
      Exit(-1);
    end;
    if not CampoDaTabela(ATabela, ACampoRetorno, vRetorno) then
    begin
      AMensagem := Format('o campo de retorno %s não existe na tabela %s', [ACampoRetorno, ATabela]);
      Exit(-1);
    end;

    // O valor de pesquisa precisa servir para o campo pesquisado (sem conversão silenciosa)
    vPesquisa.Obrigatorio := False;
    if not ConverterParaDestino(AValor, vPesquisa, False, vValorPesquisa, vMensagem) then
    begin
      AMensagem := Format('valor de pesquisa incompatível com %s.%s: %s', [ATabela, ACampoPesquisa, vMensagem]);
      Exit(-1);
    end;

    vChave := UpperCase(ATabela + '|' + ACampoPesquisa + '|' + ACampoRetorno) + '|' + ValorParaTexto(vValorPesquisa);
    if FEncontrados.TryGetValue(vChave, ARetorno) then
    begin
      Inc(FUsosDoCache);
      Exit(1);
    end;

    Inc(FConsultasAoBanco);
    Result := FDestino.ConsultarValor(ATabela, vPesquisa, ACampoRetorno, vValorPesquisa, ARetorno);
    if Result = 1 then
      FEncontrados.Add(vChave, ARetorno);
  except
    on E: Exception do
    begin
      AMensagem := 'falha ao consultar ' + ATabela + ': ' + E.Message;
      Result := -1;
    end;
  end;
end;

function TConsultaReferencias.ConsultarSql(const ASql: string; const AValores: TArray<Variant>;
  out ARetorno: Variant; out AMensagem: string): Integer;
var
  vChave: string;
  vValor: Variant;
begin
  ARetorno := Null;
  AMensagem := '';
  try
    // Cache pelo SQL + valores dos parâmetros (só o que foi encontrado, como na consulta simples)
    vChave := 'SQL|' + ASql;
    for vValor in AValores do
      vChave := vChave + '|' + VarToStr(vValor);
    if FEncontrados.TryGetValue(vChave, ARetorno) then
    begin
      Inc(FUsosDoCache);
      Exit(1);
    end;

    Inc(FConsultasAoBanco);
    Result := FDestino.ConsultarSql(ASql, AValores, ARetorno);
    if Result = 1 then
      FEncontrados.Add(vChave, ARetorno);
  except
    on E: Exception do
    begin
      AMensagem := E.Message;
      Result := -1;
    end;
  end;
end;

{ Validação do perfil }

function AcharCampo(const ACampos: TArray<TCampoDestino>; const ANome: string; out ACampo: TCampoDestino): Boolean;
var
  vCampo: TCampoDestino;
begin
  for vCampo in ACampos do
    if SameText(vCampo.Nome, Trim(ANome)) then
    begin
      ACampo := vCampo;
      Exit(True);
    end;
  ACampo := Default(TCampoDestino);
  Result := False;
end;

function ValidarPerfil(APerfil: TPerfil; ATabelaExiste: Boolean; const ACamposDestino: TArray<TCampoDestino>;
  APlanilhaCarregada: Boolean; const AColunas, AGenerators, ATabelas: TArray<string>;
  ACamposDaTabela: TFunc<string, TArray<TCampoDestino>>; ATestarSql: TFunc<string, string>): TArray<TProblemaPerfil>;
var
  vProblemas: TArray<TProblemaPerfil>;

  procedure Adicionar(AGravidade: TGravidade; const ACampo, AMensagem: string);
  var
    vProblema: TProblemaPerfil;
  begin
    vProblema.Gravidade := AGravidade;
    vProblema.Campo := ACampo;
    vProblema.Mensagem := AMensagem;
    vProblemas := vProblemas + [vProblema];
  end;

var
  vCampo: TCampoPerfil;
  vDestino, vItem: TCampoDestino;
  vCamposConsulta: TArray<TCampoDestino>;
  vTemDestino: Boolean;
  vColuna, vMensagem, vSqlFinal: string;
  vResolvido: TValorResolvido;
  vFinal: Variant;
  vSemColunas: TObterCelula;
begin
  vProblemas := nil;
  vSemColunas :=
    function(const AColuna: string; out AValor: Variant; out ATexto: string): Boolean
    begin
      AValor := Null;
      ATexto := '';
      Result := False;
    end;

  if not ATabelaExiste then
  begin
    Adicionar(gvErro, '', Format('A tabela de destino %s não existe no banco.', [APerfil.TabelaDestino]));
    Exit(vProblemas);
  end;
  if Length(APerfil.CamposMapeados) = 0 then
    Adicionar(gvErro, '', 'Nenhum campo mapeado.');

  for vCampo in APerfil.CamposMapeados do
  begin
    vTemDestino := False;
    vDestino := Default(TCampoDestino);
    for vItem in ACamposDestino do
      if SameText(vItem.Nome, vCampo.CampoDestino) then
      begin
        vDestino := vItem;
        vTemDestino := True;
        Break;
      end;
    if not vTemDestino then
    begin
      Adicionar(gvErro, vCampo.CampoDestino, 'O campo não existe na tabela de destino.');
      Continue;
    end;

    if vDestino.Calculado then
      Adicionar(gvErro, vCampo.CampoDestino, 'Campo calculado (COMPUTED BY) não pode ser gravado.');

    if not vCampo.ValidarConfiguracao(vMensagem) then
    begin
      Adicionar(gvErro, vCampo.CampoDestino, cORIGENS[vCampo.Origem].Nome + ': ' + vMensagem + '.');
      Continue;
    end;

    if APlanilhaCarregada then
      for vColuna in vCampo.ColunasUsadas do
        if not Contem(AColunas, vColuna) then
        begin
          if (vCampo.Origem = ovPadrao) and vCampo.PadraoSeInexistente and SameText(vColuna, vCampo.Coluna) then
            Adicionar(gvAviso, vCampo.CampoDestino,
              Format('A coluna "%s" não existe na planilha: todas as linhas vão receber o valor padrão.', [vColuna]))
          else
            Adicionar(gvErro, vCampo.CampoDestino, Format('A coluna "%s" não existe na planilha.', [vColuna]));
        end;

    case vCampo.Origem of
      ovGerado:
        begin
          if not Contem(AGenerators, vCampo.Generator) then
            Adicionar(gvErro, vCampo.CampoDestino, Format('O generator %s não existe no banco.', [vCampo.Generator]));
          if vDestino.Categoria <> ccInteiro then
            Adicionar(gvErro, vCampo.CampoDestino,
              Format('Valor gerado só pode ir para campo inteiro (o campo é %s).', [vDestino.TipoSql]));
        end;

      ovConsulta:
        if not Contem(ATabelas, vCampo.ConsultaTabela) then
          Adicionar(gvErro, vCampo.CampoDestino,
            Format('A tabela de consulta %s não existe no banco.', [vCampo.ConsultaTabela]))
        else if Assigned(ACamposDaTabela) then
        begin
          vCamposConsulta := ACamposDaTabela(vCampo.ConsultaTabela);
          if not AcharCampo(vCamposConsulta, vCampo.ConsultaCampoPesquisa, vItem) then
            Adicionar(gvErro, vCampo.CampoDestino, Format('O campo de pesquisa %s não existe na tabela %s.',
              [vCampo.ConsultaCampoPesquisa, vCampo.ConsultaTabela]));
          if not AcharCampo(vCamposConsulta, vCampo.ConsultaCampoRetorno, vItem) then
            Adicionar(gvErro, vCampo.CampoDestino, Format('O campo de retorno %s não existe na tabela %s.',
              [vCampo.ConsultaCampoRetorno, vCampo.ConsultaTabela]))
          else if (vItem.Categoria <> vDestino.Categoria) and not (vDestino.Categoria in [ccTexto, ccTextoLongo]) then
            Adicionar(gvAviso, vCampo.CampoDestino, Format('O campo de retorno %s.%s é %s e o campo de destino é %s: ' +
              'confira se os valores combinam.', [vCampo.ConsultaTabela, vCampo.ConsultaCampoRetorno, vItem.TipoSql,
              vDestino.TipoSql]));
        end;

      ovConsultaSql:
        begin
          vMensagem := TdmDestino.ConferirSomenteLeitura(vCampo.ConsultaSql);
          if vMensagem = '' then
          begin
            MontarSqlManual(vCampo.ConsultaSql, vSqlFinal);
            if Assigned(ATestarSql) then
              vMensagem := ATestarSql(vSqlFinal);
          end;
          if vMensagem <> '' then
            Adicionar(gvErro, vCampo.CampoDestino, 'Consulta SQL: ' + vMensagem);
        end;

      ovFixo:
        begin
          // O valor fixo é igual em todas as linhas: dá para conferir já
          vResolvido := ResolverCampo(vCampo, vDestino, True, vSemColunas);
          if not vResolvido.Ok then
            Adicionar(gvErro, vCampo.CampoDestino, 'Valor fixo: ' + vResolvido.Mensagem + '.');
        end;

      ovPadrao:
        // O valor padrão vai direto para o campo (sem transformações): confere já
        if not ConverterParaDestino(vCampo.ValorPadrao, vDestino, True, vFinal, vMensagem) then
          Adicionar(gvErro, vCampo.CampoDestino, 'Valor padrão: ' + vMensagem + '.');
    end;
  end;

  // Campos-chave: identificam o registro para saber se ele já existe no destino
  if EstrategiaUsaChave(APerfil.Estrategia) then
  begin
    if Length(APerfil.ListaCamposChave) = 0 then
      Adicionar(gvErro, '', Format('A estratégia "%s" precisa dos campos-chave (aba Gravação do perfil).',
        [cESTRATEGIAS[APerfil.Estrategia].Nome]));
    for vColuna in APerfil.ListaCamposChave do
    begin
      vTemDestino := False;
      for vItem in ACamposDestino do
        if SameText(vItem.Nome, vColuna) then
          vTemDestino := True;
      vCampo := APerfil.CampoPorNome(vColuna);
      if not vTemDestino then
        Adicionar(gvErro, vColuna, 'Campo-chave não existe na tabela de destino.')
      else if (vCampo = nil) or not vCampo.Mapeado then
        Adicionar(gvErro, vColuna, 'Campo-chave sem mapeamento: sem ele não dá para saber se o registro já existe.')
      else if vCampo.Origem = ovGerado then
        Adicionar(gvErro, vColuna, 'Campo-chave não pode ser valor gerado (o valor só existe depois de gravar).');
    end;
  end;

  // Obrigatórios sem mapeamento
  for vDestino in ACamposDestino do
    if vDestino.Obrigatorio and not vDestino.Calculado then
    begin
      vCampo := APerfil.CampoPorNome(vDestino.Nome);
      if (vCampo = nil) or not vCampo.Mapeado then
      begin
        if vDestino.Padrao = '' then
          Adicionar(gvErro, vDestino.Nome, 'Campo obrigatório sem mapeamento.')
        else
          Adicionar(gvAviso, vDestino.Nome,
            Format('Campo obrigatório sem mapeamento: será usado o padrão do banco (%s).', [vDestino.Padrao]));
      end;
    end;

  Result := vProblemas;
end;

end.
