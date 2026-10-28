program BlessImport;

uses
  Winapi.Windows,
  Vcl.Forms,
  uConfigIni in 'Utils\uConfigIni.pas',
  uMensagens in 'Utils\uMensagens.pas',
  uFormBase in 'FormsBase\uFormBase.pas' {frmFormBase},
  uFormTabBase in 'FormsBase\uFormTabBase.pas' {frmFormTabBase},
  uFormModalBase in 'FormsBase\uFormModalBase.pas' {frmFormModalBase},
  uDmConexao in 'uDmConexao.pas' {dmConexao: TDataModule},
  uConexaoDados in 'uConexaoDados.pas',
  uConexoesDm in 'uConexoesDm.pas' {dmConexoes: TDataModule},
  uConexoes in 'uConexoes.pas' {frmConexoes},
  uConexaoEdicao in 'uConexaoEdicao.pas' {frmConexaoEdicao},
  uLeitorXls in 'uLeitorXls.pas',
  uVisualizarPlanilha in 'uVisualizarPlanilha.pas' {frmVisualizarPlanilha},
  uDmDestino in 'uDmDestino.pas' {dmDestino: TDataModule},
  uMetadadosDestino in 'uMetadadosDestino.pas' {frmMetadadosDestino},
  uTransformacoes in 'uTransformacoes.pas',
  uPerfilModelo in 'uPerfilModelo.pas',
  uPerfisDm in 'uPerfisDm.pas' {dmPerfis: TDataModule},
  uPerfis in 'uPerfis.pas' {frmPerfis},
  uPerfilEdicao in 'uPerfilEdicao.pas' {frmPerfilEdicao},
  uImportador in 'uImportador.pas',
  uImportacaoDm in 'uImportacaoDm.pas' {dmImportacao: TDataModule},
  uImportacao in 'uImportacao.pas' {frmImportacao},
  uHistoricoDm in 'uHistoricoDm.pas' {dmHistorico: TDataModule},
  uHistorico in 'uHistorico.pas' {frmHistorico},
  uPrincipal in 'uPrincipal.pas' {frmPrincipal};

{$R *.res}

// Permite usar até 4 GB de memória no Windows 64 bits (planilhas grandes passam de 800 MB ao carregar)
{$SETPEFLAGS IMAGE_FILE_LARGE_ADDRESS_AWARE}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Bless Import';
  Application.CreateForm(TdmConexao, dmConexao);
  if not Application.Terminated then
  begin
    Application.CreateForm(TfrmPrincipal, frmPrincipal);
    Application.Run;
  end;
end.
