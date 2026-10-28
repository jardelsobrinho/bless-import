unit uConexaoDados;

{ Dados de uma conexão de destino (tabela CONEXAO) e montagem da TFDConnection do ERP. }

interface

uses
  System.SysUtils, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Def, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.Comp.Client;

type
  TConexaoDados = record
    Id: Integer;
    Nome: string;
    Erp: string;
    Servidor: string;
    Porta: Integer;
    Banco: string;
    Usuario: string;
    Senha: string;    // sempre em texto puro na memória; criptografada só no banco
    Charset: string;
    Dialeto: Integer;
    class function Novo: TConexaoDados; static;
  end;

procedure ConfigurarConexaoFireDAC(AConexao: TFDConnection; const ADados: TConexaoDados);
procedure TestarConexao(const ADados: TConexaoDados);

implementation

class function TConexaoDados.Novo: TConexaoDados;
begin
  Result := Default(TConexaoDados);
  Result.Servidor := 'localhost';
  Result.Porta := 3050;
  Result.Usuario := 'SYSDBA';
  Result.Charset := 'WIN1252';
  Result.Dialeto := 1;
end;

procedure ConfigurarConexaoFireDAC(AConexao: TFDConnection; const ADados: TConexaoDados);
begin
  AConexao.Connected := False;
  AConexao.LoginPrompt := False;
  AConexao.Params.Clear;
  AConexao.Params.AddPair('DriverID', 'FB');
  AConexao.Params.AddPair('Protocol', 'TCPIP');
  AConexao.Params.AddPair('Server', ADados.Servidor);
  AConexao.Params.AddPair('Port', IntToStr(ADados.Porta));
  AConexao.Params.AddPair('Database', ADados.Banco);
  AConexao.Params.AddPair('User_Name', ADados.Usuario);
  AConexao.Params.AddPair('Password', ADados.Senha);
  AConexao.Params.AddPair('SQLDialect', IntToStr(ADados.Dialeto));
  AConexao.Params.AddPair('CharacterSet', ADados.Charset);
end;

procedure TestarConexao(const ADados: TConexaoDados);
var
  vConexao: TFDConnection;
begin
  vConexao := TFDConnection.Create(nil);
  try
    ConfigurarConexaoFireDAC(vConexao, ADados);
    vConexao.Open;
    vConexao.Close;
  finally
    vConexao.Free;
  end;
end;

end.
