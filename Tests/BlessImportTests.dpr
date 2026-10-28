program BlessImportTests;

{ Testes automatizados (DUnit).
  Normal: abre o executor gráfico (barra verde/vermelha).
  Compilado com o define CONSOLE_TESTRUNNER: roda no console e termina com ExitCode <> 0 se algum teste falhar. }

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  {$IFDEF CONSOLE_TESTRUNNER}
  TextTestRunner,
  {$ELSE}
  Vcl.Forms,
  GUITestRunner,
  {$ENDIF}
  uTransformacoes in '..\uTransformacoes.pas',
  uPerfilModelo in '..\uPerfilModelo.pas',
  uConexaoDados in '..\uConexaoDados.pas',
  uDmDestino in '..\uDmDestino.pas' {dmDestino: TDataModule},
  uImportador in '..\uImportador.pas',
  uTestTransformacoes in 'uTestTransformacoes.pas',
  uTestPerfilModelo in 'uTestPerfilModelo.pas',
  uTestImportador in 'uTestImportador.pas';

{$R *.RES}

begin
  {$IFDEF CONSOLE_TESTRUNNER}
  TextTestRunner.RunRegisteredTests(rxbHaltOnFailures);
  {$ELSE}
  Application.Initialize;
  GUITestRunner.RunRegisteredTests;
  {$ENDIF}
end.
