unit uPerfisDm;

interface

uses
  System.SysUtils, System.Classes, Data.DB, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, uPerfilModelo;

type
  TdmPerfis = class(TDataModule)
    qryPerfis: TFDQuery;
    dsPerfis: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    function NovaQuery: TFDQuery;
    procedure Validar(APerfil: TPerfil);
    function NomeDisponivel(const ANomeBase: string): string;
  public
    procedure Pesquisar;
    function IdSelecionado: Integer;
    // O chamador libera o perfil devolvido
    function Carregar(AId: Integer): TPerfil;
    procedure Gravar(APerfil: TPerfil);
    function Duplicar(AId: Integer): Integer;
    procedure Excluir(AId: Integer);
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  uDmConexao, uTransformacoes;

function SimNao(AValor: Boolean): string;
begin
  if AValor then
    Result := 'S'
  else
    Result := 'N';
end;

procedure TdmPerfis.DataModuleCreate(Sender: TObject);
begin
  qryPerfis.Connection := dmConexao.cnConexao;
end;

function TdmPerfis.NovaQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := dmConexao.cnConexao;
end;

procedure TdmPerfis.Pesquisar;
var
  vId: Integer;
begin
  vId := IdSelecionado;
  qryPerfis.Close;
  qryPerfis.Open;
  if vId > 0 then
    qryPerfis.Locate('ID', vId, []);
end;

function TdmPerfis.IdSelecionado: Integer;
begin
  if qryPerfis.Active and not qryPerfis.IsEmpty then
    Result := qryPerfis.FieldByName('ID').AsInteger
  else
    Result := 0;
end;

function TdmPerfis.Carregar(AId: Integer): TPerfil;
var
  vQry: TFDQuery;
  vCampo: TCampoPerfil;
  vOrigem: TOrigemValor;
begin
  Result := TPerfil.Create;
  try
    vQry := NovaQuery;
    try
      vQry.SQL.Text :=
        'select ID, NOME, DESCRICAO, ID_CONEXAO, TABELA_DESTINO, ARQUIVO_EXEMPLO, ABA, LINHA_CABECALHO, ' +
        'LINHA_INICIAL, ESTRATEGIA, CAMPOS_CHAVE, ACAO_ERRO, VERSAO, DATA_ALTERACAO ' +
        'from PERFIL where ID = :ID';
      vQry.ParamByName('ID').AsInteger := AId;
      vQry.Open;
      if vQry.IsEmpty then
        raise Exception.CreateFmt('Perfil %d não encontrado.', [AId]);

      Result.Id := vQry.FieldByName('ID').AsInteger;
      Result.Nome := vQry.FieldByName('NOME').AsString;
      Result.Descricao := vQry.FieldByName('DESCRICAO').AsString;
      Result.IdConexao := vQry.FieldByName('ID_CONEXAO').AsInteger;
      Result.TabelaDestino := vQry.FieldByName('TABELA_DESTINO').AsString;
      Result.ArquivoExemplo := vQry.FieldByName('ARQUIVO_EXEMPLO').AsString;
      Result.Aba := vQry.FieldByName('ABA').AsString;
      Result.LinhaCabecalho := vQry.FieldByName('LINHA_CABECALHO').AsInteger;
      Result.LinhaInicial := vQry.FieldByName('LINHA_INICIAL').AsInteger;
      Result.Estrategia := EstrategiaPorCodigo(vQry.FieldByName('ESTRATEGIA').AsString);
      Result.CamposChave := vQry.FieldByName('CAMPOS_CHAVE').AsString;
      Result.AcaoErro := AcaoErroPorCodigo(vQry.FieldByName('ACAO_ERRO').AsString);
      Result.Versao := vQry.FieldByName('VERSAO').AsInteger;
      Result.DataAlteracao := vQry.FieldByName('DATA_ALTERACAO').AsDateTime;

      vQry.Close;
      vQry.SQL.Text :=
        'select CAMPO_DESTINO, ORIGEM, COLUNA, VALOR_FIXO, VALOR_PADRAO, PADRAO_SE_INEXISTENTE, PADRAO_SE_VAZIO, ' +
        'PADRAO_SE_INVALIDO, GENERATOR, EXPRESSAO, CONSULTA_TABELA, CONSULTA_CAMPO_PESQUISA, ' +
        'CONSULTA_CAMPO_RETORNO, CONSULTA_SE_NAO_ACHAR, CONSULTA_SQL, TRANSFORMACOES ' +
        'from PERFIL_CAMPO where ID_PERFIL = :ID order by ORDEM';
      vQry.ParamByName('ID').AsInteger := AId;
      vQry.Open;
      while not vQry.Eof do
      begin
        if not OrigemPorCodigo(vQry.FieldByName('ORIGEM').AsString, vOrigem) then
          raise Exception.CreateFmt('Origem "%s" desconhecida no campo %s do perfil.',
            [vQry.FieldByName('ORIGEM').AsString, vQry.FieldByName('CAMPO_DESTINO').AsString]);

        vCampo := Result.AdicionarCampo(vQry.FieldByName('CAMPO_DESTINO').AsString);
        vCampo.Origem := vOrigem;
        vCampo.Coluna := vQry.FieldByName('COLUNA').AsString;
        vCampo.ValorFixo := vQry.FieldByName('VALOR_FIXO').AsString;
        vCampo.ValorPadrao := vQry.FieldByName('VALOR_PADRAO').AsString;
        vCampo.PadraoSeInexistente := vQry.FieldByName('PADRAO_SE_INEXISTENTE').AsString = 'S';
        vCampo.PadraoSeVazio := vQry.FieldByName('PADRAO_SE_VAZIO').AsString = 'S';
        vCampo.PadraoSeInvalido := vQry.FieldByName('PADRAO_SE_INVALIDO').AsString = 'S';
        vCampo.Generator := vQry.FieldByName('GENERATOR').AsString;
        vCampo.Expressao := vQry.FieldByName('EXPRESSAO').AsString;
        vCampo.ConsultaTabela := vQry.FieldByName('CONSULTA_TABELA').AsString;
        vCampo.ConsultaCampoPesquisa := vQry.FieldByName('CONSULTA_CAMPO_PESQUISA').AsString;
        vCampo.ConsultaCampoRetorno := vQry.FieldByName('CONSULTA_CAMPO_RETORNO').AsString;
        vCampo.ConsultaSeNaoAchar := AcaoNaoEncontradoPorCodigo(vQry.FieldByName('CONSULTA_SE_NAO_ACHAR').AsString);
        vCampo.ConsultaSql := vQry.FieldByName('CONSULTA_SQL').AsString;
        vCampo.Transformacoes := TextoParaTransformacoes(vQry.FieldByName('TRANSFORMACOES').AsString);
        vQry.Next;
      end;
    finally
      vQry.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TdmPerfis.Validar(APerfil: TPerfil);
var
  vQry: TFDQuery;
  vCampo: TCampoPerfil;
  vMensagem: string;
begin
  if Trim(APerfil.Nome) = '' then
    raise Exception.Create('Informe o nome do perfil.');
  if APerfil.IdConexao <= 0 then
    raise Exception.Create('Selecione a conexão de destino.');
  if Trim(APerfil.TabelaDestino) = '' then
    raise Exception.Create('Informe a tabela de destino.');
  if APerfil.LinhaCabecalho < 0 then
    raise Exception.Create('A linha do cabeçalho não pode ser negativa.');
  if APerfil.LinhaInicial <= APerfil.LinhaCabecalho then
    raise Exception.Create('A linha inicial dos dados deve ficar depois da linha do cabeçalho.');

  for vCampo in APerfil.CamposMapeados do
    if not vCampo.ValidarConfiguracao(vMensagem) then
      raise Exception.CreateFmt('Campo %s (%s): %s.', [vCampo.CampoDestino, cORIGENS[vCampo.Origem].Nome, vMensagem]);

  vQry := NovaQuery;
  try
    vQry.SQL.Text := 'select count(*) from PERFIL where upper(NOME) = upper(:NOME) and ID <> :ID';
    vQry.ParamByName('NOME').AsString := Trim(APerfil.Nome);
    vQry.ParamByName('ID').AsInteger := APerfil.Id;
    vQry.Open;
    if vQry.Fields[0].AsInteger > 0 then
      raise Exception.CreateFmt('Já existe um perfil com o nome "%s".', [Trim(APerfil.Nome)]);
  finally
    vQry.Free;
  end;
end;

procedure TdmPerfis.Gravar(APerfil: TPerfil);
var
  vQry: TFDQuery;
  vCampo: TCampoPerfil;
  vOrdem: Integer;
begin
  Validar(APerfil);

  vQry := NovaQuery;
  try
    dmConexao.StartTransaction;
    try
      if APerfil.Id = 0 then
        vQry.SQL.Text :=
          'insert into PERFIL (NOME, DESCRICAO, ID_CONEXAO, TABELA_DESTINO, ARQUIVO_EXEMPLO, ABA, LINHA_CABECALHO, ' +
          'LINHA_INICIAL, ESTRATEGIA, CAMPOS_CHAVE, ACAO_ERRO, VERSAO, DATA_ALTERACAO) ' +
          'values (:NOME, :DESCRICAO, :ID_CONEXAO, :TABELA_DESTINO, :ARQUIVO_EXEMPLO, :ABA, :LINHA_CABECALHO, ' +
          ':LINHA_INICIAL, :ESTRATEGIA, :CAMPOS_CHAVE, :ACAO_ERRO, 1, current_timestamp) ' +
          'returning ID, VERSAO, DATA_ALTERACAO'
      else
      begin
        vQry.SQL.Text :=
          'update PERFIL set NOME = :NOME, DESCRICAO = :DESCRICAO, ID_CONEXAO = :ID_CONEXAO, ' +
          'TABELA_DESTINO = :TABELA_DESTINO, ARQUIVO_EXEMPLO = :ARQUIVO_EXEMPLO, ABA = :ABA, ' +
          'LINHA_CABECALHO = :LINHA_CABECALHO, LINHA_INICIAL = :LINHA_INICIAL, ESTRATEGIA = :ESTRATEGIA, ' +
          'CAMPOS_CHAVE = :CAMPOS_CHAVE, ACAO_ERRO = :ACAO_ERRO, VERSAO = VERSAO + 1, ' +
          'DATA_ALTERACAO = current_timestamp ' +
          'where ID = :ID ' +
          'returning ID, VERSAO, DATA_ALTERACAO';
        vQry.ParamByName('ID').AsInteger := APerfil.Id;
      end;
      vQry.ParamByName('NOME').AsString := Trim(APerfil.Nome);
      vQry.ParamByName('DESCRICAO').AsString := Trim(APerfil.Descricao);
      vQry.ParamByName('ID_CONEXAO').AsInteger := APerfil.IdConexao;
      vQry.ParamByName('TABELA_DESTINO').AsString := UpperCase(Trim(APerfil.TabelaDestino));
      vQry.ParamByName('ARQUIVO_EXEMPLO').AsString := APerfil.ArquivoExemplo;
      vQry.ParamByName('ABA').AsString := APerfil.Aba;
      vQry.ParamByName('LINHA_CABECALHO').AsInteger := APerfil.LinhaCabecalho;
      vQry.ParamByName('LINHA_INICIAL').AsInteger := APerfil.LinhaInicial;
      vQry.ParamByName('ESTRATEGIA').AsString := cESTRATEGIAS[APerfil.Estrategia].Codigo;
      vQry.ParamByName('CAMPOS_CHAVE').AsString := APerfil.CamposChave;
      vQry.ParamByName('ACAO_ERRO').AsString := cACOES_ERRO[APerfil.AcaoErro].Codigo;
      vQry.Open;
      if vQry.IsEmpty then
        raise Exception.CreateFmt('Perfil %d não encontrado (foi excluído?).', [APerfil.Id]);
      APerfil.Id := vQry.FieldByName('ID').AsInteger;
      APerfil.Versao := vQry.FieldByName('VERSAO').AsInteger;
      APerfil.DataAlteracao := vQry.FieldByName('DATA_ALTERACAO').AsDateTime;
      vQry.Close;

      // Campos: apaga e grava de novo só os mapeados
      vQry.SQL.Text := 'delete from PERFIL_CAMPO where ID_PERFIL = :ID';
      vQry.ParamByName('ID').AsInteger := APerfil.Id;
      vQry.ExecSQL;

      vQry.SQL.Text :=
        'insert into PERFIL_CAMPO (ID_PERFIL, ORDEM, CAMPO_DESTINO, ORIGEM, COLUNA, VALOR_FIXO, VALOR_PADRAO, ' +
        'PADRAO_SE_INEXISTENTE, PADRAO_SE_VAZIO, PADRAO_SE_INVALIDO, GENERATOR, EXPRESSAO, CONSULTA_TABELA, ' +
        'CONSULTA_CAMPO_PESQUISA, CONSULTA_CAMPO_RETORNO, CONSULTA_SE_NAO_ACHAR, CONSULTA_SQL, TRANSFORMACOES) ' +
        'values (:ID_PERFIL, :ORDEM, :CAMPO_DESTINO, :ORIGEM, :COLUNA, :VALOR_FIXO, :VALOR_PADRAO, ' +
        ':PADRAO_SE_INEXISTENTE, :PADRAO_SE_VAZIO, :PADRAO_SE_INVALIDO, :GENERATOR, :EXPRESSAO, :CONSULTA_TABELA, ' +
        ':CONSULTA_CAMPO_PESQUISA, :CONSULTA_CAMPO_RETORNO, :CONSULTA_SE_NAO_ACHAR, :CONSULTA_SQL, :TRANSFORMACOES)';
      vOrdem := 0;
      for vCampo in APerfil.CamposMapeados do
      begin
        Inc(vOrdem);
        vQry.ParamByName('ID_PERFIL').AsInteger := APerfil.Id;
        vQry.ParamByName('ORDEM').AsInteger := vOrdem;
        vQry.ParamByName('CAMPO_DESTINO').AsString := vCampo.CampoDestino;
        vQry.ParamByName('ORIGEM').AsString := cORIGENS[vCampo.Origem].Codigo;
        vQry.ParamByName('COLUNA').AsString := vCampo.Coluna;
        vQry.ParamByName('VALOR_FIXO').AsString := vCampo.ValorFixo;
        vQry.ParamByName('VALOR_PADRAO').AsString := vCampo.ValorPadrao;
        vQry.ParamByName('PADRAO_SE_INEXISTENTE').AsString := SimNao(vCampo.PadraoSeInexistente);
        vQry.ParamByName('PADRAO_SE_VAZIO').AsString := SimNao(vCampo.PadraoSeVazio);
        vQry.ParamByName('PADRAO_SE_INVALIDO').AsString := SimNao(vCampo.PadraoSeInvalido);
        vQry.ParamByName('GENERATOR').AsString := vCampo.Generator;
        vQry.ParamByName('EXPRESSAO').AsString := vCampo.Expressao;
        vQry.ParamByName('CONSULTA_TABELA').AsString := vCampo.ConsultaTabela;
        vQry.ParamByName('CONSULTA_CAMPO_PESQUISA').AsString := vCampo.ConsultaCampoPesquisa;
        vQry.ParamByName('CONSULTA_CAMPO_RETORNO').AsString := vCampo.ConsultaCampoRetorno;
        vQry.ParamByName('CONSULTA_SE_NAO_ACHAR').AsString := cACOES_NAO_ENCONTRADO[vCampo.ConsultaSeNaoAchar].Codigo;
        vQry.ParamByName('CONSULTA_SQL').AsWideMemo := vCampo.ConsultaSql;
        vQry.ParamByName('TRANSFORMACOES').AsWideMemo := TransformacoesParaTexto(vCampo.Transformacoes);
        vQry.ExecSQL;
      end;

      dmConexao.Commit;
    except
      dmConexao.Rollback;
      raise;
    end;
  finally
    vQry.Free;
  end;

  qryPerfis.Close;
  qryPerfis.Open;
  qryPerfis.Locate('ID', APerfil.Id, []);
end;

function TdmPerfis.NomeDisponivel(const ANomeBase: string): string;
var
  vQry: TFDQuery;
  vNumero: Integer;
begin
  vQry := NovaQuery;
  try
    vQry.SQL.Text := 'select count(*) from PERFIL where upper(NOME) = upper(:NOME)';
    vNumero := 1;
    Result := ANomeBase + ' (cópia)';
    repeat
      vQry.Close;
      vQry.ParamByName('NOME').AsString := Result;
      vQry.Open;
      if vQry.Fields[0].AsInteger = 0 then
        Exit;
      Inc(vNumero);
      Result := ANomeBase + ' (cópia ' + IntToStr(vNumero) + ')';
    until False;
  finally
    vQry.Free;
  end;
end;

function TdmPerfis.Duplicar(AId: Integer): Integer;
var
  vPerfil: TPerfil;
begin
  vPerfil := Carregar(AId);
  try
    vPerfil.Id := 0;
    vPerfil.Nome := NomeDisponivel(vPerfil.Nome);
    Gravar(vPerfil);
    Result := vPerfil.Id;
  finally
    vPerfil.Free;
  end;
end;

procedure TdmPerfis.Excluir(AId: Integer);
var
  vQry: TFDQuery;
begin
  vQry := NovaQuery;
  try
    // PERFIL_CAMPO sai junto (ON DELETE CASCADE)
    vQry.SQL.Text := 'delete from PERFIL where ID = :ID';
    vQry.ParamByName('ID').AsInteger := AId;
    vQry.ExecSQL;
  finally
    vQry.Free;
  end;

  Pesquisar;
end;

end.
