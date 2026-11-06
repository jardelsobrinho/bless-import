unit uPerfis;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uFormTabBase, Vcl.StdCtrls, Vcl.ExtCtrls, Data.DB, Vcl.Grids,
  Vcl.DBGrids, uPerfisDm;

type
  TfrmPerfis = class(TfrmFormTabBase)
    pnlBotoes: TPanel;
    btnNovo: TButton;
    btnEditar: TButton;
    btnDuplicar: TButton;
    btnExcluir: TButton;
    btnExportar: TButton;
    btnImportar: TButton;
    grdPerfis: TDBGrid;
    procedure FormCreate(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnDuplicarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure grdPerfisDblClick(Sender: TObject);
    procedure btnExportarClick(Sender: TObject);
    procedure btnImportarClick(Sender: TObject);
  private
    FDm: TdmPerfis;
    function PerfilSelecionado: Boolean;
    function IdsSelecionados: TArray<Integer>;
  end;

var
  frmPerfis: TfrmPerfis;

implementation

{$R *.dfm}

uses
  uPerfilEdicao, uMensagens, uPerfilArquivo, uPerfisImportar;

procedure TfrmPerfis.FormCreate(Sender: TObject);
begin
  FDm := TdmPerfis.Create(Self);
  grdPerfis.DataSource := FDm.dsPerfis;
  FDm.Pesquisar;
end;

function TfrmPerfis.PerfilSelecionado: Boolean;
begin
  Result := FDm.IdSelecionado > 0;
  if not Result then
    TMensagens.Alerta('Selecione um perfil.');
end;

procedure TfrmPerfis.btnNovoClick(Sender: TObject);
begin
  TfrmPerfilEdicao.Editar(FDm, 0);
end;

procedure TfrmPerfis.btnEditarClick(Sender: TObject);
begin
  if PerfilSelecionado then
    TfrmPerfilEdicao.Editar(FDm, FDm.IdSelecionado);
end;

procedure TfrmPerfis.btnDuplicarClick(Sender: TObject);
var
  vNovoId: Integer;
begin
  if not PerfilSelecionado then
    Exit;

  vNovoId := FDm.Duplicar(FDm.IdSelecionado);
  TMensagens.Info('Perfil duplicado como "' + FDm.qryPerfis.FieldByName('NOME').AsString + '".');
  if TMensagens.Confirmacao('Deseja editar a cópia agora?') then
    TfrmPerfilEdicao.Editar(FDm, vNovoId);
end;

procedure TfrmPerfis.btnExcluirClick(Sender: TObject);
begin
  if not PerfilSelecionado then
    Exit;

  if TMensagens.Confirmacao('Excluir o perfil "' + FDm.qryPerfis.FieldByName('NOME').AsString +
    '" e todo o seu mapeamento?') then
    FDm.Excluir(FDm.IdSelecionado);
end;

procedure TfrmPerfis.grdPerfisDblClick(Sender: TObject);
begin
  btnEditar.Click;
end;

function TfrmPerfis.IdsSelecionados: TArray<Integer>;
var
  i: Integer;
  vMarca: TBookmark;
begin
  // Ctrl/Shift+clique seleciona vários; sem seleção múltipla vale o perfil atual
  Result := nil;
  if grdPerfis.SelectedRows.Count = 0 then
  begin
    if FDm.IdSelecionado > 0 then
      Result := [FDm.IdSelecionado];
    Exit;
  end;

  vMarca := FDm.qryPerfis.GetBookmark;
  FDm.qryPerfis.DisableControls;
  try
    for i := 0 to grdPerfis.SelectedRows.Count - 1 do
    begin
      FDm.qryPerfis.GotoBookmark(grdPerfis.SelectedRows[i]);
      Result := Result + [FDm.qryPerfis.FieldByName('ID').AsInteger];
    end;
    FDm.qryPerfis.GotoBookmark(vMarca);
  finally
    FDm.qryPerfis.FreeBookmark(vMarca);
    FDm.qryPerfis.EnableControls;
  end;
end;

procedure TfrmPerfis.btnExportarClick(Sender: TObject);
var
  vIds: TArray<Integer>;
  vDialogo: TSaveDialog;
begin
  vIds := IdsSelecionados;
  if Length(vIds) = 0 then
  begin
    TMensagens.Alerta('Selecione os perfis a exportar (Ctrl+clique seleciona vários).');
    Exit;
  end;

  vDialogo := TSaveDialog.Create(nil);
  try
    vDialogo.Title := Format('Exportar %d perfil(is)', [Length(vIds)]);
    vDialogo.Filter := 'Perfis do BlessImport (*' + cEXTENSAO_ARQUIVO + ')|*' + cEXTENSAO_ARQUIVO;
    vDialogo.DefaultExt := Copy(cEXTENSAO_ARQUIVO, 2, MaxInt);
    vDialogo.Options := vDialogo.Options + [ofOverwritePrompt, ofPathMustExist];
    if Length(vIds) = 1 then
      vDialogo.FileName := FDm.qryPerfis.FieldByName('NOME').AsString + cEXTENSAO_ARQUIVO
    else
      vDialogo.FileName := 'perfis' + cEXTENSAO_ARQUIVO;
    if not vDialogo.Execute then
      Exit;
    FDm.Exportar(vIds, vDialogo.FileName);
    TMensagens.Info(Format('%d perfil(is) exportado(s) para %s.', [Length(vIds), vDialogo.FileName]));
  finally
    vDialogo.Free;
  end;
end;

procedure TfrmPerfis.btnImportarClick(Sender: TObject);
var
  vDialogo: TOpenDialog;
begin
  vDialogo := TOpenDialog.Create(nil);
  try
    vDialogo.Title := 'Importar perfis';
    vDialogo.Filter := 'Perfis do BlessImport (*' + cEXTENSAO_ARQUIVO + ')|*' + cEXTENSAO_ARQUIVO +
      '|Todos os arquivos (*.*)|*.*';
    vDialogo.Options := vDialogo.Options + [ofFileMustExist];
    if not vDialogo.Execute then
      Exit;
    if TfrmPerfisImportar.Executar(FDm, vDialogo.FileName) then
      FDm.Pesquisar;
  finally
    vDialogo.Free;
  end;
end;

end.
