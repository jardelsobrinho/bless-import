unit uDmConexao;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait, FireDAC.Phys.IBBase, Data.DB, FireDAC.Comp.Client, Vcl.Forms,
  uConfigIni, uMensagens;

type
  TdmConexao = class(TDataModule)
    cnConexao: TFDConnection;
    trTransacao: TFDTransaction;
    linkDriver: TFDPhysFBDriverLink;
    procedure DataModuleCreate(Sender: TObject);
    procedure cnConexaoBeforeConnect(Sender: TObject);
  private
    procedure ConfigurarConexao;
  public
    function DescricaoBanco: string;
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
  end;

var
  dmConexao: TdmConexao;

const
  cSECAO_BANCO_CONFIG = 'BancoConfig';

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

const
  cUSUARIO_BANCO = 'SYSDBA';
  cSENHA_BANCO = 'pmpsyfwr';

procedure TdmConexao.ConfigurarConexao;
var
  vVendorLib: string;
begin
  // fbclient.dll ao lado do exe tem prioridade; senão o FireDAC usa o cliente instalado
  vVendorLib := ExtractFilePath(Application.ExeName) + 'fbclient.dll';
  if FileExists(vVendorLib) then
    linkDriver.VendorLib := vVendorLib;

  cnConexao.Params.Clear;
  cnConexao.Params.AddPair('DriverID', 'FB');
  cnConexao.Params.AddPair('Protocol', 'TCPIP');
  cnConexao.Params.AddPair('Server', TConfigIni.Retornar(cSECAO_BANCO_CONFIG, 'Servidor', 'localhost'));
  cnConexao.Params.AddPair('Port', TConfigIni.Retornar(cSECAO_BANCO_CONFIG, 'Porta', '3050'));
  cnConexao.Params.AddPair('Database', TConfigIni.Retornar(cSECAO_BANCO_CONFIG, 'Banco', 'BLESS_IMPORT'));
  cnConexao.Params.AddPair('User_Name', cUSUARIO_BANCO);
  cnConexao.Params.AddPair('Password', cSENHA_BANCO);
  cnConexao.Params.AddPair('SQLDialect', '3');
  cnConexao.Params.AddPair('CharacterSet', 'UTF8');
end;

procedure TdmConexao.cnConexaoBeforeConnect(Sender: TObject);
begin
  // Em design-time usa os parâmetros do DFM; em runtime sempre os do Config.ini
  if csDesigning in ComponentState then
    Exit;

  ConfigurarConexao;
end;

procedure TdmConexao.DataModuleCreate(Sender: TObject);
begin
  if not TConfigIni.ArquivoExiste then
  begin
    TMensagens.Alerta('Arquivo de configuração não encontrado:' + sLineBreak + TConfigIni.CaminhoArquivo + sLineBreak +
      sLineBreak + 'A aplicação será fechada.');
    Application.Terminate;
    Exit;
  end;

  try
    cnConexao.Open;
  except
    on E: Exception do
    begin
      TMensagens.Alerta('Não foi possível conectar ao banco de configurações (' + DescricaoBanco + ').' + sLineBreak +
        'Verifique a seção [' + cSECAO_BANCO_CONFIG + '] do arquivo ' + TConfigIni.CaminhoArquivo + '.' + sLineBreak +
        sLineBreak + E.Message + sLineBreak + sLineBreak + 'A aplicação será fechada.');
      Application.Terminate;
    end;
  end;
end;

function TdmConexao.DescricaoBanco: string;
begin
  Result := TConfigIni.Retornar(cSECAO_BANCO_CONFIG, 'Servidor', 'localhost') + ':' +
    TConfigIni.Retornar(cSECAO_BANCO_CONFIG, 'Banco', 'BLESS_IMPORT');
end;

procedure TdmConexao.StartTransaction;
begin
  if not cnConexao.InTransaction then
    trTransacao.StartTransaction;
end;

procedure TdmConexao.Commit;
begin
  trTransacao.Commit;
end;

procedure TdmConexao.Rollback;
begin
  trTransacao.Rollback;
end;

end.
