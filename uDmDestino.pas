unit uDmDestino;

{ Acesso ao banco de destino (ERP, sempre Firebird): conexão, metadados e gravação.
  Cada tela que precisa do destino cria o seu: TdmDestino.Create(Self) + Conectar(Dados da conexão).
  Gravação: SQL sempre com parâmetros; nomes de tabela/campo/generator só passam por ValidarNome (no dialeto 1
  não há identificador entre aspas) e devem ter sido conferidos contra os metadados por quem chama. }

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections, Data.DB, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.UI.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Phys,
  FireDAC.VCLUI.Wait, FireDAC.Comp.DataSet, FireDAC.Comp.Client, uConexaoDados;

type
  TCategoriaCampo = (ccTexto, ccInteiro, ccDecimal, ccData, ccDataHora, ccHora, ccBooleano, ccTextoLongo,
    ccBinario, ccOutro);

  TCampoDestino = record
    Posicao: Integer;
    Nome: string;
    TipoSql: string;          // como no DDL: VARCHAR(14), NUMERIC(15,2), INTEGER...
    Categoria: TCategoriaCampo;
    Tamanho: Integer;         // caracteres (texto) ou precisão (numérico)
    Escala: Integer;          // casas decimais
    Obrigatorio: Boolean;     // NOT NULL
    Padrao: string;           // DEFAULT do banco, como no DDL
    ChavePrimaria: Boolean;
    Referencia: string;       // FK: TABELA.CAMPO
    Calculado: Boolean;       // COMPUTED BY: não pode ser gravado
  end;

  TdmDestino = class(TDataModule)
    cnDestino: TFDConnection;
  private
    FConexao: TConexaoDados;
    FComandos: TObjectDictionary<string, TFDQuery>;
    function NovaQuery: TFDQuery;
    function Comando(const ASql: string): TFDQuery;
    procedure LimparComandos;
    class procedure AtribuirParametro(AParametro: TFDParam; const AValor: Variant;
      const ACampo: TCampoDestino); static;
    function ListaDeStrings(const ASql: string; const ATabela: string = ''): TArray<string>;
    class function MontarTipo(ATipo, ASubTipo, ATamanho, APrecisao, AEscala: Integer;
      out ACategoria: TCategoriaCampo; out ATamanhoCampo: Integer): string; static;
  public
    procedure Conectar(const ADados: TConexaoDados);
    procedure Desconectar;
    function Conectado: Boolean;
    function Tabelas: TArray<string>;
    function Generators: TArray<string>;
    function ChavePrimaria(const ATabela: string): TArray<string>;
    function Campos(const ATabela: string): TArray<TCampoDestino>;
    function ExisteTabela(const ATabela: string): Boolean;
    class function NomeCategoria(ACategoria: TCategoriaCampo): string; static;
    class procedure ValidarNome(const ANome: string); static;

    // Gravação
    destructor Destroy; override;
    procedure IniciarTransacao;
    procedure ConfirmarTransacao;
    procedure DesfazerTransacao;
    function EmTransacao: Boolean;
    function ProximoValor(const AGenerator: string): Int64;
    // Quantos registros têm estes valores nos campos-chave
    function ContarRegistros(const ATabela: string; const AChaves: TArray<TCampoDestino>;
      const AValoresChave: TArray<Variant>): Integer;
    // Procura AValor em ATabela.ACampoPesquisa e devolve ACampoRetorno do registro achado.
    // Resultado: quantos registros têm o valor (0, 1, ou 2 = "mais de um"; só lê até 2)
    function ConsultarValor(const ATabela: string; const ACampoPesquisa: TCampoDestino; const ACampoRetorno: string;
      const AValor: Variant; out ARetorno: Variant): Integer;
    // Consulta SQL manual (origem "Consulta SQL"): ASql já com os parâmetros :P0, :P1... na ordem de AValores.
    // Devolve a 1ª coluna da 1ª linha em ARetorno; resultado = linhas encontradas (0, 1 ou 2 = "mais de uma")
    function ConsultarSql(const ASql: string; const AValores: TArray<Variant>; out ARetorno: Variant): Integer;
    // '' = o SELECT é válido no banco (prepara sem executar); senão, a mensagem do erro
    function TestarSql(const ASql: string): string;
    // '' = é um SELECT (ou WITH) sem ";" — a consulta manual não pode alterar o banco
    class function ConferirSomenteLeitura(const ASql: string): string; static;
    procedure Inserir(const ATabela: string; const ACampos: TArray<TCampoDestino>; const AValores: TArray<Variant>);
    function Atualizar(const ATabela: string; const ACampos: TArray<TCampoDestino>; const AValores: TArray<Variant>;
      const AChaves: TArray<TCampoDestino>; const AValoresChave: TArray<Variant>): Integer;
    property Conexao: TConexaoDados read FConexao;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmDestino.Conectar(const ADados: TConexaoDados);
begin
  Desconectar;
  ConfigurarConexaoFireDAC(cnDestino, ADados);
  cnDestino.Open;
  FConexao := ADados;
end;

procedure TdmDestino.Desconectar;
begin
  LimparComandos;
  cnDestino.Close;
  FConexao := Default(TConexaoDados);
end;

destructor TdmDestino.Destroy;
begin
  LimparComandos;
  FComandos.Free;
  inherited;
end;

function TdmDestino.Conectado: Boolean;
begin
  Result := cnDestino.Connected;
end;

function TdmDestino.NovaQuery: TFDQuery;
begin
  if not cnDestino.Connected then
    raise Exception.Create('Não há conexão aberta com o banco de destino.');
  Result := TFDQuery.Create(nil);
  Result.Connection := cnDestino;
end;

function TdmDestino.ListaDeStrings(const ASql, ATabela: string): TArray<string>;
var
  vQry: TFDQuery;
begin
  Result := nil;
  vQry := NovaQuery;
  try
    vQry.SQL.Text := ASql;
    if ATabela <> '' then
      vQry.ParamByName('TABELA').AsString := UpperCase(Trim(ATabela));
    vQry.Open;
    while not vQry.Eof do
    begin
      Result := Result + [Trim(vQry.Fields[0].AsString)];
      vQry.Next;
    end;
  finally
    vQry.Free;
  end;
end;

function TdmDestino.Tabelas: TArray<string>;
begin
  Result := ListaDeStrings(
    'select rdb$relation_name from rdb$relations ' +
    'where coalesce(rdb$system_flag, 0) = 0 and rdb$view_blr is null ' +
    'order by rdb$relation_name');
end;

function TdmDestino.Generators: TArray<string>;
begin
  Result := ListaDeStrings(
    'select rdb$generator_name from rdb$generators ' +
    'where coalesce(rdb$system_flag, 0) = 0 ' +
    'order by rdb$generator_name');
end;

function TdmDestino.ChavePrimaria(const ATabela: string): TArray<string>;
begin
  Result := ListaDeStrings(
    'select s.rdb$field_name from rdb$relation_constraints c ' +
    'join rdb$index_segments s on s.rdb$index_name = c.rdb$index_name ' +
    'where c.rdb$relation_name = :TABELA and c.rdb$constraint_type = ''PRIMARY KEY'' ' +
    'order by s.rdb$field_position', ATabela);
end;

function TdmDestino.ExisteTabela(const ATabela: string): Boolean;
begin
  Result := Length(ListaDeStrings(
    'select rdb$relation_name from rdb$relations where rdb$relation_name = :TABELA', ATabela)) > 0;
end;

class function TdmDestino.MontarTipo(ATipo, ASubTipo, ATamanho, APrecisao, AEscala: Integer;
  out ACategoria: TCategoriaCampo; out ATamanhoCampo: Integer): string;

  function Numerico(APrecisaoPadrao: Integer): string;
  begin
    if APrecisao <= 0 then
      APrecisao := APrecisaoPadrao;
    ATamanhoCampo := APrecisao;
    ACategoria := ccDecimal;
    if ASubTipo = 2 then
      Result := Format('DECIMAL(%d,%d)', [APrecisao, -AEscala])
    else
      Result := Format('NUMERIC(%d,%d)', [APrecisao, -AEscala]);
  end;

begin
  ACategoria := ccOutro;
  ATamanhoCampo := 0;
  case ATipo of
    7, 8, 16, 26:  // SMALLINT, INTEGER, BIGINT, INT128 (ou NUMERIC/DECIMAL com escala)
      if (AEscala < 0) or (ASubTipo in [1, 2]) then
        case ATipo of
          7: Result := Numerico(4);
          8: Result := Numerico(9);
        else
          Result := Numerico(18);
        end
      else
      begin
        ACategoria := ccInteiro;
        case ATipo of
          7: Result := 'SMALLINT';
          8: Result := 'INTEGER';
          16: Result := 'BIGINT';
        else
          Result := 'INT128';
        end;
      end;
    10:
      begin
        Result := 'FLOAT';
        ACategoria := ccDecimal;
      end;
    27:  // no dialeto 1, NUMERIC/DECIMAL de precisão alta é gravado como DOUBLE com escala
      if AEscala < 0 then
        Result := Numerico(15)
      else
      begin
        Result := 'DOUBLE PRECISION';
        ACategoria := ccDecimal;
      end;
    24, 25:
      begin
        Result := 'DECFLOAT';
        ACategoria := ccDecimal;
      end;
    12:
      begin
        Result := 'DATE';
        ACategoria := ccData;
      end;
    13, 28:
      begin
        Result := 'TIME';
        ACategoria := ccHora;
      end;
    35, 29:  // no dialeto 1 o "DATE" é este tipo (data e hora)
      begin
        Result := 'TIMESTAMP';
        ACategoria := ccDataHora;
      end;
    14:
      begin
        Result := Format('CHAR(%d)', [ATamanho]);
        ACategoria := ccTexto;
        ATamanhoCampo := ATamanho;
      end;
    37:
      begin
        Result := Format('VARCHAR(%d)', [ATamanho]);
        ACategoria := ccTexto;
        ATamanhoCampo := ATamanho;
      end;
    23:
      begin
        Result := 'BOOLEAN';
        ACategoria := ccBooleano;
      end;
    261:
      if ASubTipo = 1 then
      begin
        Result := 'BLOB SUB_TYPE TEXT';
        ACategoria := ccTextoLongo;
      end
      else
      begin
        Result := 'BLOB';
        ACategoria := ccBinario;
      end;
  else
    Result := Format('TIPO %d', [ATipo]);
  end;
end;

function TdmDestino.Campos(const ATabela: string): TArray<TCampoDestino>;
var
  vQry: TFDQuery;
  vChave: TArray<string>;
  vCampo: TCampoDestino;
  vTamanho: Integer;
  i: Integer;
begin
  Result := nil;
  vChave := ChavePrimaria(ATabela);

  vQry := NovaQuery;
  try
    vQry.SQL.Text :=
      'select rf.rdb$field_name as CAMPO, rf.rdb$field_position as POSICAO, ' +
      '  f.rdb$field_type as TIPO, coalesce(f.rdb$field_sub_type, 0) as SUBTIPO, ' +
      '  coalesce(f.rdb$character_length, f.rdb$field_length) as TAMANHO, ' +
      '  coalesce(f.rdb$field_precision, 0) as PRECISAO, coalesce(f.rdb$field_scale, 0) as ESCALA, ' +
      '  coalesce(rf.rdb$null_flag, f.rdb$null_flag, 0) as OBRIGATORIO, ' +
      '  coalesce(rf.rdb$default_source, f.rdb$default_source) as PADRAO, ' +
      '  iif(f.rdb$computed_blr is null, 0, 1) as CALCULADO ' +
      'from rdb$relation_fields rf ' +
      'join rdb$fields f on f.rdb$field_name = rf.rdb$field_source ' +
      'where rf.rdb$relation_name = :TABELA ' +
      'order by rf.rdb$field_position';
    vQry.ParamByName('TABELA').AsString := UpperCase(Trim(ATabela));
    vQry.Open;
    while not vQry.Eof do
    begin
      vCampo := Default(TCampoDestino);
      vCampo.Posicao := vQry.FieldByName('POSICAO').AsInteger + 1;
      vCampo.Nome := Trim(vQry.FieldByName('CAMPO').AsString);
      vCampo.TipoSql := MontarTipo(vQry.FieldByName('TIPO').AsInteger, vQry.FieldByName('SUBTIPO').AsInteger,
        vQry.FieldByName('TAMANHO').AsInteger, vQry.FieldByName('PRECISAO').AsInteger,
        vQry.FieldByName('ESCALA').AsInteger, vCampo.Categoria, vTamanho);
      vCampo.Tamanho := vTamanho;
      vCampo.Escala := -vQry.FieldByName('ESCALA').AsInteger;
      if vCampo.Escala < 0 then
        vCampo.Escala := 0;
      vCampo.Obrigatorio := vQry.FieldByName('OBRIGATORIO').AsInteger = 1;
      vCampo.Padrao := Trim(vQry.FieldByName('PADRAO').AsString);
      if SameText(Copy(vCampo.Padrao, 1, 8), 'DEFAULT ') then
        vCampo.Padrao := Trim(Copy(vCampo.Padrao, 9, MaxInt));
      vCampo.Calculado := vQry.FieldByName('CALCULADO').AsInteger = 1;
      for i := 0 to High(vChave) do
        if SameText(vChave[i], vCampo.Nome) then
          vCampo.ChavePrimaria := True;
      Result := Result + [vCampo];
      vQry.Next;
    end;

    // Chaves estrangeiras: campo -> TABELA.CAMPO referenciado
    vQry.Close;
    vQry.SQL.Text :=
      'select seg.rdb$field_name as CAMPO, rcu.rdb$relation_name as TABELA_REF, segr.rdb$field_name as CAMPO_REF ' +
      'from rdb$relation_constraints rc ' +
      'join rdb$index_segments seg on seg.rdb$index_name = rc.rdb$index_name ' +
      'join rdb$ref_constraints ref on ref.rdb$constraint_name = rc.rdb$constraint_name ' +
      'join rdb$relation_constraints rcu on rcu.rdb$constraint_name = ref.rdb$const_name_uq ' +
      'join rdb$index_segments segr on segr.rdb$index_name = rcu.rdb$index_name ' +
      '  and segr.rdb$field_position = seg.rdb$field_position ' +
      'where rc.rdb$relation_name = :TABELA and rc.rdb$constraint_type = ''FOREIGN KEY''';
    vQry.ParamByName('TABELA').AsString := UpperCase(Trim(ATabela));
    vQry.Open;
    while not vQry.Eof do
    begin
      for i := 0 to High(Result) do
        if SameText(Result[i].Nome, Trim(vQry.FieldByName('CAMPO').AsString)) then
          Result[i].Referencia := Trim(vQry.FieldByName('TABELA_REF').AsString) + '.' +
            Trim(vQry.FieldByName('CAMPO_REF').AsString);
      vQry.Next;
    end;
  finally
    vQry.Free;
  end;
end;

{ Gravação }

class procedure TdmDestino.ValidarNome(const ANome: string);
var
  i: Integer;
begin
  // Nome de tabela, campo ou generator que entra no texto do SQL: só letras, dígitos, _ e $
  if (ANome = '') or (Length(ANome) > 63) or not CharInSet(ANome[1], ['A'..'Z', 'a'..'z']) then
    raise Exception.CreateFmt('Nome inválido para o banco de destino: "%s".', [ANome]);
  for i := 2 to Length(ANome) do
    if not CharInSet(ANome[i], ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']) then
      raise Exception.CreateFmt('Nome inválido para o banco de destino: "%s".', [ANome]);
end;

function TdmDestino.Comando(const ASql: string): TFDQuery;
begin
  // Um comando por texto de SQL, preparado uma vez e reaproveitado em todas as linhas
  if FComandos = nil then
    FComandos := TObjectDictionary<string, TFDQuery>.Create([doOwnsValues]);
  if not FComandos.TryGetValue(ASql, Result) then
  begin
    Result := NovaQuery;
    Result.SQL.Text := ASql;
    FComandos.Add(ASql, Result);
  end;
end;

procedure TdmDestino.LimparComandos;
begin
  if FComandos <> nil then
    FComandos.Clear;
end;

class procedure TdmDestino.AtribuirParametro(AParametro: TFDParam; const AValor: Variant;
  const ACampo: TCampoDestino);
begin
  // O tipo do parâmetro vem do campo de destino (também para gravar nulo)
  case ACampo.Categoria of
    ccTexto:
      begin
        AParametro.DataType := ftWideString;
        AParametro.Size := ACampo.Tamanho;
      end;
    ccTextoLongo:
      AParametro.DataType := ftWideMemo;
    ccInteiro:
      AParametro.DataType := ftLargeint;
    ccDecimal:
      AParametro.DataType := ftFloat;
    ccData:
      AParametro.DataType := ftDate;
    ccDataHora:
      AParametro.DataType := ftDateTime;
    ccHora:
      AParametro.DataType := ftTime;
    ccBooleano:
      AParametro.DataType := ftBoolean;
  else
    raise Exception.CreateFmt('Tipo do campo %s (%s) não é suportado na gravação.', [ACampo.Nome, ACampo.TipoSql]);
  end;

  if VarIsNull(AValor) or VarIsEmpty(AValor) then
    AParametro.Clear
  else
    AParametro.Value := AValor;
end;

procedure TdmDestino.IniciarTransacao;
begin
  if not cnDestino.InTransaction then
    cnDestino.StartTransaction;
end;

procedure TdmDestino.ConfirmarTransacao;
begin
  if cnDestino.InTransaction then
    cnDestino.Commit;
end;

procedure TdmDestino.DesfazerTransacao;
begin
  if cnDestino.InTransaction then
    cnDestino.Rollback;
end;

function TdmDestino.EmTransacao: Boolean;
begin
  Result := cnDestino.InTransaction;
end;

function TdmDestino.ProximoValor(const AGenerator: string): Int64;
var
  vQry: TFDQuery;
begin
  ValidarNome(AGenerator);
  vQry := Comando('select gen_id(' + UpperCase(AGenerator) + ', 1) from rdb$database');
  vQry.Open;
  try
    Result := vQry.Fields[0].AsLargeInt;
  finally
    vQry.Close;
  end;
end;

function TdmDestino.ContarRegistros(const ATabela: string; const AChaves: TArray<TCampoDestino>;
  const AValoresChave: TArray<Variant>): Integer;
var
  vSql: string;
  vQry: TFDQuery;
  i: Integer;
begin
  if Length(AChaves) = 0 then
    raise Exception.Create('Nenhum campo-chave para procurar o registro.');
  ValidarNome(ATabela);
  vSql := 'select count(*) from ' + UpperCase(ATabela) + ' where ';
  for i := 0 to High(AChaves) do
  begin
    ValidarNome(AChaves[i].Nome);
    if i > 0 then
      vSql := vSql + ' and ';
    vSql := vSql + UpperCase(AChaves[i].Nome) + ' = :K' + IntToStr(i);
  end;

  vQry := Comando(vSql);
  for i := 0 to High(AChaves) do
    AtribuirParametro(vQry.ParamByName('K' + IntToStr(i)), AValoresChave[i], AChaves[i]);
  vQry.Open;
  try
    Result := vQry.Fields[0].AsInteger;
  finally
    vQry.Close;
  end;
end;

function TdmDestino.ConsultarValor(const ATabela: string; const ACampoPesquisa: TCampoDestino;
  const ACampoRetorno: string; const AValor: Variant; out ARetorno: Variant): Integer;
var
  vQry: TFDQuery;
begin
  ValidarNome(ATabela);
  ValidarNome(ACampoPesquisa.Nome);
  ValidarNome(ACampoRetorno);
  vQry := Comando('select first 2 ' + UpperCase(ACampoRetorno) + ' from ' + UpperCase(ATabela) + ' where ' +
    UpperCase(ACampoPesquisa.Nome) + ' = :V');
  AtribuirParametro(vQry.ParamByName('V'), AValor, ACampoPesquisa);
  vQry.Open;
  try
    ARetorno := Null;
    Result := 0;
    while not vQry.Eof do
    begin
      if Result = 0 then
        ARetorno := vQry.Fields[0].Value;
      Inc(Result);
      vQry.Next;
    end;
  finally
    vQry.Close;
  end;
end;

class function TdmDestino.ConferirSomenteLeitura(const ASql: string): string;
var
  vSql: string;
begin
  Result := '';
  vSql := LowerCase(Trim(ASql));
  if vSql = '' then
    Exit('o SELECT está vazio');
  if not (vSql.StartsWith('select') or vSql.StartsWith('with')) then
    Exit('a consulta manual precisa começar com SELECT (ou WITH)');
  if Pos(';', vSql) > 0 then
    Exit('a consulta manual não pode ter ";" (um comando só)');
end;

function TdmDestino.ConsultarSql(const ASql: string; const AValores: TArray<Variant>; out ARetorno: Variant): Integer;
var
  vQry: TFDQuery;
  vMensagem: string;
  vTipo: TVarType;
  i: Integer;
begin
  vMensagem := ConferirSomenteLeitura(ASql);
  if vMensagem <> '' then
    raise Exception.Create(vMensagem);

  vQry := Comando(ASql);
  for i := 0 to High(AValores) do
    with vQry.ParamByName('P' + IntToStr(i)) do
    begin
      // Tipo do parâmetro pelo valor (a consulta manual não tem metadados do campo comparado)
      vTipo := VarType(AValores[i]) and varTypeMask;
      if VarIsNull(AValores[i]) or VarIsEmpty(AValores[i]) then
      begin
        DataType := ftWideString;
        Clear;
        Continue;
      end;
      case vTipo of
        varSmallint, varInteger, varShortInt, varByte, varWord, varLongWord, varInt64, varUInt64:
          DataType := ftLargeint;
        varSingle, varDouble, varCurrency:
          DataType := ftFloat;
        varDate:
          DataType := ftDateTime;
        varBoolean:
          DataType := ftBoolean;
      else
        DataType := ftWideString;
      end;
      Value := AValores[i];
    end;

  vQry.Open;
  try
    if vQry.FieldCount = 0 then
      raise Exception.Create('a consulta não devolve nenhuma coluna');
    ARetorno := Null;
    Result := 0;
    while not vQry.Eof and (Result < 2) do
    begin
      if Result = 0 then
        ARetorno := vQry.Fields[0].Value;
      Inc(Result);
      vQry.Next;
    end;
  finally
    vQry.Close;
  end;
end;

function TdmDestino.TestarSql(const ASql: string): string;
var
  vQry: TFDQuery;
begin
  Result := ConferirSomenteLeitura(ASql);
  if Result <> '' then
    Exit;
  vQry := NovaQuery;
  try
    try
      vQry.SQL.Text := ASql;
      vQry.Prepare;
    except
      on E: Exception do
        Result := E.Message;
    end;
  finally
    vQry.Free;
  end;
end;

procedure TdmDestino.Inserir(const ATabela: string; const ACampos: TArray<TCampoDestino>;
  const AValores: TArray<Variant>);
var
  vCampos, vParametros: string;
  vQry: TFDQuery;
  i: Integer;
begin
  ValidarNome(ATabela);
  vCampos := '';
  vParametros := '';
  for i := 0 to High(ACampos) do
  begin
    ValidarNome(ACampos[i].Nome);
    if i > 0 then
    begin
      vCampos := vCampos + ', ';
      vParametros := vParametros + ', ';
    end;
    vCampos := vCampos + UpperCase(ACampos[i].Nome);
    vParametros := vParametros + ':P' + IntToStr(i);
  end;

  vQry := Comando('insert into ' + UpperCase(ATabela) + ' (' + vCampos + ') values (' + vParametros + ')');
  for i := 0 to High(ACampos) do
    AtribuirParametro(vQry.ParamByName('P' + IntToStr(i)), AValores[i], ACampos[i]);
  vQry.ExecSQL;
end;

function TdmDestino.Atualizar(const ATabela: string; const ACampos: TArray<TCampoDestino>;
  const AValores: TArray<Variant>; const AChaves: TArray<TCampoDestino>; const AValoresChave: TArray<Variant>): Integer;
var
  vSql: string;
  vQry: TFDQuery;
  i: Integer;
begin
  if Length(AChaves) = 0 then
    raise Exception.Create('Nenhum campo-chave para atualizar o registro.');
  ValidarNome(ATabela);
  vSql := 'update ' + UpperCase(ATabela) + ' set ';
  for i := 0 to High(ACampos) do
  begin
    ValidarNome(ACampos[i].Nome);
    if i > 0 then
      vSql := vSql + ', ';
    vSql := vSql + UpperCase(ACampos[i].Nome) + ' = :P' + IntToStr(i);
  end;
  vSql := vSql + ' where ';
  for i := 0 to High(AChaves) do
  begin
    ValidarNome(AChaves[i].Nome);
    if i > 0 then
      vSql := vSql + ' and ';
    vSql := vSql + UpperCase(AChaves[i].Nome) + ' = :K' + IntToStr(i);
  end;

  vQry := Comando(vSql);
  for i := 0 to High(ACampos) do
    AtribuirParametro(vQry.ParamByName('P' + IntToStr(i)), AValores[i], ACampos[i]);
  for i := 0 to High(AChaves) do
    AtribuirParametro(vQry.ParamByName('K' + IntToStr(i)), AValoresChave[i], AChaves[i]);
  vQry.ExecSQL;
  Result := vQry.RowsAffected;
end;

class function TdmDestino.NomeCategoria(ACategoria: TCategoriaCampo): string;
const
  cNOMES: array[TCategoriaCampo] of string = ('Texto', 'Inteiro', 'Decimal', 'Data', 'Data e hora', 'Hora',
    'Booleano', 'Texto longo', 'Binário', 'Outro');
begin
  Result := cNOMES[ACategoria];
end;

end.
