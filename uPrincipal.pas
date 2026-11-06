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
    procedure pcJanelasMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pcJanelasMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pcJanelasMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pcJanelasMouseLeave(Sender: TObject);
  private
    FAbaFecharSobMouse: Integer;     // aba com o mouse sobre o "×" (-1 = nenhuma)
    FAbaFecharPressionada: Integer;  // aba em que o botão foi pressionado sobre o "×" (-1 = nenhuma)
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    function RetanguloFechar(AIndice: Integer): TRect;
    function AbaFecharEm(X, Y: Integer): Integer;
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
  // Espaços no fim: lugar para o "×" de fechar (a largura da aba é calculada pelo texto)
  vAba.Caption := vForm.Caption + '       ';

  pcJanelas.ActivePage := vAba;
  Result := vForm;
end;

procedure TfrmPrincipal.mnuHistoricoClick(Sender: TObject);
begin
  AbrirFormEmAba(TfrmHistorico);
end;

procedure TfrmPrincipal.pcJanelasDrawTab(Control: TCustomTabControl; TabIndex: Integer; const Rect: TRect;
  Active: Boolean);
const
  cRECUO_X = 3;  // distância do "X" até a borda do botão
var
  vRetangulo, vFechar: TRect;
  vTexto: string;
  vCanvas: TCanvas;
  vCorX: TColor;
begin
  // A fonte do pcJanelas é negrito (a largura das abas é calculada com ela); só a aba ativa fica em negrito
  vTexto := Trim(pcJanelas.Pages[TabIndex].Caption);
  if Active then
    Control.Canvas.Font.Style := [fsBold]
  else
    Control.Canvas.Font.Style := [];
  Control.Canvas.Brush.Color := clBtnFace;
  Control.Canvas.FillRect(Rect);

  vFechar := RetanguloFechar(TabIndex);
  vRetangulo := Rect;
  vRetangulo.Right := vFechar.Left;
  DrawText(Control.Canvas.Handle, PChar(vTexto), Length(vTexto), vRetangulo,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);

  // Botão de fechar: quadrado com borda e um "X" desenhado com linhas; vermelho com o mouse em cima
  vCanvas := Control.Canvas;
  if TabIndex = FAbaFecharSobMouse then
  begin
    vCanvas.Brush.Color := clRed;
    vCanvas.Pen.Color := clMaroon;
    vCorX := clWhite;
  end
  else
  begin
    vCanvas.Brush.Color := clWindow;
    vCanvas.Pen.Color := clGrayText;
    vCorX := clWindowText;
  end;
  vCanvas.Pen.Width := 1;
  vCanvas.RoundRect(vFechar.Left, vFechar.Top, vFechar.Right, vFechar.Bottom, 4, 4);

  vCanvas.Pen.Color := vCorX;
  vCanvas.Pen.Width := 2;
  vCanvas.MoveTo(vFechar.Left + cRECUO_X, vFechar.Top + cRECUO_X);
  vCanvas.LineTo(vFechar.Right - cRECUO_X, vFechar.Bottom - cRECUO_X);
  vCanvas.MoveTo(vFechar.Right - cRECUO_X, vFechar.Top + cRECUO_X);
  vCanvas.LineTo(vFechar.Left + cRECUO_X, vFechar.Bottom - cRECUO_X);

  vCanvas.Pen.Width := 1;
  vCanvas.Pen.Color := clWindowText;
  vCanvas.Brush.Color := clBtnFace;
  vCanvas.Font.Color := clWindowText;
end;

function TfrmPrincipal.RetanguloFechar(AIndice: Integer): TRect;
const
  cTAMANHO = 13;
  cMARGEM = 4;
var
  vAba: TRect;
begin
  vAba := pcJanelas.TabRect(AIndice);
  Result.Right := vAba.Right - cMARGEM;
  Result.Left := Result.Right - cTAMANHO;
  Result.Top := vAba.Top + (vAba.Height - cTAMANHO) div 2;
  Result.Bottom := Result.Top + cTAMANHO;
end;

function TfrmPrincipal.AbaFecharEm(X, Y: Integer): Integer;
begin
  Result := pcJanelas.IndexOfTabAt(X, Y);
  if (Result >= 0) and not PtInRect(RetanguloFechar(Result), Point(X, Y)) then
    Result := -1;
end;

procedure TfrmPrincipal.pcJanelasMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  vAba: Integer;
begin
  vAba := AbaFecharEm(X, Y);
  if vAba <> FAbaFecharSobMouse then
  begin
    FAbaFecharSobMouse := vAba;
    pcJanelas.Invalidate;
  end;
end;

procedure TfrmPrincipal.pcJanelasMouseLeave(Sender: TObject);
begin
  if FAbaFecharSobMouse <> -1 then
  begin
    FAbaFecharSobMouse := -1;
    pcJanelas.Invalidate;
  end;
end;

procedure TfrmPrincipal.pcJanelasMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if Button = mbLeft then
    FAbaFecharPressionada := AbaFecharEm(X, Y)
  else
    FAbaFecharPressionada := -1;
end;

procedure TfrmPrincipal.pcJanelasMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  vAba: Integer;
  vPagina: TTabSheet;
begin
  vAba := FAbaFecharPressionada;
  FAbaFecharPressionada := -1;
  if (Button <> mbLeft) or (vAba < 0) or (AbaFecharEm(X, Y) <> vAba) or (vAba >= pcJanelas.PageCount) then
    Exit;

  FAbaFecharSobMouse := -1;
  vPagina := pcJanelas.Pages[vAba];
  // Close passa pelo OnCloseQuery da tela (ex.: importação em andamento não fecha) e pelo FormClose da base,
  // que libera a aba
  if (vPagina.ControlCount > 0) and (vPagina.Controls[0] is TForm) then
    TForm(vPagina.Controls[0]).Close;
  pcJanelas.Invalidate;
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

function VersaoDoExecutavel: string;
var
  vTamanho, vManipulador, vTamanhoFixo: DWORD;
  vDados: TBytes;
  vFixo: PVSFixedFileInfo;
begin
  // FileVersion do recurso de versão do exe (Projeto > Opções > Informações de versão)
  Result := '?';
  vTamanho := GetFileVersionInfoSize(PChar(ParamStr(0)), vManipulador);
  if vTamanho = 0 then
    Exit;
  SetLength(vDados, vTamanho);
  if GetFileVersionInfo(PChar(ParamStr(0)), 0, vTamanho, @vDados[0]) and
    VerQueryValue(@vDados[0], '\', Pointer(vFixo), vTamanhoFixo) and (vTamanhoFixo >= SizeOf(TVSFixedFileInfo)) then
    Result := Format('%d.%d.%d.%d', [HiWord(vFixo.dwFileVersionMS), LoWord(vFixo.dwFileVersionMS),
      HiWord(vFixo.dwFileVersionLS), LoWord(vFixo.dwFileVersionLS)]);
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  OnCloseQuery := FormCloseQuery;
  FAbaFecharSobMouse := -1;
  FAbaFecharPressionada := -1;
  sbStatus.Panels[0].Text := 'VERSÃO: ' + VersaoDoExecutavel;
  sbStatus.Panels[1].Text := 'BANCO DADOS: ' + dmConexao.DescricaoBanco;
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
