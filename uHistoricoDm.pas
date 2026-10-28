unit uHistoricoDm;

interface

uses
  System.SysUtils, System.Classes, Data.DB, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  // O que a tela de importação precisa para continuar uma execução
  TDadosRetomada = record
    IdExecucao: Integer;
    IdPerfil: Integer;
    Arquivo: string;
    LinhaInicio: Integer;      // ULTIMA_LINHA + 1
    VersaoPerfil: Integer;     // versão usada na execução
    VersaoAtual: Integer;      // versão atual do perfil
    Status: string;
    RetomadaPor: Integer;      // execução que já retomou esta (0 = nenhuma)
  end;

  TdmHistorico = class(TDataModule)
    qryExecucoes: TFDQuery;
    dsExecucoes: TDataSource;
    qryErros: TFDQuery;
    dsErros: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    procedure qryExecucoesAfterScroll(DataSet: TDataSet);
  public
    procedure Pesquisar(AIdPerfil: Integer);
    function IdSelecionado: Integer;
    function DadosRetomada: TDadosRetomada;
  end;

const
  // Status em que faz sentido continuar de onde parou
  cSTATUS_RETOMAVEIS: array[0..2] of string = ('INTERROMPIDA', 'CANCELADA', 'FALHOU');

function StatusRetomavel(const AStatus: string): Boolean;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  uDmConexao;

function StatusRetomavel(const AStatus: string): Boolean;
var
  vStatus: string;
begin
  for vStatus in cSTATUS_RETOMAVEIS do
    if SameText(vStatus, AStatus) then
      Exit(True);
  Result := False;
end;

procedure TdmHistorico.DataModuleCreate(Sender: TObject);
begin
  qryExecucoes.Connection := dmConexao.cnConexao;
  qryErros.Connection := dmConexao.cnConexao;
  qryExecucoes.AfterScroll := qryExecucoesAfterScroll;
end;

procedure TdmHistorico.Pesquisar(AIdPerfil: Integer);
var
  vId: Integer;
begin
  vId := IdSelecionado;
  qryExecucoes.Close;
  qryExecucoes.ParamByName('ID_PERFIL').AsInteger := AIdPerfil;
  qryExecucoes.Open;
  if vId > 0 then
    qryExecucoes.Locate('ID', vId, []);
  qryExecucoesAfterScroll(qryExecucoes);
end;

function TdmHistorico.IdSelecionado: Integer;
begin
  if qryExecucoes.Active and not qryExecucoes.IsEmpty then
    Result := qryExecucoes.FieldByName('ID').AsInteger
  else
    Result := 0;
end;

procedure TdmHistorico.qryExecucoesAfterScroll(DataSet: TDataSet);
begin
  // Erros da execução selecionada
  qryErros.Close;
  qryErros.ParamByName('ID_EXECUCAO').AsInteger := IdSelecionado;
  qryErros.Open;
end;

function TdmHistorico.DadosRetomada: TDadosRetomada;
begin
  Result := Default(TDadosRetomada);
  if IdSelecionado = 0 then
    Exit;
  Result.IdExecucao := qryExecucoes.FieldByName('ID').AsInteger;
  Result.IdPerfil := qryExecucoes.FieldByName('ID_PERFIL').AsInteger;
  Result.Arquivo := qryExecucoes.FieldByName('ARQUIVO').AsString;
  Result.LinhaInicio := qryExecucoes.FieldByName('ULTIMA_LINHA').AsInteger + 1;
  Result.VersaoPerfil := qryExecucoes.FieldByName('VERSAO_PERFIL').AsInteger;
  Result.VersaoAtual := qryExecucoes.FieldByName('VERSAO_ATUAL').AsInteger;
  Result.Status := qryExecucoes.FieldByName('STATUS').AsString;
  Result.RetomadaPor := qryExecucoes.FieldByName('RETOMADA_POR').AsInteger;
end;

end.
