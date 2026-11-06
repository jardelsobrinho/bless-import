unit uPerfisImportar;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uFormModalBase, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.CheckLst,
  System.Generics.Collections, uPerfisDm, uConexoesDm, uPerfilArquivo;

type
  TfrmPerfisImportar = class(TfrmFormModalBase)
    btnImportar: TButton;
    lblArquivo: TLabel;
    lblPerfis: TLabel;
    clbPerfis: TCheckListBox;
    lblConexao: TLabel;
    cbxConexao: TComboBox;
    rgExistente: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnImportarClick(Sender: TObject);
  private
    FDm: TdmPerfis;
    FDmConexoes: TdmConexoes;
    FPerfis: TObjectList<TPerfilExportado>;
    FNomesConexoes: TArray<string>;  // nome de cada item de cbxConexao
    procedure CarregarTela(const AArquivo: string);
    procedure CarregarConexoes;
  public
    // Lê o arquivo e mostra a tela; True = algum perfil foi gravado
    class function Executar(ADm: TdmPerfis; const AArquivo: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils, uMensagens;

class function TfrmPerfisImportar.Executar(ADm: TdmPerfis; const AArquivo: string): Boolean;
var
  vForm: TfrmPerfisImportar;
begin
  vForm := TfrmPerfisImportar.Create(nil);
  try
    vForm.FDm := ADm;
    vForm.CarregarTela(AArquivo);
    Result := vForm.ShowModal = mrOk;
  finally
    vForm.Free;
  end;
end;

procedure TfrmPerfisImportar.FormCreate(Sender: TObject);
begin
  FDmConexoes := TdmConexoes.Create(Self);
end;

procedure TfrmPerfisImportar.FormDestroy(Sender: TObject);
begin
  FPerfis.Free;
end;

procedure TfrmPerfisImportar.CarregarConexoes;
begin
  cbxConexao.Items.Clear;
  FNomesConexoes := nil;
  FDmConexoes.Pesquisar;
  FDmConexoes.qryConexoes.First;
  while not FDmConexoes.qryConexoes.Eof do
  begin
    cbxConexao.Items.AddObject(FDmConexoes.qryConexoes.FieldByName('NOME').AsString + ' (' +
      FDmConexoes.qryConexoes.FieldByName('ERP').AsString + ')',
      TObject(FDmConexoes.qryConexoes.FieldByName('ID').AsInteger));
    FNomesConexoes := FNomesConexoes + [FDmConexoes.qryConexoes.FieldByName('NOME').AsString];
    FDmConexoes.qryConexoes.Next;
  end;
end;

procedure TfrmPerfisImportar.CarregarTela(const AArquivo: string);
var
  vItem: TPerfilExportado;
  i: Integer;
  vConexao: string;
begin
  // Erro de leitura (arquivo inválido, código desconhecido) sobe para quem chamou, antes de abrir a tela
  FPerfis := JsonParaPerfis(TFile.ReadAllText(AArquivo, TEncoding.UTF8));
  lblArquivo.Caption := 'Arquivo: ' + AArquivo;

  clbPerfis.Items.Clear;
  vConexao := '';
  for vItem in FPerfis do
  begin
    clbPerfis.Items.Add(Format('%s  -  tabela %s, %d campos (conexão de origem: %s)', [vItem.Perfil.Nome,
      vItem.Perfil.TabelaDestino, Length(vItem.Perfil.CamposMapeados), vItem.Conexao]));
    if vConexao = '' then
      vConexao := vItem.Conexao;
  end;
  clbPerfis.CheckAll(cbChecked);

  // Sugere a conexão deste banco com o mesmo nome da conexão de origem
  CarregarConexoes;
  cbxConexao.ItemIndex := -1;
  for i := 0 to cbxConexao.Items.Count - 1 do
    if SameText(FNomesConexoes[i], vConexao) then
    begin
      cbxConexao.ItemIndex := i;
      Break;
    end;
end;

procedure TfrmPerfisImportar.btnImportarClick(Sender: TObject);
var
  i, vIdConexao: Integer;
  vAcao: TAcaoPerfilExistente;
  vContagem: array[TResultadoPerfilImportado] of Integer;
  vResultado: TResultadoPerfilImportado;
  vErros, vResumo: string;
  vMarcados, vComErro: Integer;
begin
  vMarcados := 0;
  for i := 0 to clbPerfis.Items.Count - 1 do
    if clbPerfis.Checked[i] then
      Inc(vMarcados);
  if vMarcados = 0 then
  begin
    TMensagens.Alerta('Marque os perfis a importar.');
    Exit;
  end;
  if cbxConexao.ItemIndex < 0 then
  begin
    TMensagens.Alerta('Selecione a conexão de destino dos perfis.');
    cbxConexao.SetFocus;
    Exit;
  end;

  vIdConexao := Integer(cbxConexao.Items.Objects[cbxConexao.ItemIndex]);
  vAcao := TAcaoPerfilExistente(rgExistente.ItemIndex);
  for vResultado := Low(TResultadoPerfilImportado) to High(TResultadoPerfilImportado) do
    vContagem[vResultado] := 0;
  vErros := '';
  vComErro := 0;

  // Cada perfil é gravado na sua transação: um erro não impede os outros
  for i := 0 to clbPerfis.Items.Count - 1 do
    if clbPerfis.Checked[i] then
      try
        Inc(vContagem[FDm.Importar(FPerfis[i].Perfil, vIdConexao, vAcao)]);
      except
        on E: Exception do
        begin
          Inc(vComErro);
          vErros := vErros + sLineBreak + '- ' + FPerfis[i].Perfil.Nome + ': ' + E.Message;
        end;
      end;

  vResumo := Format('%d novo(s), %d substituído(s), %d cópia(s), %d pulado(s) por já existir.',
    [vContagem[rpiNovo], vContagem[rpiSubstituido], vContagem[rpiCopia], vContagem[rpiPulado]]);
  if vComErro > 0 then
  begin
    TMensagens.Alerta(vResumo + sLineBreak + sLineBreak + Format('%d perfil(is) com erro:', [vComErro]) + vErros);
    if vContagem[rpiNovo] + vContagem[rpiSubstituido] + vContagem[rpiCopia] = 0 then
      Exit;
  end
  else
    TMensagens.Info(vResumo);
  ModalResult := mrOk;
end;

end.
