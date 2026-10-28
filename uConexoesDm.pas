unit uConexoesDm;

interface

uses
  System.SysUtils, System.Classes, Data.DB, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, uConexaoDados;

type
  TdmConexoes = class(TDataModule)
    qryConexoes: TFDQuery;
    dsConexoes: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    function NovaQuery: TFDQuery;
    procedure Validar(const ADados: TConexaoDados);
  public
    procedure Pesquisar;
    function IdSelecionado: Integer;
    function Carregar(AId: Integer): TConexaoDados;
    procedure Gravar(var ADados: TConexaoDados);
    procedure Excluir(AId: Integer);
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  uDmConexao;

procedure TdmConexoes.DataModuleCreate(Sender: TObject);
begin
  qryConexoes.Connection := dmConexao.cnConexao;
end;

function TdmConexoes.NovaQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := dmConexao.cnConexao;
end;

procedure TdmConexoes.Pesquisar;
var
  vId: Integer;
begin
  vId := IdSelecionado;
  qryConexoes.Close;
  qryConexoes.Open;
  if vId > 0 then
    qryConexoes.Locate('ID', vId, []);
end;

function TdmConexoes.IdSelecionado: Integer;
begin
  if qryConexoes.Active and not qryConexoes.IsEmpty then
    Result := qryConexoes.FieldByName('ID').AsInteger
  else
    Result := 0;
end;

function TdmConexoes.Carregar(AId: Integer): TConexaoDados;
var
  vQry: TFDQuery;
begin
  vQry := NovaQuery;
  try
    vQry.SQL.Text :=
      'select ID, NOME, ERP, SERVIDOR, PORTA, BANCO, USUARIO, SENHA, CHARSET, DIALETO ' +
      'from CONEXAO where ID = :ID';
    vQry.ParamByName('ID').AsInteger := AId;
    vQry.Open;
    if vQry.IsEmpty then
      raise Exception.CreateFmt('Conexão %d não encontrada.', [AId]);

    Result.Id := vQry.FieldByName('ID').AsInteger;
    Result.Nome := vQry.FieldByName('NOME').AsString;
    Result.Erp := vQry.FieldByName('ERP').AsString;
    Result.Servidor := vQry.FieldByName('SERVIDOR').AsString;
    Result.Porta := vQry.FieldByName('PORTA').AsInteger;
    Result.Banco := vQry.FieldByName('BANCO').AsString;
    Result.Usuario := vQry.FieldByName('USUARIO').AsString;
    Result.Senha := vQry.FieldByName('SENHA').AsString;
    Result.Charset := vQry.FieldByName('CHARSET').AsString;
    Result.Dialeto := vQry.FieldByName('DIALETO').AsInteger;
  finally
    vQry.Free;
  end;
end;

procedure TdmConexoes.Validar(const ADados: TConexaoDados);
var
  vQry: TFDQuery;
begin
  if Trim(ADados.Nome) = '' then
    raise Exception.Create('Informe o nome da conexão.');
  if Trim(ADados.Erp) = '' then
    raise Exception.Create('Informe o ERP.');
  if Trim(ADados.Servidor) = '' then
    raise Exception.Create('Informe o servidor.');
  if (ADados.Porta <= 0) or (ADados.Porta > 65535) then
    raise Exception.Create('Porta inválida.');
  if Trim(ADados.Banco) = '' then
    raise Exception.Create('Informe o banco (alias ou caminho do arquivo .FDB).');
  if Trim(ADados.Usuario) = '' then
    raise Exception.Create('Informe o usuário.');
  if Trim(ADados.Charset) = '' then
    raise Exception.Create('Informe o charset.');
  if not (ADados.Dialeto in [1, 3]) then
    raise Exception.Create('O dialeto deve ser 1 ou 3.');

  vQry := NovaQuery;
  try
    vQry.SQL.Text := 'select count(*) from CONEXAO where upper(NOME) = upper(:NOME) and ID <> :ID';
    vQry.ParamByName('NOME').AsString := Trim(ADados.Nome);
    vQry.ParamByName('ID').AsInteger := ADados.Id;
    vQry.Open;
    if vQry.Fields[0].AsInteger > 0 then
      raise Exception.CreateFmt('Já existe uma conexão com o nome "%s".', [Trim(ADados.Nome)]);
  finally
    vQry.Free;
  end;
end;

procedure TdmConexoes.Gravar(var ADados: TConexaoDados);
var
  vQry: TFDQuery;
begin
  Validar(ADados);

  vQry := NovaQuery;
  try
    if ADados.Id = 0 then
      vQry.SQL.Text :=
        'insert into CONEXAO (NOME, ERP, SERVIDOR, PORTA, BANCO, USUARIO, SENHA, CHARSET, DIALETO) ' +
        'values (:NOME, :ERP, :SERVIDOR, :PORTA, :BANCO, :USUARIO, :SENHA, :CHARSET, :DIALETO) ' +
        'returning ID'
    else
    begin
      vQry.SQL.Text :=
        'update CONEXAO set NOME = :NOME, ERP = :ERP, SERVIDOR = :SERVIDOR, PORTA = :PORTA, BANCO = :BANCO, ' +
        'USUARIO = :USUARIO, SENHA = :SENHA, CHARSET = :CHARSET, DIALETO = :DIALETO ' +
        'where ID = :ID';
      vQry.ParamByName('ID').AsInteger := ADados.Id;
    end;

    vQry.ParamByName('NOME').AsString := Trim(ADados.Nome);
    vQry.ParamByName('ERP').AsString := ADados.Erp;
    vQry.ParamByName('SERVIDOR').AsString := Trim(ADados.Servidor);
    vQry.ParamByName('PORTA').AsInteger := ADados.Porta;
    vQry.ParamByName('BANCO').AsString := Trim(ADados.Banco);
    vQry.ParamByName('USUARIO').AsString := Trim(ADados.Usuario);
    vQry.ParamByName('SENHA').AsString := ADados.Senha;
    vQry.ParamByName('CHARSET').AsString := Trim(ADados.Charset);
    vQry.ParamByName('DIALETO').AsInteger := ADados.Dialeto;

    if ADados.Id = 0 then
    begin
      vQry.Open;
      ADados.Id := vQry.Fields[0].AsInteger;
    end
    else
      vQry.ExecSQL;
  finally
    vQry.Free;
  end;

  qryConexoes.Close;
  qryConexoes.Open;
  qryConexoes.Locate('ID', ADados.Id, []);
end;

procedure TdmConexoes.Excluir(AId: Integer);
var
  vQry: TFDQuery;
begin
  vQry := NovaQuery;
  try
    vQry.SQL.Text := 'delete from CONEXAO where ID = :ID';
    vQry.ParamByName('ID').AsInteger := AId;
    vQry.ExecSQL;
  finally
    vQry.Free;
  end;

  Pesquisar;
end;

end.
