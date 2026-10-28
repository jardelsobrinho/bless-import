unit uLeitorXls;

{ Leitura de planilhas .xls/.xlsx com o DevExpress TdxSpreadSheet (só leitura, sem tela).
  Linhas são numeradas como no Excel (1 = primeira linha); colunas a partir de 0 (0 = coluna A).
  O arquivo inteiro é carregado em memória: planilhas de ~50 MB levam ~1,5 min e ~800 MB de RAM. }

interface

uses
  System.SysUtils, System.Classes, System.Variants, dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetTypes,
  dxSpreadSheetCoreStyles, dxSpreadSheetFormatXLS, dxSpreadSheetFormatXLSX, dxHashUtils;

type
  TTipoCelula = (tcVazia, tcTexto, tcNumero, tcData, tcBooleano, tcErro);

  TCelula = record
    Tipo: TTipoCelula;
    Valor: Variant;   // string, Double, TDateTime ou Boolean conforme o Tipo; Null quando vazia
    Texto: string;    // texto como o Excel exibe (formatado)
  end;

  TColunaPlanilha = record
    Indice: Integer;
    Letra: string;
    Nome: string;
    Tipo: string;     // tipo inferido pela amostra: Texto, Inteiro, Decimal, Data, Booleano, Vazia
    Exemplo: string;        // primeiro valor não vazio da amostra, como o Excel exibe
    ExemploValor: Variant;  // o mesmo valor tipado (Null se a coluna está vazia)
  end;

  TLeitorXls = class
  private
    FPlanilha: TdxSpreadSheet;
    FAba: TdxSpreadSheetTableView;
    FArquivo: string;
    FLinhaCabecalho: Integer;
    FLinhaInicial: Integer;
    procedure VerificarAba;
    function InferirTipo(AColuna, AAmostra: Integer; out AExemplo: TCelula): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Abrir(const AArquivo: string);
    function Abas: TArray<string>;
    procedure SelecionarAba(AIndice: Integer);
    function UltimaLinha: Integer;
    function QuantidadeColunas: Integer;
    function Celula(ALinha, AColuna: Integer): TCelula;
    function LinhaVazia(ALinha: Integer): Boolean;
    function Colunas(AAmostra: Integer = 200): TArray<TColunaPlanilha>;
    class function LetraColuna(AIndice: Integer): string; static;
    property Arquivo: string read FArquivo;
    property LinhaCabecalho: Integer read FLinhaCabecalho write FLinhaCabecalho;  // 0 = sem cabeçalho
    property LinhaInicial: Integer read FLinhaInicial write FLinhaInicial;
  end;

implementation

constructor TLeitorXls.Create;
begin
  inherited Create;
  FPlanilha := TdxSpreadSheet.Create(nil);
  FLinhaCabecalho := 1;
  FLinhaInicial := 2;
end;

destructor TLeitorXls.Destroy;
begin
  FPlanilha.Free;
  inherited;
end;

procedure TLeitorXls.Abrir(const AArquivo: string);
begin
  if not FileExists(AArquivo) then
    raise Exception.CreateFmt('Arquivo não encontrado: %s', [AArquivo]);

  FAba := nil;
  FArquivo := '';
  try
    FPlanilha.LoadFromFile(AArquivo);
  except
    on E: Exception do
      raise Exception.CreateFmt('Não foi possível abrir a planilha "%s": %s', [ExtractFileName(AArquivo), E.Message]);
  end;
  FArquivo := AArquivo;

  if Length(Abas) = 0 then
    raise Exception.CreateFmt('A planilha "%s" não tem abas com dados.', [ExtractFileName(AArquivo)]);
  SelecionarAba(0);
end;

function TLeitorXls.Abas: TArray<string>;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to FPlanilha.SheetCount - 1 do
    if FPlanilha.Sheets[i] is TdxSpreadSheetTableView then
      Result := Result + [FPlanilha.Sheets[i].Caption];
end;

procedure TLeitorXls.SelecionarAba(AIndice: Integer);
var
  i, vIndiceTabela: Integer;
begin
  // AIndice conta só as abas de tabela (mesma ordem de Abas)
  vIndiceTabela := -1;
  for i := 0 to FPlanilha.SheetCount - 1 do
    if FPlanilha.Sheets[i] is TdxSpreadSheetTableView then
    begin
      Inc(vIndiceTabela);
      if vIndiceTabela = AIndice then
      begin
        FAba := TdxSpreadSheetTableView(FPlanilha.Sheets[i]);
        Exit;
      end;
    end;
  raise Exception.CreateFmt('Aba %d não existe na planilha.', [AIndice]);
end;

procedure TLeitorXls.VerificarAba;
begin
  if FAba = nil then
    raise Exception.Create('Nenhuma planilha aberta.');
end;

function TLeitorXls.UltimaLinha: Integer;
begin
  VerificarAba;
  if FAba.Dimensions.Bottom < 0 then
    Result := 0
  else
    Result := FAba.Dimensions.Bottom + 1;
end;

function TLeitorXls.QuantidadeColunas: Integer;
begin
  VerificarAba;
  if FAba.Dimensions.Right < 0 then
    Result := 0
  else
    Result := FAba.Dimensions.Right + 1;
end;

function TLeitorXls.Celula(ALinha, AColuna: Integer): TCelula;
var
  vCel: TdxSpreadSheetCell;
  vValor: Variant;
begin
  VerificarAba;
  Result.Tipo := tcVazia;
  Result.Valor := Null;
  Result.Texto := '';

  if (ALinha < 1) or (AColuna < 0) then
    Exit;
  vCel := FAba.Cells[ALinha - 1, AColuna];
  if vCel = nil then
    Exit;

  case vCel.DataType of
    cdtBlank:
      Exit;
    cdtString:
      begin
        if Trim(vCel.AsString) = '' then
          Exit;
        Result.Tipo := tcTexto;
        Result.Valor := vCel.AsString;
      end;
    cdtBoolean:
      begin
        Result.Tipo := tcBooleano;
        Result.Valor := vCel.AsBoolean;
      end;
    cdtError:
      Result.Tipo := tcErro;
    cdtDateTime:
      begin
        Result.Tipo := tcData;
        Result.Valor := vCel.AsDateTime;
      end;
    cdtInteger, cdtFloat, cdtCurrency:
      // No .xls a data é um número com formato de data
      if vCel.StyleHandle.DataFormat.IsDateTime then
      begin
        Result.Tipo := tcData;
        Result.Valor := vCel.AsDateTime;
      end
      else
      begin
        Result.Tipo := tcNumero;
        Result.Valor := vCel.AsFloat;
      end;
    cdtFormula:
      begin
        // Usa o resultado já calculado da fórmula; classifica pelo tipo do valor
        vValor := vCel.AsVariant;
        case VarType(vValor) and varTypeMask of
          varEmpty, varNull:
            Exit;
          varBoolean:
            Result.Tipo := tcBooleano;
          varDate:
            Result.Tipo := tcData;
          varSmallint, varInteger, varSingle, varDouble, varCurrency, varShortInt, varByte, varWord,
          varLongWord, varInt64, varUInt64:
            if vCel.StyleHandle.DataFormat.IsDateTime then
            begin
              Result.Tipo := tcData;
              vValor := VarAsType(vValor, varDate);
            end
            else
              Result.Tipo := tcNumero;
        else
          if Trim(VarToStr(vValor)) = '' then
            Exit;
          Result.Tipo := tcTexto;
        end;
        Result.Valor := vValor;
      end;
  end;

  Result.Texto := vCel.DisplayText;
end;

function TLeitorXls.LinhaVazia(ALinha: Integer): Boolean;
var
  c: Integer;
begin
  for c := 0 to QuantidadeColunas - 1 do
    if Celula(ALinha, c).Tipo <> tcVazia then
      Exit(False);
  Result := True;
end;

function TLeitorXls.InferirTipo(AColuna, AAmostra: Integer; out AExemplo: TCelula): string;
var
  vLinha, vUltima, vLidas: Integer;
  vCelula: TCelula;
  vTemTexto, vTemNumero, vTemDecimal, vTemData, vTemBooleano: Boolean;
begin
  AExemplo.Tipo := tcVazia;
  AExemplo.Valor := Null;
  AExemplo.Texto := '';
  vTemTexto := False;
  vTemNumero := False;
  vTemDecimal := False;
  vTemData := False;
  vTemBooleano := False;

  vLidas := 0;
  vLinha := FLinhaInicial;
  vUltima := UltimaLinha;
  while (vLinha <= vUltima) and (vLidas < AAmostra) do
  begin
    vCelula := Celula(vLinha, AColuna);
    if vCelula.Tipo <> tcVazia then
    begin
      Inc(vLidas);
      if AExemplo.Tipo = tcVazia then
        AExemplo := vCelula;
      case vCelula.Tipo of
        tcTexto, tcErro:
          vTemTexto := True;
        tcNumero:
          begin
            vTemNumero := True;
            if Frac(Double(vCelula.Valor)) <> 0 then
              vTemDecimal := True;
          end;
        tcData:
          vTemData := True;
        tcBooleano:
          vTemBooleano := True;
      end;
    end;
    Inc(vLinha);
  end;

  if vLidas = 0 then
    Result := 'Vazia'
  else if vTemTexto or (Ord(vTemNumero) + Ord(vTemData) + Ord(vTemBooleano) > 1) then
    Result := 'Texto'
  else if vTemData then
    Result := 'Data'
  else if vTemBooleano then
    Result := 'Booleano'
  else if vTemDecimal then
    Result := 'Decimal'
  else
    Result := 'Inteiro';
end;

function TLeitorXls.Colunas(AAmostra: Integer): TArray<TColunaPlanilha>;
var
  c, vRepeticao: Integer;
  vExemplo: TCelula;
  vNome, vNomeBase: string;
  vNomes: TStringList;
begin
  VerificarAba;
  SetLength(Result, QuantidadeColunas);

  vNomes := TStringList.Create;
  try
    vNomes.CaseSensitive := False;
    for c := 0 to High(Result) do
    begin
      Result[c].Indice := c;
      Result[c].Letra := LetraColuna(c);

      vNomeBase := '';
      if FLinhaCabecalho > 0 then
        vNomeBase := Trim(Celula(FLinhaCabecalho, c).Texto);
      if vNomeBase = '' then
        vNomeBase := 'Coluna ' + Result[c].Letra;

      // Nomes repetidos ganham sufixo para continuarem únicos
      vNome := vNomeBase;
      vRepeticao := 1;
      while vNomes.IndexOf(vNome) >= 0 do
      begin
        Inc(vRepeticao);
        vNome := vNomeBase + ' (' + IntToStr(vRepeticao) + ')';
      end;
      vNomes.Add(vNome);
      Result[c].Nome := vNome;

      Result[c].Tipo := InferirTipo(c, AAmostra, vExemplo);
      Result[c].Exemplo := vExemplo.Texto;
      Result[c].ExemploValor := vExemplo.Valor;
    end;
  finally
    vNomes.Free;
  end;
end;

class function TLeitorXls.LetraColuna(AIndice: Integer): string;
var
  vIndice: Integer;
begin
  Result := '';
  vIndice := AIndice + 1;
  while vIndice > 0 do
  begin
    Result := Chr(Ord('A') + (vIndice - 1) mod 26) + Result;
    vIndice := (vIndice - 1) div 26;
  end;
end;

end.
