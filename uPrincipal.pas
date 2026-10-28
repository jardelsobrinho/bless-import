unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, System.Types, dxNavBar, dxNavBarBase, dxNavBarCollns,
  dxNavBarConsts, dxNavBarOffice12Views;

type
  TfrmPrincipal = class(TForm)
    nbMenu: TdxNavBar;
    nbgCadastros: TdxNavBarGroup;
    nbgImportacao: TdxNavBarGroup;
    nbgFerramentas: TdxNavBarGroup;
    nbgSistema: TdxNavBarGroup;
    nbiConexoes: TdxNavBarItem;
    nbiPerfis: TdxNavBarItem;
    nbiImportarPlanilha: TdxNavBarItem;
    nbiVisualizarPlanilha: TdxNavBarItem;
    nbiMetadadosDestino: TdxNavBarItem;
    nbiSair: TdxNavBarItem;
    nbiHistorico: TdxNavBarItem;
    pcJanelas: TPageControl;
    sbStatus: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure mnuHistoricoClick(Sender: TObject);
    procedure mnuImportarPlanilhaClick(Sender: TObject);
    procedure mnuPerfisClick(Sender: TObject);
    procedure mnuSairClick(Sender: TObject);
    procedure mnuConexoesClick(Sender: TObject);
    procedure mnuVisualizarPlanilhaClick(Sender: TObject);
    procedure mnuMetadadosDestinoClick(Sender: TObject);
    procedure pcJanelasDrawTab(Control: TCustomTabControl; TabIndex: Integer; const Rect: TRect; Active: Boolean);
  private
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  public
    // Abre o form numa aba (ou ativa a aba se já estiver aberto) e devolve o form
    function AbrirFormEmAba(AFormClass: TFormClass): TForm;
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.dfm}

uses
  uMensagens, uDmConexao, uConexoes, uVisualizarPlanilha, uMetadadosDestino, uPerfis, uImportacao, uHistorico;

function TfrmPrincipal.AbrirFormEmAba(AFormClass: TFormClass): TForm;
var
  i: Integer;
  vAba: TTabSheet;
  vForm: TForm;
begin
  // Reaproveita a aba se o form já estiver aberto
  for i := 0 to pcJanelas.PageCount - 1 do
  begin
    if pcJanelas.Pages[i].Tag = NativeInt(AFormClass) then
    begin
      pcJanelas.ActivePage := pcJanelas.Pages[i];
      Exit(pcJanelas.Pages[i].Controls[0] as TForm);
    end;
  end;

  vAba := TTabSheet.Create(pcJanelas);
  vAba.PageControl := pcJanelas;
  vAba.Tag := NativeInt(AFormClass);

  vForm := AFormClass.Create(Self);
  // As abas usam fonte em negrito (pcJanelas); o form mantém a fonte dele
  vForm.ParentFont := False;
  vForm.BorderStyle := bsNone;
  vForm.Align := alClient;
  vForm.Parent := vAba;
  vForm.Visible := True;
  vAba.Caption := vForm.Caption + '   ';

  pcJanelas.ActivePage := vAba;
  Result := vForm;
end;

procedure TfrmPrincipal.mnuHistoricoClick(Sender: TObject);
begin
  AbrirFormEmAba(TfrmHistorico);
end;

procedure TfrmPrincipal.pcJanelasDrawTab(Control: TCustomTabControl; TabIndex: Integer; const Rect: TRect;
  Active: Boolean);
var
  vRetangulo: TRect;
  vTexto: string;
begin
  // A fonte do pcJanelas é negrito (a largura das abas é calculada com ela); só a aba ativa fica em negrito
  vTexto := Trim(pcJanelas.Pages[TabIndex].Caption);
  if Active then
    Control.Canvas.Font.Style := [fsBold]
  else
    Control.Canvas.Font.Style := [];
  Control.Canvas.Brush.Color := clBtnFace;
  Control.Canvas.FillRect(Rect);

  vRetangulo := Rect;
  DrawText(Control.Canvas.Handle, PChar(vTexto), Length(vTexto), vRetangulo,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
end;

procedure TfrmPrincipal.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  i: Integer;
begin
  // Pergunta a cada tela aberta em aba se ela pode fechar (ex.: importação em andamento)
  for i := 0 to pcJanelas.PageCount - 1 do
    if (pcJanelas.Pages[i].ControlCount > 0) and (pcJanelas.Pages[i].Controls[0] is TForm) and
      not TForm(pcJanelas.Pages[i].Controls[0]).CloseQuery then
    begin
      CanClose := False;
      Exit;
    end;

  CanClose := TMensagens.Confirmacao('Deseja realmente sair do programa?');
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  OnCloseQuery := FormCloseQuery;
  sbStatus.SimpleText := 'BANCO DADOS: ' + dmConexao.DescricaoBanco;
end;

procedure TfrmPrincipal.mnuConexoesClick(Sender: TObject);
begin
  AbrirFormEmAba(TfrmConexoes);
end;

procedure TfrmPrincipal.mnuVisualizarPlanilhaClick(Sender: TObject);
begin
  AbrirFormEmAba(TfrmVisualizarPlanilha);
end;

procedure TfrmPrincipal.mnuMetadadosDestinoClick(Sender: TObject);
begin
  AbrirFormEmAba(TfrmMetadadosDestino);
end;

procedure TfrmPrincipal.mnuPerfisClick(Sender: TObject);
begin
  AbrirFormEmAba(TfrmPerfis);
end;

procedure TfrmPrincipal.mnuImportarPlanilhaClick(Sender: TObject);
begin
  AbrirFormEmAba(TfrmImportacao);
end;

procedure TfrmPrincipal.mnuSairClick(Sender: TObject);
begin
  Close;
end;

end.
