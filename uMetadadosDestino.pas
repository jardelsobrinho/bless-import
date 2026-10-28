unit uMetadadosDestino;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uFormTabBase, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, uConexoesDm,
  uDmDestino;

type
  TfrmMetadadosDestino = class(TfrmFormTabBase)
    pnlTopo: TPanel;
    lblConexao: TLabel;
    cbxConexao: TComboBox;
    btnConectar: TButton;
    lblStatus: TLabel;
    pnlEsquerda: TPanel;
    lblTabelas: TLabel;
    edtFiltro: TEdit;
    lstTabelas: TListBox;
    pnlGenerators: TPanel;
    lblGenerators: TLabel;
    lstGenerators: TListBox;
    splEsquerda: TSplitter;
    pnlCampos: TPanel;
    lblResumo: TLabel;
    grdCampos: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure cbxConexaoDropDown(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
    procedure edtFiltroChange(Sender: TObject);
    procedure lstTabelasClick(Sender: TObject);
  private
    FDmConexoes: TdmConexoes;
    FDmDestino: TdmDestino;
    FTabelas: TArray<string>;
    procedure CarregarConexoes;
    procedure FiltrarTabelas;
    procedure LimparCampos;
    procedure MostrarCampos(const ATabela: string);
  end;

var
  frmMetadadosDestino: TfrmMetadadosDestino;

implementation

{$R *.dfm}

uses
  uMensagens;

procedure TfrmMetadadosDestino.FormCreate(Sender: TObject);
begin
  FDmConexoes := TdmConexoes.Create(Self);
  FDmDestino := TdmDestino.Create(Self);
  CarregarConexoes;
  LimparCampos;
end;

procedure TfrmMetadadosDestino.CarregarConexoes;
var
  vSelecionado: string;
begin
  // Recarrega a cada abertura do combo para pegar conexões cadastradas depois de abrir a tela
  vSelecionado := cbxConexao.Text;
  cbxConexao.Items.Clear;
  FDmConexoes.Pesquisar;
  FDmConexoes.qryConexoes.First;
  while not FDmConexoes.qryConexoes.Eof do
  begin
    cbxConexao.Items.AddObject(FDmConexoes.qryConexoes.FieldByName('NOME').AsString + ' (' +
      FDmConexoes.qryConexoes.FieldByName('ERP').AsString + ')',
      TObject(FDmConexoes.qryConexoes.FieldByName('ID').AsInteger));
    FDmConexoes.qryConexoes.Next;
  end;
  cbxConexao.ItemIndex := cbxConexao.Items.IndexOf(vSelecionado);
end;

procedure TfrmMetadadosDestino.cbxConexaoDropDown(Sender: TObject);
begin
  CarregarConexoes;
end;

procedure TfrmMetadadosDestino.btnConectarClick(Sender: TObject);
var
  vId: Integer;
begin
  if cbxConexao.ItemIndex < 0 then
  begin
    TMensagens.Alerta('Selecione uma conexão.');
    Exit;
  end;
  vId := Integer(cbxConexao.Items.Objects[cbxConexao.ItemIndex]);

  FTabelas := nil;
  lstTabelas.Clear;
  lstGenerators.Clear;
  LimparCampos;
  lblStatus.Caption := 'Conectando...';
  lblStatus.Update;

  Screen.Cursor := crHourGlass;
  try
    try
      FDmDestino.Conectar(FDmConexoes.Carregar(vId));
      FTabelas := FDmDestino.Tabelas;
      lstGenerators.Items.AddStrings(FDmDestino.Generators);
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        lblStatus.Caption := 'Não conectado';
        TMensagens.Alerta('Falha ao conectar:' + sLineBreak + sLineBreak + E.Message);
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  FiltrarTabelas;
  lblStatus.Caption := Format('Conectado em %s:%s  |  %d tabelas  |  %d generators',
    [FDmDestino.Conexao.Servidor, FDmDestino.Conexao.Banco, Length(FTabelas), lstGenerators.Count]);
end;

procedure TfrmMetadadosDestino.FiltrarTabelas;
var
  vFiltro, vTabela: string;
begin
  vFiltro := UpperCase(Trim(edtFiltro.Text));
  lstTabelas.Items.BeginUpdate;
  try
    lstTabelas.Clear;
    for vTabela in FTabelas do
      if (vFiltro = '') or (Pos(vFiltro, vTabela) > 0) then
        lstTabelas.Items.Add(vTabela);
  finally
    lstTabelas.Items.EndUpdate;
  end;
end;

procedure TfrmMetadadosDestino.edtFiltroChange(Sender: TObject);
begin
  FiltrarTabelas;
end;

procedure TfrmMetadadosDestino.lstTabelasClick(Sender: TObject);
begin
  if lstTabelas.ItemIndex >= 0 then
    MostrarCampos(lstTabelas.Items[lstTabelas.ItemIndex]);
end;

procedure TfrmMetadadosDestino.LimparCampos;
var
  i: Integer;
begin
  for i := 0 to grdCampos.RowCount - 1 do
    grdCampos.Rows[i].Clear;
  grdCampos.RowCount := 2;
  grdCampos.Cells[0, 0] := 'Pos.';
  grdCampos.Cells[1, 0] := 'Campo';
  grdCampos.Cells[2, 0] := 'Tipo';
  grdCampos.Cells[3, 0] := 'Categoria';
  grdCampos.Cells[4, 0] := 'Obrigatório';
  grdCampos.Cells[5, 0] := 'Chave';
  grdCampos.Cells[6, 0] := 'Padrão';
  grdCampos.Cells[7, 0] := 'Referência (FK)';
  grdCampos.Cells[8, 0] := 'Calculado';
  lblResumo.Caption := '';
end;

procedure TfrmMetadadosDestino.MostrarCampos(const ATabela: string);
var
  vCampos: TArray<TCampoDestino>;
  vChave: TArray<string>;
  i, vObrigatorios: Integer;
const
  cSIM: array[Boolean] of string = ('', 'Sim');
begin
  LimparCampos;
  Screen.Cursor := crHourGlass;
  try
    vCampos := FDmDestino.Campos(ATabela);
    vChave := FDmDestino.ChavePrimaria(ATabela);
  finally
    Screen.Cursor := crDefault;
  end;

  if Length(vCampos) > 0 then
    grdCampos.RowCount := Length(vCampos) + 1;

  vObrigatorios := 0;
  for i := 0 to High(vCampos) do
  begin
    grdCampos.Cells[0, i + 1] := IntToStr(vCampos[i].Posicao);
    grdCampos.Cells[1, i + 1] := vCampos[i].Nome;
    grdCampos.Cells[2, i + 1] := vCampos[i].TipoSql;
    grdCampos.Cells[3, i + 1] := TdmDestino.NomeCategoria(vCampos[i].Categoria);
    grdCampos.Cells[4, i + 1] := cSIM[vCampos[i].Obrigatorio];
    grdCampos.Cells[5, i + 1] := cSIM[vCampos[i].ChavePrimaria];
    grdCampos.Cells[6, i + 1] := vCampos[i].Padrao;
    grdCampos.Cells[7, i + 1] := vCampos[i].Referencia;
    grdCampos.Cells[8, i + 1] := cSIM[vCampos[i].Calculado];
    if vCampos[i].Obrigatorio then
      Inc(vObrigatorios);
  end;

  if Length(vChave) = 0 then
    vChave := ['(sem chave primária)'];
  lblResumo.Caption := Format('%s  |  %d campos  |  %d obrigatórios  |  chave primária: %s',
    [ATabela, Length(vCampos), vObrigatorios, string.Join(', ', vChave)]);
end;

end.
