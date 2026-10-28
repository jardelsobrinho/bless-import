unit uTransformacoes;

{ Transformações de valores (sem tela e sem banco).
  Regras:
  - Nunca converter em silêncio: valor que não puder ser convertido gera erro com mensagem clara.
  - Formatos fixos (não dependem da configuração regional da máquina).
  - Valor vazio/nulo passa adiante como Null nas conversões de tipo (quem decide o que fazer com ele é o
    valor padrão do campo); só "Vazio para nulo" e "De-para" tratam vazio explicitamente.
  Nova transformação: novo item em TTipoTransformacao + cTRANSFORMACOES + um case em Transformar. }

interface

uses
  System.SysUtils, System.Variants, System.Math, System.DateUtils;

type
  TTipoTransformacao = (
    ttTextoParaInteiro,
    ttTextoParaDecimal,
    ttTextoParaData,
    ttTextoParaDataHora,
    ttTextoParaBooleano,
    ttRemoverEspacos,
    ttMaiusculas,
    ttMinusculas,
    ttSomenteDigitos,
    ttDdd,
    ttTelefoneSemDdd,
    ttParteTexto,
    ttCpfCnpj,
    ttConcatenar,
    ttArredondar,
    ttDePara,
    ttVazioParaNulo);

  TTransformacao = record
    Tipo: TTipoTransformacao;
    Parametro: string;
  end;

  TResultadoTransformacao = record
    Sucesso: Boolean;
    Valor: Variant;
    Mensagem: string;
  end;

  TInfoTransformacao = record
    Codigo: string;          // gravado no perfil
    Nome: string;            // exibido na tela
    AjudaParametro: string;  // vazio = não usa parâmetro
  end;

  // Devolve o valor de outra coluna da linha (usado por Concatenar); False = coluna não existe
  TObterValorColuna = reference to function(const ANomeColuna: string; out AValor: Variant): Boolean;

const
  cTRANSFORMACOES: array[TTipoTransformacao] of TInfoTransformacao = (
    (Codigo: 'TEXTO_PARA_INTEIRO'; Nome: 'Texto para inteiro'; AjudaParametro: ''),
    (Codigo: 'TEXTO_PARA_DECIMAL'; Nome: 'Texto para decimal';
      AjudaParametro: 'BR (1.234,56 - padrão) ou US (1,234.56)'),
    (Codigo: 'TEXTO_PARA_DATA'; Nome: 'Texto para data';
      AjudaParametro: 'Formato: DD/MM/AAAA (padrão), DD/MM/AA, AAAA-MM-DD, DDMMAAAA, AAAAMMDD...'),
    (Codigo: 'TEXTO_PARA_DATA_HORA'; Nome: 'Texto para data e hora';
      AjudaParametro: 'Formato da data (padrão DD/MM/AAAA); a hora HH:NN[:SS] é opcional depois de um espaço'),
    (Codigo: 'TEXTO_PARA_BOOLEANO'; Nome: 'Texto para booleano';
      AjudaParametro: 'Valores gravados para verdadeiro/falso: S/N (padrão), T/F, 1/0...'),
    (Codigo: 'REMOVER_ESPACOS'; Nome: 'Remover espaços';
      AjudaParametro: 'Vazio = bordas e espaços repetidos; TODOS = remove todos os espaços'),
    (Codigo: 'MAIUSCULAS'; Nome: 'Maiúsculas'; AjudaParametro: ''),
    (Codigo: 'MINUSCULAS'; Nome: 'Minúsculas'; AjudaParametro: ''),
    (Codigo: 'SOMENTE_DIGITOS'; Nome: 'Somente dígitos'; AjudaParametro: ''),
    (Codigo: 'DDD'; Nome: 'DDD do telefone'; AjudaParametro: ''),
    (Codigo: 'TELEFONE_SEM_DDD'; Nome: 'Telefone sem DDD';
      AjudaParametro: 'Vazio = só dígitos (33431342); FORMATADO = 3343-1342. O DDD só é removido com mais ' +
      'de 9 dígitos; telefone zerado ou inválido fica em branco'),
    (Codigo: 'PARTE_TEXTO'; Nome: 'Parte do texto';
      AjudaParametro: 'início,quantidade (início a partir de 1), ex.: 1,3 = 3 primeiros; 5 = do 5º até o fim'),
    (Codigo: 'CPF_CNPJ'; Nome: 'CPF/CNPJ';
      AjudaParametro: 'Vazio = só dígitos validando; FORMATADO = com pontuação; SEM_VALIDAR = só dígitos'),
    (Codigo: 'CONCATENAR'; Nome: 'Concatenar';
      AjudaParametro: 'Modelo com {valor} e {Nome da coluna}, ex.: {valor}, {Numero} - {Complemento}'),
    (Codigo: 'ARREDONDAR'; Nome: 'Arredondar'; AjudaParametro: 'Casas decimais (padrão 2)'),
    (Codigo: 'DE_PARA'; Nome: 'De-para (condicional)';
      AjudaParametro: 'de=para separados por ;  e * para os demais, ex.: JURIDICA=J;FISICA=F;*=F'),
    (Codigo: 'VAZIO_PARA_NULO'; Nome: 'Vazio para nulo'; AjudaParametro: ''));

function Transformar(ATipo: TTipoTransformacao; const AValor: Variant; const AParametro: string;
  AObterColuna: TObterValorColuna = nil): TResultadoTransformacao;

// Aplica a lista em ordem; para no primeiro erro (a mensagem indica qual transformação falhou)
function AplicarTransformacoes(const ALista: TArray<TTransformacao>; const AValor: Variant;
  AObterColuna: TObterValorColuna = nil): TResultadoTransformacao;

// Gravação da lista no perfil: uma transformação por linha, "CODIGO|parâmetro"
function TransformacoesParaTexto(const ALista: TArray<TTransformacao>): string;
function TextoParaTransformacoes(const ATexto: string): TArray<TTransformacao>;
function TipoPorCodigo(const ACodigo: string; out ATipo: TTipoTransformacao): Boolean;

// Utilitários também usados pela validação dos valores
function TextoParaNumero(const ATexto: string; AFormatoBR: Boolean; out AValor: Double): Boolean;
function ValidarCpf(const ADigitos: string): Boolean;
function ValidarCnpj(const ADigitos: string): Boolean;
function ValorParaTexto(const AValor: Variant): string;
function EhVazio(const AValor: Variant): Boolean;
function EhTexto(const AValor: Variant): Boolean;
function EhNumero(const AValor: Variant): Boolean;
function EhData(const AValor: Variant): Boolean;

// Nomes de coluna citados num modelo de concatenação/expressão ({Coluna}), sem o {valor} e sem repetir
function ColunasDoModelo(const AModelo: string): TArray<string>;

implementation

var
  GFormatoInvariante: TFormatSettings;

function Ok(const AValor: Variant): TResultadoTransformacao;
begin
  Result.Sucesso := True;
  Result.Valor := AValor;
  Result.Mensagem := '';
end;

function Erro(const AMensagem: string): TResultadoTransformacao;
begin
  Result.Sucesso := False;
  Result.Valor := Null;
  Result.Mensagem := AMensagem;
end;

function EhTexto(const AValor: Variant): Boolean;
var
  vTipo: TVarType;
begin
  vTipo := VarType(AValor) and varTypeMask;
  Result := (vTipo = varString) or (vTipo = varUString) or (vTipo = varOleStr);
end;

function EhVazio(const AValor: Variant): Boolean;
begin
  Result := VarIsNull(AValor) or VarIsEmpty(AValor) or (EhTexto(AValor) and (Trim(VarToStr(AValor)) = ''));
end;

function EhData(const AValor: Variant): Boolean;
begin
  Result := (VarType(AValor) and varTypeMask) = varDate;
end;

function EhNumero(const AValor: Variant): Boolean;
begin
  Result := (VarType(AValor) and varTypeMask) in [varSmallint, varInteger, varSingle, varDouble, varCurrency,
    varShortInt, varByte, varWord, varLongWord, varInt64, varUInt64];
end;

function ValorParaTexto(const AValor: Variant): string;
begin
  // Texto em formato brasileiro fixo, sem depender da máquina
  if EhVazio(AValor) then
    Result := ''
  else if EhData(AValor) then
  begin
    if TimeOf(AValor) = 0 then
      Result := FormatDateTime('dd/mm/yyyy', AValor)
    else
      Result := FormatDateTime('dd/mm/yyyy hh:nn:ss', AValor);
  end
  else if (VarType(AValor) and varTypeMask) = varBoolean then
  begin
    if Boolean(AValor) then
      Result := 'S'
    else
      Result := 'N';
  end
  else if EhNumero(AValor) then
    Result := StringReplace(FloatToStr(Double(AValor), GFormatoInvariante), '.', ',', [])
  else
    Result := VarToStr(AValor);
end;

// Divide na primeira ocorrência do separador (o Split do Delphi com Count descarta o restante)
function DividirNaPrimeira(const ATexto: string; ASeparador: Char; out AAntes, ADepois: string): Boolean;
var
  vPosicao: Integer;
begin
  vPosicao := Pos(ASeparador, ATexto);
  Result := vPosicao > 0;
  if Result then
  begin
    AAntes := Copy(ATexto, 1, vPosicao - 1);
    ADepois := Copy(ATexto, vPosicao + 1, MaxInt);
  end
  else
  begin
    AAntes := ATexto;
    ADepois := '';
  end;
end;

function SomenteDigitos(const ATexto: string): string;
var
  vCaractere: Char;
begin
  Result := '';
  for vCaractere in ATexto do
    if CharInSet(vCaractere, ['0'..'9']) then
      Result := Result + vCaractere;
end;

function SoDigitos(const ATexto: string): Boolean;
var
  vCaractere: Char;
begin
  Result := ATexto <> '';
  for vCaractere in ATexto do
    if not CharInSet(vCaractere, ['0'..'9']) then
      Exit(False);
end;

function TextoParaNumero(const ATexto: string; AFormatoBR: Boolean; out AValor: Double): Boolean;
var
  vTexto, vInteira, vFracao: string;
  vSepDecimal, vSepMilhar: Char;
  vNegativo: Boolean;
  vPosDecimal, i: Integer;
  vGrupos: TArray<string>;
begin
  Result := False;
  AValor := 0;

  vTexto := StringReplace(Trim(ATexto), 'R$', '', [rfIgnoreCase]);
  vTexto := StringReplace(vTexto, ' ', '', [rfReplaceAll]);
  vTexto := StringReplace(vTexto, #160, '', [rfReplaceAll]);
  if vTexto = '' then
    Exit;

  // Negativo: -10, 10- ou (10)
  vNegativo := False;
  if (vTexto[1] = '(') and (vTexto[Length(vTexto)] = ')') then
  begin
    vNegativo := True;
    vTexto := Copy(vTexto, 2, Length(vTexto) - 2);
  end
  else if vTexto[1] = '-' then
  begin
    vNegativo := True;
    Delete(vTexto, 1, 1);
  end
  else if vTexto[Length(vTexto)] = '-' then
  begin
    vNegativo := True;
    Delete(vTexto, Length(vTexto), 1);
  end
  else if vTexto[1] = '+' then
    Delete(vTexto, 1, 1);

  if AFormatoBR then
  begin
    vSepDecimal := ',';
    vSepMilhar := '.';
  end
  else
  begin
    vSepDecimal := '.';
    vSepMilhar := ',';
  end;

  // No máximo um separador decimal
  vPosDecimal := Pos(vSepDecimal, vTexto);
  if vPosDecimal > 0 then
  begin
    if Pos(vSepDecimal, Copy(vTexto, vPosDecimal + 1, MaxInt)) > 0 then
      Exit;
    vInteira := Copy(vTexto, 1, vPosDecimal - 1);
    vFracao := Copy(vTexto, vPosDecimal + 1, MaxInt);
    if not SoDigitos(vFracao) then
      Exit;
  end
  else
  begin
    vInteira := vTexto;
    vFracao := '';
  end;

  if vInteira = '' then
    vInteira := '0';

  // Separador de milhar só em grupos de 3 dígitos (1.234.567)
  if Pos(vSepMilhar, vInteira) > 0 then
  begin
    vGrupos := vInteira.Split([vSepMilhar]);
    if (Length(vGrupos[0]) < 1) or (Length(vGrupos[0]) > 3) then
      Exit;
    for i := 1 to High(vGrupos) do
      if Length(vGrupos[i]) <> 3 then
        Exit;
    vInteira := StringReplace(vInteira, vSepMilhar, '', [rfReplaceAll]);
  end;

  if not SoDigitos(vInteira) then
    Exit;

  if vFracao = '' then
    vTexto := vInteira
  else
    vTexto := vInteira + '.' + vFracao;
  if not TryStrToFloat(vTexto, AValor, GFormatoInvariante) then
    Exit;
  if vNegativo then
    AValor := -AValor;
  Result := True;
end;

function ConverterInteiro(const AValor: Variant): TResultadoTransformacao;
var
  vNumero: Double;
begin
  if EhVazio(AValor) then
    Exit(Ok(Null));

  if EhNumero(AValor) then
    vNumero := AValor
  else if not TextoParaNumero(VarToStr(AValor), True, vNumero) then
    Exit(Erro(Format('"%s" não é um número inteiro válido.', [VarToStr(AValor)])));

  if Frac(vNumero) <> 0 then
    Exit(Erro(Format('"%s" tem casas decimais; esperado um número inteiro.', [ValorParaTexto(AValor)])));
  if Abs(vNumero) > High(Int64) then
    Exit(Erro(Format('"%s" é grande demais para um número inteiro.', [ValorParaTexto(AValor)])));

  Result := Ok(Trunc(vNumero));
end;

function ConverterDecimal(const AValor: Variant; const AParametro: string): TResultadoTransformacao;
var
  vNumero: Double;
  vFormatoBR: Boolean;
begin
  if EhVazio(AValor) then
    Exit(Ok(Null));
  if EhNumero(AValor) then
    Exit(Ok(Double(AValor)));

  if (Trim(AParametro) = '') or SameText(Trim(AParametro), 'BR') then
    vFormatoBR := True
  else if SameText(Trim(AParametro), 'US') then
    vFormatoBR := False
  else
    Exit(Erro(Format('Parâmetro "%s" inválido para texto para decimal (use BR ou US).', [AParametro])));

  if not TextoParaNumero(VarToStr(AValor), vFormatoBR, vNumero) then
  begin
    if vFormatoBR then
      Exit(Erro(Format('"%s" não é um número decimal válido no formato BR (ex.: 1.234,56).', [VarToStr(AValor)])))
    else
      Exit(Erro(Format('"%s" não é um número decimal válido no formato US (ex.: 1,234.56).', [VarToStr(AValor)])));
  end;
  Result := Ok(vNumero);
end;

function LerData(const ATexto, AFormato: string; out AData: TDateTime): Boolean;
var
  vFormato, vTexto, vSeparadores: string;
  vTokens, vPartes: TArray<string>;
  vDia, vMes, vAno, i, vPosicao, vValor: Integer;
  vToken: string;
  vCaractere: Char;
begin
  Result := False;
  vFormato := UpperCase(Trim(AFormato));
  if vFormato = '' then
    vFormato := 'DD/MM/AAAA';
  vTexto := Trim(ATexto);
  vDia := 0;
  vMes := 0;
  vAno := 0;

  vSeparadores := '';
  for vCaractere in vFormato do
    if not CharInSet(vCaractere, ['D', 'M', 'A']) and (Pos(vCaractere, vSeparadores) = 0) then
      vSeparadores := vSeparadores + vCaractere;

  if vSeparadores <> '' then
  begin
    // Com separador: aceita dia e mês com 1 ou 2 dígitos (1/2/2020)
    vTokens := vFormato.Split(vSeparadores.ToCharArray);
    vPartes := vTexto.Split(vSeparadores.ToCharArray);
    if Length(vTokens) <> Length(vPartes) then
      Exit;
    for i := 0 to High(vTokens) do
    begin
      if not SoDigitos(vPartes[i]) then
        Exit;
      vValor := StrToInt(vPartes[i]);
      if vTokens[i] = 'DD' then
      begin
        if Length(vPartes[i]) > 2 then
          Exit;
        vDia := vValor;
      end
      else if vTokens[i] = 'MM' then
      begin
        if Length(vPartes[i]) > 2 then
          Exit;
        vMes := vValor;
      end
      else if vTokens[i] = 'AAAA' then
      begin
        if Length(vPartes[i]) <> 4 then
          Exit;
        vAno := vValor;
      end
      else if vTokens[i] = 'AA' then
      begin
        if Length(vPartes[i]) <> 2 then
          Exit;
        vAno := vValor;
        if vAno < 50 then
          vAno := 2000 + vAno
        else
          vAno := 1900 + vAno;
      end
      else
        Exit;
    end;
  end
  else
  begin
    // Sem separador: posições fixas (DDMMAAAA, AAAAMMDD)
    if (Length(vTexto) <> Length(vFormato)) or not SoDigitos(vTexto) then
      Exit;
    vPosicao := 1;
    while vPosicao <= Length(vFormato) do
    begin
      if Copy(vFormato, vPosicao, 4) = 'AAAA' then
        vToken := 'AAAA'
      else
        vToken := Copy(vFormato, vPosicao, 2);
      vValor := StrToInt(Copy(vTexto, vPosicao, Length(vToken)));
      if vToken = 'DD' then
        vDia := vValor
      else if vToken = 'MM' then
        vMes := vValor
      else if vToken = 'AAAA' then
        vAno := vValor
      else if vToken = 'AA' then
      begin
        if vValor < 50 then
          vAno := 2000 + vValor
        else
          vAno := 1900 + vValor;
      end
      else
        Exit;
      Inc(vPosicao, Length(vToken));
    end;
  end;

  Result := TryEncodeDate(vAno, vMes, vDia, AData);
end;

function LerHora(const ATexto: string; out AHora: TDateTime): Boolean;
var
  vPartes: TArray<string>;
  vHora, vMinuto, vSegundo: Integer;
begin
  Result := False;
  vPartes := Trim(ATexto).Split([':']);
  if not (Length(vPartes) in [2, 3]) then
    Exit;
  if not SoDigitos(vPartes[0]) or not SoDigitos(vPartes[1]) then
    Exit;
  vHora := StrToInt(vPartes[0]);
  vMinuto := StrToInt(vPartes[1]);
  vSegundo := 0;
  if Length(vPartes) = 3 then
  begin
    if not SoDigitos(vPartes[2]) then
      Exit;
    vSegundo := StrToInt(vPartes[2]);
  end;
  Result := TryEncodeTime(vHora, vMinuto, vSegundo, 0, AHora);
end;

function NomeFormato(const AParametro: string): string;
begin
  Result := UpperCase(Trim(AParametro));
  if Result = '' then
    Result := 'DD/MM/AAAA';
end;

function ConverterData(const AValor: Variant; const AParametro: string): TResultadoTransformacao;
var
  vData: TDateTime;
begin
  if EhVazio(AValor) then
    Exit(Ok(Null));
  if EhData(AValor) then
    Exit(Ok(VarFromDateTime(DateOf(AValor))));
  if not EhTexto(AValor) then
    Exit(Erro(Format('"%s" não é uma data (esperado texto no formato %s).',
      [ValorParaTexto(AValor), NomeFormato(AParametro)])));

  if not LerData(VarToStr(AValor), AParametro, vData) then
    Exit(Erro(Format('"%s" não é uma data válida no formato %s.', [VarToStr(AValor), NomeFormato(AParametro)])));
  Result := Ok(VarFromDateTime(vData));
end;

function ConverterDataHora(const AValor: Variant; const AParametro: string): TResultadoTransformacao;
var
  vTexto, vParteData, vParteHora: string;
  vData, vHora: TDateTime;
  vEspaco: Integer;
begin
  if EhVazio(AValor) then
    Exit(Ok(Null));
  if EhData(AValor) then
    Exit(Ok(VarFromDateTime(AValor)));
  if not EhTexto(AValor) then
    Exit(Erro(Format('"%s" não é uma data e hora (esperado texto no formato %s HH:NN:SS).',
      [ValorParaTexto(AValor), NomeFormato(AParametro)])));

  vTexto := Trim(VarToStr(AValor));
  vEspaco := Pos(' ', vTexto);
  if vEspaco > 0 then
  begin
    vParteData := Copy(vTexto, 1, vEspaco - 1);
    vParteHora := Trim(Copy(vTexto, vEspaco + 1, MaxInt));
  end
  else
  begin
    vParteData := vTexto;
    vParteHora := '';
  end;

  if not LerData(vParteData, AParametro, vData) then
    Exit(Erro(Format('"%s" não é uma data e hora válida no formato %s HH:NN:SS.',
      [vTexto, NomeFormato(AParametro)])));
  vHora := 0;
  if (vParteHora <> '') and not LerHora(vParteHora, vHora) then
    Exit(Erro(Format('"%s" tem uma hora inválida (esperado HH:NN ou HH:NN:SS).', [vTexto])));

  Result := Ok(VarFromDateTime(vData + vHora));
end;

function ConverterBooleano(const AValor: Variant; const AParametro: string): TResultadoTransformacao;
var
  vSaidas: TArray<string>;
  vTexto: string;
  vVerdadeiro: Boolean;
begin
  if Trim(AParametro) = '' then
    vSaidas := ['S', 'N']
  else
    vSaidas := Trim(AParametro).Split(['/']);
  if Length(vSaidas) <> 2 then
    Exit(Erro(Format('Parâmetro "%s" inválido para texto para booleano (use verdadeiro/falso, ex.: S/N).',
      [AParametro])));

  if EhVazio(AValor) then
    Exit(Ok(Null));

  if (VarType(AValor) and varTypeMask) = varBoolean then
    vVerdadeiro := AValor
  else
  begin
    vTexto := AnsiUpperCase(Trim(ValorParaTexto(AValor)));
    if (vTexto = 'S') or (vTexto = 'SIM') or (vTexto = 'T') or (vTexto = 'TRUE') or (vTexto = 'V') or
      (vTexto = 'VERDADEIRO') or (vTexto = '1') or (vTexto = 'Y') or (vTexto = 'YES') then
      vVerdadeiro := True
    else if (vTexto = 'N') or (vTexto = 'NAO') or (vTexto = 'NÃO') or (vTexto = 'F') or (vTexto = 'FALSE') or
      (vTexto = 'FALSO') or (vTexto = '0') or (vTexto = 'NO') then
      vVerdadeiro := False
    else
      Exit(Erro(Format('"%s" não é um valor booleano reconhecido (S/N, Sim/Não, T/F, 1/0...).',
        [ValorParaTexto(AValor)])));
  end;

  if vVerdadeiro then
    Result := Ok(vSaidas[0])
  else
    Result := Ok(vSaidas[1]);
end;

function RemoverEspacos(const AValor: Variant; const AParametro: string): TResultadoTransformacao;
var
  vTexto: string;
begin
  if VarIsNull(AValor) or VarIsEmpty(AValor) then
    Exit(Ok(Null));
  vTexto := StringReplace(ValorParaTexto(AValor), #160, ' ', [rfReplaceAll]);

  if SameText(Trim(AParametro), 'TODOS') then
    vTexto := StringReplace(vTexto, ' ', '', [rfReplaceAll])
  else if Trim(AParametro) = '' then
  begin
    vTexto := Trim(vTexto);
    while Pos('  ', vTexto) > 0 do
      vTexto := StringReplace(vTexto, '  ', ' ', [rfReplaceAll]);
  end
  else
    Exit(Erro(Format('Parâmetro "%s" inválido para remover espaços (use vazio ou TODOS).', [AParametro])));

  Result := Ok(vTexto);
end;

function FormatarCpfCnpj(const ADigitos: string): string;
begin
  if Length(ADigitos) = 11 then
    Result := Copy(ADigitos, 1, 3) + '.' + Copy(ADigitos, 4, 3) + '.' + Copy(ADigitos, 7, 3) + '-' +
      Copy(ADigitos, 10, 2)
  else
    Result := Copy(ADigitos, 1, 2) + '.' + Copy(ADigitos, 3, 3) + '.' + Copy(ADigitos, 6, 3) + '/' +
      Copy(ADigitos, 9, 4) + '-' + Copy(ADigitos, 13, 2);
end;

function TodosIguais(const ADigitos: string): Boolean;
var
  vCaractere: Char;
begin
  Result := True;
  for vCaractere in ADigitos do
    if vCaractere <> ADigitos[1] then
      Exit(False);
end;

function ValidarCpf(const ADigitos: string): Boolean;
var
  i, vSoma, vDigito: Integer;
begin
  Result := False;
  if (Length(ADigitos) <> 11) or not SoDigitos(ADigitos) or TodosIguais(ADigitos) then
    Exit;

  vSoma := 0;
  for i := 1 to 9 do
    Inc(vSoma, StrToInt(ADigitos[i]) * (11 - i));
  vDigito := 11 - (vSoma mod 11);
  if vDigito >= 10 then
    vDigito := 0;
  if vDigito <> StrToInt(ADigitos[10]) then
    Exit;

  vSoma := 0;
  for i := 1 to 10 do
    Inc(vSoma, StrToInt(ADigitos[i]) * (12 - i));
  vDigito := 11 - (vSoma mod 11);
  if vDigito >= 10 then
    vDigito := 0;
  Result := vDigito = StrToInt(ADigitos[11]);
end;

function ValidarCnpj(const ADigitos: string): Boolean;
const
  cPESOS1: array[1..12] of Integer = (5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);
  cPESOS2: array[1..13] of Integer = (6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);
var
  i, vSoma, vDigito: Integer;
begin
  Result := False;
  if (Length(ADigitos) <> 14) or not SoDigitos(ADigitos) or TodosIguais(ADigitos) then
    Exit;

  vSoma := 0;
  for i := 1 to 12 do
    Inc(vSoma, StrToInt(ADigitos[i]) * cPESOS1[i]);
  vDigito := vSoma mod 11;
  if vDigito < 2 then
    vDigito := 0
  else
    vDigito := 11 - vDigito;
  if vDigito <> StrToInt(ADigitos[13]) then
    Exit;

  vSoma := 0;
  for i := 1 to 13 do
    Inc(vSoma, StrToInt(ADigitos[i]) * cPESOS2[i]);
  vDigito := vSoma mod 11;
  if vDigito < 2 then
    vDigito := 0
  else
    vDigito := 11 - vDigito;
  Result := vDigito = StrToInt(ADigitos[14]);
end;

function ConverterCpfCnpj(const AValor: Variant; const AParametro: string): TResultadoTransformacao;
var
  vParametro, vOriginal, vDigitos: string;
  vValidar, vFormatar: Boolean;
begin
  vParametro := UpperCase(Trim(AParametro));
  if (vParametro <> '') and (vParametro <> 'FORMATADO') and (vParametro <> 'SEM_VALIDAR') then
    Exit(Erro(Format('Parâmetro "%s" inválido para CPF/CNPJ (use vazio, FORMATADO ou SEM_VALIDAR).',
      [AParametro])));
  vValidar := vParametro <> 'SEM_VALIDAR';
  vFormatar := vParametro = 'FORMATADO';

  if EhVazio(AValor) then
    Exit(Ok(Null));

  if EhNumero(AValor) then
    vOriginal := FormatFloat('0', Double(AValor), GFormatoInvariante)
  else
    vOriginal := Trim(VarToStr(AValor));
  vDigitos := SomenteDigitos(vOriginal);

  if vValidar then
  begin
    if Length(vDigitos) = 11 then
    begin
      if not ValidarCpf(vDigitos) then
        Exit(Erro(Format('"%s" não é um CPF válido.', [vOriginal])));
    end
    else if Length(vDigitos) = 14 then
    begin
      if not ValidarCnpj(vDigitos) then
        Exit(Erro(Format('"%s" não é um CNPJ válido.', [vOriginal])));
    end
    else
      Exit(Erro(Format('"%s" não é um CPF (11 dígitos) nem um CNPJ (14 dígitos).', [vOriginal])));
  end;

  if vFormatar and (Length(vDigitos) in [11, 14]) then
    Result := Ok(FormatarCpfCnpj(vDigitos))
  else
    Result := Ok(vDigitos);
end;

// Separa DDD e número contando só os dígitos. Aceita qualquer pontuação: (68) 3343-1342, 68 9 9999 9999...
// Descarta o 0 de discagem (031 3333 4444) e o 55 do país (+55 68 3343-1342).
// Até 9 dígitos: não tem DDD (ADdd vazio, ANumero = os dígitos como vieram).
// 10 ou 11 dígitos: os 2 primeiros são o DDD; DDD 00 = sem DDD (ADdd vazio, ANumero = o resto).
// False = telefone inválido (nenhum dígito, mais de 11 dígitos, DDD com um zero como 01 ou 10).
function SepararTelefone(const AValor: Variant; out ADdd, ANumero: string): Boolean;
var
  vDigitos: string;
begin
  Result := False;
  ADdd := '';
  ANumero := '';

  if EhNumero(AValor) then
    vDigitos := SomenteDigitos(FormatFloat('0', Double(AValor), GFormatoInvariante))
  else
    vDigitos := SomenteDigitos(VarToStr(AValor));

  if (Length(vDigitos) in [12, 13]) and (Copy(vDigitos, 1, 2) = '55') then
    Delete(vDigitos, 1, 2)
  else if (Length(vDigitos) in [11, 12]) and (vDigitos[1] = '0') and (vDigitos[2] <> '0') then
    Delete(vDigitos, 1, 1);

  case Length(vDigitos) of
    1..9:
      ANumero := vDigitos;
    10, 11:
      begin
        ADdd := Copy(vDigitos, 1, 2);
        ANumero := Copy(vDigitos, 3, MaxInt);
        // 00 nas planilhas = DDD desconhecido
        if ADdd = '00' then
          ADdd := ''
        // DDDs do Brasil vão de 11 a 99 e não têm zero
        else if (ADdd[1] = '0') or (ADdd[2] = '0') then
          Exit;
      end;
  else
    Exit;
  end;
  Result := True;
end;

// Telefone só com zeros (00 0000-0000, (00) 00000-0000...) é usado nas planilhas para "sem telefone"
function TelefoneZerado(const AValor: Variant): Boolean;
var
  vDigitos: string;
begin
  if EhNumero(AValor) then
    Result := Double(AValor) = 0
  else
  begin
    vDigitos := SomenteDigitos(VarToStr(AValor));
    Result := (vDigitos <> '') and (StringReplace(vDigitos, '0', '', [rfReplaceAll]) = '');
  end;
end;

// Regra pedida pelo usuário para telefones: sem DDD, DDD 00 ou telefone inválido = em branco, nunca erro
function ExtrairDdd(const AValor: Variant): TResultadoTransformacao;
var
  vDdd, vNumero: string;
begin
  if EhVazio(AValor) or TelefoneZerado(AValor) then
    Exit(Ok(Null));
  if not SepararTelefone(AValor, vDdd, vNumero) or (vDdd = '') then
    Exit(Ok(Null));
  Result := Ok(vDdd);
end;

function ExtrairTelefoneSemDdd(const AValor: Variant; const AParametro: string): TResultadoTransformacao;
var
  vDdd, vNumero: string;
  vFormatar: Boolean;
begin
  if Trim(AParametro) = '' then
    vFormatar := False
  else if SameText(Trim(AParametro), 'FORMATADO') then
    vFormatar := True
  else
    Exit(Erro(Format('Parâmetro "%s" inválido para telefone sem DDD (use vazio ou FORMATADO).', [AParametro])));

  if EhVazio(AValor) or TelefoneZerado(AValor) then
    Exit(Ok(Null));
  if not SepararTelefone(AValor, vDdd, vNumero) then
    Exit(Ok(Null));

  // O DDD só sai quando há mais de 9 dígitos (SepararTelefone); com menos o número fica como veio
  if vFormatar and (Length(vNumero) >= 8) then
    // 8 dígitos: 3343-1342; 9 dígitos: 99999-9999
    vNumero := Copy(vNumero, 1, Length(vNumero) - 4) + '-' + Copy(vNumero, Length(vNumero) - 3, 4);
  Result := Ok(vNumero);
end;

function ParteTexto(const AValor: Variant; const AParametro: string): TResultadoTransformacao;
var
  vTextoInicio, vTextoQuantidade: string;
  vInicio, vQuantidade: Integer;
begin
  DividirNaPrimeira(Trim(AParametro), ',', vTextoInicio, vTextoQuantidade);
  if not TryStrToInt(Trim(vTextoInicio), vInicio) or (vInicio < 1) then
    Exit(Erro(Format('Parâmetro "%s" inválido para parte do texto: informe início,quantidade ' +
      '(início a partir de 1, ex.: 1,3).', [AParametro])));
  if Trim(vTextoQuantidade) = '' then
    vQuantidade := MaxInt
  else if not TryStrToInt(Trim(vTextoQuantidade), vQuantidade) or (vQuantidade < 1) then
    Exit(Erro(Format('Parâmetro "%s" inválido para parte do texto: a quantidade deve ser maior que zero.',
      [AParametro])));

  if VarIsNull(AValor) or VarIsEmpty(AValor) then
    Exit(Ok(Null));
  Result := Ok(Copy(ValorParaTexto(AValor), vInicio, vQuantidade));
end;

function ColunasDoModelo(const AModelo: string): TArray<string>;
var
  vInicio, vFim, i: Integer;
  vNome: string;
  vRepetido: Boolean;
begin
  Result := nil;
  vInicio := Pos('{', AModelo);
  while vInicio > 0 do
  begin
    vFim := Pos('}', AModelo, vInicio + 1);
    if vFim = 0 then
      Break;
    vNome := Trim(Copy(AModelo, vInicio + 1, vFim - vInicio - 1));
    if (vNome <> '') and not SameText(vNome, 'valor') then
    begin
      vRepetido := False;
      for i := 0 to High(Result) do
        if SameText(Result[i], vNome) then
          vRepetido := True;
      if not vRepetido then
        Result := Result + [vNome];
    end;
    vInicio := Pos('{', AModelo, vFim + 1);
  end;
end;

function Concatenar(const AValor: Variant; const AParametro: string;
  AObterColuna: TObterValorColuna): TResultadoTransformacao;
var
  vResultado, vNome: string;
  vInicio, vFim: Integer;
  vValorColuna: Variant;
begin
  if Trim(AParametro) = '' then
    Exit(Erro('Informe o modelo da concatenação, ex.: {valor} - {Nome da coluna}.'));

  vResultado := '';
  vInicio := 1;
  while vInicio <= Length(AParametro) do
  begin
    if AParametro[vInicio] = '{' then
    begin
      vFim := Pos('}', AParametro, vInicio + 1);
      if vFim = 0 then
        Exit(Erro(Format('Modelo de concatenação inválido: falta "}" em "%s".', [AParametro])));
      vNome := Trim(Copy(AParametro, vInicio + 1, vFim - vInicio - 1));
      if SameText(vNome, 'valor') then
        vResultado := vResultado + ValorParaTexto(AValor)
      else
      begin
        if not Assigned(AObterColuna) then
          Exit(Erro(Format('A coluna "%s" não está disponível para a concatenação.', [vNome])));
        if not AObterColuna(vNome, vValorColuna) then
          Exit(Erro(Format('A coluna "%s" usada na concatenação não existe na planilha.', [vNome])));
        vResultado := vResultado + ValorParaTexto(vValorColuna);
      end;
      vInicio := vFim + 1;
    end
    else
    begin
      vResultado := vResultado + AParametro[vInicio];
      Inc(vInicio);
    end;
  end;
  Result := Ok(vResultado);
end;

function ArredondarComercial(AValor: Double; ACasas: Integer): Double;
var
  vFator, vEscalado: Double;
begin
  // 0,5 para cima (longe do zero), não o bancário. 2,345 em binário é 2,34499999...; limpar o ruído
  // para 15 dígitos significativos antes de arredondar evita 2,345 -> 2,34
  vFator := IntPower(10, ACasas);
  vEscalado := Abs(AValor) * vFator;
  vEscalado := StrToFloat(FloatToStrF(vEscalado, ffGeneral, 15, 0, GFormatoInvariante), GFormatoInvariante);
  Result := Int(vEscalado + 0.5) / vFator;
  if AValor < 0 then
    Result := -Result;
end;

function Arredondar(const AValor: Variant; const AParametro: string): TResultadoTransformacao;
var
  vCasas: Integer;
  vNumero: Double;
begin
  if Trim(AParametro) = '' then
    vCasas := 2
  else if not TryStrToInt(Trim(AParametro), vCasas) or (vCasas < 0) or (vCasas > 10) then
    Exit(Erro(Format('Parâmetro "%s" inválido para arredondar (informe as casas decimais, de 0 a 10).',
      [AParametro])));

  if EhVazio(AValor) then
    Exit(Ok(Null));
  if EhNumero(AValor) then
    vNumero := AValor
  else if not TextoParaNumero(VarToStr(AValor), True, vNumero) then
    Exit(Erro(Format('"%s" não é um número para arredondar.', [VarToStr(AValor)])));

  Result := Ok(ArredondarComercial(vNumero, vCasas));
end;

function DePara(const AValor: Variant; const AParametro: string): TResultadoTransformacao;
var
  vItens: TArray<string>;
  vItem, vTexto, vSenao, vDe, vPara: string;
  vTemSenao: Boolean;
begin
  if Trim(AParametro) = '' then
    Exit(Erro('Informe os pares do de-para, ex.: JURIDICA=J;FISICA=F;*=F.'));

  vTexto := Trim(ValorParaTexto(AValor));
  vTemSenao := False;
  vSenao := '';
  vItens := AParametro.Split([';']);
  for vItem in vItens do
  begin
    if Trim(vItem) = '' then
      Continue;
    if not DividirNaPrimeira(vItem, '=', vDe, vPara) then
      Exit(Erro(Format('Item "%s" do de-para inválido (use de=para).', [Trim(vItem)])));
    if Trim(vDe) = '*' then
    begin
      vTemSenao := True;
      vSenao := vPara;
    end
    else if SameText(Trim(vDe), vTexto) then
      Exit(Ok(vPara));
  end;

  if vTemSenao then
    Result := Ok(vSenao)
  else
    Result := Erro(Format('"%s" não está previsto no de-para (%s).', [vTexto, AParametro]));
end;

function Transformar(ATipo: TTipoTransformacao; const AValor: Variant; const AParametro: string;
  AObterColuna: TObterValorColuna): TResultadoTransformacao;
begin
  case ATipo of
    ttTextoParaInteiro:
      Result := ConverterInteiro(AValor);
    ttTextoParaDecimal:
      Result := ConverterDecimal(AValor, AParametro);
    ttTextoParaData:
      Result := ConverterData(AValor, AParametro);
    ttTextoParaDataHora:
      Result := ConverterDataHora(AValor, AParametro);
    ttTextoParaBooleano:
      Result := ConverterBooleano(AValor, AParametro);
    ttRemoverEspacos:
      Result := RemoverEspacos(AValor, AParametro);
    ttMaiusculas:
      if VarIsNull(AValor) or VarIsEmpty(AValor) then
        Result := Ok(Null)
      else
        Result := Ok(AnsiUpperCase(ValorParaTexto(AValor)));
    ttMinusculas:
      if VarIsNull(AValor) or VarIsEmpty(AValor) then
        Result := Ok(Null)
      else
        Result := Ok(AnsiLowerCase(ValorParaTexto(AValor)));
    ttSomenteDigitos:
      if EhVazio(AValor) then
        Result := Ok(Null)
      else if EhNumero(AValor) then
        Result := Ok(SomenteDigitos(FormatFloat('0', Double(AValor), GFormatoInvariante)))
      else
        Result := Ok(SomenteDigitos(VarToStr(AValor)));
    ttDdd:
      Result := ExtrairDdd(AValor);
    ttTelefoneSemDdd:
      Result := ExtrairTelefoneSemDdd(AValor, AParametro);
    ttParteTexto:
      Result := ParteTexto(AValor, AParametro);
    ttCpfCnpj:
      Result := ConverterCpfCnpj(AValor, AParametro);
    ttConcatenar:
      Result := Concatenar(AValor, AParametro, AObterColuna);
    ttArredondar:
      Result := Arredondar(AValor, AParametro);
    ttDePara:
      Result := DePara(AValor, AParametro);
    ttVazioParaNulo:
      if EhVazio(AValor) then
        Result := Ok(Null)
      else
        Result := Ok(AValor);
  else
    Result := Erro('Transformação desconhecida.');
  end;
end;

function AplicarTransformacoes(const ALista: TArray<TTransformacao>; const AValor: Variant;
  AObterColuna: TObterValorColuna): TResultadoTransformacao;
var
  vTransformacao: TTransformacao;
begin
  Result := Ok(AValor);
  for vTransformacao in ALista do
  begin
    Result := Transformar(vTransformacao.Tipo, Result.Valor, vTransformacao.Parametro, AObterColuna);
    if not Result.Sucesso then
    begin
      Result.Mensagem := cTRANSFORMACOES[vTransformacao.Tipo].Nome + ': ' + Result.Mensagem;
      Exit;
    end;
  end;
end;

function TipoPorCodigo(const ACodigo: string; out ATipo: TTipoTransformacao): Boolean;
var
  vTipo: TTipoTransformacao;
begin
  for vTipo := Low(TTipoTransformacao) to High(TTipoTransformacao) do
    if SameText(cTRANSFORMACOES[vTipo].Codigo, Trim(ACodigo)) then
    begin
      ATipo := vTipo;
      Exit(True);
    end;
  Result := False;
end;

function TransformacoesParaTexto(const ALista: TArray<TTransformacao>): string;
var
  vTransformacao: TTransformacao;
begin
  Result := '';
  for vTransformacao in ALista do
  begin
    if Result <> '' then
      Result := Result + sLineBreak;
    Result := Result + cTRANSFORMACOES[vTransformacao.Tipo].Codigo + '|' + vTransformacao.Parametro;
  end;
end;

function TextoParaTransformacoes(const ATexto: string): TArray<TTransformacao>;
var
  vLinha, vCodigo, vParametro: string;
  vTransformacao: TTransformacao;
begin
  Result := nil;
  for vLinha in ATexto.Split([#13#10, #10]) do
  begin
    if Trim(vLinha) = '' then
      Continue;
    DividirNaPrimeira(vLinha, '|', vCodigo, vParametro);
    if not TipoPorCodigo(vCodigo, vTransformacao.Tipo) then
      raise Exception.CreateFmt('Transformação "%s" desconhecida.', [Trim(vCodigo)]);
    vTransformacao.Parametro := vParametro;
    Result := Result + [vTransformacao];
  end;
end;

initialization
  GFormatoInvariante := TFormatSettings.Invariant;

end.
