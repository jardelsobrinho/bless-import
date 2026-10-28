unit uTestTransformacoes;

interface

uses
  System.SysUtils, System.Variants, System.DateUtils, TestFramework, uTransformacoes;

type
  TTestTransformacoes = class(TTestCase)
  private
    function Aplicar(ATipo: TTipoTransformacao; const AValor: Variant; const AParametro: string = '';
      AObterColuna: TObterValorColuna = nil): TResultadoTransformacao;
    procedure VerificarOk(ATipo: TTipoTransformacao; const AValor: Variant; const AEsperado: Variant;
      const AParametro: string = '');
    procedure VerificarErro(ATipo: TTipoTransformacao; const AValor: Variant; const AParametro: string = '');
  published
    procedure TestInteiro;
    procedure TestInteiroErros;
    procedure TestDecimalBR;
    procedure TestDecimalUS;
    procedure TestDecimalErros;
    procedure TestData;
    procedure TestDataErros;
    procedure TestDataHora;
    procedure TestBooleano;
    procedure TestRemoverEspacos;
    procedure TestMaiusculasMinusculas;
    procedure TestSomenteDigitos;
    procedure TestDdd;
    procedure TestDddErros;
    procedure TestTelefoneSemDdd;
    procedure TestParteTexto;
    procedure TestParteTextoErros;
    procedure TestCpfCnpj;
    procedure TestCpfCnpjErros;
    procedure TestConcatenar;
    procedure TestArredondar;
    procedure TestDePara;
    procedure TestVazioParaNulo;
    procedure TestVazioPassaComoNulo;
    procedure TestListaEmOrdem;
    procedure TestListaParaComErro;
    procedure TestSerializacao;
    procedure TestNaoDependeDaMaquina;
  end;

implementation

function TTestTransformacoes.Aplicar(ATipo: TTipoTransformacao; const AValor: Variant;
  const AParametro: string; AObterColuna: TObterValorColuna): TResultadoTransformacao;
begin
  Result := Transformar(ATipo, AValor, AParametro, AObterColuna);
end;

procedure TTestTransformacoes.VerificarOk(ATipo: TTipoTransformacao; const AValor, AEsperado: Variant;
  const AParametro: string);
var
  vResultado: TResultadoTransformacao;
  vDescricao: string;
begin
  vResultado := Aplicar(ATipo, AValor, AParametro);
  vDescricao := Format('%s("%s", "%s")', [cTRANSFORMACOES[ATipo].Codigo, VarToStr(AValor), AParametro]);
  CheckTrue(vResultado.Sucesso, vDescricao + ' deveria funcionar: ' + vResultado.Mensagem);
  if VarIsNull(AEsperado) then
    CheckTrue(VarIsNull(vResultado.Valor), vDescricao + ' deveria ser nulo')
  else if VarIsFloat(AEsperado) then
  begin
    // Literal decimal pode chegar como Double ou Currency: compara sempre como número
    CheckTrue(VarIsNumeric(vResultado.Valor), vDescricao + ' deveria devolver um número');
    CheckEquals(Double(AEsperado), Double(vResultado.Valor), 0.0000001, vDescricao);
  end
  else if VarType(AEsperado) = varDate then
    CheckEquals(FormatDateTime('dd/mm/yyyy hh:nn:ss', AEsperado),
      FormatDateTime('dd/mm/yyyy hh:nn:ss', vResultado.Valor), vDescricao)
  else
    CheckEquals(VarToStr(AEsperado), VarToStr(vResultado.Valor), vDescricao);
end;

procedure TTestTransformacoes.VerificarErro(ATipo: TTipoTransformacao; const AValor: Variant;
  const AParametro: string);
var
  vResultado: TResultadoTransformacao;
begin
  vResultado := Aplicar(ATipo, AValor, AParametro);
  CheckFalse(vResultado.Sucesso, Format('%s("%s", "%s") deveria dar erro, mas devolveu "%s"',
    [cTRANSFORMACOES[ATipo].Codigo, VarToStr(AValor), AParametro, VarToStr(vResultado.Valor)]));
  CheckNotEquals('', vResultado.Mensagem, 'O erro precisa ter mensagem');
end;

procedure TTestTransformacoes.TestInteiro;
begin
  VerificarOk(ttTextoParaInteiro, '0010', 10);
  VerificarOk(ttTextoParaInteiro, ' 25 ', 25);
  VerificarOk(ttTextoParaInteiro, '-3', -3);
  VerificarOk(ttTextoParaInteiro, '1.234', 1234);
  VerificarOk(ttTextoParaInteiro, 42.0, 42);
  VerificarOk(ttTextoParaInteiro, '15,00', 15);
end;

procedure TTestTransformacoes.TestInteiroErros;
begin
  VerificarErro(ttTextoParaInteiro, '12,5');
  VerificarErro(ttTextoParaInteiro, 12.5);
  VerificarErro(ttTextoParaInteiro, 'ABC');
  VerificarErro(ttTextoParaInteiro, '12A');
end;

procedure TTestTransformacoes.TestDecimalBR;
begin
  VerificarOk(ttTextoParaDecimal, '1.234,56', 1234.56);
  VerificarOk(ttTextoParaDecimal, '601,21', 601.21);
  VerificarOk(ttTextoParaDecimal, 'R$ 12.955,92', 12955.92);
  VerificarOk(ttTextoParaDecimal, '1.000.000', 1000000.0);
  VerificarOk(ttTextoParaDecimal, '-15,5', -15.5);
  VerificarOk(ttTextoParaDecimal, '(15,5)', -15.5);
  VerificarOk(ttTextoParaDecimal, '15,5-', -15.5);
  VerificarOk(ttTextoParaDecimal, ',5', 0.5);
  VerificarOk(ttTextoParaDecimal, 601.21, 601.21, 'BR');
end;

procedure TTestTransformacoes.TestDecimalUS;
begin
  VerificarOk(ttTextoParaDecimal, '1,234.56', 1234.56, 'US');
  VerificarOk(ttTextoParaDecimal, '601.21', 601.21, 'US');
end;

procedure TTestTransformacoes.TestDecimalErros;
begin
  // No formato BR, "601.21" é ambíguo (milhar mal formado): erro em vez de virar 60121
  VerificarErro(ttTextoParaDecimal, '601.21');
  VerificarErro(ttTextoParaDecimal, '1,2,3');
  VerificarErro(ttTextoParaDecimal, '12.34,5');
  VerificarErro(ttTextoParaDecimal, 'dez reais');
  VerificarErro(ttTextoParaDecimal, '1.234,56', 'XX');
end;

procedure TTestTransformacoes.TestData;
begin
  VerificarOk(ttTextoParaData, '15/09/2014', EncodeDate(2014, 9, 15));
  VerificarOk(ttTextoParaData, '1/2/2020', EncodeDate(2020, 2, 1));
  VerificarOk(ttTextoParaData, '15/09/14', EncodeDate(2014, 9, 15), 'DD/MM/AA');
  VerificarOk(ttTextoParaData, '15/09/98', EncodeDate(1998, 9, 15), 'DD/MM/AA');
  VerificarOk(ttTextoParaData, '2014-09-15', EncodeDate(2014, 9, 15), 'AAAA-MM-DD');
  VerificarOk(ttTextoParaData, '15092014', EncodeDate(2014, 9, 15), 'DDMMAAAA');
  VerificarOk(ttTextoParaData, '20140915', EncodeDate(2014, 9, 15), 'AAAAMMDD');
  // Data que já vem da planilha como data: mantém só a data
  VerificarOk(ttTextoParaData, VarFromDateTime(EncodeDateTime(2014, 9, 15, 10, 30, 0, 0)),
    VarFromDateTime(EncodeDate(2014, 9, 15)));
end;

procedure TTestTransformacoes.TestDataErros;
begin
  VerificarErro(ttTextoParaData, '31/02/2020');
  VerificarErro(ttTextoParaData, '15/13/2020');
  VerificarErro(ttTextoParaData, '2014-09-15');
  VerificarErro(ttTextoParaData, '15/09/14');
  VerificarErro(ttTextoParaData, 'ontem');
  // Número não vira data sem configuração explícita
  VerificarErro(ttTextoParaData, 41897.0);
end;

procedure TTestTransformacoes.TestDataHora;
begin
  VerificarOk(ttTextoParaDataHora, '24/02/2021 16:44', EncodeDateTime(2021, 2, 24, 16, 44, 0, 0));
  VerificarOk(ttTextoParaDataHora, '24/02/2021 16:44:30', EncodeDateTime(2021, 2, 24, 16, 44, 30, 0));
  VerificarOk(ttTextoParaDataHora, '24/02/2021', EncodeDateTime(2021, 2, 24, 0, 0, 0, 0));
  VerificarErro(ttTextoParaDataHora, '24/02/2021 25:00');
  VerificarErro(ttTextoParaDataHora, '24/02/2021 16h44');
end;

procedure TTestTransformacoes.TestBooleano;
begin
  VerificarOk(ttTextoParaBooleano, 'Sim', 'S');
  VerificarOk(ttTextoParaBooleano, 'n', 'N');
  VerificarOk(ttTextoParaBooleano, 'Não', 'N');
  VerificarOk(ttTextoParaBooleano, 'S', 'T', 'T/F');
  VerificarOk(ttTextoParaBooleano, 'N', 'F', 'T/F');
  VerificarOk(ttTextoParaBooleano, 1.0, 'S');
  VerificarOk(ttTextoParaBooleano, True, '1', '1/0');
  VerificarErro(ttTextoParaBooleano, 'TALVEZ');
  VerificarErro(ttTextoParaBooleano, 'S', 'SN');
end;

procedure TTestTransformacoes.TestRemoverEspacos;
begin
  VerificarOk(ttRemoverEspacos, '  RUA   DAS  FLORES  ', 'RUA DAS FLORES');
  VerificarOk(ttRemoverEspacos, '69 990 000', '69990000', 'TODOS');
  VerificarErro(ttRemoverEspacos, 'X', 'ALGUNS');
end;

procedure TTestTransformacoes.TestMaiusculasMinusculas;
begin
  VerificarOk(ttMaiusculas, 'Algodão', 'ALGODÃO');
  VerificarOk(ttMinusculas, 'COMERCIAL@HOTMAIL.COM', 'comercial@hotmail.com');
end;

procedure TTestTransformacoes.TestSomenteDigitos;
begin
  VerificarOk(ttSomenteDigitos, '69.990-000', '69990000');
  VerificarOk(ttSomenteDigitos, '68 3343-1342', '6833431342');
end;

procedure TTestTransformacoes.TestDdd;
begin
  // Formatos encontrados em CLIENTES F11.xls
  VerificarOk(ttDdd, '68 3343-1342', '68');
  VerificarOk(ttDdd, '(68)3343-1342', '68');
  VerificarOk(ttDdd, '(97)99999-9999', '97');
  VerificarOk(ttDdd, '(19)9 9672 1169', '19');
  VerificarOk(ttDdd, '6833431342', '68');
  VerificarOk(ttDdd, '68-3343-1342', '68');
  VerificarOk(ttDdd, '031 3333 4444', '31');
  VerificarOk(ttDdd, '+55 68 3343-1342', '68');
  VerificarOk(ttDdd, '+55 (11) 98765-4321', '11');
  // DDD 55 (RS) não é confundido com o código do país
  VerificarOk(ttDdd, '55 3333-4444', '55');
  VerificarOk(ttDdd, 6833431342.0, '68');
  VerificarOk(ttDdd, '', Null);
  // Telefone zerado = "sem telefone": vazio, não erro
  VerificarOk(ttDdd, '00 0000-0000', Null);
  VerificarOk(ttDdd, '(00) 00000-0000', Null);
  VerificarOk(ttDdd, '0000-0000', Null);
  VerificarOk(ttDdd, 0.0, Null);
end;

procedure TTestTransformacoes.TestDddErros;
begin
  // Até 9 dígitos não há DDD: fica em branco (não é erro)
  VerificarOk(ttDdd, '3343-1342', Null);
  VerificarOk(ttDdd, '9 9999 9999', Null);
  VerificarOk(ttDdd, '(75)343 2578', Null);
  VerificarOk(ttDdd, '123', Null);
  // DDD 00 = sem DDD
  VerificarOk(ttDdd, '00 3343-1342', Null);
  VerificarOk(ttDdd, '0036423119', Null);
  VerificarOk(ttDdd, '00 99999 8888', Null);
  // Telefone inválido também fica em branco (regra pedida pelo usuário: nunca erro)
  VerificarOk(ttDdd, '(01) 3343-1342', Null);
  VerificarOk(ttDdd, '(10) 3343-1342', Null);
  VerificarOk(ttDdd, '94 98 8889 0763', Null);
  VerificarOk(ttDdd, 'sem telefone', Null);
end;

procedure TTestTransformacoes.TestTelefoneSemDdd;
begin
  VerificarOk(ttTelefoneSemDdd, '68 3343-1342', '33431342');
  VerificarOk(ttTelefoneSemDdd, '(97)99999-9999', '999999999');
  VerificarOk(ttTelefoneSemDdd, '(19)9 9672 1169', '996721169');
  VerificarOk(ttTelefoneSemDdd, '68 3343-1342', '3343-1342', 'FORMATADO');
  VerificarOk(ttTelefoneSemDdd, '(97)99999-8888', '99999-8888', 'FORMATADO');
  VerificarOk(ttTelefoneSemDdd, '+55 68 3343-1342', '33431342');
  // Até 9 dígitos o DDD não é removido: o número fica como veio (só os dígitos)
  VerificarOk(ttTelefoneSemDdd, '3343 1342', '33431342');
  VerificarOk(ttTelefoneSemDdd, '(75)343 2578', '753432578');
  VerificarOk(ttTelefoneSemDdd, '123', '123');
  VerificarOk(ttTelefoneSemDdd, '123', '123', 'FORMATADO');
  VerificarOk(ttTelefoneSemDdd, '3343 1342', '3343-1342', 'FORMATADO');
  VerificarOk(ttTelefoneSemDdd, '', Null);
  VerificarOk(ttTelefoneSemDdd, '00 0000-0000', Null);
  VerificarOk(ttTelefoneSemDdd, '00 0000-0000', Null, 'FORMATADO');
  VerificarOk(ttTelefoneSemDdd, '(00) 00000-0000', Null);
  // DDD 00 = sem DDD: sai o 00 e fica o número
  VerificarOk(ttTelefoneSemDdd, '00 2102-8800', '21028800');
  VerificarOk(ttTelefoneSemDdd, '00 2102-8800', '2102-8800', 'FORMATADO');
  VerificarOk(ttTelefoneSemDdd, '00 99999 8888', '999998888');
  // Inválido: em branco
  VerificarOk(ttTelefoneSemDdd, '94 98 8889 0763', Null);
  VerificarOk(ttTelefoneSemDdd, '(01) 3343-1342', Null);
  VerificarOk(ttTelefoneSemDdd, 'sem telefone', Null);
  // Parâmetro errado continua sendo erro de configuração
  VerificarErro(ttTelefoneSemDdd, '68 3343-1342', 'OUTRO');
end;

procedure TTestTransformacoes.TestParteTexto;
begin
  VerificarOk(ttParteTexto, 'ABCDEFGH', 'ABC', '1,3');
  VerificarOk(ttParteTexto, 'ABCDEFGH', 'DE', '4,2');
  VerificarOk(ttParteTexto, 'ABCDEFGH', 'EFGH', '5');
  VerificarOk(ttParteTexto, 'ABCDEFGH', 'GH', ' 7 , 10 ');
  VerificarOk(ttParteTexto, 'ABC', '', '5,2');
  VerificarOk(ttParteTexto, 'Algodão', 'Algod', '1,5');
  VerificarOk(ttParteTexto, '5597-FL RODRIGUES', 'FL RODRIGUES', '6');
  VerificarOk(ttParteTexto, Null, Null, '1,3');
end;

procedure TTestTransformacoes.TestParteTextoErros;
begin
  VerificarErro(ttParteTexto, 'ABC', '');
  VerificarErro(ttParteTexto, 'ABC', '0,2');
  VerificarErro(ttParteTexto, 'ABC', '1,0');
  VerificarErro(ttParteTexto, 'ABC', 'A,2');
  VerificarErro(ttParteTexto, 'ABC', '1,-1');
end;

procedure TTestTransformacoes.TestCpfCnpj;
begin
  // CNPJ real da planilha CLIENTES F11.xls
  VerificarOk(ttCpfCnpj, '12.194.177/0001-55', '12194177000155');
  VerificarOk(ttCpfCnpj, '12194177000155', '12.194.177/0001-55', 'FORMATADO');
  VerificarOk(ttCpfCnpj, '529.982.247-25', '52998224725');
  VerificarOk(ttCpfCnpj, '52998224725', '529.982.247-25', 'FORMATADO');
  VerificarOk(ttCpfCnpj, '12.194.177/0001-00', '12194177000100', 'SEM_VALIDAR');
end;

procedure TTestTransformacoes.TestCpfCnpjErros;
begin
  VerificarErro(ttCpfCnpj, '12.194.177/0001-00');
  VerificarErro(ttCpfCnpj, '111.111.111-11');
  VerificarErro(ttCpfCnpj, '123');
  VerificarErro(ttCpfCnpj, '12194177000155', 'OUTRO');
end;

procedure TTestTransformacoes.TestConcatenar;
var
  vResultado: TResultadoTransformacao;
  vColunas: TObterValorColuna;
begin
  vColunas :=
    function(const ANomeColuna: string; out AValor: Variant): Boolean
    begin
      Result := True;
      if SameText(ANomeColuna, 'Numero') then
        AValor := '1008'
      else if SameText(ANomeColuna, 'Bairro') then
        AValor := 'CENTRO'
      else
        Result := False;
    end;

  vResultado := Aplicar(ttConcatenar, 'AVENIDA JAPIM', '{valor}, {Numero} - {Bairro}', vColunas);
  CheckTrue(vResultado.Sucesso, vResultado.Mensagem);
  CheckEquals('AVENIDA JAPIM, 1008 - CENTRO', VarToStr(vResultado.Valor));

  vResultado := Aplicar(ttConcatenar, 'X', '{valor} {Inexistente}', vColunas);
  CheckFalse(vResultado.Sucesso, 'Coluna inexistente deveria dar erro');

  vResultado := Aplicar(ttConcatenar, 'X', '{valor', vColunas);
  CheckFalse(vResultado.Sucesso, 'Modelo sem "}" deveria dar erro');
end;

procedure TTestTransformacoes.TestArredondar;
begin
  VerificarOk(ttArredondar, 2.345, 2.35);
  VerificarOk(ttArredondar, 2.344, 2.34);
  VerificarOk(ttArredondar, '10,555', 10.56);
  VerificarOk(ttArredondar, 10.4, 10.0, '0');
  VerificarOk(ttArredondar, -2.345, -2.35);
  VerificarOk(ttArredondar, 1.005, 1.01);
  VerificarErro(ttArredondar, 'abc');
  VerificarErro(ttArredondar, 1.0, 'duas');
end;

procedure TTestTransformacoes.TestDePara;
begin
  VerificarOk(ttDePara, 'JURIDICA', 'J', 'JURIDICA=J;FISICA=F');
  VerificarOk(ttDePara, 'fisica', 'F', 'JURIDICA=J;FISICA=F');
  VerificarOk(ttDePara, 'OUTRO', 'F', 'JURIDICA=J;FISICA=F;*=F');
  // O "para" pode conter "=" (só a primeira ocorrência separa)
  VerificarOk(ttDePara, 'A', 'X=Y', 'A=X=Y');
  // Sem "*" e sem correspondência: erro, nunca um valor inventado
  VerificarErro(ttDePara, 'OUTRO', 'JURIDICA=J;FISICA=F');
  VerificarErro(ttDePara, 'X', 'JURIDICA');
end;

procedure TTestTransformacoes.TestVazioParaNulo;
begin
  VerificarOk(ttVazioParaNulo, '   ', Null);
  VerificarOk(ttVazioParaNulo, 'A', 'A');
end;

procedure TTestTransformacoes.TestVazioPassaComoNulo;
begin
  // Conversões de tipo não decidem o que fazer com vazio: devolvem nulo (o valor padrão do campo decide)
  VerificarOk(ttTextoParaInteiro, '', Null);
  VerificarOk(ttTextoParaDecimal, '  ', Null);
  VerificarOk(ttTextoParaData, Null, Null);
  VerificarOk(ttCpfCnpj, '', Null);
end;

procedure TTestTransformacoes.TestListaEmOrdem;
var
  vLista: TArray<TTransformacao>;
  vResultado: TResultadoTransformacao;
begin
  SetLength(vLista, 2);
  vLista[0].Tipo := ttRemoverEspacos;
  vLista[0].Parametro := '';
  vLista[1].Tipo := ttMaiusculas;
  vLista[1].Parametro := '';

  vResultado := AplicarTransformacoes(vLista, '  f l   rodrigues ');
  CheckTrue(vResultado.Sucesso, vResultado.Mensagem);
  CheckEquals('F L RODRIGUES', VarToStr(vResultado.Valor));
end;

procedure TTestTransformacoes.TestListaParaComErro;
var
  vLista: TArray<TTransformacao>;
  vResultado: TResultadoTransformacao;
begin
  SetLength(vLista, 2);
  vLista[0].Tipo := ttTextoParaDecimal;
  vLista[0].Parametro := 'BR';
  vLista[1].Tipo := ttArredondar;
  vLista[1].Parametro := '2';

  vResultado := AplicarTransformacoes(vLista, 'abc');
  CheckFalse(vResultado.Sucesso);
  CheckTrue(Pos('Texto para decimal', vResultado.Mensagem) = 1,
    'A mensagem deve dizer qual transformação falhou: ' + vResultado.Mensagem);
end;

procedure TTestTransformacoes.TestSerializacao;
var
  vLista, vLida: TArray<TTransformacao>;
  vTexto: string;
begin
  SetLength(vLista, 3);
  vLista[0].Tipo := ttCpfCnpj;
  vLista[0].Parametro := '';
  vLista[1].Tipo := ttDePara;
  vLista[1].Parametro := 'JURIDICA=J;FISICA=F;*=F';
  vLista[2].Tipo := ttConcatenar;
  vLista[2].Parametro := '{valor} | {Numero}';

  vTexto := TransformacoesParaTexto(vLista);
  vLida := TextoParaTransformacoes(vTexto);
  CheckEquals(3, Length(vLida));
  CheckTrue(vLida[0].Tipo = ttCpfCnpj);
  CheckEquals('', vLida[0].Parametro);
  CheckTrue(vLida[1].Tipo = ttDePara);
  CheckEquals('JURIDICA=J;FISICA=F;*=F', vLida[1].Parametro);
  CheckTrue(vLida[2].Tipo = ttConcatenar);
  CheckEquals('{valor} | {Numero}', vLida[2].Parametro);

  CheckEquals(0, Length(TextoParaTransformacoes('')));
  StartExpectingException(Exception);
  TextoParaTransformacoes('NAO_EXISTE|x');
  StopExpectingException;
end;

procedure TTestTransformacoes.TestNaoDependeDaMaquina;
var
  vOriginal: TFormatSettings;
begin
  // Mesmo com a máquina configurada em inglês, o formato BR continua igual
  vOriginal := FormatSettings;
  try
    FormatSettings.DecimalSeparator := '.';
    FormatSettings.ThousandSeparator := ',';
    FormatSettings.ShortDateFormat := 'mm/dd/yyyy';
    VerificarOk(ttTextoParaDecimal, '1.234,56', 1234.56);
    VerificarOk(ttTextoParaData, '02/03/2020', EncodeDate(2020, 3, 2));
    CheckEquals('1234,56', ValorParaTexto(1234.56));
  finally
    FormatSettings := vOriginal;
  end;
end;

initialization
  RegisterTest(TTestTransformacoes.Suite);

end.
